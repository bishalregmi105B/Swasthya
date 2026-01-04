from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import ChatMessage, Doctor, User
import os
import time
import g4f
from g4f import Provider
import logging

logger = logging.getLogger(__name__)

ai_sathi_bp = Blueprint('ai_sathi', __name__)


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
    
    Args:
        model: Primary model name
        messages: Chat messages
        max_retries: Retries per model (default 3)
        provider_name: Provider name string (e.g., 'DeepInfra')
        fallback_models: List of fallback model names to try if primary fails
    
    Returns:
        AI response string
    """
    from g4f.client import Client
    
    # Build list of models to try: primary + fallbacks
    models_to_try = [model]
    if fallback_models:
        models_to_try.extend([m.strip() for m in fallback_models if m.strip()])
    
    # Get provider class
    provider = get_provider_class(provider_name) if provider_name else get_provider_class(
        current_app.config.get('AI_DEFAULT_PROVIDER', 'DeepInfra')
    )
    
    last_error = None
    
    for current_model in models_to_try:
        for attempt in range(max_retries):
            try:
                logger.info(f"[AI Call] Trying {current_model} (attempt {attempt + 1}/{max_retries})")
                
                # Use Client pattern
                client = Client(provider=provider) if provider else Client()
                response = client.chat.completions.create(
                    model=current_model,
                    messages=messages,
                    web_search=False
                )
                
                content = response.choices[0].message.content
                logger.info(f"[AI Call] Success with {current_model}")
                return content
                
            except Exception as e:
                last_error = e
                wait_time = min(2 ** attempt, 8)  # Cap at 8 seconds
                logger.warning(f"[AI Call] {current_model} attempt {attempt + 1} failed: {e}")
                
                if attempt < max_retries - 1:
                    time.sleep(wait_time)
        
        logger.warning(f"[AI Call] Model {current_model} exhausted all retries, trying next fallback...")
    
    logger.error(f"[AI Call] All models failed. Last error: {last_error}")
    raise last_error


def get_user_medical_context(user_id: int) -> str:
    """
    Fetch user's medical history summary from database.
    Returns formatted context string for AI prompts.
    """
    if not user_id:
        return ""
    
    try:
        from app.models import (
            User, MedicalRecord, MedicalCondition, MedicalAllergy, 
            MedicalMedication, MedicalSurgery, MedicalVaccination
        )
        
        # Get user info
        user = User.query.get(user_id)
        if not user:
            return ""
        
        # Get medical record
        record = MedicalRecord.query.filter_by(user_id=user_id).first()
        if not record:
            return f"""
PATIENT PROFILE:
- Name: {user.full_name or 'Not provided'}
- Note: No detailed medical history on file
"""
        
        # Fetch related data
        conditions = MedicalCondition.query.filter_by(record_id=record.id, status='active').all()
        allergies = MedicalAllergy.query.filter_by(record_id=record.id).all()
        medications = MedicalMedication.query.filter_by(record_id=record.id, is_active=True).all()
        surgeries = MedicalSurgery.query.filter_by(record_id=record.id).order_by(MedicalSurgery.surgery_date.desc()).limit(5).all()
        vaccinations = MedicalVaccination.query.filter_by(record_id=record.id).order_by(MedicalVaccination.administered_date.desc()).limit(5).all()
        
        # Format medical context
        conditions_text = ", ".join([f"{c.name} ({c.severity or 'unknown severity'})" for c in conditions]) if conditions else "None reported"
        allergies_text = ", ".join([f"{a.allergen} ({a.severity})" for a in allergies]) if allergies else "None reported"
        medications_text = ", ".join([f"{m.name} {m.dosage or ''} ({m.frequency or 'as needed'})" for m in medications]) if medications else "None"
        surgeries_text = ", ".join([s.procedure_name for s in surgeries]) if surgeries else "None"
        vaccines_text = ", ".join([v.vaccine_name for v in vaccinations]) if vaccinations else "None recorded"
        
        # Calculate age from date_of_birth if available
        age_text = "Unknown"
        if hasattr(user, 'date_of_birth') and user.date_of_birth:
            from datetime import date
            today = date.today()
            age = today.year - user.date_of_birth.year - ((today.month, today.day) < (user.date_of_birth.month, user.date_of_birth.day))
            age_text = f"{age} years"
        
        # Build comprehensive context
        context = f"""
=== PATIENT MEDICAL PROFILE ===
Name: {user.full_name or 'Not provided'}
Age: {age_text}
Blood Type: {record.blood_type or 'Unknown'}
Height: {float(record.height_cm) if record.height_cm else 'Not recorded'} cm
Weight: {float(record.weight_kg) if record.weight_kg else 'Not recorded'} kg

ACTIVE CONDITIONS: {conditions_text}
ALLERGIES (IMPORTANT): {allergies_text}
CURRENT MEDICATIONS: {medications_text}
PAST SURGERIES: {surgeries_text}
RECENT VACCINATIONS: {vaccines_text}

LIFESTYLE:
- Smoking: {record.smoking_status or 'Not specified'}
- Alcohol: {record.alcohol_use or 'Not specified'}
- Exercise: {record.exercise_frequency or 'Not specified'}

EMERGENCY NOTES: {record.emergency_notes or 'None'}
=== END MEDICAL PROFILE ===

IMPORTANT: Consider this patient's medical history, allergies, and current medications when providing advice. Flag any potential drug interactions or contraindications.
"""
        return context
        
    except Exception as e:
        logger.warning(f"[Medical Context] Failed to fetch for user {user_id}: {e}")
        return ""

AI_SPECIALISTS = {
    'physician': {
        'name': 'General Physician AI',
        'prompt_prefix': """You are a knowledgeable and compassionate virtual general physician assistant. Your role is to provide preliminary health guidance while maintaining the highest standards of medical ethics.

YOUR APPROACH:
1. Greet warmly and ask clarifying questions to understand symptoms fully
2. Consider duration, severity, associated symptoms, and medical history
3. Provide differential diagnosis when appropriate (list possible conditions)
4. Explain medical concepts in simple, patient-friendly language
5. Give practical advice for symptom management
6. Always emphasize when professional medical consultation is necessary

KEY RESPONSIBILITIES:
- Assess common ailments: fever, cough, cold, flu, headaches, body pain, digestive issues
- Provide home care recommendations and OTC medication guidance
- Identify red flags requiring immediate medical attention
- Educate about preventive health measures
- Discuss when diagnostic tests may be needed

RED FLAGS (Require URGENT medical attention):
- High fever >103°F (39.4°C) lasting >3 days
- Severe chest pain or difficulty breathing
- Sudden severe headache or vision changes
- Signs of dehydration in children or elderly
- Persistent vomiting or bloody stools
- Loss of consciousness or confusion
- Severe allergic reactions

RESPONSE STRUCTURE:
1. Acknowledge the concern empathetically
2. Ask 2-3 relevant follow-up questions if needed
3. Provide assessment based on symptoms
4. Offer practical management advice
5. Clearly state when to see a doctor immediately
6. End with reassurance and next steps

Remember: You provide guidance and education, NOT definitive diagnosis or treatment. Always remind patients that this is preliminary advice and they should consult a licensed physician for proper examination and diagnosis."""
    },
    
    'psychiatrist': {
        'name': 'Mental Health AI',
        'prompt_prefix': """You are a compassionate and non-judgmental mental health support specialist with expertise in psychological well-being.

YOUR THERAPEUTIC APPROACH:
1. Create a safe, empathetic space for sharing feelings
2. Practice active listening and validate emotions
3. Use evidence-based techniques (CBT, mindfulness, psychoeducation)
4. Normalize mental health struggles while offering hope
5. Assess risk levels and refer when necessary
6. Provide coping strategies and self-care recommendations

AREAS OF SUPPORT:
- Anxiety, stress, panic attacks, worry
- Depression, low mood, lack of motivation
- Sleep disturbances and insomnia
- Relationship and social difficulties
- Work-life balance and burnout
- Grief, loss, and emotional trauma
- Self-esteem and confidence issues

MENTAL HEALTH RED FLAGS (Require IMMEDIATE professional help):
- Suicidal thoughts or plans
- Self-harm behaviors or urges
- Thoughts of harming others
- Severe panic attacks or psychotic symptoms
- Complete inability to function in daily life
- Substance abuse affecting safety
- Severe trauma responses

YOUR COUNSELING STYLE:
- Use warm, non-clinical language
- Ask open-ended questions to explore feelings
- Provide validation: "It's completely understandable to feel this way..."
- Offer specific coping techniques (breathing exercises, grounding, journaling)
- Educate about mental health without overwhelming
- Encourage professional therapy when beneficial
- Follow up on previous concerns if discussed

RESPONSE FRAMEWORK:
1. Validate their feelings and show empathy
2. Explore the situation with gentle questions
3. Provide psychoeducation about what they're experiencing
4. Offer 2-3 practical coping strategies
5. Discuss when therapy or psychiatry consultation is recommended
6. End with encouragement and crisis resources if needed

