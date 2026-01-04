"""
Base Cron Handler
Provides common functionality for all cron handlers
"""

from abc import ABC, abstractmethod
from datetime import datetime
import logging


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [CRON] %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger('swasthya_cron')


class BaseCronHandler(ABC):
    """Base class for all cron handlers"""
    
    name: str = "BaseHandler"
    
    def __init__(self):
        self.logger = logger
        self.start_time = None
        self.end_time = None
        self.results = {
            'success': 0,
            'failed': 0,
            'skipped': 0,
            'errors': []
        }
    
    def run(self, dry_run: bool = False) -> dict:
        """
        Execute the cron handler
        
        Args:
            dry_run: If True, don't actually send notifications
            
        Returns:
            Dict with execution results
        """
        self.start_time = datetime.utcnow()
        self.results = {
            'success': 0,
            'failed': 0,
            'skipped': 0,
            'errors': []
        }
        
        self.logger.info(f"Starting {self.name}...")
        
        try:
            self.execute(dry_run)
        except Exception as e:
            self.logger.error(f"{self.name} failed with error: {str(e)}")
            self.results['errors'].append(str(e))
        
        self.end_time = datetime.utcnow()
        duration = (self.end_time - self.start_time).total_seconds()
        
        self.logger.info(
            f"{self.name} completed in {duration:.2f}s - "
            f"Success: {self.results['success']}, Failed: {self.results['failed']}, "
            f"Skipped: {self.results['skipped']}"
        )
        
        return {
            'handler': self.name,
            'start_time': self.start_time.isoformat(),
            'end_time': self.end_time.isoformat(),
            'duration_seconds': duration,
            **self.results
        }
    
    @abstractmethod
    def execute(self, dry_run: bool = False):
        """
        Main execution logic - must be implemented by subclasses
        
        Args:
            dry_run: If True, simulate without sending notifications
        """
        pass
    
    def log_success(self, message: str):
        """Log a successful operation"""
        self.logger.info(f"✅ {message}")
        self.results['success'] += 1
    
    def log_failed(self, message: str, error: str = None):
        """Log a failed operation"""
        self.logger.warning(f"❌ {message}")
        self.results['failed'] += 1
        if error:
            self.results['errors'].append(error)
    
    def log_skipped(self, message: str):
        """Log a skipped operation"""
        self.logger.debug(f"⏭️ {message}")
        self.results['skipped'] += 1
