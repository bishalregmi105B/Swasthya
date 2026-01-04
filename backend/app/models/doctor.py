from datetime import datetime
from app import db


class Doctor(db.Model):
    __tablename__ = 'doctors'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    license_number = db.Column(db.String(100), unique=True, nullable=False)
    specialization = db.Column(db.Enum(
        'physician', 'dermatologist', 'cardiologist', 'psychiatrist',
        'neurologist', 'pediatrician', 'gynecologist', 'orthopedic',
        'ophthalmologist', 'ent', 'dentist', 'nutritionist', 'surgeon',
        'oncologist', 'nephrologist', 'pulmonologist', 'gastroenterologist', 'other'
    ), nullable=False)
    sub_specialization = db.Column(db.String(255))
    experience_years = db.Column(db.Integer)
    qualification = db.Column(db.Text)
    education = db.Column(db.Text)  # Detailed education history
    
    # Hospital & Department
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'))
    department_id = db.Column(db.Integer, db.ForeignKey('departments.id'))
    is_department_head = db.Column(db.Boolean, default=False)
    
    # Fees
    consultation_fee = db.Column(db.Numeric(10, 2))
    chat_fee = db.Column(db.Numeric(10, 2))
    video_fee = db.Column(db.Numeric(10, 2))
    home_visit_fee = db.Column(db.Numeric(10, 2))
    is_free_consultation = db.Column(db.Boolean, default=False)
    
    # Availability
    is_available = db.Column(db.Boolean, default=True)
    available_days = db.Column(db.String(100))  # e.g., "mon,tue,wed,thu,fri"
    available_hours = db.Column(db.Text)  # JSON: {"mon": "09:00-17:00", ...}
    next_available_slot = db.Column(db.DateTime)
    avg_consultation_time = db.Column(db.Integer)  # minutes
    
    # Ratings & Stats
    is_verified = db.Column(db.Boolean, default=False)
    rating = db.Column(db.Numeric(3, 2), default=0)
    total_reviews = db.Column(db.Integer, default=0)
    total_patients = db.Column(db.Integer, default=0)
    success_rate = db.Column(db.Numeric(5, 2))  # treatment success percentage
    
    # Profile Info
    about = db.Column(db.Text)
    languages = db.Column(db.Text)  # Comma-separated
    achievements = db.Column(db.Text)  # Comma-separated
    publications = db.Column(db.Text)  # Count or list
    
    # Contact (additional)
    phone = db.Column(db.String(20))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    appointments = db.relationship('Appointment', backref='doctor', foreign_keys='Appointment.doctor_id')
    reviews = db.relationship('DoctorReview', backref='doctor', lazy='dynamic')
    
    def to_dict(self, include_details=False):
        user = self.user
        data = {
            'id': self.id,
            'user_id': self.user_id,
            'name': user.full_name if user else None,
            'email': user.email if user else None,
            'profile_image': user.profile_image if user else None,
            'license_number': self.license_number,
            'specialization': self.specialization,
            'sub_specialization': self.sub_specialization,
            'experience_years': self.experience_years,
            'qualification': self.qualification,
            'hospital_id': self.hospital_id,
            'hospital_name': self.hospital.name if self.hospital else None,
            'department_id': self.department_id,
            'department_name': self.department.name if self.department else None,
            'consultation_fee': float(self.consultation_fee) if self.consultation_fee else None,
            'chat_fee': float(self.chat_fee) if self.chat_fee else None,
            'video_fee': float(self.video_fee) if self.video_fee else None,
            'is_free_consultation': self.is_free_consultation,
            'is_available': self.is_available,
            'is_verified': self.is_verified,
            'rating': float(self.rating) if self.rating else 0,
            'total_reviews': self.total_reviews,
            'total_patients': self.total_patients,
            'about': self.about,
            'languages': self.languages.split(',') if self.languages else []
        }
        
        if include_details:
            data.update({
                'education': self.education,
                'achievements': self.achievements.split(',') if self.achievements else [],
                'available_days': self.available_days.split(',') if self.available_days else [],
                'available_hours': self.available_hours,
                'home_visit_fee': float(self.home_visit_fee) if self.home_visit_fee else None,
                'avg_consultation_time': self.avg_consultation_time,
                'success_rate': float(self.success_rate) if self.success_rate else None,
                'next_available_slot': self.next_available_slot.isoformat() if self.next_available_slot else None,
                'is_department_head': self.is_department_head
            })
        
        return data


class DoctorReview(db.Model):
    """Reviews for doctors"""
    __tablename__ = 'doctor_reviews'
    
    id = db.Column(db.Integer, primary_key=True)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    appointment_id = db.Column(db.Integer, db.ForeignKey('appointments.id'))
    
    rating = db.Column(db.Integer, nullable=False)  # 1-5
    title = db.Column(db.String(255))
    content = db.Column(db.Text)
    
    # Detailed ratings
    punctuality_rating = db.Column(db.Integer)  # 1-5
    knowledge_rating = db.Column(db.Integer)  # 1-5
    bedside_manner_rating = db.Column(db.Integer)  # 1-5
    communication_rating = db.Column(db.Integer)  # 1-5
    
    # Recommendation
    would_recommend = db.Column(db.Boolean, default=True)
    
    # Helpfulness
    helpful_count = db.Column(db.Integer, default=0)
    
    # Status
    is_verified = db.Column(db.Boolean, default=False)
    is_visible = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User')
    
    def to_dict(self):
        return {
            'id': self.id,
            'rating': self.rating,
            'title': self.title,
            'content': self.content,
            'punctuality_rating': self.punctuality_rating,
            'knowledge_rating': self.knowledge_rating,
            'bedside_manner_rating': self.bedside_manner_rating,
            'communication_rating': self.communication_rating,
            'would_recommend': self.would_recommend,
            'helpful_count': self.helpful_count,
            'user_name': self.user.full_name if self.user else 'Anonymous',
            'user_image': self.user.profile_image if self.user else None,
            'is_verified': self.is_verified,
            'created_at': self.created_at.isoformat()
        }
