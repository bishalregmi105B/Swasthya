-- Migration: Add role and hospital_id to users table
-- Run this on your MariaDB/MySQL database

-- Add role column to users table
ALTER TABLE users ADD COLUMN role ENUM('user', 'doctor', 'hospital_admin', 'clinic_admin', 'pharmacy_admin', 'admin', 'super_admin') DEFAULT 'user' NOT NULL;

-- Add hospital_id foreign key for facility admins
ALTER TABLE users ADD COLUMN hospital_id INT NULL;
ALTER TABLE users ADD CONSTRAINT fk_users_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE SET NULL;

-- Update existing users who are doctors to have role='doctor'
UPDATE users u
SET role = 'doctor'
WHERE EXISTS (SELECT 1 FROM doctors d WHERE d.user_id = u.id);