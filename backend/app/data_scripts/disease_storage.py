"""
Disease Data Storage Service
Saves fetched disease data to database for historical tracking
"""

from datetime import date, datetime, timezone
from typing import Dict, List, Optional
import time

from app import db
from app.models.disease_surveillance import (
    DiseaseOutbreak, CovidRecord, DiseaseSpreadLevel,
    RegionalDiseaseAlert, CountryDiseaseRisk, HealthDataFetchLog
)


def save_covid_record(country: str, covid_data: Dict) -> Optional[CovidRecord]:
    """
    Save COVID statistics for a country
    Updates existing record for today or creates new one
    """
    if not covid_data:
        return None
    
    try:
        today = date.today()
        stats = covid_data.get('statistics', {})
        
        # Check if record exists for today
        existing = CovidRecord.query.filter_by(
            country=country,
            record_date=today
        ).first()
        
        if existing:
            # Update existing record
            existing.total_cases = stats.get('total_cases', 0)
            existing.new_cases = stats.get('today_cases', 0)
            existing.total_deaths = stats.get('total_deaths', 0)
            existing.new_deaths = stats.get('today_deaths', 0)
            existing.recovered = stats.get('recovered', 0)
            existing.active_cases = stats.get('active_cases', 0)
            existing.critical_cases = stats.get('critical', 0)
            existing.cases_per_million = stats.get('cases_per_million', 0)
            existing.deaths_per_million = stats.get('deaths_per_million', 0)
            existing.tests_per_million = stats.get('tests_per_million', 0)
            existing.population = stats.get('population')
            record = existing
        else:
            # Create new record
            record = CovidRecord(
                country=country,
                country_code=covid_data.get('country_code'),
                record_date=today,
                total_cases=stats.get('total_cases', 0),
                new_cases=stats.get('today_cases', 0),
                total_deaths=stats.get('total_deaths', 0),
                new_deaths=stats.get('today_deaths', 0),
                recovered=stats.get('recovered', 0),
                active_cases=stats.get('active_cases', 0),
                critical_cases=stats.get('critical', 0),
                cases_per_million=stats.get('cases_per_million', 0),
                deaths_per_million=stats.get('deaths_per_million', 0),
                tests_per_million=stats.get('tests_per_million', 0),
                population=stats.get('population'),
                source='disease.sh'
            )
            db.session.add(record)
        
        db.session.commit()
        return record
    except Exception as e:
        db.session.rollback()
        print(f"Error saving COVID record for {country}: {e}")
        return None


def save_disease_outbreak(outbreak_data: Dict) -> Optional[DiseaseOutbreak]:
    """
    Save a disease outbreak record
    Checks for duplicates based on disease + location + date
    """
    try:
        disease = outbreak_data.get('disease', 'Unknown')
        location = outbreak_data.get('location', 'Global')
        
        # Check for existing (avoid duplicates)
        existing = DiseaseOutbreak.query.filter_by(
            disease_name=disease,
            location=location,
            is_active=True
        ).first()
        
        if existing:
            # Update existing outbreak
            existing.severity = outbreak_data.get('severity', 'moderate')
            existing.severity_score = outbreak_data.get('severity_score', 4)
            existing.description = outbreak_data.get('description')
            existing.source_url = outbreak_data.get('link')
            existing.updated_at = datetime.now(timezone.utc)
            record = existing
        else:
            # Create new outbreak
            record = DiseaseOutbreak(
                disease_name=disease,
                location=location,
                title=outbreak_data.get('title'),
                description=outbreak_data.get('description'),
                severity=outbreak_data.get('severity', 'moderate'),
                severity_score=outbreak_data.get('severity_score', 4),
                source=outbreak_data.get('source', 'WHO'),
                source_url=outbreak_data.get('link'),
                prevention_tips=outbreak_data.get('prevention'),
                symptoms=outbreak_data.get('symptoms')
            )
            db.session.add(record)
        
        db.session.commit()
        return record
    except Exception as e:
        db.session.rollback()
        print(f"Error saving outbreak: {e}")
        return None


