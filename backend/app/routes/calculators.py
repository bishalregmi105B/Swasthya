from flask import Blueprint, request, jsonify
import math

calculators_bp = Blueprint('calculators', __name__)


@calculators_bp.route('/bmi', methods=['POST'])
def calculate_bmi():
    data = request.get_json()
    
    weight = data.get('weight')
    height = data.get('height')
    unit = data.get('unit', 'metric')
    
    if not weight or not height:
        return jsonify({'error': 'Weight and height required'}), 400
    
    if unit == 'imperial':
        height_m = height * 0.0254
        weight_kg = weight * 0.453592
    else:
        height_m = height / 100
        weight_kg = weight
    
    bmi = weight_kg / (height_m ** 2)
    
    if bmi < 18.5:
        category = 'Underweight'
        color = 'blue'
    elif bmi < 25:
        category = 'Normal'
        color = 'green'
    elif bmi < 30:
        category = 'Overweight'
        color = 'yellow'
    else:
        category = 'Obese'
        color = 'red'
    
    return jsonify({
        'bmi': round(bmi, 1),
        'category': category,
        'color': color,
        'healthy_range': '18.5 - 24.9'
    })


@calculators_bp.route('/ibw', methods=['POST'])
def calculate_ibw():
    data = request.get_json()
    
    height = data.get('height')
    gender = data.get('gender', 'male')
    formula = data.get('formula', 'robinson')
    unit = data.get('unit', 'metric')
    
    if not height:
        return jsonify({'error': 'Height required'}), 400
    
    if unit == 'imperial':
        height_in = height
    else:
        height_in = height / 2.54
    
    inches_over_5ft = height_in - 60
    
    if formula == 'robinson':
        if gender == 'male':
            ibw = 52 + 1.9 * inches_over_5ft
        else:
            ibw = 49 + 1.7 * inches_over_5ft
    elif formula == 'devine':
        if gender == 'male':
            ibw = 50 + 2.3 * inches_over_5ft
        else:
            ibw = 45.5 + 2.3 * inches_over_5ft
    else:
        if gender == 'male':
            ibw = 48 + 2.7 * inches_over_5ft
        else:
            ibw = 45.5 + 2.2 * inches_over_5ft
    
    return jsonify({
        'ideal_weight_kg': round(ibw, 1),
        'ideal_weight_lb': round(ibw * 2.205, 1),
        'formula': formula,
        'healthy_range_kg': f"{round(ibw * 0.9, 1)} - {round(ibw * 1.1, 1)}"
    })


@calculators_bp.route('/heart-rate', methods=['POST'])
def calculate_heart_rate():
    data = request.get_json()
    
    age = data.get('age')
    resting_hr = data.get('resting_hr', 70)
    
    if not age:
        return jsonify({'error': 'Age required'}), 400
    
    max_hr = 220 - age
    
    target_zones = {
        'fat_burn': {'min': int(max_hr * 0.5), 'max': int(max_hr * 0.6)},
        'cardio': {'min': int(max_hr * 0.6), 'max': int(max_hr * 0.7)},
        'peak': {'min': int(max_hr * 0.7), 'max': int(max_hr * 0.85)},
    }
    
    hrr = max_hr - resting_hr
    target_50 = int(hrr * 0.5 + resting_hr)
    target_70 = int(hrr * 0.7 + resting_hr)
    
    return jsonify({
        'max_heart_rate': max_hr,
        'target_zones': target_zones,
        'karvonen_target': {'min': target_50, 'max': target_70}
    })


@calculators_bp.route('/blood-volume', methods=['POST'])
def calculate_blood_volume():
    data = request.get_json()
    
    weight = data.get('weight')
    height = data.get('height')
    gender = data.get('gender', 'male')
    
    if not weight or not height:
        return jsonify({'error': 'Weight and height required'}), 400
    
    height_m = height / 100
    
    if gender == 'male':
        blood_volume = 0.3669 * (height_m ** 3) + 0.03219 * weight + 0.6041
    else:
        blood_volume = 0.3561 * (height_m ** 3) + 0.03308 * weight + 0.1833
    
    blood_volume_ml = blood_volume * 1000
    
    return jsonify({
        'blood_volume_liters': round(blood_volume, 2),
        'blood_volume_ml': round(blood_volume_ml),
        'formula': 'Nadler equation'
    })


@calculators_bp.route('/all', methods=['GET'])
def get_all_calculators():
    calculators = [
        {'id': 'bmi', 'name': 'BMI Calculator', 'icon': 'monitor_weight', 'description': 'Body Mass Index'},
        {'id': 'ibw', 'name': 'Ideal Body Weight', 'icon': 'accessibility_new', 'description': 'Robinson Formula'},
        {'id': 'heart_rate', 'name': 'Target Heart Rate', 'icon': 'favorite', 'description': 'Karvonen Method'},
        {'id': 'blood_volume', 'name': 'Blood Volume', 'icon': 'bloodtype', 'description': 'Nadler Equation'},
    ]
    return jsonify(calculators)
