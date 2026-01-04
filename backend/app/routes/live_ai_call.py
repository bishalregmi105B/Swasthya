"""
Live AI Call Routes for Swasthya Healthcare
Provides voice-based AI medical consultations with:
- Multi-language support (English, Hindi, Nepali)
- Healthcare-focused AI responses
- Text-to-speech for AI responses
- Session management for ongoing consultations
"""

from flask import Blueprint, request, jsonify, g, send_file, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
import os
import uuid
import asyncio
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass, field
from collections import deque
import hashlib
import re

import g4f
from g4f.client import AsyncClient
from g4f import Provider

from app import db

logger = logging.getLogger(__name__)

# Create blueprint
live_ai_bp = Blueprint('live_ai', __name__)


def get_provider_class(provider_name: str):
    """Get the g4f provider class from string name"""
    if not provider_name:
        return None
    try:
        return getattr(Provider, provider_name, None)
    except Exception:
        return None


def ai_call_with_retry(model, messages, max_retries=3, provider_name=None, fallback_models=None):
    """
    Wrapper for g4f Client with retry and fallback mechanism.
    """
    from g4f.client import Client
    
    models_to_try = [model]
    if fallback_models:
        models_to_try.extend([m.strip() for m in fallback_models if m.strip()])
    
    provider = get_provider_class(provider_name) if provider_name else get_provider_class(
        current_app.config.get('AI_DEFAULT_PROVIDER', 'DeepInfra')
    )
    
    last_error = None
    
    for current_model in models_to_try:
        for attempt in range(max_retries):
            try:
                logger.info(f"[Live AI] Trying {current_model} (attempt {attempt + 1}/{max_retries})")
                
                # Use Client pattern
                client = Client(provider=provider) if provider else Client()
                response = client.chat.completions.create(
                    model=current_model,
                    messages=messages,
                    web_search=False
                )
                
                content = response.choices[0].message.content
                logger.info(f"[Live AI] Success with {current_model}")
                return content
                
            except Exception as e:
                last_error = e
                wait_time = min(2 ** attempt, 8)
                logger.warning(f"[Live AI] {current_model} attempt {attempt + 1} failed: {e}")
                
                if attempt < max_retries - 1:
                    time.sleep(wait_time)
        
        logger.warning(f"[Live AI] Model {current_model} exhausted retries, trying next...")
    
    logger.error(f"[Live AI] All models failed. Last error: {last_error}")
    raise last_error

# Import TTS service with Edge TTS
try:
    from app.utils.tts_service import (
        get_speech_generator, generate_speech_async,
        get_optimal_voice, AUDIO_OUTPUT_DIR, LANGUAGE_NAMES, clean_text_for_tts,
        EDGE_TTS_AVAILABLE
    )
    TTS_AVAILABLE = EDGE_TTS_AVAILABLE
    speech_generator = get_speech_generator()
except ImportError as e:
    print(f"Warning: TTS service import failed: {e}")
    TTS_AVAILABLE = False
    speech_generator = None
    AUDIO_OUTPUT_DIR = "/tmp/swasthya_audio"
    LANGUAGE_NAMES = {'en-US': 'English', 'hi-IN': 'Hindi', 'ne-NP': 'Nepali'}
    os.makedirs(AUDIO_OUTPUT_DIR, exist_ok=True)