def save_spread_level(country: str, spread_data: Dict) -> Optional[DiseaseSpreadLevel]:
    """
    Save disease spread level for a country
    Creates daily record for trend tracking
    """
    if not spread_data or spread_data.get('spread_level') == 'unknown':
        return None
    
    try:
        today = date.today()
        
        # Check for existing today's record
        existing = DiseaseSpreadLevel.query.filter_by(
            country=country,
            record_date=today
        ).first()
        
        if existing:
            existing.spread_level = spread_data.get('spread_level')
            existing.spread_color = spread_data.get('spread_color')
            existing.active_per_100k = spread_data.get('active_per_100k', 0)
            existing.trend = spread_data.get('trend', 'stable')
            existing.today_new_cases = spread_data.get('today_new', 0)
            existing.total_active = spread_data.get('total_active', 0)
            record = existing
        else:
            record = DiseaseSpreadLevel(
                country=country,
                record_date=today,
                spread_level=spread_data.get('spread_level'),
                spread_color=spread_data.get('spread_color'),
                active_per_100k=spread_data.get('active_per_100k', 0),
                trend=spread_data.get('trend', 'stable'),
                today_new_cases=spread_data.get('today_new', 0),
                total_active=spread_data.get('total_active', 0)
            )
            db.session.add(record)
        
        db.session.commit()
        return record
    except Exception as e:
        db.session.rollback()
        print(f"Error saving spread level for {country}: {e}")
        return None


def save_regional_alert(alert_data: Dict) -> Optional[RegionalDiseaseAlert]:
    """Save or update regional disease alert"""
    try:
        region = alert_data.get('region', 'south-asia')
        disease = alert_data.get('disease')
        season = alert_data.get('season', 'year_round')
        
        existing = RegionalDiseaseAlert.query.filter_by(
            region=region,
            disease=disease,
            season=season,
            is_active=True
        ).first()
        
        if existing:
            existing.risk_level = alert_data.get('risk_level', 'moderate')
            existing.prevention_tips = alert_data.get('prevention_tips', [])
            existing.affected_countries = alert_data.get('affected_countries', [])
            existing.updated_at = datetime.now(timezone.utc)
            record = existing
        else:
            record = RegionalDiseaseAlert(
                region=region,
                disease=disease,
                season=season,
                risk_level=alert_data.get('risk_level', 'moderate'),
                alert_type=alert_data.get('alert_type', 'seasonal'),
                affected_countries=alert_data.get('affected_countries', []),
                prevention_tips=alert_data.get('prevention_tips', [])
            )
            db.session.add(record)
        
        db.session.commit()
        return record
    except Exception as e:
        db.session.rollback()
        print(f"Error saving regional alert: {e}")
        return None


def save_country_disease_risk(country: str, disease: str, risk_data: Dict) -> Optional[CountryDiseaseRisk]:
    """Save disease risk for a country"""
    try:
        existing = CountryDiseaseRisk.query.filter_by(
            country=country,
            disease=disease
        ).first()
        
        if existing:
            existing.risk_level = risk_data.get('risk_level', 'low')
            existing.updated_at = datetime.now(timezone.utc)
            record = existing
        else:
            record = CountryDiseaseRisk(
                country=country,
                disease=disease,
                risk_level=risk_data.get('risk_level', 'low'),
                prevention_tips=risk_data.get('prevention_tips', []),
                vaccination_recommended=risk_data.get('vaccination_recommended', False),
                source=risk_data.get('source', 'WHO')
            )
            db.session.add(record)
        
        db.session.commit()
        return record
    except Exception as e:
        db.session.rollback()
        print(f"Error saving disease risk for {country}/{disease}: {e}")
        return None


