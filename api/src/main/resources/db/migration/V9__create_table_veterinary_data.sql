CREATE TABLE veterinary_records (
    id INTEGER PRIMARY KEY REFERENCES animals(id) ON DELETE CASCADE,
    size_cm INTEGER,
    weight DECIMAL(5,2),
    neutered BOOLEAN NOT NULL
);

CREATE TABLE vaccines (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE vaccinations (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_record_id INTEGER NOT NULL REFERENCES veterinary_records(id) ON DELETE CASCADE,
    vaccine_id INTEGER NOT NULL REFERENCES vaccines(id) ON DELETE RESTRICT,
    dose VARCHAR(10) NOT NULL,
    manufacturer VARCHAR(50),
    batch_number VARCHAR(50),
    vaccination_date DATE,
    next_dose_date DATE
);

CREATE TABLE diseases (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TYPE disease_status AS ENUM ('ACTIVE', 'HEALED', 'CHRONIC');

CREATE TABLE diagnoses (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_record_id INTEGER NOT NULL REFERENCES veterinary_records(id) ON DELETE CASCADE,
    disease_id INTEGER NOT NULL REFERENCES diseases(id) ON DELETE RESTRICT,
    diagnosed_at DATE,
    status disease_status NOT NULL DEFAULT 'ACTIVE'
);

CREATE TYPE treatment_status AS ENUM ('PENDING', 'STARTED', 'FINISHED', 'CANCELED');

CREATE TABLE treatments (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_record_id INTEGER NOT NULL REFERENCES veterinary_records(id) ON DELETE CASCADE,
    diagnosis_id INTEGER REFERENCES diagnoses(id) ON DELETE RESTRICT,
    start_date DATE,
    end_date DATE,
    status treatment_status NOT NULL DEFAULT 'PENDING',
    observations TEXT
);

CREATE TABLE medicines (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE treatment_medicines (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    treatment_id INTEGER NOT NULL REFERENCES treatments(id) ON DELETE CASCADE,
    medicine_id INTEGER NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    dosage VARCHAR(30) NOT NULL,
    frequency VARCHAR(30) NOT NULL,
    duration_days INTEGER NOT NULL,
    start_date DATE NOT NULL
);

CREATE TABLE surgical_procedures (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE surgeries (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_record_id INTEGER NOT NULL REFERENCES veterinary_records(id) ON DELETE CASCADE,
    procedure_id INTEGER NOT NULL REFERENCES surgical_procedures(id) ON DELETE RESTRICT,
    procedure_date DATE NOT NULL,
    observations TEXT
);

CREATE TABLE preventive_procedures (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    default_frequency_days SMALLINT NOT NULL    
);

CREATE TABLE preventive_care (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_record_id INTEGER NOT NULL REFERENCES veterinary_records(id) ON DELETE CASCADE,
    procedure_id INTEGER NOT NULL REFERENCES preventive_procedures(id) ON DELETE RESTRICT,
    medicine_id INTEGER REFERENCES medicines(id) ON DELETE RESTRICT,
    procedure_date DATE NOT NULL,
    next_procedure_date DATE,
    observations TEXT
);

CREATE TABLE lab_test_types(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE lab_test_results (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_record_id INTEGER NOT NULL REFERENCES veterinary_records(id) ON DELETE CASCADE,
    lab_test_id INTEGER NOT NULL REFERENCES lab_test_types(id) ON DELETE RESTRICT,
    test_date TIMESTAMPTZ NOT NULL,
    results TEXT NOT NULL,
    observations TEXT    
);