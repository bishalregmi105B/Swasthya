"""
AI Tools Module - Modular database query functions for AI integration

This module provides tools that AI can call to fetch relevant data from the database.
Each tool returns structured data that can be formatted into AI responses.
"""

from app import db
from app.models import (
    Doctor, Hospital, Department, Medicine, Pharmacy,
    BloodBank, HealthAlert, Appointment, MedicineReminder,
    DiseaseOutbreak, EmergencyContact
)
from sqlalchemy import or_, func


class AITools:
    """
    AI Tools class providing database query methods.
    Each method is a 'tool' that can be called based on AI decisions.
    """
    
    # ==================== DOCTOR TOOLS ====================
    
    @staticmethod
    def search_doctors(specialty=None, condition=None, city=None, limit=3):
        """
        Search for doctors by specialty or condition.
        
        Args:
            specialty: Doctor specialization (cardiologist, dermatologist, etc.)
            condition: Health condition to match specialty (chest pain → cardiologist)
            city: Filter by city/location
            limit: Maximum number of results
            
        Returns:
            List of doctor dicts with essential info
        """
        query = Doctor.query.filter(Doctor.is_available == True)
        
        # Map common conditions to specialties
        condition_specialty_map = {
            'heart': 'cardiologist', 'chest pain': 'cardiologist', 'blood pressure': 'cardiologist',
            'skin': 'dermatologist', 'rash': 'dermatologist', 'acne': 'dermatologist',
            'mental': 'psychiatrist', 'anxiety': 'psychiatrist', 'depression': 'psychiatrist',
            'child': 'pediatrician', 'baby': 'pediatrician', 'infant': 'pediatrician',
            'diet': 'nutritionist', 'weight': 'nutritionist', 'nutrition': 'nutritionist',
            'headache': 'neurologist', 'migraine': 'neurologist', 'brain': 'neurologist',
            'bone': 'orthopedic', 'joint': 'orthopedic', 'fracture': 'orthopedic',
            'eye': 'ophthalmologist', 'vision': 'ophthalmologist',
            'teeth': 'dentist', 'dental': 'dentist', 'gum': 'dentist',
            'ear': 'ent', 'nose': 'ent', 'throat': 'ent',
            'stomach': 'gastroenterologist', 'digestion': 'gastroenterologist',
            'lung': 'pulmonologist', 'breathing': 'pulmonologist', 'cough': 'physician',
            'fever': 'physician', 'cold': 'physician', 'flu': 'physician',
        }
        
        # Determine specialty from condition
        if condition and not specialty:
            condition_lower = condition.lower()
            for keyword, spec in condition_specialty_map.items():
                if keyword in condition_lower:
                    specialty = spec
                    break
        
        if specialty:
            query = query.filter(Doctor.specialization == specialty)
        
        # Order by rating and experience
        query = query.order_by(Doctor.rating.desc(), Doctor.experience_years.desc())
        
        doctors = query.limit(limit).all()
        
        return [{
            'id': d.id,
            'name': d.user.full_name if d.user else f'Dr. {d.id}',
            'specialty': d.specialization,
            'rating': float(d.rating) if d.rating else 4.0,
            'experience': d.experience_years or 5,
            'fee': float(d.consultation_fee) if d.consultation_fee else None,
            'hospital': d.hospital.name if d.hospital else None,
            'is_verified': d.is_verified,
            'image': d.user.profile_image if d.user else None,
        } for d in doctors]
    
    # ==================== HOSPITAL TOOLS ====================
    
    @staticmethod
    def search_hospitals(hospital_type=None, city=None, service=None, emergency=False, limit=3):
        """
        Search for hospitals by type, city, or service.
        
        Args:
            hospital_type: 'hospital', 'clinic', 'pharmacy'
            city: City name to filter
            service: Specific service needed (MRI, X-Ray, etc.)
            emergency: Filter for 24/7 emergency hospitals
            limit: Maximum number of results
            
        Returns:
            List of hospital dicts
        """
        query = Hospital.query.filter(Hospital.is_active == True)
        
        if hospital_type:
            query = query.filter(Hospital.type == hospital_type)
        
        if city:
            query = query.filter(Hospital.city.ilike(f'%{city}%'))
        
        if emergency:
            query = query.filter(Hospital.has_emergency == True)
        
        query = query.order_by(Hospital.rating.desc())
        
        hospitals = query.limit(limit).all()
        
        return [{
            'id': h.id,
            'name': h.name,
            'type': h.type,
            'city': h.city,
            'address': h.address,
            'rating': float(h.rating) if h.rating else 4.0,
            'phone': h.phone,
            'has_emergency': h.has_emergency,
            'image': h.image_url,
        } for h in hospitals]
    
    # ==================== MEDICINE TOOLS ====================
    
    @staticmethod
    def search_medicines(name=None, category=None, symptom=None, limit=3):
        """
        Search for medicines by name, category, or symptom.
        
        Args:
            name: Medicine name or partial name
            category: Category (pain relief, antibiotics, etc.)
            symptom: Symptom to treat
            limit: Maximum number of results
            
        Returns:
            List of medicine dicts
        """
        query = Medicine.query
        
        if name:
            query = query.filter(or_(
                Medicine.name.ilike(f'%{name}%'),
                Medicine.generic_name.ilike(f'%{name}%')
            ))
        
        if category:
            query = query.filter(Medicine.category.ilike(f'%{category}%'))
        
        medicines = query.limit(limit).all()
        
        return [{
            'id': m.id,
            'name': m.name,
            'generic_name': m.generic_name,
            'category': m.category,
            'price': float(m.price) if m.price else None,
            'requires_prescription': m.requires_prescription,
            'form': m.form,
            'strength': m.strength,
        } for m in medicines]
    
    # ==================== PHARMACY TOOLS ====================
    
    @staticmethod
    def search_pharmacies(city=None, is_open=True, limit=3):
        """
        Search for pharmacies.
        
        Args:
            city: City to filter
            is_open: Filter for currently open pharmacies
            limit: Maximum number of results
            
        Returns:
            List of pharmacy dicts
        """
        query = Pharmacy.query.filter(Pharmacy.is_verified == True)
        
        if city:
            query = query.filter(Pharmacy.city.ilike(f'%{city}%'))
        
        if is_open:
            query = query.filter(Pharmacy.is_open == True)
        
        pharmacies = query.order_by(Pharmacy.rating.desc()).limit(limit).all()
        
        return [{
            'id': p.id,
            'name': p.name,
            'address': p.address,
            'city': p.city,
            'phone': p.phone,
            'rating': float(p.rating) if p.rating else 4.0,
            'delivery_time': p.delivery_time,
            'is_open': p.is_open,
        } for p in pharmacies]
    
    # ==================== BLOOD BANK TOOLS ====================
    
    @staticmethod
    def search_blood_banks(blood_type=None, city=None, limit=3):
        """
        Search for blood banks by blood type availability.
        
        Args:
            blood_type: Blood type needed (A+, B-, O+, etc.)
            city: City to filter
            limit: Maximum number of results
            
        Returns:
            List of blood bank dicts
        """
        query = BloodBank.query.filter(BloodBank.is_active == True)
        
        if city:
            query = query.filter(BloodBank.city.ilike(f'%{city}%'))
        
        blood_banks = query.limit(limit).all()
        
        return [{
            'id': b.id,
            'name': b.name,
            'city': b.city,
            'address': b.address,
            'phone': b.phone,
            'blood_type': blood_type,
        } for b in blood_banks]
    
    # ==================== EMERGENCY TOOLS ====================
    
    @staticmethod
    def get_emergency_contacts(city=None, contact_type=None, limit=5):
        """
        Get emergency contacts.
        
        Args:
            city: City to filter
            contact_type: Type of contact (ambulance, fire, police, hospital)
            limit: Maximum number of results
            
        Returns:
            List of emergency contact dicts
        """
        query = EmergencyContact.query
        
        if city:
            query = query.filter(EmergencyContact.city.ilike(f'%{city}%'))
        
        if contact_type:
            query = query.filter(EmergencyContact.contact_type == contact_type)
        
        contacts = query.limit(limit).all()
        
        return [{
            'id': c.id,
            'name': c.name,
            'type': c.contact_type,
            'phone': c.phone,
            'city': c.city,
        } for c in contacts]
    
    # ==================== DISEASE TOOLS ====================
    
    @staticmethod
    def get_disease_outbreaks(country=None, limit=3):
        """
        Get current disease outbreaks.
        
        Args:
            country: Country to filter
            limit: Maximum number of results
            
        Returns:
            List of outbreak dicts
        """
        query = DiseaseOutbreak.query.filter(DiseaseOutbreak.is_active == True)
        
        if country:
            query = query.filter(DiseaseOutbreak.country.ilike(f'%{country}%'))
        
        outbreaks = query.order_by(DiseaseOutbreak.created_at.desc()).limit(limit).all()
        
        return [{
            'id': o.id,
            'disease': o.disease_name,
            'country': o.country,
            'severity': o.severity,
            'cases': o.total_cases,
        } for o in outbreaks]


