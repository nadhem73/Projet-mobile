// Module RENDEZ-VOUS (Membre 2) — prise de rendez-vous, agenda.
// Cahier des charges §10.5 + règle §14 « un créneau ne doit pas être réservé
// simultanément par plusieurs patients ».

abstract final class AppointmentTables {
  static const appointments = 'appointments';
}

/// Statuts possibles d'un rendez-vous (colonne `appointments.status`).
abstract final class AppointmentStatus {
  static const pending = 'PENDING';
  static const confirmed = 'CONFIRMED';
  static const cancelled = 'CANCELLED';
  static const completed = 'COMPLETED';
  static const noShow = 'NO_SHOW';
}

const List<String> appointmentSchema = [
  '''
  CREATE TABLE appointments (
    appointment_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_date_time TEXT NOT NULL, -- ISO 8601 : 2026-10-20T09:30:00
    reason                TEXT,
    status                TEXT NOT NULL DEFAULT 'PENDING'
                          CHECK (status IN ('PENDING','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW')),
    created_at            TEXT NOT NULL DEFAULT (datetime('now')),
    doctor_id             INTEGER NOT NULL REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    patient_id            INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE
  )
  ''',
  // Un seul rendez-vous actif par médecin et par créneau.
  '''
  CREATE UNIQUE INDEX ux_appointments_slot
    ON appointments(doctor_id, appointment_date_time)
    WHERE status <> 'CANCELLED'
  ''',
  'CREATE INDEX idx_appointments_patient ON appointments(patient_id)',
];
