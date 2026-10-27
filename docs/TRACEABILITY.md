# Matriks Keterlacakan (Traceability Matrix)
Tujuan file ini: menyediakan peta keterlacakan end-to-end dari Tujuan Bisnis hingga Kode, Database, Pengujian, dan Tugas Implementasi.
Dibaca oleh / kapan dipakai: arsitek perangkat lunak, tim pengembang, QA engineer, dan auditor proyek.

## Prinsip Keterlacakan
Setiap komponen dalam platform ini WAJIB memiliki keterlacakan yang jelas tanpa celah:
1. Tidak boleh ada User Story (`US-`) tanpa Kriteria Penerimaan (`A-`) dan Uji Kasus (`TC-`).
2. Tidak boleh ada Endpoint API (`API-`) tanpa otorisasi peran dan pemetaan ke User Story.
3. Tidak boleh ada Tabel Database yang tidak terpakai oleh proses/API.
4. Tidak boleh ada Tugas Implementasi (`T-`) yang tidak memiliki acuan fitur bisnis.

---

## Konvensi Standar Identifier
- **F-xxx:** Fitur Bisnis Utama
- **US-xxx:** User Story (format standar agile)
- **VR-xxx:** Validation Rule deterministik
- **API-xxx:** Kontrak Endpoint REST API
- **TC-xxx:** Test Case konkret (Golden, Faults, Security, Load)
- **A-xxx:** Kriteria Penerimaan Acceptance (Given/When/Then)
- **T-xxx:** Tugas Implementasi dalam Roadmap
- **D-xxx:** Decision Log (Keputusan Arsitektur/Bisnis)
- **Q-xxx:** Open Questions (Pertanyaan Terbuka / Parameter)

---

## Matriks Keterlacakan Komprehensif

| Tujuan Bisnis | Fitur (F) | User Story (US) | Rule Terkait (VR) | Endpoint API | Tabel Database | Kasus Uji (TC) | Acceptance (A) | Milestone Task (T) |
|---|---|---|---|---|---|---|---|---|
| **Reduce Processing Cost & Effort** | F-01: Upload & Ingestion | US-UPLOAD-01: Unggah berkas invoice & pendukung | VR-009: Kualitas Ekstraksi | API-CASE-01 (`POST /cases`), API-DOC-01 (`POST /cases/{id}/documents`) | `cases`, `documents`, `document_pages`, `processing_jobs` | TC-G01, TC-F09, TC-SEC-03 | A-UPLOAD-01, A-PAGECOUNT-01 | T0.2, T1.1 |
| **Increase Scalability & Speed** | F-01: Ingestion Pipeline Monitoring | US-MONITOR-01: Pemantauan status pemrosesan & retry | N/A (Pipeline Health) | API-CASE-02 (`GET /cases`), API-CASE-03 (`GET /cases/{id}`), API-JOB-01 (`GET /jobs/{id}`) | `cases`, `processing_jobs` | TC-REC-01, TC-REC-02 | A-MONITOR-01 | T1.2, T3.1 |
| **Adaptive Document Capture** | F-02: Structured Extraction & Evidence | US-EXTRACT-01: Ekstraksi field faktur & evidence | VR-009: Kualitas Dokumen | API-DOC-02 (`GET /documents/{id}`), API-DOC-03 (`GET /documents/{id}/pages/{n}/image`) | `extractions`, `doc_headers`, `doc_line_items`, `evidence` | TC-G01, TC-G02, TC-F06, TC-AI-01 | A-EXTRACT-01, A-ACCURACY-01, A-HELDOUT-01, A-UNREADABLE-01 | T1.4, T1.5, T4.1 |
| **Automated Policy Validation** | F-03: Multi-Document Validation Engine | US-VALIDATE-01: Validasi silang faktur vs PO, GR, BAST | VR-001, VR-002, VR-003, VR-004, VR-005, VR-006, VR-007, VR-008, VR-009 | API-VAL-01 (`GET /cases/{id}/validation`), API-REP-01 (`POST /cases/{id}/reprocess`) | `validation_rules`, `validation_runs`, `validation_results`, `exceptions` | TC-G01, TC-F01, TC-F02, TC-F03, TC-F04, TC-F05, TC-F08 | A-RULES-01, A-EVIDENCE-01, A-PRECEDENCE-01, A-DUPLICATE-01 | T2.1, T2.2, T2.3 |
| **Human Decision Governance** | F-04: Exception Queue & Review Control | US-REVIEW-01: Peninjauan bukti & pencatatan keputusan manusia | N/A (Governance Control) | API-EXC-01 (`GET /exceptions`), API-EXC-02 (`PATCH /exceptions/{id}`), API-DEC-01 (`POST /cases/{id}/decisions`), API-DEC-02 (`GET /cases/{id}/decisions`) | `exceptions`, `review_decisions`, `audit_log` | TC-SEC-02 (Anti-Auto-Decision), TC-RBAC-01 | A-HUMAN-01, A-APPROVER-01, A-NEUTRAL-01, A-QUEUE-01 | T3.2, T3.3, T4.3 |
| **Operational Reporting** | F-05: Structured Export | US-EXPORT-01: Ekspor snapshot data terstruktur | N/A (Data Export) | API-EXP-01 (`POST /exports`), API-EXP-02 (`GET /exports/{id}`), API-EXP-03 (`GET /exports/{id}/download`) | `export_jobs`, `processing_jobs` | TC-SEC-04 (CSV Injection), TC-RBAC-01 | A-EXPORT-01 | T3.4 |
| **Commercial Predictability** | F-06: Credit Metering & Usage Tracking | US-CREDIT-01: Pemantauan kuota 50k & overage | N/A (Commercial Metering) | API-CRD-01 (`GET /credits/current`), API-CRD-02 (`GET /credits/history`), API-NOT-01 (`GET /notifications`), API-NOT-02 (`POST /notifications/{id}/read`) | `credit_periods`, `credit_ledger`, `notifications` | TC-C01 (Credit Idempotency), TC-C02 (Overage Formula), TC-ONPREM-01 | A-CREDITMETER-01, A-CREDITQUOTA-01, A-CREDITNOTIF-01, A-ONPREM-01 | T1.3, T3.5, T5.3 |
| **Platform Governance & Control** | F-07: Admin & Configuration Management | US-ADMIN-01: Manajemen user, parameter rule & audit | N/A (Administration) | API-ADM-01..03 (Users), API-ADM-04..05 (Rules), API-ADM-06 (`GET /admin/audit`) | `users`, `validation_rules`, `audit_log`, `api_idempotency` | TC-RBAC-01, TC-AUD-01 | A-ADMIN-01 | T0.3, T2.4, T3.6 |
| **Operational Reliability** | F-08: Ops Health & Recovery | US-OPS-01: Monitoring kesehatan, retry teknis & backup | N/A (Infrastructure) | API-OPS-01 (`GET /ops/health`), API-OPS-02 (`GET /ops/jobs`), API-OPS-03 (`POST /ops/jobs/{id}/retry`) | `processing_jobs`, `audit_log` | TC-REC-01, TC-REC-02, TC-RESTORE-01, TC-LOAD-01 | A-PERF-01, A-RECOVERY-01, A-RESTORE-01, A-SECURITY-01 | T1.2, T4.2, T5.1 |
| **Production Handover** | F-09: Handover & Adoption | US-HANDOVER-01: Penerimaan operasional & BAST Phase 1 | N/A (Project Handover) | Dokumen & Artefak Handover | Seluruh Tabel Sistem | Verifikasi Seluruh Suite Pengujian | A-HANDOVERDOC-01, A-TRAINING-01, A-SIGNBAST-01 | T4.4, T5.2, T5.4 |

