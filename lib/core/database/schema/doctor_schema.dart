// Module MÉDECIN (Membre 5) — consultations et ordonnances.
// Cahier des charges §10.6, §10.9, §10.10.

abstract final class DoctorTables {
  static const consultations = 'consultations';
  static const prescriptions = 'prescriptions';
  static const prescriptionItems = 'prescription_items';

  /// Demandes de bilan (analyses à réaliser) rédigées pendant une consultation.
  static const labRequests = 'lab_requests';

  /// Plages où le médecin n'est pas disponible (réunion, pause…) : aucun rendez-vous possible.
  static const blockedSlots = 'doctor_blocked_slots';
}

/// Statuts possibles d'une consultation (colonne `consultations.status`).
abstract final class ConsultationStatus {
  static const inProgress = 'IN_PROGRESS';
  static const closed = 'CLOSED';
}

const List<String> doctorSchema = [
  '''
  CREATE TABLE consultations (
    consultation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id  INTEGER UNIQUE REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    doctor_id       INTEGER NOT NULL REFERENCES doctors(doctor_id),
    patient_id      INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    motif           TEXT,    -- motif de consultation
    diagnostic      TEXT,
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
  // medicament_id référence medicines.medicine_id (catalogue du module Pharmacie).
  // Pas de clé étrangère (tables de modules distincts) : on garde une copie du nom pour l'affichage.
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
  // Demande de bilan : liste des analyses à faire au laboratoire. Comme les
  // ordonnances, elle n'est visible du patient qu'après la clôture de la consultation.
  '''
  CREATE TABLE lab_requests (
    lab_request_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    consultation_id INTEGER REFERENCES consultations(consultation_id) ON DELETE SET NULL,
    doctor_id       INTEGER NOT NULL REFERENCES doctors(doctor_id),
    patient_id      INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    tests           TEXT NOT NULL,   -- JSON : ["NFS","Glycémie à jeun"]
    note            TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  // Indisponibilités du médecin : les patients ne peuvent pas réserver sur ces plages.
  '''
  CREATE TABLE doctor_blocked_slots (
    blocked_slot_id INTEGER PRIMARY KEY AUTOINCREMENT,
    doctor_id       INTEGER NOT NULL REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    title           TEXT NOT NULL,   -- ex. "Réunion de service"
    start_time      TEXT NOT NULL,   -- 2026-11-10T09:00:00 (heure locale)
    end_time        TEXT NOT NULL,
    note            TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    CHECK (end_time > start_time)
  )
  ''',
  'CREATE INDEX idx_blocked_slots_doctor ON doctor_blocked_slots(doctor_id, start_time)',
  'CREATE INDEX idx_consultations_patient ON consultations(patient_id)',
  'CREATE INDEX idx_consultations_doctor ON consultations(doctor_id, status)',
  'CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id)',
  'CREATE INDEX idx_lab_requests_patient ON lab_requests(patient_id)',
];
