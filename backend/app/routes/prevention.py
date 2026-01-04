from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import date
from app import db
from app.models import PreventionTip, DailyGoal, SimulationProgress

prevention_bp = Blueprint('prevention', __name__)


@prevention_bp.route('/tips', methods=['GET'])
def get_tips():
    category = request.args.get('category')
    
    query = PreventionTip.query
    if category:
        query = query.filter_by(category=category)
    
    tips = query.order_by(PreventionTip.created_at.desc()).all()
    return jsonify([t.to_dict() for t in tips])


@prevention_bp.route('/daily-insight', methods=['GET'])
def get_daily_insight():
    featured = PreventionTip.query.filter_by(is_featured=True).first()
    
    if not featured:
        return jsonify({
            'title': 'Boost Your Immunity',
            'category': 'Hydration',
            'content': 'Drinking 3L of water daily can significantly improve your body\'s natural defense mechanisms.',
            'is_medically_reviewed': True
        })
    
    return jsonify(featured.to_dict())


@prevention_bp.route('/goals', methods=['GET'])
@jwt_required()
def get_goals():
    user_id = get_jwt_identity()
    today = date.today()
    
    goals = DailyGoal.query.filter_by(user_id=user_id, date=today).all()
    
    if not goals:
        default_goals = [
            {'goal_type': 'hydration', 'title': 'Drink Water', 'target_value': '2000ml', 'icon': 'water_drop'},
            {'goal_type': 'supplement', 'title': 'Vitamin D', 'target_value': '1 Tablet (1000 IU)', 'icon': 'pill'},
            {'goal_type': 'sleep', 'title': 'Sleep Early', 'target_value': '10:30 PM', 'icon': 'bedtime'},
        ]
        return jsonify(default_goals)
    
    return jsonify([g.to_dict() for g in goals])


@prevention_bp.route('/goals/<int:goal_id>/toggle', methods=['POST'])
@jwt_required()
def toggle_goal(goal_id):
    user_id = get_jwt_identity()
    goal = DailyGoal.query.filter_by(id=goal_id, user_id=user_id).first_or_404()
    
    goal.is_completed = not goal.is_completed
    db.session.commit()
    
    return jsonify(goal.to_dict())


@prevention_bp.route('/categories', methods=['GET'])
def get_categories():
    categories = [
        {'id': 'for_you', 'name': 'For You'},
        {'id': 'viral', 'name': 'Viral'},
        {'id': 'hygiene', 'name': 'Hygiene'},
        {'id': 'nutrition', 'name': 'Nutrition'},
        {'id': 'mental', 'name': 'Mental'},
    ]
    return jsonify(categories)


@prevention_bp.route('/simulation/cpr', methods=['GET'])
def get_cpr_simulation():
    steps = [
        {'step': 1, 'title': 'Call for Help', 'instruction': 'Call 911 or ask someone to call'},
        {'step': 2, 'title': 'Check Responsiveness', 'instruction': 'Tap shoulders and ask "Are you okay?"'},
        {'step': 3, 'title': 'Open Airway', 'instruction': 'Tilt head back, lift chin'},
        {'step': 4, 'title': 'Begin Compressions', 'instruction': 'Push hard and fast at 100-120 per minute'},
        {'step': 5, 'title': 'Continue CPR', 'instruction': '30 compressions, 2 breaths, repeat'},
    ]
    return jsonify({
        'title': 'CPR Simulation',
        'total_steps': 5,
        'steps': steps,
        'target_rate_bpm': 110,
        'target_depth_inches': 2.0
    })


@prevention_bp.route('/simulation/cpr/progress', methods=['POST'])
@jwt_required()
def update_cpr_progress():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    progress = SimulationProgress.query.filter_by(
        user_id=user_id,
        simulation_type='cpr',
        is_completed=False
    ).first()
    
    if not progress:
        progress = SimulationProgress(
            user_id=user_id,
            simulation_type='cpr',
            total_steps=5
        )
        db.session.add(progress)
    
    progress.current_step = data.get('current_step', progress.current_step)
    progress.stats = data.get('stats', progress.stats)
    
    if progress.current_step >= progress.total_steps:
        progress.is_completed = True
    
    db.session.commit()
    
    return jsonify({
        'current_step': progress.current_step,
        'is_completed': progress.is_completed
    })
