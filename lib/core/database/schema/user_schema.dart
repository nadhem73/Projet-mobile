// Module USER (Membre 1) — comptes, rôles, sécurité, profils, dossier médical.
// Cahier des charges §10.1, §10.2, §10.3, §10.4, §10.7, §13.1.

abstract final class UserTables {
  static const users = 'users';
  static const passwordResetCodes = 'password_reset_codes';
  static const patients = 'patients';
  static const dependents = 'dependents';
  static const doctors = 'doctors';
  static const doctorProfiles = 'doctor_profiles';
  static const pharmacists = 'pharmacists';
  static const insurers = 'insurers';
  static const medicalRecords = 'medical_records';
  static const vaccinations = 'vaccinations';
  static const medicalDocuments = 'medical_documents';
  static const recordAccessLog = 'medical_record_access_log';
}

/// Statuts d'un compte (colonne `users.status`).
abstract final class AccountStatus {
  /// Compte utilisable.
  static const active = 'ACTIVE';

  /// Compte professionnel en attente de validation par un administrateur.
  static const pending = 'PENDING';

  /// Demande refusée par un administrateur (voir `rejection_reason`).
  static const rejected = 'REJECTED';

  /// Compte bloqué par un administrateur.
  static const suspended = 'SUSPENDED';
}

const List<String> userSchema = [
  '''
  CREATE TABLE users (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    nom              TEXT NOT NULL,
    prenom           TEXT NOT NULL,
    email            TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash    TEXT NOT NULL,
    phone            TEXT,
    role             TEXT NOT NULL CHECK (role IN ('PATIENT', 'DOCTOR', 'PHARMACIST', 'INSURER', 'ADMIN')),
    status           TEXT NOT NULL DEFAULT 'ACTIVE'
                     CHECK (status IN ('ACTIVE', 'PENDING', 'REJECTED', 'SUSPENDED')),
    rejection_reason TEXT,
    failed_attempts  INTEGER NOT NULL DEFAULT 0, -- échecs de connexion consécutifs
    locked_until     TEXT,                       -- blocage temporaire après 5 échecs
    avatar           BLOB,                       -- photo de profil (JPEG)
    created_at       TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  // Codes de réinitialisation du mot de passe (envoyés par SMS, stockés hachés).
  '''
  CREATE TABLE password_reset_codes (
    code_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash  TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    attempts   INTEGER NOT NULL DEFAULT 0,
    used       INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
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
  // Proches gérés par un patient (enfants, parents...).
  '''
  CREATE TABLE dependents (
    dependent_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id     INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    nom            TEXT NOT NULL,
    prenom         TEXT NOT NULL,
    relation       TEXT NOT NULL, -- CHILD, SPOUSE, PARENT, OTHER
    date_naissance TEXT,
    gender         TEXT CHECK (gender IN ('M', 'F')),
    blood_group    TEXT CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    allergies      TEXT,
    created_at     TEXT NOT NULL DEFAULT (datetime('now'))
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
    surgical_history        TEXT, -- antécédents chirurgicaux
    family_history          TEXT, -- antécédents familiaux
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
  '''
  CREATE TABLE vaccinations (
    vaccination_id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id     INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    date           TEXT NOT NULL, -- AAAA-MM-JJ
    dose           TEXT,          -- ex. « 2e dose », « rappel »
    notes          TEXT
  )
  ''',
  // Documents joints au dossier (photo d'une analyse, d'une radio...).
  '''
  CREATE TABLE medical_documents (
    document_id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id  INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    category    TEXT NOT NULL, -- ANALYSIS, IMAGING, PRESCRIPTION, REPORT, OTHER
    data        BLOB NOT NULL, -- image JPEG
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  // Traçabilité : quel médecin a consulté quel dossier, et quand.
  '''
  CREATE TABLE medical_record_access_log (
    access_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id  INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    doctor_id   INTEGER NOT NULL REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    accessed_at TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  'CREATE INDEX idx_doctors_specialty ON doctors(specialty)',
  'CREATE INDEX idx_users_status ON users(status, role)',
  'CREATE INDEX idx_access_log_patient ON medical_record_access_log(patient_id, accessed_at)',
];
