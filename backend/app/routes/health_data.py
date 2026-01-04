"""
Health Data Routes
API endpoints for weather, disease, earthquake, and climate data
"""

from flask import Blueprint, request, jsonify
from datetime import datetime

# Import data fetching scripts
from app.data_scripts.weather_data import (
    get_weather_data, 
    get_all_countries_weather,
    COUNTRY_COORDINATES as WEATHER_COUNTRIES
)
from app.data_scripts.disease_data import (
    get_covid_data,
    get_global_covid_data,
    get_disease_outbreaks,
    get_country_disease_risk,
    get_all_countries_disease_data
)
from app.data_scripts.earthquake_data import (
    get_earthquakes,
    get_country_earthquake_summary,
    get_significant_earthquakes,
    get_all_countries_earthquakes,
    COUNTRY_BOUNDS as EARTHQUAKE_COUNTRIES
)
from app.data_scripts.climate_data import (
    get_air_quality_data,
    get_all_countries_air_quality,
    COUNTRY_COORDINATES as CLIMATE_COUNTRIES
)

health_data_bp = Blueprint('health_data', __name__)


# ==================== WEATHER ENDPOINTS ====================

@health_data_bp.route('/weather/<country>', methods=['GET'])
def get_country_weather(country):
    """Get weather data for a specific country"""
    data = get_weather_data(country)
    if not data:
        return jsonify({'error': f'Weather data not available for {country}'}), 404
    return jsonify(data)


@health_data_bp.route('/weather', methods=['GET'])
def get_weather_all():
    """Get weather data for all supported countries"""
    countries = request.args.get('countries')
    if countries:
        country_list = [c.strip() for c in countries.split(',')]
        results = [get_weather_data(c) for c in country_list]
        results = [r for r in results if r]
    else:
        results = get_all_countries_weather()
    return jsonify({'data': results, 'count': len(results)})


# ==================== DISEASE ENDPOINTS ====================

@health_data_bp.route('/disease/covid/<country>', methods=['GET'])
def get_country_covid(country):
    """Get COVID-19 data for a specific country"""
    data = get_covid_data(country)
    if not data:
        return jsonify({'error': f'COVID data not available for {country}'}), 404
    return jsonify(data)


@health_data_bp.route('/disease/covid/global', methods=['GET'])
def get_covid_global():
    """Get global COVID-19 statistics"""
    data = get_global_covid_data()
    if not data:
        return jsonify({'error': 'Unable to fetch global COVID data'}), 500
    return jsonify(data)


@health_data_bp.route('/disease/outbreaks', methods=['GET'])
def get_outbreaks():
    """Get current disease outbreaks and alerts"""
    outbreaks = get_disease_outbreaks()
    return jsonify({
        'outbreaks': outbreaks,
        'count': len(outbreaks),
        'fetched_at': datetime.utcnow().isoformat()
    })


@health_data_bp.route('/disease/risk/<country>', methods=['GET'])
def get_disease_risk(country):
    """Get disease risk assessment for a country"""
    data = get_country_disease_risk(country)
    return jsonify(data)


@health_data_bp.route('/disease', methods=['GET'])
def get_disease_all():
    """Get disease data for multiple countries"""
    countries = request.args.get('countries', 'nepal,india,bangladesh').split(',')
    countries = [c.strip() for c in countries]
    results = get_all_countries_disease_data(countries)
    return jsonify({'data': results, 'count': len(results)})


@health_data_bp.route('/disease/covid/comparison/<country>', methods=['GET'])
def get_covid_comparison(country):
    """Get COVID data for a country with neighboring countries comparison"""
    from app.data_scripts.disease_data import get_covid_with_neighbors
    data = get_covid_with_neighbors(country)
    if not data or not data.get('main_country'):
        return jsonify({'error': f'COVID data not available for {country}'}), 404
    return jsonify(data)


@health_data_bp.route('/disease/covid/historical/<country>', methods=['GET'])
def get_covid_historical(country):
    """Get historical COVID-19 trends for a country"""
    from app.data_scripts.disease_data import get_covid_historical as fetch_historical
    days = request.args.get('days', 30, type=int)
    data = fetch_historical(country, days)
    if not data:
        return jsonify({'error': f'Historical data not available for {country}'}), 404
    return jsonify(data)


@health_data_bp.route('/disease/vaccination/<country>', methods=['GET'])
def get_vaccination(country):
    """Get vaccination coverage data for a country"""
    from app.data_scripts.disease_data import get_vaccination_data
    days = request.args.get('days', 30, type=int)
    data = get_vaccination_data(country, days)
    if not data:
        return jsonify({'error': f'Vaccination data not available for {country}'}), 404
    return jsonify(data)


@health_data_bp.route('/climate/pollen/<country>', methods=['GET'])
def get_pollen(country):
    """Get pollen and allergy data for a country"""
    from app.data_scripts.climate_data import get_pollen_data
    data = get_pollen_data(country)
    if not data:
        return jsonify({'error': f'Pollen data not available for {country}'}), 404
    return jsonify(data)


