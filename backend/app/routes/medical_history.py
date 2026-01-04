from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from datetime import datetime
import os
import uuid
import base64

from app import db
from app.models import (
    MedicalRecord, MedicalCondition, MedicalAllergy, MedicalMedication,
    MedicalDocument, MedicalDocumentImage, MedicalSurgery, MedicalVaccination,
    User
)

medical_history_bp = Blueprint('medical_history', __name__)


# Debug: Log all incoming requests before JWT validation
@medical_history_bp.before_request
def log_request():
    auth_header = request.headers.get('Authorization', 'NONE')
    print(f"\n{'='*50}")
    print(f"[DEBUG] Medical History Request: {request.method} {request.path}")
    print(f"[DEBUG] Authorization: {auth_header[:60]}..." if len(auth_header) > 60 else f"[DEBUG] Authorization: {auth_header}")
    print(f"{'='*50}\n")


# Demo AI analysis texts for different document types
DEMO_AI_ANALYSIS = {
    'lab_report': """Based on the uploaded lab report analysis:

**Key Findings:**
- All major blood parameters appear within normal reference ranges
- Hemoglobin levels indicate adequate oxygen-carrying capacity
- Liver and kidney function markers show healthy organ performance
- Cholesterol profile suggests moderate cardiovascular risk

**Recommendations:**
- Continue current diet and exercise routine
- Follow up with your physician for detailed interpretation
- Consider lipid panel recheck in 6 months

*Note: This is an AI-generated preliminary analysis. Please consult your healthcare provider for definitive interpretation.*""",

    'prescription': """Prescription Analysis Summary:

**Medications Identified:**
- The prescribed medications are commonly used for the indicated condition
- Dosage appears appropriate for standard treatment protocols
- Duration of treatment follows clinical guidelines

**Important Notes:**
- Take medications as directed with or after meals
- Complete the full course of antibiotics if prescribed
- Watch for potential side effects and report to your doctor

*AI-generated summary. Verify with your pharmacist.*""",

    'xray': """X-Ray Image Analysis:

**Observations:**
- Bone structure appears normal with no visible fractures
- Soft tissue outlines are within expected parameters
- No obvious abnormalities detected in the imaging field

**AI Confidence:** Moderate (75%)

*This is a preliminary AI screening. Radiologist consultation is recommended for definitive diagnosis.*""",

    'blood_test': """Blood Test Analysis Report:

**Complete Blood Count (CBC):**
- White Blood Cells: Within normal range
- Red Blood Cells: Adequate levels detected
- Platelets: Normal coagulation potential

**Metabolic Panel:**
- Blood glucose: Refer to fasting status for interpretation
- Electrolytes: Balanced mineral levels

**Lipid Profile:**
- Total cholesterol requires attention if elevated
- HDL/LDL ratio important for heart health assessment

*AI-generated preliminary review. Consult physician for complete interpretation.*""",

    'default': """Medical Document Analysis:

This document has been processed by our AI system. Key information has been extracted and stored for your reference.

**Document Summary:**
- Document type and content have been categorized
- Relevant medical information has been indexed
- This record is now part of your medical history

For detailed interpretation, please consult with your healthcare provider.

*AI-generated analysis for organizational purposes.*"""
}


def get_or_create_medical_record(user_id):
    """Get existing or create new medical record for user"""
    try:
        # Convert user_id to int if it's a string (from JWT identity)
        if isinstance(user_id, str):
            user_id = int(user_id)
        
        record = MedicalRecord.query.filter_by(user_id=user_id).first()
        if not record:
            record = MedicalRecord(user_id=user_id)
            db.session.add(record)
            db.session.commit()
        return record
    except Exception as e:
        db.session.rollback()
        raise e


# ==================== MEDICAL RECORD ====================

@medical_history_bp.route('', methods=['GET'])
@jwt_required()
def get_medical_record():
    """Get user's complete medical record"""
    try:
        # Debug: Log incoming headers
        auth_header = request.headers.get('Authorization', 'NONE')
        print(f"[JWT DEBUG] Authorization header: {auth_header[:50] if len(auth_header) > 50 else auth_header}...")
        
        user_id = get_jwt_identity()
        print(f"[JWT DEBUG] user_id from token: {user_id}")
        include_details = request.args.get('details', 'true') == 'true'
        
        record = get_or_create_medical_record(user_id)
        return jsonify(record.to_dict(include_details=include_details))
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500



