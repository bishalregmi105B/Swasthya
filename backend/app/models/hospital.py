from datetime import datetime
from app import db


class Hospital(db.Model):
    __tablename__ = 'hospitals'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    type = db.Column(db.Enum('hospital', 'clinic', 'pharmacy'), nullable=False)
    description = db.Column(db.Text)
    address = db.Column(db.Text)
    city = db.Column(db.String(100))
    province = db.Column(db.String(100))
    country = db.Column(db.String(100), default='Nepal')
    postal_code = db.Column(db.String(20))
    latitude = db.Column(db.Numeric(10, 8))
    longitude = db.Column(db.Numeric(11, 8))
    
    # Contact Information
    phone = db.Column(db.String(20))
    phone_secondary = db.Column(db.String(20))
    emergency_phone = db.Column(db.String(20))
    email = db.Column(db.String(255))
    website = db.Column(db.String(255))
    
    # Social Links
    facebook_url = db.Column(db.String(255))
    twitter_url = db.Column(db.String(255))
    instagram_url = db.Column(db.String(255))
    linkedin_url = db.Column(db.String(255))
    youtube_url = db.Column(db.String(255))
    
    # Images
    image_url = db.Column(db.Text)  # Main/cover image
    logo_url = db.Column(db.Text)
    banner_url = db.Column(db.Text)
    
    # Capacity & Facilities
    total_beds = db.Column(db.Integer)
    icu_beds = db.Column(db.Integer)
    ventilators = db.Column(db.Integer)
    operation_theaters = db.Column(db.Integer)
    ambulances = db.Column(db.Integer)
    parking_available = db.Column(db.Boolean, default=True)
    wheelchair_accessible = db.Column(db.Boolean, default=True)
    
    # Ratings & Stats
    rating = db.Column(db.Numeric(3, 2), default=0)
    total_reviews = db.Column(db.Integer, default=0)
    ai_trust_score = db.Column(db.Numeric(3, 1))
    avg_wait_time = db.Column(db.Integer)  # in minutes
    rank = db.Column(db.Integer)
    
    # Operational Info
    emergency_available = db.Column(db.Boolean, default=True)
    is_open_24h = db.Column(db.Boolean, default=False)
    opening_hours = db.Column(db.Text)  # JSON format
    established_year = db.Column(db.Integer)
    
    # Specializations & Features
    specializations = db.Column(db.Text)  # Comma-separated
    features = db.Column(db.Text)  # Comma-separated: wifi, cafeteria, pharmacy, lab, etc.
    insurance_accepted = db.Column(db.Text)  # Comma-separated insurance names
    payment_methods = db.Column(db.Text)  # Comma-separated: cash, card, esewa, khalti
    
    # Status
    is_verified = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    doctors = db.relationship('Doctor', backref='hospital')
    departments = db.relationship('Department', backref='hospital', lazy='dynamic')
    metrics = db.relationship('HospitalMetric', backref='hospital')
    reviews = db.relationship('HospitalReview', backref='hospital', lazy='dynamic')
    services = db.relationship('HospitalService', backref='hospital', lazy='dynamic')
    gallery = db.relationship('HospitalImage', backref='hospital', lazy='dynamic')
    
    def to_dict(self, include_details=False):
        data = {
            'id': self.id,
            'name': self.name,
            'type': self.type,
            'description': self.description,
            'address': self.address,
            'city': self.city,
            'province': self.province,
            'latitude': float(self.latitude) if self.latitude else None,
            'longitude': float(self.longitude) if self.longitude else None,
            'phone': self.phone,
            'email': self.email,
            'website': self.website,
            'image_url': self.image_url,
            'logo_url': self.logo_url,
            'rating': float(self.rating) if self.rating else 0,
            'total_reviews': self.total_reviews or 0,
            'total_beds': self.total_beds,
            'emergency_available': self.emergency_available,
            'is_open_24h': self.is_open_24h,
            'is_verified': self.is_verified,
            'ai_trust_score': float(self.ai_trust_score) if self.ai_trust_score else None,
            'avg_wait_time': self.avg_wait_time,
            'rank': self.rank
        }
        
        if include_details:
            data.update({
                'phone_secondary': self.phone_secondary,
                'emergency_phone': self.emergency_phone,
                'facebook_url': self.facebook_url,
                'instagram_url': self.instagram_url,
                'twitter_url': self.twitter_url,
                'icu_beds': self.icu_beds,
                'ventilators': self.ventilators,
                'operation_theaters': self.operation_theaters,
                'ambulances': self.ambulances,
                'parking_available': self.parking_available,
                'wheelchair_accessible': self.wheelchair_accessible,
                'opening_hours': self.opening_hours,
                'established_year': self.established_year,
                'specializations': self.specializations.split(',') if self.specializations else [],
                'features': self.features.split(',') if self.features else [],
                'insurance_accepted': self.insurance_accepted.split(',') if self.insurance_accepted else [],
                'payment_methods': self.payment_methods.split(',') if self.payment_methods else [],
                'departments': [d.to_dict() for d in self.departments.all()],
                'services': [s.to_dict() for s in self.services.filter_by(is_available=True).all()],
                'gallery': [g.to_dict() for g in self.gallery.all()[:10]]
            })
        
        return data


