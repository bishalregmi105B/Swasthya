"""
General Health Tips Cron Handler
Generates AI-powered general health tips and sends to all users hourly
"""

from datetime import datetime, timedelta
import json
import os
import re
from .base import BaseCronHandler


class GeneralHealthTipsHandler(BaseCronHandler):
    """
    Sends AI-generated general health tips to all users hourly
    """
    
    name = "GeneralHealthTipsHandler"
    
    # Maximum users to process per batch
    BATCH_SIZE = int(os.getenv('CRON_HEALTH_TIPS_BATCH', '500'))
    
    # Categories of health tips to rotate through
    TIP_CATEGORIES = [
        'hydration',      # 0:00, 8:00, 16:00
        'nutrition',      # 1:00, 9:00, 17:00
        'exercise',       # 2:00, 10:00, 18:00
        'mental_health',  # 3:00, 11:00, 19:00
        'sleep',          # 4:00, 12:00, 20:00
        'hygiene',        # 5:00, 13:00, 21:00
        'safety',         # 6:00, 14:00, 22:00
        'prevention',     # 7:00, 15:00, 23:00
    ]
    
    def execute(self, dry_run: bool = False):
        """
        Generate and send general health tip to all users
        """
        from app import db
        from app.models.user import User
        from app.routes.notifications import send_onesignal_notification
        
        # Get current hour to determine tip category
        current_hour = datetime.now().hour
        category_index = current_hour % len(self.TIP_CATEGORIES)
        category = self.TIP_CATEGORIES[category_index]
        
        self.logger.info(f"Generating {category} tip for hour {current_hour}")
        
        # Generate tip using AI
        tip = self._generate_health_tip(category, dry_run)
        
        if not tip:
            self.log_failed("Failed to generate health tip")
            return
        
        if dry_run:
            self.logger.info(f"[DRY RUN] Would send: {tip['title']} - {tip['message'][:50]}...")
            self.log_success("[DRY RUN] Tip generated successfully")
            return
        
        # Send to all users with push notifications enabled using segment
        # Using 'Subscribed Users' segment to send to all subscribed users
        try:
            result = send_onesignal_notification(
                title=tip['title'],
                message=tip['message'],
                segments=['Subscribed Users'],  # Send to all subscribed users
                data={
                    'type': 'health_tip',
                    'category': category,
                    'tip_id': f"{datetime.now().strftime('%Y%m%d%H')}_{category}",
                    'action': 'open_tips'
                }
            )
            
            if 'id' in result or 'recipients' in result:
                recipients = result.get('recipients', 'all')
                self.log_success(f"Sent {category} tip to {recipients} users")
                self.logger.info(f"OneSignal Response: {result}")
            else:
                self.log_failed(
                    f"Failed to send {category} tip",
                    error=str(result.get('errors', result))
                )
        except Exception as e:
            self.log_failed(f"Error sending notification", error=str(e))
    
    def _generate_health_tip(self, category: str, dry_run: bool = False) -> dict:
        """
        Generate a health tip for the given category using AI
        """
        from flask import current_app
        from app.routes.ai_sathi import ai_call_with_retry
        
        # Get current context
        now = datetime.now()
        month = now.strftime("%B")
        day_of_week = now.strftime("%A")
        hour = now.hour
        
        # Time of day context
        if 5 <= hour < 12:
            time_context = "morning"
        elif 12 <= hour < 17:
            time_context = "afternoon"
        elif 17 <= hour < 21:
            time_context = "evening"
        else:
            time_context = "night"
        
        category_prompts = {
            'hydration': "water intake, staying hydrated, benefits of drinking water",
            'nutrition': "healthy eating, balanced diet, food choices, nutrients",
            'exercise': "physical activity, workout tips, fitness, stretching",
            'mental_health': "stress management, mindfulness, mental wellness, relaxation",
            'sleep': "sleep hygiene, rest, quality sleep, bedtime routine",
            'hygiene': "personal hygiene, cleanliness, washing hands, oral health",
            'safety': "accident prevention, home safety, first aid awareness",
            'prevention': "disease prevention, immunity, vaccinations, health checkups",
        }
        
        prompt = f"""You are a friendly health advisor. Generate ONE short, engaging health tip.

CATEGORY: {category} ({category_prompts.get(category, 'general health')})
TIME: {time_context} ({day_of_week}, {month})
LOCATION: Nepal

REQUIREMENTS:
1. Make it SHORT (1-2 sentences max)
2. Be practical and actionable
3. Relevant to the time of day
4. Friendly and encouraging tone
5. Include an appropriate emoji in the title

Return ONLY valid JSON:
{{
    "title": "Emoji + Short Title (3-5 words)",
    "message": "Brief actionable tip (1-2 sentences)"
}}

OUTPUT ONLY THE JSON, NO OTHER TEXT."""

        if dry_run:
            # Return mock tip for dry run
            mock_tips = {
                'hydration': {'title': '💧 Stay Hydrated!', 'message': 'Drink a glass of water right now. Your body needs 8 glasses daily!'},
                'nutrition': {'title': '🥗 Eat Your Greens', 'message': 'Add a serving of vegetables to your next meal for better health.'},
                'exercise': {'title': '🏃 Move Your Body', 'message': 'Take a 5-minute walk or do some stretches. Every movement counts!'},
                'mental_health': {'title': '🧘 Take a Deep Breath', 'message': 'Pause for 3 deep breaths. It calms your mind and reduces stress.'},
                'sleep': {'title': '😴 Rest Well Tonight', 'message': 'Put away screens 30 mins before bed for better sleep quality.'},
                'hygiene': {'title': '🧼 Wash Your Hands', 'message': 'Clean hands prevent 80% of common infections. Use soap for 20 seconds!'},
                'safety': {'title': '🛡️ Safety First', 'message': 'Check your smoke detector batteries this month. Prevention saves lives!'},
                'prevention': {'title': '💪 Boost Your Immunity', 'message': 'Include vitamin C rich foods like oranges and lemons in your diet.'},
            }
            return mock_tips.get(category, {'title': '❤️ Health Tip', 'message': 'Take care of yourself today!'})
        
        try:
            response = ai_call_with_retry(
                model=current_app.config['AI_HEALTH_TIPS_MODEL'],
                messages=[
                    {'role': 'system', 'content': 'You are a health tip generator. Return ONLY valid JSON.'},
                    {'role': 'user', 'content': prompt}
                ],
                fallback_models=current_app.config.get('AI_HEALTH_TIPS_MODEL_FALLBACKS', []),
            )
            
            # Strip think tags
            response = re.sub(r'<think>[\s\S]*?</think>', '', response, flags=re.IGNORECASE).strip()
            
            # Extract JSON
            json_match = re.search(r'\{[\s\S]*\}', response)
            if json_match:
                tip = json.loads(json_match.group())
                return tip
            else:
                self.logger.error(f"No JSON found in AI response: {response[:200]}")
                return None
                
        except Exception as e:
            self.logger.error(f"AI call failed: {e}")
            return None