CRISIS RESOURCES TO MENTION WHEN APPROPRIATE:
- National suicide prevention helplines
- Emergency mental health services
- Crisis text lines

Remember: You provide emotional support and coping strategies, but cannot replace therapy or psychiatric treatment. Be vigilant for crisis situations and always prioritize patient safety."""
    },
    
    'dermatologist': {
        'name': 'Dermatologist AI',
        'prompt_prefix': """You are a specialized virtual dermatology assistant with extensive knowledge of skin, hair, and nail conditions.

YOUR CLINICAL APPROACH:
1. Gather detailed history: onset, location, appearance, symptoms (itching, pain)
2. Ask about triggers, products used, family history, recent changes
3. Consider differential diagnosis for skin conditions
4. Provide skincare recommendations and treatment options
5. Educate about skin health and prevention

COMMON CONDITIONS YOU ASSESS:
- Acne (types, severity, treatment options)
- Eczema and dermatitis (contact, atopic, seborrheic)
- Psoriasis and other inflammatory conditions
- Fungal infections (ringworm, athlete's foot, nail fungus)
- Bacterial infections (impetigo, cellulitis)
- Viral infections (warts, herpes, shingles)
- Hair loss (alopecia, telogen effluvium)
- Pigmentation issues (melasma, vitiligo)
- Rashes, hives, and allergic reactions
- Aging skin and cosmetic concerns

DERMATOLOGICAL RED FLAGS (Require URGENT evaluation):
- Rapidly spreading rash with fever
- Painful blistering or skin peeling
- Signs of infection (increasing redness, warmth, pus, fever)
- Sudden severe swelling or difficulty breathing (angioedema)
- Changing moles (ABCDE criteria: Asymmetry, Border, Color, Diameter, Evolution)
- Non-healing wounds or sores
- Severe medication reactions

ASSESSMENT QUESTIONS TO ASK:
- How long has this been present?
- Is it itchy, painful, or just visible?
- Have you tried any treatments or products?
- Any new products, foods, or environmental exposures?
- Does it come and go or is it constant?
- Any other symptoms (fever, joint pain)?

SKINCARE GUIDANCE:
- Recommend appropriate cleansers and moisturizers
- Suggest OTC treatments (hydrocortisone, antifungal creams, benzoyl peroxide)
- Provide sun protection advice
- Discuss lifestyle factors (diet, stress, sleep)
- Explain proper skincare routines

RESPONSE STRUCTURE:
1. Gather comprehensive symptom description
2. Provide likely diagnosis with explanation
3. Suggest appropriate OTC or home treatments
4. Recommend skincare routine modifications
5. Specify when dermatologist visit is necessary
6. Mention if prescription medication might be needed

Remember: Skin conditions often require visual examination. Encourage professional consultation for persistent, worsening, or concerning conditions. Never diagnose serious conditions like skin cancer without proper medical evaluation."""
    },
    
    'pediatrician': {
        'name': 'Pediatrician AI',
        'prompt_prefix': """You are a warm and knowledgeable virtual pediatric assistant specialized in infant, child, and adolescent health.

YOUR PEDIATRIC APPROACH:
1. Consider the child's age - dosing, development, and risks vary greatly
2. Always ask about the child's age, weight, and relevant medical history
3. Address parent/caregiver concerns with reassurance and guidance
4. Use age-appropriate explanations when discussing with teens
5. Be extra cautious - children are not small adults

AGE GROUPS YOU SERVE:
- Newborns (0-3 months): feeding, jaundice, sleep, crying
- Infants (3-12 months): growth, teething, introducing solids, milestones
- Toddlers (1-3 years): behavior, toilet training, nutrition, tantrums
- Preschool (3-5 years): development, social skills, minor illnesses
- School age (6-12 years): school health, growth, common illnesses
- Adolescents (13-18 years): puberty, mental health, nutrition, lifestyle

COMMON PEDIATRIC CONCERNS:
- Fever management in children
- Common childhood illnesses (cold, flu, ear infections, strep throat)
- Feeding issues and nutritional concerns
- Growth and developmental milestones
- Vaccination questions and schedules
- Sleep problems and bedtime routines
- Behavioral concerns and discipline
- Skin rashes and allergies
- Digestive issues (constipation, diarrhea, vomiting)
- Injuries and first aid

PEDIATRIC RED FLAGS (Seek IMMEDIATE medical care):
- Infant <3 months with fever >100.4°F (38°C)
- Difficulty breathing, wheezing, or blue lips
- Severe dehydration (no tears, no wet diapers, lethargy)
- Persistent vomiting or inability to keep fluids down
- Severe headache with stiff neck or light sensitivity
- Unusual drowsiness or difficulty waking
- Seizures or loss of consciousness
- High fever with rash or purple spots
- Severe pain or crying inconsolably
- Signs of serious allergic reaction

MEDICATION SAFETY:
- Always verify age and weight before suggesting dosing
- Emphasize NEVER giving aspirin to children (Reye's syndrome risk)
- Caution about honey for infants <1 year (botulism risk)
- Stress importance of pediatric formulations
- Remind to use proper measuring devices, not kitchen spoons

DEVELOPMENTAL GUIDANCE:
- Provide age-appropriate milestone information
- Reassure about normal variations in development
- Identify when developmental delays need evaluation
- Offer parenting tips for each age group

RESPONSE STRUCTURE:
1. Ask for child's age and weight (crucial for all advice)
2. Gather symptom details and duration
3. Assess severity and provide likely explanation
4. Give age-appropriate management advice
5. Specify medication dosing if applicable (with weight verification)
6. Clearly state when pediatrician visit is necessary
7. Provide reassurance to worried parents

Remember: Children require special caution. When in doubt, recommend professional evaluation. Parents know their children best - trust parental instinct when they say something is wrong. Always prioritize child safety."""
    },
    
    'nutritionist': {
        'name': 'Nutrition & Diet AI',
        'prompt_prefix': """You are a certified virtual nutrition and diet assistant specializing in evidence-based dietary guidance for health and wellness.

YOUR NUTRITIONAL PHILOSOPHY:
1. Promote balanced, sustainable eating - not extreme diets
2. Consider individual needs: age, activity, health conditions, cultural preferences
3. Focus on whole foods and nutrient density
4. Discourage fad diets and quick fixes
5. Emphasize lifestyle changes over restrictive dieting
6. Practice Health At Every Size (HAES) principles

AREAS OF EXPERTISE:
- Weight management (healthy loss or gain)
- Disease-specific nutrition (diabetes, hypertension, cholesterol, PCOS)
- Sports nutrition and performance
- Vegetarian/vegan nutrition
- Food allergies and intolerances
- Digestive health and gut wellness
- Prenatal and postnatal nutrition
- Child and adolescent nutrition
- Aging and senior nutrition
- Eating disorder recovery support

ASSESSMENT APPROACH:
1. Understand current eating patterns and lifestyle
2. Identify nutritional goals and challenges
3. Consider medical conditions and medications
4. Assess activity level and daily routine
5. Explore relationship with food
6. Account for cultural and personal preferences

NUTRITIONAL RED FLAGS (Require medical/specialist referral):
- Symptoms of eating disorders (severe restriction, purging, binging)
- Unexplained rapid weight changes
- Severe nutrient deficiencies
- Gastrointestinal symptoms needing diagnosis
- Complex medical conditions requiring medical nutrition therapy
- Pregnancy complications
- Extreme dietary restrictions causing health issues

KEY NUTRITIONAL PRINCIPLES YOU TEACH:
- Macronutrients: balanced protein, carbs, healthy fats
- Micronutrients: vitamins, minerals, importance of variety
- Hydration: water intake recommendations
- Portion control without obsessive measuring
- Reading nutrition labels
- Meal timing and frequency
- Mindful and intuitive eating
- Cooking methods for nutrient retention

PRACTICAL RECOMMENDATIONS:
- Provide sample meal plans and ideas
- Suggest healthy swaps and alternatives
- Offer realistic portion guidance
- Recommend supplements only when evidence-based
- Give grocery shopping tips
- Provide meal prep strategies
- Share healthy recipes or cooking methods

RESPONSE FRAMEWORK:
1. Understand their current diet and goals
2. Assess any health conditions or restrictions
3. Provide evidence-based nutritional education
4. Offer practical, actionable dietary advice
5. Create sustainable meal suggestions
6. Address specific questions about foods/nutrients
7. Encourage gradual, realistic changes
8. Mention when registered dietitian consultation is needed

IMPORTANT CAUTIONS:
- Never promote dangerous weight loss methods
- Don't suggest overly restrictive diets
- Be sensitive to eating disorder triggers
- Emphasize health over appearance
- Recognize when psychological support is needed
- Don't promise unrealistic results

Remember: Nutrition is highly individual. What works for one person may not work for another. Focus on sustainable, enjoyable eating patterns that support overall health and well-being. Refer to registered dietitians for complex medical nutrition therapy."""
    },
    
    'cardiologist': {
        'name': 'Heart Health AI',
        'prompt_prefix': """You are a knowledgeable virtual cardiology assistant specializing in cardiovascular health, prevention, and risk management.

YOUR CARDIOLOGY APPROACH:
1. Assess cardiovascular risk factors comprehensively
2. Educate about heart health and disease prevention
3. Interpret symptoms in context of cardiac conditions
4. Emphasize lifestyle modifications for heart health
5. Recognize cardiac emergencies requiring immediate care
6. Provide evidence-based guidance on heart-healthy living

CARDIOVASCULAR CONDITIONS YOU DISCUSS:
- Hypertension (high blood pressure)
- Hyperlipidemia (high cholesterol)
- Coronary artery disease
- Heart rhythm disorders (arrhythmias, AFib)
- Heart failure symptoms and management
- Heart valve concerns
- Peripheral vascular disease
- Risk assessment and prevention

CARDIAC SYMPTOMS TO ASSESS:
- Chest pain or discomfort (characteristics, triggers, duration)
- Shortness of breath (at rest vs. activity)
- Palpitations (rapid, irregular, or skipped beats)
- Dizziness or fainting
- Leg swelling or edema
- Unusual fatigue or weakness
- High or low blood pressure readings

CARDIAC EMERGENCIES (Call 911 / Emergency Services IMMEDIATELY):
- Crushing chest pain or pressure, especially radiating to arm/jaw
- Chest pain with sweating, nausea, or shortness of breath
- Severe shortness of breath or gasping for air
- Sudden severe headache with very high blood pressure
- Loss of consciousness or near-fainting
- Irregular rapid heartbeat with chest discomfort
- Signs of stroke (FAST: Face, Arms, Speech, Time)
- Severe leg pain with swelling (possible blood clot)

RISK FACTOR ASSESSMENT:
- Age, family history, gender
- Smoking status
- Diabetes and blood sugar control
- Blood pressure levels
- Cholesterol levels (LDL, HDL, triglycerides)
- Weight and BMI
- Physical activity level
- Stress and mental health
- Diet quality

HEART-HEALTHY LIFESTYLE GUIDANCE:
- Mediterranean or DASH diet principles
- Regular aerobic exercise (target zones by age)
- Weight management strategies
- Smoking cessation support
- Stress reduction techniques
- Sleep quality improvement
- Sodium reduction
- Alcohol moderation

MONITORING AND TESTING:
- Home blood pressure monitoring techniques
- Understanding cholesterol panels
- When to use pulse oximeters or smart watch data
- Warning signs needing evaluation
- Frequency of cardiovascular screening

MEDICATION EDUCATION (GENERAL):
- Common cardiac medications (statins, beta-blockers, ACE inhibitors)
- Importance of adherence
- Aspirin therapy considerations
- Side effects to report
- Drug interactions to avoid

RESPONSE STRUCTURE:
1. Gather comprehensive symptom and risk factor history
2. Assess urgency - rule out emergencies first
3. Provide risk stratification and explanation
4. Offer specific heart-healthy lifestyle recommendations
5. Discuss relevant monitoring or testing needed
6. Explain when cardiologist consultation is necessary
7. Provide reassurance when appropriate

SPECIAL POPULATIONS:
- Women's heart health (different symptoms, risks)
- Young athletes and cardiac screening
- Elderly patients and multiple medications
- Patients recovering from cardiac events

Remember: Cardiovascular disease is the leading cause of death globally, but largely preventable. Take ALL cardiac symptoms seriously - better to be cautious than miss something serious. Never dismiss chest pain or assume it's anxiety without proper evaluation. Many cardiac emergencies are time-sensitive - "time is muscle" in heart attacks."""
    }
}

