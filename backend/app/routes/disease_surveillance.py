"""
Disease Surveillance Routes
API endpoints for disease spread levels and surveillance data
"""

from flask import Blueprint, jsonify
from datetime import datetime
from app.data_scripts.disease_data import get_covid_data

disease_surveillance_bp = Blueprint('disease_surveillance', __name__)


# City to country mapping for COVID API
CITY_TO_COUNTRY = {
    'kathmandu': 'nepal', 'pokhara': 'nepal', 'lalitpur': 'nepal',
    'bhaktapur': 'nepal', 'biratnagar': 'nepal', 'birgunj': 'nepal',
    'bharatpur': 'nepal', 'hetauda': 'nepal', 'dharan': 'nepal',
    'butwal': 'nepal', 'nepalgunj': 'nepal', 'janakpur': 'nepal',
    'dhangadhi': 'nepal', 'bagmati': 'nepal', 'gandaki': 'nepal',
    'lumbini': 'nepal', 'karnali': 'nepal', 'sudurpashchim': 'nepal',
    'madhesh': 'nepal', 'koshi': 'nepal',
}


def _get_country_from_location(location: str) -> str:
    """Map city/province names to country names for COVID API"""
    return CITY_TO_COUNTRY.get(location.lower(), location)


@disease_surveillance_bp.route('/spread/<country>', methods=['GET'])
def get_spread_level(country):
    """
    Get disease spread level for a country based on COVID data
    Returns spread level (low/moderate/high/critical) and trend
    """
    country_name = _get_country_from_location(country)
    covid_data = get_covid_data(country_name)
    
    if not covid_data:
        # Return demo/fallback data
        return jsonify({
            'country': country,
            'spread_level': 'low',
            'active_per_100k': 0.5,
            'new_cases_7day': 50,
            'trend': 'stable',
            'risk_level': 'minimal',
            'last_updated': datetime.utcnow().isoformat()
        })
    
    stats = covid_data.get('statistics', {})
    
    # Calculate active cases per 100k population directly
    active_cases = stats.get('active_cases', 0) or 0
    population = stats.get('population', 0) or 1  # Avoid division by zero
    
    # Calculate per 100k
    active_per_100k = (active_cases / population) * 100000
    
    # Determine spread level
    if active_per_100k < 1:
        spread_level = 'minimal'
        risk_level = 'low'
    elif active_per_100k < 10:
        spread_level = 'low'
        risk_level = 'low'
    elif active_per_100k < 50:
        spread_level = 'moderate'
        risk_level = 'medium'
    elif active_per_100k < 200:
        spread_level = 'high'
        risk_level = 'high'
    else:
        spread_level = 'critical'
        risk_level = 'critical'
    
    # Determine trend based on today's cases (simplified)
    today_cases = stats.get('today_cases', 0) or 0
    if today_cases > 100:
        trend = 'increasing'
    elif today_cases > 0:
        trend = 'stable'
    else:
        trend = 'decreasing'
    
    return jsonify({
        'country': country,
        'country_resolved': country_name,
        'spread_level': spread_level,
        'active_per_100k': round(active_per_100k, 2),
        'active_cases': stats.get('active_cases', 0),
        'today_cases': today_cases,
        'trend': trend,
        'risk_level': risk_level,
        'population': stats.get('population', 0),
        'last_updated': datetime.utcnow().isoformat()
    })


@disease_surveillance_bp.route('/outbreaks', methods=['GET'])
def get_outbreaks():
    """Get disease outbreaks from WHO and other sources"""
    from app.data_scripts.disease_data import get_disease_outbreaks
    outbreaks = get_disease_outbreaks()
    return jsonify({
        'outbreaks': outbreaks,
        'realtime_from_who': outbreaks,
        'count': len(outbreaks),
        'fetched_at': datetime.utcnow().isoformat()
    })


@disease_surveillance_bp.route('/regional-alerts/<region>', methods=['GET'])
def get_regional_alerts(region):
    """Get regional health alerts"""
    # Return demo data for now
    return jsonify({
        'region': region,
        'alerts': [
            {
                'type': 'respiratory',
                'title': 'Seasonal Flu Advisory',
                'severity': 'moderate',
                'message': 'Increased flu activity in the region. Consider vaccination.',
                'date': datetime.utcnow().isoformat()
            }
        ],
        'fetched_at': datetime.utcnow().isoformat()
    })


@disease_surveillance_bp.route('/covid/<country>', methods=['GET'])
def get_covid(country):
    """Get COVID data for a country"""
    country_name = _get_country_from_location(country)
    covid_data = get_covid_data(country_name)
    if not covid_data:
        # Return fallback demo data when external API is unavailable
        return jsonify({
            'country': country_name.title(),
            'statistics': {
                'total_cases': 1000000,
                'active_cases': 100,
                'recovered': 990000,
                'deaths': 12000,
                'today_cases': 5,
                'today_deaths': 0,
                'cases_per_million': 33000,
                'deaths_per_million': 400,
                'active_per_million': 3,
                'population': 30000000,
            },
            'flag': f'https://disease.sh/assets/img/flags/{country_name[:2].lower()}.png',
            'is_demo_data': True,
            'message': 'Using demo data - external API temporarily unavailable',
            'fetched_at': datetime.utcnow().isoformat()
        })
    return jsonify(covid_data)


