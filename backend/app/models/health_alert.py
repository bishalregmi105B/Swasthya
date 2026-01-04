from datetime import datetime
from app import db


class HealthAlert(db.Model):
    __tablename__ = 'health_alerts'
    
    id = db.Column(db.Integer, primary_key=True)
    disease_name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    severity = db.Column(db.Enum('low', 'moderate', 'high', 'critical'), nullable=False)
    affected_city = db.Column(db.String(100))
    affected_province = db.Column(db.String(100))
    affected_country = db.Column(db.String(100), default='Nepal')
    cases_count = db.Column(db.Integer, default=0)
    trend = db.Column(db.Enum('increasing', 'decreasing', 'stable'), default='stable')
    trend_percentage = db.Column(db.Numeric(5, 2))
    prevention_tips = db.Column(db.Text)
    symptoms = db.Column(db.Text)
    is_active = db.Column(db.Boolean, default=True)
    source = db.Column(db.String(255))
    icon = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'disease_name': self.disease_name,
            'description': self.description,
            'severity': self.severity,
            'affected_city': self.affected_city,
            'affected_province': self.affected_province,
            'cases_count': self.cases_count,
            'trend': self.trend,
            'trend_percentage': float(self.trend_percentage) if self.trend_percentage else None,
            'prevention_tips': self.prevention_tips,
            'symptoms': self.symptoms.split(',') if self.symptoms else [],
            'icon': self.icon,
            'updated_at': self.updated_at.isoformat()
        }


class BloodBank(db.Model):
    __tablename__ = 'blood_banks'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    type = db.Column(db.Enum('blood_bank', 'ngo'), nullable=False)
    address = db.Column(db.Text)
    city = db.Column(db.String(100))
    province = db.Column(db.String(100))
    latitude = db.Column(db.Numeric(10, 8))
    longitude = db.Column(db.Numeric(11, 8))
    phone = db.Column(db.String(20))
    email = db.Column(db.String(255))
    opening_hours = db.Column(db.Text)
    is_open = db.Column(db.Boolean, default=True)
    is_open_24h = db.Column(db.Boolean, default=False)
    blood_availability = db.Column(db.JSON)
    image_url = db.Column(db.Text)
    rating = db.Column(db.Numeric(3, 2))
    upcoming_event = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'type': self.type,
            'address': self.address,
            'city': self.city,
            'latitude': float(self.latitude) if self.latitude else None,
            'longitude': float(self.longitude) if self.longitude else None,
            'phone': self.phone,
            'is_open': self.is_open,
            'is_open_24h': self.is_open_24h,
            'blood_availability': self.blood_availability,
            'rating': float(self.rating) if self.rating else None,
            'upcoming_event': self.upcoming_event
        }


class EmergencyContact(db.Model):
    __tablename__ = 'emergency_contacts'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    relationship = db.Column(db.String(100))
    is_primary = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'phone': self.phone,
            'relationship': self.relationship,
            'is_primary': self.is_primary
        }
