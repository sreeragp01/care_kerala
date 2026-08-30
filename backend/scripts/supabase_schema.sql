-- ==============================================================
-- CareLink Kerala: Complete Supabase PostgreSQL Schema
-- Organization: Nammal Tech Innovations
-- ==============================================================

-- Migration: contenttypes.0001_initial
BEGIN;
--
-- Create model ContentType
--
CREATE TABLE "django_content_type" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(100) NOT NULL, "app_label" varchar(100) NOT NULL, "model" varchar(100) NOT NULL);
--
-- Alter unique_together for contenttype (1 constraint(s))
--
CREATE UNIQUE INDEX "django_content_type_app_label_model_76bd3d3b_uniq" ON "django_content_type" ("app_label", "model");
COMMIT;

-- Migration: auth.0001_initial
BEGIN;
--
-- Create model Permission
--
CREATE TABLE "auth_permission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(50) NOT NULL, "content_type_id" integer NOT NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "codename" varchar(100) NOT NULL);
--
-- Create model Group
--
CREATE TABLE "auth_group" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(80) NOT NULL UNIQUE);
CREATE TABLE "auth_group_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model User
--
-- (no-op)
CREATE UNIQUE INDEX "auth_permission_content_type_id_codename_01ab375a_uniq" ON "auth_permission" ("content_type_id", "codename");
CREATE INDEX "auth_permission_content_type_id_2f476e4b" ON "auth_permission" ("content_type_id");
CREATE UNIQUE INDEX "auth_group_permissions_group_id_permission_id_0cd325b0_uniq" ON "auth_group_permissions" ("group_id", "permission_id");
CREATE INDEX "auth_group_permissions_group_id_b120cbf9" ON "auth_group_permissions" ("group_id");
CREATE INDEX "auth_group_permissions_permission_id_84c5c92e" ON "auth_group_permissions" ("permission_id");
COMMIT;

-- Migration: organizations.0001_initial
BEGIN;
--
-- Create model Organization
--
CREATE TABLE "organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL);
COMMIT;

-- Migration: organizations.0002_organization_bank_account_name_and_more
BEGIN;
--
-- Add field bank_account_name to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bank_account_name" varchar(200) NOT NULL, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
--
-- Add field bank_account_number to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL, "bank_account_name" varchar(200) NOT NULL, "bank_account_number" varchar(50) NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
--
-- Add field bank_name to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL, "bank_account_name" varchar(200) NOT NULL, "bank_account_number" varchar(50) NOT NULL, "bank_name" varchar(100) NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
--
-- Add field ifsc_code to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL, "bank_account_name" varchar(200) NOT NULL, "bank_account_number" varchar(50) NOT NULL, "bank_name" varchar(100) NOT NULL, "ifsc_code" varchar(20) NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
--
-- Add field qr_code_image_url to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL, "bank_account_name" varchar(200) NOT NULL, "bank_account_number" varchar(50) NOT NULL, "bank_name" varchar(100) NOT NULL, "ifsc_code" varchar(20) NOT NULL, "qr_code_image_url" varchar(500) NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code", "qr_code_image_url") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
--
-- Add field razorpay_account_id to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL, "bank_account_name" varchar(200) NOT NULL, "bank_account_number" varchar(50) NOT NULL, "bank_name" varchar(100) NOT NULL, "ifsc_code" varchar(20) NOT NULL, "qr_code_image_url" varchar(500) NOT NULL, "razorpay_account_id" varchar(100) NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code", "qr_code_image_url", "razorpay_account_id") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code", "qr_code_image_url", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
--
-- Add field upi_id to organization
--
CREATE TABLE "new__organizations_organization" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "registration_number" varchar(100) NOT NULL UNIQUE, "phone" varchar(20) NOT NULL, "active_patients_count" integer NOT NULL, "total_visits_count" integer NOT NULL, "created_at" datetime NOT NULL, "bank_account_name" varchar(200) NOT NULL, "bank_account_number" varchar(50) NOT NULL, "bank_name" varchar(100) NOT NULL, "ifsc_code" varchar(20) NOT NULL, "qr_code_image_url" varchar(500) NOT NULL, "razorpay_account_id" varchar(100) NOT NULL, "upi_id" varchar(100) NOT NULL);
INSERT INTO "new__organizations_organization" ("id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code", "qr_code_image_url", "razorpay_account_id", "upi_id") SELECT "id", "name", "district", "registration_number", "phone", "active_patients_count", "total_visits_count", "created_at", "bank_account_name", "bank_account_number", "bank_name", "ifsc_code", "qr_code_image_url", "razorpay_account_id", '' FROM "organizations_organization";
DROP TABLE "organizations_organization";
ALTER TABLE "new__organizations_organization" RENAME TO "organizations_organization";
COMMIT;

