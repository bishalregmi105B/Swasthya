from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from app import db


class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=True)  # Nullable for social logins
    full_name = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20))
    date_of_birth = db.Column(db.Date)
    gender = db.Column(db.Enum('male', 'female', 'other'))
    blood_type = db.Column(db.Enum('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
    profile_image = db.Column(db.Text)
    address = db.Column(db.Text)
    city = db.Column(db.String(100))
    province = db.Column(db.String(100))
    country = db.Column(db.String(100), default='Nepal')
    latitude = db.Column(db.Numeric(10, 8))
    longitude = db.Column(db.Numeric(11, 8))
    is_verified = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    notification_email = db.Column(db.Boolean, default=True)
    notification_sms = db.Column(db.Boolean, default=True)
    notification_push = db.Column(db.Boolean, default=True)
    
    # Role field for provider types
    role = db.Column(db.Enum(
        'user',              # Normal patient (uses mobile app)
        'doctor',            # Doctor (linked via Doctor model)
        'hospital_admin',    # Hospital administrator
        'clinic_admin',      # Clinic administrator
        'pharmacy_admin',    # Pharmacy administrator
        'admin',             # System admin
        'super_admin'        # Super admin
    ), default='user', nullable=False)
    
    # For hospital/clinic/pharmacy admins - link to their facility
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'), nullable=True)
    
    # OAuth fields
    google_id = db.Column(db.String(255), unique=True, nullable=True, index=True)
    auth_provider = db.Column(db.String(20), default='email')  # 'email', 'google', 'apple'
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    doctor = db.relationship('Doctor', backref='user', uselist=False)
    hospital = db.relationship('Hospital', backref='admins')
    appointments = db.relationship('Appointment', backref='patient', foreign_keys='Appointment.patient_id')
    reminders = db.relationship('MedicineReminder', backref='user')
    emergency_contacts = db.relationship('EmergencyContact', backref='user')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        if not self.password_hash:
            return False
        return check_password_hash(self.password_hash, password)
    
    def is_provider(self):
        """Check if user is a healthcare provider (not a patient)"""
        provider_roles = ['doctor', 'hospital_admin', 'clinic_admin', 'pharmacy_admin', 'admin', 'super_admin']
        return self.role in provider_roles
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'full_name': self.full_name,
            'phone': self.phone,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'gender': self.gender,
            'blood_type': self.blood_type,
            'profile_image': self.profile_image,
            'city': self.city,
            'province': self.province,
            'role': self.role,
            'hospital_id': self.hospital_id,
            'is_verified': self.is_verified,
            'auth_provider': self.auth_provider,
            'created_at': self.created_at.isoformat()
        }
