# Stack Teknologi dan Konfigurasi Sistem
Tujuan file ini: menetapkan standar teknologi monorepo, versi pustaka kandidat, pemodelan ekonomi biaya AI per halaman, dan templat konfigurasi.
Dibaca oleh / kapan dipakai: tim pengembang backend, frontend, DevOps, dan solusi arsitek saat menyiapkan lingkungan kerja M0 dan infrastruktur M6.

## Status dan versi
**Berdasarkan Usulan D-002/D-007.** Pilihan teknologi berikut dirancang untuk menjamin portabilitas monorepo penuh antara lingkungan cloud Managed dan infrastruktur mandiri On-Premise.

| Lapisan Sistem | Teknologi & Versi Kandidat | Alasan Pemilihan | Alternatif yang Ditolak & Alasannya |
|---|---|---|---|
| **Web Frontend** | Next.js 16 (App Router), React 19, TypeScript 5.6 | Server-Side Rendering (SSR) cepat, komponen strongly-typed, ekosistem dashboard modern | **Angular / Vue:** Ditolak karena ekosistem komponen viewer dokumen dan library AI token visualizer lebih matang di React. |
| **Styling UI** | Tailwind CSS 4, Lucide React (Icons) | Utility-first cepat, ukuran bundle CSS minimalis, token warna konsisten tanpa dependensi UI library pihak ketiga | **Bootstrap / MUI:** Ditolak karena berat, sulit dikustomisasi dengan layout split-screen PDF viewer khusus, dan risiko class pollution. |
| **REST API Engine** | Python 3.12, FastAPI 0.115+, Pydantic v2 | Performa asinkron tinggi, validasi skema otomatis via OpenAPI 3.1, integrasi native dengan library data science/AI | **Django REST Framework:** Ditolak karena overhead ORM monolitik terlalu berat untuk streaming asinkron dan parsing file biner besar. |
| **Worker & Queue** | Celery 5.4, Redis 7.2 | Pengelolaan antrean tugas asinkron terdistribusi, retry dengan exponential backoff, rate limiting terintegrasi | **RabbitMQ:** Ditolak karena kompleksitas operasional On-Premise lebih tinggi dibanding Redis yang multi-guna (caching + broker). |
| **Relational Database** | PostgreSQL 16, SQLAlchemy 2.0, Alembic 1.13 | Integritas ACID ketat, dukungan JSONB terindeks cepat, partitioning native untuk data bervolume tinggi, tipe `NUMERIC` exact | **MongoDB / NoSQL:** Ditolak karena transaksi keuangan dan integritas buku besar kredit (ledger) memerlukan jaminan relasional strict. |
| **Object Storage Adapter** | MinIO (Self-hosted) / AWS S3 SDK (boto3) | Antarmuka standar industri S3-compatible, mendukung signed URL, enkripsi at-rest, dan portabel ke server lokal | **Local Filesystem:** Ditolak karena tidak dapat diskalakan horizontal pada multi-instance worker dan rentan path traversal. |
| **Document Processing** | PyMuPDF (fitz) 1.24+, Pillow 11.0 | Render halaman PDF ke gambar berkecepatan tinggi (C-binding), ekstraksi teks visual dan koordinat bounding box presisi | **PDFMiner / PyPDF2:** Ditolak karena kecepatan rendering halaman gambar jauh lebih lambat (5-10x) dan boros memori. |
| **AI & LLM Client** | Antarmuka `LLMProvider` terisolasi (OpenAI SDK / LiteLLM / VLLM) | Abstraksi modul fleksibel: dapat diarahkan ke cloud provider (Managed) atau engine lokal VLLM on-premise tanpa ubah kode | **LangChain / LlamaIndex:** Ditolak karena lapisan abstraksi terlalu tebal, rawan memory leak, dan sulit diaudit keamanannya. |
| **Container & CI/CD** | Docker Engine 26+, Compose v2, GitHub Actions | Format OCI standar industri untuk deployment portable dan automasi pengujian multi-stage | **Bare Metal VM Script:** Ditolak karena sulit direproduksi secara identik di lingkungan server klien On-Premise. |

---

