"""
Simulation API Routes
Endpoints for medical simulations (CPR, First Aid, etc.) with bilingual support
"""

from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from app import db
from app.models.simulation import Simulation, SimulationStep, UserSimulationProgress

simulations_bp = Blueprint('simulations', __name__, url_prefix='/api/simulations')


# Animation URLs from LottieFiles CDN
ANIMATIONS = {
    'heartbeat': 'https://assets2.lottiefiles.com/packages/lf20_M9p23l.json',
    'phone': 'https://assets10.lottiefiles.com/packages/lf20_dhcsd5b5.json',
    'hand': 'https://assets9.lottiefiles.com/packages/lf20_oyi9a28g.json',
    'heart': 'https://assets4.lottiefiles.com/packages/lf20_xvz4fv5t.json',
    'success': 'https://assets4.lottiefiles.com/packages/lf20_jbrw3hcz.json',
    'warning': 'https://assets9.lottiefiles.com/packages/lf20_vqvesrnu.json',
    'medical': 'https://assets8.lottiefiles.com/packages/lf20_pk5mpw6l.json',
    'wash': 'https://assets3.lottiefiles.com/packages/lf20_kxn0b8nm.json',
    'water': 'https://assets8.lottiefiles.com/packages/lf20_k8vldxuk.json',
    'hospital': 'https://assets4.lottiefiles.com/packages/lf20_5njp3vgg.json',
    'help': 'https://assets9.lottiefiles.com/packages/lf20_xlmz9xwm.json',
    'person': 'https://assets3.lottiefiles.com/packages/lf20_v1yudlrx.json',
}


@simulations_bp.route('', methods=['GET'])
def get_simulations():
    """Get all available simulations"""
    category = request.args.get('category')
    lang = request.args.get('lang', 'en')
    
    query = Simulation.query.filter_by(is_active=True)
    
    if category:
        query = query.filter_by(category=category)
    
    simulations = query.order_by(Simulation.order_index, Simulation.title).all()
    
    return jsonify({
        'simulations': [s.to_dict(lang=lang) for s in simulations],
        'categories': get_categories()
    })


@simulations_bp.route('/featured', methods=['GET'])
def get_featured_simulations():
    """Get featured simulations for home screen"""
    lang = request.args.get('lang', 'en')
    simulations = Simulation.query.filter_by(
        is_active=True,
        is_featured=True
    ).order_by(Simulation.order_index).limit(6).all()
    
    return jsonify({
        'simulations': [s.to_dict(lang=lang) for s in simulations]
    })


@simulations_bp.route('/<slug>', methods=['GET'])
def get_simulation(slug):
    """Get simulation details with all steps"""
    lang = request.args.get('lang', 'en')
    simulation = Simulation.query.filter_by(slug=slug, is_active=True).first()
    
    if not simulation:
        return jsonify({'error': 'Simulation not found'}), 404
    
    return jsonify({
        'simulation': simulation.to_dict(include_steps=True, lang=lang)
    })


@simulations_bp.route('/<int:sim_id>/start', methods=['POST'])
@jwt_required()
def start_simulation(sim_id):
    """Start or resume a simulation (track progress)"""
    user_id = get_jwt_identity()
    lang = request.args.get('lang', 'en')
    
    simulation = Simulation.query.get(sim_id)
    if not simulation:
        return jsonify({'error': 'Simulation not found'}), 404
    
    progress = UserSimulationProgress.query.filter_by(
        user_id=user_id,
        simulation_id=sim_id
    ).first()
    
    if not progress:
        progress = UserSimulationProgress(
            user_id=user_id,
            simulation_id=sim_id,
            current_step=1
        )
        db.session.add(progress)
    else:
        if progress.completed:
            progress.current_step = 1
            progress.completed = False
            progress.attempts += 1
    
    db.session.commit()
    
    return jsonify({
        'simulation': simulation.to_dict(include_steps=True, lang=lang),
        'progress': progress.to_dict()
    })


