-- OPTIONAL POSTGRESQL EXAMPLE ONLY; not required for other record stores.
-- PROPOSAL ONLY. Inspect the live schema, adapt ID types/foreign keys/field
-- mappings, and obtain explicit migration approval before executing.
-- Reuse existing exercise tables where suitable. Never create a database here.
-- New standalone catalog is optional, not a replacement for existing exercises.
-- Two-sheet batch contract: generation slots belong to batches; exercise pairs
-- reference regions in the same two sheets. This is not a live migration.
-- Existing per-exercise schemas need an inspected, separately approved adaptation.
BEGIN;
CREATE SCHEMA IF NOT EXISTS exercise_images;
CREATE TABLE exercise_images.exercise_image_catalog (
  collection_id text NOT NULL,
  exercise_key text NOT NULL,
  original_name text NOT NULL,
  exercise_name text NOT NULL,
  variant text NOT NULL,
  side text NOT NULL,
  external_exercise_id text,
  PRIMARY KEY (collection_id, exercise_key)
);
CREATE TABLE exercise_images.exercise_image_runs (
  run_id text PRIMARY KEY,
  collection_id text NOT NULL,
  input_sha256 text NOT NULL CHECK (input_sha256 ~ '^[a-f0-9]{64}$'),
  profile_sha256 text NOT NULL CHECK (profile_sha256 ~ '^[a-f0-9]{64}$'),
  review_every_pair boolean NOT NULL,
  state_revision bigint NOT NULL DEFAULT 0,
  state jsonb NOT NULL DEFAULT '{}'::jsonb,
  durable_bundle_reference text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE exercise_images.exercise_image_batches (
  collection_id text NOT NULL,
  batch_key text NOT NULL,
  revision integer NOT NULL CHECK (revision > 0),
  run_id text NOT NULL REFERENCES exercise_images.exercise_image_runs(run_id),
  occupied_panels integer NOT NULL CHECK (occupied_panels BETWEEN 1 AND 6),
  grid_columns integer NOT NULL DEFAULT 3 CHECK (grid_columns = 3),
  grid_rows integer NOT NULL DEFAULT 2 CHECK (grid_rows = 2),
  manifest jsonb NOT NULL CHECK (jsonb_typeof(manifest) = 'array'),
  manifest_sha256 text NOT NULL CHECK (manifest_sha256 ~ '^[a-f0-9]{64}$'),
  profile_sha256 text NOT NULL CHECK (profile_sha256 ~ '^[a-f0-9]{64}$'),
  status text NOT NULL,
  lease_owner text,
  lease_expires_at timestamptz,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (collection_id, batch_key, revision),
  CHECK (jsonb_array_length(manifest) = occupied_panels)
);
CREATE TABLE exercise_images.exercise_image_items (
  run_id text NOT NULL REFERENCES exercise_images.exercise_image_runs(run_id),
  collection_id text NOT NULL,
  exercise_key text NOT NULL,
  revision integer NOT NULL CHECK (revision > 0),
  batch_key text NOT NULL,
  panel_index integer NOT NULL CHECK (panel_index BETWEEN 1 AND 6),
  cell_rect jsonb NOT NULL CHECK (jsonb_typeof(cell_rect) = 'array' AND jsonb_array_length(cell_rect) = 4),
  input_order integer NOT NULL CHECK (input_order >= 0),
  status text NOT NULL,
  clinical_spec jsonb NOT NULL,
  review_status text NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending','approved','rejected','not_requested')),
  clinical_status text NOT NULL DEFAULT 'unverified'
    CHECK (clinical_status IN ('unverified','ai_checked','clinician_verified')),
  lease_owner text,
  lease_expires_at timestamptz,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (run_id, exercise_key, revision),
  UNIQUE (collection_id, batch_key, revision, panel_index),
  FOREIGN KEY (collection_id, batch_key, revision)
    REFERENCES exercise_images.exercise_image_batches(collection_id, batch_key, revision),
  FOREIGN KEY (collection_id, exercise_key)
    REFERENCES exercise_images.exercise_image_catalog(collection_id, exercise_key)
);
CREATE TABLE exercise_images.exercise_image_slots (
  collection_id text NOT NULL,
  batch_key text NOT NULL,
  revision integer NOT NULL CHECK (revision > 0),
  style text NOT NULL CHECK (style IN ('colorful','pencil')),
  run_id text NOT NULL REFERENCES exercise_images.exercise_image_runs(run_id),
  status text NOT NULL DEFAULT 'reserved',
  generation_calls integer NOT NULL DEFAULT 1 CHECK (generation_calls = 1),
  provider_result_id text,
  prompt_sha256 text NOT NULL,
  output_reference text,
  output_sha256 text,
  reserved_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (collection_id, batch_key, revision, style),
  FOREIGN KEY (collection_id, batch_key, revision)
    REFERENCES exercise_images.exercise_image_batches(collection_id, batch_key, revision)
);
CREATE TABLE exercise_images.exercise_image_pairs (
  collection_id text NOT NULL,
  exercise_key text NOT NULL,
  revision integer NOT NULL CHECK (revision > 0),
  run_id text NOT NULL REFERENCES exercise_images.exercise_image_runs(run_id),
  batch_key text NOT NULL,
  panel_index integer NOT NULL CHECK (panel_index BETWEEN 1 AND 6),
  cell_rect jsonb NOT NULL CHECK (jsonb_typeof(cell_rect) = 'array' AND jsonb_array_length(cell_rect) = 4),
  manifest_sha256 text NOT NULL CHECK (manifest_sha256 ~ '^[a-f0-9]{64}$'),
  exercise_name text NOT NULL,
  variant text NOT NULL,
  side text NOT NULL,
  profile_sha256 text NOT NULL CHECK (profile_sha256 ~ '^[a-f0-9]{64}$'),
  clinical_spec_sha256 text NOT NULL CHECK (clinical_spec_sha256 ~ '^[a-f0-9]{64}$'),
  colorful jsonb NOT NULL CHECK (jsonb_typeof(colorful) = 'object'
    AND colorful ?& ARRAY['provider','account_id','container','asset_key','durable_reference','sha256','width','height','access_mode','content_type','bytes','panel_index','cell_rect','manifest_sha256']),
  pencil jsonb NOT NULL CHECK (jsonb_typeof(pencil) = 'object'
    AND pencil ?& ARRAY['provider','account_id','container','asset_key','durable_reference','sha256','width','height','access_mode','content_type','bytes','panel_index','cell_rect','manifest_sha256']),
  review_status text NOT NULL CHECK (review_status IN ('approved','not_requested')),
  clinical_status text NOT NULL CHECK (clinical_status IN ('ai_checked','clinician_verified')),
  validation_evidence jsonb NOT NULL,
  published_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (collection_id, exercise_key, revision),
  UNIQUE (collection_id, batch_key, revision, panel_index),
  FOREIGN KEY (collection_id, batch_key, revision)
    REFERENCES exercise_images.exercise_image_batches(collection_id, batch_key, revision),
  FOREIGN KEY (collection_id, exercise_key)
    REFERENCES exercise_images.exercise_image_catalog(collection_id, exercise_key)
);
-- Keep internal workflow records out of public by default. Do not expose this
-- schema through the Data API without an approved access plan.
ALTER TABLE exercise_images.exercise_image_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_images.exercise_image_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_images.exercise_image_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_images.exercise_image_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_images.exercise_image_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_images.exercise_image_pairs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON SCHEMA exercise_images FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA exercise_images FROM PUBLIC;
CREATE INDEX exercise_image_items_catalog_idx
  ON exercise_images.exercise_image_items (collection_id, exercise_key);
CREATE INDEX exercise_image_items_next_idx
  ON exercise_images.exercise_image_items (run_id, status, input_order);
CREATE INDEX exercise_image_slots_run_idx
  ON exercise_images.exercise_image_slots (run_id);
CREATE INDEX exercise_image_pairs_run_idx
  ON exercise_images.exercise_image_pairs (run_id);
COMMIT;
-- This optional PostgreSQL proposal is private and fail-closed. It does not
-- grant a caller role or implement collection authorization. Adapt the actual
-- deployment roles/policies before publication. Other databases may use their
-- own schema, constraints, and equivalent atomic whole-batch operations.
-- The adapter must enforce leases, unique batch/style reservations, revision
-- guards, complete manifest membership, matching sheet identities/rectangles,
-- hashes and evidence in one atomic commit. Structural CHECK constraints are
-- neither clinical verification nor a full application transaction.
-- File/object operations use the selected storage API, never SQL metadata writes.
-- Canonical asset records use generic provider/account/container/key locators.
-- No vendor-specific project or bucket identity is required.