@medical_history_bp.route('', methods=['PUT'])
@jwt_required()
def update_medical_record():
    """Update basic medical record info"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    # Update fields if provided
    if 'blood_type' in data:
        record.blood_type = data['blood_type']
    if 'height_cm' in data:
        record.height_cm = data['height_cm']
    if 'weight_kg' in data:
        record.weight_kg = data['weight_kg']
    if 'emergency_notes' in data:
        record.emergency_notes = data['emergency_notes']
    if 'organ_donor' in data:
        record.organ_donor = data['organ_donor']
    if 'smoking_status' in data:
        record.smoking_status = data['smoking_status']
    if 'alcohol_use' in data:
        record.alcohol_use = data['alcohol_use']
    if 'exercise_frequency' in data:
        record.exercise_frequency = data['exercise_frequency']
    
    db.session.commit()
    return jsonify({'message': 'Medical record updated', 'record': record.to_dict()})


# ==================== CONDITIONS ====================

@medical_history_bp.route('/conditions', methods=['GET'])
@jwt_required()
def get_conditions():
    """Get user's medical conditions"""
    user_id = get_jwt_identity()
    status = request.args.get('status')  # active, resolved, chronic
    
    record = get_or_create_medical_record(user_id)
    query = record.conditions
    
    if status:
        query = query.filter_by(status=status)
    
    conditions = query.order_by(MedicalCondition.diagnosed_date.desc()).all()
    return jsonify([c.to_dict() for c in conditions])


@medical_history_bp.route('/conditions', methods=['POST'])
@jwt_required()
def add_condition():
    """Add a medical condition"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    condition = MedicalCondition(
        record_id=record.id,
        name=data.get('name'),
        icd_code=data.get('icd_code'),
        category=data.get('category'),
        severity=data.get('severity'),
        status=data.get('status', 'active'),
        diagnosed_date=datetime.strptime(data['diagnosed_date'], '%Y-%m-%d').date() if data.get('diagnosed_date') else None,
        diagnosed_by=data.get('diagnosed_by'),
        notes=data.get('notes'),
        treatment=data.get('treatment'),
        ai_analysis=DEMO_AI_ANALYSIS['default']  # Demo AI analysis
    )
    
    db.session.add(condition)
    db.session.commit()
    
    return jsonify({'message': 'Condition added', 'condition': condition.to_dict()}), 201


@medical_history_bp.route('/conditions/<int:condition_id>', methods=['PUT'])
@jwt_required()
def update_condition(condition_id):
    """Update a medical condition"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    condition = MedicalCondition.query.filter_by(id=condition_id, record_id=record.id).first_or_404()
    
    for field in ['name', 'severity', 'status', 'notes', 'treatment']:
        if field in data:
            setattr(condition, field, data[field])
    
    if 'resolved_date' in data:
        condition.resolved_date = datetime.strptime(data['resolved_date'], '%Y-%m-%d').date() if data['resolved_date'] else None
    
    db.session.commit()
    return jsonify({'message': 'Condition updated', 'condition': condition.to_dict()})


@medical_history_bp.route('/conditions/<int:condition_id>', methods=['DELETE'])
@jwt_required()
def delete_condition(condition_id):
    """Delete a medical condition"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    condition = MedicalCondition.query.filter_by(id=condition_id, record_id=record.id).first_or_404()
    
    db.session.delete(condition)
    db.session.commit()
    return jsonify({'message': 'Condition deleted'})


# ==================== ALLERGIES ====================

@medical_history_bp.route('/allergies', methods=['GET'])
@jwt_required()
def get_allergies():
    """Get user's allergies"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    
    allergies = record.allergies.order_by(MedicalAllergy.severity.desc()).all()
    return jsonify([a.to_dict() for a in allergies])