-- Migration: authentication.0001_initial
BEGIN;
--
-- Create model User
--
CREATE TABLE "authentication_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "password" varchar(128) NOT NULL, "last_login" datetime NULL, "is_superuser" bool NOT NULL, "username" varchar(150) NOT NULL UNIQUE, "first_name" varchar(150) NOT NULL, "last_name" varchar(150) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL, "role" varchar(50) NOT NULL, "phone" varchar(20) NOT NULL, "district" varchar(100) NOT NULL, "organization_id" bigint NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE TABLE "authentication_user_groups" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" bigint NOT NULL REFERENCES "authentication_user" ("id") DEFERRABLE INITIALLY DEFERRED, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE TABLE "authentication_user_user_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" bigint NOT NULL REFERENCES "authentication_user" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "authentication_user_organization_id_d85c0efb" ON "authentication_user" ("organization_id");
CREATE UNIQUE INDEX "authentication_user_groups_user_id_group_id_8af031ac_uniq" ON "authentication_user_groups" ("user_id", "group_id");
CREATE INDEX "authentication_user_groups_user_id_30868577" ON "authentication_user_groups" ("user_id");
CREATE INDEX "authentication_user_groups_group_id_6b5c44b7" ON "authentication_user_groups" ("group_id");
CREATE UNIQUE INDEX "authentication_user_user_permissions_user_id_permission_id_ec51b09f_uniq" ON "authentication_user_user_permissions" ("user_id", "permission_id");
CREATE INDEX "authentication_user_user_permissions_user_id_736ebf7e" ON "authentication_user_user_permissions" ("user_id");
CREATE INDEX "authentication_user_user_permissions_permission_id_ea6be19a" ON "authentication_user_user_permissions" ("permission_id");
COMMIT;

-- Migration: patients.0001_initial
BEGIN;
--
-- Create model Patient
--
CREATE TABLE "patients_patient" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "patient_id_code" varchar(50) NOT NULL UNIQUE, "name" varchar(200) NOT NULL, "age" integer NOT NULL, "gender" varchar(20) NOT NULL, "blood_group" varchar(10) NOT NULL, "district" varchar(100) NOT NULL, "ward" varchar(100) NOT NULL, "address" text NOT NULL, "phone" varchar(20) NOT NULL, "category_tier" varchar(100) NOT NULL, "diagnosis" text NOT NULL, "risk_level" varchar(50) NOT NULL, "ai_summary" text NOT NULL, "emergency_contact_name" varchar(100) NOT NULL, "emergency_contact_phone" varchar(20) NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model FamilyMemberContact
--
CREATE TABLE "patients_familymembercontact" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(100) NOT NULL, "relation" varchar(50) NOT NULL, "phone" varchar(20) NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model EquipmentIssued
--
CREATE TABLE "patients_equipmentissued" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "equipment_name" varchar(200) NOT NULL, "serial_number" varchar(100) NOT NULL, "issued_date" date NOT NULL, "status" varchar(50) NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model VitalsReading
--
CREATE TABLE "patients_vitalsreading" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bp" varchar(20) NOT NULL, "pulse" integer NOT NULL, "spo2" integer NOT NULL, "pain_scale" integer NOT NULL, "recorded_by" varchar(100) NOT NULL, "recorded_date" date NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "patients_patient_organization_id_772b1524" ON "patients_patient" ("organization_id");
CREATE INDEX "patients_familymembercontact_patient_id_7a44f120" ON "patients_familymembercontact" ("patient_id");
CREATE INDEX "patients_equipmentissued_patient_id_37ea7513" ON "patients_equipmentissued" ("patient_id");
CREATE INDEX "patients_vitalsreading_patient_id_e69f0534" ON "patients_vitalsreading" ("patient_id");
COMMIT;

