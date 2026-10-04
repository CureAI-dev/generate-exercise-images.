# Provider selection and adapter mapping

## Portable core

Select providers from the user's request, verified saved configuration, and tools actually available in their environment. Ask only for missing choices; never silently change vendors or copy someone else's runtime configuration. Preview generation needs no database or external image store. Publishing adds the complete capability contract in connection-contract.md. These examples are mappings, not prebuilt integrations or tested universal support.

| Selected system | Role and mapping | Evidence required |
| --- | --- | --- |
| Compatible host image tool, including OpenAI or another provider | Single-output colorful generation and whole-sheet pencil editing | Reference editing, inspectable full output, original-byte access for publishing; never silently substitute a prompt-only recreation |
| Supabase | Optional PostgreSQL record store and/or Storage; use either independently | Exact project/environment, record mapping, grants/RLS, actual binary Storage transfer and original-byte readback |
| PostgreSQL, MySQL, SQLite or another transactional database | Record store with dialect-specific schema | Verified transactions, uniqueness, lease/revision checks, ownership controls and durable location; SQLite scratch storage is not durable |
| Document/other record store | Complete aggregate batch document or compatible transactions | Verified atomicity for all references plus member uniqueness and concurrency controls; sequential per-member writes do not qualify |
| Cloudinary | Optional media store independent of database | Cloud/account, folder/public ID/asset ID, access mode, create-only semantics and authenticated original-byte retrieval, not transformed preview only |
| S3-compatible or another object store | Optional image and/or private run store | Account/endpoint, bucket/prefix, permissions, conditional create, lookup, exact full-object readback |
| Host durable file store or durable filesystem | Optional private run store; image storage only if explicitly requested and capabilities suffice | Persistent destination, atomic create/locking, exact byte access and approved delivery; remote tools may not read local paths |

Apply the selected provider's applicable skill and current official docs before implementing its integration. For a chosen Supabase adapter, apply the Supabase skill and PostgreSQL guidance as appropriate; use supabase-inspection.sql only for SELECT-only metadata inspection after resolving the project. Those templates and managed auth/storage schemas do not apply to other providers. Discover actual callable schemas in every host; no fixed tool name in this skill is an integration promise.

Do not provision new infrastructure or switch a publishing destination to solve a capability gap without authorization. Report precisely which adapter capability is missing; preview_only can remain available. Configuration records refer to connections by alias and non-secret identity, never embed service keys, passwords, signing secrets, personal account IDs as defaults, or reusable approvals from another user.

## Legacy configuration and data

Recognize old supabase config blocks only as that user's runtime mapping. Convert them into separate database/image_storage/run_store sections after identifying their exact targets and authorization; do not change the live services. Preserve native project/bucket/path metadata while normalizing asset records. An existing schema that requires Supabase-shaped JSON needs an inspected, separately approved adaptation or explicit lossless mapping before writing other providers' references. Never invent fake project_ref/bucket_id values for Cloudinary or S3.

A legacy photorealistic profile/anchor is incompatible with the cartoon contract. Preserve old files and generation counts, but use a new immutable professional_cartoon_2d profile/hash for future batches. Do not reuse realistic-person anchors or silently change a reserved batch. User-requested future style changes do not authorize extra regeneration of completed or unknown batches.
