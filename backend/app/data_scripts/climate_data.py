"""
Climate Data Service
Fetches climate/air quality data from Open-Meteo API (free, no API key)
"""

import requests
from datetime import datetime
from typing import Dict, List, Optional

# Open-Meteo Air Quality API (free, no API key)
AIR_QUALITY_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"

# Country coordinates (capital cities)
COUNTRY_COORDINATES = {
    'nepal': {'lat': 27.7172, 'lon': 85.3240, 'city': 'Kathmandu'},
    'india': {'lat': 28.6139, 'lon': 77.2090, 'city': 'New Delhi'},
    'bangladesh': {'lat': 23.8103, 'lon': 90.4125, 'city': 'Dhaka'},
    'pakistan': {'lat': 33.6844, 'lon': 73.0479, 'city': 'Islamabad'},
    'china': {'lat': 39.9042, 'lon': 116.4074, 'city': 'Beijing'},
    'usa': {'lat': 38.8951, 'lon': -77.0364, 'city': 'Washington DC'},
    'uk': {'lat': 51.5074, 'lon': -0.1278, 'city': 'London'},
    'japan': {'lat': 35.6762, 'lon': 139.6503, 'city': 'Tokyo'},
    'australia': {'lat': -35.2809, 'lon': 149.1300, 'city': 'Canberra'},
}

# Nepal provinces and major cities for granular data
NEPAL_LOCATIONS = {
    # Provinces
    'bagmati': {'lat': 27.7172, 'lon': 85.3240, 'city': 'Kathmandu'},
    'gandaki': {'lat': 28.2096, 'lon': 83.9856, 'city': 'Pokhara'},
    'lumbini': {'lat': 27.7006, 'lon': 83.4588, 'city': 'Butwal'},
    'karnali': {'lat': 29.0470, 'lon': 82.3090, 'city': 'Birendranagar'},
    'sudurpashchim': {'lat': 28.7000, 'lon': 80.5800, 'city': 'Dhangadhi'},
    'madhesh': {'lat': 26.8065, 'lon': 87.2846, 'city': 'Janakpur'},
    'koshi': {'lat': 26.4525, 'lon': 87.2718, 'city': 'Biratnagar'},
    
    # Major cities
    'kathmandu': {'lat': 27.7172, 'lon': 85.3240, 'city': 'Kathmandu'},
    'pokhara': {'lat': 28.2096, 'lon': 83.9856, 'city': 'Pokhara'},
    'lalitpur': {'lat': 27.6588, 'lon': 85.3247, 'city': 'Lalitpur'},
    'bhaktapur': {'lat': 27.6710, 'lon': 85.4298, 'city': 'Bhaktapur'},
    'biratnagar': {'lat': 26.4525, 'lon': 87.2718, 'city': 'Biratnagar'},
    'birgunj': {'lat': 27.0104, 'lon': 84.8821, 'city': 'Birgunj'},
    'bharatpur': {'lat': 27.6833, 'lon': 84.4333, 'city': 'Bharatpur'},
    'hetauda': {'lat': 27.4167, 'lon': 85.0333, 'city': 'Hetauda'},
    'dharan': {'lat': 26.8167, 'lon': 87.2833, 'city': 'Dharan'},
    'butwal': {'lat': 27.7006, 'lon': 83.4588, 'city': 'Butwal'},
    'nepalgunj': {'lat': 28.0500, 'lon': 81.6167, 'city': 'Nepalgunj'},
    'janakpur': {'lat': 26.7271, 'lon': 85.9407, 'city': 'Janakpur'},
    'dhangadhi': {'lat': 28.7000, 'lon': 80.5800, 'city': 'Dhangadhi'},
}


