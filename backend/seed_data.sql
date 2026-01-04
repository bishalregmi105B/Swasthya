-- Swasthya Demo Data Seed Script
-- Run this after tables are created
-- Matches actual SQLAlchemy model schemas

-- =====================
-- CLEAR EXISTING DATA (in correct order for foreign keys)
-- =====================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE doctor_reviews;
TRUNCATE TABLE hospital_images;
TRUNCATE TABLE hospital_services;
TRUNCATE TABLE hospital_reviews;
TRUNCATE TABLE hospital_metrics;
TRUNCATE TABLE departments;
TRUNCATE TABLE appointments;
TRUNCATE TABLE chat_messages;
TRUNCATE TABLE medicine_reminders;
TRUNCATE TABLE reminder_logs;
TRUNCATE TABLE daily_goals;
TRUNCATE TABLE simulation_progress;
TRUNCATE TABLE emergency_contacts;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE doctors;
TRUNCATE TABLE hospitals;
TRUNCATE TABLE health_alerts;
TRUNCATE TABLE blood_banks;
TRUNCATE TABLE medicines;
TRUNCATE TABLE pharmacies;
TRUNCATE TABLE prevention_tips;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

-- =====================
-- USERS (password is 'password123' hashed with bcrypt)
-- IDs 1-3: Patients, IDs 4-9: Doctors
-- =====================
INSERT INTO users (id, email, password_hash, full_name, phone, date_of_birth, gender, blood_type, address, city, province, country, is_verified, is_active, created_at, updated_at) VALUES
(1, 'patient1@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Ram Sharma', '+977-9841234567', '1990-05-15', 'male', 'A+', 'Kalimati', 'Kathmandu', 'Bagmati', 'Nepal', 1, 1, NOW(), NOW()),
(2, 'patient2@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Sita Gurung', '+977-9851234567', '1988-08-20', 'female', 'B+', 'Lazimpat', 'Kathmandu', 'Bagmati', 'Nepal', 1, 1, NOW(), NOW()),
(3, 'patient3@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Krishna Rai', '+977-9861234567', '1995-03-10', 'male', 'O+', 'Lakeside', 'Pokhara', 'Gandaki', 'Nepal', 1, 1, NOW(), NOW()),
(4, 'dr.maya@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Dr. Maya Thapa', '+977-9841111111', '1982-03-15', 'female', 'O+', 'Dhapasi', 'Kathmandu', 'Bagmati', 'Nepal', 1, 1, NOW(), NOW()),
(5, 'dr.raj@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Dr. Raj Sharma', '+977-9841222222', '1978-07-20', 'male', 'A+', 'Thapathali', 'Kathmandu', 'Bagmati', 'Nepal', 1, 1, NOW(), NOW()),
(6, 'dr.priya@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Dr. Priya Gurung', '+977-9841333333', '1985-11-10', 'female', 'B+', 'Lakeside', 'Pokhara', 'Gandaki', 'Nepal', 1, 1, NOW(), NOW()),
(7, 'dr.arun@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Dr. Arun Kumar', '+977-9841444444', '1975-01-25', 'male', 'AB+', 'Maharajgunj', 'Kathmandu', 'Bagmati', 'Nepal', 1, 1, NOW(), NOW()),
(8, 'dr.sunita@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Dr. Sunita Shrestha', '+977-9841555555', '1980-06-05', 'female', 'A-', 'Ramghat', 'Pokhara', 'Gandaki', 'Nepal', 1, 1, NOW(), NOW()),
(9, 'dr.binod@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLXCJzN/pWe', 'Dr. Binod Thapa', '+977-9841666666', '1988-09-12', 'male', 'B-', 'Maharajgunj', 'Kathmandu', 'Bagmati', 'Nepal', 1, 1, NOW(), NOW());