@simulations_bp.route('/<int:sim_id>/step', methods=['POST'])
@jwt_required()
def update_step(sim_id):
    """Update user's current step in simulation"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    progress = UserSimulationProgress.query.filter_by(
        user_id=user_id,
        simulation_id=sim_id
    ).first()
    
    if not progress:
        return jsonify({'error': 'Simulation not started'}), 400
    
    progress.current_step = data.get('step', progress.current_step)
    
    simulation = Simulation.query.get(sim_id)
    if progress.current_step > simulation.total_steps:
        progress.completed = True
        progress.completed_at = db.func.now()
        progress.score = data.get('score', 80)
    
    db.session.commit()
    
    return jsonify({'progress': progress.to_dict()})


@simulations_bp.route('/progress', methods=['GET'])
@jwt_required()
def get_user_progress():
    """Get user's simulation progress"""
    user_id = get_jwt_identity()
    progress_records = UserSimulationProgress.query.filter_by(user_id=user_id).all()
    return jsonify({'progress': [p.to_dict() for p in progress_records]})


def get_categories():
    """Get unique simulation categories"""
    categories = db.session.query(Simulation.category).filter(
        Simulation.is_active == True
    ).distinct().all()
    
    category_labels = {
        'cpr': {'name': 'CPR', 'icon': 'favorite', 'color': '#ef4444'},
        'choking': {'name': 'Choking', 'icon': 'emergency', 'color': '#f97316'},
        'first_aid': {'name': 'First Aid', 'icon': 'healing', 'color': '#22c55e'},
        'emergency': {'name': 'Emergency', 'icon': 'local_hospital', 'color': '#3b82f6'}
    }
    
    return [
        {**category_labels.get(c[0], {'name': c[0], 'icon': 'info', 'color': '#6b7280'}), 'slug': c[0]}
        for c in categories if c[0]
    ]


# ==================== SEED DATA ====================