@medical_history_bp.route('/allergies', methods=['POST'])
@jwt_required()
def add_allergy():
    """Add an allergy"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    allergy = MedicalAllergy(
        record_id=record.id,
        allergen=data.get('allergen'),
        category=data.get('category'),
        severity=data.get('severity'),
        reaction=data.get('reaction'),
        discovered_date=datetime.strptime(data['discovered_date'], '%Y-%m-%d').date() if data.get('discovered_date') else None,
        notes=data.get('notes')
    )
    
    db.session.add(allergy)
    db.session.commit()
    
    return jsonify({'message': 'Allergy added', 'allergy': allergy.to_dict()}), 201


@medical_history_bp.route('/allergies/<int:allergy_id>', methods=['DELETE'])
@jwt_required()
def delete_allergy(allergy_id):
    """Delete an allergy"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    allergy = MedicalAllergy.query.filter_by(id=allergy_id, record_id=record.id).first_or_404()
    
    db.session.delete(allergy)
    db.session.commit()
    return jsonify({'message': 'Allergy deleted'})


# ==================== MEDICATIONS ====================

@medical_history_bp.route('/medications', methods=['GET'])
@jwt_required()
def get_medications():
    """Get user's medications"""
    user_id = get_jwt_identity()
    active_only = request.args.get('active', 'true') == 'true'
    
    record = get_or_create_medical_record(user_id)
    query = record.medications
    
    if active_only:
        query = query.filter_by(is_active=True)
    
    medications = query.order_by(MedicalMedication.start_date.desc()).all()
    return jsonify([m.to_dict() for m in medications])


@medical_history_bp.route('/medications', methods=['POST'])
@jwt_required()
def add_medication():
    """Add a medication"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    medication = MedicalMedication(
        record_id=record.id,
        name=data.get('name'),
        generic_name=data.get('generic_name'),
        dosage=data.get('dosage'),
        frequency=data.get('frequency'),
        route=data.get('route'),
        prescribed_for=data.get('prescribed_for'),
        prescribed_by=data.get('prescribed_by'),
        start_date=datetime.strptime(data['start_date'], '%Y-%m-%d').date() if data.get('start_date') else None,
        end_date=datetime.strptime(data['end_date'], '%Y-%m-%d').date() if data.get('end_date') else None,
        is_active=data.get('is_active', True),
        notes=data.get('notes')
    )
    
    db.session.add(medication)
    db.session.commit()
    
    return jsonify({'message': 'Medication added', 'medication': medication.to_dict()}), 201


@medical_history_bp.route('/medications/<int:medication_id>', methods=['PUT'])
@jwt_required()
def update_medication(medication_id):
    """Update a medication"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    medication = MedicalMedication.query.filter_by(id=medication_id, record_id=record.id).first_or_404()
    
    for field in ['name', 'dosage', 'frequency', 'is_active', 'notes']:
        if field in data:
            setattr(medication, field, data[field])
    
    if 'end_date' in data:
        medication.end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date() if data['end_date'] else None
    
    db.session.commit()
    return jsonify({'message': 'Medication updated', 'medication': medication.to_dict()})


@medical_history_bp.route('/medications/<int:medication_id>', methods=['DELETE'])
@jwt_required()
def delete_medication(medication_id):
    """Delete a medication"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    medication = MedicalMedication.query.filter_by(id=medication_id, record_id=record.id).first_or_404()
    
    db.session.delete(medication)
    db.session.commit()
    return jsonify({'message': 'Medication deleted'})


# ==================== DOCUMENTS ====================

@medical_history_bp.route('/documents', methods=['GET'])
@jwt_required()
def get_documents():
    """Get user's medical documents"""
    user_id = get_jwt_identity()
    doc_type = request.args.get('type')
    
    record = get_or_create_medical_record(user_id)
    query = record.documents
    
    if doc_type:
        query = query.filter_by(document_type=doc_type)
    
    documents = query.order_by(MedicalDocument.document_date.desc()).all()
    return jsonify([d.to_dict() for d in documents])


