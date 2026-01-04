-- =====================================================
-- MIGRATION: Add Enhanced Hospital/Doctor Schema Fields
-- Run this BEFORE running seed_data.sql
-- =====================================================

-- =====================
-- HOSPITALS TABLE - Add new columns
-- =====================
ALTER TABLE hospitals 
  ADD COLUMN IF NOT EXISTS description TEXT AFTER type,
  ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'Nepal' AFTER province,
  ADD COLUMN IF NOT EXISTS postal_code VARCHAR(20) AFTER country,
  ADD COLUMN IF NOT EXISTS phone_secondary VARCHAR(20) AFTER phone,
  ADD COLUMN IF NOT EXISTS emergency_phone VARCHAR(20) AFTER phone_secondary,
  ADD COLUMN IF NOT EXISTS facebook_url VARCHAR(255) AFTER website,
  ADD COLUMN IF NOT EXISTS twitter_url VARCHAR(255) AFTER facebook_url,
  ADD COLUMN IF NOT EXISTS instagram_url VARCHAR(255) AFTER twitter_url,
  ADD COLUMN IF NOT EXISTS linkedin_url VARCHAR(255) AFTER instagram_url,
  ADD COLUMN IF NOT EXISTS youtube_url VARCHAR(255) AFTER linkedin_url,
  ADD COLUMN IF NOT EXISTS logo_url TEXT AFTER image_url,
  ADD COLUMN IF NOT EXISTS banner_url TEXT AFTER logo_url,
  ADD COLUMN IF NOT EXISTS icu_beds INT AFTER total_beds,
  ADD COLUMN IF NOT EXISTS ventilators INT AFTER icu_beds,
  ADD COLUMN IF NOT EXISTS operation_theaters INT AFTER ventilators,
  ADD COLUMN IF NOT EXISTS ambulances INT AFTER operation_theaters,
  ADD COLUMN IF NOT EXISTS parking_available BOOLEAN DEFAULT TRUE AFTER ambulances,
  ADD COLUMN IF NOT EXISTS wheelchair_accessible BOOLEAN DEFAULT TRUE AFTER parking_available,
  ADD COLUMN IF NOT EXISTS total_reviews INT DEFAULT 0 AFTER rating,
  ADD COLUMN IF NOT EXISTS established_year INT AFTER opening_hours,
  ADD COLUMN IF NOT EXISTS features TEXT AFTER specializations,
  ADD COLUMN IF NOT EXISTS insurance_accepted TEXT AFTER features,
  ADD COLUMN IF NOT EXISTS payment_methods TEXT AFTER insurance_accepted,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE AFTER is_verified,
  ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- =====================
-- DEPARTMENTS TABLE - Add new columns
-- =====================
ALTER TABLE departments
  ADD COLUMN IF NOT EXISTS description TEXT AFTER name,
  ADD COLUMN IF NOT EXISTS floor VARCHAR(50) AFTER description,
  ADD COLUMN IF NOT EXISTS phone_extension VARCHAR(20) AFTER floor,
  ADD COLUMN IF NOT EXISTS head_doctor_id INT AFTER phone_extension,
  ADD COLUMN IF NOT EXISTS beds_count INT DEFAULT 0 AFTER specialists_count,
  ADD COLUMN IF NOT EXISTS image_url TEXT AFTER icon,
  ADD COLUMN IF NOT EXISTS opening_hours TEXT AFTER image_url,
  ADD COLUMN IF NOT EXISTS appointment_required BOOLEAN DEFAULT TRUE AFTER opening_hours,
  ADD COLUMN IF NOT EXISTS avg_consultation_time INT AFTER appointment_required,
  ADD COLUMN IF NOT EXISTS created_at DATETIME DEFAULT CURRENT_TIMESTAMP AFTER avg_consultation_time;