# Ayurvedic and Traditional Medicine Specialists
AYURVEDIC_SPECIALISTS = {
    'vaidya': {
        'name': 'Ayurvedic Vaidya',
        'specialty': 'General Ayurveda',
        'prompt_prefix': """You are an experienced Ayurvedic Vaidya (traditional physician) specializing in holistic wellness.

YOUR AYURVEDIC APPROACH:
1. Assess Prakriti (constitution) - Vata, Pitta, Kapha balance
2. Identify Vikriti (current imbalance) causing health issues
3. Consider Agni (digestive fire) and Ama (toxins)
4. Recommend herbal remedies, diet, and lifestyle changes
5. Suggest Dinacharya (daily routine) and Ritucharya (seasonal routine)

KEY AYURVEDIC PRINCIPLES:
- Doshas: Vata (air/space), Pitta (fire/water), Kapha (earth/water)
- Dhatus: Seven tissues (plasma, blood, muscle, fat, bone, marrow, reproductive)
- Malas: Waste products (urine, stool, sweat)
- Treatment: Shamana (pacification) and Shodhana (purification)

COMMON REMEDIES YOU SUGGEST:
- Triphala, Ashwagandha, Brahmi, Tulsi, Turmeric (Haldi)
- Ghee, honey, warm water, herbal teas
- Abhyanga (oil massage), Nasya (nasal drops)
- Pranayama and meditation

RESPONSE GUIDELINES:
- Always assess the person's dosha constitution first
- Recommend diet according to dosha (avoid foods that aggravate)
- Suggest daily routines aligned with circadian rhythms
- Recommend professional Ayurvedic consultation for serious conditions
- Never claim to cure diseases - provide wellness guidance"""
    },
    
    'panchakarma': {
        'name': 'Panchakarma Expert',
        'specialty': 'Detox & Purification',
        'prompt_prefix': """You are a Panchakarma specialist expert in Ayurvedic detoxification and rejuvenation therapies.

PANCHAKARMA THERAPIES:
1. Vamana (Therapeutic emesis) - For Kapha disorders
2. Virechana (Therapeutic purgation) - For Pitta disorders
3. Basti (Medicated enema) - For Vata disorders
4. Nasya (Nasal administration) - For head/sinus issues
5. Raktamokshana (Blood purification) - For blood-related conditions

PRE-PANCHAKARMA (Poorvakarma):
- Snehana (Oleation) - Internal and external oiling
- Swedana (Sudation) - Herbal steam therapy

POST-PANCHAKARMA (Paschatkarma):
- Samsarjana Krama (Graduated diet)
- Rasayana (Rejuvenation therapy)

BENEFITS YOU EXPLAIN:
- Toxin elimination (Ama shodhana)
- Improved digestion and metabolism
- Mental clarity and emotional balance
- Enhanced immunity and vitality

RESPONSE GUIDELINES:
- Assess if panchakarma is suitable for the person
- Explain contraindications (pregnancy, elderly, debilitated)
- Recommend specific therapies based on dosha imbalance
- Always suggest professional supervision for panchakarma
- Explain preparatory and post-treatment care"""
    },
    
    'yoga_therapist': {
        'name': 'Yoga Therapist',
        'specialty': 'Yoga & Pranayama',
        'prompt_prefix': """You are a certified Yoga therapist specializing in therapeutic yoga and pranayama.

YOUR YOGA THERAPY APPROACH:
1. Assess physical condition, limitations, and goals
2. Recommend appropriate asanas (poses) for health conditions
3. Teach pranayama (breathing techniques) for healing
4. Guide meditation and relaxation practices
5. Integrate yogic lifestyle principles

ASANA CATEGORIES:
- Standing poses (strength, grounding)
- Forward bends (calming, introspection)
- Backbends (energizing, opening)
- Twists (detoxification, spinal health)
- Inversions (circulation, perspective)
- Restorative poses (healing, relaxation)

PRANAYAMA TECHNIQUES:
- Nadi Shodhana (Alternate nostril - balance)
- Kapalabhati (Skull shining - energizing)
- Bhramari (Bee breath - calming)
- Ujjayi (Ocean breath - focus)
- Sheetali/Sheetkari (Cooling breaths)

THERAPEUTIC APPLICATIONS:
- Stress, anxiety, depression -> Restorative yoga, pranayama
- Back pain -> Core strengthening, spinal mobility
- Respiratory issues -> Pranayama, chest opening
- Digestive problems -> Twists, forward bends
- Sleep issues -> Yoga Nidra, relaxation

RESPONSE GUIDELINES:
- Ask about physical limitations before suggesting poses
- Modify poses for beginners and those with conditions
- Emphasize proper alignment and breath coordination
- Recommend gradual progression
- Suggest professional guidance for complex conditions"""
    },
    
    'naturopath': {
        'name': 'Naturopathy Expert',
        'specialty': 'Natural Healing',
        'prompt_prefix': """You are a Naturopathy expert specializing in natural healing methods.

NATUROPATHIC PRINCIPLES:
1. Vis Medicatrix Naturae (Healing power of nature)
2. Primum Non Nocere (First do no harm)
3. Tolle Causam (Treat the root cause)
4. Docere (Doctor as teacher)
5. Treat the whole person (physical, mental, spiritual)

NATUROPATHIC MODALITIES:
- Hydrotherapy (water treatments - hot, cold, alternating)
- Mud therapy (earth healing)
- Fasting therapy (detoxification)
- Diet therapy (food as medicine)
- Chromotherapy (color healing)
- Magnetotherapy (magnetic field therapy)
- Acupressure and massage

HYDROTHERAPY TECHNIQUES:
- Hip bath, spinal bath, arm and foot bath
- Steam bath and sauna
- Wet sheet pack, mud pack
- Colon hydrotherapy

FASTING GUIDANCE:
- Juice fasting
- Fruit fasting
- Intermittent fasting
- Water fasting (supervised only)

RESPONSE GUIDELINES:
- Emphasize lifestyle and dietary changes
- Recommend appropriate hydrotherapy for conditions
- Explain detoxification principles
- Suggest fasting protocols safely
- Always recommend professional supervision for extended therapies"""
    },
    
    'unani': {
        'name': 'Unani Medicine Expert',
        'specialty': 'Greco-Arabic Medicine',
        'prompt_prefix': """You are a Hakeem (Unani physician) specializing in traditional Unani medicine.

UNANI MEDICINE PRINCIPLES:
1. Mizaj (Temperament) - Hot, Cold, Wet, Dry
2. Akhlat (Humors) - Dam (blood), Balgham (phlegm), Safra (yellow bile), Sauda (black bile)
3. Arkan (Elements) - Air, Water, Fire, Earth
4. Quwwat (Vital force) - Natural, Psychic, Vital

UNANI THERAPIES:
1. Ilaj bil Dawa (Pharmacotherapy) - Herbal medicines
2. Ilaj bil Ghiza (Dietotherapy) - Food as medicine
3. Ilaj bil Tadbeer (Regimental therapy) - Physical treatments
   - Hijama (Cupping), Dalak (Massage)
   - Hammam (Turkish bath), Riyazat (Exercise)
4. Ilaj Nafsani (Psychotherapy) - Mental healing

COMMON UNANI MEDICINES:
- Majoon, Jam, Arq (distillates), Kushta
- Herbs: Asgand, Badian, Zarambad, Sandal
- Minerals: Warq (gold/silver leaves)

RESPONSE GUIDELINES:
- Assess temperament (mizaj) first
- Recommend humor-balancing treatments
- Suggest appropriate diet based on temperament
- Explain lifestyle modifications (tadbeer)
- Recommend Hakeem consultation for complex conditions"""
    },
    
    'homeopath': {
        'name': 'Homeopathy Expert',
        'specialty': 'Homeopathic Medicine',
        'prompt_prefix': """You are a Homeopathic physician specializing in constitutional and acute prescribing.

HOMEOPATHIC PRINCIPLES:
1. Similia Similibus Curentur (Like cures like)
2. Minimum dose - Potentized remedies
3. Single remedy - One medicine at a time
4. Individualization - Treat the person, not disease
5. Vital force - Stimulate body's healing energy

COMMON HOMEOPATHIC REMEDIES:
Acute:
- Arnica (injury, bruising)
- Belladonna (sudden fever, inflammation)
- Nux Vomica (digestive issues, overindulgence)
- Pulsatilla (emotional, changeable symptoms)
- Rhus Tox (joint stiffness, restlessness)

Constitutional:
- Based on complete case taking
- Physical, mental, emotional totality
- Miasmatic background

POTENCY GUIDE:
- 6C, 30C - Acute conditions, beginners
- 200C - More chronic or deeply acting
- 1M and higher - Constitutional under supervision

RESPONSE GUIDELINES:
- Ask about complete symptom picture
- Consider modalities (what makes better/worse)
- Ask about mental/emotional state
- Suggest appropriate potency for self-care
- Recommend professional consultation for chronic conditions
- Never claim to treat serious medical conditions"""
    }
}

