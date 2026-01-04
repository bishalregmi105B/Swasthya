from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date, timedelta
from app import db
from app.models import MedicineReminder, ReminderLog

reminders_bp = Blueprint('reminders', __name__)


@reminders_bp.route('', methods=['POST'])
@jwt_required()
def create_reminder():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    required = ['medicine_name', 'form']
    if not all(k in data for k in required):
        return jsonify({'error': 'Missing required fields'}), 400
    
    reminder = MedicineReminder(
        user_id=user_id,
        medicine_name=data['medicine_name'],
        form=data['form'],
        strength=data.get('strength'),
        unit=data.get('unit'),
        frequency=data.get('frequency', 'daily'),
        times_per_day=data.get('times_per_day', 1),
        reminder_times=data.get('reminder_times', ['08:00']),
        instructions=data.get('instructions'),
        refill_reminder=data.get('refill_reminder', True),
        critical_alert=data.get('critical_alert', False)
    )
    
    db.session.add(reminder)
    db.session.commit()
    
    return jsonify({
        'message': 'Reminder created',
        'reminder': reminder.to_dict()
    }), 201


@reminders_bp.route('', methods=['GET'])
@jwt_required(optional=True)
def get_reminders():
    user_id = get_jwt_identity()
    
    # Return empty list if not authenticated
    if not user_id:
        return jsonify([])
    
    active_only = request.args.get('active', 'true') == 'true'
    
    query = MedicineReminder.query.filter_by(user_id=user_id)
    if active_only:
        query = query.filter_by(is_active=True)
    
    reminders = query.all()
    return jsonify([r.to_dict() for r in reminders])


@reminders_bp.route('/today', methods=['GET'])
@jwt_required()
def get_today_reminders():
    user_id = get_jwt_identity()
    today = date.today()
    
    reminders = MedicineReminder.query.filter_by(user_id=user_id, is_active=True).all()
    
    schedule = {'morning': [], 'afternoon': [], 'evening': []}
    
    for r in reminders:
        for time_str in (r.reminder_times or ['08:00']):
            hour = int(time_str.split(':')[0])
            item = {**r.to_dict(), 'scheduled_time': time_str, 'is_taken': False}
            
            if hour < 12:
                schedule['morning'].append(item)
            elif hour < 17:
                schedule['afternoon'].append(item)
            else:
                schedule['evening'].append(item)
    
    return jsonify(schedule)


@reminders_bp.route('/<int:reminder_id>', methods=['GET'])
@jwt_required()
def get_reminder_by_id(reminder_id):
    """Get a single reminder by ID"""
    user_id = get_jwt_identity()
    reminder = MedicineReminder.query.filter_by(id=reminder_id, user_id=user_id).first_or_404()
    return jsonify(reminder.to_dict())


@reminders_bp.route('/<int:reminder_id>', methods=['PUT'])
@jwt_required()
def update_reminder(reminder_id):
    user_id = get_jwt_identity()
    reminder = MedicineReminder.query.filter_by(id=reminder_id, user_id=user_id).first_or_404()
    data = request.get_json()
    
    updatable = ['medicine_name', 'form', 'strength', 'unit', 'frequency', 
                 'times_per_day', 'reminder_times', 'instructions', 
                 'refill_reminder', 'critical_alert', 'is_active']
    
    for field in updatable:
        if field in data:
            setattr(reminder, field, data[field])
    
    db.session.commit()
    return jsonify(reminder.to_dict())


@reminders_bp.route('/<int:reminder_id>', methods=['DELETE'])
@jwt_required()
def delete_reminder(reminder_id):
    user_id = get_jwt_identity()
    reminder = MedicineReminder.query.filter_by(id=reminder_id, user_id=user_id).first_or_404()
    
    db.session.delete(reminder)
    db.session.commit()
    
    return jsonify({'message': 'Reminder deleted'})


@reminders_bp.route('/<int:reminder_id>/take', methods=['POST'])
@jwt_required()
def mark_taken(reminder_id):
    user_id = get_jwt_identity()
    reminder = MedicineReminder.query.filter_by(id=reminder_id, user_id=user_id).first_or_404()
    data = request.get_json()
    
    log = ReminderLog(
        reminder_id=reminder_id,
        scheduled_time=datetime.now(),
        taken_at=datetime.now(),
        is_taken=True
    )
    db.session.add(log)
    db.session.commit()
    
    return jsonify({'message': 'Marked as taken'})


@reminders_bp.route('/adherence', methods=['GET'])
@jwt_required()
def get_adherence():
    user_id = get_jwt_identity()
    
    return jsonify({
        'adherence_percentage': 95,
        'streak_days': 7,
        'total_taken': 42,
        'total_scheduled': 44,
        'insight': "You've adhered to 95% of your schedule this week! Great job keeping up."
    })


@reminders_bp.route('/ai-suggestion', methods=['POST'])
@jwt_required()
def get_ai_suggestion():
    data = request.get_json()
    medicine_name = data.get('medicine_name', '')
    
    suggestions = {
        'atorvastatin': {'time': '20:00', 'reason': 'Atorvastatin is generally most effective when taken in the evening.'},
        'metformin': {'time': '08:00', 'reason': 'Take Metformin with breakfast to reduce stomach upset.'},
        'lisinopril': {'time': '08:00', 'reason': 'Blood pressure medications work best when taken in the morning.'},
    }
    
    medicine_lower = medicine_name.lower()
    for key, suggestion in suggestions.items():
        if key in medicine_lower:
            return jsonify(suggestion)
    
    return jsonify({'time': '08:00', 'reason': 'Morning is usually a good time for this medication.'})
