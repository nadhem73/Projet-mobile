-- =============================================================================
-- MediLink Tunisia — Dataset des médicaments (PostgreSQL)
-- Cahier des charges §9.2 / §10.8. Module Pharmacie (Membre 4).
--
-- Création :
--   createdb medilink_medicaments
--   psql -d medilink_medicaments -f database/postgres/medicaments.sql
--
-- L'application mobile n'accède PAS directement à PostgreSQL : elle passe par
-- une API intermédiaire (voir AppConfig.medicamentsApiUrl).
-- =============================================================================

DROP TABLE IF EXISTS medicament;

CREATE TABLE medicament (
    medicament_id SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    dosage        VARCHAR(100),
    forme         VARCHAR(100),           -- comprimé, sirop, gélule...
    presentation  VARCHAR(200),           -- ex. « Boîte de 20 comprimés »
    price         NUMERIC(10, 3),         -- en dinars tunisiens (TND)
    dci           VARCHAR(200),           -- dénomination commune internationale
    type          VARCHAR(50)             -- princeps / générique
);

-- Recherche rapide par nom et DCI (insensible à la casse)
CREATE INDEX idx_medicament_name ON medicament (LOWER(name));
CREATE INDEX idx_medicament_dci ON medicament (LOWER(dci));

-- Quelques lignes d'exemple (à remplacer par le dataset complet)
INSERT INTO medicament (name, dosage, forme, presentation, price, dci, type) VALUES
  ('Doliprane',   '1000 mg', 'Comprimé',          'Boîte de 8 comprimés',      2.450, 'Paracétamol',          'Princeps'),
  ('Efferalgan',  '500 mg',  'Comprimé effervescent', 'Boîte de 16 comprimés', 3.100, 'Paracétamol',          'Princeps'),
  ('Augmentin',   '1 g',     'Comprimé pelliculé', 'Boîte de 12 comprimés',    14.800, 'Amoxicilline + Acide clavulanique', 'Princeps'),
  ('Amoxil',      '500 mg',  'Gélule',            'Boîte de 12 gélules',        5.600, 'Amoxicilline',         'Générique'),
  ('Ventoline',   '100 µg',  'Suspension pour inhalation', 'Flacon de 200 doses', 9.900, 'Salbutamol',      'Princeps'),
  ('Spasfon',     '80 mg',   'Comprimé',          'Boîte de 30 comprimés',      4.200, 'Phloroglucinol',       'Princeps'),
  ('Glucophage',  '850 mg',  'Comprimé',          'Boîte de 30 comprimés',      3.750, 'Metformine',           'Princeps'),
  ('Aerius',      '5 mg',    'Comprimé',          'Boîte de 15 comprimés',      8.300, 'Desloratadine',        'Princeps');