-- Migration: patients.0002_patientauditlog
BEGIN;
--
-- Create model PatientAuditLog
--
CREATE TABLE "patients_patientauditlog" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_username" varchar(150) NOT NULL, "user_role" varchar(50) NOT NULL, "organization_name" varchar(200) NOT NULL, "action" varchar(50) NOT NULL, "ip_address" varchar(50) NOT NULL, "details" text NOT NULL, "timestamp" datetime NOT NULL, "patient_id" bigint NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "patients_patientauditlog_patient_id_f8fc056e" ON "patients_patientauditlog" ("patient_id");
COMMIT;

-- Migration: patients.0003_patient_lifecycle_status_vitalsreading_recorded_at_and_more
BEGIN;
--
-- Add field lifecycle_status to patient
--
CREATE TABLE "new__patients_patient" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "lifecycle_status" varchar(50) NOT NULL, "patient_id_code" varchar(50) NOT NULL UNIQUE, "name" varchar(200) NOT NULL, "age" integer NOT NULL, "gender" varchar(20) NOT NULL, "blood_group" varchar(10) NOT NULL, "district" varchar(100) NOT NULL, "ward" varchar(100) NOT NULL, "address" text NOT NULL, "phone" varchar(20) NOT NULL, "category_tier" varchar(100) NOT NULL, "diagnosis" text NOT NULL, "risk_level" varchar(50) NOT NULL, "ai_summary" text NOT NULL, "emergency_contact_name" varchar(100) NOT NULL, "emergency_contact_phone" varchar(20) NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
INSERT INTO "new__patients_patient" ("id", "patient_id_code", "name", "age", "gender", "blood_group", "district", "ward", "address", "phone", "category_tier", "diagnosis", "risk_level", "ai_summary", "emergency_contact_name", "emergency_contact_phone", "created_at", "organization_id", "lifecycle_status") SELECT "id", "patient_id_code", "name", "age", "gender", "blood_group", "district", "ward", "address", "phone", "category_tier", "diagnosis", "risk_level", "ai_summary", "emergency_contact_name", "emergency_contact_phone", "created_at", "organization_id", 'Active Care' FROM "patients_patient";
DROP TABLE "patients_patient";
ALTER TABLE "new__patients_patient" RENAME TO "patients_patient";
CREATE INDEX "patients_patient_organization_id_772b1524" ON "patients_patient" ("organization_id");
--
-- Add field recorded_at to vitalsreading
--
CREATE TABLE "new__patients_vitalsreading" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bp" varchar(20) NOT NULL, "pulse" integer NOT NULL, "spo2" integer NOT NULL, "pain_scale" integer NOT NULL, "recorded_by" varchar(100) NOT NULL, "recorded_date" date NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "recorded_at" datetime NOT NULL);
INSERT INTO "new__patients_vitalsreading" ("id", "bp", "pulse", "spo2", "pain_scale", "recorded_by", "recorded_date", "patient_id", "recorded_at") SELECT "id", "bp", "pulse", "spo2", "pain_scale", "recorded_by", "recorded_date", "patient_id", '2026-08-30 18:03:47.442676' FROM "patients_vitalsreading";
DROP TABLE "patients_vitalsreading";
ALTER TABLE "new__patients_vitalsreading" RENAME TO "patients_vitalsreading";
CREATE INDEX "patients_vitalsreading_patient_id_e69f0534" ON "patients_vitalsreading" ("patient_id");
--
-- Add field respiratory_rate to vitalsreading
--
CREATE TABLE "new__patients_vitalsreading" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bp" varchar(20) NOT NULL, "pulse" integer NOT NULL, "spo2" integer NOT NULL, "pain_scale" integer NOT NULL, "recorded_by" varchar(100) NOT NULL, "recorded_date" date NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "recorded_at" datetime NOT NULL, "respiratory_rate" integer NOT NULL);
INSERT INTO "new__patients_vitalsreading" ("id", "bp", "pulse", "spo2", "pain_scale", "recorded_by", "recorded_date", "patient_id", "recorded_at", "respiratory_rate") SELECT "id", "bp", "pulse", "spo2", "pain_scale", "recorded_by", "recorded_date", "patient_id", "recorded_at", 16 FROM "patients_vitalsreading";
DROP TABLE "patients_vitalsreading";
ALTER TABLE "new__patients_vitalsreading" RENAME TO "patients_vitalsreading";
CREATE INDEX "patients_vitalsreading_patient_id_e69f0534" ON "patients_vitalsreading" ("patient_id");
--
-- Add field temperature to vitalsreading
--
CREATE TABLE "new__patients_vitalsreading" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bp" varchar(20) NOT NULL, "pulse" integer NOT NULL, "spo2" integer NOT NULL, "pain_scale" integer NOT NULL, "recorded_by" varchar(100) NOT NULL, "recorded_date" date NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "recorded_at" datetime NOT NULL, "respiratory_rate" integer NOT NULL, "temperature" decimal NOT NULL);
INSERT INTO "new__patients_vitalsreading" ("id", "bp", "pulse", "spo2", "pain_scale", "recorded_by", "recorded_date", "patient_id", "recorded_at", "respiratory_rate", "temperature") SELECT "id", "bp", "pulse", "spo2", "pain_scale", "recorded_by", "recorded_date", "patient_id", "recorded_at", "respiratory_rate", '98.60' FROM "patients_vitalsreading";
DROP TABLE "patients_vitalsreading";
ALTER TABLE "new__patients_vitalsreading" RENAME TO "patients_vitalsreading";
CREATE INDEX "patients_vitalsreading_patient_id_e69f0534" ON "patients_vitalsreading" ("patient_id");
--
-- Alter field pain_scale on vitalsreading
--
CREATE TABLE "new__patients_vitalsreading" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bp" varchar(20) NOT NULL, "pulse" integer NOT NULL, "spo2" integer NOT NULL, "recorded_by" varchar(100) NOT NULL, "recorded_date" date NOT NULL, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "recorded_at" datetime NOT NULL, "respiratory_rate" integer NOT NULL, "temperature" decimal NOT NULL, "pain_scale" integer NOT NULL);
INSERT INTO "new__patients_vitalsreading" ("id", "bp", "pulse", "spo2", "recorded_by", "recorded_date", "patient_id", "recorded_at", "respiratory_rate", "temperature", "pain_scale") SELECT "id", "bp", "pulse", "spo2", "recorded_by", "recorded_date", "patient_id", "recorded_at", "respiratory_rate", "temperature", "pain_scale" FROM "patients_vitalsreading";
DROP TABLE "patients_vitalsreading";
ALTER TABLE "new__patients_vitalsreading" RENAME TO "patients_vitalsreading";
CREATE INDEX "patients_vitalsreading_patient_id_e69f0534" ON "patients_vitalsreading" ("patient_id");
--
-- Create model CarePlan
--
CREATE TABLE "patients_careplan" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "primary_nurse_name" varchar(100) NOT NULL, "assigned_doctor_name" varchar(100) NOT NULL, "care_goals" text NOT NULL, "dietary_instructions" text NOT NULL, "emergency_escalation_notes" text NOT NULL, "review_frequency_days" integer NOT NULL, "last_reviewed_date" date NOT NULL, "created_at" datetime NOT NULL, "patient_id" bigint NOT NULL UNIQUE REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
COMMIT;

