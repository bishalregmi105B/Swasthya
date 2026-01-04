from datetime import datetime
from app import db


class MedicalRecord(db.Model):
    """Main medical record container for each user"""
    __tablename__ = 'medical_records'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    
    # Basic Medical Info
    blood_type = db.Column(db.Enum('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
    height_cm = db.Column(db.Numeric(5, 2))
    weight_kg = db.Column(db.Numeric(5, 2))
    
    # Emergency Info
    emergency_notes = db.Column(db.Text)  # Critical info for emergencies
    organ_donor = db.Column(db.Boolean, default=False)
    
    # Lifestyle
    smoking_status = db.Column(db.Enum('never', 'former', 'current'))
    alcohol_use = db.Column(db.Enum('none', 'occasional', 'moderate', 'heavy'))
    exercise_frequency = db.Column(db.Enum('none', 'rarely', 'weekly', 'daily'))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('medical_record', uselist=False))
    conditions = db.relationship('MedicalCondition', backref='record', lazy='dynamic', cascade='all, delete-orphan')
    allergies = db.relationship('MedicalAllergy', backref='record', lazy='dynamic', cascade='all, delete-orphan')
    medications = db.relationship('MedicalMedication', backref='record', lazy='dynamic', cascade='all, delete-orphan')
    documents = db.relationship('MedicalDocument', backref='record', lazy='dynamic', cascade='all, delete-orphan')
    surgeries = db.relationship('MedicalSurgery', backref='record', lazy='dynamic', cascade='all, delete-orphan')
    vaccinations = db.relationship('MedicalVaccination', backref='record', lazy='dynamic', cascade='all, delete-orphan')
    
    def to_dict(self, include_details=False):
        data = {
            'id': self.id,
            'user_id': self.user_id,
            'blood_type': self.blood_type,
            'height_cm': float(self.height_cm) if self.height_cm else None,
            'weight_kg': float(self.weight_kg) if self.weight_kg else None,
            'emergency_notes': self.emergency_notes,
            'organ_donor': self.organ_donor,
            'smoking_status': self.smoking_status,
            'alcohol_use': self.alcohol_use,
            'exercise_frequency': self.exercise_frequency,
            'conditions_count': self.conditions.count(),
            'allergies_count': self.allergies.count(),
            'medications_count': self.medications.count(),
            'documents_count': self.documents.count(),
            'surgeries_count': self.surgeries.count(),
            'vaccinations_count': self.vaccinations.count()
        }
        
        if include_details:
            data['conditions'] = [c.to_dict() for c in self.conditions.filter_by(status='active').all()]
            data['allergies'] = [a.to_dict() for a in self.allergies.all()]
            data['medications'] = [m.to_dict() for m in self.medications.filter_by(is_active=True).all()]
            data['recent_documents'] = [d.to_dict() for d in self.documents.order_by(MedicalDocument.document_date.desc()).limit(5).all()]
            data['surgeries'] = [s.to_dict() for s in self.surgeries.order_by(MedicalSurgery.surgery_date.desc()).all()]
            data['vaccinations'] = [v.to_dict() for v in self.vaccinations.order_by(MedicalVaccination.administered_date.desc()).all()]
        
        return data


class MedicalCondition(db.Model):
    """User's medical conditions/diagnoses"""
    __tablename__ = 'medical_conditions'
    
    id = db.Column(db.Integer, primary_key=True)
    record_id = db.Column(db.Integer, db.ForeignKey('medical_records.id'), nullable=False)
    
    name = db.Column(db.String(255), nullable=False)
    icd_code = db.Column(db.String(20))  # International Classification of Diseases code
    category = db.Column(db.Enum(
        'cardiovascular', 'respiratory', 'digestive', 'neurological',
        'musculoskeletal', 'endocrine', 'mental_health', 'skin',
        'infectious', 'genetic', 'autoimmune', 'other'
    ))
    severity = db.Column(db.Enum('mild', 'moderate', 'severe'))
    status = db.Column(db.Enum('active', 'resolved', 'chronic', 'in_remission'), default='active')
    
    diagnosed_date = db.Column(db.Date)
    resolved_date = db.Column(db.Date)
    diagnosed_by = db.Column(db.String(255))  # Doctor name
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'))
    
    notes = db.Column(db.Text)
    treatment = db.Column(db.Text)  # Current treatment plan
    
    # AI Analysis
    ai_analysis = db.Column(db.Text)  # AI interpretation/summary
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'icd_code': self.icd_code,
            'category': self.category,
            'severity': self.severity,
            'status': self.status,
            'diagnosed_date': self.diagnosed_date.isoformat() if self.diagnosed_date else None,
            'resolved_date': self.resolved_date.isoformat() if self.resolved_date else None,
            'diagnosed_by': self.diagnosed_by,
            'notes': self.notes,
            'treatment': self.treatment,
            'ai_analysis': self.ai_analysis
        }


