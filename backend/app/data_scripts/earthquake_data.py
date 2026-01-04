"""
Earthquake Alert Data Service
Fetches earthquake data from USGS Earthquake API (free, no API key)
"""

import requests
from datetime import datetime, timedelta
from typing import Dict, List, Optional

# USGS Earthquake API (free, no API key)
USGS_EARTHQUAKE_URL = "https://earthquake.usgs.gov/fdsnws/event/1/query"

# Country bounding boxes for filtering earthquakes
COUNTRY_BOUNDS = {
    'nepal': {'minlat': 26.35, 'maxlat': 30.45, 'minlon': 80.05, 'maxlon': 88.20},
    'india': {'minlat': 6.75, 'maxlat': 35.50, 'minlon': 68.16, 'maxlon': 97.40},
    'bangladesh': {'minlat': 20.74, 'maxlat': 26.63, 'minlon': 88.01, 'maxlon': 92.67},
    'pakistan': {'minlat': 23.69, 'maxlat': 37.09, 'minlon': 60.87, 'maxlon': 77.84},
    'japan': {'minlat': 24.40, 'maxlat': 45.52, 'minlon': 122.93, 'maxlon': 153.99},
    'indonesia': {'minlat': -11.00, 'maxlat': 6.08, 'minlon': 95.01, 'maxlon': 141.02},
    'usa': {'minlat': 24.52, 'maxlat': 49.38, 'minlon': -125.00, 'maxlon': -66.95},
    'turkey': {'minlat': 35.82, 'maxlat': 42.11, 'minlon': 25.67, 'maxlon': 44.82},
    'chile': {'minlat': -56.00, 'maxlat': -17.50, 'minlon': -75.64, 'maxlon': -66.96},
    'philippines': {'minlat': 4.64, 'maxlat': 21.12, 'minlon': 116.93, 'maxlon': 126.60},
}


def get_earthquakes(country: str = None, min_magnitude: float = 2.5, days: int = 7) -> List[Dict]:
    """
    Fetch recent earthquakes
    
    Args:
        country: Country to filter (optional)
        min_magnitude: Minimum magnitude to fetch
        days: Number of days to look back
    
    Returns:
        List of earthquake events
    """
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=days)
    
    params = {
        'format': 'geojson',
        'starttime': start_time.strftime('%Y-%m-%d'),
        'endtime': end_time.strftime('%Y-%m-%d'),
        'minmagnitude': min_magnitude,
        'orderby': 'time',
        'limit': 100
    }
    
    # Add country bounds if specified
    if country and country.lower() in COUNTRY_BOUNDS:
        bounds = COUNTRY_BOUNDS[country.lower()]
        params.update(bounds)
    
    try:
        response = requests.get(USGS_EARTHQUAKE_URL, params=params, timeout=15)
        response.raise_for_status()
        data = response.json()
        
        earthquakes = []
        for feature in data.get('features', []):
            props = feature.get('properties', {})
            coords = feature.get('geometry', {}).get('coordinates', [0, 0, 0])
            
            earthquake = {
                'id': feature.get('id'),
                'magnitude': props.get('mag'),
                'magnitude_type': props.get('magType'),
                'place': props.get('place'),
                'time': datetime.fromtimestamp(props.get('time', 0) / 1000).isoformat() if props.get('time') else None,
                'updated': datetime.fromtimestamp(props.get('updated', 0) / 1000).isoformat() if props.get('updated') else None,
                'coordinates': {
                    'longitude': coords[0] if len(coords) > 0 else None,
                    'latitude': coords[1] if len(coords) > 1 else None,
                    'depth_km': coords[2] if len(coords) > 2 else None
                },
                'alert_level': props.get('alert'),  # green, yellow, orange, red
                'tsunami_warning': props.get('tsunami', 0) == 1,
                'felt_reports': props.get('felt', 0),
                'significance': props.get('sig', 0),
                'url': props.get('url'),
                'severity': get_earthquake_severity(props.get('mag', 0)),
                'safety_advisory': get_earthquake_advisory(props.get('mag', 0), props.get('alert'))
            }
            earthquakes.append(earthquake)
        
        return earthquakes
    except Exception as e:
        print(f"Error fetching earthquake data: {e}")
        return []


