"""
AI Chat History Routes
API endpoints for managing centralized AI conversation history.
Supports both text chat (AI Sathi) and voice call history.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from app import db
from app.models import AIConversation, AIMessage

ai_history_bp = Blueprint('ai_history', __name__)


@ai_history_bp.route('/conversations', methods=['GET'])
@jwt_required()
def get_conversations():
    """
    Get all AI conversations for the current user.
    
    Query params:
    - type: filter by conversation_type ('chat', 'voice_call')
    - specialist: filter by specialist_type 
    - limit: max results (default 50)
    - offset: pagination offset (default 0)
    """
    user_id = int(get_jwt_identity())
    
    # Build query
    query = AIConversation.query.filter_by(user_id=user_id)
    
    # Filters
    conv_type = request.args.get('type')
    if conv_type:
        query = query.filter_by(conversation_type=conv_type)
    
    specialist = request.args.get('specialist')
    if specialist:
        query = query.filter_by(specialist_type=specialist)
    
    # Order by most recent first
    query = query.order_by(AIConversation.started_at.desc())
    
    # Pagination
    limit = min(int(request.args.get('limit', 50)), 100)
    offset = int(request.args.get('offset', 0))
    
    total = query.count()
    conversations = query.offset(offset).limit(limit).all()
    
    return jsonify({
        'conversations': [c.to_dict() for c in conversations],
        'total': total,
        'limit': limit,
        'offset': offset
    })


@ai_history_bp.route('/conversations/<int:conversation_id>', methods=['GET'])
@jwt_required()
def get_conversation(conversation_id):
    """Get a single conversation with all its messages"""
    user_id = int(get_jwt_identity())
    
    conversation = AIConversation.query.filter_by(
        id=conversation_id, 
        user_id=user_id
    ).first()
    
    if not conversation:
        return jsonify({'error': 'Conversation not found'}), 404
    
    return jsonify({
        'conversation': conversation.to_dict(include_messages=True)
    })


@ai_history_bp.route('/conversations/<int:conversation_id>', methods=['DELETE'])
@jwt_required()
def delete_conversation(conversation_id):
    """Delete a conversation and all its messages"""
    user_id = int(get_jwt_identity())
    
    conversation = AIConversation.query.filter_by(
        id=conversation_id, 
        user_id=user_id
    ).first()
    
    if not conversation:
        return jsonify({'error': 'Conversation not found'}), 404
    
    db.session.delete(conversation)
    db.session.commit()
    
    return jsonify({'message': 'Conversation deleted successfully'})


@ai_history_bp.route('/conversations', methods=['DELETE'])
@jwt_required()
def clear_all_conversations():
    """Delete all conversations for the current user"""
    user_id = int(get_jwt_identity())
    
    deleted_count = AIConversation.query.filter_by(user_id=user_id).delete()
    db.session.commit()
    
    return jsonify({
        'message': f'Deleted {deleted_count} conversations'
    })


@ai_history_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_stats():
    """Get AI usage statistics for current user"""
    user_id = int(get_jwt_identity())
    
    total_conversations = AIConversation.query.filter_by(user_id=user_id).count()
    total_messages = db.session.query(AIMessage).join(AIConversation).filter(
        AIConversation.user_id == user_id
    ).count()
    
    chat_count = AIConversation.query.filter_by(
        user_id=user_id, 
        conversation_type='chat'
    ).count()
    
    voice_count = AIConversation.query.filter_by(
        user_id=user_id, 
        conversation_type='voice_call'
    ).count()
    
    # Get specialist breakdown
    specialists = db.session.query(
        AIConversation.specialist_type, 
        db.func.count(AIConversation.id)
    ).filter_by(user_id=user_id).group_by(
        AIConversation.specialist_type
    ).all()
    
    return jsonify({
        'total_conversations': total_conversations,
        'total_messages': total_messages,
        'chat_conversations': chat_count,
        'voice_conversations': voice_count,
        'by_specialist': {s[0]: s[1] for s in specialists}
    })


# Helper functions for other routes to save messages

def create_conversation(user_id: int, conversation_type: str, specialist_type: str, 
                       session_id: str, language_code: str = 'en-US') -> AIConversation:
    """Create a new AI conversation"""
    conversation = AIConversation(
        user_id=user_id,
        session_id=session_id,
        conversation_type=conversation_type,
        specialist_type=specialist_type,
        language_code=language_code,
        started_at=datetime.utcnow()
    )
    db.session.add(conversation)
    db.session.commit()
    return conversation


def add_message(conversation_id: int, role: str, content: str, 
                audio_url: str = None) -> AIMessage:
    """Add a message to a conversation"""
    message = AIMessage(
        conversation_id=conversation_id,
        role=role,
        content=content,
        audio_url=audio_url
    )
    db.session.add(message)
    
    # Update message count
    conversation = AIConversation.query.get(conversation_id)
    if conversation:
        conversation.total_messages = (conversation.total_messages or 0) + 1
    
    db.session.commit()
    return message


def end_conversation(conversation_id: int, summary: str = None):
    """Mark conversation as ended"""
    conversation = AIConversation.query.get(conversation_id)
    if conversation:
        conversation.ended_at = datetime.utcnow()
        if summary:
            conversation.summary = summary
        db.session.commit()


def get_or_create_conversation(user_id: int, session_id: str, conversation_type: str,
                                specialist_type: str, language_code: str = 'en-US') -> AIConversation:
    """Get existing conversation by session_id or create new one"""
    conversation = AIConversation.query.filter_by(session_id=session_id).first()
    if not conversation:
        conversation = create_conversation(
            user_id=user_id,
            conversation_type=conversation_type,
            specialist_type=specialist_type,
            session_id=session_id,
            language_code=language_code
        )
    return conversation
