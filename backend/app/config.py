import os
from datetime import timedelta
from dotenv import load_dotenv
from urllib.parse import quote_plus

load_dotenv()

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-jwt-secret')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)  # Extended for development
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # Build database URL from components to handle special characters in password
    @staticmethod
    def _get_database_uri():
        # If DATABASE_URL is provided directly, use it
        db_url = os.getenv('DATABASE_URL')
        if db_url and not os.getenv('DATABASE_PASSWORD'):
            return db_url
        
        # Otherwise build from individual components
        db_host = os.getenv('DATABASE_HOST', 'localhost')
        db_port = os.getenv('DATABASE_PORT', '3306')
        db_user = os.getenv('DATABASE_USER', 'root')
        db_password = os.getenv('DATABASE_PASSWORD', '')
        db_name = os.getenv('DATABASE_NAME', 'swasthya')
        
        # URL-encode the password to handle special characters like @
        encoded_password = quote_plus(db_password) if db_password else ''
        
        if encoded_password:
            return f'mysql+pymysql://{db_user}:{encoded_password}@{db_host}:{db_port}/{db_name}'
        else:
            return f'mysql+pymysql://{db_user}@{db_host}:{db_port}/{db_name}'
    
    SQLALCHEMY_DATABASE_URI = _get_database_uri.__func__()  # Call static method
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_recycle': 280,
        'pool_pre_ping': True,
    }
    
    ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY', 'default-32-byte-key-for-dev!')
    
    # AI Model Configuration with Fallbacks
    AI_CHAT_MODEL = os.getenv('AI_CHAT_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
    AI_CHAT_MODEL_FALLBACKS = os.getenv('AI_CHAT_MODEL_FALLBACKS', 'deepseek-ai/DeepSeek-V3,Qwen/QwQ-32B').split(',')
    
    AI_LIVE_CALL_MODEL = os.getenv('AI_LIVE_CALL_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
    AI_LIVE_CALL_MODEL_FALLBACKS = os.getenv('AI_LIVE_CALL_MODEL_FALLBACKS', 'deepseek-ai/DeepSeek-V3').split(',')
    
    AI_JSON_MODEL = os.getenv('AI_JSON_MODEL', 'google/gemma-2-27b-it')
    AI_JSON_MODEL_FALLBACKS = os.getenv('AI_JSON_MODEL_FALLBACKS', 'meta-llama/Llama-3.3-70B-Instruct').split(',')
    
    AI_HEALTH_TIPS_MODEL = os.getenv('AI_HEALTH_TIPS_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
    AI_HEALTH_TIPS_MODEL_FALLBACKS = os.getenv('AI_HEALTH_TIPS_MODEL_FALLBACKS', 'deepseek-ai/DeepSeek-V3').split(',')
    
    AI_ALERTS_MODEL = os.getenv('AI_ALERTS_MODEL', 'meta-llama/Llama-3.3-70B-Instruct')
    AI_ALERTS_MODEL_FALLBACKS = os.getenv('AI_ALERTS_MODEL_FALLBACKS', 'deepseek-ai/DeepSeek-V3').split(',')
    
    AI_ANALYSIS_MODEL = os.getenv('AI_ANALYSIS_MODEL', 'deepseek-ai/DeepSeek-V3')
    AI_ANALYSIS_MODEL_FALLBACKS = os.getenv('AI_ANALYSIS_MODEL_FALLBACKS', 'meta-llama/Llama-3.3-70B-Instruct').split(',')
    
    AI_VISION_MODEL = os.getenv('AI_VISION_MODEL', 'meta-llama/Llama-3.2-90B-Vision-Instruct')
    
    # AI Provider Configuration
    AI_DEFAULT_PROVIDER = os.getenv('AI_DEFAULT_PROVIDER', 'DeepInfra')
    AI_VISION_PROVIDER = os.getenv('AI_VISION_PROVIDER', 'DeepInfra')
    AI_IMAGE_ANALYSIS_PROVIDER = os.getenv('AI_IMAGE_ANALYSIS_PROVIDER', 'DeepInfra')
    AI_IMAGE_ANALYSIS_MODEL = os.getenv('AI_IMAGE_ANALYSIS_MODEL', 'meta-llama/Llama-3.2-90B-Vision-Instruct')
    
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}


class DevelopmentConfig(Config):
    DEBUG = True


class ProductionConfig(Config):
    DEBUG = False


class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
