from datetime import datetime
from app import db


class MedicineReminder(db.Model):
    __tablename__ = 'medicine_reminders'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    medicine_name = db.Column(db.String(255), nullable=False)
    form = db.Column(db.Enum('pill', 'tablet', 'injection', 'liquid', 'cream', 'drops'), nullable=False)
    strength = db.Column(db.String(50))
    unit = db.Column(db.String(20))
    frequency = db.Column(db.Enum('daily', 'weekly', 'custom'), default='daily')
    times_per_day = db.Column(db.Integer, default=1)
    reminder_times = db.Column(db.JSON)
    days_of_week = db.Column(db.JSON)
    start_date = db.Column(db.Date)
    end_date = db.Column(db.Date)
    instructions = db.Column(db.String(255))
    refill_reminder = db.Column(db.Boolean, default=True)
    critical_alert = db.Column(db.Boolean, default=False)
    notes = db.Column(db.Text)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    logs = db.relationship('ReminderLog', backref='reminder')
    
    def to_dict(self):
        return {
            'id': self.id,
            'medicine_name': self.medicine_name,
            'form': self.form,
            'strength': self.strength,
            'unit': self.unit,
            'frequency': self.frequency,
            'times_per_day': self.times_per_day,
            'reminder_times': self.reminder_times,
            'instructions': self.instructions,
            'is_active': self.is_active,
            'refill_reminder': self.refill_reminder,
            'critical_alert': self.critical_alert
        }


class ReminderLog(db.Model):
    __tablename__ = 'reminder_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    reminder_id = db.Column(db.Integer, db.ForeignKey('medicine_reminders.id'), nullable=False)
    scheduled_time = db.Column(db.DateTime, nullable=False)
    taken_at = db.Column(db.DateTime)
    is_taken = db.Column(db.Boolean, default=False)
    is_skipped = db.Column(db.Boolean, default=False)
