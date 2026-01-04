from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token, jwt_required, 
    get_jwt_identity, get_jwt
)
from app import db
from app.models import User, Doctor, Hospital

auth_bp = Blueprint('auth', __name__)

# Valid provider roles that can access the web dashboard
PROVIDER_ROLES = ['doctor', 'hospital_admin', 'clinic_admin', 'pharmacy_admin', 'admin', 'super_admin']


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    required = ['email', 'password', 'full_name']
    if not all(k in data for k in required):
        return jsonify({'error': 'Missing required fields'}), 400
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already registered'}), 409
    
    # Get role from request, default to 'user' for mobile app users
    role = data.get('role', 'user')
    
    # Validate role
    valid_roles = ['user', 'doctor', 'hospital_admin', 'clinic_admin', 'pharmacy_admin']
    if role not in valid_roles:
        return jsonify({'error': f'Invalid role. Must be one of: {", ".join(valid_roles)}'}), 400
    
    try:
        # For hospital/clinic/pharmacy admins, create the facility first
        hospital_id = None
        if role in ['hospital_admin', 'clinic_admin', 'pharmacy_admin']:
            # Determine facility type
            if role == 'hospital_admin':
                facility_type = 'hospital'
            elif role == 'clinic_admin':
                facility_type = 'clinic'
            else:
                facility_type = 'pharmacy'
            
            # Create the hospital/clinic/pharmacy record
            hospital = Hospital(
                name=data.get('facility_name', data['full_name'] + "'s " + facility_type.capitalize()),
                type=facility_type,
                phone=data.get('phone'),
                email=data['email'],
                address=data.get('address'),
                city=data.get('city'),
                province=data.get('province'),
                is_active=True
            )
            db.session.add(hospital)
            db.session.flush()  # Get the ID before committing
            hospital_id = hospital.id
        
        # Create user
        user = User(
            email=data['email'],
            full_name=data['full_name'],
            phone=data.get('phone'),
            gender=data.get('gender'),
            blood_type=data.get('blood_type'),
            city=data.get('city'),
            province=data.get('province'),
            role=role,
            hospital_id=hospital_id
        )
        user.set_password(data['password'])
        db.session.add(user)
        db.session.flush()  # Get user ID
        
        # For doctors, create the doctor record
        if role == 'doctor':
            doctor = Doctor(
                user_id=user.id,
                license_number=data.get('license_number', f'TEMP-{user.id}'),
                specialization=data.get('specialization', 'physician'),
                experience_years=data.get('experience_years', 0),
                qualification=data.get('qualification', ''),
                consultation_fee=data.get('consultation_fee', 500),
                is_available=True,
                is_verified=False
            )
            db.session.add(doctor)
        
        db.session.commit()
        
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        
        response_data = {
            'message': 'Registration successful',
            'user': user.to_dict(),
            'access_token': access_token,
            'refresh_token': refresh_token
        }
        
        # Include entity info in response
        if role == 'doctor' and user.doctor:
            response_data['doctor'] = user.doctor.to_dict()
        if hospital_id:
            response_data['facility'] = Hospital.query.get(hospital_id).to_dict()
        
        return jsonify(response_data), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password required'}), 400
    
    user = User.query.filter_by(email=data['email']).first()
    
    if not user or not user.check_password(data['password']):
        return jsonify({'error': 'Invalid credentials'}), 401
    
    if not user.is_active:
        return jsonify({'error': 'Account is deactivated'}), 403
    
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    
    return jsonify({
        'message': 'Login successful',
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token
    })


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify({'access_token': access_token})


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    # Get additional info based on role
    user_data = user.to_dict()
    
    # If doctor, include doctor profile info
    if user.role == 'doctor' and user.doctor:
        user_data['doctor_profile'] = user.doctor.to_dict()
    
    # If facility admin, include facility info
    if user.role in ['hospital_admin', 'clinic_admin', 'pharmacy_admin'] and user.hospital:
        user_data['facility'] = user.hospital.to_dict()
    
    return jsonify(user_data)


@auth_bp.route('/me', methods=['PUT'])
@jwt_required()
def update_profile():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    data = request.get_json()
    
    updatable = ['full_name', 'phone', 'date_of_birth', 'gender', 'blood_type', 
                 'profile_image', 'address', 'city', 'province']
    
    for field in updatable:
        if field in data:
            setattr(user, field, data[field])
    
    db.session.commit()
    return jsonify(user.to_dict())


@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """Alias for /me endpoint for compatibility"""
    return get_current_user()


@auth_bp.route('/google', methods=['POST'])
def google_auth():
    """
    Authenticate with Google via Firebase.
    Receives user info directly from mobile app (Firebase already verified the user).
    """
    data = request.get_json()
    
    email = data.get('email')
    name = data.get('name', '')
    google_id = data.get('google_id')
    photo_url = data.get('photo_url', '')
    
    if not email:
        return jsonify({'error': 'Email is required'}), 400
    
    if not google_id:
        return jsonify({'error': 'Google ID is required'}), 400
    
    try:
        # Check if user exists by google_id
        user = User.query.filter_by(google_id=google_id).first()
        
        if not user:
            # Check if user exists by email (account linking)
            user = User.query.filter_by(email=email).first()
            
            if user:
                # Link existing email account with Google
                user.google_id = google_id
                if not user.profile_image and photo_url:
                    user.profile_image = photo_url
                if user.auth_provider == 'email':
                    user.auth_provider = 'google'
                db.session.commit()
            else:
                # Create new user - Google auth is typically for mobile (patient) users
                user = User(
                    email=email,
                    full_name=name or email.split('@')[0],
                    google_id=google_id,
                    auth_provider='google',
                    profile_image=photo_url,
                    role='user',  # Default to patient role for Google auth
                    is_verified=True,
                    is_active=True
                )
                db.session.add(user)
                db.session.commit()
        
        # Check if account is active
        if not user.is_active:
            return jsonify({'error': 'Account is deactivated'}), 403
        
        # Generate JWT tokens
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        
        return jsonify({
            'message': 'Google authentication successful',
            'user': user.to_dict(),
            'access_token': access_token,
            'refresh_token': refresh_token,
            'is_new_user': user.auth_provider == 'google' and not user.phone
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Authentication failed: {str(e)}'}), 500
