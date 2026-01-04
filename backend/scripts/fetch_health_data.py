#!/usr/bin/env python3

import os
import sys
import json
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.data_scripts.weather_data import get_weather_data, get_all_countries_weather
from app.data_scripts.disease_data import get_covid_data, get_disease_outbreaks, get_country_disease_risk
from app.data_scripts.earthquake_data import get_country_earthquake_summary, get_significant_earthquakes
from app.data_scripts.climate_data import get_air_quality_data, get_all_countries_air_quality

# Configuration
CACHE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data_cache')
COUNTRIES = ['nepal', 'india', 'bangladesh', 'pakistan', 'usa', 'uk', 'japan']
LOG_PREFIX = f"[{datetime.utcnow().isoformat()}]"


def ensure_cache_dir():
    """Create cache directory if it doesn't exist"""
    if not os.path.exists(CACHE_DIR):
        os.makedirs(CACHE_DIR)
    print(f"{LOG_PREFIX} Cache directory: {CACHE_DIR}")


def save_to_cache(filename: str, data: dict):
    """Save data to JSON cache file"""
    filepath = os.path.join(CACHE_DIR, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"{LOG_PREFIX} Saved: {filename}")


def fetch_weather_data():
    """Fetch weather data for all countries"""
    print(f"{LOG_PREFIX} Fetching weather data...")
    all_data = []
    for country in COUNTRIES:
        data = get_weather_data(country)
        if data:
            all_data.append(data)
            save_to_cache(f'weather_{country}.json', data)
    
    save_to_cache('weather_all.json', {
        'data': all_data,
        'fetched_at': datetime.utcnow().isoformat(),
        'count': len(all_data)
    })
    print(f"{LOG_PREFIX} Weather data fetched for {len(all_data)} countries")
    return all_data


def fetch_disease_data():
    """Fetch disease/COVID data"""
    print(f"{LOG_PREFIX} Fetching disease data...")
    all_data = []
    
    for country in COUNTRIES:
        covid = get_covid_data(country)
        risk = get_country_disease_risk(country)
        if covid or risk:
            data = {'country': country, 'covid': covid, 'disease_risk': risk}
            all_data.append(data)
            save_to_cache(f'disease_{country}.json', data)
    
    # Save outbreaks
    outbreaks = get_disease_outbreaks()
    save_to_cache('disease_outbreaks.json', {
        'outbreaks': outbreaks,
        'fetched_at': datetime.utcnow().isoformat()
    })
    
    save_to_cache('disease_all.json', {
        'data': all_data,
        'fetched_at': datetime.utcnow().isoformat(),
        'count': len(all_data)
    })
    print(f"{LOG_PREFIX} Disease data fetched for {len(all_data)} countries")
    return all_data


def fetch_earthquake_data():
    """Fetch earthquake data"""
    print(f"{LOG_PREFIX} Fetching earthquake data...")
    all_data = []
    
    for country in COUNTRIES:
        summary = get_country_earthquake_summary(country)
        if summary:
            all_data.append(summary)
            save_to_cache(f'earthquake_{country}.json', summary)
    
    # Get significant worldwide earthquakes
    significant = get_significant_earthquakes(min_magnitude=5.0, days=7)
    save_to_cache('earthquake_significant.json', {
        'earthquakes': significant,
        'fetched_at': datetime.utcnow().isoformat(),
        'count': len(significant)
    })
    
    save_to_cache('earthquake_all.json', {
        'data': all_data,
        'fetched_at': datetime.utcnow().isoformat(),
        'count': len(all_data)
    })
    print(f"{LOG_PREFIX} Earthquake data fetched for {len(all_data)} countries")
    return all_data


def fetch_climate_data():
    """Fetch air quality/climate data"""
    print(f"{LOG_PREFIX} Fetching climate/air quality data...")
    all_data = []
    
    for country in COUNTRIES:
        data = get_air_quality_data(country)
        if data:
            all_data.append(data)
            save_to_cache(f'climate_{country}.json', data)
    
    save_to_cache('climate_all.json', {
        'data': all_data,
        'fetched_at': datetime.utcnow().isoformat(),
        'count': len(all_data)
    })
    print(f"{LOG_PREFIX} Climate data fetched for {len(all_data)} countries")
    return all_data


def check_for_alerts(weather_data, earthquake_data, climate_data):
    """Check for critical conditions that need alerts"""
    alerts = []
    
    # Check weather alerts
    for w in weather_data:
        advisories = w.get('health_advisory', [])
        if any('⚠️' in a or '🚨' in a for a in advisories):
            alerts.append({
                'type': 'weather',
                'country': w.get('country'),
                'message': advisories[0] if advisories else 'Weather alert'
            })
    
    # Check earthquake alerts
    for eq in earthquake_data:
        if eq.get('max_magnitude', 0) >= 5.0:
            alerts.append({
                'type': 'earthquake',
                'country': eq.get('country'),
                'message': f"M{eq['max_magnitude']} earthquake detected in {eq.get('country')}"
            })
    
    # Check air quality alerts
    for aq in climate_data:
        aqi = aq.get('current', {}).get('aqi', 0)
        if aqi >= 150:
            alerts.append({
                'type': 'air_quality',
                'country': aq.get('country'),
                'message': f"Unhealthy air quality (AQI: {aqi}) in {aq.get('city')}"
            })
    
    if alerts:
        save_to_cache('alerts.json', {
            'alerts': alerts,
            'generated_at': datetime.utcnow().isoformat()
        })
        print(f"{LOG_PREFIX} Generated {len(alerts)} alerts")
    
    return alerts


def main():
    """Main entry point"""
    print(f"\n{'='*60}")
    print(f"{LOG_PREFIX} Starting health data fetch...")
    print(f"{'='*60}")
    
    ensure_cache_dir()
    
    try:
        # Fetch all data
        weather_data = fetch_weather_data()
        disease_data = fetch_disease_data()
        earthquake_data = fetch_earthquake_data()
        climate_data = fetch_climate_data()
        
        # Check for alerts
        alerts = check_for_alerts(weather_data, earthquake_data, climate_data)
        
        # Summary
        print(f"\n{LOG_PREFIX} === SUMMARY ===")
        print(f"{LOG_PREFIX} Weather: {len(weather_data)} countries")
        print(f"{LOG_PREFIX} Disease: {len(disease_data)} countries")
        print(f"{LOG_PREFIX} Earthquake: {len(earthquake_data)} countries")
        print(f"{LOG_PREFIX} Climate: {len(climate_data)} countries")
        print(f"{LOG_PREFIX} Alerts: {len(alerts)}")
        print(f"{LOG_PREFIX} Completed successfully!")
        
    except Exception as e:
        print(f"{LOG_PREFIX} ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