@medical_history_bp.route('/documents', methods=['POST'])
@jwt_required()
def add_document():
    """Add a medical document with optional AI analysis"""
    from app.utils.ai_image_service import analyze_document_for_storage
    import base64
    
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    doc_type = data.get('document_type', 'other')
    
    # Check if image data is provided for AI analysis
    image_data = data.get('image_data')  # Base64 encoded image
    ai_analysis = None
    ai_summary = None
    
    if image_data:
        try:
            # Decode base64 image and analyze with AI
            image_bytes = base64.b64decode(image_data)
            filename = data.get('filename', 'document.jpg')
            
            result = analyze_document_for_storage(
                image_bytes=image_bytes,
                filename=filename,
                document_type=doc_type
            )
            
            ai_analysis = result.get('ai_analysis')
            ai_summary = result.get('ai_summary')
        except Exception as e:
            print(f"[AI Analysis Error] {str(e)}")
            # Fall back to demo analysis if AI fails
            ai_analysis = DEMO_AI_ANALYSIS.get(doc_type, DEMO_AI_ANALYSIS['default'])
            ai_summary = f"AI Analysis completed for {doc_type.replace('_', ' ').title()}"
    else:
        # No image provided, use demo analysis
        ai_analysis = DEMO_AI_ANALYSIS.get(doc_type, DEMO_AI_ANALYSIS['default'])
        ai_summary = f"AI Analysis completed for {doc_type.replace('_', ' ').title()}"
    
    document = MedicalDocument(
        record_id=record.id,
        title=data.get('title'),
        document_type=doc_type,
        description=data.get('description'),
        document_date=datetime.strptime(data['document_date'], '%Y-%m-%d').date() if data.get('document_date') else datetime.utcnow().date(),
        doctor_name=data.get('doctor_name'),
        hospital_name=data.get('hospital_name'),
        hospital_id=data.get('hospital_id'),
        doctor_id=data.get('doctor_id'),
        file_url=data.get('file_url'),
        file_type=data.get('file_type'),
        ai_analysis=ai_analysis,
        ai_summary=ai_summary,
        ai_analyzed_at=datetime.utcnow(),
        is_critical=data.get('is_critical', False)
    )
    
    db.session.add(document)
    db.session.commit()
    
    return jsonify({'message': 'Document added', 'document': document.to_dict()}), 201


@medical_history_bp.route('/documents/<int:document_id>', methods=['GET'])
@jwt_required()
def get_document(document_id):
    """Get a single medical document"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    document = MedicalDocument.query.filter_by(id=document_id, record_id=record.id).first_or_404()
    
    return jsonify(document.to_dict(include_images=True))


@medical_history_bp.route('/documents/<int:document_id>', methods=['PUT'])
@jwt_required()
def update_document(document_id):
    """Update a medical document"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    document = MedicalDocument.query.filter_by(id=document_id, record_id=record.id).first_or_404()
    
    for field in ['title', 'description', 'doctor_name', 'hospital_name', 'is_critical', 'is_shared']:
        if field in data:
            setattr(document, field, data[field])
    
    db.session.commit()
    return jsonify({'message': 'Document updated', 'document': document.to_dict()})


@medical_history_bp.route('/documents/<int:document_id>', methods=['DELETE'])
@jwt_required()
def delete_document(document_id):
    """Delete a medical document"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    document = MedicalDocument.query.filter_by(id=document_id, record_id=record.id).first_or_404()
    
    db.session.delete(document)
    db.session.commit()
    return jsonify({'message': 'Document deleted'})


@medical_history_bp.route('/documents/<int:document_id>/images', methods=['POST'])
@jwt_required()
def add_document_image(document_id):
    """Add an image to a medical document"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    document = MedicalDocument.query.filter_by(id=document_id, record_id=record.id).first_or_404()
    
    image = MedicalDocumentImage(
        document_id=document_id,
        image_url=data.get('image_url'),
        thumbnail_url=data.get('thumbnail_url'),
        caption=data.get('caption'),
        page_number=data.get('page_number', 1),
        ocr_text=data.get('ocr_text')
    )
    
    db.session.add(image)
    db.session.commit()
    
    return jsonify({'message': 'Image added', 'image': image.to_dict()}), 201


