-- Add Google OAuth columns to users table
-- Run this in your MySQL client

ALTER TABLE users 
ADD COLUMN google_id VARCHAR(255) UNIQUE NULL AFTER notification_push,
ADD COLUMN auth_provider VARCHAR(20) DEFAULT 'email' AFTER google_id;

-- Make password_hash nullable for social logins
ALTER TABLE users MODIFY COLUMN password_hash VARCHAR(255) NULL;

-- Add index for faster google_id lookups
CREATE INDEX idx_users_google_id ON users(google_id);