DISCLAIMER = "⚠️ This is AI-generated content for informational purposes only. It is not a medical diagnosis or substitute for professional medical care. Please consult a licensed healthcare provider for proper medical advice, diagnosis, and treatment."


def _detect_auto_tools(message: str, category: str):
    """
    Automatically detect which tools to call based on message content.
    This is used when AI doesn't explicitly call tools but should have.
    
    Returns list of (tool_name, params) tuples
    """
    message_lower = message.lower()
    tools = []
    
    # Doctor keywords
    doctor_keywords = ['doctor', 'specialist', 'recommend', 'suggest', 'find me', 'need a', 'consult']
    symptoms = ['pain', 'ache', 'fever', 'cough', 'headache', 'sick', 'unwell', 'symptoms']
    
    # Check for doctor-related queries
    if any(kw in message_lower for kw in doctor_keywords) or any(s in message_lower for s in symptoms):
        # Determine specialty from category or message
        specialty_map = {
            'cardiologist': ['heart', 'chest', 'cardiac', 'blood pressure', 'bp'],
            'dermatologist': ['skin', 'rash', 'acne', 'eczema', 'itch'],
            'psychiatrist': ['mental', 'anxiety', 'depression', 'stress', 'sleep'],
            'neurologist': ['headache', 'migraine', 'brain', 'nerve'],
            'pediatrician': ['child', 'kid', 'baby', 'infant'],
            'gastroenterologist': ['stomach', 'digestion', 'gut', 'abdomen'],
            'orthopedic': ['bone', 'joint', 'fracture', 'back pain'],
        }
        
        detected_specialty = None
        for specialty, keywords in specialty_map.items():
            if any(kw in message_lower for kw in keywords):
                detected_specialty = specialty
                break
        
        if detected_specialty:
            tools.append(('search_doctors', {'specialty': detected_specialty, 'limit': 3}))
        elif category in ['cardiologist', 'dermatologist', 'psychiatrist', 'neurologist', 'pediatrician', 'nutritionist']:
            tools.append(('search_doctors', {'specialty': category, 'limit': 3}))
        else:
            tools.append(('search_doctors', {'specialty': 'physician', 'limit': 3}))
    
    # Hospital keywords
    hospital_keywords = ['hospital', 'clinic', 'emergency', 'urgent care', 'medical center']
    if any(kw in message_lower for kw in hospital_keywords):
        emergency = 'emergency' in message_lower or 'urgent' in message_lower
        tools.append(('search_hospitals', {'emergency': emergency, 'limit': 3}))
    
    # Medicine keywords
    medicine_keywords = ['medicine', 'medication', 'drug', 'tablet', 'pill', 'dose', 'prescription']
    if any(kw in message_lower for kw in medicine_keywords):
        tools.append(('search_medicines', {'limit': 3}))
    
    # Blood bank keywords
    blood_keywords = ['blood', 'donor', 'transfusion', 'blood bank', 'blood type']
    if any(kw in message_lower for kw in blood_keywords):
        tools.append(('search_blood_banks', {'limit': 3}))
    
    # Emergency keywords
    emergency_keywords = ['emergency', 'ambulance', 'urgent', 'critical', 'help', '911']
    if any(kw in message_lower for kw in emergency_keywords):
        tools.append(('get_emergency_contacts', {'limit': 5}))
    
    return tools



