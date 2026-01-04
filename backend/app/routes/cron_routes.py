"""
Cron API Routes
Provides HTTP endpoints to trigger cron jobs
"""

from flask import Blueprint, request, jsonify
import os
from datetime import datetime

cron_bp = Blueprint('cron', __name__)

# Secret key for cron authentication (set in .env)
CRON_SECRET_KEY = os.getenv('CRON_SECRET_KEY', 'default-cron-secret-change-me')

# Store last run info
_last_run_info = {
    'last_run': None,
    'result': None
}


def verify_cron_auth():
    """Verify cron authentication via header or query param"""
    # Check header first
    auth_key = request.headers.get('X-Cron-Key')
    
    # Fallback to query param
    if not auth_key:
        auth_key = request.args.get('key')
    
    if not auth_key or auth_key != CRON_SECRET_KEY:
        return False
    return True


@cron_bp.route('/run', methods=['POST', 'GET'])
def run_all_cron():
    """
    Run all cron jobs
    
    Authentication: X-Cron-Key header or ?key= query param
    Query params:
        - dry_run: Set to 'true' to simulate (optional)
    """
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized', 'message': 'Invalid or missing cron key'}), 401
    
    dry_run = request.args.get('dry_run', 'false').lower() == 'true'
    
    try:
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        result = scheduler.run_all(dry_run=dry_run)
        
        # Store last run info
        _last_run_info['last_run'] = datetime.utcnow().isoformat()
        _last_run_info['result'] = result
        
        return jsonify({
            'status': 'success',
            'message': 'Cron jobs completed',
            'result': result
        })
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500


@cron_bp.route('/medicine-reminders', methods=['POST', 'GET'])
def run_medicine_reminders():
    """Run only medicine reminder cron"""
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    dry_run = request.args.get('dry_run', 'false').lower() == 'true'
    
    try:
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        result = scheduler.run_handler('medicine_reminders', dry_run=dry_run)
        
        return jsonify({
            'status': 'success',
            'result': result
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500


@cron_bp.route('/health-alerts', methods=['POST', 'GET'])
def run_health_alerts():
    """Run only health alerts cron"""
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    dry_run = request.args.get('dry_run', 'false').lower() == 'true'
    
    try:
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        result = scheduler.run_handler('health_alerts', dry_run=dry_run)
        
        return jsonify({
            'status': 'success',
            'result': result
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500


@cron_bp.route('/weather-alerts', methods=['POST', 'GET'])
def run_weather_alerts():
    """Run only weather alerts cron"""
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    dry_run = request.args.get('dry_run', 'false').lower() == 'true'
    
    try:
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        result = scheduler.run_handler('weather_alerts', dry_run=dry_run)
        
        return jsonify({
            'status': 'success',
            'result': result
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500


@cron_bp.route('/user-health-insights', methods=['POST', 'GET'])
def run_user_health_insights():
    """
    Run AI-powered user health insights cron
    Analyzes user medical data and sends personalized daily notifications
    """
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    dry_run = request.args.get('dry_run', 'false').lower() == 'true'
    
    try:
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        result = scheduler.run_handler('user_health_insights', dry_run=dry_run)
        
        return jsonify({
            'status': 'success',
            'result': result
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500


@cron_bp.route('/general-health-tips', methods=['POST', 'GET'])
def run_general_health_tips():
    """
    Run AI-powered general health tips cron
    Sends hourly health tips to all users
    """
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    dry_run = request.args.get('dry_run', 'false').lower() == 'true'
    
    try:
        from app.cron import CronScheduler
        
        scheduler = CronScheduler()
        result = scheduler.run_handler('general_health_tips', dry_run=dry_run)
        
        return jsonify({
            'status': 'success',
            'result': result
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500


@cron_bp.route('/status', methods=['GET'])
def cron_status():
    """Get cron status and last run info"""
    if not verify_cron_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    from app.cron import CronScheduler
    
    scheduler = CronScheduler()
    
    return jsonify({
        'status': 'ok',
        'available_handlers': scheduler.get_handler_names(),
        'last_run': _last_run_info['last_run'],
        'last_result': _last_run_info['result']
    })


@cron_bp.route('/handlers', methods=['GET'])
def list_handlers():
    """List available cron handlers"""
    from app.cron import CronScheduler
    
    scheduler = CronScheduler()
    
    return jsonify({
        'handlers': scheduler.get_handler_names()
    })