# ==================== EARTHQUAKE ENDPOINTS ====================

@health_data_bp.route('/earthquake/<country>', methods=['GET'])
def get_country_earthquakes(country):
    """Get earthquake summary for a specific country"""
    days = request.args.get('days', 30, type=int)
    data = get_country_earthquake_summary(country, days)
    return jsonify(data)


@health_data_bp.route('/earthquake/recent', methods=['GET'])
def get_recent_earthquakes():
    """Get recent significant earthquakes worldwide"""
    min_magnitude = request.args.get('min_magnitude', 5.0, type=float)
    days = request.args.get('days', 7, type=int)
    earthquakes = get_significant_earthquakes(min_magnitude, days)
    return jsonify({
        'earthquakes': earthquakes,
        'count': len(earthquakes),
        'filters': {'min_magnitude': min_magnitude, 'days': days},
        'fetched_at': datetime.utcnow().isoformat()
    })


@health_data_bp.route('/earthquake', methods=['GET'])
def get_earthquake_all():
    """Get earthquake data for all supported countries"""
    days = request.args.get('days', 7, type=int)
    countries = request.args.get('countries')
    if countries:
        country_list = [c.strip() for c in countries.split(',')]
        results = get_all_countries_earthquakes(country_list, days)
    else:
        results = get_all_countries_earthquakes(days=days)
    return jsonify({'data': results, 'count': len(results)})


# ==================== CLIMATE/AIR QUALITY ENDPOINTS ====================

@health_data_bp.route('/climate/<country>', methods=['GET'])
def get_country_climate(country):
    """Get air quality/climate data for a specific country"""
    data = get_air_quality_data(country)
    if not data:
        return jsonify({'error': f'Climate data not available for {country}'}), 404
    return jsonify(data)


@health_data_bp.route('/climate', methods=['GET'])
def get_climate_all():
    """Get air quality data for all supported countries"""
    countries = request.args.get('countries')
    if countries:
        country_list = [c.strip() for c in countries.split(',')]
        results = [get_air_quality_data(c) for c in country_list]
        results = [r for r in results if r]
    else:
        results = get_all_countries_air_quality()
    return jsonify({'data': results, 'count': len(results)})


# ==================== COMBINED ENDPOINT ====================

@health_data_bp.route('/combined/<country>', methods=['GET'])
def get_combined_data(country):
    """Get all health-related data for a specific country"""
    # Map cities/provinces to countries for COVID API (which only supports country names)
    city_to_country = {
        'kathmandu': 'nepal', 'pokhara': 'nepal', 'lalitpur': 'nepal',
        'bhaktapur': 'nepal', 'biratnagar': 'nepal', 'birgunj': 'nepal',
        'bharatpur': 'nepal', 'hetauda': 'nepal', 'dharan': 'nepal',
        'butwal': 'nepal', 'nepalgunj': 'nepal', 'janakpur': 'nepal',
        'dhangadhi': 'nepal', 'bagmati': 'nepal', 'gandaki': 'nepal',
        'lumbini': 'nepal', 'karnali': 'nepal', 'sudurpashchim': 'nepal',
        'madhesh': 'nepal', 'koshi': 'nepal',
        # Add more city mappings as needed
    }
    
    country_for_covid = city_to_country.get(country.lower(), country)
    
    weather = get_weather_data(country)  # Weather/climate support city-level
    covid = get_covid_data(country_for_covid)  # COVID needs country name
    disease_risk = get_country_disease_risk(country_for_covid)
    earthquake = get_country_earthquake_summary(country)
    air_quality = get_air_quality_data(country)
    
    return jsonify({
        'country': country,
        'weather': weather,
        'covid': covid,
        'disease_risk': disease_risk,
        'earthquake': earthquake,
        'air_quality': air_quality,
        'fetched_at': datetime.utcnow().isoformat()
    })


@health_data_bp.route('/combined', methods=['GET'])
def get_all_combined():
    """Get combined data for multiple countries"""
    countries = request.args.get('countries', 'nepal,india').split(',')
    countries = [c.strip() for c in countries]
    
    results = []
    for country in countries:
        data = {
            'country': country,
            'weather': get_weather_data(country),
            'covid': get_covid_data(country),
            'disease_risk': get_country_disease_risk(country),
            'earthquake': get_country_earthquake_summary(country),
            'air_quality': get_air_quality_data(country)
        }
        results.append(data)
    
    return jsonify({
        'data': results,
        'count': len(results),
        'fetched_at': datetime.utcnow().isoformat()
    })


# ==================== SUPPORTED COUNTRIES ====================

@health_data_bp.route('/supported-countries', methods=['GET'])
def get_supported_countries():
    """Get list of supported countries for each data type"""
    return jsonify({
        'weather': list(WEATHER_COUNTRIES.keys()),
        'earthquake': list(EARTHQUAKE_COUNTRIES.keys()),
        'air_quality': list(CLIMATE_COUNTRIES.keys()),
        'covid': 'All countries supported (use country name or ISO code)'
    })
