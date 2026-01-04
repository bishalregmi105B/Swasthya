from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date
from app import db
from app.models import Appointment, Doctor

appointments_bp = Blueprint('appointments', __name__)


@appointments_bp.route('', methods=['POST'])
@jwt_required()
def create_appointment():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    required = ['doctor_id', 'appointment_date', 'appointment_time', 'type']
    if not all(k in data for k in required):
        return jsonify({'error': 'Missing required fields'}), 400
    
    doctor = Doctor.query.get_or_404(data['doctor_id'])
    
    appointment = Appointment(
        patient_id=user_id,
        doctor_id=data['doctor_id'],
        appointment_date=datetime.strptime(data['appointment_date'], '%Y-%m-%d').date(),
        appointment_time=datetime.strptime(data['appointment_time'], '%H:%M').time(),
        type=data['type'],
        consultation_fee=doctor.consultation_fee if data['type'] == 'video' else doctor.chat_fee,
        notes=data.get('notes')
    )
    
    if data['type'] == 'video':
        appointment.generate_room_id()
    
    db.session.add(appointment)
    db.session.commit()
    
    return jsonify({
        'message': 'Appointment booked successfully',
        'appointment': appointment.to_dict()
    }), 201


@appointments_bp.route('', methods=['GET'])
@jwt_required()
def get_appointments():
    user_id = get_jwt_identity()
    status = request.args.get('status')
    upcoming = request.args.get('upcoming')
    
    query = Appointment.query.filter_by(patient_id=user_id)
    
    if status:
        query = query.filter_by(status=status)
    
    if upcoming == 'true':
        query = query.filter(Appointment.appointment_date >= date.today())
    
    appointments = query.order_by(Appointment.appointment_date.desc()).all()
    return jsonify([a.to_dict() for a in appointments])


@appointments_bp.route('/<int:appointment_id>', methods=['GET'])
@jwt_required()
def get_appointment(appointment_id):
    user_id = get_jwt_identity()
    appointment = Appointment.query.filter_by(id=appointment_id, patient_id=user_id).first_or_404()
    return jsonify(appointment.to_dict())


@appointments_bp.route('/<int:appointment_id>/join', methods=['POST'])
@jwt_required()
def join_call(appointment_id):
    user_id = get_jwt_identity()
    appointment = Appointment.query.filter_by(id=appointment_id, patient_id=user_id).first_or_404()
    
    if appointment.type != 'video':
        return jsonify({'error': 'Not a video appointment'}), 400
    
    if not appointment.jitsi_room_id:
        appointment.generate_room_id()
        db.session.commit()
    
    return jsonify({
        'room_id': appointment.jitsi_room_id,
        'domain': 'meet.jit.si',
        'room_name': appointment.jitsi_room_id,
        'doctor': appointment.doctor.to_dict()
    })


@appointments_bp.route('/<int:appointment_id>/cancel', methods=['POST'])
@jwt_required()
def cancel_appointment(appointment_id):
    user_id = get_jwt_identity()
    appointment = Appointment.query.filter_by(id=appointment_id, patient_id=user_id).first_or_404()
    
    if appointment.status == 'completed':
        return jsonify({'error': 'Cannot cancel completed appointment'}), 400
    
    appointment.status = 'cancelled'
    db.session.commit()
    
    return jsonify({'message': 'Appointment cancelled'})


@appointments_bp.route('/<int:appointment_id>/complete', methods=['POST'])
@jwt_required()
def complete_appointment(appointment_id):
    user_id = get_jwt_identity()
    appointment = Appointment.query.get_or_404(appointment_id)
    
    appointment.status = 'completed'
    db.session.commit()
    
    return jsonify({'message': 'Appointment completed'})