-- Migration: visits.0001_initial
BEGIN;
--
-- Create model HomeVisit
--
CREATE TABLE "visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
COMMIT;

-- Migration: visits.0002_homevisit_assessment_notes_homevisit_care_provided_and_more
BEGIN;
--
-- Add field assessment_notes to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assessment_notes" text NOT NULL, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field care_provided to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field doctor_review_notes to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL, "doctor_review_notes" text NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field doctor_signed_off to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL, "doctor_review_notes" text NOT NULL, "doctor_signed_off" bool NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", 0 FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field doctor_signoff_timestamp to homevisit
--
ALTER TABLE "visits_homevisit" ADD COLUMN "doctor_signoff_timestamp" datetime NULL;
--
-- Add field equipment_used to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL, "doctor_review_notes" text NOT NULL, "doctor_signed_off" bool NOT NULL, "doctor_signoff_timestamp" datetime NULL, "equipment_used" text NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field follow_up_instructions to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL, "doctor_review_notes" text NOT NULL, "doctor_signed_off" bool NOT NULL, "doctor_signoff_timestamp" datetime NULL, "equipment_used" text NOT NULL, "follow_up_instructions" text NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used", "follow_up_instructions") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field medication_administered to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL, "doctor_review_notes" text NOT NULL, "doctor_signed_off" bool NOT NULL, "doctor_signoff_timestamp" datetime NULL, "equipment_used" text NOT NULL, "follow_up_instructions" text NOT NULL, "medication_administered" text NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used", "follow_up_instructions", "medication_administered") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used", "follow_up_instructions", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Add field next_visit_date to homevisit
--
ALTER TABLE "visits_homevisit" ADD COLUMN "next_visit_date" date NULL;
--
-- Add field symptoms_observed to homevisit
--
CREATE TABLE "new__visits_homevisit" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "assigned_nurse_name" varchar(100) NOT NULL, "scheduled_date" date NOT NULL, "scheduled_time" varchar(50) NOT NULL, "status" varchar(50) NOT NULL, "gps_check_in_time" varchar(100) NULL, "gps_location_name" varchar(255) NULL, "clinical_notes" text NULL, "voice_recording_path" varchar(255) NULL, "is_synced_offline" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NOT NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "assessment_notes" text NOT NULL, "care_provided" text NOT NULL, "doctor_review_notes" text NOT NULL, "doctor_signed_off" bool NOT NULL, "doctor_signoff_timestamp" datetime NULL, "equipment_used" text NOT NULL, "follow_up_instructions" text NOT NULL, "medication_administered" text NOT NULL, "next_visit_date" date NULL, "symptoms_observed" text NOT NULL);
INSERT INTO "new__visits_homevisit" ("id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used", "follow_up_instructions", "medication_administered", "next_visit_date", "symptoms_observed") SELECT "id", "assigned_nurse_name", "scheduled_date", "scheduled_time", "status", "gps_check_in_time", "gps_location_name", "clinical_notes", "voice_recording_path", "is_synced_offline", "created_at", "organization_id", "patient_id", "assessment_notes", "care_provided", "doctor_review_notes", "doctor_signed_off", "doctor_signoff_timestamp", "equipment_used", "follow_up_instructions", "medication_administered", "next_visit_date", '' FROM "visits_homevisit";
DROP TABLE "visits_homevisit";
ALTER TABLE "new__visits_homevisit" RENAME TO "visits_homevisit";
CREATE INDEX "visits_homevisit_organization_id_6e6eaa19" ON "visits_homevisit" ("organization_id");
CREATE INDEX "visits_homevisit_patient_id_c3da44c9" ON "visits_homevisit" ("patient_id");
--
-- Alter field status on homevisit
--
-- (no-op)
COMMIT;