-- =====================
-- HOSPITALS (Enhanced with new fields)
-- =====================
INSERT INTO hospitals (id, name, type, description, address, city, province, country, latitude, longitude, 
  phone, phone_secondary, emergency_phone, email, website,
  facebook_url, instagram_url, image_url, logo_url,
  total_beds, icu_beds, ventilators, operation_theaters, ambulances,
  rating, total_reviews, ai_trust_score, avg_wait_time, `rank`,
  emergency_available, is_open_24h, established_year, specializations, features, insurance_accepted, payment_methods,
  is_verified, is_active, created_at) VALUES
(1, 'Grande International Hospital', 'hospital', 
  'Nepal''s leading multi-specialty hospital providing world-class healthcare services with state-of-the-art facilities and internationally trained doctors.',
  'Dhapasi, Tokha', 'Kathmandu', 'Bagmati', 'Nepal', 27.7370, 85.3340,
  '+977-1-5159266', '+977-1-5159267', '+977-1-5159268', 'info@grandehospital.com', 'https://grandehospital.com',
  'https://facebook.com/grandehospital', 'https://instagram.com/grandehospital',
  'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800', 'https://grandehospital.com/logo.png',
  200, 35, 20, 8, 6,
  4.8, 1250, 9.2, 12, 1,
  1, 1, 2010, 'Cardiology,Neurology,Orthopedics,Oncology,Nephrology', 'wifi,cafeteria,pharmacy,lab,parking,wheelchair', 'Nepal Life,Asian Life,NLG', 'cash,card,esewa,khalti',
  1, 1, NOW()),

(2, 'Norvic International Hospital', 'hospital',
  'A JCI-accredited hospital offering comprehensive healthcare with advanced medical technology and compassionate care.',
  'Thapathali', 'Kathmandu', 'Bagmati', 'Nepal', 27.6950, 85.3180,
  '+977-1-4258554', '+977-1-4258555', '+977-1-4258000', 'info@norvichospital.com', 'https://norvic.com',
  'https://facebook.com/norvic', 'https://instagram.com/norvic',
  'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800', 'https://norvic.com/logo.png',
  300, 50, 30, 12, 8,
  4.9, 2100, 9.5, 8, 2,
  1, 1, 1998, 'Cardiology,Oncology,Nephrology,Transplant', 'wifi,cafeteria,pharmacy,lab,parking,wheelchair,helipad', 'All major insurances', 'cash,card,esewa,khalti,imepay',
  1, 1, NOW()),

(3, 'Civil Hospital Pokhara', 'hospital',
  'The primary government hospital serving Gandaki Province with affordable healthcare services.',
  'Ramghat', 'Pokhara', 'Gandaki', 'Nepal', 28.2096, 83.9856,
  '+977-61-520066', NULL, '+977-61-520000', 'info@civilpokhara.gov.np', NULL,
  NULL, NULL,
  'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=800', NULL,
  150, 15, 8, 4, 3,
  4.2, 450, 7.5, 25, 5,
  1, 1, 1975, 'General Medicine,Emergency,Pediatrics,Surgery', 'pharmacy,lab,parking', NULL, 'cash',
  1, 1, NOW()),

(4, 'Teaching Hospital (TUTH)', 'hospital',
  'Nepal''s largest teaching hospital affiliated with Tribhuvan University, providing tertiary care and medical education.',
  'Maharajgunj', 'Kathmandu', 'Bagmati', 'Nepal', 27.7372, 85.3300,
  '+977-1-4412303', '+977-1-4412404', '+977-1-4412505', 'info@tuth.edu.np', 'https://tuth.org.np',
  'https://facebook.com/tuthofficial', NULL,
  'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?w=800', 'https://tuth.org.np/logo.png',
  500, 60, 40, 15, 10,
  4.6, 3500, 8.8, 15, 3,
  1, 1, 1983, 'All Specialties', 'pharmacy,lab,parking,research', NULL, 'cash,card',
  1, 1, NOW()),

