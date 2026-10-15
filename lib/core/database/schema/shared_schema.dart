// Tables transverses : notifications (§6.4) et bilans OCR (§6.5 / §8.1).

abstract final class SharedTables {
  static const notifications = 'notifications';
  static const labResults = 'lab_results';
}

const List<String> sharedSchema = [
  '''
  CREATE TABLE notifications (
    notification_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            TEXT NOT NULL, -- APPOINTMENT, PRESCRIPTION, INSURANCE, PHARMACY, SYSTEM
    title           TEXT NOT NULL,
    body            TEXT,
    payload         TEXT,          -- JSON optionnel (ex. {"prescriptionId": 3})
    is_read         INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  '''
  CREATE TABLE lab_results (
    lab_result_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id     INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    title          TEXT,
    image_path     TEXT,
    raw_text       TEXT,   -- texte brut Tesseract
    extracted_json TEXT,   -- valeurs structurées validées par le patient
    validated      INTEGER NOT NULL DEFAULT 0,
    created_at     TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  'CREATE INDEX idx_notifications_user ON notifications(user_id, is_read)',
];
