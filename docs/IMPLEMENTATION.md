# Roadmap Implementasi Teknis dan Rencana Milestone
Tujuan file ini: mengurutkan tugas teknis pembangunan aplikasi per milestone, modul yang disentuh, dependensi, dan Definition of Done.
Dibaca oleh / kapan dipakai: tim pengembang software (backend, frontend, DevOps) dan Technical Project Manager saat merencanakan sprint.

## Konvensi dan dependensi
**Berdasarkan Usulan D-002/D-007/D-009.**
1. **Aturan Format Tugas:** Setiap tugas memiliki ID unik dengan format `T<nomor milestone>.<nomor urut>` (misal: `T0.1`, `T1.2`).
2. **Dependensi Ketat:** Tugas yang memiliki dependensi pada tugas lain DILARANG dimulai sebelum tugas prasyaratnya berstatus selesai (*Done*) dan diverifikasi oleh tes otomatis.
3. **Keterkaitan Acceptance:** Setiap tugas terikat pada kriteria penerimaan di [ACCEPTANCE](ACCEPTANCE.md) (`A-xxx`).
4. **Batas Mutlak:** Pekerjaan implementasi DILARANG menulis kode integrasi langsung ERP/pembayaran, DILARANG membuat keputusan otomatis, dan DILARANG menyerahkan source code ke klien.

---