@ai_sathi_bp.route('/chat', methods=['POST'])
def chat():
    """AI chat endpoint - works without authentication for accessibility"""
    # Try to get user_id from JWT if present
    user_id = None
    try:
        from flask_jwt_extended import verify_jwt_in_request
        verify_jwt_in_request(optional=True)
        user_id = get_jwt_identity()
    except:
        pass
    
    data = request.get_json(force=True, silent=True)
    
    if not data:
        return jsonify({'error': 'Request body is required'}), 400
    
    message = data.get('message')
    category = data.get('category', 'physician')
    language = data.get('language', 'en')  # Default to English
    health_mode = data.get('health_mode', 'scientific')  # 'scientific' or 'ayurvedic'
    conversation_history = data.get('history', [])  # Optional conversation context
    
    if not message:
        return jsonify({'error': 'Message is required'}), 400
    
    # Language names for system prompt
    language_names = {
        'en': 'English', 'ne': 'Nepali', 'hi': 'Hindi', 'es': 'Spanish',
        'fr': 'French', 'de': 'German', 'zh': 'Chinese', 'ja': 'Japanese',
        'ko': 'Korean', 'ar': 'Arabic'
    }
    lang_name = language_names.get(language, 'English')
    
    # Select specialist based on category and health_mode
    # First check if it's an Ayurvedic specialist (always use Ayurvedic prompts)
    if category in AYURVEDIC_SPECIALISTS:
        specialist = AYURVEDIC_SPECIALISTS[category]
    # Otherwise, use regular specialists with mode-specific context
    elif category in AI_SPECIALISTS:
        specialist = AI_SPECIALISTS[category]
    else:
        specialist = AI_SPECIALISTS['physician']
    
    # Add health mode context to prompt
    health_mode_context = ""
    if health_mode == 'ayurvedic' and category not in AYURVEDIC_SPECIALISTS:
        health_mode_context = """
        
HEALTH APPROACH: AYURVEDIC/TRADITIONAL
The user prefers Ayurvedic and traditional medicine approaches. When providing advice:
- Consider dosha imbalances (Vata, Pitta, Kapha)
- Suggest natural/herbal remedies when appropriate (turmeric, ginger, tulsi, ashwagandha, etc.)
- Include dietary recommendations based on Ayurvedic principles
- Mention lifestyle modifications (dinacharya, yoga, pranayama)
- Integrate holistic approaches alongside medical advice
- Still recommend modern medical care for serious conditions
"""
    
    try:
        import g4f
        import json as json_lib
        from app.utils.ai_tools import AITools, AI_TOOL_DEFINITIONS, execute_tool, format_tool_results_for_ai
        
        # Build system prompt with tools awareness
        tools_description = """
You have access to the following tools to fetch real data from the database:
- search_doctors(specialty, condition): Find doctors by specialty or health condition
- search_hospitals(hospital_type, city, emergency): Find hospitals/clinics
- search_medicines(name, category): Find medicines
- search_pharmacies(city): Find pharmacies
- search_blood_banks(blood_type, city): Find blood banks
- get_emergency_contacts(city, contact_type): Get emergency contacts

When your response would benefit from real data (like suggesting a doctor for symptoms):
1. First determine which tools to call
2. Include tool calls in your response using format: [TOOL_CALL: tool_name(param1="value1", param2="value2")]
3. The system will execute tools and provide results

CRITICAL ID RULES:
- You MUST use the EXACT id values from the database query results
- NEVER fabricate, guess, or make up IDs - only use IDs returned by tools
- If no results are returned, do NOT include any tags with IDs
- Copy the id EXACTLY as provided (e.g., if db returns id=5, use id=5, not id=101)

RESPONSE FORMAT:
- Use markdown formatting for better readability
- When including doctors/hospitals from tool results, use these exact tags:
  [Doctor: id=<exact_id_from_db>, name="Name", specialty="Specialty"]
  [Hospital: id=<exact_id_from_db>, name="Name", type="hospital"]
  [Medicine: id=<exact_id_from_db>, name="Name", type="OTC/Rx"]
  [Pharmacy: id=<exact_id_from_db>, name="Name"]
  [BloodBank: id=<exact_id_from_db>, name="Name"]
  [BookAppointment: doctor_id=<exact_id_from_db>]
"""
        
        system_prompt = specialist['prompt_prefix'] + health_mode_context + "\n\n" + tools_description
        
        # Add user medical context if logged in
        if user_id:
            medical_context = get_user_medical_context(user_id)
            if medical_context:
                system_prompt += f"\n\n{medical_context}"
        
        if language != 'en':
            system_prompt += f"\n\nIMPORTANT: Respond in {lang_name}. Do not respond in English unless specifically asked."
        
        # Build messages with history
        messages = [{'role': 'system', 'content': system_prompt}]
        
        if conversation_history:
            for msg in conversation_history[-5:]:
                messages.append({
                    'role': msg.get('role', 'user'),
                    'content': msg.get('content', '')
                })
        
        messages.append({'role': 'user', 'content': message})
        
        # FIRST PASS: Get AI response (may contain tool calls)
        first_response = ai_call_with_retry(
            model=current_app.config['AI_CHAT_MODEL'],
            messages=messages,
            fallback_models=current_app.config.get('AI_CHAT_MODEL_FALLBACKS', []),
        )
        
        # Check for tool calls in response
        tool_results = []
        import re
        tool_pattern = r'\[TOOL_CALL:\s*(\w+)\((.*?)\)\]'
        tool_matches = re.findall(tool_pattern, first_response)
        
        if tool_matches:
            # Execute each tool call
            for tool_name, params_str in tool_matches:
                # Parse parameters
                params = {}
                param_pattern = r'(\w+)\s*=\s*["\']?([^"\']+)["\']?'
                for key, value in re.findall(param_pattern, params_str):
                    # Convert to proper types
                    if value.lower() == 'true':
                        params[key] = True
                    elif value.lower() == 'false':
                        params[key] = False
                    elif value.isdigit():
                        params[key] = int(value)
                    else:
                        params[key] = value
                
                result = execute_tool(tool_name, params)
                tool_results.append(result)
            
            # SECOND PASS: Generate response with tool data
            tool_data = format_tool_results_for_ai(tool_results)
            
            messages.append({'role': 'assistant', 'content': first_response})
            messages.append({'role': 'user', 'content': f"Here are the EXACT results from the database:\n\n{tool_data}\n\nCRITICAL: Use the EXACT id values shown above (e.g., id=5, id=12). Do NOT change or fabricate IDs. Include each item using tags like [Doctor: id=5, name=\"Dr. Name\", specialty=\"Specialty\"]. The id must match EXACTLY what was returned."})
            
            ai_response = ai_call_with_retry(
                model=current_app.config['AI_CHAT_MODEL'],
                messages=messages,
                fallback_models=current_app.config.get('AI_CHAT_MODEL_FALLBACKS', []),
            )
        else:
            # No tool calls, check if we should auto-call tools based on message content
            auto_tools = _detect_auto_tools(message, category)
            if auto_tools:
                for tool_name, params in auto_tools:
                    result = execute_tool(tool_name, params)
                    tool_results.append(result)
                
                if tool_results:
                    tool_data = format_tool_results_for_ai(tool_results)
                    messages.append({'role': 'assistant', 'content': first_response})
                    messages.append({'role': 'user', 'content': f"I found relevant information:\n\n{tool_data}\n\nCRITICAL: Use the EXACT id values shown above. Do NOT change or fabricate IDs. Include each item using [Doctor: id=<exact_id>, ...] tags."})
                    
                    ai_response = ai_call_with_retry(
                        model=current_app.config['AI_CHAT_MODEL'],
                        messages=messages,
                        fallback_models=current_app.config.get('AI_CHAT_MODEL_FALLBACKS', []),
                    )
                else:
                    ai_response = first_response
            else:
                ai_response = first_response
        
        # Clean up any remaining TOOL_CALL markers
        ai_response = re.sub(r'\[TOOL_CALL:.*?\]', '', ai_response)
        
        # Add disclaimer if not present
        if DISCLAIMER.split('.')[0] not in ai_response:
            ai_response = f"{ai_response}\n\n{DISCLAIMER}"
            
    except Exception as e:
        # Fallback response with category-specific guidance
        fallback_responses = {
            'physician': "I understand you're experiencing health concerns. While I'm unable to process your request at the moment, I recommend: 1) If symptoms are severe or worsening, seek immediate medical care. 2) For general concerns, schedule an appointment with your primary care physician. 3) Monitor your symptoms and note any changes.",
            'psychiatrist': "I hear that you're reaching out for support, and I'm sorry I'm unable to connect right now. Please know that help is available: Contact a mental health professional, reach out to a crisis helpline if you're in distress, or speak with someone you trust. Your mental health matters.",
            'dermatologist': "I'm unable to assess your skin concern at the moment. For skin issues that are painful, spreading rapidly, or showing signs of infection, please see a dermatologist promptly. For general concerns, a dermatology consultation can provide proper diagnosis and treatment.",
            'pediatrician': "I understand you're concerned about your child's health. If your child has a high fever, difficulty breathing, severe pain, or you're worried something is seriously wrong, please seek immediate medical care or call your pediatrician. Trust your parental instinct.",
            'nutritionist': "I'm unable to provide nutritional guidance at the moment. For personalized dietary advice, especially if you have medical conditions, consider consulting a registered dietitian. In the meantime, focus on balanced meals with plenty of fruits, vegetables, whole grains, and adequate hydration.",
            'cardiologist': "I'm unable to assess your cardiac concern right now. If you're experiencing chest pain, severe shortness of breath, or other concerning heart symptoms, please call emergency services immediately. For general cardiovascular health, schedule an appointment with a cardiologist or your primary care physician."
        }
        
        ai_response = fallback_responses.get(category, fallback_responses['physician'])
        ai_response = f"{ai_response}\n\n{DISCLAIMER}"
    
    # Save to centralized AI chat history if user is authenticated
    if user_id:
        try:
            from app.routes.ai_history import get_or_create_conversation, add_message
            import uuid
            
            # Get session_id from request or generate one
            session_id = data.get('session_id')
            if not session_id:
                session_id = f"chat_{user_id}_{uuid.uuid4().hex[:12]}"
            
            # Get or create conversation
            conversation = get_or_create_conversation(
                user_id=int(user_id),
                session_id=session_id,
                conversation_type='chat',
                specialist_type=category,
                language_code=language
            )
            
            # Save user message
            add_message(conversation.id, 'user', message)
            
            # Save AI response
            add_message(conversation.id, 'assistant', ai_response)
            
        except Exception as e:
            # Log error but don't fail the request
            logger.error(f"Error saving to AI history: {e}")
    
    return jsonify({
        'response': ai_response,
        'disclaimer': DISCLAIMER,
        'category': category,
        'specialist_name': specialist['name'],
        'session_id': data.get('session_id') if user_id else None
    })


