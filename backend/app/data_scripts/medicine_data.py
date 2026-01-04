"""
Medicine Data Service
Fetches medication information from openFDA and RxNorm APIs
For drug search, details, interactions, and adverse events
"""
import requests
from typing import List, Dict, Optional
from functools import lru_cache

# openFDA Drug API endpoints
OPENFDA_DRUG_LABEL = "https://api.fda.gov/drug/label.json"
OPENFDA_DRUG_EVENT = "https://api.fda.gov/drug/event.json"

# RxNorm API endpoints (NLM)
RXNORM_BASE = "https://rxnav.nlm.nih.gov/REST"

# DailyMed API
DAILYMED_API = "https://dailymed.nlm.nih.gov/dailymed/services/v2"

# Medicine categories for browsing
MEDICINE_CATEGORIES = [
    {"id": "pain", "name": "Pain Relief", "icon": "💊", "keywords": ["analgesic", "pain", "ibuprofen", "acetaminophen"]},
    {"id": "antibiotic", "name": "Antibiotics", "icon": "🦠", "keywords": ["antibiotic", "amoxicillin", "penicillin", "azithromycin"]},
    {"id": "cardiovascular", "name": "Heart & Blood Pressure", "icon": "❤️", "keywords": ["cardiovascular", "blood pressure", "hypertension", "statin"]},
    {"id": "diabetes", "name": "Diabetes", "icon": "🍬", "keywords": ["diabetes", "insulin", "metformin", "glucose"]},
    {"id": "respiratory", "name": "Respiratory", "icon": "🫁", "keywords": ["asthma", "inhaler", "bronchodilator", "corticosteroid"]},
    {"id": "mental", "name": "Mental Health", "icon": "🧠", "keywords": ["antidepressant", "anxiety", "ssri", "psychiatric"]},
    {"id": "allergy", "name": "Allergy", "icon": "🤧", "keywords": ["antihistamine", "allergy", "cetirizine", "loratadine"]},
    {"id": "gastrointestinal", "name": "Digestive", "icon": "🍽️", "keywords": ["antacid", "omeprazole", "digestive", "laxative"]},
    {"id": "vitamins", "name": "Vitamins & Supplements", "icon": "🥗", "keywords": ["vitamin", "supplement", "mineral", "calcium"]},
    {"id": "skin", "name": "Skin & Topical", "icon": "🧴", "keywords": ["topical", "cream", "ointment", "dermatological"]},
]


def search_medicines(query: str, limit: int = 20) -> List[Dict]:
    """
    Search for medicines using openFDA Drug Label API
    """
    if not query or len(query) < 2:
        return []
    
    try:
        # Search in brand name and generic name
        params = {
            "search": f'openfda.brand_name:"{query}" OR openfda.generic_name:"{query}"',
            "limit": limit
        }
        
        response = requests.get(OPENFDA_DRUG_LABEL, params=params, timeout=15)
        
        if response.status_code == 404:
            # Try broader search
            params = {"search": f'openfda.brand_name:*{query}*', "limit": limit}
            response = requests.get(OPENFDA_DRUG_LABEL, params=params, timeout=15)
        
        if response.status_code != 200:
            return _fallback_rxnorm_search(query, limit)
        
        data = response.json()
        results = data.get('results', [])
        
        medicines = []
        seen_names = set()
        
        for item in results:
            openfda = item.get('openfda', {})
            brand_names = openfda.get('brand_name', [])
            generic_names = openfda.get('generic_name', [])
            
            name = brand_names[0] if brand_names else (generic_names[0] if generic_names else None)
            if not name or name.upper() in seen_names:
                continue
            
            seen_names.add(name.upper())
            
            medicines.append({
                "id": openfda.get('spl_id', [''])[0] or f"med_{len(medicines)}",
                "brand_name": brand_names[0] if brand_names else "N/A",
                "generic_name": generic_names[0] if generic_names else "N/A",
                "manufacturer": openfda.get('manufacturer_name', ['Unknown'])[0],
                "route": openfda.get('route', ['Unknown'])[0] if openfda.get('route') else "Unknown",
                "substance": openfda.get('substance_name', []),
                "product_type": openfda.get('product_type', [''])[0],
                "rxcui": openfda.get('rxcui', []),
            })
        
        return medicines
        
    except Exception as e:
        print(f"Error searching medicines: {e}")
        return _fallback_rxnorm_search(query, limit)


def _fallback_rxnorm_search(query: str, limit: int = 20) -> List[Dict]:
    """Fallback search using RxNorm API"""
    try:
        url = f"{RXNORM_BASE}/drugs.json"
        params = {"name": query}
        
        response = requests.get(url, params=params, timeout=10)
        if response.status_code != 200:
            return []
        
        data = response.json()
        drug_group = data.get('drugGroup', {})
        concept_group = drug_group.get('conceptGroup', [])
        
        medicines = []
        for group in concept_group:
            for concept in group.get('conceptProperties', []):
                medicines.append({
                    "id": concept.get('rxcui', ''),
                    "brand_name": concept.get('name', ''),
                    "generic_name": concept.get('name', ''),
                    "manufacturer": "Unknown",
                    "route": "Unknown",
                    "substance": [],
                    "product_type": concept.get('tty', ''),
                    "rxcui": [concept.get('rxcui', '')],
                })
                if len(medicines) >= limit:
                    break
        
        return medicines
        
    except Exception as e:
        print(f"RxNorm fallback error: {e}")
        return []