## Analisis Ekonomi Unit Biaya LLM vs Tarif Kredit
Model komersial Managed menetapkan tarif pemakaian tambahan sebesar **IDR 500 / kredit** (1 kredit = 1 halaman dokumen). Analisis kelayakan ekonomi biaya inferensi AI per halaman dihitung dengan asumsi berikut:

### Asumsi Parameter Inferensi Per Halaman:
1. **Input Tokens per Halaman:** Rata-rata 1.200 token teks OCR & instruksi prompt chunking.
2. **Output Tokens per Halaman:** Rata-rata 350 token JSON terstruktur dan koordinat evidence.
3. **Model Biaya Baseline (misal Azure OpenAI GPT-4o-mini / Claude 3.5 Haiku):**
   - Biaya Input: USD 0.15 per 1.000.000 tokens.
   - Biaya Output: USD 0.60 per 1.000.000 tokens.
   - Nilai Tukar Konservatif: USD 1.00 = IDR 16.000.

### Perhitungan Biaya Inferensi:
$$\text{Biaya Input} = \frac{1.200}{1.000.000} \times \$0,15 = \$0,00018$$
$$\text{Biaya Output} = \frac{350}{1.000.000} \times \$0,60 = \$0,00021$$
$$\text{Total Biaya LLM per Halaman} = \$0,00039 \times \text{IDR } 16.000 \approx \mathbf{\text{IDR } 6,24 \text{ / halaman}}$$

### Buffer Operasional & Margin Kotor:
- Biaya Ekstraksi PDF & Rendering Lokal (PyMuPDF): IDR 0 (Free software).
- Biaya Penyimpanan Objek & Bandwidth Egress: ~IDR 5,00 / halaman.
- Buffer Retry (asumsi kegagalan 5%): ~IDR 1,50 / halaman.
- **Total Biaya Pokok Pemrosesan (COGS) per Halaman:** **~IDR 12,74 / halaman**.
- **Tarif Kredit ke Klien:** **IDR 500,00 / halaman**.
- **Gross Margin:**

$$\text{Gross Margin} = \frac{\text{IDR } 500 - \text{IDR } 12,74}{\text{IDR } 500} \times 100\% = \mathbf{97,45\%}$$

*Kesimpulan:* Margin kotor di atas 95% memberikan bantalan finansial yang sangat kokoh untuk menutupi biaya infrastruktur server, lisensi database, dan pemeliharaan tanpa risiko defisit biaya komputasi AI.

---

## Struktur monorepo usulan

```text
alamtri/
├── apps/
│   ├── web/                     # Frontend Next.js 16 (Bahasa Indonesia)
│   │   ├── src/app/             # App Router pages (/cases, /exceptions, /credits)
│   │   ├── src/components/      # UI components (SplitViewer, QueueTable, FormReview)
│   │   └── src/lib/             # API client, tokens, formatters
│   ├── api/                     # Backend FastAPI REST Engine
│   │   ├── src/routes/          # Endpoint controllers (cases, documents, rules, exports)
│   │   ├── src/middleware/      # Auth, tenant isolation, idempotency, error handler
│   │   └── src/main.py          # FastAPI application bootstrap
│   └── worker/                  # Celery Pipeline Worker
│       ├── src/tasks/           # Ingestion, OCR render, AI extraction, rule evaluation
│       └── src/celery_app.py    # Celery configuration and beat scheduler
├── packages/
│   ├── contracts/               # Skema JSON Schema, OpenAPI YAML, & DTOs
│   ├── domain/                  # Entitas bisnis, state machine, kalkulasi kredit
│   ├── rules/                   # Mesin validasi deterministik (VR-001 s.d. VR-009)
│   ├── llm/                     # Interface adapter LLM (OpenAI, VLLM, Mock)
│   └── ocr/                     # Adapter pemrosesan PDF & bounding box extraction
├── infra/
│   ├── docker/                  # Dockerfile per service & Compose multi-stage
│   ├── migrations/              # Skrip migrasi Alembic database
│   └── scripts/                 # Backup, restore, and month-close CLI tools
├── fixtures/
│   └── synthetic/               # Dataset sintetis aman (Golden & Faults)
├── tests/
│   ├── unit/                    # Unit testing logika bisnis & rules
│   ├── integration/             # Integration testing API, DB, & storage
│   ├── e2e/                     # End-to-end testing browser (Playwright)
│   └── ai-eval/                 # Pengujian regresi akurasi model & anti-injection
├── docs/                        # Spesifikasi lengkap proyek (Pusat Kebenaran)
└── package.json                 # Monorepo workspaces manifest
```

