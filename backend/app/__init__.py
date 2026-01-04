import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_migrate import Migrate
from sqlalchemy import text

from app.config import config

db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()


def create_app(config_name=None):
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    
    # JWT Error handlers for debugging
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        print(f"[JWT ERROR] Token expired! Payload: {jwt_payload}")
        return {'error': 'Token has expired', 'type': 'expired'}, 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        print(f"[JWT ERROR] Invalid token: {error}")
        return {'error': f'Invalid token: {error}', 'type': 'invalid'}, 422
    
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        print(f"[JWT ERROR] Missing token: {error}")
        return {'error': 'Missing authorization token', 'type': 'missing'}, 401
    
    @jwt.token_verification_failed_loader
    def verification_failed_callback(jwt_header, jwt_payload):
        print(f"[JWT ERROR] Verification failed! Header: {jwt_header}, Payload: {jwt_payload}")
        return {'error': 'Token verification failed', 'type': 'verification_failed'}, 422
    
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    # Import all models to ensure they're registered with SQLAlchemy
    from app.models import (
        user, doctor, hospital, appointment, reminder,
        health_alert, medicine, prevention, disease_surveillance, simulation,
        medical_history
    )
    
    # Create all tables and auto-add new columns
    with app.app_context():
        db.create_all()
        _upgrade_simulation_tables(app)
        _seed_simulations(app)
        print("✓ Database tables initialized and seeded")
    
    from app.routes import register_blueprints
    register_blueprints(app)
    
    @app.route('/health')
    def health_check():
        return {'status': 'healthy', 'service': 'swasthya-api'}
    
    return app


def _upgrade_simulation_tables(app):
    """Add new bilingual columns to existing simulation tables"""
    try:
        with db.engine.connect() as conn:
            # Check if title_ne column exists
            result = conn.execute(text(
                "SELECT COUNT(*) FROM information_schema.columns "
                "WHERE table_name='simulations' AND column_name='title_ne'"
            ))
            if result.scalar() == 0:
                # Add new columns to simulations table
                conn.execute(text("ALTER TABLE simulations ADD COLUMN title_ne VARCHAR(255)"))
                conn.execute(text("ALTER TABLE simulations ADD COLUMN description_ne TEXT"))
                conn.commit()
                print("✓ Added bilingual columns to simulations table")
            
            # Check if title_ne column exists in simulation_steps
            result = conn.execute(text(
                "SELECT COUNT(*) FROM information_schema.columns "
                "WHERE table_name='simulation_steps' AND column_name='title_ne'"
            ))
            if result.scalar() == 0:
                # Add new columns to simulation_steps table
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN title_ne VARCHAR(255)"))
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN instruction_ne TEXT"))
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN voice_text TEXT"))
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN voice_text_ne TEXT"))
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN animation_url TEXT"))
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN ai_feedback_good_ne TEXT"))
                conn.execute(text("ALTER TABLE simulation_steps ADD COLUMN ai_feedback_adjust_ne TEXT"))
                conn.commit()
                print("✓ Added bilingual columns to simulation_steps table")
            
            # Upgrade step_type enum to include 'compress'
            try:
                conn.execute(text(
                    "ALTER TABLE simulation_steps MODIFY COLUMN step_type "
                    "ENUM('info', 'action', 'check', 'timed', 'compress') DEFAULT 'info'"
                ))
                conn.commit()
                print("✓ Updated step_type enum to include 'compress'")
            except Exception:
                pass  # Already updated or not needed
    except Exception as e:
        print(f"! Column upgrade skipped: {e}")


def _seed_simulations(app):
    """Seed simulations if not already present with full data"""
    try:
        from app.routes.simulations import seed_simulations
        seed_simulations()
    except Exception as e:
        print(f"! Seed skipped: {e}")

