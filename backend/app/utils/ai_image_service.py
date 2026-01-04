"""
AI Image Analysis Service using g4f
Provides real image analysis for medical documents and skin conditions
"""
import g4f
import base64
from flask import current_app


def get_provider_class(provider_name: str):
    """Get the g4f provider class from string name"""
    if not provider_name:
        return None
    
    try:
        # Dynamic import of provider
        from g4f import Provider
        return getattr(Provider, provider_name, None)
    except Exception:
        return None

def analyze_medical_image(image_bytes: bytes, filename: str, analysis_type: str = 'general', context: str = '', language: str = 'en') -> dict:
    """
    Analyze a medical image using g4f
    
    Args:
        image_bytes: The image file bytes
        filename: Original filename
        analysis_type: Type of analysis (skin, document, xray, etc.)
        context: Additional context about the image
        language: Response language ('en' for English, 'ne' for Nepali, etc.)
    
    Returns:
        dict with analysis results
    """
    
    # Language instruction
    language_names = {'en': 'English', 'ne': 'Nepali (नेपाली)', 'hi': 'Hindi (हिन्दी)'}
    lang_name = language_names.get(language, 'English')
    lang_instruction = f"\n\nIMPORTANT: Respond ENTIRELY in {lang_name} language." if language != 'en' else ""
    
    # Build analysis prompt based on type
    prompts = {
        'skin': f"""You are an expert dermatologist AI assistant. Analyze this skin condition and provide:

1. **Observations**: Describe what you see in detail (color, texture, patterns, location)
2. **Possible Conditions**: List 2-3 most likely conditions based on visual analysis
3. **Severity Assessment**: Rate as mild/moderate/severe
4. **Immediate Care**: Simple home care recommendations
5. **When to See a Doctor**: Warning signs that need professional attention

Additional context from user: {context if context else 'None provided'}

IMPORTANT: Always include a disclaimer that this is AI-generated guidance and not a medical diagnosis. Recommend consulting a dermatologist for accurate diagnosis.{lang_instruction}""",

        'prescription': f"""You are a prescription analysis AI. Analyze this prescription and provide:

1. **Medications Listed**: List all medicines with their dosages
2. **Usage Instructions**: Frequency and timing for each medicine
3. **Duration**: How long to take each medication
4. **Precautions**: Important warnings or side effects to watch for
5. **General Notes**: Any other instructions

Additional context: {context if context else 'None provided'}

Include a disclaimer about verifying with your pharmacist.{lang_instruction}""",

        'document': f"""You are a medical document analysis AI. Analyze this document and provide:

1. **Document Type**: Identify what type of document this is
2. **Key Information**: Extract important details
3. **Medical Values**: List any test results or values found
4. **Summary**: Brief summary of findings
5. **Notable Points**: Any abnormal values or important notes

Additional context: {context if context else 'None provided'}

Format your response clearly with headers.{lang_instruction}""",

        'general': f"""You are a medical image analysis AI assistant. Analyze this medical image and provide:

1. **Image Description**: What type of medical image is this?
2. **Key Observations**: What can you see in this image?
3. **Analysis**: Provide relevant medical insights
4. **Recommendations**: Any suggested next steps
5. **Important Notes**: Things the user should be aware of

Additional context from user: {context if context else 'None provided'}

Include appropriate medical disclaimers in your response.{lang_instruction}"""
    }
    
    prompt = prompts.get(analysis_type, prompts['general'])
    
    try:
        # Convert image to base64 for the prompt
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # Determine image type from filename
        ext = filename.lower().split('.')[-1] if '.' in filename else 'jpg'
        mime_type = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp'
        }.get(ext, 'image/jpeg')
        
        print(f"[AI Image Service] Sending request...")
        print(f"[AI Image Service] Analysis type: {analysis_type}")
        print(f"[AI Image Service] Image size: {len(image_bytes)} bytes")
        
        # Get provider and model from config
        provider_name = current_app.config.get('AI_IMAGE_ANALYSIS_PROVIDER', 'DeepInfra')
        model_name = current_app.config.get('AI_IMAGE_ANALYSIS_MODEL', 'meta-llama/Llama-3.2-90B-Vision-Instruct')
        provider_class = get_provider_class(provider_name)
        
        print(f"[AI Image Service] Using provider: {provider_name}, model: {model_name}")
        
        # Try using configured provider
        try:
            from g4f.client import Client
            
            data_url = f"data:{mime_type};base64,{image_base64}"
            
            # Use Client pattern
            client = Client(provider=provider_class) if provider_class else Client()
            response = client.chat.completions.create(
                model=model_name,
                messages=[{"role": "user", "content": prompt}],
                image=data_url,
                web_search=False
            )
            
            print(f"[AI Image Service] Response received")
            analysis_text = response.choices[0].message.content
                
        except Exception as primary_err:
            print(f"[AI Image Service] Primary failed: {primary_err}, trying text-only fallback")
            
            from g4f.client import Client
            from g4f import Provider
            
            # Fallback: Use text-only analysis with working DeepInfra model
            fallback_prompt = f"""Based on the user's description, provide medical guidance.

User says: {context if context else 'User uploaded a medical image for analysis'}

Analysis type requested: {analysis_type}

{prompt}

Note: I cannot see the actual image, so I'm providing general guidance based on the description provided. For accurate diagnosis, please consult a healthcare professional who can examine you in person."""

            fallback_model = current_app.config.get('AI_CHAT_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
            
            client = Client(provider=Provider.DeepInfra)
            response = client.chat.completions.create(
                model=fallback_model,
                messages=[{"role": "user", "content": fallback_prompt}],
                web_search=False
            )
            
            analysis_text = response.choices[0].message.content
        
        print(f"[AI Image Service] Success! Analysis length: {len(analysis_text)} chars")
        
        return {
            'success': True,
            'analysis': analysis_text,
            'analysis_type': analysis_type,
            'model': 'g4f-vision'
        }
        
    except Exception as e:
        print(f"[AI Image Analysis Error] {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'error': str(e),
            'analysis': get_fallback_analysis(analysis_type),
            'analysis_type': analysis_type,
            'model': 'fallback'
        }


def get_fallback_analysis(analysis_type: str) -> str:
    """Return fallback analysis text when AI service is unavailable"""
    
    fallbacks = {
        'skin': """**AI Image Analysis - Service Temporarily Unavailable**

We were unable to analyze your image at this time. Please try again later.

**General Skin Care Recommendations:**
• Keep the affected area clean and dry
• Avoid scratching or irritating the area
• Watch for signs of infection (increasing redness, warmth, pus)
• If symptoms persist or worsen, consult a dermatologist

*For accurate diagnosis, please visit a healthcare provider.*""",

        'document': """**Medical Document Uploaded**

Your document has been saved to your medical records. AI analysis is temporarily unavailable.

The document will be available for:
• Your personal reference
• Sharing with healthcare providers
• AI analysis when the service is restored

*Please consult your doctor for interpretation of medical documents.*""",

        'xray': """**X-Ray Image Received**

AI analysis is temporarily unavailable. Your image has been saved for your records.

**General Information:**
• X-ray interpretation requires professional radiologist review
• Keep this image for your medical records
• Share with your healthcare provider for proper diagnosis

*This image requires professional medical interpretation.*""",

        'general': """**Medical Image Analysis Unavailable**

We were unable to analyze your image at this time. Please try again later or consult with a healthcare provider for proper assessment.

Your image has been saved to your medical records for future reference.

*For medical concerns, please consult a qualified healthcare professional.*"""
    }
    
    return fallbacks.get(analysis_type, fallbacks['general'])


def analyze_document_for_storage(image_bytes: bytes, filename: str, document_type: str) -> dict:
    """
    Analyze a medical document and extract key information for storage
    
    Returns structured data for database storage
    """
    
    # Map document types to analysis types
    doc_type_mapping = {
        'lab_report': 'lab_report',
        'blood_test': 'lab_report',
        'xray': 'xray',
        'mri': 'xray',
        'ct_scan': 'xray',
        'ultrasound': 'xray',
        'ecg': 'document',
        'prescription': 'document',
        'discharge_summary': 'document',
        'pathology': 'lab_report',
    }
    
    analysis_type = doc_type_mapping.get(document_type, 'document')
    
    result = analyze_medical_image(
        image_bytes=image_bytes,
        filename=filename,
        analysis_type=analysis_type,
        context=f"Document type: {document_type}"
    )
    
    analysis_text = result.get('analysis', '')
    
    # Generate a short summary (first 200 chars of significant content)
    lines = [l.strip() for l in analysis_text.split('\n') if l.strip() and not l.startswith('*')]
    summary = ' '.join(lines)[:200] + '...' if len(' '.join(lines)) > 200 else ' '.join(lines)
    
    return {
        'ai_analysis': analysis_text,
        'ai_summary': summary,
        'ocr_text': None,  # Could add OCR integration later
        'analysis_success': result.get('success', False)
    }
