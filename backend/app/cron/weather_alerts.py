"""
Weather Alert Cron Handler
Fetches weather data using Open-Meteo API (free, no API key needed) 
and sends alerts for extreme conditions
"""

from datetime import datetime, timedelta
import os
import requests
from .base import BaseCronHandler


class WeatherAlertHandler(BaseCronHandler):
    """Handles fetching weather data and sending alerts for extreme conditions"""
    
    name = "WeatherAlertHandler"
    
    # Open-Meteo API (free, no API key required)
    OPEN_METEO_URL = 'https://api.open-meteo.com/v1/forecast'
    AIR_QUALITY_URL = 'https://air-quality-api.open-meteo.com/v1/air-quality'
    
    # Alert thresholds
    TEMP_HIGH_THRESHOLD = float(os.getenv('WEATHER_TEMP_HIGH', '35'))  # Celsius
    TEMP_LOW_THRESHOLD = float(os.getenv('WEATHER_TEMP_LOW', '5'))  # Celsius
    AQI_THRESHOLD = int(os.getenv('WEATHER_AQI_THRESHOLD', '150'))  # PM2.5 threshold
    HUMIDITY_HIGH_THRESHOLD = float(os.getenv('WEATHER_HUMIDITY_HIGH', '85'))
    
    # Major cities in Nepal to monitor
    MONITORED_CITIES = [
        {'name': 'Kathmandu', 'lat': 27.7172, 'lon': 85.3240},
        {'name': 'Pokhara', 'lat': 28.2096, 'lon': 83.9856},
        {'name': 'Biratnagar', 'lat': 26.4525, 'lon': 87.2718},
        {'name': 'Lalitpur', 'lat': 27.6644, 'lon': 85.3188},
        {'name': 'Bharatpur', 'lat': 27.6833, 'lon': 84.4333},
        {'name': 'Birgunj', 'lat': 27.0104, 'lon': 84.8821},
    ]
    
    # Cache to prevent repeated alerts
    _last_alerts = {}
    
    def execute(self, dry_run: bool = False):
        """
        Check weather conditions and send alerts for extreme conditions
        """
        from app import db
        from app.models.user import User
        from app.routes.notifications import send_onesignal_notification
        
        for city in self.MONITORED_CITIES:
            try:
                # Fetch weather data from Open-Meteo (no API key needed!)
                weather_data = self._fetch_weather(city['lat'], city['lon'])
                
                if not weather_data:
                    self.log_failed(f"Failed to fetch weather for {city['name']}")
                    continue
                
                # Check for extreme conditions
                alerts = self._check_conditions(weather_data, city['name'])
                
                if not alerts:
                    self.log_skipped(f"{city['name']}: Weather normal")
                    continue
                
                # Check if we've already sent these alerts recently
                cache_key = f"{city['name']}_{','.join([a['type'] for a in alerts])}"
                if self._was_alert_sent_recently(cache_key):
                    self.log_skipped(f"{city['name']}: Alerts already sent recently")
                    continue
                
                # Find users in this city
                users = User.query.filter(
                    User.is_active == True,
                    User.notification_push == True,
                    User.city.ilike(f'%{city["name"]}%')
                ).all()
                
                if not users:
                    self.log_skipped(f"{city['name']}: No users to notify")
                    continue
                
                # Build and send notification
                for alert in alerts:
                    if dry_run:
                        self.logger.info(
                            f"[DRY RUN] Would send {alert['type']} alert to "
                            f"{len(users)} users in {city['name']}"
                        )
                        self.log_success(f"[DRY RUN] {city['name']} - {alert['type']}")
                    else:
                        user_ids = [str(u.id) for u in users]
                        
                        result = send_onesignal_notification(
                            title=alert['title'],
                            message=alert['message'],
                            user_ids=user_ids,
                            data={
                                'type': 'weather_alert',
                                'alert_type': alert['type'],
                                'city': city['name'],
                                'value': str(alert['value'])
                            }
                        )
                        
                        if 'id' in result or 'recipients' in result:
                            self.log_success(
                                f"Sent {alert['type']} alert to {len(users)} users in {city['name']}"
                            )
                            self._mark_alert_sent(cache_key)
                        else:
                            self.log_failed(
                                f"Failed to send {alert['type']} alert for {city['name']}",
                                error=str(result.get('errors', result))
                            )
            
            except Exception as e:
                self.log_failed(f"Error processing {city['name']}", error=str(e))
    
    def _fetch_weather(self, lat: float, lon: float) -> dict:
        """Fetch weather data from Open-Meteo API (free, no API key)"""
        try:
            # Fetch current weather
            params = {
                'latitude': lat,
                'longitude': lon,
                'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
                'timezone': 'auto'
            }
            
            response = requests.get(self.OPEN_METEO_URL, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                current = data.get('current', {})
                
                # Fetch air quality data
                try:
                    aqi_response = requests.get(self.AIR_QUALITY_URL, params={
                        'latitude': lat,
                        'longitude': lon,
                        'current': 'pm2_5,pm10,us_aqi'
                    }, timeout=10)
                    
                    if aqi_response.status_code == 200:
                        aqi_data = aqi_response.json()
                        aqi_current = aqi_data.get('current', {})
                        data['pm2_5'] = aqi_current.get('pm2_5', 0)
                        data['pm10'] = aqi_current.get('pm10', 0)
                        data['aqi'] = aqi_current.get('us_aqi', 0)
                except Exception as e:
                    self.logger.warning(f"AQI fetch failed: {e}")
                    data['pm2_5'] = 0
                    data['aqi'] = 0
                
                return data
            else:
                self.logger.error(f"Weather API error: {response.status_code}")
                return None
                
        except Exception as e:
            self.logger.error(f"Weather fetch error: {e}")
            return None
    
    def _check_conditions(self, weather_data: dict, city_name: str) -> list:
        """Check weather data for extreme conditions"""
        alerts = []
        
        current = weather_data.get('current', {})
        temp = current.get('temperature_2m', 0)
        humidity = current.get('relative_humidity_2m', 0)
        weather_code = current.get('weather_code', 0)
        pm2_5 = weather_data.get('pm2_5', 0)
        aqi = weather_data.get('aqi', 0)
        
        # Weather code descriptions
        weather_codes = {
            0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
            45: 'Fog', 48: 'Rime fog', 51: 'Light drizzle', 53: 'Drizzle', 55: 'Dense drizzle',
            61: 'Slight rain', 63: 'Moderate rain', 65: 'Heavy rain',
            71: 'Slight snow', 73: 'Moderate snow', 75: 'Heavy snow',
            80: 'Slight rain showers', 81: 'Moderate showers', 82: 'Violent showers',
            95: 'Thunderstorm', 96: 'Thunderstorm with hail', 99: 'Severe thunderstorm'
        }
        weather_desc = weather_codes.get(weather_code, 'Unknown')
        
        # High temperature alert
        if temp >= self.TEMP_HIGH_THRESHOLD:
            alerts.append({
                'type': 'heat_warning',
                'title': '🌡️ Heat Warning',
                'message': f"High temperature of {temp:.1f}°C in {city_name}. "
                           f"Stay hydrated and avoid sun exposure.",
                'value': temp
            })
        
        # Low temperature alert
        elif temp <= self.TEMP_LOW_THRESHOLD:
            alerts.append({
                'type': 'cold_warning',
                'title': '❄️ Cold Warning',
                'message': f"Low temperature of {temp:.1f}°C in {city_name}. "
                           f"Dress warmly and protect from hypothermia.",
                'value': temp
            })
        
        # High humidity (could indicate heavy rain)
        if humidity >= self.HUMIDITY_HIGH_THRESHOLD:
            alerts.append({
                'type': 'humidity_warning',
                'title': '💧 High Humidity Alert',
                'message': f"Humidity level at {humidity}% in {city_name}. "
                           f"May cause discomfort for respiratory conditions.",
                'value': humidity
            })
        
        # Air quality alert
        if pm2_5 >= self.AQI_THRESHOLD or aqi >= 150:
            alerts.append({
                'type': 'air_quality',
                'title': '😷 Air Quality Alert',
                'message': f"Poor air quality in {city_name} (PM2.5: {pm2_5:.0f}, AQI: {aqi}). "
                           f"Consider wearing a mask outdoors.",
                'value': pm2_5
            })
        
        # Heavy rain/storm warning
        if weather_code in [65, 82, 95, 96, 99]:
            alerts.append({
                'type': 'storm_warning',
                'title': '⛈️ Storm Warning',
                'message': f"{weather_desc} in {city_name}. "
                           f"Be careful of flooding and stay indoors if possible.",
                'value': weather_code
            })
        
        return alerts
    
    def _was_alert_sent_recently(self, cache_key: str) -> bool:
        """Check if this alert was sent in the last 6 hours"""
        if cache_key in self._last_alerts:
            last_sent = self._last_alerts[cache_key]
            if datetime.utcnow() - last_sent < timedelta(hours=6):
                return True
        return False
    
    def _mark_alert_sent(self, cache_key: str):
        """Mark an alert as sent"""
        self._last_alerts[cache_key] = datetime.utcnow()
