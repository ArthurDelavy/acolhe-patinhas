CREATE TABLE term_versions(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version VARCHAR(10) NOT NULL UNIQUE,
    file_path VARCHAR(100) NOT NULL UNIQUE,
    content_hash VARCHAR(64) NOT NULL UNIQUE,
    effective_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_current BOOLEAN NOT NULL
);


CREATE UNIQUE INDEX uq_term_versions_single_current 
ON term_versions (is_current) 
WHERE is_current = TRUE;



CREATE TABLE term_agreements (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  term_version_id INTEGER NOT NULL REFERENCES term_versions(id) ON DELETE RESTRICT,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ip_address VARCHAR(45) NOT NULL,

  CONSTRAINT uq_user_term_version UNIQUE (user_id, term_version_id)
);