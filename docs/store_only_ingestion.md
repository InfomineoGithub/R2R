# Store-Only Ingestion for R2R

## Goal
Provide a new ingestion path that **copies the file into R2R storage but skips**

* parsing
* chunking
* embedding
* document-summary generation

so gigantic files can be registered quickly while still living in the system.

The pipeline should still allow a later promotion to full processing (e.g. re-ingest with another mode, or targeted embedding of chosen chunks).

## Design Overview

1. **Enum flag**
   * Add `store_only = "store-only"` to `IngestionMode` (in `core.base.providers.ingestion.py`).

2. **Router entry-point**
   * In `DocumentsRouter.create_document` recognise the new mode **before** the orchestration branch.
   * Path:
     1. save the file via `providers.database.files_handler.store_file` (the helper `_process_file` already returns what `store_file` needs).
     2. create a `DocumentResponse` row with `ingestion_status = IngestionStatus.SUCCESS` and `size_in_bytes` filled.
     3. **return** immediately; do **not** call `orchestration.run_workflow`.

3. **Service helper (optional)**
   * Put the logic above behind a small method in `IngestionService` e.g. `store_only_ingress(...)` so the router stays thin.

4. **Later upgrade path**
   * Re-use the existing `update_files` route:
     * client uploads the same file with `ingestion_mode = fast / hi-res / custom` → full pipeline will run, replacing status/summary etc.

No server-side setting is required; the router decides per request.

## Touch Points

| File | Change |
|------|--------|
| `core/base/providers/ingestion.py` | add enum member |
| `core/main/api/v3/documents_router.py` | fast path when `ingestion_mode == IngestionMode.store_only` |
| `core/main/services/ingestion_service.py` | (optional) `store_only_ingress` |
| tests | copy `tests/unit/test_store_only_ingestion.py` into formal suite |

## Behaviour Summary

* `POST /v3/documents ... ingestion_mode=store-only` – stores file, returns immediately, ingestion_status=`success`.
* Every other mode remains unchanged.

---

**Decision**: keep all new code in its own small helper(s); do *not* touch existing parser / embedder paths.