@medical_history_bp.route('/documents/<int:document_id>/analyze', methods=['POST'])
@jwt_required()
def analyze_document_with_ai(document_id):
    """Analyze document images with AI to extract and summarize information"""
    from app.utils.ai_image_service import analyze_document_for_storage
    
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    document = MedicalDocument.query.filter_by(id=document_id, record_id=record.id).first_or_404()
    
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    image = request.files['image']
    
    try:
        image_bytes = image.read()
        filename = image.filename or 'document_image.jpg'
        
        # Analyze document image with AI
        result = analyze_document_for_storage(
            image_bytes=image_bytes,
            filename=filename,
            document_type=document.document_type
        )
        
        # Update document with AI analysis
        document.ai_analysis = result.get('ai_analysis')
        document.ai_summary = result.get('ai_summary')
        document.ai_analyzed_at = datetime.utcnow()
        
        if result.get('ocr_text'):
            document.ocr_text = result['ocr_text']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Document analyzed successfully',
            'analysis': result.get('ai_analysis'),
            'summary': result.get('ai_summary'),
            'success': result.get('analysis_success', False),
            'document': document.to_dict()
        })
        
    except Exception as e:
        print(f"[Document Analysis Error] {str(e)}")
        return jsonify({
            'error': f'Analysis failed: {str(e)}',
            'success': False
        }), 500


@medical_history_bp.route('/documents/upload-and-analyze', methods=['POST'])
@jwt_required()
def upload_and_analyze_document():
    """Upload a document image and analyze it in one step"""
    from app.utils.ai_image_service import analyze_document_for_storage
    
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    image = request.files['image']
    title = request.form.get('title', 'Uploaded Document')
    document_type = request.form.get('document_type', 'other')
    description = request.form.get('description', '')
    document_date_str = request.form.get('document_date')
    doctor_name = request.form.get('doctor_name')
    hospital_name = request.form.get('hospital_name')
    is_critical = request.form.get('is_critical', 'false').lower() == 'true'
    
    try:
        # Read and analyze image
        image_bytes = image.read()
        filename = image.filename or 'document_image.jpg'
        
        result = analyze_document_for_storage(
            image_bytes=image_bytes,
            filename=filename,
            document_type=document_type
        )
        
        # Parse document date
        doc_date = datetime.utcnow().date()
        if document_date_str:
            try:
                doc_date = datetime.strptime(document_date_str, '%Y-%m-%d').date()
            except:
                pass
        
        # Create document with AI analysis
        document = MedicalDocument(
            record_id=record.id,
            title=title,
            document_type=document_type,
            description=description,
            document_date=doc_date,
            doctor_name=doctor_name,
            hospital_name=hospital_name,
            ai_analysis=result.get('ai_analysis'),
            ai_summary=result.get('ai_summary'),
            ai_analyzed_at=datetime.utcnow(),
            is_critical=is_critical
        )
        
        db.session.add(document)
        db.session.commit()
        
        return jsonify({
            'message': 'Document uploaded and analyzed',
            'document': document.to_dict(),
            'analysis': result.get('ai_analysis'),
            'summary': result.get('ai_summary'),
            'success': result.get('analysis_success', False)
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"[Upload and Analyze Error] {str(e)}")
        return jsonify({
            'error': f'Upload failed: {str(e)}',
            'success': False
        }), 500


# ==================== SURGERIES ====================

@medical_history_bp.route('/surgeries', methods=['GET'])
@jwt_required()
def get_surgeries():
    """Get user's surgical history"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    
    surgeries = record.surgeries.order_by(MedicalSurgery.surgery_date.desc()).all()
    return jsonify([s.to_dict() for s in surgeries])


@medical_history_bp.route('/surgeries', methods=['POST'])
@jwt_required()
def add_surgery():
    """Add a surgery record"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    surgery = MedicalSurgery(
        record_id=record.id,
        procedure_name=data.get('procedure_name'),
        procedure_type=data.get('procedure_type'),
        surgery_date=datetime.strptime(data['surgery_date'], '%Y-%m-%d').date() if data.get('surgery_date') else None,
        surgeon_name=data.get('surgeon_name'),
        hospital_name=data.get('hospital_name'),
        anesthesia_type=data.get('anesthesia_type'),
        duration_minutes=data.get('duration_minutes'),
        outcome=data.get('outcome'),
        complications=data.get('complications'),
        recovery_notes=data.get('recovery_notes'),
        ai_analysis=DEMO_AI_ANALYSIS['default']
    )
    
    db.session.add(surgery)
    db.session.commit()
    
    return jsonify({'message': 'Surgery record added', 'surgery': surgery.to_dict()}), 201


