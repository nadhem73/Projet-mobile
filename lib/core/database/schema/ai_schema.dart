// Module IA — bilans médicaux scannés (OCR serveur ou Tesseract hors-ligne).

abstract final class AiTables {
  static const bilans = 'bilans';
  static const bilanResults = 'bilan_results';
}

const List<String> aiSchema = [
  '''
  CREATE TABLE bilans (
    bilan_id      TEXT PRIMARY KEY,          -- UUID serveur ou « local-… » (OCR hors-ligne)
    patient_id    INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    doctor_id     INTEGER REFERENCES doctors(doctor_id) ON DELETE SET NULL,
    type_bilan    TEXT,
    format        TEXT NOT NULL DEFAULT 'NOUVEAU_PATIENT',
    date_bilan    TEXT,                       -- yyyy-MM-dd lu sur le bilan
    laboratoire   TEXT,
    status        TEXT NOT NULL DEFAULT 'PENDING',
    review_status TEXT,                       -- EN_ATTENTE, LU, TRAITE
    doctor_comment TEXT,                      -- retour du médecin au patient
    image_path    TEXT,                       -- photo conservée pour un renvoi au serveur
    raw_text      TEXT,                       -- texte OCR brut
    synced        INTEGER NOT NULL DEFAULT 0, -- 0 = analysé hors-ligne, non envoyé au serveur
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  '''
  CREATE TABLE bilan_results (
    result_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    bilan_id        TEXT NOT NULL REFERENCES bilans(bilan_id) ON DELETE CASCADE,
    test_name       TEXT NOT NULL,
    valeur          TEXT,
    unite           TEXT,
    reference_min   REAL,
    reference_max   REAL,
    reference_text  TEXT,
    valeur_ancienne TEXT,
    date_ancienne   TEXT,
    status          TEXT NOT NULL DEFAULT 'NON_APPLICABLE',
    confiance       TEXT
  )
  ''',
  'CREATE INDEX idx_bilans_patient ON bilans(patient_id, created_at)',
  'CREATE INDEX idx_bilan_results_bilan ON bilan_results(bilan_id)',
];
