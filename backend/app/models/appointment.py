from datetime import datetime
import uuid
from app import db


class Appointment(db.Model):
    __tablename__ = 'appointments'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    appointment_date = db.Column(db.Date, nullable=False)
    appointment_time = db.Column(db.Time, nullable=False)
    type = db.Column(db.Enum('video', 'chat', 'in_person'), nullable=False)
    status = db.Column(db.Enum('pending', 'confirmed', 'completed', 'cancelled'), default='pending')
    jitsi_room_id = db.Column(db.String(255))
    consultation_fee = db.Column(db.Numeric(10, 2))
    is_paid = db.Column(db.Boolean, default=False)
    notes = db.Column(db.Text)
    ai_summary = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    messages = db.relationship('ChatMessage', backref='appointment')
    
    def generate_room_id(self):
        self.jitsi_room_id = f"swasthya-{uuid.uuid4().hex[:12]}"
        return self.jitsi_room_id
    
    def to_dict(self):
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'doctor_id': self.doctor_id,
            'doctor': self.doctor.to_dict() if self.doctor else None,
            'appointment_date': self.appointment_date.isoformat(),
            'appointment_time': self.appointment_time.isoformat(),
            'type': self.type,
            'status': self.status,
            'jitsi_room_id': self.jitsi_room_id,
            'consultation_fee': float(self.consultation_fee) if self.consultation_fee else None,
            'is_paid': self.is_paid,
            'created_at': self.created_at.isoformat()
        }


class ChatMessage(db.Model):
    __tablename__ = 'chat_messages'
    
    id = db.Column(db.Integer, primary_key=True)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    receiver_id = db.Column(db.Integer)
    appointment_id = db.Column(db.Integer, db.ForeignKey('appointments.id'))
    is_ai_chat = db.Column(db.Boolean, default=False)
    ai_category = db.Column(db.String(50))
    message_encrypted = db.Column(db.Text, nullable=False)
    message_type = db.Column(db.Enum('text', 'image', 'file'), default='text')
    attachment_url = db.Column(db.Text)
    is_flagged = db.Column(db.Boolean, default=False)
    flag_reason = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    sender = db.relationship('User', foreign_keys=[sender_id])
