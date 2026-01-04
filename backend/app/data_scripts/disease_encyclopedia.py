"""
Disease Encyclopedia Service
Fetches disease/condition information from NIH Clinical Tables API
For searching, browsing, and getting detailed disease information
"""
import requests
from typing import List, Dict, Optional
from functools import lru_cache

# NIH Clinical Tables API - Medical Conditions
NIH_CONDITIONS_URL = "https://clinicaltables.nlm.nih.gov/api/conditions/v3/search"

# Common disease categories for browsing
DISEASE_CATEGORIES = [
    {"id": "infectious", "name": "Infectious Diseases", "icon": "🦠", "keywords": ["infection", "viral", "bacterial", "fungal"]},
    {"id": "cardiovascular", "name": "Heart & Cardiovascular", "icon": "❤️", "keywords": ["heart", "cardiac", "vascular", "blood pressure"]},
    {"id": "respiratory", "name": "Respiratory Diseases", "icon": "🫁", "keywords": ["lung", "respiratory", "breathing", "asthma"]},
    {"id": "digestive", "name": "Digestive System", "icon": "🍽️", "keywords": ["stomach", "intestine", "digestive", "gastro"]},
    {"id": "neurological", "name": "Neurological", "icon": "🧠", "keywords": ["brain", "nerve", "neural", "neuro"]},
    {"id": "musculoskeletal", "name": "Bones & Muscles", "icon": "🦴", "keywords": ["bone", "muscle", "joint", "arthritis"]},
    {"id": "endocrine", "name": "Hormonal & Metabolic", "icon": "⚗️", "keywords": ["diabetes", "thyroid", "hormone", "metabolic"]},
    {"id": "skin", "name": "Skin Conditions", "icon": "🩹", "keywords": ["skin", "derma", "rash", "eczema"]},
    {"id": "mental", "name": "Mental Health", "icon": "🧘", "keywords": ["anxiety", "depression", "mental", "psychiatric"]},
    {"id": "cancer", "name": "Cancer & Tumors", "icon": "🎗️", "keywords": ["cancer", "tumor", "oncology", "malignant"]},
    {"id": "kidney", "name": "Kidney & Urinary", "icon": "🫘", "keywords": ["kidney", "renal", "urinary", "bladder"]},
    {"id": "eye", "name": "Eye Diseases", "icon": "👁️", "keywords": ["eye", "vision", "ophthalmic", "retina"]},
]


def search_diseases(query: str, max_results: int = 20) -> List[Dict]:
    """
    Search for diseases/conditions using NIH Clinical Tables API
    Returns list of conditions with ICD codes
    """
    if not query or len(query) < 2:
        return []
    
    try:
        params = {
            "terms": query,
            "maxList": max_results,
            "df": "primary_name,word_synonyms,icd10cm_codes,icd9cm_codes"
        }
        
        response = requests.get(NIH_CONDITIONS_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # NIH API returns: [total_count, codes, extra_data, display_strings]
        if not data or len(data) < 4:
            return []
        
        results = data[3] if len(data) > 3 else []
        
        conditions = []
        for i, item in enumerate(results):
            if isinstance(item, list) and len(item) >= 1:
                name = item[0] if item[0] else ""
                synonyms = item[1] if len(item) > 1 and item[1] else ""
                icd10 = item[2] if len(item) > 2 and item[2] else ""
                icd9 = item[3] if len(item) > 3 and item[3] else ""
                
                conditions.append({
                    "id": f"cond_{i}",
                    "name": name,
                    "synonyms": synonyms.split(";") if synonyms else [],
                    "icd10_codes": icd10.split(";") if icd10 else [],
                    "icd9_codes": icd9.split(";") if icd9 else [],
                    "category": _detect_category(name)
                })
        
        return conditions
        
    except Exception as e:
        print(f"Error searching diseases: {e}")
        return []


def _detect_category(name: str) -> Optional[str]:
    """Detect disease category from name"""
    name_lower = name.lower()
    for cat in DISEASE_CATEGORIES:
        for keyword in cat["keywords"]:
            if keyword in name_lower:
                return cat["id"]
    return None


def get_disease_details(disease_name: str, language: str = 'en') -> Optional[Dict]:
    """Get detailed information about a specific disease using AI"""
    import os
    from g4f.client import Client
    import g4f
    
    lang_instruction = ""
    if language == 'ne':
        lang_instruction = "\n\nIMPORTANT: Respond entirely in Nepali (नेपाली) language."
    
    try:
        # Get model and provider from environment
        model = os.environ.get('AI_CHAT_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
        provider_name = os.environ.get('AI_DEFAULT_PROVIDER', 'DeepInfra')
        
        # Get provider class
        provider = getattr(g4f.Provider, provider_name, None)
        
        prompt = f"""Provide comprehensive medical information about: {disease_name}

Include these sections:
1. **Overview**: Brief description
2. **Causes**: What causes this condition
3. **Risk Factors**: Who is at higher risk
4. **Symptoms**: Common signs and symptoms
5. **Diagnosis**: How it's diagnosed
6. **Treatment**: Treatment options
7. **Prevention**: How to prevent or reduce risk
8. **When to See a Doctor**: Warning signs

Use clear headers and bullet points. Be accurate and evidence-based.
Include a disclaimer that this is for informational purposes only.{lang_instruction}"""

        # Use Client pattern
        client = Client(provider=provider) if provider else Client()
        
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            web_search=False
        )
        
        content = response.choices[0].message.content
        
        return {
            "name": disease_name,
            "description": content,
            "source": "AI-generated medical information",
            "disclaimer": "This information is for educational purposes only. Consult a healthcare provider for diagnosis and treatment."
        }
        
    except Exception as e:
        print(f"Error getting disease details: {e}")
        return {
            "name": disease_name,
            "description": f"Detailed information about {disease_name} is currently unavailable.",
            "source": "Fallback",
            "disclaimer": "Always consult a healthcare provider for medical advice."
        }


def get_disease_categories() -> List[Dict]:
    """Get list of disease categories for browsing"""
    return DISEASE_CATEGORIES


def get_diseases_by_category(category_id: str, limit: int = 15) -> List[Dict]:
    """Get diseases in a specific category"""
    category = next((c for c in DISEASE_CATEGORIES if c["id"] == category_id), None)
    if not category:
        return []
    
    results = []
    for keyword in category["keywords"][:2]:
        diseases = search_diseases(keyword, max_results=8)
        for d in diseases:
            if d["name"] not in [r["name"] for r in results]:
                results.append(d)
        if len(results) >= limit:
            break
    
    return results[:limit]


@lru_cache(maxsize=1)
def get_common_diseases() -> List[Dict]:
    """Get list of common diseases for quick access"""
    common = [
        "Diabetes", "Hypertension", "Asthma", "Arthritis", "Migraine",
        "Depression", "Anxiety", "Influenza", "Pneumonia", "Bronchitis"
    ]
    
    results = []
    for disease in common:
        search_result = search_diseases(disease, max_results=1)
        if search_result:
            results.append(search_result[0])
    
    return results
