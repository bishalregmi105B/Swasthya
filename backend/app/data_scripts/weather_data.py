"""
Weather Data Service
Fetches weather data from Open-Meteo API (free, no API key required)
"""

import requests
from datetime import datetime
from typing import Dict, List, Optional

# Open-Meteo API (free, no API key)
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

# Country coordinates (capital cities)
COUNTRY_COORDINATES = {
    'nepal': {'lat': 27.7172, 'lon': 85.3240, 'city': 'Kathmandu'},
    'india': {'lat': 28.6139, 'lon': 77.2090, 'city': 'New Delhi'},
    'bangladesh': {'lat': 23.8103, 'lon': 90.4125, 'city': 'Dhaka'},
    'pakistan': {'lat': 33.6844, 'lon': 73.0479, 'city': 'Islamabad'},
    'sri_lanka': {'lat': 6.9271, 'lon': 79.8612, 'city': 'Colombo'},
    'usa': {'lat': 38.8951, 'lon': -77.0364, 'city': 'Washington DC'},
    'uk': {'lat': 51.5074, 'lon': -0.1278, 'city': 'London'},
    'australia': {'lat': -35.2809, 'lon': 149.1300, 'city': 'Canberra'},
    'japan': {'lat': 35.6762, 'lon': 139.6503, 'city': 'Tokyo'},
    'china': {'lat': 39.9042, 'lon': 116.4074, 'city': 'Beijing'},
}

# Nepal provinces and major cities for granular weather data
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