# Healthcare AI Specialists configuration
MEDICAL_SPECIALISTS = {
    'physician': {
        'name': 'General Physician',
        'specialty': 'General Medicine',
        'prompt': """You are a compassionate virtual general physician assistant.

Guidelines:
1. Listen carefully to symptoms and ask clarifying questions about duration, severity, and related symptoms
2. Provide clear, reassuring explanations in simple language
3. Give practical advice for symptom management
4. Recommend professional consultation for serious concerns
5. Never diagnose - provide preliminary guidance only

Response style:
- Keep responses concise (2-3 sentences) for voice conversation
- Be warm but professional
- Avoid introducing yourself by name in every response
- Focus on helping the patient understand their situation"""
    },
    'psychiatrist': {
        'name': 'Mental Health Specialist',
        'specialty': 'Mental Health',
        'prompt': """You are a compassionate mental health support specialist.

Guidelines:
1. Create a safe, non-judgmental space for sharing feelings
2. Practice active listening and validate emotions
3. Offer coping strategies and mindfulness techniques
4. Recognize when professional help is needed
5. Provide crisis resources when appropriate

Response style:
- Keep responses warm and supportive (2-3 sentences) for voice conversation
- Avoid clinical jargon
- Do not introduce yourself by name repeatedly
- Focus on empathy and practical support"""
    },
    'dermatologist': {
        'name': 'Dermatology Specialist',
        'specialty': 'Dermatology',
        'prompt': """You are a knowledgeable virtual dermatology assistant.

Guidelines:
1. Ask about symptom location, appearance, duration, and triggers
2. Provide general guidance on skin care
3. Recommend when in-person dermatologist visit is needed
4. Suggest over-the-counter remedies when appropriate

Response style:
- Keep responses concise (2-3 sentences) for voice conversation
- Be descriptive and clear
- Do not introduce yourself by name in every response
- Always recommend professional examination for persistent conditions"""
    },
    'pediatrician': {
        'name': 'Pediatric Specialist',
        'specialty': 'Pediatrics',
        'prompt': """You are a warm and reassuring virtual pediatric assistant.

Guidelines:
1. Always ask for child's age first - it affects all advice
2. Be sensitive to parental concerns
3. Provide age-appropriate guidance
4. Highlight red flags requiring immediate care
5. Trust parental instinct and err on the side of caution

Response style:
- Keep responses warm and clear (2-3 sentences) for voice conversation
- Be reassuring without dismissing concerns
- Do not introduce yourself by name repeatedly
- Focus on actionable guidance for parents"""
    },
    'nutritionist': {
        'name': 'Nutrition Specialist',
        'specialty': 'Nutrition & Diet',
        'prompt': """You are a certified nutrition assistant focused on healthy eating.

Guidelines:
1. Understand current eating patterns and goals
2. Consider medical conditions and restrictions
3. Provide practical, sustainable dietary advice
4. Focus on whole foods and balanced nutrition
5. Avoid promoting fad diets

Response style:
- Keep responses practical (2-3 sentences) for voice conversation
- Be encouraging and non-judgmental
- Do not introduce yourself repeatedly
- Recommend registered dietitian for complex medical nutrition needs"""
    },
    'cardiologist': {
        'name': 'Cardiology Specialist',
        'specialty': 'Cardiology',
        'prompt': """You are a knowledgeable virtual cardiology assistant.

Guidelines:
1. Take ALL heart-related symptoms seriously
2. Recognize emergency symptoms requiring immediate care
3. Discuss risk factors and prevention
4. Provide heart-healthy lifestyle guidance
5. Encourage regular check-ups

Response style:
- Keep responses clear and calm (2-3 sentences) for voice conversation
- Be reassuring but appropriately serious
- Do not introduce yourself by name in every response
- IMPORTANT: Advise calling emergency services for chest pain, severe breathlessness, or fainting"""
    }
}


MEDICAL_DISCLAIMER = "⚠️ This is AI-generated health guidance, not medical diagnosis. Please consult a licensed healthcare provider for proper medical advice."


@dataclass
class LiveCallSession:
    """Session for live AI medical consultations"""
    session_id: str
    user_id: Optional[int]
    specialist: str
    created_at: datetime
    last_activity: datetime
    conversation_history: deque = field(default_factory=lambda: deque(maxlen=50))
    language_code: str = "en-US"
    total_interactions: int = 0
    patient_context: str = ""
    
    def to_dict(self):
        return {
            'session_id': self.session_id,
            'specialist': self.specialist,
            'specialist_name': MEDICAL_SPECIALISTS.get(self.specialist, {}).get('name', 'Dr. AI'),
            'created_at': self.created_at.isoformat(),
            'total_interactions': self.total_interactions,
            'language': self.language_code
        }
    
    def get_history(self, limit: int = 10) -> List[Dict]:
        """Get recent conversation history"""
        return list(self.conversation_history)[-limit:]


# Active sessions storage (in production, use Redis or database)
active_sessions: Dict[str, LiveCallSession] = {}


def cleanup_old_sessions():
    """Remove sessions older than 1 hour"""
    cutoff = datetime.now() - timedelta(hours=1)
    expired = [sid for sid, s in active_sessions.items() if s.last_activity < cutoff]
    for sid in expired:
        del active_sessions[sid]


