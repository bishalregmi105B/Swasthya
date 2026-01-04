"""
Simulation Database Models
Stores medical simulations (CPR, First Aid, Choking, etc.) with bilingual support
"""

from datetime import datetime, timezone
from app import db


class Simulation(db.Model):
    """
    Medical simulation/training module
    Examples: Adult CPR, Infant CPR, Choking Response, First Aid
    """
    __tablename__ = 'simulations'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Bilingual titles
    title = db.Column(db.String(255), nullable=False)  # English
    title_ne = db.Column(db.String(255))  # Nepali
    
    slug = db.Column(db.String(100), unique=True, nullable=False, index=True)
    
    # Bilingual descriptions
    description = db.Column(db.Text)  # English
    description_ne = db.Column(db.Text)  # Nepali
    
    category = db.Column(db.String(50), index=True)  # cpr, choking, first_aid, emergency
    
    # Display
    icon = db.Column(db.String(50), default='emergency')
    image_url = db.Column(db.Text)
    color = db.Column(db.String(20), default='#136dec')
    
    # Metadata
    difficulty = db.Column(db.Enum('beginner', 'intermediate', 'advanced'), default='beginner')
    duration_minutes = db.Column(db.Integer, default=10)
    total_steps = db.Column(db.Integer, default=5)
    
    # AI Integration
    ai_voice_enabled = db.Column(db.Boolean, default=True)
    ai_feedback_enabled = db.Column(db.Boolean, default=True)
    
    # Status
    is_active = db.Column(db.Boolean, default=True)
    is_featured = db.Column(db.Boolean, default=False)
    order_index = db.Column(db.Integer, default=0)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relationships
    steps = db.relationship('SimulationStep', backref='simulation', lazy='dynamic', order_by='SimulationStep.step_number')
    
    def to_dict(self, include_steps=False, lang='en'):
        data = {
            'id': self.id,
            'title': self.title_ne if lang == 'ne' and self.title_ne else self.title,
            'title_en': self.title,
            'title_ne': self.title_ne,
            'slug': self.slug,
            'description': self.description_ne if lang == 'ne' and self.description_ne else self.description,
            'description_en': self.description,
            'description_ne': self.description_ne,
            'category': self.category,
            'icon': self.icon,
            'image_url': self.image_url,
            'color': self.color,
            'difficulty': self.difficulty,
            'duration_minutes': self.duration_minutes,
            'total_steps': self.total_steps,
            'ai_voice_enabled': self.ai_voice_enabled,
            'ai_feedback_enabled': self.ai_feedback_enabled,
            'is_featured': self.is_featured
        }
        if include_steps:
            data['steps'] = [s.to_dict(lang=lang) for s in self.steps.all()]
        return data


class SimulationStep(db.Model):
    """
    Individual step within a simulation with bilingual support
    """
    __tablename__ = 'simulation_steps'
    
    id = db.Column(db.Integer, primary_key=True)
    simulation_id = db.Column(db.Integer, db.ForeignKey('simulations.id'), nullable=False)
    step_number = db.Column(db.Integer, nullable=False)
    
    # Bilingual content
    title = db.Column(db.String(255), nullable=False)  # English
    title_ne = db.Column(db.String(255))  # Nepali
    
    instruction = db.Column(db.Text, nullable=False)  # English
    instruction_ne = db.Column(db.Text)  # Nepali
    
    voice_text = db.Column(db.Text)  # TTS text English
    voice_text_ne = db.Column(db.Text)  # TTS text Nepali
    
    # Visual/Audio assets
    animation_url = db.Column(db.Text)  # Lottie animation URL
    image_url = db.Column(db.Text)
    video_url = db.Column(db.Text)
    audio_url = db.Column(db.Text)  # For pre-recorded narration
    
    # Interactive elements
    step_type = db.Column(db.Enum('info', 'action', 'compress', 'timed'), default='info')
    target_value = db.Column(db.Integer)  # e.g., 30 compressions
    target_rate = db.Column(db.Integer)  # e.g., 100-120 BPM for CPR
    duration_seconds = db.Column(db.Integer)  # Time for timed steps
    
    # AI feedback prompts (bilingual)
    ai_feedback_good = db.Column(db.Text)  # "Great depth!"
    ai_feedback_good_ne = db.Column(db.Text)  # Nepali
    ai_feedback_adjust = db.Column(db.Text)  # "Push harder"
    ai_feedback_adjust_ne = db.Column(db.Text)  # Nepali
    
    def to_dict(self, lang='en'):
        return {
            'id': self.id,
            'step_number': self.step_number,
            'title': self.title_ne if lang == 'ne' and self.title_ne else self.title,
            'title_en': self.title,
            'title_ne': self.title_ne,
            'instruction': self.instruction_ne if lang == 'ne' and self.instruction_ne else self.instruction,
            'instruction_en': self.instruction,
            'instruction_ne': self.instruction_ne,
            'voice_text': self.voice_text_ne if lang == 'ne' and self.voice_text_ne else self.voice_text,
            'voice_text_en': self.voice_text,
            'voice_text_ne': self.voice_text_ne,
            'animation_url': self.animation_url,
            'image_url': self.image_url,
            'video_url': self.video_url,
            'audio_url': self.audio_url,
            'step_type': self.step_type,
            'target_value': self.target_value,
            'target_rate': self.target_rate,
            'duration_seconds': self.duration_seconds,
            'ai_feedback_good': self.ai_feedback_good_ne if lang == 'ne' and self.ai_feedback_good_ne else self.ai_feedback_good,
            'ai_feedback_adjust': self.ai_feedback_adjust_ne if lang == 'ne' and self.ai_feedback_adjust_ne else self.ai_feedback_adjust
        }


class UserSimulationProgress(db.Model):
    """
    Tracks user progress through simulations
    """
    __tablename__ = 'user_simulation_progress'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    simulation_id = db.Column(db.Integer, db.ForeignKey('simulations.id'), nullable=False)
    
    # Progress
    current_step = db.Column(db.Integer, default=1)
    completed = db.Column(db.Boolean, default=False)
    score = db.Column(db.Integer)  # 0-100 score
    
    # Performance metrics
    total_time_seconds = db.Column(db.Integer)
    attempts = db.Column(db.Integer, default=1)
    
    # Timestamps
    started_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = db.Column(db.DateTime)
    
    # Unique constraint
    __table_args__ = (
        db.UniqueConstraint('user_id', 'simulation_id', name='unique_user_simulation'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'simulation_id': self.simulation_id,
            'current_step': self.current_step,
            'completed': self.completed,
            'score': self.score,
            'total_time_seconds': self.total_time_seconds,
            'attempts': self.attempts,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None
        }
