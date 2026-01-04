from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import BloodBank, User

blood_banks_bp = Blueprint('blood_banks', __name__)


@blood_banks_bp.route('', methods=['GET'])
def get_blood_banks():
    bank_type = request.args.get('type')
    city = request.args.get('city')
    blood_type = request.args.get('blood_type')
    is_open = request.args.get('is_open')
    
    query = BloodBank.query
    
    if bank_type:
        query = query.filter_by(type=bank_type)
    if city:
        query = query.filter_by(city=city)
    if is_open == 'true':
        query = query.filter_by(is_open=True)
    
    banks = query.order_by(BloodBank.rating.desc()).all()
    return jsonify([b.to_dict() for b in banks])


@blood_banks_bp.route('/<int:bank_id>', methods=['GET'])
def get_blood_bank(bank_id):
    bank = BloodBank.query.get_or_404(bank_id)
    return jsonify(bank.to_dict())


@blood_banks_bp.route('/nearby', methods=['GET'])
@jwt_required()
def get_nearby():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    banks = BloodBank.query.filter_by(is_open=True).limit(10).all()
    return jsonify([b.to_dict() for b in banks])


@blood_banks_bp.route('/recommendation', methods=['GET'])
@jwt_required()
def get_recommendation():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    bank = BloodBank.query.filter_by(is_open=True).order_by(BloodBank.rating.desc()).first()
    
    if not bank:
        return jsonify({'message': 'No blood banks available'})
    
    return jsonify({
        'recommendation': bank.to_dict(),
        'message': f"Based on your location and {user.blood_type or 'O+'} blood type, {bank.name} is the nearest open center.",
        'blood_type': user.blood_type or 'O+'
    })
