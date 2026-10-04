# State, progress, and recovery

## Sheet scheduling and dispatch limits

Group resolved entries into ordered batches of up to six. A full batch contains six exercise panels in each of two sheets, totaling twelve illustrations in two files. Use one coordinator and at most one image request in flight: colorful sheet -> all-panel validation -> whole-sheet pencil conversion -> pair validation. Never reserve per-exercise generation slots or start independent pencil workers.

Before dispatch freeze the batch manifest and reserve its style slot. The unique reservation key is `(collection_id, batch_key, revision, style)`. Each of the two slots permits one dispatch. Persist an explicit batch lease, manifest hash, profile hash, prompt hash, and output identity; item leases alone cannot prevent duplicate batch generation. Expired leases and restarts never clear a consumed slot. A timeout remains `generation_unknown` until its actual outcome is reconciled.

For preview-only requests track session reservations, manifest, originals, and quality findings without requiring any database or external storage provider. Display both original sheets and the external exercise-to-panel mapping in main chat. Do not claim external completion or cross-session recovery without a verified durable store.

## Durable run bundle

Persist outside the installed skill folder under an approved durable reference:

- Original input and its hash, non-secret config, authorization record, and review policy.
- Immutable professional_cartoon_2d collection profile/hash and compliant full-resolution cartoon anchor/reference; never a photorealistic identity/style anchor.
- Selected provider capability mapping, exact non-secret connection identities, canonical asset records, and private durable-run destination.
- Per-exercise clinical specifications and provenance.
- Ordered batch manifests with batch/revision, panel indices/rectangles, layout/dimensions, member exercise keys and specification hashes, and manifest hash.
- Two batch-style reservation/count records, exact full-sheet prompts, result identities, two original sheet files/checksums, per-panel and sheet validation, and actual review evidence.
- Machine-readable run.json and human-readable progress.md, including batch states and exercise-to-panel mappings.

Use the host's approved durable file store or private MCP run store. Publishing uses authoritative provider-neutral record-store run/batch/item/slot records with verified atomic commits and a private durable bundle. Do not put private bundles in public image delivery buckets. Update shared checkpoints with revision guards under an exclusive run lease; only the coordinator writes them. Scratch loss requires restoring originals, never generating replacements automatically.

## Batch state machine

`queued -> resolved -> colorful_reserved -> colorful_saved -> colorful_validated -> pencil_reserved -> pencil_saved -> pair_validated -> awaiting_review (if enabled) -> approved -> uploading -> uploaded -> db_committed -> completed`

Use `preview_ready` after validation and main-chat delivery in preview mode; `completed` means verified external publication. Gate states are needs_clarification, rejected, failed, generation_unknown, and conflict. Any panel failing or uncertain rejects its sheet and holds the entire batch. Automatic mode records review_status=not_requested, not invented approval. A replacement batch revision needs explicit generation authorization; retain old counts and originals. Do not use a one-panel repair generation.

Record panel-level validation/review status for every exercise, but keep generation counts and result files at batch level. All exercise records refer to the shared colorful/pencil sheets plus their fixed panel index and normalized rectangle. Record UTC timestamps, state revision, errors, and next action. Progress includes one row per batch and an exercise panel mapping. Exclude credentials, signed URLs, and patient-identifying data.

## Crash reconciliation

| Evidence | Action |
| --- | --- |
| Completed batch transaction, all member panel references, and matching sheet objects | Restore completed; skip generation |
| Both matching uploaded sheets, no complete batch transaction | Verify validation/review evidence, commit all member references atomically |
| Only one uploaded sheet | Restore the second original and upload identical bytes |
| Validated original sheet pair awaiting review | Display both whole sheets and all panel mappings; await batch approval |
| Colorful validated, pencil slot unused | Restore exact colorful original, then reserve and dispatch the one pencil conversion |
| Reserved slot with unavailable outcome | generation_unknown; reconcile provider result; never resend automatically |
| Any rejected panel | Preserve findings; request authorized replacement batch revision |
| Missing original bytes | Restore durable output; otherwise block without regeneration |
| Different input, ordered members, profile, provider/account, container/namespace, or manifest hash | Block conflicting resume; require approved new run/profile/revision |
| Existing object path with different checksum | Conflict; no overwrite/delete |
| Access failure | Stop writes; reconnect without claiming objects/tables are missing |
| Database transaction timeout | Re-query batch key and every member pair before a transaction retry |

If only some member references exist, publication is incomplete and incompatible with the required transaction contract; investigate/reconcile rather than marking the rest complete. Never change a reserved batch's membership, order, or layout. Completed legacy standalone pairs may be reused only if their cartoon profile/style satisfies this contract, and must not be represented as new sheet outputs. Preserve incompatible realistic-person assets and old reservation counts; use a new profile/run for future cartoon batches rather than mutating or regenerating old work. Provider changes require an authorized new target mapping and renewed readiness evidence, never implicit permission carried across vendors or owners.

## Local helper compatibility

The bundled scripts/progress.py is retained for legacy standalone per-exercise runs only. Its per-exercise generation_calls and completion rules do not represent shared sheets or batch leases. Do not run it for the two-sheet workflow or mistake six per-exercise reservations for one atomic batch reservation. Use a compatible session record in preview mode, or a verified batch-aware remote recorder and checkpoint format in publish mode. Block unattended publication until the integration supplies batch reservations, manifest/panel metadata, and atomic publication for every member.

This skill and its legacy helper are not an autonomous runner. Do not promise background execution after the session ends without a real connected job runner.
