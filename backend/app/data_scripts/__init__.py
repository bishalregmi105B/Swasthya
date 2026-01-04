"""
Data Scripts Package
Health data fetching scripts for weather, disease, earthquake, and climate data
"""

from .weather_data import get_weather_data, get_all_countries_weather
from .disease_data import get_covid_data, get_disease_outbreaks, get_country_disease_risk
from .earthquake_data import get_earthquakes, get_country_earthquake_summary
from .climate_data import get_air_quality_data, get_all_countries_air_quality

__all__ = [
    'get_weather_data',
    'get_all_countries_weather',
    'get_covid_data',
    'get_disease_outbreaks',
    'get_country_disease_risk',
    'get_earthquakes',
    'get_country_earthquake_summary',
    'get_air_quality_data',
    'get_all_countries_air_quality',
]
