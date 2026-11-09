// Module PHARMACY (Pharmacien) — gestion pharmacies, médicaments, stock.
// Pharmacien user role, medicine catalog, per-pharmacy inventory, pharmacy finder.

abstract final class PharmacyPharmacienTables {
  static const pharmacies = 'pharmacies';
  static const medicines = 'medicines';
  static const pharmacyStock = 'pharmacy_stock';
}

const List<String> pharmacyPharmacienSchema = [
  '''
  CREATE TABLE pharmacies (
    pharmacy_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    pharmacien_user_id INTEGER NOT NULL UNIQUE,
    name               TEXT NOT NULL,
    address            TEXT NOT NULL,
    latitude           REAL NOT NULL,
    longitude          REAL NOT NULL,
    phone              TEXT,
    email              TEXT,
    photo_url          TEXT,
    opening_hours      TEXT,  -- JSON: {"monday":"08:00-18:00", "tuesday":"08:00-18:00", ...}
    created_at         TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at         TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (pharmacien_user_id) REFERENCES users(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE medicines (
    medicine_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name                 TEXT NOT NULL,
    dosage               TEXT,
    forme                TEXT,
    presentation         TEXT,
    price                REAL NOT NULL,
    remboursement        REAL,
    dci                  TEXT,
    type                 TEXT,
    prescription_required INTEGER NOT NULL DEFAULT 0,  -- 0=Non, 1=Oui
    image_url            TEXT,
    created_at           TEXT NOT NULL DEFAULT (datetime('now'))
  )
  ''',
  '''
  CREATE TABLE pharmacy_stock (
    stock_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    pharmacy_id        INTEGER NOT NULL,
    medicine_id        INTEGER NOT NULL,
    in_stock           INTEGER NOT NULL DEFAULT 1,  -- 0=rupture, 1=available
    quantity           INTEGER NOT NULL DEFAULT 0,
    shelf_location     TEXT,  -- emplacement (A12, B18, Rayon5, etc.)
    custom_price       REAL,  -- Prix de vente specifique a cette pharmacie (DT)
    expiration_date    TEXT,
    manufacturing_date TEXT,
    last_restock_date  TEXT,
    created_at         TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at         TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(pharmacy_id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id) ON DELETE CASCADE,
    UNIQUE(pharmacy_id, medicine_id)  -- One stock entry per pharmacy per medicine
  )
  ''',
  // Indexes for fast search and lookups
  'CREATE INDEX idx_medicines_name ON medicines(name COLLATE NOCASE)',
  'CREATE INDEX idx_medicines_dci ON medicines(dci COLLATE NOCASE)',
  'CREATE INDEX idx_medicines_type ON medicines(type)',
  'CREATE INDEX idx_medicines_forme ON medicines(forme)',
  'CREATE INDEX idx_pharmacy_stock_pharmacy ON pharmacy_stock(pharmacy_id)',
  'CREATE INDEX idx_pharmacy_stock_medicine ON pharmacy_stock(medicine_id)',
  'CREATE INDEX idx_pharmacy_stock_in_stock ON pharmacy_stock(in_stock)',
  'CREATE INDEX idx_pharmacy_stock_expiration ON pharmacy_stock(expiration_date)',
];
