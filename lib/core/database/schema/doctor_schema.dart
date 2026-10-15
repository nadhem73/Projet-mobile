// Module MÉDECIN (Membre 5) — consultations et ordonnances.
// Cahier des charges §10.6, §10.9, §10.10.

abstract final class DoctorTables {
  static const consultations = 'consultations';
  static const prescriptions = 'prescriptions';
  static const prescriptionItems = 'prescription_items';
}

const List<String> doctorSchema = [
  '''
  CREATE TABLE consultations (
    consultation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id  INTEGER UNIQUE REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    doctor_id       INTEGER NOT NULL REFERENCES doctors(doctor_id),
    patient_id      INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    blood_pressure  TEXT,    -- ex. "12/8"
    temperature     REAL,    -- °C
    height          REAL,    -- cm
    weight          REAL,    -- kg
    bmi             REAL,
    observation     TEXT,
    start_time      TEXT,
    end_time        TEXT,
    follow_up_date  TEXT,
    status          TEXT NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS','CLOSED'))
  )
  ''',
  '''
  CREATE TABLE prescriptions (
    prescription_id INTEGER PRIMARY KEY AUTOINCREMENT,
    consultation_id INTEGER REFERENCES consultations(consultation_id) ON DELETE SET NULL,
    doctor_id       INTEGER NOT NULL REFERENCES doctors(doctor_id),
    patient_id      INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    note            TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  // medicament_id référence la table Medicament de PostgreSQL (autre base) :
  // pas de clé étrangère possible, on garde une copie du nom pour l'affichage.
  '''
  CREATE TABLE prescription_items (
    prescription_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    prescription_id      INTEGER NOT NULL REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    medicament_id        INTEGER,
    medicament_name      TEXT NOT NULL,
    dosage               TEXT,
    duree_traitement     TEXT,
    forme                TEXT,
    instruction          TEXT,
    posologie            TEXT,
    voie_administration  TEXT
  )
  ''',
  'CREATE INDEX idx_consultations_patient ON consultations(patient_id)',
  'CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id)',
];
