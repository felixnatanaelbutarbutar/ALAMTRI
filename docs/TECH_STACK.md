# Stack dan konfigurasi
Tujuan file ini: menetapkan kandidat stack portabel dan batas konfigurasi implementasi.
Dibaca oleh / kapan dipakai: agent fondasi, DevOps dan reviewer dependency sebelum M0/M6.

## Status dan versi
Seluruh pilihan berikut **Usulan D-002/D-007**, bukan klaim versi terbaru atau provider yang telah disetujui. M0 wajib memilih patch yang masih didukung, memverifikasi advisori/lisensi terhadap sumber resmi, mencatat exact version + digest + lockfile + SBOM sebelum build; tanpa floating tag produksi. Versi produksi [TBD], Q-014. Provider LLM produksi [TBD], Q-004; tidak ada provider default tersembunyi.

| Layer | Baseline kandidat | Alasan dan dependensi |
|---|---|---|
| Web | Next.js 16 / React 19 / TypeScript 5 / Node.js 24 | Dashboard bertipe; kandidat patch final menunggu verifikasi M0 |
| UI | Tailwind CSS 4 | Tokens konsisten, tanpa layanan desain hosted wajib |
| API | Python 3.12 / FastAPI 0.x / Pydantic 2 | REST, schema validation, OpenAPI; exact FastAPI [TBD] M0 |
| Worker | Celery 5 / Redis 7 | Task retry; Redis bukan sumber kebenaran job/credit |
| Database | PostgreSQL 16 / SQLAlchemy 2 / Alembic 1 | Transaksi, NUMERIC, tenant filtering, migrasi |
| Storage | S3-compatible adapter / self-hosted implementation [TBD] | Object storage portabel; lisensi/distribusi Q-014 |
| File processing | PyMuPDF 1.x / Pillow 11 kandidat | Render/count terisolasi; lisensi dan patch harus ditinjau, Q-014 |
| AI | LLMProvider + OCRProvider interfaces, versi model [TBD] | Vision/API atau model lokal; Q-004 |
| Auth | AuthProvider interface, token/session validation | Produksi Q-008; auth lokal hanya dev sintetis |
| Observability | OpenTelemetry 1 / Prometheus 3 kandidat | Metrik tanpa dokumen/nilai finansial |
| Test | pytest 8 / Vitest 3 / Playwright 1 kandidat | Unit, integrasi, E2E, regresi AI |
| Packaging | OCI container, Compose v2 | Instalasi Managed dan On-Premise; orchestrator produksi Q-014 |
Dependencies di atas harus kompatibel bersama; tidak merupakan lockfile siap deploy. Provider hosted wajib melalui adapter yang bisa diganti deployment lokal. Tidak ada ERP connector atau parser vendor.

## Struktur monorepo usulan
```text
apps/web/                 # UI Bahasa Indonesia
apps/api/                 # REST, auth, schema, authorization
apps/worker/              # pipeline jobs dan recovery
packages/contracts/       # OpenAPI + schema prompt
packages/llm/             # provider interface dan adapter
packages/ocr/             # adapter OCR, bila disetujui
packages/rules/            # deterministic evaluator + versioning
packages/domain/           # state, credit, evidence, permissions
infra/                    # containers, deployment, migration
fixtures/synthetic/       # seed tanpa data PT SIS
 tests/                    # unit, integration, e2e, ai-eval
 docs/                     # spesifikasi ini
```
Path ini rencana implementasi, bukan permintaan scaffold sekarang.

## Deployment dan adapter
`managed`: cloud INaAI, credit aktif; `onprem`: infra PT SIS, credit tidak berlaku. Keduanya API/domain sama. Adapter `LLMProvider.classify/extract/match/explain` menerima input terbatas dan mengembalikan schema [PROMPTS](PROMPTS.md); storage adapter put/get/delete/signedRead; auth adapter memetakan subject ke users aktif. Licensing On-Premise melalui proses aktivasi terkontrol, mekanisme Q-014; jangan menambah network call eksternal tersembunyi. OCI image dan panduan instalasi tidak termasuk penyerahan source code.

## Environment template
Contoh dokumentasi, nilai kosong tidak boleh dianggap konfigurasi produksi valid. Semua secret disuplai secret manager atau mount file, bukan literal di repo.
```dotenv
DEPLOYMENT_MODE=managed
APP_ENV=development
DATABASE_URL=
REDIS_URL=
OBJECT_STORAGE_ENDPOINT=
OBJECT_STORAGE_BUCKET=
OBJECT_STORAGE_ACCESS_KEY_FILE=
OBJECT_STORAGE_SECRET_KEY_FILE=
AUTH_PROVIDER=
AUTH_ISSUER=
AUTH_AUDIENCE=
AUTH_SECRET_FILE=
LLM_PROVIDER=
LLM_MODEL=
LLM_API_KEY_FILE=
LLM_ENDPOINT=
ALLOW_EXTERNAL_LLM=false
OCR_PROVIDER=
CREDIT_POLICY_VERSION=
BILLING_TIMEZONE=
BILLING_CYCLE_ANCHOR=
CREDIT_NEAR_QUOTA_THRESHOLD=
UPLOAD_MAX_BYTES=
UPLOAD_MAX_PAGES=
ALLOWED_UPLOAD_MIME_TYPES=
WORKER_CONCURRENCY=
LLM_RETRY_LIMIT=
EXPORT_TTL_SECONDS=
RETENTION_POLICY_VERSION=
LOG_LEVEL=INFO
```
Config validation: `DEPLOYMENT_MODE` enum strict, secrets requis selon adapter, upload limits positive; valeurs [TBD] Q-002/004/005/008/009/011/012/014 doivent bloquer activation production de la fonction correspondante. Bahasa pesan kesalahan tetap Indonesia. Billing mode onprem mengabaikan seluruh credit settings dan tidak membuat ledger. `ALLOW_EXTERNAL_LLM=false` tidak boleh diubah diam-diam. Endpoint eksternal harus allowlist. Penjelasan operasi di [OPERATIONS](OPERATIONS.md), kontrol data di [SECURITY](SECURITY.md), kontrak di [API_CONTRACT](API_CONTRACT.md).