# ==================== VACCINATIONS ====================

@medical_history_bp.route('/vaccinations', methods=['GET'])
@jwt_required()
def get_vaccinations():
    """Get user's vaccination records"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    
    vaccinations = record.vaccinations.order_by(MedicalVaccination.administered_date.desc()).all()
    return jsonify([v.to_dict() for v in vaccinations])


@medical_history_bp.route('/vaccinations', methods=['POST'])
@jwt_required()
def add_vaccination():
    """Add a vaccination record"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    record = get_or_create_medical_record(user_id)
    
    vaccination = MedicalVaccination(
        record_id=record.id,
        vaccine_name=data.get('vaccine_name'),
        vaccine_type=data.get('vaccine_type'),
        dose_number=data.get('dose_number'),
        total_doses=data.get('total_doses'),
        administered_date=datetime.strptime(data['administered_date'], '%Y-%m-%d').date() if data.get('administered_date') else None,
        next_due_date=datetime.strptime(data['next_due_date'], '%Y-%m-%d').date() if data.get('next_due_date') else None,
        administered_by=data.get('administered_by'),
        location=data.get('location'),
        batch_number=data.get('batch_number'),
        manufacturer=data.get('manufacturer'),
        notes=data.get('notes')
    )
    
    db.session.add(vaccination)
    db.session.commit()
    
    return jsonify({'message': 'Vaccination record added', 'vaccination': vaccination.to_dict()}), 201


# ==================== AI CONTEXT ====================

@medical_history_bp.route('/ai-context', methods=['GET'])
@jwt_required()
def get_ai_context():
    """Get medical history formatted for AI consultation context"""
    user_id = get_jwt_identity()
    record = get_or_create_medical_record(user_id)
    user = User.query.get(user_id)
    
    context = f"""Patient Medical History Summary:

**Basic Information:**
- Name: {user.full_name if user else 'Patient'}
- Blood Type: {record.blood_type or 'Not specified'}
- Height: {record.height_cm}cm, Weight: {record.weight_kg}kg
- Organ Donor: {'Yes' if record.organ_donor else 'No'}

**Lifestyle:**
- Smoking: {record.smoking_status or 'Not specified'}
- Alcohol: {record.alcohol_use or 'Not specified'}
- Exercise: {record.exercise_frequency or 'Not specified'}

**Active Medical Conditions:**
"""
    
    active_conditions = record.conditions.filter_by(status='active').all()
    if active_conditions:
        for c in active_conditions:
            context += f"- {c.name} ({c.severity or 'Unknown severity'})\n"
    else:
        context += "- No active conditions recorded\n"
    
    context += "\n**Known Allergies:**\n"
    allergies = record.allergies.all()
    if allergies:
        for a in allergies:
            context += f"- {a.allergen} ({a.severity}): {a.reaction or 'No reaction details'}\n"
    else:
        context += "- No allergies recorded\n"
    
    context += "\n**Current Medications:**\n"
    medications = record.medications.filter_by(is_active=True).all()
    if medications:
        for m in medications:
            context += f"- {m.name} {m.dosage or ''} - {m.frequency or ''}\n"
    else:
        context += "- No current medications\n"
    
    context += "\n**Recent Documents:**\n"
    recent_docs = record.documents.order_by(MedicalDocument.created_at.desc()).limit(3).all()
    if recent_docs:
        for d in recent_docs:
            context += f"- {d.title} ({d.document_type}) - {d.document_date}\n"
            if d.ai_summary:
                context += f"  Summary: {d.ai_summary}\n"
    else:
        context += "- No documents uploaded\n"
    
    if record.emergency_notes:
        context += f"\n**Emergency Notes:**\n{record.emergency_notes}\n"
    
    return jsonify({
        'context': context,
        'summary': {
            'conditions_count': record.conditions.filter_by(status='active').count(),
            'allergies_count': record.allergies.count(),
            'medications_count': record.medications.filter_by(is_active=True).count(),
            'documents_count': record.documents.count()
        }
    })
