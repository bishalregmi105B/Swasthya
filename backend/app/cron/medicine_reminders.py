"""
Medicine Reminder Cron Handler
Sends push notifications for scheduled medicine reminders via OneSignal
"""

from datetime import datetime, timedelta
import pytz
import os
from .base import BaseCronHandler


class MedicineReminderHandler(BaseCronHandler):
    """Handles sending medicine reminder push notifications"""
    
    name = "MedicineReminderHandler"
    
    # Time window in minutes - reminders within this window of current time will be sent
    REMINDER_WINDOW_MINUTES = int(os.getenv('CRON_MEDICINE_WINDOW_MINUTES', '5'))
    
    def __init__(self):
        super().__init__()
        # Nepal timezone - adjust as needed
        self.timezone = pytz.timezone('Asia/Kathmandu')
    
    def execute(self, dry_run: bool = False):
        """
        Check all active reminders and send notifications for those due now
        """
        from app import db
        from app.models.reminder import MedicineReminder, ReminderLog
        from app.models.user import User
        from app.routes.notifications import send_onesignal_notification
        
        now = datetime.now(self.timezone)
        current_time = now.strftime('%H:%M')
        current_hour = now.hour
        current_minute = now.minute
        
        self.logger.info(f"Checking reminders for {current_time} (window: ±{self.REMINDER_WINDOW_MINUTES} min)")
        
        # Get all active reminders
        active_reminders = MedicineReminder.query.filter_by(is_active=True).all()
        
        self.logger.info(f"Found {len(active_reminders)} active reminders")
        
        for reminder in active_reminders:
            try:
                # Check if reminder times match current time window
                reminder_times = reminder.reminder_times or []
                
                if not reminder_times:
                    self.log_skipped(f"Reminder {reminder.id} has no times")
                    continue
                
                # Check each reminder time
                for time_str in reminder_times:
                    if self._is_time_due(time_str, current_hour, current_minute):
                        # Check if already sent recently (within last hour)
                        if self._was_recently_sent(reminder.id, time_str):
                            self.log_skipped(
                                f"Reminder {reminder.id} ({reminder.medicine_name}) at {time_str} "
                                "already sent recently"
                            )
                            continue
                        
                        # Send notification
                        if dry_run:
                            self.logger.info(
                                f"[DRY RUN] Would send: {reminder.medicine_name} to user {reminder.user_id}"
                            )
                            self.log_success(f"[DRY RUN] Reminder {reminder.id} at {time_str}")
                        else:
                            # Get user info
                            user = User.query.get(reminder.user_id)
                            if not user:
                                self.log_failed(f"User {reminder.user_id} not found")
                                continue
                            
                            # Build notification message
                            message = f"Time to take {reminder.medicine_name}"
                            if reminder.strength:
                                message += f" ({reminder.strength} {reminder.unit or ''})"
                            if reminder.instructions:
                                message += f"\n{reminder.instructions}"
                            
                            # Send via OneSignal
                            result = send_onesignal_notification(
                                title='💊 Medicine Reminder',
                                message=message,
                                user_ids=[str(reminder.user_id)],
                                data={
                                    'type': 'medicine_reminder',
                                    'reminder_id': str(reminder.id),
                                    'medicine_name': reminder.medicine_name,
                                    'scheduled_time': time_str
                                }
                            )
                            
                            if 'id' in result or 'recipients' in result:
                                self.log_success(
                                    f"Sent reminder for {reminder.medicine_name} to user {reminder.user_id}"
                                )
                                # Log the sent reminder
                                self._log_reminder_sent(reminder.id, time_str)
                            else:
                                self.log_failed(
                                    f"Failed to send reminder {reminder.id}",
                                    error=str(result.get('errors', result))
                                )
            
            except Exception as e:
                self.log_failed(
                    f"Error processing reminder {reminder.id}",
                    error=str(e)
                )
    
    def _is_time_due(self, time_str: str, current_hour: int, current_minute: int) -> bool:
        """
        Check if a reminder time is within the current window
        
        Args:
            time_str: Time string in HH:MM format
            current_hour: Current hour
            current_minute: Current minute
            
        Returns:
            True if the time is within the reminder window
        """
        try:
            parts = time_str.split(':')
            reminder_hour = int(parts[0])
            reminder_minute = int(parts[1])
            
            # Calculate minutes from midnight for both times
            current_total = current_hour * 60 + current_minute
            reminder_total = reminder_hour * 60 + reminder_minute
            
            # Check if within window
            diff = abs(current_total - reminder_total)
            
            # Handle midnight crossing
            if diff > 720:  # More than 12 hours
                diff = 1440 - diff
            
            return diff <= self.REMINDER_WINDOW_MINUTES
            
        except (ValueError, IndexError):
            self.logger.warning(f"Invalid time format: {time_str}")
            return False
    
    def _was_recently_sent(self, reminder_id: int, time_str: str) -> bool:
        """
        Check if this reminder was already sent within the last hour
        
        Args:
            reminder_id: Reminder ID
            time_str: Time string
            
        Returns:
            True if reminder was sent recently
        """
        from app import db
        from app.models.reminder import ReminderLog
        
        one_hour_ago = datetime.utcnow() - timedelta(hours=1)
        
        # Check for existing log entry
        recent_log = ReminderLog.query.filter(
            ReminderLog.reminder_id == reminder_id,
            ReminderLog.scheduled_time >= one_hour_ago
        ).first()
        
        return recent_log is not None
    
    def _log_reminder_sent(self, reminder_id: int, time_str: str):
        """
        Log that a reminder was sent
        
        Args:
            reminder_id: Reminder ID
            time_str: Scheduled time
        """
        from app import db
        from app.models.reminder import ReminderLog
        
        try:
            # Parse time and combine with today's date
            now = datetime.now(self.timezone)
            parts = time_str.split(':')
            scheduled_dt = now.replace(
                hour=int(parts[0]),
                minute=int(parts[1]),
                second=0,
                microsecond=0
            )
            
            log = ReminderLog(
                reminder_id=reminder_id,
                scheduled_time=scheduled_dt.astimezone(pytz.UTC).replace(tzinfo=None)
            )
            db.session.add(log)
            db.session.commit()
        except Exception as e:
            self.logger.error(f"Failed to log reminder: {e}")
            db.session.rollback()
