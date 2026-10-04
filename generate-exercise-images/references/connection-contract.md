# Provider-neutral connection and publication contract

## Boundary and selection

This is a capability specification, not an implemented connector. Discover actual tools and read their schemas; save a mapping from the capabilities below to the selected tools. Do not invent tool names or promise support merely because a vendor is listed. Choose generation, database/record store, image storage, and private run store independently. There is no mandatory vendor, SQL dialect, bucket service, or host. Read provider-adapters.md for selection examples and Supabase-only inspection guidance.

Keep inspection read-only. Resolve exact accounts/environments and intended targets before querying data; distinguish missing targets from permission errors. Do not create schemas, containers, policies, functions, or test records during inspection. Use host-supported authentication; keep secrets on the trusted server. An imported skill must not inherit another person's account targets, credentials, or authorization. Runtime configuration belongs outside the installed skill.

## Required publishing capabilities

| Area | Capability and evidence |
| --- | --- |
| Generation | One output per request, full-sheet reference editing, full-resolution inspection, preservable original bytes; selected tool/provider/model |
| Identity | Approved exact record-store and storage accounts, connection aliases, environments, namespaces and caller identities |
| Image storage | Verified container/folder, access mode, size/MIME limits, allowed key prefix, create-only upload, lookup, full-byte readback |
| Record store | Exercise ID/name mapping, types, uniqueness, relationships, and caller/collection authorization |
| Runs/batches/items | Restore ordered manifests, hashes, states, approvals, sheet artifacts and errors |
| Generation slots | Atomic unique batch/style reservation and exclusive batch lease across sessions/runs |
| Pair publication | One atomic commit of both sheet identities, all exercise/panel references, evidence and batch completion; unique batch/revision and exercise/revision keys |
| Durable files | Verified private durable store for input, cartoon anchor, prompts, original bytes, run.json and progress.md |

Require a database transaction or demonstrably equivalent atomic whole-batch operation. A conditional write of one aggregate batch document may qualify if it atomically includes every member reference, enforces uniqueness and revision/lease checks, and readers cannot observe partial publication. Sequential writes, promises of eventual consistency, and a scratch JSON file are insufficient. If an adapter lacks a required capability, block publishing while leaving preview_only available. Never lower correctness requirements to accommodate a provider.

A remote tool may not access the host filesystem. A local path is not proof of upload transport: verify actual bytes, authorized URL import, signed transport, or an approved relay. Require upload AND full-byte download/readback before publishing. Do not bypass missing tools with raw credentials, arbitrary network calls, or a paid generation API.

## Access and immutable storage

Default to private image delivery and private run bundles. Reuse the user's exact existing destination; proposed names such as exercise-images and exercise-image-runs are suggestions only. Container creation, visibility/policy changes, deletion, overwrite and schema changes require separate concrete authorization. Public delivery requires explicit approval. Do not make run bundles public.

Enforce caller ownership/collection membership and target/prefix scope independently in both systems. Verify grants, RLS, ACLs, IAM, or their provider-specific equivalent for the actual identities; never disable access controls to fix an integration. Privileged service clients require server-side authorization checks and must not expose credentials to the model or frontend. Operate files through the actual file/object API, never database metadata writes as a substitute.

Use create-only uploads with a verified no-overwrite option or conditional create; record the exact semantics of the selected API. Do not assume similarly named flags guarantee equivalent behavior. Require exact lookup and original full-byte readback, not thumbnails or a transformed rendition. ETags and provider checksums are not automatically SHA-256.

## Portable asset and record model

Use deterministic logical keys when supported:

`collections/<collection-id>/batches/<batch-key>/r<revision>/colorful.<extension>`

`collections/<collection-id>/batches/<batch-key>/r<revision>/pencil.<extension>`

For a provider with immutable asset IDs rather than object paths, preserve both the requested logical key and returned stable asset ID. Validate key/path segments and approved prefix. Match extension to MIME/bytes. Upload two original sheets once; never twelve duplicates or automatically cropped files.

Persist a canonical asset record for each sheet:

| Field | Meaning |
| --- | --- |
| provider | Actual storage provider/adapter |
| account_id | Verified project/account/cloud/endpoint identity, with environment recorded in connection config |
| container | Bucket, folder, library, or other namespace; explicit null if the provider has none |
| asset_key | Stable object key/public ID/relative durable path; explicit null if ID-only |
| asset_id | Immutable provider ID when exposed; optional |
| durable_reference | Non-expiring provider-qualified locator resolvable by the adapter; never a signed URL or secret |
| access_mode | Verified private/public/authenticated delivery mode |
| content_type, width, height, bytes | Actual original file metadata |
| sha256 | SHA-256 of the original full uploaded/readback bytes |
| profile_sha256, manifest_sha256 | Immutable cartoon profile and ordered batch manifest hashes |
| generation_result_id | Actual generation result identity when exposed |
| public_url | Optional, only after explicitly public delivery and original-byte verification |

For Supabase, map project_ref to account_id, bucket_id to container, and object_path to asset_key. For other vendors map their identifiers without inventing a Supabase project/bucket. Keep native metadata in a provider_metadata object when useful. Temporary signed URLs are generated on demand and must not serve as permanent records.

Persist ordered exercise keys, clinical/specification hashes, panel_index (1–6), normalized cell_rect [x,y,width,height], layout/version, batch key/revision and manifest hash. Every member references the same two original sheets and the same rectangle in both styles. These references describe regions, not standalone images. Consumers must support region-aware display; if they require separate files, explain the incompatibility and obtain an explicit extraction request. Do not generate extra images for consumer compatibility.

Inspect the actual exercise records before mapping; do not replace an existing catalog. Adapt identifier types, constraints and relationships. schema.sql is an OPTIONAL PostgreSQL proposal, not a universal dependency or live migration; translate its conceptual entities to other stores and verify the atomicity/authorization contract. Legacy per-exercise slots do not satisfy batch reservations. Use parameterized queries and validated identifiers for SQL; treat exercise names as data.

## Publication and recovery

1. Lease/reconcile the batch, two style slots, all member/revision keys and sheet assets. Reserve uniquely on (collection,batch_key,revision,style).
2. Validate both original cartoon sheets and every panel. Preserve originals privately. Collect review covering all panels when enabled; one rejected panel holds the entire batch.
3. Upload each original once through verified create-only transport. For an uncertain result/existing key, look up and read the exact original bytes before considering a same-byte upload retry. Never regenerate for an upload error.
4. Read back both originals and verify metadata/SHA-256. Different bytes at an existing identity mean conflict; do not overwrite/delete.
5. In one atomic record-store commit verify lease/revision, manifest, complete member set and uniqueness; save both canonical asset records, every paired panel reference, review/clinical evidence and batch/item completion. Re-query every member before declaring completed.
6. Save private run/progress checkpoints under revision guards and release the batch lease. Resume from original bytes and stable references.

Storage and record-store operations remain separate boundaries even if supplied by the same vendor. Database failure may leave unreferenced sheets: record/reconcile rather than delete. Reservations permanently consume their style allowance for that revision. Timeout remains generation_unknown; never assume provider idempotency or redispatch automatically.
