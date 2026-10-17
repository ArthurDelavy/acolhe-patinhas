CREATE TYPE report_type AS ENUM ('LOST', 'FOUND', 'ABANDONED');

CREATE TYPE report_status AS ENUM ('OPEN', 'RESOLVED', 'CANCELLED');

CREATE TABLE animal_reports (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    type report_type NOT NULL,
    status report_status NOT NULL DEFAULT 'OPEN',
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    image_url VARCHAR(255),
    location GEOGRAPHY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);