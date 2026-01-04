from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User

users_bp = Blueprint('users', __name__)


@users_bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())


@users_bp.route('/location', methods=['PUT'])
@jwt_required()
def update_location():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    data = request.get_json()
    
    user.latitude = data.get('latitude')
    user.longitude = data.get('longitude')
    user.city = data.get('city')
    user.province = data.get('province')
    
    db.session.commit()
    return jsonify({'message': 'Location updated'})


@users_bp.route('/notifications', methods=['PUT'])
@jwt_required()
def update_notification_settings():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    data = request.get_json()
    
    if 'notification_email' in data:
        user.notification_email = data['notification_email']
    if 'notification_sms' in data:
        user.notification_sms = data['notification_sms']
    if 'notification_push' in data:
        user.notification_push = data['notification_push']
    
    db.session.commit()
    return jsonify({'message': 'Notification settings updated'})