def log_fetch_operation(fetch_type: str, country: str = None, status: str = 'success', 
                        records: int = 0, error: str = None, duration_ms: int = None):
    """Log a data fetch operation"""
    try:
        log = HealthDataFetchLog(
            fetch_type=fetch_type,
            country=country,
            status=status,
            records_fetched=records,
            error_message=error,
            duration_ms=duration_ms
        )
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        print(f"Error logging fetch operation: {e}")


# ==================== BULK OPERATIONS ====================

def save_all_disease_data(countries: List[str]):
    """
    Fetch and save all disease data for given countries
    Main entry point for cron job
    """
    from app.data_scripts.disease_data import (
        get_covid_data, get_disease_spread_level, 
        get_who_disease_outbreaks, get_regional_disease_alerts,
        get_country_disease_risk
    )
    
    results = {
        'covid_records': 0,
        'spread_levels': 0,
        'outbreaks': 0,
        'regional_alerts': 0,
        'risks': 0
    }
    
    # 1. Save COVID data for each country
    for country in countries:
        start = time.time()
        try:
            covid_data = get_covid_data(country)
            if covid_data:
                save_covid_record(country, covid_data)
                results['covid_records'] += 1
            
            # Save spread level
            spread_data = get_disease_spread_level(country)
            if spread_data:
                save_spread_level(country, spread_data)
                results['spread_levels'] += 1
            
            # Save disease risks
            risk_data = get_country_disease_risk(country)
            if risk_data and 'disease_risks' in risk_data:
                for disease, level in risk_data['disease_risks'].items():
                    save_country_disease_risk(country, disease, {'risk_level': level})
                    results['risks'] += 1
            
            duration = int((time.time() - start) * 1000)
            log_fetch_operation('country_data', country, 'success', 1, duration_ms=duration)
        except Exception as e:
            log_fetch_operation('country_data', country, 'failed', error=str(e))
    
    # 2. Save WHO outbreaks
    try:
        outbreaks = get_who_disease_outbreaks()
        for outbreak in outbreaks:
            save_disease_outbreak(outbreak)
            results['outbreaks'] += 1
        log_fetch_operation('who_outbreaks', status='success', records=len(outbreaks))
    except Exception as e:
        log_fetch_operation('who_outbreaks', status='failed', error=str(e))
    
    # 3. Save regional alerts
    try:
        for region in ['south-asia', 'southeast-asia']:
            alerts = get_regional_disease_alerts(region)
            for alert in alerts:
                save_regional_alert(alert)
                results['regional_alerts'] += 1
        log_fetch_operation('regional_alerts', status='success', records=results['regional_alerts'])
    except Exception as e:
        log_fetch_operation('regional_alerts', status='failed', error=str(e))
    
    return results


# ==================== QUERY FUNCTIONS ====================

def get_historical_covid_data(country: str, days: int = 30) -> List[Dict]:
    """Get historical COVID data for a country"""
    records = CovidRecord.query.filter_by(country=country)\
        .order_by(CovidRecord.record_date.desc())\
        .limit(days)\
        .all()
    return [r.to_dict() for r in records]


def get_historical_spread_levels(country: str, days: int = 30) -> List[Dict]:
    """Get historical spread levels for trend analysis"""
    records = DiseaseSpreadLevel.query.filter_by(country=country)\
        .order_by(DiseaseSpreadLevel.record_date.desc())\
        .limit(days)\
        .all()
    return [r.to_dict() for r in records]


def get_active_outbreaks(severity: str = None) -> List[Dict]:
    """Get all active disease outbreaks"""
    query = DiseaseOutbreak.query.filter_by(is_active=True)
    if severity:
        query = query.filter_by(severity=severity)
    outbreaks = query.order_by(DiseaseOutbreak.updated_at.desc()).all()
    return [o.to_dict() for o in outbreaks]


def get_country_risks(country: str) -> List[Dict]:
    """Get all disease risks for a country"""
    risks = CountryDiseaseRisk.query.filter_by(
        country=country,
        is_active=True
    ).all()
    return [r.to_dict() for r in risks]