class MedicalAllergy(db.Model):
    """User's allergies"""
    __tablename__ = 'medical_allergies'
    
    id = db.Column(db.Integer, primary_key=True)
    record_id = db.Column(db.Integer, db.ForeignKey('medical_records.id'), nullable=False)
    
    allergen = db.Column(db.String(255), nullable=False)  # What they're allergic to
    category = db.Column(db.Enum('drug', 'food', 'environmental', 'insect', 'latex', 'other'))
    severity = db.Column(db.Enum('mild', 'moderate', 'severe', 'life_threatening'), nullable=False)
    reaction = db.Column(db.Text)  # Description of reaction
    
    discovered_date = db.Column(db.Date)
    notes = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'allergen': self.allergen,
            'category': self.category,
            'severity': self.severity,
            'reaction': self.reaction,
            'discovered_date': self.discovered_date.isoformat() if self.discovered_date else None,
            'notes': self.notes
        }


class MedicalMedication(db.Model):
    """User's current and past medications"""
    __tablename__ = 'medical_medications'
    
    id = db.Column(db.Integer, primary_key=True)
    record_id = db.Column(db.Integer, db.ForeignKey('medical_records.id'), nullable=False)
    
    name = db.Column(db.String(255), nullable=False)
    generic_name = db.Column(db.String(255))
    dosage = db.Column(db.String(100))  # e.g., "500mg"
    frequency = db.Column(db.String(100))  # e.g., "twice daily"
    route = db.Column(db.Enum('oral', 'injection', 'topical', 'inhaled', 'sublingual', 'rectal', 'other'))
    
    prescribed_for = db.Column(db.String(255))  # Reason for medication
    prescribed_by = db.Column(db.String(255))  # Doctor name
    prescribed_date = db.Column(db.Date)
    
    start_date = db.Column(db.Date)
    end_date = db.Column(db.Date)
    is_active = db.Column(db.Boolean, default=True)
    
    # Link to reminder if exists
    reminder_id = db.Column(db.Integer, db.ForeignKey('medicine_reminders.id'))
    
    side_effects = db.Column(db.Text)
    notes = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'generic_name': self.generic_name,
            'dosage': self.dosage,
            'frequency': self.frequency,
            'route': self.route,
            'prescribed_for': self.prescribed_for,
            'prescribed_by': self.prescribed_by,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'is_active': self.is_active,
            'notes': self.notes
        }


class MedicalDocument(db.Model):
    """Medical documents and reports with image uploads"""
    __tablename__ = 'medical_documents'
    
    id = db.Column(db.Integer, primary_key=True)
    record_id = db.Column(db.Integer, db.ForeignKey('medical_records.id'), nullable=False)
    
    title = db.Column(db.String(255), nullable=False)
    document_type = db.Column(db.Enum(
        'lab_report', 'prescription', 'discharge_summary', 'xray',
        'mri', 'ct_scan', 'ultrasound', 'ecg', 'blood_test',
        'pathology', 'vaccination', 'insurance', 'referral', 'other'
    ), nullable=False)
    
    description = db.Column(db.Text)
    document_date = db.Column(db.Date, nullable=False)
    
    # Provider Info
    doctor_name = db.Column(db.String(255))
    hospital_name = db.Column(db.String(255))
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'))
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'))
    
    # File Storage
    file_url = db.Column(db.Text)  # Primary document file
    file_type = db.Column(db.String(50))  # pdf, image, etc.
    file_size = db.Column(db.Integer)  # Size in bytes
    
    # OCR and AI Analysis
    ocr_text = db.Column(db.Text)  # Extracted text from image
    ai_analysis = db.Column(db.Text)  # AI interpretation of the document
    ai_summary = db.Column(db.Text)  # Short AI summary
    ai_analyzed_at = db.Column(db.DateTime)
    
    # Results/Values (for lab reports)
    results_json = db.Column(db.Text)  # JSON of key-value results
    
    # Status
    is_critical = db.Column(db.Boolean, default=False)  # Flag for abnormal results
    is_shared = db.Column(db.Boolean, default=False)  # Shared with doctors
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    images = db.relationship('MedicalDocumentImage', backref='document', lazy='dynamic', cascade='all, delete-orphan')
    
    def to_dict(self, include_images=True):
        data = {
            'id': self.id,
            'title': self.title,
            'document_type': self.document_type,
            'description': self.description,
            'document_date': self.document_date.isoformat() if self.document_date else None,
            'doctor_name': self.doctor_name,
            'hospital_name': self.hospital_name,
            'file_url': self.file_url,
            'file_type': self.file_type,
            'ai_analysis': self.ai_analysis,
            'ai_summary': self.ai_summary,
            'is_critical': self.is_critical,
            'is_shared': self.is_shared,
            'created_at': self.created_at.isoformat()
        }
        
        if include_images:
            data['images'] = [img.to_dict() for img in self.images.all()]
        
        return data


