from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import HealthAlert, User

health_alerts_bp = Blueprint('health_alerts', __name__)


@health_alerts_bp.route('', methods=['GET'])
def get_alerts():
    city = request.args.get('city')
    province = request.args.get('province')
    severity = request.args.get('severity')
    
    query = HealthAlert.query.filter_by(is_active=True)
    
    if city:
        query = query.filter_by(affected_city=city)
    if province:
        query = query.filter_by(affected_province=province)
    if severity:
        query = query.filter_by(severity=severity)
    
    alerts = query.order_by(HealthAlert.updated_at.desc()).all()
    return jsonify([a.to_dict() for a in alerts])


@health_alerts_bp.route('/local', methods=['GET'])
@jwt_required()
def get_local_alerts():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    query = HealthAlert.query.filter_by(is_active=True)
    if user.city:
        query = query.filter_by(affected_city=user.city)
    
    alerts = query.order_by(HealthAlert.severity.desc()).limit(10).all()
    return jsonify([a.to_dict() for a in alerts])


@health_alerts_bp.route('/trending', methods=['GET'])
def get_trending():
    trending = HealthAlert.query.filter_by(is_active=True, trend='increasing')\
        .order_by(HealthAlert.cases_count.desc()).limit(5).all()
    return jsonify([a.to_dict() for a in trending])


@health_alerts_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_ai_summary():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    return jsonify({
        'risk_level': 'moderate',
        'title': 'Respiratory Alert Level Rising',
        'summary': f"Based on data from {user.city or 'your area'}, there's a moderate increase in respiratory infections. Stay hydrated and consider wearing a mask in crowded areas.",
        'updated_at': '2026-01-01T09:00:00'
    })


@health_alerts_bp.route('/critical', methods=['GET'])
def get_critical_alerts():
    critical = [
        {'id': 1, 'type': 'air_quality', 'title': 'Air Quality Alert', 'value': 'AQI 156', 'severity': 'high', 'icon': 'air'},
        {'id': 2, 'type': 'heat_wave', 'title': 'Heat Wave Warning', 'value': '38°C', 'severity': 'moderate', 'icon': 'thermostat'},
        {'id': 3, 'type': 'pollen', 'title': 'Pollen Alert', 'value': 'High', 'severity': 'moderate', 'icon': 'nature'},
    ]
    return jsonify(critical)
