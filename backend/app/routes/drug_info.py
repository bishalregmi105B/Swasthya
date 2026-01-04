"""
Drug Information API Routes
Provides endpoints for drug/medication encyclopedia (separate from e-commerce medicines)
"""
from flask import Blueprint, jsonify, request
from app.data_scripts.medicine_data import (
    search_medicines,
    get_medicine_details,
    get_medicine_categories,
    get_drug_interactions,
    get_adverse_events,
    get_common_medicines
)

drug_info_bp = Blueprint('drug_info', __name__, url_prefix='/api/drug-info')


@drug_info_bp.route('/search', methods=['GET'])
def search():
    """Search for drugs by name"""
    query = request.args.get('q', '')
    limit = request.args.get('limit', 20, type=int)
    
    if not query or len(query) < 2:
        return jsonify({'error': 'Query must be at least 2 characters'}), 400
    
    results = search_medicines(query, limit=min(limit, 50))
    
    return jsonify({
        'query': query,
        'count': len(results),
        'results': results
    })


@drug_info_bp.route('/details/<drug_name>', methods=['GET'])
def details(drug_name: str):
    """Get detailed information about a specific drug"""
    language = request.args.get('lang', 'en')
    
    result = get_medicine_details(drug_name, language=language)
    
    if result:
        return jsonify(result)
    else:
        return jsonify({'error': 'Drug not found'}), 404


@drug_info_bp.route('/categories', methods=['GET'])
def categories():
    """Get list of drug categories for browsing"""
    return jsonify({
        'categories': get_medicine_categories()
    })


@drug_info_bp.route('/interactions/<rxcui>', methods=['GET'])
def interactions(rxcui: str):
    """Get drug interactions for a given RXCUI"""
    results = get_drug_interactions(rxcui)
    
    return jsonify({
        'rxcui': rxcui,
        'count': len(results),
        'interactions': results
    })


@drug_info_bp.route('/adverse-events/<drug_name>', methods=['GET'])
def adverse_events(drug_name: str):
    """Get reported adverse events for a drug"""
    limit = request.args.get('limit', 10, type=int)
    
    results = get_adverse_events(drug_name, limit=min(limit, 50))
    
    return jsonify({
        'drug': drug_name,
        'count': len(results),
        'events': results
    })


@drug_info_bp.route('/common', methods=['GET'])
def common():
    """Get list of common drugs"""
    return jsonify({
        'medicines': get_common_medicines()
    })
