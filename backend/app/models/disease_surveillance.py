"""
Disease Surveillance Database Models
Stores historical disease outbreak data for future reference and analysis
"""

from datetime import datetime, timezone
from app import db


class DiseaseOutbreak(db.Model):
    """
    Stores disease outbreak records from WHO and other sources
    Tracks outbreaks over time for historical analysis
    """
    __tablename__ = 'disease_outbreaks'
    
    id = db.Column(db.Integer, primary_key=True)
    disease_name = db.Column(db.String(255), nullable=False, index=True)
    location = db.Column(db.String(255), nullable=False, index=True)
    country = db.Column(db.String(100), index=True)
    region = db.Column(db.String(100))
    
    # Outbreak details
    title = db.Column(db.Text)
    description = db.Column(db.Text)
    severity = db.Column(db.Enum('low', 'moderate', 'high', 'critical'), nullable=False, index=True)
    severity_score = db.Column(db.Integer, default=1)  # 1-10 scale
    status = db.Column(db.Enum('active', 'monitoring', 'contained', 'ended'), default='active')
    
    # Case statistics
    confirmed_cases = db.Column(db.Integer, default=0)
    deaths = db.Column(db.Integer, default=0)
    recovered = db.Column(db.Integer, default=0)
    
    # Source info
    source = db.Column(db.String(100))  # WHO, CDC, local health ministry
    source_url = db.Column(db.Text)
    published_at = db.Column(db.DateTime)
    
    # Prevention and symptoms (JSON arrays)
    prevention_tips = db.Column(db.JSON)
    symptoms = db.Column(db.JSON)
    
    # Metadata
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    def to_dict(self):
        return {
            'id': self.id,
            'disease_name': self.disease_name,
            'location': self.location,
            'country': self.country,
            'region': self.region,
            'title': self.title,
            'description': self.description,
            'severity': self.severity,
            'severity_score': self.severity_score,
            'status': self.status,
            'confirmed_cases': self.confirmed_cases,
            'deaths': self.deaths,
            'recovered': self.recovered,
            'source': self.source,
            'source_url': self.source_url,
            'published_at': self.published_at.isoformat() if self.published_at else None,
            'prevention_tips': self.prevention_tips or [],
            'symptoms': self.symptoms or [],
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class CovidRecord(db.Model):
    """
    Stores daily COVID-19 statistics for countries
    Historical data for trend analysis
    """
    __tablename__ = 'covid_records'
    
    id = db.Column(db.Integer, primary_key=True)
    country = db.Column(db.String(100), nullable=False, index=True)
    country_code = db.Column(db.String(3))
    record_date = db.Column(db.Date, nullable=False, index=True)
    
    # Statistics
    total_cases = db.Column(db.BigInteger, default=0)
    new_cases = db.Column(db.Integer, default=0)
    total_deaths = db.Column(db.BigInteger, default=0)
    new_deaths = db.Column(db.Integer, default=0)
    recovered = db.Column(db.BigInteger, default=0)
    active_cases = db.Column(db.BigInteger, default=0)
    critical_cases = db.Column(db.Integer, default=0)
    
    # Per million stats
    cases_per_million = db.Column(db.Numeric(12, 2), default=0)
    deaths_per_million = db.Column(db.Numeric(12, 2), default=0)
    tests_per_million = db.Column(db.Numeric(12, 2), default=0)
    
    # Metadata
    population = db.Column(db.BigInteger)
    source = db.Column(db.String(100), default='disease.sh')
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    
    # Unique constraint: one record per country per day
    __table_args__ = (
        db.UniqueConstraint('country', 'record_date', name='unique_country_date'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'country': self.country,
            'country_code': self.country_code,
            'record_date': self.record_date.isoformat() if self.record_date else None,
            'statistics': {
                'total_cases': self.total_cases,
                'new_cases': self.new_cases,
                'total_deaths': self.total_deaths,
                'new_deaths': self.new_deaths,
                'recovered': self.recovered,
                'active_cases': self.active_cases,
                'critical_cases': self.critical_cases,
                'cases_per_million': float(self.cases_per_million) if self.cases_per_million else 0,
                'deaths_per_million': float(self.deaths_per_million) if self.deaths_per_million else 0,
            },
            'population': self.population,
            'source': self.source
        }


class DiseaseSpreadLevel(db.Model):
    """
    Tracks disease spread level for countries over time
    Used for trend analysis and historical comparison
    """
    __tablename__ = 'disease_spread_levels'
    
    id = db.Column(db.Integer, primary_key=True)
    country = db.Column(db.String(100), nullable=False, index=True)
    record_date = db.Column(db.Date, nullable=False, index=True)
    
    # Spread indicators
    spread_level = db.Column(db.Enum('low', 'moderate', 'high', 'critical', 'unknown'), default='unknown')
    spread_color = db.Column(db.String(20))  # green, yellow, orange, red, gray
    active_per_100k = db.Column(db.Numeric(10, 2), default=0)
    trend = db.Column(db.Enum('increasing', 'decreasing', 'stable'), default='stable')
    
    # Raw data
    today_new_cases = db.Column(db.Integer, default=0)
    total_active = db.Column(db.Integer, default=0)
    
    # Metadata
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    
    # Unique constraint
    __table_args__ = (
        db.UniqueConstraint('country', 'record_date', name='unique_spread_country_date'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'country': self.country,
            'record_date': self.record_date.isoformat() if self.record_date else None,
            'spread_level': self.spread_level,
            'spread_color': self.spread_color,
            'active_per_100k': float(self.active_per_100k) if self.active_per_100k else 0,
            'trend': self.trend,
            'today_new_cases': self.today_new_cases,
            'total_active': self.total_active
        }


class RegionalDiseaseAlert(db.Model):
    """
    Stores regional disease alerts based on seasonal and environmental factors
    """
    __tablename__ = 'regional_disease_alerts'
    
    id = db.Column(db.Integer, primary_key=True)
    region = db.Column(db.String(100), nullable=False, index=True)  # south-asia, southeast-asia, etc
    disease = db.Column(db.String(255), nullable=False, index=True)
    season = db.Column(db.Enum('monsoon', 'winter', 'summer', 'year_round'), nullable=False)
    
    # Alert details
    risk_level = db.Column(db.Enum('low', 'moderate', 'high', 'critical'), default='moderate')
    alert_type = db.Column(db.String(50))  # seasonal, outbreak, endemic
    affected_countries = db.Column(db.JSON)  # List of countries
    
    # Prevention
    prevention_tips = db.Column(db.JSON)
    
    # Validity
    valid_from = db.Column(db.Date)
    valid_until = db.Column(db.Date)
    is_active = db.Column(db.Boolean, default=True)
    
    # Metadata
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    def to_dict(self):
        return {
            'id': self.id,
            'region': self.region,
            'disease': self.disease,
            'season': self.season,
            'risk_level': self.risk_level,
            'alert_type': self.alert_type,
            'affected_countries': self.affected_countries or [],
            'prevention_tips': self.prevention_tips or [],
            'valid_from': self.valid_from.isoformat() if self.valid_from else None,
            'valid_until': self.valid_until.isoformat() if self.valid_until else None,
            'is_active': self.is_active
        }


class CountryDiseaseRisk(db.Model):
    """
    Stores disease risk profiles for countries
    Updated periodically based on current conditions
    """
    __tablename__ = 'country_disease_risks'
    
    id = db.Column(db.Integer, primary_key=True)
    country = db.Column(db.String(100), nullable=False, index=True)
    disease = db.Column(db.String(255), nullable=False, index=True)
    risk_level = db.Column(db.Enum('low', 'moderate', 'high', 'critical'), nullable=False)
    
    # Additional info
    description = db.Column(db.Text)
    prevention_tips = db.Column(db.JSON)
    vaccination_recommended = db.Column(db.Boolean, default=False)
    
    # Validity
    effective_date = db.Column(db.Date)
    is_active = db.Column(db.Boolean, default=True)
    
    # Metadata
    source = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Unique constraint: one risk level per country-disease pair
    __table_args__ = (
        db.UniqueConstraint('country', 'disease', name='unique_country_disease'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'country': self.country,
            'disease': self.disease,
            'risk_level': self.risk_level,
            'description': self.description,
            'prevention_tips': self.prevention_tips or [],
            'vaccination_recommended': self.vaccination_recommended,
            'effective_date': self.effective_date.isoformat() if self.effective_date else None,
            'is_active': self.is_active,
            'source': self.source
        }


class HealthDataFetchLog(db.Model):
    """
    Logs data fetch operations for monitoring and debugging
    """
    __tablename__ = 'health_data_fetch_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    fetch_type = db.Column(db.String(50), nullable=False)  # covid, outbreak, weather, etc
    country = db.Column(db.String(100))
    status = db.Column(db.Enum('success', 'failed', 'partial'), nullable=False)
    records_fetched = db.Column(db.Integer, default=0)
    error_message = db.Column(db.Text)
    duration_ms = db.Column(db.Integer)  # Fetch duration in milliseconds
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    
    def to_dict(self):
        return {
            'id': self.id,
            'fetch_type': self.fetch_type,
            'country': self.country,
            'status': self.status,
            'records_fetched': self.records_fetched,
            'error_message': self.error_message,
            'duration_ms': self.duration_ms,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