class MedicalDocumentImage(db.Model):
    """Multiple images for a medical document"""
    __tablename__ = 'medical_document_images'
    
    id = db.Column(db.Integer, primary_key=True)
    document_id = db.Column(db.Integer, db.ForeignKey('medical_documents.id'), nullable=False)
    
    image_url = db.Column(db.Text, nullable=False)
    thumbnail_url = db.Column(db.Text)
    caption = db.Column(db.String(255))
    page_number = db.Column(db.Integer, default=1)
    
    # OCR
    ocr_text = db.Column(db.Text)
    ocr_confidence = db.Column(db.Numeric(5, 2))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'image_url': self.image_url,
            'thumbnail_url': self.thumbnail_url,
            'caption': self.caption,
            'page_number': self.page_number,
            'ocr_text': self.ocr_text
        }


class MedicalSurgery(db.Model):
    """User's surgical history"""
    __tablename__ = 'medical_surgeries'
    
    id = db.Column(db.Integer, primary_key=True)
    record_id = db.Column(db.Integer, db.ForeignKey('medical_records.id'), nullable=False)
    
    procedure_name = db.Column(db.String(255), nullable=False)
    procedure_type = db.Column(db.Enum(
        'emergency', 'elective', 'outpatient', 'inpatient', 'minimally_invasive'
    ))
    
    surgery_date = db.Column(db.Date)
    surgeon_name = db.Column(db.String(255))
    hospital_name = db.Column(db.String(255))
    hospital_id = db.Column(db.Integer, db.ForeignKey('hospitals.id'))
    
    anesthesia_type = db.Column(db.Enum('local', 'regional', 'general', 'sedation'))
    duration_minutes = db.Column(db.Integer)
    
    outcome = db.Column(db.Text)
    complications = db.Column(db.Text)
    recovery_notes = db.Column(db.Text)
    
    # AI Analysis
    ai_analysis = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'procedure_name': self.procedure_name,
            'procedure_type': self.procedure_type,
            'surgery_date': self.surgery_date.isoformat() if self.surgery_date else None,
            'surgeon_name': self.surgeon_name,
            'hospital_name': self.hospital_name,
            'anesthesia_type': self.anesthesia_type,
            'duration_minutes': self.duration_minutes,
            'outcome': self.outcome,
            'complications': self.complications,
            'ai_analysis': self.ai_analysis
        }


class MedicalVaccination(db.Model):
    """User's vaccination records"""
    __tablename__ = 'medical_vaccinations'
    
    id = db.Column(db.Integer, primary_key=True)
    record_id = db.Column(db.Integer, db.ForeignKey('medical_records.id'), nullable=False)
    
    vaccine_name = db.Column(db.String(255), nullable=False)
    vaccine_type = db.Column(db.Enum(
        'childhood', 'adult', 'travel', 'flu', 'covid', 'booster', 'other'
    ))
    
    dose_number = db.Column(db.Integer)  # 1st, 2nd, 3rd dose
    total_doses = db.Column(db.Integer)  # Total required doses
    
    administered_date = db.Column(db.Date)
    next_due_date = db.Column(db.Date)
    
    administered_by = db.Column(db.String(255))
    location = db.Column(db.String(255))
    
    batch_number = db.Column(db.String(100))
    manufacturer = db.Column(db.String(255))
    
    side_effects = db.Column(db.Text)
    notes = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'vaccine_name': self.vaccine_name,
            'vaccine_type': self.vaccine_type,
            'dose_number': self.dose_number,
            'total_doses': self.total_doses,
            'administered_date': self.administered_date.isoformat() if self.administered_date else None,
            'next_due_date': self.next_due_date.isoformat() if self.next_due_date else None,
            'administered_by': self.administered_by,
            'location': self.location,
            'manufacturer': self.manufacturer,
            'notes': self.notes
        }