## M0 Fondasi — minggu 1–2
Fokus: Penyiapan monorepo, blueprint skema database, antarmuka adapter, dan dataset sintetis awal. Selaras dengan fase *Discovery & Solution Design*.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T0.1** | [ ] **Process Mapping & Technical Charter:** Memetakan alur verifikasi faktur bersama PT SIS, menyepakati default usulan Q-001 s.d. Q-017, dan menyusun spesifikasi final. | Kick-off Proyek PT SIS/INaAI | `docs/PRD.md`, `docs/DECISIONS.md` | [A-RULES-01, A-SIGNBAST-01](ACCEPTANCE.md#validasi) |
| **T0.2** | [ ] **Monorepo & CI/CD Pipeline Setup:** Inisialisasi struktur monorepo (`apps/`, `packages/`, `infra/`), Docker Compose multi-stage dev, static linter (`flake8`, `mypy`, `eslint`), dan GitHub Actions workflow. | T0.1; `Q-014` | `infra/docker/`, `package.json`, `.github/` | [A-SECURITY-01](ACCEPTANCE.md#keamanan-dan-administrasi) |
| **T0.3** | [ ] **Database Blueprint & Migration Setup:** Menerapkan skema relasional [DATA_MODEL](DATA_MODEL.md) ke dalam skrip migrasi awal Alembic, konfigurasi PostgreSQL 16, dan isolasi tenant. | T0.2; `Q-008`, `Q-015` | `infra/migrations/`, `packages/domain/` | [A-HUMAN-01, A-APPROVER-01, A-ADMIN-01](ACCEPTANCE.md#human-control) |
| **T0.4** | [ ] **Synthetic Dataset Generator:** Membangun generator dokumen PDF/gambar sintetis dan manifest JSON kebenaran untuk kasus uji `TC-G01` s.d. `TC-F09`. | T0.1 | `fixtures/synthetic/`, `tests/` | [A-ACCURACY-01, A-RULES-01](ACCEPTANCE.md#ekstraksi) |

---

## M1 Ingestion dan extraction — minggu 3–4
Fokus: Pembangunan pipeline penerimaan berkas, kalkulasi halaman, pencatatan kredit idempotensi, dan integrasi modul ekstraksi AI.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T1.1** | [ ] **Upload API & Document Quarantine:** Implementasi endpoint `POST /cases` dan `POST /cases/{id}/documents`, validasi MIME magic bytes, batasan 50 MB / 150 halaman, dan upload ke S3. | T0.2, T0.3; `Q-002` | `apps/api/src/routes/cases.py`, `packages/domain/` | [A-UPLOAD-01, A-PAGECOUNT-01, A-SECURITY-01](ACCEPTANCE.md#upload-dan-pemrosesan) |
| **T1.2** | [ ] **Durable Job Outbox & Celery Worker:** Membangun antrean Celery worker dengan Redis broker, penanganan heartbeat, lease retry, dan endpoint pelacakan status `GET /jobs/{id}`. | T1.1 | `apps/worker/`, `apps/api/src/routes/jobs.py` | [A-MONITOR-01, A-RECOVERY-01](ACCEPTANCE.md#kinerja-dan-keandalan) |
| **T1.3** | [ ] **Credit Metering Engine (Managed):** Implementasi buku besar kredit `credit_ledger` append-only dengan kunci idempotensi `billing_event_key` dan notifikasi batas kuota. | T1.1, T1.2; `Q-011`, `Q-012` | `packages/domain/credit/`, `apps/api/src/routes/credits.py` | [A-CREDITMETER-01, A-CREDITQUOTA-01, A-CREDITNOTIF-01, A-ONPREM-01](ACCEPTANCE.md#credit) |
| **T1.4** | [ ] **Document Rendering & AI Extraction Adapters:** Integrasi PyMuPDF untuk render halaman ke gambar, implementasi prompt P-001 (Klasifikasi) dan P-002 (Ekstraksi) dengan JSON Schema 2020-12. | T1.2; `Q-004`, `Q-006`, `Q-007`, `Q-010` | `packages/ocr/`, `packages/llm/`, `packages/contracts/` | [A-EXTRACT-01, A-ACCURACY-01, A-UNREADABLE-01](ACCEPTANCE.md#ekstraksi) |
| **T1.5** | [ ] **Structured Storage & Evidence Bounding Box:** Menyimpan data hasil ekstraksi ke `doc_headers`, `doc_line_items`, dan mengaitkan koordinat bukti ke tabel partisi `evidence`. | T1.4 | `apps/worker/src/tasks/storage.py`, `tests/unit/` | [A-EXTRACT-01, A-EVIDENCE-01](ACCEPTANCE.md#ekstraksi) |

---

## M2 Validation Engine — minggu 5–6
Fokus: Implementasi mesin validasi deterministik, pencocokan semantik baris item, deteksi duplikasi, dan pencatatan audit.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T2.1** | [ ] **Deterministic Rules Engine:** Membangun evaluator aturan berbasis Python `Decimal` untuk `VR-001` (Total), `VR-002` (Harga), `VR-003` (Qty), `VR-004` (Ref PO), `VR-005` (BAST), `VR-006` (Header), dan `VR-007` (Internal). | T1.5, T0.1; `Q-001` | `packages/rules/`, `apps/worker/src/tasks/validate.py` | [A-RULES-01, A-PRECEDENCE-01](ACCEPTANCE.md#validasi) |
| **T2.2** | [ ] **Duplicate Detection & Semantic Matching:** Implementasi aturan `VR-008` (Deteksi Duplikasi 90 hari) dan integrasi prompt `P-004` untuk usulan pasangan baris item non-identik. | T2.1; `Q-001`, `Q-017` | `packages/rules/duplicate.py`, `packages/llm/matching.py` | [A-RULES-01, A-DUPLICATE-01](ACCEPTANCE.md#validasi) |
| **T2.3** | [ ] **Reasoning Summarizer & Status Aggregation:** Integrasi prompt `P-003` untuk pembuatan narasi netral berbahasa Indonesia, fallback template statis, dan aturan agregasi preseden status case. | T2.1, T2.2 | `packages/llm/reasoning.py`, `packages/domain/` | [A-EVIDENCE-01, A-NEUTRAL-01, A-PRECEDENCE-01](ACCEPTANCE.md#validasi) |
| **T2.4** | [ ] **Admin Rules API & Audit Logging:** Membangun endpoint `PATCH /admin/rules/{id}/params` dengan versioning aturan otomatis dan pencatatan hash chain ke `audit_log`. | T2.1, T1.1 | `apps/api/src/routes/admin.py`, `packages/domain/audit/` | [A-ADMIN-01, A-SECURITY-01](ACCEPTANCE.md#keamanan-dan-administrasi) |

---

## M3 Dashboard — minggu 6–8
Fokus: Pembangunan antarmuka pengguna web Next.js 16, viewer split-screen dokumen fisik, form catatan review manusia, dan modul ekspor.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T3.1** | [ ] **Dashboard Shell & Ingestion UI:** Membangun layout web modern Bahasa Indonesia, halaman daftar kasus `/cases`, widget antrean, dan dialog multi-file upload dengan progress bar. | T1.1, T1.2 | `apps/web/src/app/cases/`, `apps/web/src/components/` | [A-UPLOAD-01, A-MONITOR-01, A-QUEUE-01](ACCEPTANCE.md#upload-dan-pemrosesan) |
| **T3.2** | [ ] **Split-Screen Evidence Viewer:** Membangun komponen viewer PDF dua panel: panel kiri menampilkan halaman dokumen dengan sorotan bounding box interaktif, panel kanan menampilkan hasil validasi. | T3.1, T2.3 | `apps/web/src/components/SplitViewer.tsx` | [A-EVIDENCE-01, A-QUEUE-01](ACCEPTANCE.md#dashboard-dan-ekspor) |
| **T3.3** | [ ] **Human Decision Review Component:** Implementasi form catatan review manusia khusus role `APPROVER`, validasi catatan wajib, proteksi stale run (409), dan banner tata kelola. | T3.2, T0.3; `Q-015` | `apps/web/src/components/ReviewForm.tsx`, `apps/api/` | [A-HUMAN-01, A-APPROVER-01, A-NEUTRAL-01](ACCEPTANCE.md#human-control) |
| **T3.4** | [ ] **Structured Export Worker & UI:** Implementasi modul ekspor CSV dan XLSX dengan pembersihan formula injection, pengelolaan TTL unduhan 24 jam, dan antarmuka `/exports`. | T3.2; `Q-003`, `Q-005` | `apps/worker/src/tasks/export.py`, `apps/web/` | [A-EXPORT-01](ACCEPTANCE.md#dashboard-dan-ekspor) |
| **T3.5** | [ ] **Credit Management Dashboard:** Antarmuka pemantauan kuota 50.000 kredit `/credits`, grafik pemakaian, riwayat overage, dan otomatis disembunyikan jika `DEPLOYMENT_MODE=onprem`. | T1.3, T3.1; `Q-011`, `Q-012` | `apps/web/src/app/credits/` | [A-CREDITMETER-01, A-CREDITQUOTA-01, A-CREDITNOTIF-01, A-ONPREM-01](ACCEPTANCE.md#credit) |
| **T3.6** | [ ] **Admin & Operations UI:** Halaman manajemen pengguna `/admin/users`, penyesuaian parameter `/admin/rules`, penelusuran audit `/admin/audit`, dan monitoring teknis `/ops`. | T2.4, T3.1 | `apps/web/src/app/admin/`, `apps/web/src/app/ops/` | [A-ADMIN-01, A-SECURITY-01](ACCEPTANCE.md#keamanan-dan-administrasi) |

---

## M4 Hardening dan UAT — minggu 9–10
Fokus: Pengujian beban skala tinggi, evaluasi akurasi regresi AI, pengujian keamanan, dan pelaksanaan pengujian UAT bersama tim PT SIS.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T4.1** | [ ] **AI Accuracy & Regression Benchmarking:** Mengeksekusi suite evaluasi pada 100+ dataset sintetis held-out; memastikan akurasi field >= 85% dan recall selisih >= 95%. | T3.2, T2.3, T0.4 | `tests/ai-eval/` | [A-ACCURACY-01, A-RULES-01](ACCEPTANCE.md#ekstraksi) |
| **T4.2** | [ ] **High-Volume Load & Restore Drills:** Menjalankan uji beban throughput 700 halaman/jam (simulasi 500k hal/bln) dan demonstrasi uji pemulihan database (restore drill RTO <= 4 jam). | T3.4, T3.5, T3.6; `Q-013`, `Q-014` | `tests/load/`, `infra/scripts/restore_drill.sh` | [A-PERF-01, A-RECOVERY-01, A-RESTORE-01](ACCEPTANCE.md#kinerja-dan-keandalan) |
| **T4.3** | [ ] **Security & Accessibility Hardening:** Pemindaian kerentanan SAST/DAST, audit RBAC anti-IDOR, pengujian keyboard navigation WCAG 2.2 AA, dan verifikasi ketiadaan kata terlarang. | T3.3, T3.6 | `tests/e2e/`, `tests/integration/test_security.py` | [A-HUMAN-01, A-NEUTRAL-01, A-SECURITY-01](ACCEPTANCE.md#human-control) |
| **T4.4** | [ ] **User Acceptance Testing (UAT) Execution:** Menjalankan skenario pengujian bersama tim Finance dan IT PT SIS; perbaikan defect dalam scope dan penandatanganan hasil UAT. | T4.1, T4.2, T4.3; `Q-016` | Modul terdampak UAT, `docs/ACCEPTANCE.md` | [A-SIGNBAST-01](ACCEPTANCE.md#serah-terima) |

---

## M5 Operational Adoption dan Go-Live — minggu 11–12
Fokus: Penyerahan dokumentasi, pelatihan pengguna akhir PT SIS, deployment produksi cloud Managed, dan penandatanganan BAST Phase 1.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T5.1** | [ ] **Production Cloud Deployment:** Deployment service `web`, `api`, `worker` ke lingkungan cloud produksi INaAI dengan TLS 1.3, secret manager aktif, dan database terenkripsi at-rest. | T4.4; `Q-004`, `Q-005`, `Q-008`, `Q-014` | `infra/docker/`, `infra/migrations/` | [A-RESTORE-01, A-SECURITY-01](ACCEPTANCE.md#kinerja-dan-keandalan) |
| **T5.2** | [ ] **User Training & Handover Deliverables:** Menyelenggarakan pelatihan pengguna bagi Finance Staff dan Approver PT SIS; menyerahkan Panduan Pengguna dan Panduan Operasi (tanpa source code). | T4.4, T5.1; `Q-016` | `docs/`, Materi Pelatihan, Daftar Hadir | [A-HANDOVERDOC-01, A-TRAINING-01](ACCEPTANCE.md#serah-terima) |
| **T5.3** | [ ] **Monthly Metering Initialization & Phase 2 Setup:** Inisialisasi periode kredit bulan pertama di `credit_periods`, penjadwalan cron job penutupan bulan, dan aktivasi tim maintenance. | T5.1, T3.5; `Q-011`, `Q-012` | `apps/worker/src/tasks/credit.py` | [A-CREDITMETER-01, A-CREDITQUOTA-01, A-PERF-01](ACCEPTANCE.md#credit) |
| **T5.4** | [ ] **BAST Phase 1 Sign-Off:** Penandatanganan resmi dokumen Berita Acara Serah Terima (BAST) Phase 1 oleh Project Sponsor PT SIS dan INaAI, menandai mulainya 12 bulan langganan. | T5.2, T5.3; `Q-016` | Berita Acara Resmi Handover | [A-SIGNBAST-01](ACCEPTANCE.md#serah-terima) |

---

## M6 On-Premise — skema alternatif
Skema deployment alternatif pada server lokal PT SIS (durasi 16 minggu kerja + pengadaan 2-3 bulan). Menggunakan basis kode portabel M0–M5.

| Tugas | Checklist Hasil Kerja | Dependensi / Gate | Modul Rencana | AC Terkait |
|---|---|---|---|:---:|
| **T6.1** | [ ] **Infrastructure Readiness & Procurement Review:** Verifikasi spesifikasi server fisik PT SIS (32 vCPU, 64 GB RAM, GPU opsional), OS Linux, dan jaringan lokal. | Pilihan Skema Onprem; `Q-014` | `docs/OPERATIONS.md`, Dokumen Sizing | [A-PERF-01, A-SECURITY-01](ACCEPTANCE.md#kinerja-dan-keandalan) |
| **T6.2** | [ ] **Portable Architecture Porting:** Mengonfigurasi image kontainer dengan `DEPLOYMENT_MODE=onprem`, adapter MinIO lokal, dan adapter model AI lokal jika model eksternal dilarang. | T6.1; `Q-004`, `Q-008` | `infra/docker/`, `packages/llm/` | [A-EXTRACT-01, A-RULES-01, A-HUMAN-01](ACCEPTANCE.md#ekstraksi) |
| **T6.3** | [ ] **System Installation & License Activation:** Instalasi paket kontainer di server PT SIS, migrasi database lokal, dan aktivasi file lisensi offline bertanda tangan digital. | T6.2 | `infra/scripts/activate_license.py` | [A-ONPREM-01, A-SECURITY-01](ACCEPTANCE.md#credit) |
| **T6.4** | [ ] **On-Premise UAT, Training, & Handover:** Pelaksanaan UAT pada jaringan lokal PT SIS, pelatihan tim IT/Finance lokal, dan serah terima BAST lisensi tahunan On-Premise. | T6.3; `Q-013`, `Q-016` | Catatan UAT Onprem, Materi Training | [A-RESTORE-01, A-HANDOVERDOC-01, A-SIGNBAST-01](ACCEPTANCE.md#serah-terima) |

---

## Definition of milestone done
Sebuah milestone dinyatakan **Selesai (Done)** hanya jika:
1. Seluruh tugas dalam milestone bersangkutan telah tercentang `[x]` dengan bukti pengujian otomatis yang lulus 100%.
2. Kriteria penerimaan (`A-xxx`) yang terkait dapat didemonstrasikan secara nyata.
3. Seluruh dokumen spesifikasi di `docs/` telah diperbarui selaras dengan implementasi aktual.
4. Skrip verifikasi `check-docs.ps1` dijalankan dan menghasilkan status **PASS (Exit Code 0)**.
