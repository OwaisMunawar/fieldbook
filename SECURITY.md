# Security and privacy

Report a vulnerability privately to **owais.munawar@gmail.com**. Include the affected revision, a minimal reproduction and expected impact. Avoid posting private inspection documents in an issue.

## Data boundaries

The application has no document-upload service or provider API key. Recognition and draft generation use Apple's native on-device frameworks. Photos selected through the system picker may be retrieved by the OS from the user's photo library, including iCloud. Foundation Models availability and installation are managed by the OS.

Images and the SQLite database are stored in the app's sandbox. There is no extra database encryption, biometric gate, remote wipe or backup exclusion policy. Device protection and OS backup settings matter. Exported JSON contains the full recognized text and review notes; the user deliberately chooses a destination through the system share sheet. The latest export is retained as a private temporary file for sharing and replaced on the next export.

## Model boundary

OCR text is untrusted. The model is instructed to treat it as evidence rather than instructions, receives no executable tools, and cannot write the notebook. Exact-quote validation blocks invented citations but does not establish truth, safety or semantic correctness. Inspectors must review actions against the original image. The application does not certify buildings, repairs or compliance.

Recognition confidence is not calibrated to field risk. The 0.45 acceptance threshold is a product rule, not a measurement of safety. An OCR transcription can be confidently wrong.

## Integrity and limits

SQLite foreign keys, unique constraints, atomic writes, revision checks and event triggers protect normal application operations. A person with filesystem access can replace the database or remove triggers. SHA-256 digests identify image bytes; they are neither signatures nor provenance attestations.

Imports are limited to 20 MB and 200 recognized lines. The picker normalizes selected media. Model input is limited to 40 lines and 16 KB of serialized source text. There is no network-facing API, rate limit or multi-tenant access model in this release.

A process killed between the image copy and SQLite insert can leave an orphan image. No automatic orphan reconciliation, retention or pruning exists yet. Do not use this reference app as the only copy of important evidence.
