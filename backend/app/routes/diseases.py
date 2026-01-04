"""
Diseases Encyclopedia API Routes
Provides endpoints for searching and browsing disease information
"""
from flask import Blueprint, jsonify, request
from app.data_scripts.disease_encyclopedia import (
    search_diseases,
    get_disease_details,
    get_disease_categories,
    get_diseases_by_category,
    get_common_diseases
)

diseases_bp = Blueprint('diseases', __name__, url_prefix='/api/diseases')


@diseases_bp.route('/search', methods=['GET'])
def search():
    """Search for diseases by name or keyword"""
    query = request.args.get('q', '')
    limit = request.args.get('limit', 20, type=int)
    
    if not query or len(query) < 2:
        return jsonify({'error': 'Query must be at least 2 characters'}), 400
    
    results = search_diseases(query, max_results=min(limit, 50))
    
    return jsonify({
        'query': query,
        'count': len(results),
        'results': results
    })


@diseases_bp.route('/details/<disease_name>', methods=['GET'])
def details(disease_name: str):
    """Get detailed information about a specific disease"""
    language = request.args.get('lang', 'en')
    
    result = get_disease_details(disease_name, language=language)
    
    if result:
        return jsonify(result)
    else:
        return jsonify({'error': 'Disease not found'}), 404


@diseases_bp.route('/categories', methods=['GET'])
def categories():
    """Get list of disease categories for browsing"""
    return jsonify({
        'categories': get_disease_categories()
    })


@diseases_bp.route('/category/<category_id>', methods=['GET'])
def by_category(category_id: str):
    """Get diseases in a specific category"""
    limit = request.args.get('limit', 15, type=int)
    
    results = get_diseases_by_category(category_id, limit=min(limit, 30))
    
    return jsonify({
        'category': category_id,
        'count': len(results),
        'results': results
    })


@diseases_bp.route('/common', methods=['GET'])
def common():
    """Get list of common diseases"""
    return jsonify({
        'diseases': get_common_diseases()
    })
