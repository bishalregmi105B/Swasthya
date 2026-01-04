from app.models.user import User
from app.models.doctor import Doctor, DoctorReview
from app.models.hospital import (
    Hospital, Department, HospitalMetric, HospitalReview,
    HospitalService, HospitalImage
)
from app.models.appointment import Appointment, ChatMessage
from app.models.reminder import MedicineReminder, ReminderLog
from app.models.health_alert import HealthAlert, BloodBank, EmergencyContact
from app.models.medicine import Medicine, Pharmacy, Order, OrderItem
from app.models.prevention import PreventionTip, DailyGoal, SimulationProgress
from app.models.disease_surveillance import (
    DiseaseOutbreak, CovidRecord, DiseaseSpreadLevel,
    RegionalDiseaseAlert, CountryDiseaseRisk, HealthDataFetchLog
)
from app.models.simulation import Simulation, SimulationStep, UserSimulationProgress
from app.models.medical_history import (
    MedicalRecord, MedicalCondition, MedicalAllergy, MedicalMedication,
    MedicalDocument, MedicalDocumentImage, MedicalSurgery, MedicalVaccination
)
from app.models.ai_conversation import AIConversation, AIMessage

__all__ = [
    'User',
    'Doctor',
    'DoctorReview',
    'Hospital',
    'Department',
    'HospitalMetric',
    'HospitalReview',
    'HospitalService',
    'HospitalImage',
    'Appointment',
    'ChatMessage',
    'MedicineReminder',
    'ReminderLog',
    'HealthAlert',
    'BloodBank',
    'EmergencyContact',
    'Medicine',
    'Pharmacy',
    'Order',
    'OrderItem',
    'PreventionTip',
    'DailyGoal',
    'SimulationProgress',
    # Disease Surveillance Models
    'DiseaseOutbreak',
    'CovidRecord',
    'DiseaseSpreadLevel',
    'RegionalDiseaseAlert',
    'CountryDiseaseRisk',
    'HealthDataFetchLog',
    # Simulation Models
    'Simulation',
    'SimulationStep',
    'UserSimulationProgress',
    # Medical History Models
    'MedicalRecord',
    'MedicalCondition',
    'MedicalAllergy',
    'MedicalMedication',
    'MedicalDocument',
    'MedicalDocumentImage',
    'MedicalSurgery',
    'MedicalVaccination',
    # AI Conversation History
    'AIConversation',
    'AIMessage',
]
