#!/usr/bin/env python3
"""
Swasthya Cron Runner
Standalone script for cPanel/Webuzo cron jobs

Usage:
    # Run all cron jobs
    python cron_runner.py
    
    # Run in dry-run mode (no actual notifications sent)
    python cron_runner.py --dry-run
    
    # Run specific handler
    python cron_runner.py --handler medicine_reminders
    python cron_runner.py --handler health_alerts
    python cron_runner.py --handler weather_alerts

Add to cPanel cron (run every minute for medicine reminders):
    * * * * * cd /path/to/backend && python cron_runner.py >> /var/log/swasthya_cron.log 2>&1

Or run health/weather checks every 30 minutes:
    */30 * * * * cd /path/to/backend && python cron_runner.py --handler health_alerts >> /var/log/swasthya_cron.log 2>&1
    */30 * * * * cd /path/to/backend && python cron_runner.py --handler weather_alerts >> /var/log/swasthya_cron.log 2>&1
"""

import sys
import os
import argparse
from datetime import datetime

# Add the parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load environment variables
from dotenv import load_dotenv
load_dotenv()


def main():
    parser = argparse.ArgumentParser(description='Swasthya Cron Runner')
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Simulate without sending actual notifications'
    )
    parser.add_argument(
        '--handler',
        type=str,
        choices=['medicine_reminders', 'health_alerts', 'weather_alerts', 'user_health_insights', 'general_health_tips'],
        help='Run specific handler only'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List available handlers'
    )
    
    args = parser.parse_args()
    
    print(f"\n{'='*60}")
    print(f"Swasthya Cron Runner - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")
    
    # Import Flask app to get database context
    from app import create_app, db
    
    app = create_app()
    
    with app.app_context():
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        
        # List handlers
        if args.list:
            print("\nAvailable handlers:")
            for handler in scheduler.get_handler_names():
                print(f"  - {handler}")
            return
        
        # Run specific handler or all
        if args.handler:
            print(f"\nRunning handler: {args.handler}")
            print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
            result = scheduler.run_handler(args.handler, dry_run=args.dry_run)
        else:
            print(f"\nRunning all handlers")
            print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
            result = scheduler.run_all(dry_run=args.dry_run)
        
        # Print results
        print(f"\n{'='*60}")
        print("Results:")
        print(f"{'='*60}")
        
        if 'handlers' in result:
            # All handlers ran
            for name, handler_result in result['handlers'].items():
                status = 'error' if handler_result.get('error') else 'ok'
                print(f"  {name}: {status}")
                if handler_result.get('error'):
                    print(f"    Error: {handler_result['error']}")
                else:
                    print(f"    Success: {handler_result.get('success', 0)}, "
                          f"Failed: {handler_result.get('failed', 0)}, "
                          f"Skipped: {handler_result.get('skipped', 0)}")
            
            print(f"\nTotal duration: {result.get('total_duration_seconds', 0):.2f}s")
            print(f"Totals: {result.get('totals', {})}")
        else:
            # Single handler ran
            print(f"  Handler: {result.get('handler', 'unknown')}")
            print(f"  Success: {result.get('success', 0)}")
            print(f"  Failed: {result.get('failed', 0)}")
            print(f"  Skipped: {result.get('skipped', 0)}")
            if result.get('errors'):
                print(f"  Errors: {result['errors']}")


if __name__ == '__main__':
    main()