(5, 'HealthPlus Clinic', 'clinic',
  'A modern outpatient clinic providing quality primary care and specialist consultations in a comfortable setting.',
  'New Road', 'Kathmandu', 'Bagmati', 'Nepal', 27.7050, 85.3100,
  '+977-1-4222111', NULL, NULL, 'info@healthplus.com', 'https://healthplus.com.np',
  'https://facebook.com/healthplusnepal', 'https://instagram.com/healthplus',
  'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800', NULL,
  20, 2, 2, 1, 1,
  4.5, 320, 8.0, 10, 10,
  0, 0, 2018, 'General Medicine,Dermatology,Pediatrics', 'wifi,pharmacy,parking', 'Nepal Life', 'cash,card,esewa',
  1, 1, NOW());

-- =====================
-- DEPARTMENTS (Enhanced with descriptions and details)
-- =====================
INSERT INTO departments (id, hospital_id, name, description, floor, specialists_count, beds_count, is_available, rating, icon, image_url, appointment_required) VALUES
(1, 1, 'Cardiology', 'Complete heart care including diagnostics, interventional procedures, and cardiac surgery.', '3rd Floor', 5, 25, 1, 4.8, 'cardiology', 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400', 1),
(2, 1, 'Neurology', 'Comprehensive neurological care for brain and nervous system disorders.', '4th Floor', 4, 20, 1, 4.9, 'neurology', 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400', 1),
(3, 1, 'Pediatrics', 'Specialized healthcare for infants, children, and adolescents.', '2nd Floor', 6, 30, 1, 4.7, 'pediatrics', 'https://images.unsplash.com/photo-1631815588090-d4bfec5b1ccb?w=400', 1),
(4, 1, 'Orthopedics', 'Bone, joint, and musculoskeletal care including joint replacements.', '3rd Floor', 3, 15, 1, 4.6, 'orthopedics', NULL, 1),
(5, 2, 'Cardiology', 'Advanced cardiac care with catheterization lab and bypass surgery facilities.', '4th Floor', 8, 40, 1, 4.9, 'cardiology', NULL, 1),
(6, 2, 'Oncology', 'Comprehensive cancer treatment including chemotherapy and radiation.', '5th Floor', 4, 25, 1, 4.7, 'oncology', NULL, 1),
(7, 2, 'Nephrology', 'Kidney care and dialysis services with transplant program.', '3rd Floor', 3, 15, 1, 4.8, 'nephrology', NULL, 1),
(8, 3, 'General Medicine', 'Primary care and internal medicine services.', 'Ground Floor', 10, 50, 1, 4.3, 'medicine', NULL, 0),
(9, 3, 'Emergency', '24/7 emergency and trauma care.', 'Ground Floor', 8, 20, 1, 4.5, 'emergency', NULL, 0),
(10, 4, 'All Departments', 'Comprehensive medical services across all specialties.', 'All Floors', 50, 400, 1, 4.6, 'hospital', NULL, 1);

-- =====================
-- HOSPITAL SERVICES
-- =====================
INSERT INTO hospital_services (hospital_id, name, category, description, price_min, price_max, duration_minutes, is_available, requires_appointment, icon) VALUES
(1, 'MRI Scan', 'imaging', 'High-resolution magnetic resonance imaging for detailed body scans.', 8000, 25000, 45, 1, 1, 'mri'),
(1, 'CT Scan', 'imaging', 'Computed tomography scan for cross-sectional imaging.', 5000, 15000, 30, 1, 1, 'ct_scan'),
(1, 'X-Ray', 'imaging', 'Digital X-ray imaging for bones and organs.', 500, 2000, 15, 1, 0, 'xray'),
(1, 'Blood Tests', 'lab', 'Complete blood count and chemistry panels.', 500, 5000, 30, 1, 0, 'lab'),
(1, 'ECG/EKG', 'diagnostic', 'Electrocardiogram for heart rhythm analysis.', 500, 1000, 15, 1, 0, 'heart'),
(1, 'Echocardiography', 'diagnostic', 'Ultrasound imaging of the heart.', 3000, 5000, 30, 1, 1, 'echo'),
(1, 'Angiography', 'diagnostic', 'Imaging of blood vessels to detect blockages.', 15000, 30000, 60, 1, 1, 'angio'),
(1, 'Dialysis', 'treatment', 'Kidney dialysis for patients with renal failure.', 5000, 8000, 240, 1, 1, 'dialysis'),
(2, 'MRI Scan', 'imaging', 'State-of-the-art 3T MRI scanning.', 10000, 30000, 45, 1, 1, 'mri'),
(2, 'PET Scan', 'imaging', 'Positron emission tomography for cancer detection.', 50000, 80000, 90, 1, 1, 'pet_scan'),
(2, 'Chemotherapy', 'treatment', 'Cancer treatment with medication.', 20000, 100000, 180, 1, 1, 'chemo'),
(2, 'Kidney Transplant', 'surgery', 'Kidney transplant surgery and care.', 500000, 1500000, 360, 1, 1, 'surgery'),
(3, 'X-Ray', 'imaging', 'Basic X-ray imaging services.', 300, 800, 15, 1, 0, 'xray'),
(3, 'Blood Tests', 'lab', 'Basic and advanced blood testing.', 200, 2000, 30, 1, 0, 'lab'),
(3, 'Ultrasound', 'imaging', 'Ultrasound imaging for various organs.', 1000, 3000, 30, 1, 1, 'ultrasound'),
(4, 'All Services', 'other', 'Comprehensive medical services available.', 100, 500000, 60, 1, 1, 'hospital'),
(5, 'General Checkup', 'diagnostic', 'Complete health checkup package.', 2000, 5000, 60, 1, 1, 'checkup'),
(5, 'Dermal Consultation', 'treatment', 'Skin care consultation and treatment.', 1000, 3000, 30, 1, 1, 'skin');

-- =====================
-- HOSPITAL IMAGES (Gallery)
-- =====================
INSERT INTO hospital_images (hospital_id, image_url, caption, category, is_primary, display_order) VALUES
(1, 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800', 'Hospital Main Building', 'exterior', 1, 1),
(1, 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800', 'Modern Reception', 'interior', 0, 2),
(1, 'https://images.unsplash.com/photo-1581595220892-b0739db3ba8c?w=800', 'ICU Facility', 'department', 0, 3),
(1, 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800', 'Advanced MRI Machine', 'equipment', 0, 4),
(2, 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800', 'Norvic Hospital', 'exterior', 1, 1),
(2, 'https://images.unsplash.com/photo-1551190822-a9333d879b1f?w=800', 'Operation Theater', 'department', 0, 2),
(2, 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800', 'Patient Ward', 'interior', 0, 3),
(3, 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=800', 'Civil Hospital Pokhara', 'exterior', 1, 1),
(4, 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?w=800', 'Teaching Hospital', 'exterior', 1, 1);

-- =====================
-- HOSPITAL METRICS (Enhanced with name field)
-- =====================
INSERT INTO hospital_metrics (hospital_id, metric_type, name, score, icon, updated_at) VALUES
(1, 'hygiene', 'Hygiene & Safety', 98, 'sanitizer', NOW()),
(1, 'technology', 'Advanced Technology', 85, 'memory', NOW()),
(1, 'success_rate', 'Treatment Success', 96, 'medical_services', NOW()),
(2, 'hygiene', 'Hygiene & Safety', 96, 'sanitizer', NOW()),
(2, 'technology', 'Advanced Technology', 92, 'memory', NOW()),
(2, 'success_rate', 'Treatment Success', 98, 'medical_services', NOW()),
(3, 'hygiene', 'Hygiene & Safety', 82, 'sanitizer', NOW()),
(3, 'technology', 'Advanced Technology', 65, 'memory', NOW()),
(3, 'success_rate', 'Treatment Success', 78, 'medical_services', NOW()),
(4, 'hygiene', 'Hygiene & Safety', 90, 'sanitizer', NOW()),
(4, 'technology', 'Advanced Technology', 88, 'memory', NOW()),
(4, 'success_rate', 'Treatment Success', 92, 'medical_services', NOW());

-- =====================
-- DOCTORS (Enhanced with department_id)
-- =====================
INSERT INTO doctors (id, user_id, license_number, specialization, sub_specialization, experience_years, qualification, education, hospital_id, department_id, is_department_head, consultation_fee, chat_fee, video_fee, available_days, is_available, is_verified, rating, total_reviews, total_patients, about, languages, created_at) VALUES
(1, 4, 'NMC-12345', 'neurologist', 'Stroke Specialist', 12, 'MBBS, MD (Neurology)', 'MBBS - IOM Nepal, MD Neurology - AIIMS Delhi', 1, 2, 1, 1500, 800, 1200, 'mon,tue,wed,thu,fri', 1, 1, 4.9, 234, 1500, 'Senior neurologist with expertise in stroke management and epilepsy treatment. Head of Neurology Department.', 'Nepali,English,Hindi', NOW()),
(2, 5, 'NMC-12346', 'cardiologist', 'Interventional Cardiology', 15, 'MBBS, MD (Cardiology), DM', 'MBBS - BPKIHS, MD - TU, DM - PGI Chandigarh', 1, 1, 1, 2000, 1000, 1500, 'mon,tue,wed,thu,fri,sat', 1, 1, 4.8, 189, 2000, 'Expert in interventional cardiology with over 500 successful angioplasties. Head of Cardiology.', 'Nepali,English', NOW()),
(3, 6, 'NMC-12347', 'dermatologist', 'Cosmetic Dermatology', 8, 'MBBS, MD (Dermatology)', 'MBBS - KU Nepal, MD - BPKIHS', 2, NULL, 0, 1200, 600, 1000, 'mon,wed,fri', 1, 1, 4.7, 156, 800, 'Specializes in cosmetic dermatology and skin cancer treatment.', 'Nepali,English', NOW()),
(4, 7, 'NMC-12348', 'pediatrician', 'Neonatal Care', 20, 'MBBS, MD (Pediatrics)', 'MBBS - IOM, MD Pediatrics - BPKIHS', 2, NULL, 0, 1800, 900, 1400, 'mon,tue,wed,thu,fri', 1, 1, 4.9, 312, 5000, 'Over 20 years experience in child healthcare and neonatal intensive care.', 'Nepali,English,Hindi', NOW()),
(5, 8, 'NMC-12349', 'psychiatrist', 'Clinical Psychology', 10, 'MBBS, MD (Psychiatry)', 'MBBS - KMC, MD Psychiatry - NIMHANS', 3, NULL, 0, 1000, 500, 800, 'tue,thu,sat', 1, 1, 4.6, 98, 600, 'Mental health specialist focusing on anxiety, depression, and stress disorders.', 'Nepali,English', NOW()),
(6, 9, 'NMC-12350', 'physician', 'Internal Medicine', 7, 'MBBS, MD', 'MBBS - TU, MD Internal Medicine - IOM', 4, 10, 0, 800, 400, 600, 'mon,tue,wed,thu,fri', 1, 1, 4.5, 145, 900, 'Primary care physician with expertise in diabetes and hypertension management.', 'Nepali,English', NOW());

-- =====================
-- APPOINTMENTS
-- =====================
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, type, status, consultation_fee, is_paid, notes, created_at) VALUES
(1, 1, CURDATE() + INTERVAL 1 DAY, '10:30:00', 'video', 'confirmed', 1500, 1, 'Follow-up for headaches', NOW()),
(1, 2, CURDATE() + INTERVAL 3 DAY, '14:00:00', 'in_person', 'pending', 2000, 0, 'Chest discomfort check', NOW()),
(2, 3, CURDATE() + INTERVAL 2 DAY, '11:00:00', 'video', 'confirmed', 1200, 1, 'Skin rash consultation', NOW()),
(3, 4, CURDATE() + INTERVAL 1 DAY, '15:30:00', 'chat', 'confirmed', 900, 1, 'Child fever follow-up', NOW());

-- =====================
-- HOSPITAL REVIEWS (Enhanced with detailed ratings)
-- =====================
INSERT INTO hospital_reviews (hospital_id, user_id, rating, title, content, tags, cleanliness_rating, staff_rating, facilities_rating, wait_time_rating, value_rating, is_verified, created_at) VALUES
(1, 1, 5, 'Excellent Care!', 'Had a wonderful experience at Grande. The doctors are highly skilled and the staff is very caring. Facilities are world-class.', 'clean,professional,caring', 5, 5, 5, 4, 4, 1, NOW() - INTERVAL 5 DAY),
(1, 2, 4, 'Good but Expensive', 'Great doctors and facilities but the costs are quite high. Had to wait longer than expected.', 'good_doctors,expensive,long_wait', 4, 4, 5, 3, 3, 1, NOW() - INTERVAL 10 DAY),
(2, 1, 5, 'Life Saving Care', 'The cardiac team saved my father''s life. Forever grateful to Dr. Sharma and team.', 'lifesaving,expert_doctors,clean', 5, 5, 5, 4, 4, 1, NOW() - INTERVAL 3 DAY),
(2, 3, 5, 'Best Hospital in Nepal', 'Professional staff, clean environment, and excellent treatment. Highly recommend!', 'professional,clean,recommended', 5, 5, 5, 5, 5, 1, NOW() - INTERVAL 7 DAY),
(3, 3, 3, 'Affordable Options', 'Good for basic care at affordable prices. Staff is helpful but facilities need improvement.', 'affordable,basic,helpful_staff', 3, 4, 3, 2, 4, 1, NOW() - INTERVAL 15 DAY),
(4, 1, 4, 'Trusted Institution', 'Nepal''s premier teaching hospital. Long waits but excellent specialists.', 'trusted,specialists,crowded', 4, 4, 4, 2, 5, 1, NOW() - INTERVAL 20 DAY);

-- =====================
-- DOCTOR REVIEWS
-- =====================
INSERT INTO doctor_reviews (doctor_id, user_id, rating, title, content, punctuality_rating, knowledge_rating, bedside_manner_rating, communication_rating, would_recommend, is_verified, created_at) VALUES
(1, 1, 5, 'Best Neurologist', 'Dr. Maya is exceptional. She diagnosed my condition accurately and explained everything clearly.', 5, 5, 5, 5, 1, 1, NOW() - INTERVAL 5 DAY),
(1, 2, 5, 'Highly Skilled', 'Excellent doctor with great expertise. Very patient and understanding.', 4, 5, 5, 5, 1, 1, NOW() - INTERVAL 12 DAY),
(2, 1, 5, 'Life Saver', 'Dr. Raj saved my life with successful angioplasty. Highly recommend!', 5, 5, 5, 4, 1, 1, NOW() - INTERVAL 8 DAY),
(3, 2, 4, 'Good Experience', 'Dr. Priya is knowledgeable and helped with my skin issues effectively.', 4, 4, 4, 4, 1, 1, NOW() - INTERVAL 20 DAY),
(4, 3, 5, 'Great with Kids', 'Dr. Arun is amazing with children. My son was comfortable throughout.', 5, 5, 5, 5, 1, 1, NOW() - INTERVAL 3 DAY);

-- =====================
-- MEDICINE REMINDERS
-- =====================
INSERT INTO medicine_reminders (user_id, medicine_name, form, strength, unit, frequency, times_per_day, reminder_times, start_date, end_date, instructions, refill_reminder, critical_alert, is_active, created_at) VALUES
(1, 'Paracetamol', 'tablet', '500', 'mg', 'daily', 2, '["08:00", "20:00"]', CURDATE(), CURDATE() + INTERVAL 7 DAY, 'Take after meals', 1, 0, 1, NOW()),
(1, 'Vitamin D3', 'tablet', '1000', 'IU', 'daily', 1, '["09:00"]', CURDATE(), CURDATE() + INTERVAL 30 DAY, 'Take with breakfast', 1, 0, 1, NOW()),
(2, 'Metformin', 'tablet', '500', 'mg', 'daily', 2, '["07:00", "19:00"]', CURDATE(), NULL, 'Essential for diabetes', 1, 1, 1, NOW()),
(2, 'Atorvastatin', 'tablet', '20', 'mg', 'daily', 1, '["21:00"]', CURDATE(), NULL, 'Take at bedtime', 1, 1, 1, NOW());

-- =====================
-- HEALTH ALERTS
-- =====================
INSERT INTO health_alerts (disease_name, description, severity, affected_city, affected_province, cases_count, trend, trend_percentage, prevention_tips, symptoms, is_active, icon, created_at, updated_at) VALUES
('Air Quality Crisis', 'PM2.5 exceeded 180 µg/m³. Avoid outdoor activities.', 'critical', 'Kathmandu', 'Bagmati', 0, 'increasing', 25.5, 'Wear N95 masks. Use air purifiers.', 'Coughing,Breathing difficulty', 1, 'air', NOW(), NOW()),
('Heat Wave Warning', 'Temperatures reaching 42°C. Stay hydrated.', 'high', 'Birgunj', 'Madhesh', 0, 'stable', 0, 'Drink water. Avoid sunlight.', 'Headache,Dizziness,Fatigue', 1, 'sun', NOW(), NOW()),
('Dengue Outbreak', 'Increased dengue cases in Chitwan.', 'high', 'Chitwan', 'Bagmati', 450, 'increasing', 32.0, 'Use mosquito nets.', 'High fever,Joint pain,Rash', 1, 'virus', NOW(), NOW()),
('Viral Fever', 'Seasonal viral fever rising.', 'moderate', 'Pokhara', 'Gandaki', 230, 'increasing', 15.0, 'Practice hand hygiene.', 'Fever,Body ache,Fatigue', 1, 'thermometer', NOW(), NOW());

-- =====================
-- BLOOD BANKS
-- =====================
INSERT INTO blood_banks (name, type, address, city, province, latitude, longitude, phone, email, opening_hours, is_open, is_open_24h, blood_availability, rating, created_at) VALUES
('Nepal Red Cross Blood Bank', 'blood_bank', 'Tripureshwor', 'Kathmandu', 'Bagmati', 27.6959, 85.3089, '+977-1-4225344', 'blood@nrcs.org', '24/7', 1, 1, '{"A+": true, "B+": true, "O+": true}', 4.8, NOW()),
('Central Blood Transfusion', 'blood_bank', 'Babar Mahal', 'Kathmandu', 'Bagmati', 27.6903, 85.3271, '+977-1-4220369', 'cbts@mohp.gov.np', '8AM-8PM', 1, 0, '{"A+": true, "B+": true}', 4.5, NOW()),
('Grande Blood Bank', 'blood_bank', 'Dhapasi', 'Kathmandu', 'Bagmati', 27.7370, 85.3340, '+977-1-5159266', 'blood@grande.com', '24/7', 1, 1, '{"A+": true, "O+": true}', 4.7, NOW()),
('Maiti Nepal', 'ngo', 'Gaushala', 'Kathmandu', 'Bagmati', 27.7120, 85.3450, '+977-1-4494816', 'info@maitinepal.org', '9AM-5PM', 1, 0, NULL, 4.6, NOW());

-- =====================
-- EMERGENCY CONTACTS
-- =====================
INSERT INTO emergency_contacts (user_id, name, phone, relationship, is_primary, created_at) VALUES
(1, 'Gita Sharma', '+977-9847654321', 'spouse', 1, NOW()),
(1, 'Hari Sharma', '+977-9847654322', 'father', 0, NOW()),
(2, 'Binod Gurung', '+977-9857654321', 'husband', 1, NOW()),
(3, 'Santa Rai', '+977-9867654321', 'mother', 1, NOW());

-- =====================
-- MEDICINES
-- =====================
INSERT INTO medicines (name, generic_name, category, form, strength, unit, price, description, manufacturer, is_fda_approved, requires_prescription, rating, created_at) VALUES
('Paracetamol 500mg', 'Paracetamol', 'Pain Relief', 'tablet', '500', 'mg', 50.00, 'For fever and pain', 'Nepal Pharma', 1, 0, 4.8, NOW()),
('Cetrizine 10mg', 'Cetirizine', 'Antihistamine', 'tablet', '10', 'mg', 80.00, 'For allergies', 'Asian Pharma', 1, 0, 4.6, NOW()),
('Amoxicillin 500mg', 'Amoxicillin', 'Antibiotic', 'capsule', '500', 'mg', 150.00, 'For infections', 'Nepal Pharma', 1, 1, 4.7, NOW()),
('Omeprazole 20mg', 'Omeprazole', 'Antacid', 'capsule', '20', 'mg', 120.00, 'For gastritis', 'Buddha Pharma', 1, 0, 4.5, NOW()),
('Vitamin C 1000mg', 'Ascorbic Acid', 'Supplements', 'tablet', '1000', 'mg', 200.00, 'Immunity booster', 'HealthVit', 1, 0, 4.9, NOW()),
('Metformin 500mg', 'Metformin', 'Diabetes', 'tablet', '500', 'mg', 80.00, 'For diabetes', 'Nepal Pharma', 1, 1, 4.6, NOW());

-- =====================
-- PHARMACIES
-- =====================
INSERT INTO pharmacies (name, address, city, latitude, longitude, phone, rating, total_reviews, delivery_time, delivery_fee, free_delivery_above, is_verified, is_open, created_at) VALUES
('HealthPlus Pharmacy', 'New Road', 'Kathmandu', 27.7050, 85.3100, '+977-1-4222333', 4.8, 156, '30-45 mins', 50.00, 500.00, 1, 1, NOW()),
('Medicare Pharmacy', 'Thapathali', 'Kathmandu', 27.6950, 85.3180, '+977-1-4256789', 4.5, 89, '45-60 mins', 60.00, 600.00, 1, 1, NOW()),
('Apollo Pharmacy', 'Lakeside', 'Pokhara', 28.2096, 83.9856, '+977-61-521234', 4.6, 67, '30-40 mins', 40.00, 400.00, 1, 1, NOW());

-- =====================
-- PREVENTION TIPS
-- =====================
INSERT INTO prevention_tips (title, category, content, is_featured, is_medically_reviewed, created_at) VALUES
('Stay Hydrated', 'hydration', 'Drink 8 glasses of water daily.', 1, 1, NOW()),
('Regular Exercise', 'fitness', '30 minutes exercise 5 times a week.', 1, 1, NOW()),
('Balanced Diet', 'nutrition', 'Include fruits and vegetables.', 1, 1, NOW()),
('Quality Sleep', 'sleep', 'Get 7-8 hours of sleep.', 0, 1, NOW()),
('Hand Hygiene', 'hygiene', 'Wash hands for 20 seconds.', 1, 1, NOW()),
('Mental Wellness', 'mental_health', 'Practice mindfulness.', 0, 1, NOW());

-- =====================
-- DAILY GOALS
-- =====================
INSERT INTO daily_goals (user_id, goal_type, title, target_value, icon, is_completed, date) VALUES
(1, 'water', 'Drink Water', '8 glasses', 'water_drop', 0, CURDATE()),
(1, 'steps', 'Walk', '10000 steps', 'directions_walk', 0, CURDATE()),
(1, 'sleep', 'Sleep Well', '8 hours', 'bedtime', 0, CURDATE()),
(2, 'water', 'Drink Water', '8 glasses', 'water_drop', 1, CURDATE()),
(2, 'vitamins', 'Take Vitamins', '1 dose', 'medication', 1, CURDATE());

SELECT 'Enhanced demo data with services, gallery, and reviews inserted successfully!' as status;
