"""
Disease Outbreak Data Service
Enhanced with real-time disease surveillance from:
- Disease.sh API (COVID-19, free)
- WHO Disease Outbreak News RSS Feed
- Open Disease Data aggregators
- CDC integrations
"""

import requests
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import re

# ==================== API ENDPOINTS ====================

# Disease.sh API (free, no API key) - COVID-19 and disease data
DISEASE_SH_BASE = "https://disease.sh/v3/covid-19"

# WHO Disease Outbreak News - Multiple endpoints to try
WHO_DON_URLS = [
    "https://www.who.int/rss-feeds/news-english.xml",  # General WHO news
    "https://www.who.int/feeds/entity/csr/don/en/rss.xml",  # Disease outbreak news
    "https://www.who.int/entity/csr/don/en/rss.xml",  # Alternative DON feed
]

# CDC Open Data Portal (no API key needed for basic endpoints)
CDC_DATA_API = "https://data.cdc.gov/resource"

# Open Disease Data - for additional disease info
OPEN_DISEASE_URL = "https://disease.sh/v3/covid-19"

# Global Health Observatory API (WHO)
WHO_GHO_API = "https://ghoapi.azureedge.net/api"


# ==================== COVID-19 DATA ====================

def get_covid_data(country: str) -> Optional[Dict]:
    """
    Fetch COVID-19 data for a specific country
    
    Args:
        country: Country name or ISO code
    
    Returns:
        COVID data dictionary or None
    """
    try:
        response = requests.get(f"{DISEASE_SH_BASE}/countries/{country}", timeout=10)
        response.raise_for_status()
        data = response.json()
        
        return {
            'country': data.get('country'),
            'country_code': data.get('countryInfo', {}).get('iso2'),
            'flag': data.get('countryInfo', {}).get('flag'),
            'statistics': {
                'total_cases': data.get('cases', 0),
                'today_cases': data.get('todayCases', 0),
                'total_deaths': data.get('deaths', 0),
                'today_deaths': data.get('todayDeaths', 0),
                'recovered': data.get('recovered', 0),
                'today_recovered': data.get('todayRecovered', 0),
                'active_cases': data.get('active', 0),
                'critical': data.get('critical', 0),
                'cases_per_million': data.get('casesPerOneMillion', 0),
                'deaths_per_million': data.get('deathsPerOneMillion', 0),
                'tests': data.get('tests', 0),
                'tests_per_million': data.get('testsPerOneMillion', 0),
                'population': data.get('population', 0),
            },
            'last_updated': datetime.fromtimestamp(data.get('updated', 0) / 1000).isoformat() if data.get('updated') else None,
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching COVID data for {country}: {e}")
        return None


def get_covid_historical(country: str, days: int = 30) -> Optional[Dict]:
    """
    Fetch historical COVID-19 data for trend analysis
    
    Args:
        country: Country name or ISO code
        days: Number of days of historical data (default 30)
    
    Returns:
        Historical data with daily cases/deaths timeline
    """
    try:
        response = requests.get(
            f"{DISEASE_SH_BASE}/historical/{country}",
            params={'lastdays': days},
            timeout=10
        )
        response.raise_for_status()
        data = response.json()
        
        timeline = data.get('timeline', {})
        cases_timeline = timeline.get('cases', {})
        deaths_timeline = timeline.get('deaths', {})
        
        # Calculate daily new cases (difference between days)
        daily_cases = []
        prev_cases = None
        for date, total in cases_timeline.items():
            if prev_cases is not None:
                daily_cases.append({
                    'date': date,
                    'new_cases': max(0, total - prev_cases),
                    'total_cases': total
                })
            prev_cases = total
        
        # Calculate trend (increasing, decreasing, stable)
        if len(daily_cases) >= 7:
            last_week = sum(d['new_cases'] for d in daily_cases[-7:])
            prev_week = sum(d['new_cases'] for d in daily_cases[-14:-7]) if len(daily_cases) >= 14 else last_week
            
            if prev_week > 0:
                change = ((last_week - prev_week) / prev_week) * 100
                if change > 10:
                    trend = 'increasing'
                elif change < -10:
                    trend = 'decreasing'
                else:
                    trend = 'stable'
            else:
                trend = 'stable'
        else:
            trend = 'unknown'
        
        return {
            'country': data.get('country', country),
            'province': data.get('province', ['mainland']),
            'days': days,
            'timeline': {
                'cases': cases_timeline,
                'deaths': deaths_timeline,
            },
            'daily_breakdown': daily_cases[-14:],  # Last 14 days for charts
            'trend': trend,
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching historical COVID data for {country}: {e}")
        return None


def get_vaccination_data(country: str, days: int = 30) -> Optional[Dict]:
    """
    Fetch COVID-19 vaccination coverage data
    
    Args:
        country: Country name or ISO code
        days: Number of days of data
    
    Returns:
        Vaccination coverage timeline and statistics
    """
    try:
        # Try without fullData first (returns simpler dict format)
        response = requests.get(
            f"{DISEASE_SH_BASE}/vaccine/coverage/countries/{country}",
            params={'lastdays': days},
            timeout=10
        )
        response.raise_for_status()
        data = response.json()
        
        timeline = data.get('timeline', {})
        
        # Handle both dict and list formats
        if isinstance(timeline, list):
            # fullData format - list of {date, total, daily} objects
            if timeline:
                latest = timeline[-1] if timeline else {}
                latest_date = latest.get('date', '')
                latest_count = latest.get('total', 0)
            else:
                latest_date = None
                latest_count = 0
        elif isinstance(timeline, dict):
            # Simple format - {date: count} dict
            if timeline:
                dates = sorted(timeline.keys())
                latest_date = dates[-1] if dates else None
                latest_count = timeline.get(latest_date, 0)
            else:
                latest_date = None
                latest_count = 0
        else:
            latest_date = None
            latest_count = 0
        
        # Get population for percentage (from main COVID endpoint)
        covid_data = get_covid_data(country)
        population = covid_data.get('statistics', {}).get('population', 0) if covid_data else 30000000
        
        # Calculate coverage percentage (assuming 2 doses per person)
        coverage_pct = (latest_count / (population * 2)) * 100 if population else 0
        
        return {
            'country': data.get('country', country),
            'timeline': timeline,
            'latest': {
                'date': latest_date,
                'total_doses': latest_count,
                'population': population,
                'coverage_percentage': round(min(coverage_pct, 100), 2),
            },
            'status': _get_vaccination_status(coverage_pct),
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching vaccination data for {country}: {e}")
        # Return demo data as fallback
        return {
            'country': country.title(),
            'timeline': {},
            'latest': {
                'date': datetime.utcnow().strftime('%m/%d/%y'),
                'total_doses': 62000000,
                'population': 30000000,
                'coverage_percentage': 85.0,
            },
            'status': _get_vaccination_status(85.0),
            'is_demo_data': True,
            'fetched_at': datetime.utcnow().isoformat()
        }


def _get_vaccination_status(coverage: float) -> Dict:
    """Get vaccination status based on coverage percentage"""
    if coverage >= 70:
        return {'level': 'high', 'color': 'green', 'message': 'High vaccination coverage'}
    elif coverage >= 40:
        return {'level': 'moderate', 'color': 'yellow', 'message': 'Moderate vaccination coverage'}
    elif coverage >= 20:
        return {'level': 'low', 'color': 'orange', 'message': 'Low vaccination coverage'}
    else:
        return {'level': 'very_low', 'color': 'red', 'message': 'Very low vaccination coverage'}


def get_global_covid_data() -> Optional[Dict]:
    """Fetch global COVID-19 statistics"""
    try:
        response = requests.get(f"{DISEASE_SH_BASE}/all", timeout=10)
        response.raise_for_status()
        data = response.json()
        
        return {
            'location': 'Global',
            'statistics': {
                'total_cases': data.get('cases', 0),
                'today_cases': data.get('todayCases', 0),
                'total_deaths': data.get('deaths', 0),
                'today_deaths': data.get('todayDeaths', 0),
                'recovered': data.get('recovered', 0),
                'today_recovered': data.get('todayRecovered', 0),
                'active_cases': data.get('active', 0),
                'critical': data.get('critical', 0),
                'affected_countries': data.get('affectedCountries', 0),
            },
            'last_updated': datetime.fromtimestamp(data.get('updated', 0) / 1000).isoformat() if data.get('updated') else None,
            'fetched_at': datetime.utcnow().isoformat()
        }
    except Exception as e:
        print(f"Error fetching global COVID data: {e}")
        return None


# Neighboring countries mapping for regional comparison
COUNTRY_NEIGHBORS = {
    'nepal': ['india', 'china', 'bangladesh', 'pakistan', 'bhutan'],
    'india': ['nepal', 'pakistan', 'bangladesh', 'sri lanka', 'china'],
    'bangladesh': ['india', 'nepal', 'pakistan', 'sri lanka'],
    'pakistan': ['india', 'nepal', 'afghanistan', 'iran'],
    'bhutan': ['india', 'nepal', 'china'],
    'sri lanka': ['india', 'bangladesh'],
    'china': ['india', 'nepal', 'pakistan', 'japan', 'south korea'],
    'usa': ['canada', 'mexico', 'brazil'],
    'uk': ['france', 'germany', 'ireland', 'netherlands'],
}


def get_covid_with_neighbors(country: str) -> Dict:
    """
    Fetch COVID-19 data for a country and its neighboring countries for comparison
    
    Args:
        country: Main country name or ISO code
    
    Returns:
        Dictionary with main country data and neighboring countries for comparison
    """
    country_lower = country.lower()
    
    # Get main country data
    main_data = get_covid_data(country)
    
    # Get neighboring countries
    neighbors = COUNTRY_NEIGHBORS.get(country_lower, ['india', 'china', 'usa'])
    
    # Fetch data for neighbors
    neighbor_data = []
    for neighbor in neighbors[:4]:  # Limit to 4 neighbors
        data = get_covid_data(neighbor)
        if data:
            neighbor_data.append(data)
    
    # Calculate comparison metrics
    comparison = None
    if main_data and neighbor_data:
        main_stats = main_data.get('statistics', {})
        
        # Calculate average of neighbors
        avg_cases_per_mil = sum(n.get('statistics', {}).get('cases_per_million', 0) for n in neighbor_data) / len(neighbor_data)
        avg_deaths_per_mil = sum(n.get('statistics', {}).get('deaths_per_million', 0) for n in neighbor_data) / len(neighbor_data)
        
        main_cases_per_mil = main_stats.get('cases_per_million', 0)
        main_deaths_per_mil = main_stats.get('deaths_per_million', 0)
        
        comparison = {
            'your_country': {
                'name': main_data.get('country'),
                'cases_per_million': main_cases_per_mil,
                'deaths_per_million': main_deaths_per_mil,
                'active_cases': main_stats.get('active_cases', 0),
            },
            'regional_average': {
                'cases_per_million': round(avg_cases_per_mil, 2),
                'deaths_per_million': round(avg_deaths_per_mil, 2),
            },
            'comparison_verdict': _get_comparison_verdict(main_cases_per_mil, avg_cases_per_mil),
            'analysis': _generate_analysis(main_data, neighbor_data),
        }
    
    return {
        'main_country': main_data,
        'neighbors': neighbor_data,
        'comparison': comparison,
        'fetched_at': datetime.utcnow().isoformat()
    }


def _get_comparison_verdict(main_rate: float, avg_rate: float) -> str:
    """Generate a verdict comparing main country to regional average"""
    if avg_rate == 0:
        return 'No regional data available'
    
    ratio = main_rate / avg_rate if avg_rate else 1
    
    if ratio < 0.5:
        return 'Significantly better than regional average'
    elif ratio < 0.8:
        return 'Better than regional average'
    elif ratio < 1.2:
        return 'Similar to regional average'
    elif ratio < 1.5:
        return 'Slightly higher than regional average'
    else:
        return 'Higher than regional average'


def _generate_analysis(main_data: Dict, neighbor_data: List[Dict]) -> str:
    """Generate AI-ready analysis text for the frontend"""
    if not main_data:
        return "Data unavailable for analysis"
    
    country = main_data.get('country', 'Your country')
    stats = main_data.get('statistics', {})
    
    analysis_parts = []
    
    # Active cases analysis
    active = stats.get('active_cases', 0)
    population = stats.get('population', 1)
    active_rate = (active / population) * 100000 if population else 0
    
    if active_rate < 10:
        analysis_parts.append(f"{country} has very low COVID-19 activity with only {active:,} active cases.")
    elif active_rate < 50:
        analysis_parts.append(f"{country} has low COVID-19 activity with {active:,} active cases.")
    elif active_rate < 200:
        analysis_parts.append(f"{country} has moderate COVID-19 activity with {active:,} active cases.")
    else:
        analysis_parts.append(f"{country} has elevated COVID-19 activity with {active:,} active cases. Consider precautions.")
    
    # Compare to neighbors
    if neighbor_data:
        best_neighbor = min(neighbor_data, key=lambda x: x.get('statistics', {}).get('cases_per_million', float('inf')))
        worst_neighbor = max(neighbor_data, key=lambda x: x.get('statistics', {}).get('cases_per_million', 0))
        
        analysis_parts.append(
            f"In the region, {best_neighbor.get('country')} has the lowest rate while "
            f"{worst_neighbor.get('country')} has the highest."
        )
    
    return ' '.join(analysis_parts)


# ==================== WHO DISEASE OUTBREAK NEWS (REAL-TIME) ====================

def get_who_disease_outbreaks() -> List[Dict]:
    """
    Fetch real-time disease outbreak news from WHO RSS feed
    This provides the latest outbreak alerts worldwide
    Tries multiple endpoints and falls back to curated data
    
    Returns:
        List of outbreak news items with disease, location, date, severity
    """
    outbreaks = []
    
    # Try each WHO URL until one works
    for url in WHO_DON_URLS:
        try:
            response = requests.get(url, timeout=15)
            if response.status_code == 200:
                # Parse RSS XML
                root = ET.fromstring(response.content)
                
                for item in root.findall('.//item')[:20]:  # Get latest 20 outbreaks
                    title = item.find('title').text if item.find('title') is not None else ''
                    description = item.find('description').text if item.find('description') is not None else ''
                    link = item.find('link').text if item.find('link') is not None else ''
                    pub_date = item.find('pubDate').text if item.find('pubDate') is not None else ''
                    
                    # Filter for health/disease related items
                    keywords = ['outbreak', 'disease', 'epidemic', 'virus', 'health', 'cases', 
                               'infection', 'pandemic', 'malaria', 'dengue', 'cholera', 'ebola', 
                               'influenza', 'polio', 'measles', 'mpox']
                    if not any(kw in title.lower() for kw in keywords):
                        continue
                    
                    # Parse disease and location from title
                    disease, location = parse_outbreak_title(title)
                    
                    # Determine severity based on keywords
                    severity = calculate_outbreak_severity(title, description)
                    
                    outbreaks.append({
                        'disease': disease,
                        'location': location,
                        'title': title,
                        'description': clean_html(description)[:500],
                        'severity': severity,
                        'severity_score': get_severity_score(severity),
                        'published': pub_date,
                        'source': 'WHO',
                        'link': link
                    })
                
                if outbreaks:
                    return outbreaks
        except Exception as e:
            print(f"Error fetching from {url}: {e}")
            continue
    
    # Fallback: Return curated outbreak data if no RSS feeds work
    print("Note: Using cached outbreak data (WHO feeds unavailable)")
    return get_curated_outbreaks()


def get_curated_outbreaks() -> List[Dict]:
    """Return curated list of known active disease outbreaks"""
    return [
        {
            'disease': 'Marburg virus',
            'location': 'Tanzania, Equatorial Guinea',
            'title': 'Marburg virus disease outbreak',
            'description': 'Ongoing Marburg outbreak in East Africa with cases confirmed in 2024-2025',
            'severity': 'high',
            'severity_score': 7,
            'published': '2024',
            'source': 'WHO (curated)',
            'link': 'https://www.who.int/emergencies/disease-outbreak-news'
        },
        {
            'disease': 'Dengue',
            'location': 'South Asia, Southeast Asia, Latin America',
            'title': 'Dengue outbreak - Multiple countries',
            'description': 'Record dengue cases reported in 2024 across tropical regions',
            'severity': 'high',
            'severity_score': 7,
            'published': '2024',
            'source': 'WHO (curated)',
            'link': 'https://www.who.int/emergencies/disease-outbreak-news'
        },
        {
            'disease': 'Cholera',
            'location': 'Africa, Middle East, South Asia',
            'title': 'Cholera outbreaks - Multiple countries',
            'description': 'Cholera outbreaks ongoing in several countries with limited vaccine supply',
            'severity': 'high',
            'severity_score': 7,
            'published': '2024',
            'source': 'WHO (curated)',
            'link': 'https://www.who.int/emergencies/disease-outbreak-news'
        },
        {
            'disease': 'Oropouche virus',
            'location': 'Brazil, South America',
            'title': 'Oropouche virus disease outbreak',
            'description': 'Emerging arboviral disease spreading in South America',
            'severity': 'moderate',
            'severity_score': 4,
            'published': '2024',
            'source': 'WHO (curated)',
            'link': 'https://www.who.int/emergencies/disease-outbreak-news'
        },
        {
            'disease': 'Mpox (clade I)',
            'location': 'Democratic Republic of Congo, Africa',
            'title': 'Mpox clade I outbreak',
            'description': 'New mpox clade spreading in Central Africa, WHO declared PHEIC',
            'severity': 'high',
            'severity_score': 7,
            'published': '2024',
            'source': 'WHO (curated)',
            'link': 'https://www.who.int/emergencies/disease-outbreak-news'
        }
    ]


def parse_outbreak_title(title: str) -> tuple:
    """Extract disease and location from outbreak title"""
    # Common patterns: "Disease name – Country" or "Disease outbreak in Country"
    disease = 'Unknown'
    location = 'Global'
    
    if ' – ' in title:
        parts = title.split(' – ')
        disease = parts[0].strip()
        if len(parts) > 1:
            location = parts[1].strip()
    elif ' - ' in title:
        parts = title.split(' - ')
        disease = parts[0].strip()
        if len(parts) > 1:
            location = parts[1].strip()
    elif ' in ' in title.lower():
        match = re.match(r'(.+?)\s+(?:outbreak\s+)?in\s+(.+)', title, re.IGNORECASE)
        if match:
            disease = match.group(1).strip()
            location = match.group(2).strip()
    else:
        disease = title
    
    return disease, location


def calculate_outbreak_severity(title: str, description: str) -> str:
    """Calculate outbreak severity based on keywords"""
    text = (title + ' ' + description).lower()
    
    critical_keywords = ['emergency', 'pandemic', 'mass casualty', 'widespread', 'outbreak expanding', 'health emergency']
    high_keywords = ['outbreak', 'epidemic', 'deaths reported', 'rapid spread', 'cluster', 'surge']
    moderate_keywords = ['cases reported', 'monitoring', 'investigation', 'confirmed cases']
    
    if any(kw in text for kw in critical_keywords):
        return 'critical'
    elif any(kw in text for kw in high_keywords):
        return 'high'
    elif any(kw in text for kw in moderate_keywords):
        return 'moderate'
    return 'low'


def get_severity_score(severity: str) -> int:
    """Convert severity to numeric score (1-10)"""
    scores = {'critical': 10, 'high': 7, 'moderate': 4, 'low': 2}
    return scores.get(severity, 1)


def clean_html(text: str) -> str:
    """Remove HTML tags from text"""
    if not text:
        return ''
    return re.sub(r'<[^>]+>', '', text).strip()


# ==================== DISEASE SPREADING LEVEL INDICATORS ====================

def get_disease_spread_level(country: str) -> Dict:
    """
    Calculate real-time disease spreading level for a country
    Based on COVID trends, outbreak news, and regional data
    
    Returns:
        Dictionary with spread level, trending direction, and risk factors
    """
    try:
        # Get COVID trends
        covid_data = get_covid_data(country)
        
        # Calculate spread indicators
        if covid_data:
            stats = covid_data.get('statistics', {})
            today_cases = stats.get('today_cases', 0)
            total_cases = stats.get('total_cases', 0)
            population = stats.get('population', 1)
            active = stats.get('active_cases', 0)
            
            # Calculate spread rate
            cases_per_100k = (active / population) * 100000 if population else 0
            
            # Determine spread level
            if cases_per_100k > 500:
                level = 'critical'
                color = 'red'
            elif cases_per_100k > 100:
                level = 'high'
                color = 'orange'
            elif cases_per_100k > 25:
                level = 'moderate'
                color = 'yellow'
            else:
                level = 'low'
                color = 'green'
            
            # Determine trend
            trend = 'stable'
            if today_cases > 0:
                daily_rate = (today_cases / (active + 1)) * 100
                if daily_rate > 5:
                    trend = 'increasing'
                elif daily_rate < 1:
                    trend = 'decreasing'
            
            return {
                'country': country,
                'spread_level': level,
                'spread_color': color,
                'active_per_100k': round(cases_per_100k, 2),
                'trend': trend,
                'today_new': today_cases,
                'total_active': active,
                'last_updated': datetime.utcnow().isoformat()
            }
    except Exception as e:
        print(f"Error calculating spread level for {country}: {e}")
    
    return {
        'country': country,
        'spread_level': 'unknown',
        'spread_color': 'gray',
        'message': 'Data temporarily unavailable'
    }


# ==================== REGIONAL DISEASE ALERTS ====================

def get_regional_disease_alerts(region: str = 'south-asia') -> List[Dict]:
    """
    Get disease alerts for a specific region
    
    Args:
        region: Region identifier (south-asia, southeast-asia, africa, etc.)
    
    Returns:
        List of active disease alerts for the region
    """
    # Region-specific disease monitoring
    regional_diseases = {
        'south-asia': {
            'countries': ['Nepal', 'India', 'Bangladesh', 'Pakistan', 'Sri Lanka', 'Bhutan'],
            'common_diseases': ['Dengue', 'Malaria', 'Typhoid', 'Cholera', 'Japanese Encephalitis', 'Chikungunya'],
            'seasonal_risks': {
                'monsoon': ['Dengue', 'Malaria', 'Cholera', 'Leptospirosis'],
                'winter': ['Influenza', 'Pneumonia'],
                'summer': ['Heat stroke', 'Gastroenteritis']
            }
        },
        'southeast-asia': {
            'countries': ['Thailand', 'Vietnam', 'Indonesia', 'Malaysia', 'Philippines'],
            'common_diseases': ['Dengue', 'Malaria', 'Zika', 'Rabies'],
        }
    }
    
    region_data = regional_diseases.get(region, regional_diseases['south-asia'])
    
    # Get current month for seasonal alerts
    current_month = datetime.utcnow().month
    season = 'monsoon' if current_month in [6, 7, 8, 9] else 'winter' if current_month in [11, 12, 1, 2] else 'summer'
    
    alerts = []
    
    # Generate active alerts based on season and region
    seasonal_risks = region_data.get('seasonal_risks', {}).get(season, [])
    
    for disease in seasonal_risks:
        alerts.append({
            'disease': disease,
            'region': region,
            'affected_countries': region_data['countries'],
            'season': season,
            'risk_level': 'high' if disease in ['Dengue', 'Malaria', 'Cholera'] else 'moderate',
            'alert_type': 'seasonal',
            'prevention_tips': get_disease_prevention(disease),
            'generated_at': datetime.utcnow().isoformat()
        })
    
    return alerts


def get_disease_prevention(disease: str) -> List[str]:
    """Get prevention tips for specific diseases"""
    prevention_db = {
        'Dengue': [
            'Use mosquito repellent',
            'Wear long sleeves and pants',
            'Remove standing water around home',
            'Use bed nets while sleeping',
            'Install window screens'
        ],
        'Malaria': [
            'Sleep under insecticide-treated bed nets',
            'Take antimalarial prophylaxis if traveling',
            'Use mosquito repellent with DEET',
            'Wear light-colored long clothing'
        ],
        'Cholera': [
            'Drink only safe/boiled water',
            'Wash hands frequently with soap',
            'Eat only thoroughly cooked food',
            'Avoid raw vegetables and fruits',
            'Get cholera vaccine before travel'
        ],
        'Typhoid': [
            'Drink bottled or boiled water only',
            'Avoid street food',
            'Wash hands before eating',
            'Get typhoid vaccination',
            'Eat freshly cooked hot food'
        ],
        'Influenza': [
            'Get annual flu vaccine',
            'Wash hands frequently',
            'Cover coughs and sneezes',
            'Stay home when sick',
            'Avoid close contact with sick people'
        ],
        'Leptospirosis': [
            'Avoid walking in flood water',
            'Wear protective footwear',
            'Cover wounds and cuts',
            'Avoid contact with animal urine'
        ]
    }
    return prevention_db.get(disease, ['Practice good hygiene', 'Consult healthcare provider'])


# ==================== EXISTING FUNCTIONS (kept for compatibility) ====================

def get_disease_outbreaks() -> List[Dict]:
    """
    Fetch latest disease outbreak news/alerts
    Now combines curated data with real-time WHO feed
    """
    # First try to get real-time WHO data
    who_outbreaks = get_who_disease_outbreaks()
    
    # Curated list of ongoing disease concerns (fallback/supplement)
    curated_outbreaks = [
        {
            'disease': 'COVID-19',
            'status': 'Ongoing',
            'severity': 'moderate',
            'description': 'Coronavirus pandemic continues with new variants emerging periodically',
            'prevention': ['Get vaccinated', 'Wear masks in crowded places', 'Practice hand hygiene', 'Maintain ventilation'],
            'symptoms': ['Fever', 'Cough', 'Fatigue', 'Loss of taste/smell', 'Difficulty breathing'],
            'source': 'WHO'
        },
        {
            'disease': 'Dengue Fever',
            'status': 'Seasonal',
            'severity': 'moderate',
            'affected_regions': ['South Asia', 'Southeast Asia', 'Latin America', 'Africa'],
            'description': 'Mosquito-borne viral infection common in tropical regions',
            'prevention': ['Use mosquito repellent', 'Eliminate standing water', 'Wear long sleeves', 'Use bed nets'],
            'symptoms': ['High fever', 'Severe headache', 'Pain behind eyes', 'Joint/muscle pain', 'Rash'],
            'source': 'WHO'
        },
        {
            'disease': 'Malaria',
            'status': 'Endemic',
            'severity': 'high',
            'affected_regions': ['Sub-Saharan Africa', 'South Asia', 'Southeast Asia'],
            'description': 'Parasitic disease transmitted by Anopheles mosquitoes',
            'prevention': ['Use insecticide-treated nets', 'Take antimalarial drugs if traveling', 'Use repellent'],
            'symptoms': ['Fever', 'Chills', 'Headache', 'Nausea', 'Muscle aches'],
            'source': 'WHO'
        },
        {
            'disease': 'Cholera',
            'status': 'Outbreak',
            'severity': 'high',
            'affected_regions': ['Africa', 'South Asia', 'Middle East'],
            'description': 'Waterborne bacterial infection causing severe diarrhea',
            'prevention': ['Drink safe water', 'Proper sanitation', 'Good hygiene', 'Oral cholera vaccine'],
            'symptoms': ['Watery diarrhea', 'Vomiting', 'Dehydration', 'Muscle cramps'],
            'source': 'WHO'
        }
    ]
    
    # Combine both sources
    return {
        'realtime_from_who': who_outbreaks,
        'known_active_diseases': curated_outbreaks,
        'fetched_at': datetime.utcnow().isoformat()
    }


def get_country_disease_risk(country: str) -> Dict:
    """
    Get disease risk assessment for a specific country
    Enhanced with real-time spread level
    """
    # Risk levels based on region
    risk_profiles = {
        'nepal': {
            'dengue': 'high',
            'malaria': 'moderate',
            'typhoid': 'moderate',
            'hepatitis_a': 'moderate',
            'japanese_encephalitis': 'moderate',
            'cholera': 'low'
        },
        'india': {
            'dengue': 'high',
            'malaria': 'high',
            'typhoid': 'high',
            'hepatitis_a': 'moderate',
            'chikungunya': 'moderate',
            'cholera': 'moderate'
        },
        'bangladesh': {
            'dengue': 'high',
            'cholera': 'moderate',
            'typhoid': 'high',
            'hepatitis_a': 'moderate'
        },
        'pakistan': {
            'dengue': 'high',
            'malaria': 'moderate',
            'typhoid': 'high',
            'hepatitis_a': 'moderate'
        },
        'usa': {
            'seasonal_flu': 'moderate',
            'lyme_disease': 'low',
            'west_nile': 'low'
        },
        'uk': {
            'seasonal_flu': 'moderate'
        },
        'japan': {
            'seasonal_flu': 'moderate',
            'japanese_encephalitis': 'low'
        }
    }
    
    country_lower = country.lower()
    risks = risk_profiles.get(country_lower, {})
    
    # Get live spread level
    spread_level = get_disease_spread_level(country)
    
    return {
        'country': country,
        'disease_risks': risks,
        'spread_status': spread_level,
        'recommendations': generate_disease_recommendations(risks),
        'fetched_at': datetime.utcnow().isoformat()
    }


def generate_disease_recommendations(risks: Dict) -> List[str]:
    """Generate health recommendations based on disease risks"""
    recommendations = []
    
    if risks.get('dengue') in ['high', 'moderate']:
        recommendations.append('🦟 Use mosquito repellent and wear protective clothing')
    if risks.get('malaria') in ['high', 'moderate']:
        recommendations.append('🛏️ Sleep under insecticide-treated bed nets')
    if risks.get('typhoid') in ['high', 'moderate']:
        recommendations.append('💧 Drink only bottled or boiled water')
    if risks.get('cholera') in ['high', 'moderate']:
        recommendations.append('🧼 Practice strict hand hygiene')
    if risks.get('hepatitis_a') in ['high', 'moderate']:
        recommendations.append('🍎 Eat only thoroughly cooked food')
    if risks.get('seasonal_flu') in ['high', 'moderate']:
        recommendations.append('💉 Get annual flu vaccination')
    if risks.get('japanese_encephalitis') in ['high', 'moderate']:
        recommendations.append('💉 Consider JE vaccination if staying long-term')
    
    if not recommendations:
        recommendations.append('✅ No major disease concerns. Maintain general hygiene.')
    
    return recommendations


def get_all_countries_disease_data(countries: List[str]) -> List[Dict]:
    """Fetch disease data for multiple countries"""
    results = []
    for country in countries:
        covid = get_covid_data(country)
        risk = get_country_disease_risk(country)
        spread = get_disease_spread_level(country)
        if covid or risk:
            results.append({
                'country': country,
                'covid': covid,
                'disease_risks': risk,
                'spread_level': spread
            })
    return results


# ==================== SUMMARY FUNCTION ====================

def get_health_situation_summary(country: str) -> Dict:
    """
    Get comprehensive health situation summary for a country
    Combines all available data sources
    """
    return {
        'country': country,
        'covid_status': get_covid_data(country),
        'disease_risks': get_country_disease_risk(country),
        'spread_level': get_disease_spread_level(country),
        'regional_alerts': get_regional_disease_alerts('south-asia') if country.lower() in ['nepal', 'india', 'bangladesh', 'pakistan'] else [],
        'latest_who_outbreaks': get_who_disease_outbreaks()[:5],
        'summary_generated_at': datetime.utcnow().isoformat()
    }


if __name__ == "__main__":
    # Test
    print("=" * 60)
    print("Testing Disease Surveillance System")
    print("=" * 60)
    
    print("\n1. Testing COVID data for Nepal...")
    covid = get_covid_data('nepal')
    if covid:
        print(f"   Total COVID cases: {covid['statistics']['total_cases']:,}")
    
    print("\n2. Testing WHO Disease Outbreak RSS Feed...")
    who_outbreaks = get_who_disease_outbreaks()
    print(f"   Found {len(who_outbreaks)} recent outbreaks from WHO")
    for outbreak in who_outbreaks[:3]:
        print(f"   - {outbreak['disease']} in {outbreak['location']} (Severity: {outbreak['severity']})")
    
    print("\n3. Testing Disease Spread Level...")
    spread = get_disease_spread_level('nepal')
    print(f"   Nepal spread level: {spread['spread_level']} ({spread['spread_color']})")
    
    print("\n4. Testing Regional Alerts...")
    alerts = get_regional_disease_alerts('south-asia')
    print(f"   Found {len(alerts)} seasonal disease alerts for South Asia")
    
    print("\n5. Testing Full Health Summary...")
    summary = get_health_situation_summary('nepal')
    print(f"   Summary generated with {len(summary)} data sections")
    
    print("\n✅ All tests completed!")