def get_weather_data(location: str) -> Optional[Dict]:
    """
    Fetch current weather and forecast for a location
    
    Args:
        location: Country, province, or city (nepal, kathmandu, bagmati, etc.)
    
    Returns:
        Weather data dictionary or None
    """
    loc = location.lower().strip()
    
    # First check Nepal locations (provinces/cities)
    coords = NEPAL_LOCATIONS.get(loc)
    
    # Fall back to country coordinates
    if not coords:
        coords = COUNTRY_COORDINATES.get(loc)
    
    if not coords:
        # Default to nepal if unknown location
        coords = COUNTRY_COORDINATES.get('nepal')
        loc = 'nepal'
    
    params = {
        'latitude': coords['lat'],
        'longitude': coords['lon'],
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,surface_pressure,dew_point_2m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,uv_index_max,sunshine_duration,precipitation_probability_max,wind_speed_10m_max',
        'timezone': 'auto',
        'forecast_days': 16  # Extended from 7 to 16 days
    }
    
    try:
        response = requests.get(OPEN_METEO_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Weather code to description
        weather_codes = {
            0: 'Clear sky',
            1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
            45: 'Fog', 48: 'Depositing rime fog',
            51: 'Light drizzle', 53: 'Moderate drizzle', 55: 'Dense drizzle',
            61: 'Slight rain', 63: 'Moderate rain', 65: 'Heavy rain',
            71: 'Slight snow', 73: 'Moderate snow', 75: 'Heavy snow',
            80: 'Slight rain showers', 81: 'Moderate rain showers', 82: 'Violent rain showers',
            95: 'Thunderstorm', 96: 'Thunderstorm with slight hail', 99: 'Thunderstorm with heavy hail'
        }
        
        current = data.get('current', {})
        daily = data.get('daily', {})
        
        return {
            'location': loc,
            'city': coords['city'],
            'coordinates': {'lat': coords['lat'], 'lon': coords['lon']},
            'current': {
                'temperature': current.get('temperature_2m'),
                'feels_like': current.get('apparent_temperature'),
                'humidity': current.get('relative_humidity_2m'),
                'precipitation': current.get('precipitation'),
                'wind_speed': current.get('wind_speed_10m'),
                'dew_point': current.get('dew_point_2m'),
                'pressure': current.get('surface_pressure'),
                'weather_code': current.get('weather_code'),
                'weather_description': weather_codes.get(current.get('weather_code', 0), 'Unknown'),
                'time': current.get('time')
            },
            'forecast': [
                {
                    'date': daily['time'][i] if daily.get('time') else None,
                    'temp_max': daily['temperature_2m_max'][i] if daily.get('temperature_2m_max') else None,
                    'temp_min': daily['temperature_2m_min'][i] if daily.get('temperature_2m_min') else None,
                    'precipitation': daily['precipitation_sum'][i] if daily.get('precipitation_sum') else None,
                    'precipitation_probability': daily['precipitation_probability_max'][i] if daily.get('precipitation_probability_max') else None,
                    'uv_index': daily['uv_index_max'][i] if daily.get('uv_index_max') else None,
                    'sunshine_hours': round((daily['sunshine_duration'][i] or 0) / 3600, 1) if daily.get('sunshine_duration') else None,
                    'max_wind': daily['wind_speed_10m_max'][i] if daily.get('wind_speed_10m_max') else None,
                    'weather_code': daily['weather_code'][i] if daily.get('weather_code') else None,
                    'weather_description': weather_codes.get(daily['weather_code'][i] if daily.get('weather_code') else 0, 'Unknown')
                }
                for i in range(len(daily.get('time', [])))
            ],
            'health_advisory': generate_weather_health_advisory(current, daily),
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching weather for {loc}: {e}")
        return None


def generate_weather_health_advisory(current: Dict, daily: Dict) -> List[str]:
    """Generate health advisories based on weather conditions"""
    advisories = []
    
    temp = current.get('temperature_2m', 25)
    humidity = current.get('relative_humidity_2m', 50)
    uv_max = daily.get('uv_index_max', [0])[0] if daily.get('uv_index_max') else 0
    weather_code = current.get('weather_code', 0)
    
    # Temperature advisories
    if temp and temp > 35:
        advisories.append('⚠️ Extreme heat warning: Stay hydrated, avoid outdoor activities during peak hours')
    elif temp and temp > 30:
        advisories.append('🌡️ High temperature: Drink plenty of water and wear light clothing')
    elif temp and temp < 5:
        advisories.append('❄️ Cold weather alert: Wear warm layers and protect extremities')
    elif temp and temp < 0:
        advisories.append('⚠️ Freezing conditions: Risk of frostbite, limit outdoor exposure')
    
    # Humidity advisories
    if humidity and humidity > 80:
        advisories.append('💧 High humidity: May cause discomfort, increased risk for heat-related illness')
    elif humidity and humidity < 30:
        advisories.append('🏜️ Low humidity: Stay hydrated, use moisturizer')
    
    # UV advisories
    if uv_max and uv_max >= 11:
        advisories.append('☀️ Extreme UV: Avoid sun exposure, use SPF 50+ sunscreen')
    elif uv_max and uv_max >= 8:
        advisories.append('🌞 Very high UV: Limit midday sun, use SPF 30+ sunscreen')
    elif uv_max and uv_max >= 6:
        advisories.append('🧴 High UV: Use sunscreen and wear protective clothing')
    
    # Weather condition advisories
    if weather_code in [95, 96, 99]:
        advisories.append('⛈️ Thunderstorm: Seek shelter indoors, avoid open areas')
    elif weather_code in [65, 82]:
        advisories.append('🌧️ Heavy rain: Risk of flooding, avoid low-lying areas')
    elif weather_code in [73, 75]:
        advisories.append('❄️ Snow conditions: Drive carefully, risk of slippery surfaces')
    elif weather_code in [45, 48]:
        advisories.append('🌫️ Foggy conditions: Reduced visibility, drive with caution')
    
    if not advisories:
        advisories.append('✅ Weather conditions are favorable for outdoor activities')
    
    return advisories


def get_all_countries_weather() -> List[Dict]:
    """Fetch weather for all configured countries"""
    results = []
    for country in COUNTRY_COORDINATES.keys():
        data = get_weather_data(country)
        if data:
            results.append(data)
    return results


if __name__ == "__main__":
    # Test
    print("Testing weather data for Nepal...")
    data = get_weather_data('nepal')
    if data:
        print(f"Temperature: {data['current']['temperature']}°C")
        print(f"Weather: {data['current']['weather_description']}")
        print(f"Advisories: {data['health_advisory']}")
