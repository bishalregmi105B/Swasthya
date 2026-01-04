"""
User Health Insights Cron Handler
Analyzes user profiles and medical history using AI to generate personalized 
health notifications and sends them once per day
"""

from datetime import datetime, timedelta
import json
import os
import re
from .base import BaseCronHandler


class UserHealthInsightsHandler(BaseCronHandler):
    """
    Analyzes user medical data with AI and sends personalized daily health insights
    """
    
    name = "UserHealthInsightsHandler"
    
    # Only send insights once per day (24 hours)
    INSIGHT_COOLDOWN_HOURS = int(os.getenv('CRON_HEALTH_INSIGHT_HOURS', '24'))
    
    # Maximum users to process per run (for performance)
    MAX_USERS_PER_RUN = int(os.getenv('CRON_HEALTH_INSIGHT_MAX_USERS', '100'))
    
    def execute(self, dry_run: bool = False):
        """
        Analyze user health data and send personalized AI-generated insights
        """
        from app import db
        from app.models.user import User
        from app.models.medical_history import (
            MedicalRecord, MedicalCondition, MedicalAllergy, 
            MedicalMedication, MedicalSurgery, MedicalVaccination
        )
        from app.routes.notifications import send_onesignal_notification
        
        # Get users who have push notifications enabled
        users = User.query.filter(
            User.is_active == True,
            User.notification_push == True
        ).limit(self.MAX_USERS_PER_RUN).all()
        
        self.logger.info(f"Processing health insights for {len(users)} users")
        
        for user in users:
            try:
                # Check if we already sent insight today
                if self._was_insight_sent_today(user.id):
                    self.log_skipped(f"User {user.id} already received insight today")
                    continue
                
                # Get user's medical data
                medical_data = self._get_user_medical_data(user)
                
                # Skip users with no medical data (optional - could send general tips)
                if not medical_data['has_data']:
                    self.log_skipped(f"User {user.id} has no medical data")
                    continue
                
                # Generate AI insight
                insight = self._generate_ai_insight(user, medical_data, dry_run)
                
                if not insight:
                    self.log_failed(f"Failed to generate insight for user {user.id}")
                    continue
                
                if dry_run:
                    self.logger.info(
                        f"[DRY RUN] Would send to {user.full_name}: {insight['title']}"
                    )
                    self.log_success(f"[DRY RUN] User {user.id}")
                else:
                    # Send push notification
                    result = send_onesignal_notification(
                        title=insight['title'],
                        message=insight['message'],
                        user_ids=[str(user.id)],
                        data={
                            'type': 'health_insight',
                            'user_id': str(user.id),
                            'insight_type': insight.get('type', 'general'),
                            'action': insight.get('action', 'open_health')
                        }
                    )
                    
                    if 'id' in result or 'recipients' in result:
                        self.log_success(f"Sent health insight to {user.full_name}")
                        self._mark_insight_sent(user.id)
                    else:
                        self.log_failed(
                            f"Failed to send insight to user {user.id}",
                            error=str(result.get('errors', result))
                        )
            
            except Exception as e:
                self.log_failed(f"Error processing user {user.id}", error=str(e))
    
    def _get_user_medical_data(self, user) -> dict:
        """
        Gather all medical data for a user
        """
        from app.models.medical_history import (
            MedicalRecord, MedicalCondition, MedicalAllergy,
            MedicalMedication, MedicalSurgery, MedicalVaccination
        )
        from app.models.reminder import MedicineReminder
        
        data = {
            'has_data': False,
            'profile': {},
            'conditions': [],
            'allergies': [],
            'medications': [],
            'surgeries': [],
            'vaccinations': [],
            'reminders': []
        }
        
        # User profile data
        data['profile'] = {
            'name': user.full_name,
            'age': self._calculate_age(user.date_of_birth),
            'gender': user.gender,
            'blood_type': user.blood_type,
            'city': user.city
        }
        
        # Get medical record
        record = MedicalRecord.query.filter_by(user_id=user.id).first()
        
        if record:
            data['has_data'] = True
            
            # Add base record info
            if record.height_cm:
                data['profile']['height'] = float(record.height_cm)
            if record.weight_kg:
                data['profile']['weight'] = float(record.weight_kg)
            if record.smoking_status:
                data['profile']['smoking'] = record.smoking_status
            if record.alcohol_use:
                data['profile']['alcohol'] = record.alcohol_use
            if record.exercise_frequency:
                data['profile']['exercise'] = record.exercise_frequency
            
            # Get conditions
            conditions = MedicalCondition.query.filter_by(
                record_id=record.id, 
                status='active'
            ).all()
            data['conditions'] = [
                {'name': c.name, 'severity': c.severity, 'diagnosed': str(c.diagnosed_date) if c.diagnosed_date else None}
                for c in conditions
            ]
            
            # Get allergies
            allergies = MedicalAllergy.query.filter_by(record_id=record.id).all()
            data['allergies'] = [
                {'allergen': a.allergen, 'severity': a.severity, 'reaction': a.reaction}
                for a in allergies
            ]
            
            # Get current medications
            medications = MedicalMedication.query.filter_by(
                record_id=record.id,
                is_active=True
            ).all()
            data['medications'] = [
                {'name': m.name, 'dosage': m.dosage, 'frequency': m.frequency}
                for m in medications
            ]
            
            # Get recent surgeries (last 2 years)
            two_years_ago = datetime.utcnow().date() - timedelta(days=730)
            surgeries = MedicalSurgery.query.filter(
                MedicalSurgery.record_id == record.id,
                MedicalSurgery.surgery_date >= two_years_ago
            ).all()
            data['surgeries'] = [
                {'name': s.procedure_name, 'date': str(s.surgery_date) if s.surgery_date else None}
                for s in surgeries
            ]
            
            # Get vaccinations (for reminders)
            vaccinations = MedicalVaccination.query.filter_by(record_id=record.id).all()
            data['vaccinations'] = [
                {'name': v.vaccine_name, 'date': str(v.administered_date) if v.administered_date else None, 'next_due': str(v.next_due_date) if v.next_due_date else None}
                for v in vaccinations
            ]
        
        # Get active medicine reminders
        reminders = MedicineReminder.query.filter_by(
            user_id=user.id,
            is_active=True
        ).all()
        if reminders:
            data['has_data'] = True
            data['reminders'] = [
                {'medicine': r.medicine_name, 'times_per_day': r.times_per_day}
                for r in reminders
            ]
        
        return data
    
    def _calculate_age(self, dob) -> int:
        """Calculate age from date of birth"""
        if not dob:
            return None
        today = datetime.utcnow().date()
        return today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
    
    def _generate_ai_insight(self, user, medical_data: dict, dry_run: bool = False) -> dict:
        """
        Use AI to generate personalized health insight based on user's medical data
        """
        from flask import current_app
        from app.routes.ai_sathi import ai_call_with_retry
        
        # Build context from medical data
        context_parts = []
        
        profile = medical_data['profile']
        if profile.get('age'):
            context_parts.append(f"Age: {profile['age']} years")
        if profile.get('gender'):
            context_parts.append(f"Gender: {profile['gender']}")
        if profile.get('blood_type'):
            context_parts.append(f"Blood Type: {profile['blood_type']}")
        if profile.get('weight') and profile.get('height'):
            bmi = profile['weight'] / ((profile['height']/100) ** 2)
            context_parts.append(f"BMI: {bmi:.1f}")
        if profile.get('blood_pressure'):
            context_parts.append(f"Blood Pressure: {profile['blood_pressure']}")
        if profile.get('smoking'):
            context_parts.append(f"Smoking: {profile['smoking']}")
        if profile.get('exercise'):
            context_parts.append(f"Exercise level: {profile['exercise']}")
        
        if medical_data['conditions']:
            conditions_str = ", ".join([c['name'] for c in medical_data['conditions']])
            context_parts.append(f"Medical Conditions: {conditions_str}")
        
        if medical_data['allergies']:
            allergies_str = ", ".join([a['allergen'] for a in medical_data['allergies']])
            context_parts.append(f"Allergies: {allergies_str}")
        
        if medical_data['medications']:
            meds_str = ", ".join([m['name'] for m in medical_data['medications']])
            context_parts.append(f"Current Medications: {meds_str}")
        
        if medical_data['reminders']:
            reminder_str = ", ".join([r['medicine'] for r in medical_data['reminders']])
            context_parts.append(f"Medicine Reminders: {reminder_str}")
        
        # Get current date for seasonal tips
        now = datetime.now()
        month = now.strftime("%B")
        day_of_week = now.strftime("%A")
        
        user_context = "\n".join(context_parts) if context_parts else "No specific health data available."
        
        prompt = f"""You are a caring personal health advisor. Generate ONE personalized health insight or tip for this user.

USER HEALTH PROFILE:
{user_context}

CONTEXT:
- Today is {day_of_week}, {month} {now.day}
- Location: Nepal
- This is a daily health notification

IMPORTANT INSTRUCTIONS:
1. Create ONE short, actionable health insight (2-3 sentences max)
2. Make it PERSONALIZED based on their conditions/medications/lifestyle
3. Be motivating and positive, not alarming
4. If they have specific conditions, provide relevant tips
5. Consider the day/season for timely advice
6. The message should feel like it's from a caring friend, not a doctor

Return ONLY valid JSON in this exact format:
{{
    "title": "Short emoji + title (max 5 words)",
    "message": "Personalized health insight (2-3 sentences)",
    "type": "lifestyle|medication|condition|prevention|motivation",
    "action": "open_health|open_reminders|open_tips"
}}

OUTPUT ONLY THE JSON, NO OTHER TEXT."""

        if dry_run:
            # Return mock insight for dry run
            return {
                'title': '💪 Daily Health Tip',
                'message': f'[DRY RUN] Personalized insight for {user.full_name} based on their health profile.',
                'type': 'general',
                'action': 'open_health'
            }
        
        try:
            response = ai_call_with_retry(
                model=current_app.config['AI_HEALTH_TIPS_MODEL'],
                messages=[
                    {'role': 'system', 'content': 'You are a health insight generator. Return ONLY valid JSON, no other text.'},
                    {'role': 'user', 'content': prompt}
                ],
                fallback_models=current_app.config.get('AI_HEALTH_TIPS_MODEL_FALLBACKS', []),
            )
            
            # Strip think tags
            response = re.sub(r'<think>[\s\S]*?</think>', '', response, flags=re.IGNORECASE).strip()
            
            # Extract JSON
            json_match = re.search(r'\{[\s\S]*\}', response)
            if json_match:
                insight = json.loads(json_match.group())
                return insight
            else:
                self.logger.error(f"No JSON found in AI response: {response[:200]}")
                return None
                
        except Exception as e:
            self.logger.error(f"AI call failed: {e}")
            return None
    
    def _was_insight_sent_today(self, user_id: int) -> bool:
        """Check if insight was already sent to user within cooldown period"""
        from app import db
        from app.models.reminder import ReminderLog
        
        # Use reminder log with special reminder_id = -1 for health insights
        # Or we could create a separate table for insight logs
        cutoff = datetime.utcnow() - timedelta(hours=self.INSIGHT_COOLDOWN_HOURS)
        
        # Check if we have a log entry for health insight
        # For simplicity, we'll use an in-memory cache for now
        # In production, you'd want to use a database table
        cache_key = f"insight_{user_id}_{datetime.utcnow().date()}"
        
        if hasattr(self, '_insight_cache') and cache_key in self._insight_cache:
            return True
        
        return False
    
    def _mark_insight_sent(self, user_id: int):
        """Mark that we've sent an insight to this user today"""
        if not hasattr(self, '_insight_cache'):
            self._insight_cache = {}
        
        cache_key = f"insight_{user_id}_{datetime.utcnow().date()}"
        self._insight_cache[cache_key] = datetime.utcnow()
