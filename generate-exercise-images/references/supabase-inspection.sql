-- OPTIONAL SUPABASE ADAPTER ONLY; do not run for other providers.
-- SELECT-only inspection templates. Confirm the intended project first.
-- No writes, migrations, bucket creation or raw exercise/patient rows.
SELECT current_database() AS database_name,
       current_user AS database_role,
       current_schema() AS current_schema;

-- Find application tables, excluding Supabase-managed schemas.
-- An empty result under a restricted role does not prove tables do not exist.
SELECT n.nspname AS schema_name, c.relname AS table_name,
       c.relrowsecurity AS rls_enabled
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN (
    'pg_catalog','information_schema','auth','storage','realtime',
    'extensions','supabase_functions','supabase_migrations','graphql',
    'graphql_public','vault','net','cron','pgsodium','pgsodium_masks'
  )
  AND n.nspname NOT LIKE 'pg_%'
ORDER BY n.nspname, c.relname;

-- Adapt candidate names after table discovery; inspect only likely exercise
-- tables. Do not assume a table is named exercises.
SELECT table_schema, table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name ILIKE '%exercise%'
ORDER BY table_schema, table_name, ordinal_position;

-- Read bucket settings only if current credentials permit this metadata query.
-- Actual file upload/download operations must use the Storage API.
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
ORDER BY id;
