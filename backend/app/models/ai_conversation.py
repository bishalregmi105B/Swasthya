from datetime import datetime
from app import db


class AIConversation(db.Model):
    """Stores AI conversation sessions from all sources (chat, voice calls)"""
    __tablename__ = 'ai_conversations'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    session_id = db.Column(db.String(100), unique=True, nullable=False)
    
    # Type: 'chat' for text AI Sathi, 'voice_call' for live AI calls
    conversation_type = db.Column(db.String(20), nullable=False, default='chat')
    
    # Specialist type: physician, psychiatrist, dermatologist, pediatrician, etc.
    specialist_type = db.Column(db.String(50), default='physician')
    
    # Language used in conversation
    language_code = db.Column(db.String(10), default='en-US')
    
    # Timestamps
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    ended_at = db.Column(db.DateTime, nullable=True)
    
    # Stats
    total_messages = db.Column(db.Integer, default=0)
    
    # AI-generated summary of the conversation (optional)
    summary = db.Column(db.Text, nullable=True)
    
    # Title for display (can be AI-generated or first message excerpt)
    title = db.Column(db.String(200), nullable=True)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('ai_conversations', lazy='dynamic'))
    messages = db.relationship('AIMessage', backref='conversation', lazy='dynamic', 
                               cascade='all, delete-orphan', order_by='AIMessage.created_at')
    
    def to_dict(self, include_messages=False):
        data = {
            'id': self.id,
            'session_id': self.session_id,
            'conversation_type': self.conversation_type,
            'specialist_type': self.specialist_type,
            'language_code': self.language_code,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'ended_at': self.ended_at.isoformat() if self.ended_at else None,
            'total_messages': self.total_messages,
            'summary': self.summary,
            'title': self.title or self._generate_title(),
        }
        if include_messages:
            data['messages'] = [m.to_dict() for m in self.messages.all()]
        return data
    
    def _generate_title(self):
        """Generate title from first user message if not set"""
        first_msg = self.messages.filter_by(role='user').first()
        if first_msg and first_msg.content:
            return first_msg.content[:50] + ('...' if len(first_msg.content) > 50 else '')
        return f"{self.specialist_type.title()} Consultation"


class AIMessage(db.Model):
    """Stores individual messages within an AI conversation"""
    __tablename__ = 'ai_messages'
    
    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey('ai_conversations.id', ondelete='CASCADE'), nullable=False)
    
    # Role: 'user', 'assistant', 'system'
    role = db.Column(db.String(20), nullable=False)
    
    # Message content
    content = db.Column(db.Text, nullable=False)
    
    # For voice calls - path to audio file
    audio_url = db.Column(db.String(500), nullable=True)
    
    # Timestamp
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'conversation_id': self.conversation_id,
            'role': self.role,
            'content': self.content,
            'audio_url': self.audio_url,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