def seed_simulations():
    """Seed all simulations with bilingual content and steps"""
    
    simulations_data = [
        # ========== ADULT CPR ==========
        {
            'title': 'Adult CPR',
            'title_ne': 'वयस्क सीपीआर',
            'slug': 'adult-cpr',
            'description': 'Learn hands-only CPR for adults. Proper technique saves lives.',
            'description_ne': 'वयस्कहरूको लागि सीपीआर सिक्नुहोस्।',
            'category': 'cpr',
            'icon': 'favorite',
            'color': '#ef4444',
            'difficulty': 'beginner',
            'duration_minutes': 10,
            'total_steps': 5,
            'is_featured': True,
            'order_index': 1,
            'steps': [
                {
                    'step_number': 1,
                    'title': 'Check Responsiveness',
                    'title_ne': 'प्रतिक्रिया जाँच',
                    'instruction': 'Tap shoulders and shout "Are you okay?"',
                    'instruction_ne': 'काँधमा थिच्नुहोस् र "के तपाईं ठीक हुनुहुन्छ?" भन्नुहोस्',
                    'voice_text': 'Step 1. Check responsiveness. Tap the person\'s shoulder and shout: Are you okay?',
                    'voice_text_ne': 'चरण १। प्रतिक्रिया जाँच गर्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['help'],
                },
                {
                    'step_number': 2,
                    'title': 'Call 102',
                    'title_ne': '१०२ मा फोन',
                    'instruction': 'Call emergency services immediately',
                    'instruction_ne': 'तुरुन्तै आपतकालीन सेवामा फोन गर्नुहोस्',
                    'voice_text': 'Step 2. Call 102 emergency services immediately.',
                    'voice_text_ne': 'चरण २। तुरुन्तै १०२ मा फोन गर्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['phone'],
                },
                {
                    'step_number': 3,
                    'title': 'Hand Position',
                    'title_ne': 'हातको स्थिति',
                    'instruction': 'Place heel of hand on center of chest',
                    'instruction_ne': 'छातीको बीचमा हातको गोलो भाग राख्नुहोस्',
                    'voice_text': 'Step 3. Position hands on center of chest.',
                    'voice_text_ne': 'चरण ३। छातीको बीचमा हात राख्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['hand'],
                },
                {
                    'step_number': 4,
                    'title': '30 Compressions',
                    'title_ne': '३० थिचाइ',
                    'instruction': 'Push hard & fast! TAP to count compressions.',
                    'instruction_ne': 'बलियो र छिटो थिच्नुहोस्! गन्तीको लागि ट्याप गर्नुहोस्।',
                    'voice_text': 'Step 4. Begin compressions. Push hard at 100 to 120 per minute.',
                    'voice_text_ne': 'चरण ४। थिच्न सुरु गर्नुहोस्।',
                    'step_type': 'compress',
                    'target_value': 30,
                    'target_rate': 110,
                    'animation_url': ANIMATIONS['heart'],
                    'ai_feedback_good': 'Great rhythm!',
                    'ai_feedback_good_ne': 'राम्रो गति!',
                    'ai_feedback_adjust': 'Push faster!',
                    'ai_feedback_adjust_ne': 'छिटो थिच्नुहोस्!',
                },
                {
                    'step_number': 5,
                    'title': 'Continue CPR',
                    'title_ne': 'जारी राख्नुहोस्',
                    'instruction': 'Keep going until help arrives!',
                    'instruction_ne': 'मद्दत नआउञ्जेल जारी राख्नुहोस्!',
                    'voice_text': 'Continue until emergency services arrive. Great job!',
                    'voice_text_ne': 'आपतकालीन सेवा आउञ्जेल जारी राख्नुहोस्। राम्रो काम!',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['success'],
                },
            ]
        },
        
        # ========== CHOKING ==========
        {
            'title': 'Choking (Heimlich)',
            'title_ne': 'गला अड्कदा (हेमलिक)',
            'slug': 'choking-adult',
            'description': 'Learn the Heimlich maneuver for choking adults.',
            'description_ne': 'गला अड्किएकोमा हेमलिक प्रविधि सिक्नुहोस्।',
            'category': 'choking',
            'icon': 'emergency',
            'color': '#f97316',
            'difficulty': 'beginner',
            'duration_minutes': 8,
            'total_steps': 5,
            'is_featured': True,
            'order_index': 2,
            'steps': [
                {
                    'step_number': 1,
                    'title': 'Identify Choking',
                    'title_ne': 'पहिचान',
                    'instruction': 'Ask "Are you choking?" Look for universal sign.',
                    'instruction_ne': '"के गला अड्कियो?" सोध्नुहोस्।',
                    'voice_text': 'Step 1. Identify choking. Ask: Are you choking?',
                    'voice_text_ne': 'चरण १। गला अड्किएको पहिचान गर्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['warning'],
                },
                {
                    'step_number': 2,
                    'title': 'Call for Help',
                    'title_ne': 'मद्दत माग्नुहोस्',
                    'instruction': 'Have someone call 102',
                    'instruction_ne': 'कसैलाई १०२ मा फोन गर्न लगाउनुहोस्',
                    'voice_text': 'Step 2. Have someone call 102 while you help.',
                    'voice_text_ne': 'चरण २। कसैलाई १०२ मा फोन गर्न लगाउनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['phone'],
                },
                {
                    'step_number': 3,
                    'title': 'Stand Behind',
                    'title_ne': 'पछाडि उभिनुहोस्',
                    'instruction': 'Wrap arms around their waist',
                    'instruction_ne': 'कम्मरमा हात बेर्नुहोस्',
                    'voice_text': 'Step 3. Stand behind. Wrap arms around waist.',
                    'voice_text_ne': 'चरण ३। पछाडि उभिनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['person'],
                },
                {
                    'step_number': 4,
                    'title': '5 Thrusts',
                    'title_ne': '५ थ्रस्ट',
                    'instruction': 'Fist above navel, thrust inward & upward. TAP!',
                    'instruction_ne': 'नाभि माथि मुट्ठी, भित्र र माथि थिच्नुहोस्।',
                    'voice_text': 'Step 4. Make a fist above navel. Thrust inward and upward.',
                    'voice_text_ne': 'चरण ४। नाभि माथि मुट्ठी बनाउनुहोस्।',
                    'step_type': 'compress',
                    'target_value': 5,
                    'animation_url': ANIMATIONS['warning'],
                    'ai_feedback_good': 'Good thrust!',
                    'ai_feedback_good_ne': 'राम्रो!',
                },
                {
                    'step_number': 5,
                    'title': 'Repeat',
                    'title_ne': 'दोहोर्याउनुहोस्',
                    'instruction': 'Continue until object is dislodged',
                    'instruction_ne': 'वस्तु निस्कने सम्म जारी राख्नुहोस्',
                    'voice_text': 'Continue until object is dislodged. Well done!',
                    'voice_text_ne': 'राम्रो काम!',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['success'],
                },
            ]
        },
        
        # ========== WOUND CARE ==========
        {
            'title': 'Wound Care',
            'title_ne': 'घाउ उपचार',
            'slug': 'wound-care',
            'description': 'Basic wound cleaning and bandaging.',
            'description_ne': 'घाउ सफा गर्ने र पट्टी बाँध्ने।',
            'category': 'first_aid',
            'icon': 'healing',
            'color': '#22c55e',
            'difficulty': 'beginner',
            'duration_minutes': 6,
            'total_steps': 5,
            'is_featured': True,
            'order_index': 3,
            'steps': [
                {
                    'step_number': 1,
                    'title': 'Wash Hands',
                    'title_ne': 'हात धुनुहोस्',
                    'instruction': 'Clean hands with soap first',
                    'instruction_ne': 'पहिले साबुनले हात धुनुहोस्',
                    'voice_text': 'Step 1. Wash your hands thoroughly.',
                    'voice_text_ne': 'चरण १। साबुनले हात धुनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['wash'],
                },
                {
                    'step_number': 2,
                    'title': 'Stop Bleeding',
                    'title_ne': 'रगत रोक्नुहोस्',
                    'instruction': 'Apply pressure with clean cloth',
                    'instruction_ne': 'सफा कपडाले दबाब दिनुहोस्',
                    'voice_text': 'Step 2. Apply firm pressure for 5 to 10 minutes.',
                    'voice_text_ne': 'चरण २। दबाब दिनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['medical'],
                },
                {
                    'step_number': 3,
                    'title': 'Clean Wound',
                    'title_ne': 'घाउ सफा',
                    'instruction': 'Rinse with clean water',
                    'instruction_ne': 'सफा पानीले धुनुहोस्',
                    'voice_text': 'Step 3. Rinse wound with clean water.',
                    'voice_text_ne': 'चरण ३। पानीले धुनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['water'],
                },
                {
                    'step_number': 4,
                    'title': 'Apply Antiseptic',
                    'title_ne': 'एन्टिसेप्टिक',
                    'instruction': 'Apply antiseptic ointment',
                    'instruction_ne': 'एन्टिसेप्टिक लगाउनुहोस्',
                    'voice_text': 'Step 4. Apply antiseptic.',
                    'voice_text_ne': 'चरण ४। एन्टिसेप्टिक लगाउनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['medical'],
                },
                {
                    'step_number': 5,
                    'title': 'Bandage',
                    'title_ne': 'पट्टी',
                    'instruction': 'Cover with sterile bandage',
                    'instruction_ne': 'पट्टीले छोप्नुहोस्',
                    'voice_text': 'Step 5. Cover with bandage. Great job!',
                    'voice_text_ne': 'चरण ५। पट्टीले छोप्नुहोस्। राम्रो काम!',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['success'],
                },
            ]
        },
        
        # ========== BURN TREATMENT ==========
        {
            'title': 'Burn Treatment',
            'title_ne': 'जलेको उपचार',
            'slug': 'burn-treatment',
            'description': 'First aid for minor burns.',
            'description_ne': 'सानो जलेकोको उपचार।',
            'category': 'first_aid',
            'icon': 'local_fire_department',
            'color': '#f59e0b',
            'difficulty': 'beginner',
            'duration_minutes': 5,
            'total_steps': 5,
            'is_featured': True,
            'order_index': 4,
            'steps': [
                {
                    'step_number': 1,
                    'title': 'Cool the Burn',
                    'title_ne': 'चिसो पार्नुहोस्',
                    'instruction': 'Run cool water for 10-20 minutes',
                    'instruction_ne': '१०-२० मिनेट चिसो पानी हाल्नुहोस्',
                    'voice_text': 'Step 1. Cool burn with cool water 10 to 20 minutes.',
                    'voice_text_ne': 'चरण १। चिसो पार्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['water'],
                },
                {
                    'step_number': 2,
                    'title': 'Remove Jewelry',
                    'title_ne': 'गहना हटाउनुहोस्',
                    'instruction': 'Remove rings, watches before swelling',
                    'instruction_ne': 'सुन्निनु अघि गहना हटाउनुहोस्',
                    'voice_text': 'Step 2. Remove jewelry before swelling.',
                    'voice_text_ne': 'चरण २। गहना हटाउनुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['warning'],
                },
                {
                    'step_number': 3,
                    'title': 'Cover Burn',
                    'title_ne': 'छोप्नुहोस्',
                    'instruction': 'Use sterile, non-fluffy bandage',
                    'instruction_ne': 'निर्जीवित पट्टी प्रयोग गर्नुहोस्',
                    'voice_text': 'Step 3. Cover with sterile bandage.',
                    'voice_text_ne': 'चरण ३। पट्टीले छोप्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['medical'],
                },
                {
                    'step_number': 4,
                    'title': "Don't Pop Blisters",
                    'title_ne': 'फोका नफोर्नुहोस्',
                    'instruction': 'Blisters protect against infection',
                    'instruction_ne': 'फोकाले संक्रमणबाट जोगाउँछ',
                    'voice_text': 'Step 4. Do not pop blisters.',
                    'voice_text_ne': 'चरण ४। फोका नफोर्नुहोस्।',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['warning'],
                },
                {
                    'step_number': 5,
                    'title': 'Seek Help',
                    'title_ne': 'मद्दत',
                    'instruction': 'Serious burns need hospital care',
                    'instruction_ne': 'गम्भीर जलेकोमा अस्पताल जानुहोस्',
                    'voice_text': 'For serious burns, seek medical help. Great job!',
                    'voice_text_ne': 'गम्भीर जलेकोमा अस्पताल जानुहोस्। राम्रो काम!',
                    'step_type': 'info',
                    'animation_url': ANIMATIONS['hospital'],
                },
            ]
        },
    ]
    
    for sim_data in simulations_data:
        existing = Simulation.query.filter_by(slug=sim_data['slug']).first()
        if existing:
            # Update existing
            for key, val in sim_data.items():
                if key != 'steps':
                    setattr(existing, key, val)
            # Delete old steps and add new
            SimulationStep.query.filter_by(simulation_id=existing.id).delete()
            for step_data in sim_data.get('steps', []):
                step = SimulationStep(simulation_id=existing.id, **step_data)
                db.session.add(step)
        else:
            # Create new
            steps = sim_data.pop('steps', [])
            sim = Simulation(**sim_data)
            db.session.add(sim)
            db.session.flush()
            for step_data in steps:
                step = SimulationStep(simulation_id=sim.id, **step_data)
                db.session.add(step)
    
    db.session.commit()
    print("✓ Simulations seeded with bilingual content")
