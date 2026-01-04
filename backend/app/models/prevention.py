from datetime import datetime
from app import db


class PreventionTip(db.Model):
    __tablename__ = 'prevention_tips'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    category = db.Column(db.String(100))
    content = db.Column(db.Text)
    image_url = db.Column(db.Text)
    is_featured = db.Column(db.Boolean, default=False)
    is_medically_reviewed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'category': self.category,
            'content': self.content,
            'image_url': self.image_url,
            'is_featured': self.is_featured,
            'is_medically_reviewed': self.is_medically_reviewed
        }


class DailyGoal(db.Model):
    __tablename__ = 'daily_goals'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    goal_type = db.Column(db.String(100), nullable=False)
    title = db.Column(db.String(255))
    target_value = db.Column(db.String(100))
    icon = db.Column(db.String(100))
    is_completed = db.Column(db.Boolean, default=False)
    date = db.Column(db.Date, nullable=False)
    completed_at = db.Column(db.DateTime)
    
    user = db.relationship('User')
    
    def to_dict(self):
        return {
            'id': self.id,
            'goal_type': self.goal_type,
            'title': self.title,
            'target_value': self.target_value,
            'icon': self.icon,
            'is_completed': self.is_completed,
            'date': self.date.isoformat()
        }


class SimulationProgress(db.Model):
    __tablename__ = 'simulation_progress'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    simulation_type = db.Column(db.String(50), nullable=False)
    current_step = db.Column(db.Integer, default=1)
    total_steps = db.Column(db.Integer)
    stats = db.Column(db.JSON)
    is_completed = db.Column(db.Boolean, default=False)
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