# ==================== TOOL DEFINITIONS FOR AI ====================
# These definitions tell the AI what tools are available and how to use them

AI_TOOL_DEFINITIONS = [
    {
        'name': 'search_doctors',
        'description': 'Search for doctors by specialty or health condition. Use this when user mentions symptoms or needs a specific type of doctor.',
        'parameters': {
            'specialty': 'Doctor specialization (cardiologist, dermatologist, psychiatrist, physician, etc.)',
            'condition': 'Health condition or symptoms (chest pain, skin rash, anxiety, etc.)',
            'limit': 'Number of results (default 3)'
        }
    },
    {
        'name': 'search_hospitals',
        'description': 'Search for hospitals, clinics, or pharmacies. Use when user needs hospital recommendations or emergency care.',
        'parameters': {
            'hospital_type': 'Type: hospital, clinic, pharmacy',
            'city': 'City name',
            'emergency': 'True if need 24/7 emergency (default False)',
            'limit': 'Number of results (default 3)'
        }
    },
    {
        'name': 'search_medicines',
        'description': 'Search for medicines by name or category. Use when discussing medication options.',
        'parameters': {
            'name': 'Medicine name or partial name',
            'category': 'Category like pain relief, antibiotics',
            'limit': 'Number of results (default 3)'
        }
    },
    {
        'name': 'search_pharmacies',
        'description': 'Find nearby pharmacies. Use when user needs to buy medicines.',
        'parameters': {
            'city': 'City name',
            'is_open': 'Filter for currently open (default True)',
            'limit': 'Number of results (default 3)'
        }
    },
    {
        'name': 'search_blood_banks',
        'description': 'Find blood banks. Use when user needs blood donation or transfusion.',
        'parameters': {
            'blood_type': 'Blood type needed (A+, B-, O+, etc.)',
            'city': 'City name',
            'limit': 'Number of results (default 3)'
        }
    },
    {
        'name': 'get_emergency_contacts',
        'description': 'Get emergency contacts like ambulance, hospital hotlines. Use in emergency situations.',
        'parameters': {
            'city': 'City name',
            'contact_type': 'Type: ambulance, fire, police, hospital',
            'limit': 'Number of results (default 5)'
        }
    }
]