class Department(db.Model):
    __tablename__ = 'departments'
    
    id = db.Column(db.Integer, primary_key=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    floor = db.Column(db.String(50))
    phone_extension = db.Column(db.String(20))
    
    # Head of Department
    head_doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'))
    
    # Stats
    specialists_count = db.Column(db.Integer, default=0)
    beds_count = db.Column(db.Integer, default=0)
    is_available = db.Column(db.Boolean, default=True)
    rating = db.Column(db.Numeric(3, 2))
    
    # Images
    icon = db.Column(db.String(100))
    image_url = db.Column(db.Text)
    
    # Operational
    opening_hours = db.Column(db.Text)
    appointment_required = db.Column(db.Boolean, default=True)
    avg_consultation_time = db.Column(db.Integer)  # in minutes
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    doctors = db.relationship('Doctor', backref='department', foreign_keys='Doctor.department_id')
    
    def to_dict(self, include_doctors=False):
        data = {
            'id': self.id,
            'hospital_id': self.hospital_id,
            'name': self.name,
            'description': self.description,
            'floor': self.floor,
            'specialists_count': self.specialists_count,
            'beds_count': self.beds_count,
            'is_available': self.is_available,
            'rating': float(self.rating) if self.rating else None,
            'icon': self.icon,
            'image_url': self.image_url,
            'appointment_required': self.appointment_required,
            'avg_consultation_time': self.avg_consultation_time
        }
        
        if include_doctors:
            data['doctors'] = [d.to_dict() for d in self.doctors[:10]]  # Limit to 10
        
        return data


class HospitalService(db.Model):
    """Services offered by the hospital (e.g., X-Ray, MRI, Lab Tests)"""
    __tablename__ = 'hospital_services'
    
    id = db.Column(db.Integer, primary_key=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    category = db.Column(db.Enum(
        'diagnostic', 'treatment', 'surgery', 'emergency', 
        'rehabilitation', 'pharmacy', 'lab', 'imaging', 'other'
    ), default='other')
    description = db.Column(db.Text)
    price_min = db.Column(db.Numeric(10, 2))
    price_max = db.Column(db.Numeric(10, 2))
    duration_minutes = db.Column(db.Integer)
    is_available = db.Column(db.Boolean, default=True)
    requires_appointment = db.Column(db.Boolean, default=True)
    icon = db.Column(db.String(100))
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'category': self.category,
            'description': self.description,
            'price_range': f"Rs. {self.price_min}-{self.price_max}" if self.price_min and self.price_max else None,
            'price_min': float(self.price_min) if self.price_min else None,
            'price_max': float(self.price_max) if self.price_max else None,
            'duration_minutes': self.duration_minutes,
            'is_available': self.is_available,
            'requires_appointment': self.requires_appointment,
            'icon': self.icon
        }


class HospitalImage(db.Model):
    """Gallery images for hospitals"""
    __tablename__ = 'hospital_images'
    
    id = db.Column(db.Integer, primary_key=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=False)
    image_url = db.Column(db.Text, nullable=False)
    caption = db.Column(db.String(255))
    category = db.Column(db.Enum('exterior', 'interior', 'department', 'equipment', 'staff', 'other'), default='other')
    is_primary = db.Column(db.Boolean, default=False)
    display_order = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'image_url': self.image_url,
            'caption': self.caption,
            'category': self.category,
            'is_primary': self.is_primary
        }


class HospitalMetric(db.Model):
    __tablename__ = 'hospital_metrics'
    
    id = db.Column(db.Integer, primary_key=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=False)
    metric_type = db.Column(db.String(100), nullable=False)
    name = db.Column(db.String(100))  # Display name
    score = db.Column(db.Numeric(5, 2))
    icon = db.Column(db.String(50))
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'metric_type': self.metric_type,
            'name': self.name or self.metric_type,
            'score': float(self.score) if self.score else 0,
            'icon': self.icon
        }


class HospitalReview(db.Model):
    __tablename__ = 'hospital_reviews'
    
    id = db.Column(db.Integer, primary_key=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)  # 1-5
    title = db.Column(db.String(255))
    content = db.Column(db.Text)
    tags = db.Column(db.Text)  # Comma-separated: clean, friendly_staff, etc.
    
    # Detailed ratings
    cleanliness_rating = db.Column(db.Integer)  # 1-5
    staff_rating = db.Column(db.Integer)  # 1-5
    facilities_rating = db.Column(db.Integer)  # 1-5
    wait_time_rating = db.Column(db.Integer)  # 1-5
    value_rating = db.Column(db.Integer)  # 1-5
    
    # Helpfulness
    helpful_count = db.Column(db.Integer, default=0)
    
    # Status
    is_verified = db.Column(db.Boolean, default=False)
    is_visible = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = db.relationship('User')
    
    def to_dict(self):
        return {
            'id': self.id,
            'rating': self.rating,
            'title': self.title,
            'content': self.content,
            'tags': self.tags.split(',') if self.tags else [],
            'cleanliness_rating': self.cleanliness_rating,
            'staff_rating': self.staff_rating,
            'facilities_rating': self.facilities_rating,
            'wait_time_rating': self.wait_time_rating,
            'value_rating': self.value_rating,
            'helpful_count': self.helpful_count,
            'user_name': self.user.full_name if self.user else 'Anonymous',
            'user_image': self.user.profile_image if self.user else None,
            'is_verified': self.is_verified,
            'created_at': self.created_at.isoformat()
        }
