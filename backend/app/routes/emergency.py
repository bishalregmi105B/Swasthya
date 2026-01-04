from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import EmergencyContact

emergency_bp = Blueprint('emergency', __name__)


@emergency_bp.route('/contacts', methods=['GET'])
@jwt_required()
def get_contacts():
    user_id = get_jwt_identity()
    contacts = EmergencyContact.query.filter_by(user_id=user_id).order_by(EmergencyContact.is_primary.desc()).all()
    return jsonify([c.to_dict() for c in contacts])


@emergency_bp.route('/contacts', methods=['POST'])
@jwt_required()
def add_contact():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data.get('name') or not data.get('phone'):
        return jsonify({'error': 'Name and phone required'}), 400
    
    contact = EmergencyContact(
        user_id=user_id,
        name=data['name'],
        phone=data['phone'],
        relationship=data.get('relationship'),
        is_primary=data.get('is_primary', False)
    )
    
    if contact.is_primary:
        EmergencyContact.query.filter_by(user_id=user_id, is_primary=True).update({'is_primary': False})
    
    db.session.add(contact)
    db.session.commit()
    
    return jsonify(contact.to_dict()), 201


@emergency_bp.route('/contacts/<int:contact_id>', methods=['DELETE'])
@jwt_required()
def delete_contact(contact_id):
    user_id = get_jwt_identity()
    contact = EmergencyContact.query.filter_by(id=contact_id, user_id=user_id).first_or_404()
    
    db.session.delete(contact)
    db.session.commit()
    
    return jsonify({'message': 'Contact deleted'})


@emergency_bp.route('/services', methods=['GET'])
def get_emergency_services():
    services = [
        {'id': 'ambulance', 'name': 'Ambulance', 'number': '102', 'icon': 'airport_shuttle', 'color': 'red'},
        {'id': 'police', 'name': 'Police', 'number': '100', 'icon': 'local_police', 'color': 'blue'},
        {'id': 'fire', 'name': 'Fire Dept', 'number': '101', 'icon': 'local_fire_department', 'color': 'orange'},
        {'id': 'poison', 'name': 'Poison Control', 'number': '1066', 'icon': 'warning', 'color': 'purple'},
    ]
    return jsonify(services)


@emergency_bp.route('/sos', methods=['POST'])
@jwt_required()
def trigger_sos():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    return jsonify({
        'message': 'SOS alert sent',
        'emergency_number': '102',
        'contacts_notified': True
    })


@emergency_bp.route('/triage', methods=['POST'])
@jwt_required()
def ai_triage():
    data = request.get_json()
    symptoms = data.get('symptoms', '')
    
    triage_result = {
        'urgency': 'moderate',
        'recommendation': 'Based on your symptoms, you should consult a healthcare provider soon. If symptoms worsen, call emergency services.',
        'suggested_service': 'ambulance',
        'call_number': '102'
    }
    
    if any(word in symptoms.lower() for word in ['chest pain', 'breathing', 'unconscious', 'severe bleeding']):
        triage_result['urgency'] = 'high'
        triage_result['recommendation'] = 'This sounds serious. Please call emergency services immediately.'
    
    return jsonify(triage_result)
