from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import Doctor, DoctorReview, User
from sqlalchemy import or_, func

doctors_bp = Blueprint('doctors', __name__)


@doctors_bp.route('', methods=['GET'])
def get_doctors():
    """Get list of doctors with filters"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    specialization = request.args.get('specialization')
    available = request.args.get('available')
    search = request.args.get('search')
    hospital_id = request.args.get('hospital_id', type=int)
    department_id = request.args.get('department_id', type=int)
    
    query = Doctor.query.join(User)
    
    if specialization:
        query = query.filter(Doctor.specialization == specialization)
    
    if available == 'true':
        query = query.filter(Doctor.is_available == True)
    
    if hospital_id:
        query = query.filter(Doctor.hospital_id == hospital_id)
    
    if department_id:
        query = query.filter(Doctor.department_id == department_id)
    
    if search:
        query = query.filter(
            or_(
                User.full_name.ilike(f'%{search}%'),
                Doctor.specialization.ilike(f'%{search}%'),
                Doctor.qualification.ilike(f'%{search}%')
            )
        )
    
    query = query.order_by(Doctor.rating.desc())
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'doctors': [d.to_dict() for d in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages,
        'current_page': page
    })


@doctors_bp.route('/<int:doctor_id>', methods=['GET'])
def get_doctor(doctor_id):
    """Get detailed doctor information"""
    doctor = Doctor.query.get_or_404(doctor_id)
    include_details = request.args.get('details', 'true') == 'true'
    data = doctor.to_dict(include_details=include_details)
    data['hospital'] = doctor.hospital.to_dict() if doctor.hospital else None
    data['department'] = doctor.department.to_dict() if doctor.department else None
    return jsonify(data)


@doctors_bp.route('/specializations', methods=['GET'])
def get_specializations():
    """Get list of available specializations"""
    specializations = [
        {'id': 'physician', 'name': 'General Physician AI', 'icon': 'stethoscope', 'color': 'blue',
         'description': 'For cold, flu, fever, and general health queries'},
        {'id': 'psychiatrist', 'name': 'Mental Health AI', 'icon': 'psychology', 'color': 'purple',
         'description': 'Anxiety, stress, depression, emotional well-being'},
        {'id': 'dermatologist', 'name': 'Dermatologist AI', 'icon': 'dermatology', 'color': 'pink',
         'description': 'Rashes, acne, skin infections, hair concerns'},
        {'id': 'pediatrician', 'name': 'Pediatrician AI', 'icon': 'child_care', 'color': 'yellow',
         'description': 'Infants, children, and adolescent health'},
        {'id': 'nutritionist', 'name': 'Nutrition & Diet AI', 'icon': 'nutrition', 'color': 'green',
         'description': 'Diet plans, weight management, nutritional advice'},
        {'id': 'cardiologist', 'name': 'Heart Health AI', 'icon': 'cardiology', 'color': 'red',
         'description': 'Blood pressure, heart rate, cardiovascular wellness'},
        {'id': 'neurologist', 'name': 'Neurologist AI', 'icon': 'neurology', 'color': 'indigo',
         'description': 'Headaches, seizures, and nervous system conditions'},
        {'id': 'orthopedic', 'name': 'Orthopedic AI', 'icon': 'bone', 'color': 'orange',
         'description': 'Bone, joint, and muscle issues'},
        {'id': 'gynecologist', 'name': 'Gynecologist AI', 'icon': 'pregnant_woman', 'color': 'teal',
         'description': "Women's health, pregnancy, and reproductive care"},
        {'id': 'dentist', 'name': 'Dentist AI', 'icon': 'dentistry', 'color': 'cyan',
         'description': 'Dental health, tooth pain, and oral care'},
    ]
    return jsonify(specializations)


@doctors_bp.route('/nearby', methods=['GET'])
def get_nearby_doctors():
    """Get nearby doctors"""
    specialization = request.args.get('specialization')
    limit = request.args.get('limit', 20, type=int)
    
    query = Doctor.query.filter(Doctor.is_available == True)
    
    if specialization:
        query = query.filter(Doctor.specialization == specialization)
    
    doctors = query.order_by(Doctor.rating.desc()).limit(limit).all()
    return jsonify([d.to_dict() for d in doctors])


@doctors_bp.route('/<int:doctor_id>/availability', methods=['GET'])
def get_availability(doctor_id):
    """Get doctor availability slots"""
    doctor = Doctor.query.get_or_404(doctor_id)
    
    # In production, this would query actual appointment slots
    available_slots = [
        {'date': '2026-01-02', 'times': ['09:00', '10:30', '14:00', '16:00']},
        {'date': '2026-01-03', 'times': ['09:00', '11:00', '15:00', '17:00']},
        {'date': '2026-01-04', 'times': ['10:00', '14:00', '16:30']},
        {'date': '2026-01-05', 'times': ['09:00', '11:30', '15:00']},
        {'date': '2026-01-06', 'times': ['10:00', '12:00', '14:30', '17:00']},
    ]
    
    return jsonify({
        'doctor_id': doctor_id,
        'available_days': doctor.available_days.split(',') if doctor.available_days else [],
        'avg_consultation_time': doctor.avg_consultation_time or 15,
        'slots': available_slots
    })


# ==================== REVIEWS ====================

@doctors_bp.route('/<int:doctor_id>/reviews', methods=['GET'])
def get_reviews(doctor_id):
    """Get doctor reviews with pagination"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    sort = request.args.get('sort', 'recent')
    
    query = DoctorReview.query.filter_by(doctor_id=doctor_id, is_visible=True)
    
    if sort == 'helpful':
        query = query.order_by(DoctorReview.helpful_count.desc())
    elif sort == 'rating_high':
        query = query.order_by(DoctorReview.rating.desc())
    elif sort == 'rating_low':
        query = query.order_by(DoctorReview.rating.asc())
    else:
        query = query.order_by(DoctorReview.created_at.desc())
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # Rating distribution
    rating_stats = db.session.query(
        DoctorReview.rating,
        func.count(DoctorReview.id)
    ).filter_by(doctor_id=doctor_id, is_visible=True)\
     .group_by(DoctorReview.rating).all()
    
    rating_distribution = {str(i): 0 for i in range(1, 6)}
    for rating, count in rating_stats:
        rating_distribution[str(rating)] = count
    
    return jsonify({
        'reviews': [r.to_dict() for r in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages,
        'rating_distribution': rating_distribution
    })


@doctors_bp.route('/<int:doctor_id>/reviews', methods=['POST'])
@jwt_required()
def create_review(doctor_id):
    """Submit a review for a doctor"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    # Check if user already reviewed this doctor
    existing = DoctorReview.query.filter_by(
        doctor_id=doctor_id, user_id=user_id
    ).first()
    
    if existing:
        return jsonify({'error': 'You have already reviewed this doctor'}), 400
    
    review = DoctorReview(
        doctor_id=doctor_id,
        user_id=user_id,
        appointment_id=data.get('appointment_id'),
        rating=data.get('rating'),
        title=data.get('title'),
        content=data.get('content'),
        punctuality_rating=data.get('punctuality_rating'),
        knowledge_rating=data.get('knowledge_rating'),
        bedside_manner_rating=data.get('bedside_manner_rating'),
        communication_rating=data.get('communication_rating'),
        would_recommend=data.get('would_recommend', True)
    )
    
    db.session.add(review)
    
    # Update doctor rating
    doctor = Doctor.query.get(doctor_id)
    if doctor:
        avg_rating = db.session.query(func.avg(DoctorReview.rating))\
            .filter_by(doctor_id=doctor_id, is_visible=True).scalar()
        count = db.session.query(func.count(DoctorReview.id))\
            .filter_by(doctor_id=doctor_id, is_visible=True).scalar()
        doctor.rating = avg_rating or 0
        doctor.total_reviews = count or 0
    
    db.session.commit()
    
    return jsonify({
        'message': 'Review submitted successfully',
        'review': review.to_dict()
    }), 201


@doctors_bp.route('/<int:doctor_id>/reviews/<int:review_id>/helpful', methods=['POST'])
@jwt_required()
def mark_review_helpful(doctor_id, review_id):
    """Mark a review as helpful"""
    review = DoctorReview.query.filter_by(
        id=review_id, doctor_id=doctor_id
    ).first_or_404()
    
    review.helpful_count = (review.helpful_count or 0) + 1
    db.session.commit()
    
    return jsonify({'message': 'Marked as helpful', 'helpful_count': review.helpful_count})


# ==================== HOSPITAL ADMIN ROUTES ====================

@doctors_bp.route('/my-hospital', methods=['GET'])
@jwt_required()
def get_my_hospital_doctors():
    """Get doctors for current user's hospital (hospital admin only)"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user or not user.hospital_id:
        return jsonify({'doctors': [], 'message': 'No hospital associated'}), 200
    
    if user.role not in ['hospital_admin', 'clinic_admin', 'admin', 'super_admin']:
        return jsonify({'error': 'Not authorized'}), 403
    
    doctors = Doctor.query.filter_by(hospital_id=user.hospital_id).all()
    return jsonify({
        'doctors': [d.to_dict() for d in doctors],
        'total': len(doctors)
    })


@doctors_bp.route('/applications', methods=['GET'])
@jwt_required()
def get_applications():
    """Get pending doctor applications for hospital admin"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user or not user.hospital_id:
        return jsonify({'applications': []}), 200
    
    if user.role not in ['hospital_admin', 'clinic_admin', 'admin', 'super_admin']:
        return jsonify({'error': 'Not authorized'}), 403
    
    # Find doctors who applied to this hospital (pending status)
    # In a real implementation, you'd have an application table
    # For now, return empty as this would need a separate model
    return jsonify({'applications': []})


@doctors_bp.route('/<int:doctor_id>/approve', methods=['POST'])
@jwt_required()
def approve_doctor(doctor_id):
    """Approve a doctor's application to join hospital"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user or not user.hospital_id:
        return jsonify({'error': 'No hospital associated'}), 400
    
    if user.role not in ['hospital_admin', 'clinic_admin', 'admin', 'super_admin']:
        return jsonify({'error': 'Not authorized'}), 403
    
    doctor = Doctor.query.get_or_404(doctor_id)
    doctor.hospital_id = user.hospital_id
    db.session.commit()
    
    return jsonify({'message': 'Doctor approved', 'doctor': doctor.to_dict()})


@doctors_bp.route('/<int:doctor_id>/reject', methods=['POST'])
@jwt_required()
def reject_doctor(doctor_id):
    """Reject a doctor's application"""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if user.role not in ['hospital_admin', 'clinic_admin', 'admin', 'super_admin']:
        return jsonify({'error': 'Not authorized'}), 403
    
    # In a real implementation, this would update the application status
    return jsonify({'message': 'Application rejected'})


# ==================== STATS ====================

@doctors_bp.route('/stats', methods=['GET'])
def get_doctor_stats():
    """Get overall doctor statistics"""
    total = Doctor.query.count()
    by_specialization = db.session.query(
        Doctor.specialization, func.count(Doctor.id)
    ).group_by(Doctor.specialization).all()
    
    return jsonify({
        'total_doctors': total,
        'by_specialization': {s: c for s, c in by_specialization},
        'verified_count': Doctor.query.filter_by(is_verified=True).count(),
        'available_count': Doctor.query.filter_by(is_available=True).count()
    })
