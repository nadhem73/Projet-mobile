// Module PHARMACIE (Membre 4).
// Le catalogue des médicaments est dans PostgreSQL (voir database/postgres/).
// ⚠️ PROPOSITION pour les données locales : le responsable du module peut
// modifier ce fichier librement.

abstract final class PharmacyTables {
  static const orders = 'pharmacy_orders';
  static const orderItems = 'pharmacy_order_items';
  static const reminders = 'medication_reminders';
}

const List<String> pharmacySchema = [
  '''
  CREATE TABLE pharmacy_orders (
    order_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id       INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    prescription_id  INTEGER REFERENCES prescriptions(prescription_id) ON DELETE SET NULL,
    status           TEXT NOT NULL DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING','CONFIRMED','READY','DELIVERED','CANCELLED')),
    total            REAL NOT NULL DEFAULT 0,
    delivery_address TEXT,
    created_at       TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  '''
  CREATE TABLE pharmacy_order_items (
    order_item_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id        INTEGER NOT NULL REFERENCES pharmacy_orders(order_id) ON DELETE CASCADE,
    medicament_id   INTEGER NOT NULL, -- id PostgreSQL
    medicament_name TEXT NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price      REAL NOT NULL DEFAULT 0
  )
  ''',
  // Rappels de prise de médicaments.
  '''
  CREATE TABLE medication_reminders (
    reminder_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id      INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    medicament_name TEXT NOT NULL,
    dosage          TEXT,
    times           TEXT NOT NULL, -- JSON : ["08:00","20:00"]
    start_date      TEXT,
    end_date        TEXT,
    active          INTEGER NOT NULL DEFAULT 1
  )
  ''',
];