def execute_tool(tool_name: str, params: dict):
    """
    Execute a tool by name with given parameters.
    
    Args:
        tool_name: Name of the tool to execute
        params: Dictionary of parameters
        
    Returns:
        Tool result or error message
    """
    tool_map = {
        'search_doctors': AITools.search_doctors,
        'search_hospitals': AITools.search_hospitals,
        'search_medicines': AITools.search_medicines,
        'search_pharmacies': AITools.search_pharmacies,
        'search_blood_banks': AITools.search_blood_banks,
        'get_emergency_contacts': AITools.get_emergency_contacts,
        'get_disease_outbreaks': AITools.get_disease_outbreaks,
    }
    
    if tool_name not in tool_map:
        return {'error': f'Unknown tool: {tool_name}'}
    
    try:
        result = tool_map[tool_name](**params)
        return {'success': True, 'data': result, 'tool': tool_name}
    except Exception as e:
        return {'error': str(e), 'tool': tool_name}


def format_tool_results_for_ai(tool_results: list) -> str:
    """
    Format tool results into a string for AI to incorporate in response.
    
    Args:
        tool_results: List of tool execution results
        
    Returns:
        Formatted string for AI context
    """
    output = []
    
    for result in tool_results:
        if result.get('error'):
            output.append(f"Tool {result.get('tool')} failed: {result['error']}")
            continue
        
        tool = result.get('tool')
        data = result.get('data', [])
        
        if tool == 'search_doctors' and data:
            output.append("Available doctors:")
            for d in data:
                output.append(f"- Dr. {d['name']} ({d['specialty']}) - Rating: {d['rating']}★, Experience: {d['experience']} years [Doctor: id={d['id']}]")
        
        elif tool == 'search_hospitals' and data:
            output.append("Recommended hospitals:")
            for h in data:
                output.append(f"- {h['name']} ({h['type']}) - {h['city']} [Hospital: id={h['id']}]")
        
        elif tool == 'search_medicines' and data:
            output.append("Related medicines:")
            for m in data:
                rx = "⚠️ Prescription required" if m['requires_prescription'] else "OTC"
                output.append(f"- {m['name']} ({m['form']}) - {rx} [Medicine: id={m['id']}]")
        
        elif tool == 'search_pharmacies' and data:
            output.append("Nearby pharmacies:")
            for p in data:
                output.append(f"- {p['name']} - {p['address']} [Pharmacy: id={p['id']}]")
        
        elif tool == 'search_blood_banks' and data:
            output.append("Blood banks:")
            for b in data:
                output.append(f"- {b['name']} - {b['city']} [BloodBank: id={b['id']}]")
        
        elif tool == 'get_emergency_contacts' and data:
            output.append("Emergency contacts:")
            for c in data:
                output.append(f"- {c['name']} ({c['type']}): {c['phone']} [Emergency: id={c['id']}]")
    
    return "\n".join(output)