def get_earthquake_severity(magnitude: float) -> str:
    """Classify earthquake severity based on magnitude"""
    if magnitude >= 8.0:
        return 'catastrophic'
    elif magnitude >= 7.0:
        return 'major'
    elif magnitude >= 6.0:
        return 'strong'
    elif magnitude >= 5.0:
        return 'moderate'
    elif magnitude >= 4.0:
        return 'light'
    elif magnitude >= 3.0:
        return 'minor'
    else:
        return 'micro'


def get_earthquake_advisory(magnitude: float, alert_level: str = None) -> List[str]:
    """Generate safety advisory based on earthquake magnitude"""
    advisories = []
    
    if magnitude >= 7.0:
        advisories.extend([
            '🚨 MAJOR EARTHQUAKE: Evacuate buildings immediately',
            '⚠️ Stay away from damaged structures',
            '🌊 If near coast, move to high ground (tsunami risk)',
            '📻 Follow emergency broadcast instructions',
            '🏥 Check for injuries, provide first aid if safe'
        ])
    elif magnitude >= 6.0:
        advisories.extend([
            '⚠️ Strong earthquake: Take cover under sturdy furniture',
            '🚪 Stay away from windows and heavy objects',
            '🔌 Be prepared for power outages',
            '📱 Keep emergency supplies ready'
        ])
    elif magnitude >= 5.0:
        advisories.extend([
            '🏠 Moderate earthquake: Check for structural damage',
            '💧 Inspect water and gas lines',
            '📋 Document any damage for insurance'
        ])
    elif magnitude >= 4.0:
        advisories.append('ℹ️ Light earthquake detected. Usually not dangerous but stay alert.')
    else:
        advisories.append('✅ Minor tremor. Generally not felt or causes minimal effects.')
    
    if alert_level == 'red':
        advisories.insert(0, '🔴 RED ALERT: Significant casualties/damage expected')
    elif alert_level == 'orange':
        advisories.insert(0, '🟠 ORANGE ALERT: Notable impact possible')
    elif alert_level == 'yellow':
        advisories.insert(0, '🟡 YELLOW ALERT: Some damage/injuries possible')
    
    return advisories


def get_significant_earthquakes(min_magnitude: float = 5.5, days: int = 30) -> List[Dict]:
    """Get significant earthquakes worldwide"""
    return get_earthquakes(country=None, min_magnitude=min_magnitude, days=days)


def get_country_earthquake_summary(country: str, days: int = 30) -> Dict:
    """Get earthquake summary for a specific country"""
    earthquakes = get_earthquakes(country=country, min_magnitude=2.0, days=days)
    
    if not earthquakes:
        return {
            'country': country,
            'period_days': days,
            'total_count': 0,
            'max_magnitude': 0,
            'recent_earthquakes': [],
            'risk_level': 'low',
            'message': f'No significant earthquakes recorded in {country} in the last {days} days'
        }
    
    max_mag = max([eq['magnitude'] or 0 for eq in earthquakes])
    count_significant = len([eq for eq in earthquakes if (eq['magnitude'] or 0) >= 4.0])
    
    # Determine risk level
    if max_mag >= 6.0 or count_significant >= 5:
        risk_level = 'high'
    elif max_mag >= 5.0 or count_significant >= 2:
        risk_level = 'moderate'
    else:
        risk_level = 'low'
    
    return {
        'country': country,
        'period_days': days,
        'total_count': len(earthquakes),
        'max_magnitude': max_mag,
        'significant_count': count_significant,
        'recent_earthquakes': earthquakes[:10],  # Last 10
        'risk_level': risk_level,
        'fetched_at': datetime.utcnow().isoformat()
    }


def get_all_countries_earthquakes(countries: List[str] = None, days: int = 7) -> List[Dict]:
    """Get earthquake data for multiple countries"""
    if countries is None:
        countries = list(COUNTRY_BOUNDS.keys())
    
    results = []
    for country in countries:
        summary = get_country_earthquake_summary(country, days)
        results.append(summary)
    
    return results


if __name__ == "__main__":
    # Test
    print("Testing earthquake data for Nepal...")
    summary = get_country_earthquake_summary('nepal')
    print(f"Total earthquakes: {summary['total_count']}")
    print(f"Max magnitude: {summary['max_magnitude']}")
    print(f"Risk level: {summary['risk_level']}")
    
    print("\nRecent significant earthquakes worldwide:")
    for eq in get_significant_earthquakes(min_magnitude=5.5, days=7)[:5]:
        print(f"- M{eq['magnitude']} at {eq['place']}")