---

## Perintah Operasional Monorepo
Perintah standar untuk pengembangan, pengujian, dan build aplikasi:

```bash
# 1. Menjalankan Lingkungan Pengembangan Lokal (Dev Server)
docker compose -f infra/docker/docker-compose.dev.yml up -d
npm run dev --workspaces

# 2. Menjalankan Pengujian Lengkap dengan Laporan Coverage
pytest tests/unit tests/integration --cov=apps/api/src --cov=packages --cov-report=term-missing --cov-fail-under=85
npm run test:e2e --workspace=apps/web

# 3. Menjalankan Verifikasi Typecheck dan Linter
npm run lint --workspaces
npm run typecheck --workspaces
flake8 apps/ packages/
mypy apps/api apps/worker packages/

# 4. Menjalankan Migrasi Database
alembic -c infra/migrations/alembic.ini upgrade head

# 5. Membangun Image Kontainer Produksi
docker build -t sis-invoice-web:latest -f infra/docker/Dockerfile.web .
docker build -t sis-invoice-api:latest -f infra/docker/Dockerfile.api .
docker build -t sis-invoice-worker:latest -f infra/docker/Dockerfile.worker .
```

---

## Deployment dan adapter
Platform menggunakan konfigurasi berbasis variabel lingkungan `DEPLOYMENT_MODE`:
1. `DEPLOYMENT_MODE=managed`: Mengaktifkan modul penagihan kredit (`packages/domain/credit`), kuota 50.000 kredit/bulan, dan adapter penyimpanan cloud S3.
2. `DEPLOYMENT_MODE=onprem`: Menonaktifkan seluruh pencatatan kredit (`credit_ledger`), merespons 404 pada endpoint `/credits/*`, dan mengalihkan penyimpanan ke object storage lokal MinIO.

Kedua mode berbagi basis kode domain dan skema database yang sama persis tanpa percabangan branch kode terpisah.

---

## Environment template

```dotenv
# ==========================================
# KONFIGURASI INTI SISTEM (SIS AI PLATFORM)
# ==========================================
DEPLOYMENT_MODE=managed
APP_ENV=development
LOG_LEVEL=INFO
ALLOW_EXTERNAL_LLM=true

# Database & Cache
DATABASE_URL=postgresql+psycopg://sis_app:secret_password@localhost:5432/sis_invoice_db
REDIS_URL=redis://localhost:6379/0

# Object Storage S3-Compatible
OBJECT_STORAGE_ENDPOINT=http://localhost:9000
OBJECT_STORAGE_BUCKET=sis-invoices
OBJECT_STORAGE_ACCESS_KEY_FILE=/run/secrets/storage_access_key
OBJECT_STORAGE_SECRET_KEY_FILE=/run/secrets/storage_secret_key

# Autentikasi Pengguna
AUTH_PROVIDER=local
AUTH_ISSUER=https://auth.sis.co.id
AUTH_AUDIENCE=sis-invoice-intelligence
AUTH_SECRET_FILE=/run/secrets/auth_jwt_secret

# AI & LLM Engine
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
LLM_API_KEY_FILE=/run/secrets/llm_api_key
LLM_ENDPOINT=https://api.openai.com/v1
LLM_RETRY_LIMIT=2

# Batasan Ingestion Dokumen (Default Terstandar)
UPLOAD_MAX_BYTES=52428800
UPLOAD_MAX_PAGES=150
ALLOWED_UPLOAD_MIME_TYPES=application/pdf,image/png,image/jpeg

# Kebijakan Kredit Managed
CREDIT_POLICY_VERSION=1.0.0
BILLING_TIMEZONE=Asia/Jakarta
BILLING_CYCLE_ANCHOR=LAST_CALENDAR_DAY
CREDIT_NEAR_QUOTA_THRESHOLD=80
EXPORT_TTL_SECONDS=86400
RETENTION_POLICY_VERSION=1.0.0
WORKER_CONCURRENCY=8
```