-- Migration: blood_donors.0001_initial
BEGIN;
--
-- Create model BloodDonor
--
CREATE TABLE "blood_donors_blooddonor" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(200) NOT NULL, "blood_group" varchar(10) NOT NULL, "district" varchar(100) NOT NULL, "locality" varchar(100) NOT NULL, "phone" varchar(20) NOT NULL, "last_donation_date" date NOT NULL, "total_donations" integer NOT NULL, "is_available" bool NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model BloodRequest
--
CREATE TABLE "blood_donors_bloodrequest" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "patient_name" varchar(200) NOT NULL, "blood_group" varchar(10) NOT NULL, "hospital_name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "units_needed" integer NOT NULL, "urgency" varchar(50) NOT NULL, "requested_date" date NOT NULL, "status" varchar(50) NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "blood_donors_blooddonor_organization_id_6146c75a" ON "blood_donors_blooddonor" ("organization_id");
CREATE INDEX "blood_donors_bloodrequest_organization_id_f06a0bbc" ON "blood_donors_bloodrequest" ("organization_id");
COMMIT;

-- Migration: blood_donors.0002_bloodrequest_fulfilled_date_and_more
BEGIN;
--
-- Add field fulfilled_date to bloodrequest
--
ALTER TABLE "blood_donors_bloodrequest" ADD COLUMN "fulfilled_date" date NULL;
--
-- Add field responding_donor to bloodrequest
--
ALTER TABLE "blood_donors_bloodrequest" ADD COLUMN "responding_donor_id" bigint NULL REFERENCES "blood_donors_blooddonor" ("id") DEFERRABLE INITIALLY DEFERRED;
--
-- Alter field status on bloodrequest
--
CREATE TABLE "new__blood_donors_bloodrequest" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "patient_name" varchar(200) NOT NULL, "blood_group" varchar(10) NOT NULL, "hospital_name" varchar(255) NOT NULL, "district" varchar(100) NOT NULL, "units_needed" integer NOT NULL, "urgency" varchar(50) NOT NULL, "requested_date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "fulfilled_date" date NULL, "responding_donor_id" bigint NULL REFERENCES "blood_donors_blooddonor" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL);
INSERT INTO "new__blood_donors_bloodrequest" ("id", "patient_name", "blood_group", "hospital_name", "district", "units_needed", "urgency", "requested_date", "organization_id", "fulfilled_date", "responding_donor_id", "status") SELECT "id", "patient_name", "blood_group", "hospital_name", "district", "units_needed", "urgency", "requested_date", "organization_id", "fulfilled_date", "responding_donor_id", "status" FROM "blood_donors_bloodrequest";
DROP TABLE "blood_donors_bloodrequest";
ALTER TABLE "new__blood_donors_bloodrequest" RENAME TO "blood_donors_bloodrequest";
CREATE INDEX "blood_donors_bloodrequest_organization_id_f06a0bbc" ON "blood_donors_bloodrequest" ("organization_id");
CREATE INDEX "blood_donors_bloodrequest_responding_donor_id_c36d150e" ON "blood_donors_bloodrequest" ("responding_donor_id");
COMMIT;