def generate_medical_response(session: LiveCallSession, user_input: str) -> str:
    """Generate AI response for medical consultation"""
    
    specialist_config = MEDICAL_SPECIALISTS.get(session.specialist, MEDICAL_SPECIALISTS['physician'])
    system_prompt = specialist_config['prompt']
    
    logger.info(f"Generating response for specialist: {session.specialist} ({specialist_config.get('name', 'Dr. AI')})")
    
    # Get language instruction
    language_name = LANGUAGE_NAMES.get(session.language_code, 'English')
    language_instruction = ""
    if session.language_code != 'en-US':
        language_instruction = f"\n\nIMPORTANT: Respond ENTIRELY in {language_name}. Do not mix languages."
    
    # Include patient context from previous text chat
    patient_context_section = ""
    if session.patient_context:
        patient_context_section = f"\nContext from patient's previous conversation:\n{session.patient_context}\n"
    
    # Get user medical context from database
    medical_context_section = ""
    if session.user_id:
        from app.routes.ai_sathi import get_user_medical_context
        medical_context = get_user_medical_context(session.user_id)
        if medical_context:
            medical_context_section = f"\n{medical_context}\n"
    
    # Build conversation context
    history_context = ""
    if session.conversation_history:
        history_parts = []
        for msg in list(session.conversation_history)[-5:]:
            role = "Patient" if msg.get('role') == 'user' else "You"
            history_parts.append(f"{role}: {msg.get('content', '')}")
        history_context = "\n".join(history_parts)
    
    # Create prompt
    history_section = f"Previous conversation:\n{history_context}\n" if history_context else ""
    prompt = f"""{system_prompt}
{language_instruction}
{medical_context_section}
{patient_context_section}
{history_section}Patient's Current Concern: "{user_input}"

Respond naturally and helpfully. Keep your response concise (2-3 sentences) for voice conversation.
End with a follow-up question or suggestion when appropriate."""

    try:
        # Use g4f for AI response with retry mechanism
        response = ai_call_with_retry(
            model=current_app.config['AI_LIVE_CALL_MODEL'],
            messages=[{"role": "user", "content": prompt}],
            fallback_models=current_app.config.get('AI_LIVE_CALL_MODEL_FALLBACKS', []),
        )
        
        # g4f returns string directly
        if isinstance(response, str):
            ai_response = response.strip()
        else:
            ai_response = response.choices[0].message.content.strip()
        
        # Clean for voice output
        ai_response = clean_for_voice(ai_response)
        
        return ai_response
        
    except Exception as e:
        logger.error(f"Error generating medical response: {e}")
        return "I apologize, but I'm having trouble connecting right now. Please try again in a moment, or if you have urgent concerns, please contact a healthcare provider directly."


def clean_for_voice(text: str) -> str:
    """Clean response for natural voice output"""
    # Strip <think>...</think> tags from DeepSeek R1 responses
    text = re.sub(r'<think>[\s\S]*?</think>', '', text, flags=re.IGNORECASE)
    
    # Remove markdown
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    text = re.sub(r'^- ', '', text, flags=re.MULTILINE)
    text = re.sub(r'^\d+\. ', '', text, flags=re.MULTILINE)
    
    # Improve natural speech
    text = text.replace('...', ', ')
    text = text.replace('  ', ' ')
    
    return text.strip()