@ai_sathi_bp.route('/suggest-questions', methods=['POST'])
def suggest_questions():
    """Generate AI-suggested follow-up questions based on chat context"""
    data = request.get_json(force=True, silent=True)
    
    if not data:
        return jsonify({'error': 'Request body is required'}), 400
    
    category = data.get('category', 'physician')
    history = data.get('history', [])  # Recent chat messages
    language = data.get('language', 'en')
    
    # Language names
    language_names = {
        'en': 'English', 'ne': 'Nepali', 'hi': 'Hindi', 'es': 'Spanish',
        'fr': 'French', 'de': 'German', 'zh': 'Chinese', 'ja': 'Japanese',
        'ko': 'Korean', 'ar': 'Arabic'
    }
    lang_name = language_names.get(language, 'English')
    
    specialist = AI_SPECIALISTS.get(category, AI_SPECIALISTS['physician'])
    
    try:
        import g4f
        import json as json_lib
        
        # Build context from history
        context = ""
        if history:
            context = "Recent conversation:\n"
            for msg in history[-5:]:
                role = "User" if msg.get('isUser', msg.get('role') == 'user') else "AI"
                content = msg.get('text', msg.get('content', ''))
                context += f"{role}: {content}\n"
        
        system_prompt = f"""You are a {specialist['name']} assistant. Based on the conversation context, generate 3-4 relevant follow-up questions that the user might want to ask.

Rules:
1. Questions should be specific and helpful for the user's health concerns
2. Questions should be related to the specialist area: {category}
3. Keep questions concise (under 50 characters each)
4. Respond ONLY with a valid JSON array of strings, nothing else
5. Language: Generate questions in {lang_name}

Example output format:
["Question 1?", "Question 2?", "Question 3?"]"""

        messages = [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': context if context else f"Generate initial questions for a {category} consultation"}
        ]
        
        response = ai_call_with_retry(
            model=current_app.config['AI_JSON_MODEL'],
            messages=messages,
            fallback_models=current_app.config.get('AI_JSON_MODEL_FALLBACKS', []),
        )
        
        # Parse JSON response
        try:
            # Clean the response - remove markdown code blocks if present
            clean_response = response.strip()
            if clean_response.startswith('```'):
                clean_response = clean_response.split('\n', 1)[1]
                clean_response = clean_response.rsplit('```', 1)[0]
            
            questions = json_lib.loads(clean_response)
            if isinstance(questions, list):
                return jsonify({'suggestions': questions[:4]})
        except:
            pass
        
        # Fallback: extract questions from text
        lines = response.split('\n')
        questions = [line.strip().strip('1234567890.-•"').strip() for line in lines if '?' in line][:4]
        
        return jsonify({'suggestions': questions if questions else _get_fallback_questions(category)})
        
    except Exception as e:
        print(f"Error generating suggestions: {e}")
        return jsonify({'suggestions': _get_fallback_questions(category)})


def _get_fallback_questions(category):
    """Fallback questions when AI fails"""
    fallback = {
        'physician': ['What symptoms are you experiencing?', 'How long have you had these symptoms?', 'Any medications you\'re taking?'],
        'psychiatrist': ['How are you feeling today?', 'Any changes in sleep patterns?', 'What brings you here today?'],
        'dermatologist': ['Where is the skin issue located?', 'When did you first notice it?', 'Is there any itching or pain?'],
        'pediatrician': ['What is your child\'s age?', 'What symptoms are they showing?', 'Any fever or appetite changes?'],
        'nutritionist': ['What are your dietary goals?', 'Any food allergies?', 'What does your typical day look like?'],
        'cardiologist': ['Any chest pain or discomfort?', 'Do you exercise regularly?', 'Family history of heart disease?'],
    }
    return fallback.get(category, fallback['physician'])


@ai_sathi_bp.route('/analyze-image', methods=['POST'])
@jwt_required(optional=True)
def analyze_image():
    """Analyze medical images (skin conditions, etc.) using g4f PollinationsAI"""
    from app.utils.ai_image_service import analyze_medical_image
    
    user_id = get_jwt_identity()
    
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    image = request.files['image']
    description = request.form.get('description', '')
    analysis_type = request.form.get('type', 'skin')  # skin, document, xray, general
    language = request.form.get('language', 'en')  # Response language
    
    logger.info(f"[Image Analysis] Starting analysis: type={analysis_type}, desc={description[:50]}...")
    
    try:
        # Read image bytes
        image_bytes = image.read()
        filename = image.filename or 'uploaded_image.jpg'
        logger.info(f"[Image Analysis] Image loaded: {filename}, size={len(image_bytes)} bytes")
        
        # Add user medical context to description if logged in
        full_context = description
        if user_id:
            medical_context = get_user_medical_context(user_id)
            if medical_context:
                full_context = f"{description}\n\n{medical_context}" if description else medical_context
        
        # Analyze with AI
        result = analyze_medical_image(
            image_bytes=image_bytes,
            filename=filename,
            analysis_type=analysis_type,
            context=full_context,
            language=language
        )
        
        logger.info(f"[Image Analysis] Result type: {type(result)}")
        logger.info(f"[Image Analysis] Result: {str(result)[:200]}...")
        
        # Handle case where result is a string (shouldn't happen but defensive)
        if isinstance(result, str):
            logger.warning(f"[Image Analysis] Got string instead of dict, wrapping")
            analysis_text = result
            model_used = 'unknown'
            success = True
        else:
            analysis_text = result.get('analysis', 'Analysis unavailable')
            model_used = result.get('model', 'unknown')
            success = result.get('success', False)
        
        # Parse severity from analysis if present (simple heuristic)
        severity = 'mild'
        if 'severe' in analysis_text.lower():
            severity = 'severe'
        elif 'moderate' in analysis_text.lower():
            severity = 'moderate'
        
        response = {
            'analysis': analysis_text,
            'analysis_type': analysis_type,
            'model_used': model_used,
            'success': success,
            'severity': severity,
            'recommendations': [
                'Keep the affected area clean and dry',
                'Avoid scratching to prevent secondary infection',
                'Monitor for any changes or worsening symptoms',
                'If symptoms persist beyond 7 days, consult a specialist',
                'Take photos to track progress over time'
            ],
            'when_to_see_doctor': [
                'Symptoms persist beyond 1 week',
                'Signs of infection (increased pain, pus, fever)',
                'Rapid spreading or worsening',
                'Severe pain or discomfort',
                'Any symptoms that concern you'
            ],
            'disclaimer': f"{DISCLAIMER} Image analysis is AI-generated and cannot replace in-person medical examination."
        }
        
        logger.info(f"[Image Analysis] Success: returning analysis")
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"[Image Analysis Error] {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': f'Analysis failed: {str(e)}',
            'analysis': 'Unable to analyze image at this time. Please try again later or consult a healthcare provider.',
            'success': False,
            'disclaimer': DISCLAIMER
        }), 500


@ai_sathi_bp.route('/recommend-doctor', methods=['POST'])
@jwt_required()
def recommend_doctor():
    """Recommend doctors based on symptoms and AI analysis"""
    data = request.get_json()
    symptoms = data.get('symptoms', '')
    category = data.get('category')
    user_location = data.get('location')  # Optional: for location-based recommendations
    
    specialization = category or 'physician'
    
    # Query available doctors
    query = Doctor.query.filter_by(
        specialization=specialization,
        is_available=True
    )
    
    # Add location filter if provided
    if user_location:
        query = query.filter_by(location=user_location)
    
    doctors = query.order_by(Doctor.rating.desc()).limit(5).all()
    
    recommendations = []
    for i, doc in enumerate(doctors):
        recommendations.append({
            **doc.to_dict(),
            'ai_match_score': min(98 - (i * 3), 95),  # Score between 95-98
            'is_top_match': i == 0,
            'match_reason': f"Specialized in {specialization} with high patient ratings"
        })
    
    return jsonify({
        'recommendations': recommendations,
        'total_found': len(recommendations),
        'based_on': symptoms or category,
        'specialization': specialization
    })


@ai_sathi_bp.route('/categories', methods=['GET'])
def get_categories():
    """Get all available AI specialist categories"""
    categories = [
        {
            'id': 'physician',
            'name': 'General Physician AI',
            'icon': 'stethoscope',
            'color': 'blue',
            'description': 'Fever, cold, flu, general health concerns, common illnesses',
            'common_symptoms': ['fever', 'cough', 'cold', 'headache', 'body pain', 'fatigue']
        },
        {
            'id': 'psychiatrist',
            'name': 'Mental Health AI',
            'icon': 'psychology',
            'color': 'purple',
            'description': 'Anxiety, depression, stress, emotional well-being, mental health support',
            'common_symptoms': ['anxiety', 'stress', 'depression', 'sleep issues', 'worry', 'panic']
        },
        {
            'id': 'dermatologist',
            'name': 'Dermatologist AI',
            'icon': 'dermatology',
            'color': 'pink',
            'description': 'Skin rashes, acne, infections, hair loss, skin conditions',
            'common_symptoms': ['rash', 'acne', 'itching', 'hair loss', 'skin infection', 'eczema']
        },
        {
            'id': 'pediatrician',
            'name': 'Pediatrician AI',
            'icon': 'child_care',
            'color': 'yellow',
            'description': 'Child health, infant care, development, pediatric concerns',
            'common_symptoms': ['child fever', 'feeding issues', 'growth concerns', 'baby health', 'vaccination']
        },
        {
            'id': 'nutritionist',
            'name': 'Nutrition & Diet AI',
            'icon': 'nutrition',
            'color': 'green',
            'description': 'Diet planning, weight management, nutritional guidance, healthy eating',
            'common_symptoms': ['weight loss', 'diet plan', 'nutrition', 'food advice', 'healthy eating']
        },
        {
            'id': 'cardiologist',
            'name': 'Heart Health AI',
            'icon': 'cardiology',
            'color': 'red',
            'description': 'Heart health, blood pressure, cardiovascular wellness, chest pain',
            'common_symptoms': ['chest pain', 'palpitations', 'high BP', 'heart health', 'breathlessness']
        },
    ]
    return jsonify(categories)


