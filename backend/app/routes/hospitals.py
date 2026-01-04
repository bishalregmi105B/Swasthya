from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import (
    Hospital, Department, HospitalReview, HospitalService, 
    HospitalImage, HospitalMetric, User, Doctor
)
from sqlalchemy import or_, func

hospitals_bp = Blueprint('hospitals', __name__)


# ==================== HOSPITALS ====================

@hospitals_bp.route('', methods=['GET'])
def get_hospitals():
    """Get list of hospitals with filters"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    hospital_type = request.args.get('type')
    search = request.args.get('search')
    open_24h = request.args.get('open_24h')
    city = request.args.get('city')
    verified_only = request.args.get('verified')
    
    query = Hospital.query.filter_by(is_active=True)
    
    if hospital_type:
        query = query.filter(Hospital.type == hospital_type)
    
    if open_24h == 'true':
        query = query.filter(Hospital.is_open_24h == True)
    
    if verified_only == 'true':
        query = query.filter(Hospital.is_verified == True)
    
    if city:
        query = query.filter(Hospital.city.ilike(f'%{city}%'))
    
    if search:
        query = query.filter(
            or_(
                Hospital.name.ilike(f'%{search}%'),
                Hospital.city.ilike(f'%{search}%'),
                Hospital.specializations.ilike(f'%{search}%')
            )
        )
    
    query = query.order_by(Hospital.rating.desc())
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'hospitals': [h.to_dict() for h in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages,
        'current_page': page
    })


@hospitals_bp.route('/<int:hospital_id>', methods=['GET'])
def get_hospital(hospital_id):
    """Get detailed hospital information"""
    hospital = Hospital.query.get_or_404(hospital_id)
    include_details = request.args.get('details', 'true') == 'true'
    return jsonify(hospital.to_dict(include_details=include_details))


@hospitals_bp.route('/<int:hospital_id>/performance', methods=['GET'])
@hospitals_bp.route('/<int:hospital_id>/metrics', methods=['GET'])
def get_hospital_performance(hospital_id):
    """Get hospital performance metrics"""
    hospital = Hospital.query.get_or_404(hospital_id)
    
    # Get metrics from database or use defaults
    metrics = HospitalMetric.query.filter_by(hospital_id=hospital_id).all()
    if not metrics:
        metrics_data = [
            {'name': 'Hygiene & Safety', 'icon': 'sanitizer', 'score': 98},
            {'name': 'Treatment Success', 'icon': 'medical_services', 'score': 94},
            {'name': 'Advanced Technology', 'icon': 'memory', 'score': 85},
        ]
    else:
        metrics_data = [m.to_dict() for m in metrics]
    
    return jsonify({
        'hospital': hospital.to_dict(),
        'ai_trust_score': float(hospital.ai_trust_score) if hospital.ai_trust_score else 9.2,
        'avg_wait_time': hospital.avg_wait_time or 12,
        'satisfaction': float(hospital.rating) if hospital.rating else 4.8,
        'total_reviews': hospital.total_reviews or 0,
        'rank': hospital.rank or 4,
        'metrics': metrics_data
    })


# ==================== DEPARTMENTS ====================

@hospitals_bp.route('/<int:hospital_id>/departments', methods=['GET'])
def get_departments(hospital_id):
    """Get all departments for a hospital"""
    include_doctors = request.args.get('include_doctors', 'false') == 'true'
    departments = Department.query.filter_by(hospital_id=hospital_id).all()
    return jsonify([d.to_dict(include_doctors=include_doctors) for d in departments])


@hospitals_bp.route('/<int:hospital_id>/departments/<int:dept_id>', methods=['GET'])
def get_department(hospital_id, dept_id):
    """Get single department with doctors"""
    department = Department.query.filter_by(
        id=dept_id, hospital_id=hospital_id
    ).first_or_404()
    return jsonify(department.to_dict(include_doctors=True))


@hospitals_bp.route('/<int:hospital_id>/departments/<int:dept_id>/doctors', methods=['GET'])
def get_department_doctors(hospital_id, dept_id):
    """Get doctors in a specific department"""
    doctors = Doctor.query.filter_by(
        hospital_id=hospital_id, department_id=dept_id
    ).all()
    return jsonify([d.to_dict() for d in doctors])


# ==================== SERVICES ====================

@hospitals_bp.route('/<int:hospital_id>/services', methods=['GET'])
def get_services(hospital_id):
    """Get services offered by a hospital"""
    category = request.args.get('category')
    
    query = HospitalService.query.filter_by(hospital_id=hospital_id, is_available=True)
    
    if category:
        query = query.filter(HospitalService.category == category)
    
    services = query.all()
    return jsonify([s.to_dict() for s in services])


# ==================== GALLERY ====================

@hospitals_bp.route('/<int:hospital_id>/gallery', methods=['GET'])
def get_gallery(hospital_id):
    """Get hospital gallery images"""
    category = request.args.get('category')
    
    query = HospitalImage.query.filter_by(hospital_id=hospital_id)
    
    if category:
        query = query.filter(HospitalImage.category == category)
    
    images = query.order_by(HospitalImage.display_order).all()
    return jsonify([i.to_dict() for i in images])


# ==================== REVIEWS ====================

@hospitals_bp.route('/<int:hospital_id>/reviews', methods=['GET'])
def get_reviews(hospital_id):
    """Get hospital reviews with pagination"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    sort = request.args.get('sort', 'recent')  # recent, helpful, rating_high, rating_low
    
    query = HospitalReview.query.filter_by(hospital_id=hospital_id, is_visible=True)
    
    if sort == 'helpful':
        query = query.order_by(HospitalReview.helpful_count.desc())
    elif sort == 'rating_high':
        query = query.order_by(HospitalReview.rating.desc())
    elif sort == 'rating_low':
        query = query.order_by(HospitalReview.rating.asc())
    else:
        query = query.order_by(HospitalReview.created_at.desc())
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # Calculate rating distribution
    rating_stats = db.session.query(
        HospitalReview.rating,
        func.count(HospitalReview.id)
    ).filter_by(hospital_id=hospital_id, is_visible=True)\
     .group_by(HospitalReview.rating).all()
    
    rating_distribution = {str(i): 0 for i in range(1, 6)}
    for rating, count in rating_stats:
        rating_distribution[str(rating)] = count
    
    return jsonify({
        'reviews': [r.to_dict() for r in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages,
        'rating_distribution': rating_distribution
    })


@hospitals_bp.route('/<int:hospital_id>/reviews', methods=['POST'])
@jwt_required()
def create_review(hospital_id):
    """Submit a review for a hospital"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    if not data.get('rating'):
        return jsonify({'error': 'Rating is required'}), 400
    
    try:
        # Check if user already reviewed this hospital
        existing = HospitalReview.query.filter_by(
            hospital_id=hospital_id, user_id=user_id
        ).first()
        
        if existing:
            return jsonify({'error': 'You have already reviewed this hospital'}), 400
        
        # Create review with only basic fields that exist in original schema
        review = HospitalReview(
            hospital_id=hospital_id,
            user_id=user_id,
            rating=data.get('rating'),
            content=data.get('content', ''),
            tags=','.join(data.get('tags', [])) if data.get('tags') else None
        )
        
        # Try to add enhanced fields if they exist in schema
        try:
            if hasattr(review, 'title'):
                review.title = data.get('title')
            if hasattr(review, 'cleanliness_rating'):
                review.cleanliness_rating = data.get('cleanliness_rating')
            if hasattr(review, 'staff_rating'):
                review.staff_rating = data.get('staff_rating')
            if hasattr(review, 'facilities_rating'):
                review.facilities_rating = data.get('facilities_rating')
            if hasattr(review, 'wait_time_rating'):
                review.wait_time_rating = data.get('wait_time_rating')
            if hasattr(review, 'value_rating'):
                review.value_rating = data.get('value_rating')
        except Exception:
            pass  # Enhanced fields not available, continue with basic review
        
        db.session.add(review)
        
        # Update hospital rating
        hospital = Hospital.query.get(hospital_id)
        if hospital:
            avg_rating = db.session.query(func.avg(HospitalReview.rating))\
                .filter_by(hospital_id=hospital_id).scalar()
            count = db.session.query(func.count(HospitalReview.id))\
                .filter_by(hospital_id=hospital_id).scalar()
            hospital.rating = avg_rating or 0
            if hasattr(hospital, 'total_reviews'):
                hospital.total_reviews = count or 0
        
        db.session.commit()
        
        return jsonify({
            'message': 'Review submitted successfully',
            'review': review.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@hospitals_bp.route('/<int:hospital_id>/reviews/<int:review_id>/helpful', methods=['POST'])
@jwt_required()
def mark_review_helpful(hospital_id, review_id):
    """Mark a review as helpful"""
    review = HospitalReview.query.filter_by(
        id=review_id, hospital_id=hospital_id
    ).first_or_404()
    
    review.helpful_count = (review.helpful_count or 0) + 1
    db.session.commit()
    
    return jsonify({'message': 'Marked as helpful', 'helpful_count': review.helpful_count})


# ==================== DOCTORS ====================

@hospitals_bp.route('/<int:hospital_id>/doctors', methods=['GET'])
def get_hospital_doctors(hospital_id):
    """Get all doctors working at a hospital"""
    specialization = request.args.get('specialization')
    available_only = request.args.get('available') == 'true'
    
    query = Doctor.query.filter_by(hospital_id=hospital_id)
    
    if specialization:
        query = query.filter(Doctor.specialization == specialization)
    
    if available_only:
        query = query.filter(Doctor.is_available == True)
    
    doctors = query.order_by(Doctor.rating.desc()).all()
    return jsonify([d.to_dict() for d in doctors])


# ==================== NEARBY ====================

@hospitals_bp.route('/nearby', methods=['GET'])
def get_nearby_hospitals():
    """Get nearby hospitals (simplified - returns all for now)"""
    hospital_type = request.args.get('type')
    limit = request.args.get('limit', 20, type=int)
    
    query = Hospital.query.filter_by(is_active=True)
    
    if hospital_type:
        query = query.filter(Hospital.type == hospital_type)
    
    hospitals = query.order_by(Hospital.rating.desc()).limit(limit).all()
    return jsonify([h.to_dict() for h in hospitals])


# ==================== STATS ====================

@hospitals_bp.route('/stats', methods=['GET'])
def get_hospital_stats():
    """Get overall hospital statistics"""
    total = Hospital.query.filter_by(is_active=True).count()
    by_type = db.session.query(
        Hospital.type, func.count(Hospital.id)
    ).filter_by(is_active=True).group_by(Hospital.type).all()
    
    return jsonify({
        'total_hospitals': total,
        'by_type': {t: c for t, c in by_type},
        'verified_count': Hospital.query.filter_by(is_active=True, is_verified=True).count()
    })
