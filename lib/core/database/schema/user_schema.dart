// Module USER (Membre 1) — comptes, rôles, profils, dossier médical.
// Cahier des charges §10.1, §10.2, §10.3, §10.4, §10.7.

abstract final class UserTables {
  static const users = 'users';
  static const patients = 'patients';
  static const doctors = 'doctors';
  static const doctorProfiles = 'doctor_profiles';
  static const pharmacists = 'pharmacists';
  static const insurers = 'insurers';
  static const medicalRecords = 'medical_records';
}

const List<String> userSchema = [
  '''
  CREATE TABLE users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nom           TEXT NOT NULL,
    prenom        TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT NOT NULL,
    phone         TEXT,
    role          TEXT NOT NULL CHECK (role IN ('PATIENT', 'DOCTOR', 'PHARMACIST', 'INSURER')),
    created_at    TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  '''
  CREATE TABLE patients (
    patient_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    cin            TEXT UNIQUE,
    date_naissance TEXT,
    adresse        TEXT,
    user_id        INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE doctors (
    doctor_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    license_number TEXT NOT NULL UNIQUE,
    specialty      TEXT NOT NULL,
    user_id        INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE doctor_profiles (
    doctor_profile_id INTEGER PRIMARY KEY AUTOINCREMENT,
    biography         TEXT,
    fee               REAL,
    working_hours     TEXT, -- JSON : {"mon":["08:00-12:00","14:00-17:00"], ...}
    address           TEXT,
    city              TEXT,
    doctor_id         INTEGER NOT NULL UNIQUE REFERENCES doctors(doctor_id) ON DELETE CASCADE
  )
  ''',
  // Compte pharmacien : une pharmacie d'officine.
  '''
  CREATE TABLE pharmacists (
    pharmacist_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    pharmacy_name  TEXT NOT NULL,
    license_number TEXT NOT NULL UNIQUE, -- numéro d'autorisation d'exercice
    address        TEXT,
    city           TEXT,
    user_id        INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
  )
  ''',
  // Compte assureur : agent d'une caisse / compagnie (CNAM, STAR, COMAR...).
  '''
  CREATE TABLE insurers (
    insurer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    company    TEXT NOT NULL,
    agent_code TEXT NOT NULL UNIQUE, -- matricule de l'agent
    user_id    INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE medical_records (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    allergies               TEXT,
    blood_group             TEXT CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    chronic_diseases        TEXT,
    current_treatment       TEXT,
    emergency_contact_name  TEXT,
    emergency_contact_phone TEXT,
    height                  REAL, -- cm
    weight                  REAL, -- kg
    insurance_company       TEXT,
    insurance_number        TEXT,
    gender                  TEXT CHECK (gender IN ('M', 'F')),
    updated_at              TEXT NOT NULL DEFAULT (datetime('now')),
    patient_id              INTEGER NOT NULL UNIQUE REFERENCES patients(patient_id) ON DELETE CASCADE
  )
  ''',
  'CREATE INDEX idx_doctors_specialty ON doctors(specialty)',
];