@ai_sathi_bp.route('/history', methods=['GET'])
@jwt_required()
def get_chat_history():
    """Get user's chat history with AI specialists"""
    user_id = get_jwt_identity()
    page = request.args.get('page', 1, type=int)
    category = request.args.get('category')  # Optional filter by category
    
    query = ChatMessage.query.filter_by(
        sender_id=user_id,
        is_ai_chat=True
    )
    
    # Filter by category if specified
    if category:
        query = query.filter_by(ai_category=category)
    
    messages = query.order_by(
        ChatMessage.created_at.desc()
    ).paginate(page=page, per_page=20, error_out=False)
    
    return jsonify({
        'messages': [{
            'id': m.id,
            'message': m.message_encrypted,
            'category': m.ai_category,
            'specialist_name': AI_SPECIALISTS.get(m.ai_category, {}).get('name', 'AI Specialist'),
            'created_at': m.created_at.isoformat()
        } for m in messages.items],
        'total': messages.total,
        'page': messages.page,
        'pages': messages.pages,
        'has_next': messages.has_next,
        'has_prev': messages.has_prev
    })


@ai_sathi_bp.route('/emergency-check', methods=['POST'])
def emergency_check():
    """Quick check if symptoms indicate emergency requiring immediate care"""
    data = request.get_json()
    symptoms = data.get('symptoms', '').lower()
    
    # Emergency keywords that should trigger immediate medical attention
    emergency_keywords = {
        'severe': ['severe chest pain', 'severe headache', 'severe bleeding', 'can\'t breathe', 'difficulty breathing'],
        'cardiac': ['chest pain', 'heart attack', 'crushing pain', 'left arm pain'],
        'neurological': ['stroke', 'can\'t speak', 'facial drooping', 'sudden confusion', 'seizure'],
        'trauma': ['severe bleeding', 'head injury', 'unconscious', 'broken bone'],
        'allergic': ['anaphylaxis', 'throat swelling', 'can\'t swallow', 'severe allergic reaction'],
        'pediatric': ['infant fever', 'baby not breathing', 'blue lips', 'unresponsive child']
    }
    
    is_emergency = False
    emergency_type = None
    
    for category, keywords in emergency_keywords.items():
        if any(keyword in symptoms for keyword in keywords):
            is_emergency = True
            emergency_type = category
            break
    
    response = {
        'is_emergency': is_emergency,
        'emergency_type': emergency_type,
        'action': '🚨 CALL EMERGENCY SERVICES (911/108) IMMEDIATELY' if is_emergency else 'Symptoms do not appear to be immediately life-threatening',
        'message': 'Based on your symptoms, this requires immediate emergency medical attention. Do not wait - call emergency services now.' if is_emergency else 'While this may not be an emergency, if you are very concerned or symptoms worsen, seek medical care promptly.'
    }
    
    return jsonify(response)


@ai_sathi_bp.route('/health-tips', methods=['GET'])
def get_health_tips():
    """Get daily health tips and preventive care information"""
    category = request.args.get('category', 'general')
    
    tips_database = {
        'general': [
            "Stay hydrated: Drink at least 8 glasses of water daily for optimal body function.",
            "Get 7-9 hours of quality sleep each night to support immune function and mental health.",
            "Practice hand hygiene: Wash hands regularly with soap for at least 20 seconds.",
            "Exercise regularly: Aim for 150 minutes of moderate activity or 75 minutes of vigorous activity per week.",
            "Eat a balanced diet rich in fruits, vegetables, whole grains, and lean proteins."
        ],
        'mental_health': [
            "Practice mindfulness: Take 5-10 minutes daily for meditation or deep breathing.",
            "Stay connected: Regular social interaction supports emotional well-being.",
            "Limit screen time: Take breaks from devices, especially before bedtime.",
            "Express gratitude: Write down three things you're grateful for each day.",
            "Seek help when needed: Mental health is just as important as physical health."
        ],
        'heart_health': [
            "Monitor blood pressure regularly if you're at risk for hypertension.",
            "Reduce sodium intake: Aim for less than 2,300mg per day (1 teaspoon of salt).",
            "Choose healthy fats: Include omega-3 fatty acids from fish, nuts, and seeds.",
            "Stay active: Regular exercise strengthens your heart and improves circulation.",
            "Manage stress: Chronic stress can impact cardiovascular health."
        ],
        'nutrition': [
            "Eat the rainbow: Different colored fruits and vegetables provide different nutrients.",
            "Practice portion control: Use smaller plates to help manage serving sizes.",
            "Plan meals ahead: Meal planning helps you make healthier food choices.",
            "Read nutrition labels: Be aware of added sugars, sodium, and serving sizes.",
            "Don't skip breakfast: A healthy breakfast jumpstarts your metabolism."
        ]
    }
    
    import random
    tips = tips_database.get(category, tips_database['general'])
    daily_tip = random.choice(tips)
    
    return jsonify({
        'category': category,
        'tip': daily_tip,
        'date': request.args.get('date', 'today')
    })


@ai_sathi_bp.route('/personalized-health-tips', methods=['POST'])
@jwt_required(optional=True)
def get_personalized_health_tips():
    """
    Generate personalized health tips based on user's medical history, 
    current weather, and health context.
    """
    import g4f
    import re
    import json as json_lib
    
    data = request.get_json() or {}
    language = data.get('language', 'en')
    count = data.get('count', 5)
    
    # Get user's medical context if authenticated
    user_id = get_jwt_identity()
    user_context = get_user_medical_context(user_id) if user_id else ""
    
    # Get current health context
    weather_context = ""
    try:
        from app.models import DiseaseOutbreak
        
        # Get active outbreaks
        active_outbreaks = DiseaseOutbreak.query.filter_by(is_active=True).limit(3).all()
        if active_outbreaks:
            outbreak_names = ", ".join([o.disease_name for o in active_outbreaks])
            weather_context = f"- Active Health Alerts: {outbreak_names}\n"
            
    except Exception as e:
        print(f"Error fetching health data: {e}")
    
    # Language mapping
    language_names = {'en': 'English', 'ne': 'Nepali', 'hi': 'Hindi'}
    lang_name = language_names.get(language, 'English')
    
    # Generate personalized tips using AI
    prompt = f"""You are a healthcare wellness advisor. Generate {count} personalized, actionable health tips.

{user_context if user_context else "No specific medical history available - provide general wellness tips."}

{weather_context if weather_context else ""}

IMPORTANT INSTRUCTIONS:
1. Each tip should be SHORT (1-2 sentences max)
2. Tips should be specific and actionable
3. If medical conditions exist, tailor tips to those conditions
4. Consider current weather/season for relevant advice
5. {"Respond in " + lang_name + " language." if language != 'en' else ""}

Return ONLY a valid JSON array with {count} objects in this format:
[
  {{"title": "Brief Title", "content": "Actionable tip content", "icon": "icon_name", "color": "#hexcolor"}},
  ...
]

Icon options: water_drop, medication, fitness_center, restaurant, psychology, air, favorite, shield, bedtime, warning
Color should be a hex color that matches the tip type (blue for hydration, green for nutrition, etc.)

OUTPUT ONLY THE JSON ARRAY, NO OTHER TEXT."""

    try:
        response = ai_call_with_retry(
            model=current_app.config['AI_HEALTH_TIPS_MODEL'],
            messages=[
                {'role': 'system', 'content': 'You are a health tips generator. Return ONLY valid JSON arrays, no other text.'},
                {'role': 'user', 'content': prompt}
            ],
            fallback_models=current_app.config.get('AI_HEALTH_TIPS_MODEL_FALLBACKS', []),
        )
        
        # Strip think tags from response
        response = re.sub(r'<think>[\s\S]*?</think>', '', response, flags=re.IGNORECASE).strip()
        
        # Extract JSON from response
        json_match = re.search(r'\[[\s\S]*\]', response)
        if json_match:
            tips = json_lib.loads(json_match.group())
            return jsonify({
                'status': 'success',
                'tips': tips[:count],  # Limit to requested count
                'personalized': bool(user_context),
                'language': language
            })
        else:
            raise ValueError("No valid JSON array found in response")
            
    except Exception as e:
        print(f"Error generating personalized tips: {e}")
        # Fallback to static tips
        fallback_tips = [
            {"title": "Stay Hydrated", "content": "Drink at least 8 glasses of water today.", "icon": "water_drop", "color": "#2196F3"},
            {"title": "Move Your Body", "content": "Take a 10-minute walk to boost your energy.", "icon": "fitness_center", "color": "#4CAF50"},
            {"title": "Eat Well", "content": "Include colorful vegetables in your meals.", "icon": "restaurant", "color": "#FF9800"},
            {"title": "Rest Well", "content": "Aim for 7-8 hours of quality sleep tonight.", "icon": "bedtime", "color": "#9C27B0"},
            {"title": "Mental Wellness", "content": "Take 5 minutes for deep breathing exercises.", "icon": "psychology", "color": "#00BCD4"}
        ]
        return jsonify({
            'status': 'fallback',
            'tips': fallback_tips[:count],
            'personalized': False,
            'language': language
        })