def get_aqi_category(aqi: float) -> Dict:
    """Get AQI category and health implications"""
    if aqi <= 50:
        return {
            'category': 'Good',
            'color': 'green',
            'health_implications': 'Air quality is satisfactory, poses little or no risk.',
            'advisory': 'Enjoy outdoor activities!'
        }
    elif aqi <= 100:
        return {
            'category': 'Moderate',
            'color': 'yellow',
            'health_implications': 'Acceptable air quality. Unusually sensitive individuals should consider limiting prolonged outdoor exertion.',
            'advisory': 'Generally safe for outdoor activities.'
        }
    elif aqi <= 150:
        return {
            'category': 'Unhealthy for Sensitive Groups',
            'color': 'orange',
            'health_implications': 'Members of sensitive groups may experience health effects. General public less likely to be affected.',
            'advisory': 'Sensitive individuals should limit prolonged outdoor exertion.'
        }
    elif aqi <= 200:
        return {
            'category': 'Unhealthy',
            'color': 'red',
            'health_implications': 'Everyone may begin to experience health effects; sensitive groups may experience more serious effects.',
            'advisory': 'Everyone should reduce prolonged outdoor exertion.'
        }
    elif aqi <= 300:
        return {
            'category': 'Very Unhealthy',
            'color': 'purple',
            'health_implications': 'Health warnings of emergency conditions. Entire population is more likely to be affected.',
            'advisory': 'Avoid outdoor activities. Keep windows closed.'
        }
    else:
        return {
            'category': 'Hazardous',
            'color': 'maroon',
            'health_implications': 'Health alert: everyone may experience serious health effects.',
            'advisory': 'Stay indoors. Use air purifiers if available.'
        }