-- Migration: inventory.0001_initial
BEGIN;
--
-- Create model EquipmentItem
--
CREATE TABLE "inventory_equipmentitem" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(200) NOT NULL, "total_count" integer NOT NULL, "available_count" integer NOT NULL, "loaned_count" integer NOT NULL, "maintenance_status" varchar(50) NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model MedicineItem
--
CREATE TABLE "inventory_medicineitem" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(200) NOT NULL, "category" varchar(100) NOT NULL, "stock_quantity" integer NOT NULL, "unit" varchar(50) NOT NULL, "reorder_level" integer NOT NULL, "expiry_date" date NOT NULL, "batch_number" varchar(100) NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "inventory_equipmentitem_organization_id_8c870266" ON "inventory_equipmentitem" ("organization_id");
CREATE INDEX "inventory_medicineitem_organization_id_3543396f" ON "inventory_medicineitem" ("organization_id");
COMMIT;

-- Migration: inventory.0002_alter_equipmentitem_maintenance_status_and_more
BEGIN;
--
-- Alter field maintenance_status on equipmentitem
--
CREATE TABLE "new__inventory_equipmentitem" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "maintenance_status" varchar(50) NOT NULL, "name" varchar(200) NOT NULL, "total_count" integer NOT NULL, "available_count" integer NOT NULL, "loaned_count" integer NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
INSERT INTO "new__inventory_equipmentitem" ("id", "name", "total_count", "available_count", "loaned_count", "created_at", "organization_id", "maintenance_status") SELECT "id", "name", "total_count", "available_count", "loaned_count", "created_at", "organization_id", "maintenance_status" FROM "inventory_equipmentitem";
DROP TABLE "inventory_equipmentitem";
ALTER TABLE "new__inventory_equipmentitem" RENAME TO "inventory_equipmentitem";
CREATE INDEX "inventory_equipmentitem_organization_id_8c870266" ON "inventory_equipmentitem" ("organization_id");
--
-- Create model MedicineTransaction
--
CREATE TABLE "inventory_medicinetransaction" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "transaction_type" varchar(50) NOT NULL, "quantity" integer NOT NULL, "recorded_by" varchar(100) NOT NULL, "notes" text NOT NULL, "timestamp" datetime NOT NULL, "medicine_id" bigint NOT NULL REFERENCES "inventory_medicineitem" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "inventory_medicinetransaction_medicine_id_a81a6a85" ON "inventory_medicinetransaction" ("medicine_id");
COMMIT;