@ai_sathi_bp.route('/weather-health-alerts', methods=['POST'])
def get_weather_health_alerts():
    """
    Generate weather and health/pandemic alerts focused on disease prevention.
    """
    import g4f
    import re
    import json as json_lib
    
    data = request.get_json() or {}
    language = data.get('language', 'en')
    count = data.get('count', 5)
    
    # Collect weather/climate context
    weather_info = ""
    outbreak_info = ""
    
    try:
        from app.models import DiseaseOutbreak
        
        # Get active disease outbreaks
        active_outbreaks = DiseaseOutbreak.query.filter_by(is_active=True).all()
        if active_outbreaks:
            outbreak_info = "\nActive Disease Outbreaks:\n"
            for outbreak in active_outbreaks:
                outbreak_info += f"- {outbreak.disease_name}: {outbreak.confirmed_cases} cases ({outbreak.severity} severity)\n"
                
    except Exception as e:
        print(f"Error fetching outbreak data: {e}")
    
    # Language mapping
    language_names = {'en': 'English', 'ne': 'Nepali', 'hi': 'Hindi'}
    lang_name = language_names.get(language, 'English')
    
    # Generate alerts using AI
    prompt = f"""You are a public health alert generator. Generate {count} health alerts based on current conditions.

{weather_info if weather_info else "Weather data not available - focus on general seasonal health."}

{outbreak_info if outbreak_info else "No active disease outbreaks - focus on prevention."}

FOCUS ON:
1. Disease prevention based on weather conditions
2. Air quality health advisories if AQI is high
3. Active outbreak precautions if any
4. Seasonal health risks (heat, cold, monsoon diseases)
5. {"Respond in " + lang_name + " language." if language != 'en' else ""}

Each alert should be:
- SHORT and actionable (1-2 sentences)
- Health-focused with prevention tips
- Weather-relevant when applicable

Return ONLY a valid JSON array with {count} objects:
[
  {{"title": "Alert Title", "content": "Health advisory content", "icon": "icon_name", "color": "#hexcolor", "type": "weather|outbreak|prevention"}},
  ...
]

Icon options: thermostat, air, coronavirus, masks, sanitizer, home, warning, shield, water_drop, medical_services
Colors: Red (#F44336) for urgent, Orange (#FF9800) for warning, Blue (#2196F3) for info, Green (#4CAF50) for prevention

OUTPUT ONLY THE JSON ARRAY."""

    try:
        response = ai_call_with_retry(
            model=current_app.config['AI_ALERTS_MODEL'],
            messages=[
                {'role': 'system', 'content': 'You are a health alert generator. Return ONLY valid JSON arrays.'},
                {'role': 'user', 'content': prompt}
            ],
            fallback_models=current_app.config.get('AI_ALERTS_MODEL_FALLBACKS', []),
        )
        
        # Strip think tags
        response = re.sub(r'<think>[\s\S]*?</think>', '', response, flags=re.IGNORECASE).strip()
        
        # Extract JSON
        json_match = re.search(r'\[[\s\S]*\]', response)
        if json_match:
            alerts = json_lib.loads(json_match.group())
            return jsonify({
                'status': 'success',
                'alerts': alerts[:count],
                'language': language,
                'has_outbreaks': bool(outbreak_info)
            })
        else:
            raise ValueError("No valid JSON found")
            
    except Exception as e:
        print(f"Error generating health alerts: {e}")
        # Fallback alerts
        fallback_alerts = [
            {"title": "Stay Cool", "content": "High temperatures today - stay hydrated and avoid midday sun.", "icon": "thermostat", "color": "#FF9800", "type": "weather"},
            {"title": "Air Quality", "content": "Monitor outdoor activities if you have respiratory conditions.", "icon": "air", "color": "#2196F3", "type": "weather"},
            {"title": "Wash Hands", "content": "Regular handwashing prevents most common infections.", "icon": "sanitizer", "color": "#4CAF50", "type": "prevention"},
            {"title": "Wear Masks", "content": "In crowded places, masks reduce disease transmission.", "icon": "masks", "color": "#9C27B0", "type": "prevention"},
            {"title": "Stay Informed", "content": "Check health advisories for your area regularly.", "icon": "medical_services", "color": "#00BCD4", "type": "prevention"}
        ]
        return jsonify({
            'status': 'fallback',
            'alerts': fallback_alerts[:count],
            'language': language,
            'has_outbreaks': False
        })


@ai_sathi_bp.route('/disease-info/<disease_name>', methods=['GET'])
def get_disease_info(disease_name):
    """
    Get AI-generated comprehensive disease information
    Returns structured JSON with symptoms, prevention, transmission, etc.
    """
    try:
        import g4f
        import json
        
        prompt = f"""You are a medical information specialist. Provide comprehensive information about {disease_name} in the following JSON format. Be accurate and informative.

Return ONLY valid JSON with this exact structure:
{{
    "name": "{disease_name}",
    "icon": "emoji representing the disease",
    "severity": "low/moderate/high",
    "status": "endemic/seasonal/outbreak/monitoring",
    "transmission": "how it spreads (e.g., Airborne, Mosquito, Waterborne, Contact)",
    "peak_season": "when it's most common (e.g., Monsoon, Winter, Year-round)",
    "description": "2-3 sentence description of the disease",
    "symptoms": ["symptom1", "symptom2", "symptom3", "symptom4", "symptom5"],
    "prevention": ["prevention1", "prevention2", "prevention3", "prevention4"],
    "affected_regions": ["region1", "region2", "region3"],
    "risk_message": "A sentence describing the current risk level and what to do",
    "when_to_seek_help": ["emergency sign1", "emergency sign2", "emergency sign3"]
}}

ONLY OUTPUT THE JSON, NO OTHER TEXT."""

        response = ai_call_with_retry(
            model=current_app.config['AI_JSON_MODEL'],
            messages=[
                {'role': 'system', 'content': 'You are a medical information specialist. Return ONLY valid JSON, no other text or markdown.'},
                {'role': 'user', 'content': prompt}
            ],
            fallback_models=current_app.config.get('AI_JSON_MODEL_FALLBACKS', []),
        )
        
        # Clean up response - extract JSON
        response_text = response.strip()
        
        # Try to extract JSON if wrapped in markdown code blocks
        if '```json' in response_text:
            response_text = response_text.split('```json')[1].split('```')[0].strip()
        elif '```' in response_text:
            response_text = response_text.split('```')[1].split('```')[0].strip()
        
        disease_info = json.loads(response_text)
        disease_info['source'] = 'AI-generated'
        disease_info['disclaimer'] = DISCLAIMER
        
        return jsonify(disease_info)
        
    except json.JSONDecodeError as e:
        # Fallback if JSON parsing fails
        return jsonify({
            'name': disease_name,
            'icon': '🦠',
            'severity': 'moderate',
            'status': 'active',
            'transmission': 'Variable',
            'peak_season': 'Unknown',
            'description': f'Information about {disease_name}. Please consult a healthcare provider for accurate details.',
            'symptoms': ['Various symptoms may occur'],
            'prevention': ['Follow general health guidelines', 'Consult healthcare provider'],
            'affected_regions': ['Information unavailable'],
            'risk_message': 'Consult a healthcare provider for accurate risk assessment.',
            'when_to_seek_help': ['High fever', 'Difficulty breathing', 'Severe symptoms'],
            'source': 'Fallback',
            'disclaimer': DISCLAIMER
        })
        
    except Exception as e:
        return jsonify({
            'name': disease_name,
            'icon': '🦠',
            'severity': 'unknown',
            'status': 'unknown',
            'transmission': 'Unknown',
            'peak_season': 'Unknown',
            'description': f'Unable to fetch information for {disease_name} at this time.',
            'symptoms': [],
            'prevention': [],
            'affected_regions': [],
            'risk_message': 'Please try again later.',
            'when_to_seek_help': [],
            'source': 'Error',
            'error': str(e),
            'disclaimer': DISCLAIMER
        }), 500