def get_air_quality_data(location: str) -> Optional[Dict]:
    """
    Fetch air quality data for a location
    
    Args:
        location: Country, province, or city (nepal, kathmandu, bagmati, etc.)
    
    Returns:
        Air quality data dictionary or None
    """
    loc = location.lower().strip()
    
    # First check Nepal locations
    coords = NEPAL_LOCATIONS.get(loc)
    
    # Fall back to country coordinates
    if not coords:
        coords = COUNTRY_COORDINATES.get(loc)
    
    if not coords:
        # Default to nepal
        coords = COUNTRY_COORDINATES.get('nepal')
        loc = 'nepal'
    
    params = {
        'latitude': coords['lat'],
        'longitude': coords['lon'],
        'current': 'us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone',
        'hourly': 'us_aqi,pm2_5,pm10',
        'timezone': 'auto',
        'forecast_days': 3
    }
    
    try:
        response = requests.get(AIR_QUALITY_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        current = data.get('current', {})
        aqi = current.get('us_aqi', 0)
        aqi_info = get_aqi_category(aqi)
        
        return {
            'location': loc,
            'city': coords['city'],
            'coordinates': {'lat': coords['lat'], 'lon': coords['lon']},
            'current': {
                'aqi': aqi,
                'aqi_category': aqi_info['category'],
                'aqi_color': aqi_info['color'],
                'health_implications': aqi_info['health_implications'],
                'advisory': aqi_info['advisory'],
                'pm2_5': current.get('pm2_5'),  # Fine particles
                'pm10': current.get('pm10'),     # Coarse particles
                'carbon_monoxide': current.get('carbon_monoxide'),
                'nitrogen_dioxide': current.get('nitrogen_dioxide'),
                'sulphur_dioxide': current.get('sulphur_dioxide'),
                'ozone': current.get('ozone'),
                'time': current.get('time')
            },
            'forecast': extract_aqi_forecast(data.get('hourly', {})),
            'health_recommendations': generate_air_quality_recommendations(aqi),
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching air quality for {loc}: {e}")
        return None


def extract_aqi_forecast(hourly: Dict) -> List[Dict]:
    """Extract daily AQI forecast from hourly data"""
    times = hourly.get('time', [])
    aqis = hourly.get('us_aqi', [])
    pm25s = hourly.get('pm2_5', [])
    
    # Group by day and get max AQI
    daily_data = {}
    for i, time in enumerate(times):
        date = time.split('T')[0] if time else None
        if date and i < len(aqis):
            if date not in daily_data:
                daily_data[date] = {'max_aqi': 0, 'max_pm25': 0}
            daily_data[date]['max_aqi'] = max(daily_data[date]['max_aqi'], aqis[i] or 0)
            if i < len(pm25s):
                daily_data[date]['max_pm25'] = max(daily_data[date]['max_pm25'], pm25s[i] or 0)
    
    forecast = []
    for date, data in sorted(daily_data.items()):
        aqi_info = get_aqi_category(data['max_aqi'])
        forecast.append({
            'date': date,
            'max_aqi': data['max_aqi'],
            'max_pm25': data['max_pm25'],
            'category': aqi_info['category'],
            'advisory': aqi_info['advisory']
        })
    
    return forecast


def generate_air_quality_recommendations(aqi: float) -> List[str]:
    """Generate health recommendations based on AQI"""
    recommendations = []
    
    if aqi <= 50:
        recommendations = [
            '✅ Great day for outdoor activities',
            '🏃 Perfect conditions for exercise outdoors',
            '🪟 Open windows for fresh air'
        ]
    elif aqi <= 100:
        recommendations = [
            '👍 Generally safe for outdoor activities',
            '⚠️ Sensitive individuals should monitor symptoms',
            '🌳 Consider parks with more vegetation'
        ]
    elif aqi <= 150:
        recommendations = [
            '😷 Sensitive groups should wear masks outdoors',
            '🏠 Limit prolonged outdoor activities',
            '🚫 Avoid exercising near high-traffic areas',
            '💨 Use air purifiers indoors if available'
        ]
    elif aqi <= 200:
        recommendations = [
            '😷 Everyone should wear N95 masks outdoors',
            '🏠 Reduce outdoor activities to minimum',
            '🚫 Avoid strenuous outdoor exercise',
            '💨 Keep air purifiers running indoors',
            '🪟 Keep windows and doors closed'
        ]
    elif aqi <= 300:
        recommendations = [
            '🚨 Avoid all outdoor activities',
            '😷 Wear N95 mask even for short exposure',
            '🏠 Stay indoors as much as possible',
            '💨 Use air purifiers on high setting',
            '🏥 Seek medical help if breathing difficulties occur'
        ]
    else:
        recommendations = [
            '🚨 EMERGENCY: Stay indoors completely',
            '😷 N95 mask required even indoors if no purifier',
            '🔒 Seal windows and doors',
            '💨 Air purifiers essential',
            '🏥 Seek immediate medical attention for respiratory issues',
            '📞 Check on elderly and vulnerable individuals'
        ]
    
    return recommendations


def get_pollen_data(country: str) -> Optional[Dict]:
    """
    Fetch pollen and allergy data from Open-Meteo Air Quality API
    
    Args:
        country: Country name
    
    Returns:
        Pollen levels for grass, birch, alder, ragweed with health alerts
    """
    loc = country.lower().strip()
    
    # Check Nepal locations first
    coords = NEPAL_LOCATIONS.get(loc)
    if not coords:
        coords = COUNTRY_COORDINATES.get(loc)
    if not coords:
        coords = COUNTRY_COORDINATES.get('nepal')
        loc = 'nepal'
    
    params = {
        'latitude': coords['lat'],
        'longitude': coords['lon'],
        'current': 'alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,olive_pollen,ragweed_pollen,dust,uv_index',
        'hourly': 'grass_pollen,birch_pollen,alder_pollen,ragweed_pollen,dust',
        'timezone': 'auto',
        'forecast_days': 3
    }
    
    try:
        response = requests.get(AIR_QUALITY_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        current = data.get('current', {})
        
        # Get pollen levels
        grass = current.get('grass_pollen', 0) or 0
        birch = current.get('birch_pollen', 0) or 0
        alder = current.get('alder_pollen', 0) or 0
        ragweed = current.get('ragweed_pollen', 0) or 0
        mugwort = current.get('mugwort_pollen', 0) or 0
        olive = current.get('olive_pollen', 0) or 0
        dust = current.get('dust', 0) or 0
        uv = current.get('uv_index', 0) or 0
        
        # Calculate overall pollen risk
        max_pollen = max(grass, birch, alder, ragweed, mugwort, olive)
        pollen_risk = _get_pollen_risk_level(max_pollen)
        
        # Generate allergy forecast from hourly data
        hourly = data.get('hourly', {})
        forecast = _extract_pollen_forecast(hourly)
        
        # Generate health alerts
        alerts = _generate_pollen_alerts(grass, birch, alder, ragweed, dust, uv)
        
        return {
            'location': loc,
            'city': coords['city'],
            'coordinates': {'lat': coords['lat'], 'lon': coords['lon']},
            'current': {
                'grass_pollen': grass,
                'birch_pollen': birch,
                'alder_pollen': alder,
                'ragweed_pollen': ragweed,
                'mugwort_pollen': mugwort,
                'olive_pollen': olive,
                'dust': dust,
                'uv_index': round(uv, 1),
            },
            'pollen_risk': pollen_risk,
            'forecast': forecast,
            'health_alerts': alerts,
            'recommendations': _generate_pollen_recommendations(max_pollen, dust, uv),
            'time': current.get('time'),
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching pollen data for {country}: {e}")
        return None


def _get_pollen_risk_level(pollen: float) -> Dict:
    """Get pollen risk level and color"""
    if pollen < 10:
        return {'level': 'very_low', 'color': 'green', 'message': 'Very low pollen - ideal for allergy sufferers'}
    elif pollen < 30:
        return {'level': 'low', 'color': 'lightgreen', 'message': 'Low pollen - minimal impact expected'}
    elif pollen < 60:
        return {'level': 'moderate', 'color': 'yellow', 'message': 'Moderate pollen - some may experience symptoms'}
    elif pollen < 100:
        return {'level': 'high', 'color': 'orange', 'message': 'High pollen - allergy sufferers take precautions'}
    else:
        return {'level': 'very_high', 'color': 'red', 'message': 'Very high pollen - stay indoors if sensitive'}


def _extract_pollen_forecast(hourly: Dict) -> List[Dict]:
    """Extract daily pollen forecast from hourly data"""
    times = hourly.get('time', [])
    grass = hourly.get('grass_pollen', [])
    birch = hourly.get('birch_pollen', [])
    
    daily = {}
    for i, time in enumerate(times):
        date = time.split('T')[0] if time else None
        if date:
            if date not in daily:
                daily[date] = {'grass': [], 'birch': []}
            # Handle None values by using 0 as fallback
            grass_val = grass[i] if i < len(grass) and grass[i] is not None else 0
            birch_val = birch[i] if i < len(birch) and birch[i] is not None else 0
            daily[date]['grass'].append(grass_val)
            daily[date]['birch'].append(birch_val)
    
    return [
        {
            'date': date,
            'max_grass': max(vals['grass']) if vals['grass'] else 0,
            'max_birch': max(vals['birch']) if vals['birch'] else 0,
        }
        for date, vals in list(daily.items())[:3]
    ]


def _generate_pollen_alerts(grass: float, birch: float, alder: float, ragweed: float, dust: float, uv: float) -> List[Dict]:
    """Generate health alerts for pollen and environmental factors"""
    alerts = []
    
    if grass > 60:
        alerts.append({
            'type': 'grass_pollen',
            'severity': 'high' if grass > 100 else 'moderate',
            'message': f'High grass pollen ({int(grass)} grains/m³) - hay fever likely',
            'icon': '🌾'
        })
    
    if birch > 50:
        alerts.append({
            'type': 'tree_pollen',
            'severity': 'high' if birch > 90 else 'moderate',
            'message': f'Elevated tree pollen ({int(birch)} grains/m³)',
            'icon': '🌳'
        })
    
    if ragweed > 30:
        alerts.append({
            'type': 'ragweed',
            'severity': 'high' if ragweed > 70 else 'moderate',
            'message': f'Ragweed allergy alert ({int(ragweed)} grains/m³)',
            'icon': '🌿'
        })
    
    if dust > 50:
        alerts.append({
            'type': 'dust',
            'severity': 'high' if dust > 100 else 'moderate',
            'message': f'High dust levels ({int(dust)} μg/m³) - wear mask',
            'icon': '💨'
        })
    
    if uv > 8:
        alerts.append({
            'type': 'uv',
            'severity': 'high' if uv > 10 else 'moderate',
            'message': f'Very high UV index ({uv}) - sun protection essential',
            'icon': '☀️'
        })
    
    return alerts


def _generate_pollen_recommendations(pollen: float, dust: float, uv: float) -> List[str]:
    """Generate health recommendations for pollen and environmental factors"""
    recs = []
    
    if pollen > 60:
        recs.extend([
            '😷 Consider wearing a pollen mask outdoors',
            '🪟 Keep windows closed during high pollen hours',
            '🚿 Shower after outdoor activities',
            '💊 Take antihistamines if prescribed'
        ])
    elif pollen > 30:
        recs.append('📋 Monitor your allergy symptoms')
    
    if dust > 50:
        recs.append('😷 Wear a mask to protect from dust')
    
    if uv > 6:
        recs.extend([
            '🧴 Apply SPF 30+ sunscreen',
            '🕶️ Wear sunglasses outdoors',
            '⏰ Avoid direct sun 10am-4pm'
        ])
    
    if not recs:
        recs.append('✅ Good conditions for outdoor activities')
    
    return recs


def get_all_countries_air_quality() -> List[Dict]:
    """Fetch air quality for all configured countries"""
    results = []
    for country in COUNTRY_COORDINATES.keys():
        data = get_air_quality_data(country)
        if data:
            results.append(data)
    return results


if __name__ == "__main__":
    # Test
    print("Testing air quality data for Nepal...")
    data = get_air_quality_data('nepal')
    if data:
        print(f"AQI: {data['current']['aqi']}")
        print(f"Category: {data['current']['aqi_category']}")
        print(f"Advisory: {data['current']['advisory']}")
