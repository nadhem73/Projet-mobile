// Module ASSURANCE (Membre 3).
// ⚠️ PROPOSITION : ce module n'est pas décrit dans le cahier des charges.
// Le responsable du module peut modifier ce fichier librement.

abstract final class InsuranceTables {
  static const contracts = 'insurance_contracts';
  static const claims = 'insurance_claims';
}

const List<String> insuranceSchema = [
  // Contrat d'assurance / mutuelle (CNAM, assurance privée...) du patient.
  '''
  CREATE TABLE insurance_contracts (
    contract_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id     INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    company        TEXT NOT NULL,           -- ex. CNAM, STAR, COMAR, GAT...
    policy_number  TEXT NOT NULL,
    coverage_rate  REAL NOT NULL DEFAULT 0.7 CHECK (coverage_rate BETWEEN 0 AND 1),
    start_date     TEXT,
    end_date       TEXT,
    status         TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','EXPIRED','SUSPENDED'))
  )
  ''',
  // Demande de remboursement (bulletin de soins) liée à une consultation ou ordonnance.
  '''
  CREATE TABLE insurance_claims (
    claim_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    contract_id       INTEGER NOT NULL REFERENCES insurance_contracts(contract_id) ON DELETE CASCADE,
    consultation_id   INTEGER REFERENCES consultations(consultation_id) ON DELETE SET NULL,
    prescription_id   INTEGER REFERENCES prescriptions(prescription_id) ON DELETE SET NULL,
    amount            REAL NOT NULL,
    reimbursed_amount REAL,
    status            TEXT NOT NULL DEFAULT 'SUBMITTED'
                      CHECK (status IN ('SUBMITTED','APPROVED','REJECTED','PAID')),
    document_path     TEXT,
    submitted_at      TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
];