@live_ai_bp.route('/live-call/start', methods=['POST'])
def start_live_call():
    """Start a new live AI medical consultation session"""
    try:
        cleanup_old_sessions()
        
        data = request.get_json() or {}
        
        # Manual optional JWT extraction
        user_id = None
        try:
            from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
            verify_jwt_in_request(optional=True)
            user_id = get_jwt_identity()
        except Exception:
            pass  # No valid JWT, continue without user_id
        
        specialist = data.get('specialist', 'physician')
        if specialist not in MEDICAL_SPECIALISTS:
            specialist = 'physician'
        
        session_id = str(uuid.uuid4())
        
        session = LiveCallSession(
            session_id=session_id,
            user_id=user_id,
            specialist=specialist,
            created_at=datetime.now(),
            last_activity=datetime.now(),
            language_code=data.get('language', 'en-US'),
            patient_context=data.get('patient_context', '')
        )
        
        active_sessions[session_id] = session
        
        # Save to AI history if user is logged in
        if user_id:
            try:
                from app.routes.ai_history import create_conversation, add_message
                ai_conv = create_conversation(
                    user_id=int(user_id),
                    conversation_type='voice_call',
                    specialist_type=specialist,
                    session_id=session_id,
                    language_code=data.get('language', 'en-US')
                )
                session.ai_conversation_id = ai_conv.id
            except Exception as e:
                logger.error(f"Error creating AI conversation: {e}")
        
        specialist_config = MEDICAL_SPECIALISTS.get(specialist, {})
        
        return jsonify({
            "status": "success",
            "message": "Live consultation session started",
            "session_id": session_id,
            "session_info": session.to_dict(),
            "greeting": f"Hello! I'm {specialist_config.get('name', 'Dr. AI')}, your virtual {specialist_config.get('specialty', 'health')} assistant. How can I help you today?"
        })
        
    except Exception as e:
        logger.error(f"Error starting live call: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500


@live_ai_bp.route('/live-call/speech', methods=['POST'])
def process_speech():
    """Process patient speech and generate AI response with audio"""
    try:
        data = request.get_json()
        
        if not data or 'session_id' not in data or 'text' not in data:
            return jsonify({"status": "error", "message": "Missing required parameters"}), 400
        
        session_id = data['session_id']
        text = data['text'].strip()
        
        if session_id not in active_sessions:
            return jsonify({"status": "error", "message": "Invalid or expired session"}), 404
        
        session = active_sessions[session_id]
        session.last_activity = datetime.now()
        session.total_interactions += 1
        
        # Add user message to history
        session.conversation_history.append({
            'role': 'user',
            'content': text,
            'timestamp': datetime.now().isoformat()
        })
        
        # Generate AI response
        ai_response = generate_medical_response(session, text)
        
        # Add AI response to history
        session.conversation_history.append({
            'role': 'assistant',
            'content': ai_response,
            'timestamp': datetime.now().isoformat()
        })
        
        # Save to AI history
        if hasattr(session, 'ai_conversation_id') and session.ai_conversation_id:
            try:
                from app.routes.ai_history import add_message
                add_message(session.ai_conversation_id, 'user', text)
                add_message(session.ai_conversation_id, 'assistant', ai_response)
            except Exception as e:
                logger.error(f"Error saving to AI history: {e}")
        
        # Generate audio if TTS available
        audio_result = None
        if TTS_AVAILABLE and speech_generator:
            audio_result = speech_generator.generate_speech(
                text=ai_response,
                voice=get_optimal_voice(session.language_code),
                language_code=session.language_code
            )
        
        response = {
            "status": "success",
            "text": ai_response,
            "session_id": session_id,
            "interaction_count": session.total_interactions
        }
        
        if audio_result and audio_result.get('status') == 'success':
            # Build audio URL - use direct path without duplication
            server_url = request.url_root.rstrip('/')
            filename = audio_result.get('filename')
            response['audio_url'] = f"{server_url}/api/ai-sathi/audio/{filename}"
            response['filename'] = filename
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error processing speech: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500


@live_ai_bp.route('/live-call/end', methods=['POST'])
def end_live_call():
    """End the live consultation session"""
    try:
        data = request.get_json() or {}
        session_id = data.get('session_id')
        
        if not session_id:
            return jsonify({"status": "error", "message": "Missing session_id"}), 400
        
        if session_id in active_sessions:
            session = active_sessions.pop(session_id)
            duration = datetime.now() - session.created_at
            
            # End conversation in AI history
            if hasattr(session, 'ai_conversation_id') and session.ai_conversation_id:
                try:
                    from app.routes.ai_history import end_conversation
                    end_conversation(session.ai_conversation_id)
                except Exception as e:
                    logger.error(f"Error ending AI conversation: {e}")
            
            return jsonify({
                "status": "success",
                "message": "Consultation session ended",
                "summary": {
                    "session_id": session_id,
                    "specialist": session.specialist,
                    "duration_seconds": int(duration.total_seconds()),
                    "total_interactions": session.total_interactions
                },
                "reminder": MEDICAL_DISCLAIMER
            })
        
        return jsonify({"status": "error", "message": "Session not found"}), 404
        
    except Exception as e:
        logger.error(f"Error ending live call: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500


@live_ai_bp.route('/live-call/keep-alive', methods=['POST'])
def keep_alive():
    """Keep session alive"""
    data = request.get_json() or {}
    session_id = data.get('session_id')
    
    if session_id and session_id in active_sessions:
        active_sessions[session_id].last_activity = datetime.now()
        return jsonify({"status": "success"})
    
    return jsonify({"status": "error", "message": "Session not found"}), 404


@live_ai_bp.route('/audio/<filename>')
def serve_audio(filename):
    """Serve generated audio files"""
    file_path = os.path.join(AUDIO_OUTPUT_DIR, filename)
    if os.path.exists(file_path):
        return send_file(file_path, mimetype='audio/wav')
    return jsonify({"status": "error", "message": "Audio file not found"}), 404


@live_ai_bp.route('/specialists', methods=['GET'])
def get_specialists():
    """Get available medical specialists for live consultation"""
    specialists = [
        {
            'id': key,
            'name': config['name'],
            'specialty': config['specialty'],
            'description': f"Consult with {config['name']} for {config['specialty'].lower()} concerns"
        }
        for key, config in MEDICAL_SPECIALISTS.items()
    ]
    return jsonify(specialists)
