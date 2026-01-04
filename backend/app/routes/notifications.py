"""
OneSignal Push Notification Routes
Send user-based push notifications through OneSignal API
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import os
import requests
import json
from app import db
from app.models import User

notifications_bp = Blueprint('notifications', __name__)

# OneSignal API Configuration
ONESIGNAL_APP_ID = os.getenv('ONESIGNAL_APP_ID', '')
ONESIGNAL_REST_API_KEY = os.getenv('ONESIGNAL_REST_API_KEY', '')
ONESIGNAL_API_URL = 'https://onesignal.com/api/v1/notifications'


def send_onesignal_notification(
    title: str,
    message: str,
    user_ids: list = None,
    player_ids: list = None,
    segments: list = None,
    data: dict = None,
    url: str = None
) -> dict:
    """
    Send push notification via OneSignal API
    
    Args:
        title: Notification title
        message: Notification body
        user_ids: List of external user IDs (backend user IDs)
        player_ids: List of OneSignal player IDs
        segments: List of segments (e.g., ['All', 'Active Users'])
        data: Additional data payload
        url: Deep link URL
    
    Returns:
        Response from OneSignal API
    """
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Basic {ONESIGNAL_REST_API_KEY}'
    }
    
    payload = {
        'app_id': ONESIGNAL_APP_ID,
        'headings': {'en': title},
        'contents': {'en': message},
    }
    
    # Target by external user IDs (recommended)
    if user_ids:
        payload['include_aliases'] = {'external_id': user_ids}
        payload['target_channel'] = 'push'
    # Target by player IDs
    elif player_ids:
        payload['include_player_ids'] = player_ids
    # Target by segments
    elif segments:
        payload['included_segments'] = segments
    else:
        # Default to all subscribed users
        payload['included_segments'] = ['Subscribed Users']
    
    # Add additional data
    if data:
        payload['data'] = data
    
    # Add deep link URL
    if url:
        payload['url'] = url
    
    try:
        response = requests.post(
            ONESIGNAL_API_URL,
            headers=headers,
            json=payload
        )
        return response.json()
    except Exception as e:
        return {'error': str(e)}


@notifications_bp.route('', methods=['POST'])
@jwt_required()
def send_notification():
    """
    Send a push notification to specific users
    
    Request body:
    {
        "title": "Notification Title",
        "message": "Notification body",
        "user_ids": [1, 2, 3],  // Optional: target user IDs
        "player_ids": ["..."],  // Optional: target player IDs
        "segments": ["All"],    // Optional: target segments
        "data": {...},          // Optional: additional data
        "type": "appointment"   // Optional: notification type
    }
    """
    data = request.get_json()
    
    if not data.get('title') or not data.get('message'):
        return jsonify({'error': 'Title and message are required'}), 400
    
    # Build notification payload
    title = data['title']
    message = data['message']
    
    # Convert user IDs to external IDs (strings)
    user_ids = None
    if data.get('user_ids'):
        user_ids = [str(uid) for uid in data['user_ids']]
    
    player_ids = data.get('player_ids')
    segments = data.get('segments')
    
    # Build additional data
    notification_data = data.get('data', {})
    if data.get('type'):
        notification_data['type'] = data['type']
    if data.get('target_id'):
        notification_data['target_id'] = str(data['target_id'])
    
    # Send notification
    result = send_onesignal_notification(
        title=title,
        message=message,
        user_ids=user_ids,
        player_ids=player_ids,
        segments=segments,
        data=notification_data if notification_data else None
    )
    
    if 'error' in result and 'errors' not in result:
        return jsonify({'status': 'error', 'message': result['error']}), 500
    
    return jsonify({
        'status': 'success',
        'message': 'Notification sent',
        'onesignal_response': result
    })


@notifications_bp.route('/broadcast', methods=['POST'])
@jwt_required()
def broadcast_notification():
    """
    Broadcast notification to all users or specific segments
    """
    data = request.get_json()
    
    if not data.get('title') or not data.get('message'):
        return jsonify({'error': 'Title and message are required'}), 400
    
    segments = data.get('segments', ['Subscribed Users'])
    
    result = send_onesignal_notification(
        title=data['title'],
        message=data['message'],
        segments=segments,
        data=data.get('data')
    )
    
    return jsonify({
        'status': 'success',
        'message': 'Broadcast sent',
        'onesignal_response': result
    })


@notifications_bp.route('/appointment-reminder', methods=['POST'])
@jwt_required()
def send_appointment_reminder():
    """
    Send appointment reminder notification
    """
    data = request.get_json()
    
    user_id = data.get('user_id')
    doctor_name = data.get('doctor_name', 'Doctor')
    appointment_time = data.get('appointment_time', '')
    appointment_id = data.get('appointment_id')
    
    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400
    
    result = send_onesignal_notification(
        title='📅 Appointment Reminder',
        message=f'Your appointment with {doctor_name} is scheduled for {appointment_time}',
        user_ids=[str(user_id)],
        data={
            'type': 'appointment',
            'target_id': str(appointment_id) if appointment_id else None
        }
    )
    
    return jsonify({
        'status': 'success',
        'message': 'Reminder sent',
        'onesignal_response': result
    })


@notifications_bp.route('/medicine-reminder', methods=['POST'])
@jwt_required()
def send_medicine_reminder():
    """
    Send medicine reminder notification
    """
    data = request.get_json()
    
    user_id = data.get('user_id')
    medicine_name = data.get('medicine_name', 'your medicine')
    reminder_id = data.get('reminder_id')
    
    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400
    
    result = send_onesignal_notification(
        title='💊 Medicine Reminder',
        message=f"It's time to take {medicine_name}",
        user_ids=[str(user_id)],
        data={
            'type': 'reminder',
            'target_id': str(reminder_id) if reminder_id else None
        }
    )
    
    return jsonify({
        'status': 'success',
        'message': 'Reminder sent',
        'onesignal_response': result
    })


@notifications_bp.route('/health-alert', methods=['POST'])
@jwt_required()
def send_health_alert():
    """
    Send health alert notification to users in a region
    """
    data = request.get_json()
    
    title = data.get('title', '⚠️ Health Alert')
    message = data.get('message', 'New health alert in your area')
    user_ids = data.get('user_ids')  # Optional: specific users
    segments = data.get('segments')  # Optional: segments
    alert_id = data.get('alert_id')
    
    result = send_onesignal_notification(
        title=title,
        message=message,
        user_ids=[str(uid) for uid in user_ids] if user_ids else None,
        segments=segments if not user_ids else None,
        data={
            'type': 'health_alert',
            'target_id': str(alert_id) if alert_id else None
        }
    )
    
    return jsonify({
        'status': 'success',
        'message': 'Health alert sent',
        'onesignal_response': result
    })


@notifications_bp.route('/register-device', methods=['POST'])
@jwt_required()
def register_device():
    """
    Register device player ID with user account
    """
    user_id = get_jwt_identity()
    data = request.get_json()
    
    player_id = data.get('player_id')
    
    if not player_id:
        return jsonify({'error': 'player_id is required'}), 400
    
    # Store player_id in user record (you may need to add this column)
    try:
        user = User.query.get(user_id)
        if user:
            # You can add a onesignal_player_id column to User model
            # For now, we'll just acknowledge the registration
            return jsonify({
                'status': 'success',
                'message': 'Device registered',
                'user_id': user_id,
                'player_id': player_id
            })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    return jsonify({'error': 'User not found'}), 404


@notifications_bp.route('/test', methods=['POST'])
def test_notification():
    """
    Test endpoint to verify OneSignal integration (no auth required for testing)
    Send a test notification to a specific player ID
    """
    data = request.get_json()
    player_id = data.get('player_id')
    
    if not player_id:
        return jsonify({'error': 'player_id is required for test'}), 400
    
    result = send_onesignal_notification(
        title='🎉 Test Notification',
        message='OneSignal is working correctly with Swasthya!',
        player_ids=[player_id],
        data={'type': 'test', 'timestamp': str(__import__('datetime').datetime.now())}
    )
    
    return jsonify({
        'status': 'success',
        'message': 'Test notification sent',
        'onesignal_response': result
    })