---

## Matriks Pemetaan Aturan Validasi ke Test Case & Acceptance
Tabel ini memetakan seluruh aturan `VR-xxx` ke kasus uji deterministik dan kriteria penerimaan:

| Rule ID | Nama Aturan | Field Utama | Kasus Uji Positif | Kasus Uji Negatif | Kriteria Acceptance |
|---|---|---|---|---|---|
| **VR-001** | Total Invoice vs PO | `total_amount`, `currency` | TC-G01 (Sama) | TC-F01 (Selisih +10 jt) | A-RULES-01, A-EVIDENCE-01 |
| **VR-002** | Unit Price vs PO | `line_items.unit_price` | TC-G01 (Sama) | TC-F03 (Harga naik) | A-RULES-01, A-EVIDENCE-01 |
| **VR-003** | Qty Invoice vs GR/DN | `line_items.qty` | TC-G01 (Sama) | TC-F02 (Kelebihan qty) | A-RULES-01, A-EVIDENCE-01 |
| **VR-004** | Kelengkapan Referensi Dokumen | `references.po`, file PO | TC-G01 (Lengkap) | TC-F04 (PO hilang) | A-RULES-01, A-PRECEDENCE-01 |
| **VR-005** | BAST untuk Tagihan Jasa | `line_items.description`, file BAST | TC-G01 (BAST ada) | TC-F04b (BAST jasa hilang) | A-RULES-01, A-PRECEDENCE-01 |
| **VR-006** | Konsistensi Vendor, Tanggal & Mata Uang | `vendor_normalized`, `doc_date`, `currency` | TC-G01 (Konsisten) | TC-F08b (Vendor beda) | A-RULES-01, A-EVIDENCE-01 |
| **VR-007** | Perhitungan Internal Faktur | `subtotal`, `tax_amount`, `total_amount` | TC-G01 (Valid) | TC-F01b (Salah hitung pajak) | A-RULES-01, A-EVIDENCE-01 |
| **VR-008** | Deteksi Duplikasi Faktur | `sha256`, `vendor`, `number`, `total` | TC-G01 (Baru) | TC-F05 (File/header identik) | A-DUPLICATE-01 |
| **VR-009** | Kualitas Ekstraksi & Keterbacaan | `quality_flags`, key fields null | TC-G01 (Jelas) | TC-F06 (Gambar buram/null) | A-UNREADABLE-01 |

---

## Verifikasi Integritas Matriks
- **Cakupan User Story:** 100% dari 10 User Story terpetakan ke Endpoint, Tabel, Acceptance, dan Task.
- **Cakupan Validation Rule:** 100% dari 9 Aturan terpetakan ke Field, TestCase, dan Acceptance.
- **Cakupan Tabel:** Seluruh 21 tabel database memiliki modul pemroses dan proses pemakai.
- **Cakupan Kriteria Acceptance:** Seluruh 28 Kriteria Acceptance terpetakan ke User Story dan Task.
