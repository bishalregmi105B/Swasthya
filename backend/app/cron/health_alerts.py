"""
Health Alert Cron Handler
Sends push notifications for new or updated health alerts in user regions
"""

from datetime import datetime, timedelta
import os
from .base import BaseCronHandler


class HealthAlertHandler(BaseCronHandler):
    """Handles sending health alert push notifications to affected regions"""
    
    name = "HealthAlertHandler"
    
    # Only send alerts for high or critical severity
    ALERT_SEVERITY_THRESHOLD = ['high', 'critical']
    
    # Don't resend alerts within this many hours
    ALERT_COOLDOWN_HOURS = int(os.getenv('CRON_ALERT_COOLDOWN_HOURS', '24'))
    
    def execute(self, dry_run: bool = False):
        """
        Check for new/updated health alerts and notify affected users
        """
        from app import db
        from app.models.health_alert import HealthAlert
        from app.models.user import User
        from app.routes.notifications import send_onesignal_notification
        
        # Get alerts updated in last check period or new alerts
        cutoff_time = datetime.utcnow() - timedelta(hours=self.ALERT_COOLDOWN_HOURS)
        
        # Get active high-severity alerts
        alerts = HealthAlert.query.filter(
            HealthAlert.is_active == True,
            HealthAlert.severity.in_(self.ALERT_SEVERITY_THRESHOLD),
            HealthAlert.updated_at >= cutoff_time
        ).all()
        
        self.logger.info(f"Found {len(alerts)} recent high-severity alerts")
        
        for alert in alerts:
            try:
                # Find users in affected area
                users_query = User.query.filter_by(
                    is_active=True,
                    notification_push=True
                )
                
                # Filter by location
                if alert.affected_city:
                    users_query = users_query.filter(
                        User.city.ilike(f'%{alert.affected_city}%')
                    )
                elif alert.affected_province:
                    users_query = users_query.filter(
                        User.province.ilike(f'%{alert.affected_province}%')
                    )
                else:
                    # National alert - send to all users
                    pass
                
                affected_users = users_query.all()
                
                if not affected_users:
                    self.log_skipped(
                        f"Alert {alert.id} ({alert.disease_name}) - no users in affected area"
                    )
                    continue
                
                self.logger.info(
                    f"Alert {alert.id}: {len(affected_users)} users in "
                    f"{alert.affected_city or alert.affected_province or 'Nepal'}"
                )
                
                # Build notification
                severity_emoji = {
                    'critical': '🚨',
                    'high': '⚠️',
                    'moderate': '📢',
                    'low': 'ℹ️'
                }
                
                title = f"{severity_emoji.get(alert.severity, '⚠️')} Health Alert: {alert.disease_name}"
                
                message = alert.description or f"{alert.disease_name} cases reported"
                if alert.cases_count:
                    message += f"\n{alert.cases_count} cases reported"
                if alert.trend == 'increasing':
                    message += " (increasing)"
                
                location = alert.affected_city or alert.affected_province or 'Nepal'
                message += f"\nLocation: {location}"
                
                if dry_run:
                    self.logger.info(
                        f"[DRY RUN] Would send '{alert.disease_name}' alert to "
                        f"{len(affected_users)} users"
                    )
                    self.log_success(f"[DRY RUN] Alert {alert.id}")
                else:
                    # Send to all affected users
                    user_ids = [str(u.id) for u in affected_users]
                    
                    result = send_onesignal_notification(
                        title=title,
                        message=message,
                        user_ids=user_ids,
                        data={
                            'type': 'health_alert',
                            'alert_id': str(alert.id),
                            'disease_name': alert.disease_name,
                            'severity': alert.severity
                        }
                    )
                    
                    if 'id' in result or 'recipients' in result:
                        recipients = result.get('recipients', len(user_ids))
                        self.log_success(
                            f"Sent {alert.disease_name} alert to {recipients} users"
                        )
                    else:
                        self.log_failed(
                            f"Failed to send alert {alert.id}",
                            error=str(result.get('errors', result))
                        )
            
            except Exception as e:
                self.log_failed(
                    f"Error processing alert {alert.id}",
                    error=str(e)
                )
