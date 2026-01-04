"""
Cron Scheduler
Coordinates all cron handlers and runs them in sequence
"""

from datetime import datetime
from .base import logger
from .medicine_reminders import MedicineReminderHandler
from .health_alerts import HealthAlertHandler
from .weather_alerts import WeatherAlertHandler
from .user_health_insights import UserHealthInsightsHandler
from .general_health_tips import GeneralHealthTipsHandler


class CronScheduler:
    """Main scheduler that coordinates all cron jobs"""
    
    def __init__(self):
        self.logger = logger
        self.handlers = {
            'medicine_reminders': MedicineReminderHandler,
            'health_alerts': HealthAlertHandler,
            'weather_alerts': WeatherAlertHandler,
            'user_health_insights': UserHealthInsightsHandler,
            'general_health_tips': GeneralHealthTipsHandler,
        }
    
    def run_all(self, dry_run: bool = False) -> dict:
        """
        Run all cron handlers
        
        Args:
            dry_run: If True, simulate without sending notifications
            
        Returns:
            Dict with results from all handlers
        """
        start_time = datetime.utcnow()
        results = {
            'start_time': start_time.isoformat(),
            'dry_run': dry_run,
            'handlers': {}
        }
        
        self.logger.info("=" * 50)
        self.logger.info("Starting Swasthya Cron Scheduler")
        self.logger.info(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
        self.logger.info("=" * 50)
        
        for name, handler_class in self.handlers.items():
            try:
                handler = handler_class()
                result = handler.run(dry_run=dry_run)
                results['handlers'][name] = result
            except Exception as e:
                self.logger.error(f"Handler {name} crashed: {e}")
                results['handlers'][name] = {
                    'handler': name,
                    'error': str(e),
                    'success': 0,
                    'failed': 0,
                    'skipped': 0
                }
        
        end_time = datetime.utcnow()
        results['end_time'] = end_time.isoformat()
        results['total_duration_seconds'] = (end_time - start_time).total_seconds()
        
        # Calculate totals
        total_success = sum(h.get('success', 0) for h in results['handlers'].values())
        total_failed = sum(h.get('failed', 0) for h in results['handlers'].values())
        total_skipped = sum(h.get('skipped', 0) for h in results['handlers'].values())
        
        results['totals'] = {
            'success': total_success,
            'failed': total_failed,
            'skipped': total_skipped
        }
        
        self.logger.info("=" * 50)
        self.logger.info(
            f"Cron completed in {results['total_duration_seconds']:.2f}s - "
            f"Success: {total_success}, Failed: {total_failed}, Skipped: {total_skipped}"
        )
        self.logger.info("=" * 50)
        
        return results
    
    def run_handler(self, handler_name: str, dry_run: bool = False) -> dict:
        """
        Run a specific handler
        
        Args:
            handler_name: Name of the handler to run
            dry_run: If True, simulate without sending notifications
            
        Returns:
            Dict with handler result or error
        """
        if handler_name not in self.handlers:
            return {
                'error': f"Unknown handler: {handler_name}",
                'available': list(self.handlers.keys())
            }
        
        handler_class = self.handlers[handler_name]
        handler = handler_class()
        return handler.run(dry_run=dry_run)
    
    def get_handler_names(self) -> list:
        """Get list of available handler names"""
        return list(self.handlers.keys())