-- Migration: finance.0001_initial
BEGIN;
--
-- Create model Donation
--
CREATE TABLE "finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
COMMIT;

-- Migration: finance.0002_donation_status_donation_transaction_id
BEGIN;
--
-- Add field status to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "status" varchar(50) NOT NULL, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", 'Completed' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field transaction_id to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", '' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
COMMIT;

-- Migration: finance.0003_donation_donor_prayer_donation_fundraiser_id_and_more
BEGIN;
--
-- Add field donor_prayer to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_prayer" text NOT NULL, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", '' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field fundraiser_id to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL, "donor_prayer" text NOT NULL, "fundraiser_id" varchar(100) NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", '' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field is_anonymous to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL, "donor_prayer" text NOT NULL, "fundraiser_id" varchar(100) NOT NULL, "is_anonymous" bool NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", 0 FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field is_verified to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL, "donor_prayer" text NOT NULL, "fundraiser_id" varchar(100) NOT NULL, "is_anonymous" bool NOT NULL, "is_verified" bool NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", 1 FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field razorpay_order_id to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL, "donor_prayer" text NOT NULL, "fundraiser_id" varchar(100) NOT NULL, "is_anonymous" bool NOT NULL, "is_verified" bool NOT NULL, "razorpay_order_id" varchar(100) NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified", "razorpay_order_id") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified", '' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field razorpay_payment_id to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL, "donor_prayer" text NOT NULL, "fundraiser_id" varchar(100) NOT NULL, "is_anonymous" bool NOT NULL, "is_verified" bool NOT NULL, "razorpay_order_id" varchar(100) NOT NULL, "razorpay_payment_id" varchar(100) NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified", "razorpay_order_id", "razorpay_payment_id") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified", "razorpay_order_id", '' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Add field razorpay_signature to donation
--
CREATE TABLE "new__finance_donation" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "donor_name" varchar(200) NOT NULL, "amount" decimal NOT NULL, "category" varchar(100) NOT NULL, "payment_mode" varchar(50) NOT NULL, "receipt_number" varchar(100) NOT NULL UNIQUE, "date" date NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "status" varchar(50) NOT NULL, "transaction_id" varchar(100) NOT NULL, "donor_prayer" text NOT NULL, "fundraiser_id" varchar(100) NOT NULL, "is_anonymous" bool NOT NULL, "is_verified" bool NOT NULL, "razorpay_order_id" varchar(100) NOT NULL, "razorpay_payment_id" varchar(100) NOT NULL, "razorpay_signature" varchar(200) NOT NULL);
INSERT INTO "new__finance_donation" ("id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature") SELECT "id", "donor_name", "amount", "category", "payment_mode", "receipt_number", "date", "organization_id", "status", "transaction_id", "donor_prayer", "fundraiser_id", "is_anonymous", "is_verified", "razorpay_order_id", "razorpay_payment_id", '' FROM "finance_donation";
DROP TABLE "finance_donation";
ALTER TABLE "new__finance_donation" RENAME TO "finance_donation";
CREATE INDEX "finance_donation_organization_id_daa3426f" ON "finance_donation" ("organization_id");
--
-- Create model MedicalFundraiser
--
CREATE TABLE "finance_medicalfundraiser" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "patient_name" varchar(200) NOT NULL, "patient_age" integer NOT NULL, "patient_gender" varchar(20) NOT NULL, "blood_group" varchar(10) NOT NULL, "district" varchar(100) NOT NULL, "ward" varchar(100) NOT NULL, "hospital_name" varchar(255) NOT NULL, "doctor_name" varchar(200) NOT NULL, "treatment_title" varchar(255) NOT NULL, "category" varchar(100) NOT NULL, "target_amount" decimal NOT NULL, "collected_amount" decimal NOT NULL, "donors_count" integer NOT NULL, "story" text NOT NULL, "medical_estimate_summary" text NOT NULL, "is_doctor_verified" bool NOT NULL, "days_remaining" integer NOT NULL, "status" varchar(50) NOT NULL, "patient_family_gratitude_message" text NOT NULL, "use_org_qr" bool NOT NULL, "custom_upi_id" varchar(100) NOT NULL, "custom_qr_url" varchar(500) NOT NULL, "created_at" datetime NOT NULL, "cooperating_organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "finance_medicalfundraiser_cooperating_organization_id_ea7da862" ON "finance_medicalfundraiser" ("cooperating_organization_id");
COMMIT;