-- =====================
-- DOCTORS TABLE - Add new columns
-- =====================
ALTER TABLE doctors
  ADD COLUMN IF NOT EXISTS sub_specialization VARCHAR(255) AFTER specialization,
  ADD COLUMN IF NOT EXISTS education TEXT AFTER qualification,
  ADD COLUMN IF NOT EXISTS department_id INT AFTER hospital_id,
  ADD COLUMN IF NOT EXISTS is_department_head BOOLEAN DEFAULT FALSE AFTER department_id,
  ADD COLUMN IF NOT EXISTS video_fee DECIMAL(10,2) AFTER chat_fee,
  ADD COLUMN IF NOT EXISTS home_visit_fee DECIMAL(10,2) AFTER video_fee,
  ADD COLUMN IF NOT EXISTS available_days VARCHAR(100) AFTER is_available,
  ADD COLUMN IF NOT EXISTS available_hours TEXT AFTER available_days,
  ADD COLUMN IF NOT EXISTS next_available_slot DATETIME AFTER available_hours,
  ADD COLUMN IF NOT EXISTS avg_consultation_time INT AFTER next_available_slot,
  ADD COLUMN IF NOT EXISTS success_rate DECIMAL(5,2) AFTER total_patients,
  ADD COLUMN IF NOT EXISTS achievements TEXT AFTER about,
  ADD COLUMN IF NOT EXISTS publications TEXT AFTER achievements,
  ADD COLUMN IF NOT EXISTS phone VARCHAR(20) AFTER publications,
  ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- Add foreign key for department
ALTER TABLE doctors
  ADD CONSTRAINT fk_doctor_department FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL;

-- =====================
-- HOSPITAL_METRICS TABLE - Add name column
-- =====================
ALTER TABLE hospital_metrics
  ADD COLUMN IF NOT EXISTS name VARCHAR(100) AFTER metric_type,
  ADD COLUMN IF NOT EXISTS icon VARCHAR(50) AFTER score;

-- =====================
-- HOSPITAL_REVIEWS TABLE - Add detailed ratings
-- =====================
ALTER TABLE hospital_reviews
  ADD COLUMN IF NOT EXISTS title VARCHAR(255) AFTER rating,
  ADD COLUMN IF NOT EXISTS cleanliness_rating INT AFTER tags,
  ADD COLUMN IF NOT EXISTS staff_rating INT AFTER cleanliness_rating,
  ADD COLUMN IF NOT EXISTS facilities_rating INT AFTER staff_rating,
  ADD COLUMN IF NOT EXISTS wait_time_rating INT AFTER facilities_rating,
  ADD COLUMN IF NOT EXISTS value_rating INT AFTER wait_time_rating,
  ADD COLUMN IF NOT EXISTS helpful_count INT DEFAULT 0 AFTER value_rating,
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE AFTER helpful_count,
  ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE AFTER is_verified,
  ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- =====================
-- CREATE NEW TABLES
-- =====================

-- Hospital Services Table
CREATE TABLE IF NOT EXISTS hospital_services (
  id INT PRIMARY KEY AUTO_INCREMENT,
  hospital_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  category ENUM('diagnostic', 'treatment', 'surgery', 'emergency', 'rehabilitation', 'pharmacy', 'lab', 'imaging', 'other') DEFAULT 'other',
  description TEXT,
  price_min DECIMAL(10,2),
  price_max DECIMAL(10,2),
  duration_minutes INT,
  is_available BOOLEAN DEFAULT TRUE,
  requires_appointment BOOLEAN DEFAULT TRUE,
  icon VARCHAR(100),
  FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
);

-- Hospital Images (Gallery) Table
CREATE TABLE IF NOT EXISTS hospital_images (
  id INT PRIMARY KEY AUTO_INCREMENT,
  hospital_id INT NOT NULL,
  image_url TEXT NOT NULL,
  caption VARCHAR(255),
  category ENUM('exterior', 'interior', 'department', 'equipment', 'staff', 'other') DEFAULT 'other',
  is_primary BOOLEAN DEFAULT FALSE,
  display_order INT DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
);

-- Doctor Reviews Table
CREATE TABLE IF NOT EXISTS doctor_reviews (
  id INT PRIMARY KEY AUTO_INCREMENT,
  doctor_id INT NOT NULL,
  user_id INT NOT NULL,
  appointment_id INT,
  rating INT NOT NULL,
  title VARCHAR(255),
  content TEXT,
  punctuality_rating INT,
  knowledge_rating INT,
  bedside_manner_rating INT,
  communication_rating INT,
  would_recommend BOOLEAN DEFAULT TRUE,
  helpful_count INT DEFAULT 0,
  is_verified BOOLEAN DEFAULT FALSE,
  is_visible BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL
);

SELECT 'Migration completed successfully! Now run seed_data.sql' AS status;
