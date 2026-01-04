def register_blueprints(app):
    from app.routes.auth import auth_bp
    from app.routes.users import users_bp
    from app.routes.ai_sathi import ai_sathi_bp
    from app.routes.live_ai_call import live_ai_bp
    from app.routes.doctors import doctors_bp
    from app.routes.hospitals import hospitals_bp
    from app.routes.appointments import appointments_bp
    from app.routes.reminders import reminders_bp
    from app.routes.health_alerts import health_alerts_bp
    from app.routes.blood_banks import blood_banks_bp
    from app.routes.emergency import emergency_bp
    from app.routes.calculators import calculators_bp
    from app.routes.medicines import medicines_bp
    from app.routes.prevention import prevention_bp
    from app.routes.notifications import notifications_bp
    from app.routes.health_data import health_data_bp
    from app.routes.simulations import simulations_bp
    from app.routes.medical_history import medical_history_bp
    from app.routes.disease_surveillance import disease_surveillance_bp
    from app.routes.diseases import diseases_bp
    from app.routes.drug_info import drug_info_bp
    from app.routes.cron_routes import cron_bp
    from app.routes.ai_history import ai_history_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(users_bp, url_prefix='/api/users')
    app.register_blueprint(ai_sathi_bp, url_prefix='/api/ai-sathi')
    app.register_blueprint(live_ai_bp, url_prefix='/api/ai-sathi')  # Live AI call routes
    app.register_blueprint(ai_history_bp, url_prefix='/api/ai-history')  # AI chat history
    app.register_blueprint(doctors_bp, url_prefix='/api/doctors')
    app.register_blueprint(hospitals_bp, url_prefix='/api/hospitals')
    app.register_blueprint(appointments_bp, url_prefix='/api/appointments')
    app.register_blueprint(reminders_bp, url_prefix='/api/reminders')
    app.register_blueprint(health_alerts_bp, url_prefix='/api/health-alerts')
    app.register_blueprint(blood_banks_bp, url_prefix='/api/blood-banks')
    app.register_blueprint(emergency_bp, url_prefix='/api/emergency')
    app.register_blueprint(calculators_bp, url_prefix='/api/calculators')
    app.register_blueprint(medicines_bp, url_prefix='/api/medicines')
    app.register_blueprint(prevention_bp, url_prefix='/api/prevention')
    app.register_blueprint(notifications_bp, url_prefix='/api/notifications')
    app.register_blueprint(health_data_bp, url_prefix='/api/health-data')
    app.register_blueprint(disease_surveillance_bp, url_prefix='/api/disease-surveillance')
    app.register_blueprint(simulations_bp)  # Uses /api/simulations from blueprint
    app.register_blueprint(medical_history_bp, url_prefix='/api/medical-history')
    app.register_blueprint(diseases_bp)  # Disease encyclopedia - uses /api/diseases from blueprint
    app.register_blueprint(drug_info_bp)  # Drug info - uses /api/drug-info from blueprint
    app.register_blueprint(cron_bp, url_prefix='/api/cron')  # Cron job endpoints