-- Migration: alerts.0001_initial
BEGIN;
--
-- Create model ClinicalAlert
--
CREATE TABLE "alerts_clinicalalert" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "alert_type" varchar(40) NOT NULL, "severity" varchar(20) NOT NULL, "title" varchar(255) NOT NULL, "message" text NOT NULL, "status" varchar(20) NOT NULL, "created_at" datetime NOT NULL, "acknowledged_at" datetime NULL, "acknowledged_by" varchar(150) NOT NULL, "metadata" text NOT NULL CHECK ((JSON_VALID("metadata") OR "metadata" IS NULL)), "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "patient_id" bigint NULL REFERENCES "patients_patient" ("id") DEFERRABLE INITIALLY DEFERRED, "visit_id" bigint NULL REFERENCES "visits_homevisit" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model NotificationPreference
--
CREATE TABLE "alerts_notificationpreference" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "high_risk_alerts" bool NOT NULL, "visit_alerts" bool NOT NULL, "inventory_alerts" bool NOT NULL, "blood_request_alerts" bool NOT NULL, "user_id" bigint NOT NULL UNIQUE REFERENCES "authentication_user" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model UserDevice
--
CREATE TABLE "alerts_userdevice" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "device_id" varchar(255) NOT NULL, "fcm_token" text NOT NULL, "platform" varchar(20) NOT NULL, "is_active" bool NOT NULL, "last_seen_at" datetime NOT NULL, "created_at" datetime NOT NULL, "organization_id" bigint NOT NULL REFERENCES "organizations_organization" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" bigint NOT NULL REFERENCES "authentication_user" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "alerts_clinicalalert_organization_id_69bd0ce4" ON "alerts_clinicalalert" ("organization_id");
CREATE INDEX "alerts_clinicalalert_patient_id_c0a42156" ON "alerts_clinicalalert" ("patient_id");
CREATE INDEX "alerts_clinicalalert_visit_id_fd63485f" ON "alerts_clinicalalert" ("visit_id");
CREATE UNIQUE INDEX "alerts_userdevice_user_id_device_id_bb9a02c7_uniq" ON "alerts_userdevice" ("user_id", "device_id");
CREATE INDEX "alerts_userdevice_organization_id_a3763252" ON "alerts_userdevice" ("organization_id");
CREATE INDEX "alerts_userdevice_user_id_d3d53969" ON "alerts_userdevice" ("user_id");
COMMIT;

-- Migration: admin.0001_initial
BEGIN;
--
-- Create model LogEntry
--
CREATE TABLE "django_admin_log" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "action_time" datetime NOT NULL, "object_id" text NULL, "object_repr" varchar(200) NOT NULL, "action_flag" smallint unsigned NOT NULL CHECK ("action_flag" >= 0), "change_message" text NOT NULL, "content_type_id" integer NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" bigint NOT NULL REFERENCES "authentication_user" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "django_admin_log_content_type_id_c4bce8eb" ON "django_admin_log" ("content_type_id");
CREATE INDEX "django_admin_log_user_id_c564eba6" ON "django_admin_log" ("user_id");
COMMIT;

-- Migration: sessions.0001_initial
BEGIN;
--
-- Create model Session
--
CREATE TABLE "django_session" ("session_key" varchar(40) NOT NULL PRIMARY KEY, "session_data" text NOT NULL, "expire_date" datetime NOT NULL);
CREATE INDEX "django_session_expire_date_a5c62663" ON "django_session" ("expire_date");
COMMIT;