def get_medicine_details(drug_name: str, language: str = 'en') -> Optional[Dict]:
    """Get detailed information about a specific medicine"""
    import os
    from g4f.client import Client
    import g4f
    
    lang_instruction = ""
    if language == 'ne':
        lang_instruction = "\n\nIMPORTANT: Respond entirely in Nepali (नेपाली) language."
    
    try:
        # First try to get data from openFDA
        fda_data = _get_openfda_label(drug_name)
        
        # Get model and provider from environment
        model = os.environ.get('AI_CHAT_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
        provider_name = os.environ.get('AI_DEFAULT_PROVIDER', 'DeepInfra')
        
        # Get provider class
        provider = getattr(g4f.Provider, provider_name, None)
        
        prompt = f"""Provide comprehensive pharmaceutical information about: {drug_name}

Include these sections:
1. **Overview**: What is this medication and what is it used for
2. **How It Works**: Mechanism of action
3. **Dosage**: Common dosing information
4. **Side Effects**: Common and serious side effects
5. **Warnings**: Important precautions and contraindications
6. **Drug Interactions**: Notable interactions to avoid
7. **Storage**: How to store the medication
8. **Important Notes**: Key points patients should know

Use clear headers and bullet points. Be accurate and evidence-based.
Include a disclaimer to consult a healthcare provider or pharmacist.{lang_instruction}"""

        # Use Client pattern
        client = Client(provider=provider) if provider else Client()
        
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            web_search=False
        )
        
        ai_content = response.choices[0].message.content
        
        return {
            "name": drug_name,
            "description": ai_content,
            "fda_data": fda_data,
            "source": "AI + openFDA",
            "disclaimer": "Consult your doctor or pharmacist before taking any medication."
        }
        
    except Exception as e:
        print(f"Error getting medicine details: {e}")
        return {
            "name": drug_name,
            "description": f"Detailed information about {drug_name} is currently unavailable.",
            "fda_data": None,
            "source": "Fallback",
            "disclaimer": "Always consult a healthcare provider or pharmacist."
        }


def _get_openfda_label(drug_name: str) -> Optional[Dict]:
    """Get FDA label data for a drug"""
    try:
        params = {
            "search": f'openfda.brand_name:"{drug_name}"',
            "limit": 1
        }
        response = requests.get(OPENFDA_DRUG_LABEL, params=params, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            results = data.get('results', [])
            if results:
                item = results[0]
                return {
                    "indications": item.get('indications_and_usage', [''])[0][:500] if item.get('indications_and_usage') else None,
                    "warnings": item.get('warnings', [''])[0][:500] if item.get('warnings') else None,
                    "dosage": item.get('dosage_and_administration', [''])[0][:500] if item.get('dosage_and_administration') else None,
                }
        return None
    except:
        return None


def get_drug_interactions(rxcui: str) -> List[Dict]:
    """
    Get drug interactions for a given RXCUI using RxNorm Interaction API
    """
    try:
        url = f"{RXNORM_BASE}/interaction/interaction.json"
        params = {"rxcui": rxcui}
        
        response = requests.get(url, params=params, timeout=10)
        if response.status_code != 200:
            return []
        
        data = response.json()
        interaction_pairs = data.get('interactionTypeGroup', [])
        
        interactions = []
        for group in interaction_pairs:
            for interaction_type in group.get('interactionType', []):
                for pair in interaction_type.get('interactionPair', []):
                    interactions.append({
                        "severity": pair.get('severity', 'Unknown'),
                        "description": pair.get('description', ''),
                        "interacting_drug": pair.get('interactionConcept', [{}])[0].get('minConceptItem', {}).get('name', '')
                    })
        
        return interactions
        
    except Exception as e:
        print(f"Error getting interactions: {e}")
        return []


def get_adverse_events(drug_name: str, limit: int = 10) -> List[Dict]:
    """Get reported adverse events for a drug from openFDA"""
    try:
        params = {
            "search": f'patient.drug.medicinalproduct:"{drug_name}"',
            "limit": limit
        }
        
        response = requests.get(OPENFDA_DRUG_EVENT, params=params, timeout=15)
        if response.status_code != 200:
            return []
        
        data = response.json()
        results = data.get('results', [])
        
        events = []
        for item in results:
            reactions = item.get('patient', {}).get('reaction', [])
            reaction_names = [r.get('reactionmeddrapt', '') for r in reactions]
            
            events.append({
                "date": item.get('receiptdate', ''),
                "serious": item.get('serious', 0) == 1,
                "reactions": reaction_names[:5],
                "outcome": item.get('patient', {}).get('patientonsetage', 'Unknown')
            })
        
        return events
        
    except Exception as e:
        print(f"Error getting adverse events: {e}")
        return []


def get_medicine_categories() -> List[Dict]:
    """Get list of medicine categories for browsing"""
    return MEDICINE_CATEGORIES


@lru_cache(maxsize=1)
def get_common_medicines() -> List[Dict]:
    """Get list of common medicines for quick access"""
    common = [
        "Paracetamol", "Ibuprofen", "Amoxicillin", "Omeprazole", 
        "Metformin", "Aspirin", "Cetirizine", "Azithromycin"
    ]
    
    results = []
    for med in common:
        search_result = search_medicines(med, limit=1)
        if search_result:
            results.append(search_result[0])
    
    return results