@disease_surveillance_bp.route('/situation/<country>', methods=['GET'])
def get_situation(country):
    """Get disease situation report for a country"""
    country_name = _get_country_from_location(country)
    covid_data = get_covid_data(country_name)
    
    stats = covid_data.get('statistics', {}) if covid_data else {}
    
    return jsonify({
        'country': country,
        'country_resolved': country_name,
        'situation': {
            'covid': {
                'active': stats.get('active_cases', 0),
                'recovered': stats.get('recovered', 0),
                'deaths': stats.get('deaths', 0),
                'today_cases': stats.get('today_cases', 0),
            },
            'general_health_status': 'stable',
            'healthcare_capacity': 'adequate',
        },
        'last_updated': datetime.utcnow().isoformat()
    })


@disease_surveillance_bp.route('/history/<country>', methods=['GET'])
def get_history(country):
    """Get disease history for a country"""
    from flask import request
    from app.data_scripts.disease_data import get_covid_historical
    
    country_name = _get_country_from_location(country)
    days = request.args.get('days', 30, type=int)
    
    historical = get_covid_historical(country_name, days)
    if not historical:
        return jsonify({
            'country': country,
            'days': days,
            'timeline': {},
            'message': 'Historical data not available'
        })
    return jsonify(historical)


@disease_surveillance_bp.route('/active-alerts/<country>', methods=['GET'])
def get_active_alerts(country):
    """
    Get active disease alerts for a country based on season and regional risks
    Returns diseases currently affecting the region
    """
    from app.data_scripts.disease_data import get_country_disease_risk
    
    country_name = _get_country_from_location(country)
    
    # Get current month for seasonal diseases
    current_month = datetime.now().month
    
    # South Asian monsoon season (June-September) - dengue, malaria peak
    is_monsoon = 6 <= current_month <= 9
    # Winter (Nov-Feb) - flu, respiratory infections
    is_winter = current_month in [11, 12, 1, 2]
    # Pre-monsoon (March-May) - typhoid, waterborne diseases rise
    is_pre_monsoon = 3 <= current_month <= 5
    
    # Get risk profile
    risk_data = get_country_disease_risk(country_name)
    disease_risks = risk_data.get('disease_risks', {})
    
    active_alerts = []
    
    # Generate seasonal alerts
    for disease, risk in disease_risks.items():
        alert = None
        
        if disease == 'dengue' and is_monsoon and risk in ['high', 'moderate']:
            alert = {
                'disease': 'Dengue Fever',
                'status': 'active',
                'severity': 'high' if risk == 'high' else 'moderate',
                'icon': '🦟',
                'message': 'Monsoon season dengue outbreak risk',
                'prevention': ['Use repellent', 'Remove standing water', 'Wear long sleeves']
            }
        elif disease == 'malaria' and is_monsoon and risk in ['high', 'moderate']:
            alert = {
                'disease': 'Malaria',
                'status': 'active',
                'severity': risk,
                'icon': '🦟',
                'message': 'Peak malaria transmission season',
                'prevention': ['Use bed nets', 'Take prophylaxis if traveling', 'Use repellent']
            }
        elif disease == 'typhoid' and is_pre_monsoon and risk in ['high', 'moderate']:
            alert = {
                'disease': 'Typhoid',
                'status': 'caution',
                'severity': 'moderate',
                'icon': '💧',
                'message': 'Waterborne disease risk elevated',
                'prevention': ['Drink safe water', 'Eat cooked food', 'Wash hands']
            }
        elif disease == 'seasonal_flu' and is_winter:
            alert = {
                'disease': 'Influenza',
                'status': 'active',
                'severity': 'moderate',
                'icon': '🤧',
                'message': 'Winter flu season in progress',
                'prevention': ['Get flu shot', 'Cover coughs', 'Wash hands frequently']
            }
        elif disease == 'cholera' and risk in ['high', 'moderate']:
            alert = {
                'disease': 'Cholera',
                'status': 'caution',
                'severity': risk,
                'icon': '💧',
                'message': 'Cholera risk in affected areas',
                'prevention': ['Drink purified water', 'Good sanitation', 'Oral vaccine']
            }
        
        if alert:
            active_alerts.append(alert)
    
    # Add COVID as low-level alert if any activity
    covid_data = get_covid_data(country_name)
    if covid_data:
        active_cases = covid_data.get('statistics', {}).get('active_cases', 0) or 0
        if active_cases > 0:
            active_alerts.append({
                'disease': 'COVID-19',
                'status': 'monitoring',
                'severity': 'low',
                'icon': '😷',
                'message': f'{active_cases} active cases',
                'prevention': ['Vaccinate', 'Mask if symptomatic', 'Hand hygiene']
            })
    
    return jsonify({
        'country': country_name,
        'active_alerts': active_alerts,
        'season': 'monsoon' if is_monsoon else 'winter' if is_winter else 'dry',
        'total_alerts': len(active_alerts),
        'fetched_at': datetime.utcnow().isoformat()
    })
