# Kontrak REST API
Tujuan file ini: menetapkan spesifikasi REST API, otorisasi peran, skema JSON, katalog kode error terpusat, dan spesifikasi OpenAPI 3.1.
Dibaca oleh / kapan dipakai: tim pengembang backend, frontend developer, dan QA engineer saat membangun integrasi dan automated contract testing.

## Konvensi kontrak
**Berdasarkan Usulan D-009/D-013.** Base path seluruh API: `/api/v1`.
1. **Format Payload & Encoding:** Seluruh permintaan dan respons menggunakan format JSON (`application/json; charset=utf-8`), kecuali endpoint unggah berkas (`multipart/form-data`) dan unduh berkas (`application/octet-stream`).
2. **Autentikasi & Konteks Pengguna:** Melalui header `Authorization: Bearer <token>`. Seluruh data difilter otomatis berdasarkan `tenant_id` dari subjek token terverifikasi.
3. **Format Angka & Finansial:** Seluruh nilai mata uang dan kuantitas WAJIB dikirimkan sebagai **Decimal String** (misal: `"1000000.000000"`), DILARANG mengirim angka desimal mentah (float) untuk mencegah kehilangan presisi.
4. **Idempotensi Mutasi:** Seluruh request mutasi (`POST`, `PATCH`, `DELETE`) WAJIB menyertakan header `Idempotency-Key: <UUID>`. Pengiriman ulang dengan key dan payload yang sama mengembalikan respons awal; pengiriman ulang dengan key sama namun payload berbeda mengembalikan 409 `IDEMPOTENCY_CONFLICT`.
5. **Paginasi Standar:** Seluruh list endpoint mendukung query param: `page` (default: 1, min: 1) dan `page_size` (default: 25, min: 1, max: 100). Envelope list:
   ```json
   {
     "items": [],
     "page": 1,
     "page_size": 25,
     "total_items": 120,
     "total_pages": 5
   }
   ```
6. **Perilaku Per Deployment Mode:** Pada mode `DEPLOYMENT_MODE=onprem`, seluruh endpoint grup `/credits/*` dan notifikasi kuota menghasilkan respons HTTP 404 dengan kode error `FEATURE_DISABLED`.

---

## Schema sumber daya

### User
```json
{
  "id": "11111111-1111-4000-8000-111111111111",
  "subject": "usr_sis_staff01",
  "name": "Budi Santoso",
  "email": "budi.santoso@sis.co.id",
  "role": "STAFF",
  "active": true,
  "version": 1,
  "created_at": "2026-10-27T08:00:00Z"
}
```

### Case & Case Detail
```json
{
  "id": "22222222-2222-4000-8000-222222222222",
  "case_number": "CAS-2026-0001",
  "processing_status": "VALIDATED",
  "validation_status": "NEEDS_REVIEW",
  "total_pages": 4,
  "current_run_id": "33333333-3333-4000-8000-333333333333",
  "version": 2,
  "created_at": "2026-10-27T08:30:00Z",
  "documents": [],
  "latest_decision": null
}
```

### Evidence
```json
{
  "id": "44444444-4444-4000-8000-444444444444",
  "extraction_id": "55555555-5555-4000-8000-555555555555",
  "document_id": "66666666-6666-4000-8000-666666666666",
  "page_number": 1,
  "field_path": "total_amount",
  "value": "110000000.000000",
  "bbox": [0.72, 0.85, 0.91, 0.88]
}
```

---

## Endpoint identitas dan konfigurasi

| Endpoint | Method | Role | Header Wajib | Request Body | Response (Sukses) | Error Codes |
|---|:---:|:---:|---|---|---|---|
| `API-AUTH-01: /auth/login` | `POST` | Publik | None | `{"email": "string", "password": "string"}` | `200 OK` `{"access_token": "string", "token_type": "Bearer", "expires_in": 3600}` | `INVALID_CREDENTIALS`, `ACCOUNT_DISABLED`, `FEATURE_DISABLED` (pada mode SSO produksi) |
| `API-AUTH-02: /auth/logout` | `POST` | All | `Authorization` | `{}` | `200 OK` `{"logged_out": true}` | `UNAUTHENTICATED` |
| `API-AUTH-03: /auth/me` | `GET` | All | `Authorization` | None | `200 OK` Resource `User` | `UNAUTHENTICATED`, `USER_NOT_FOUND` |
| `API-CAP-01: /capabilities` | `GET` | All | `Authorization` | None | `200 OK` `{"deployment_mode": "managed", "credit_enabled": true, "export_formats": ["CSV", "XLSX"], "upload_limits": {"max_bytes": 52428800, "max_pages": 150, "mime_types": ["application/pdf", "image/png", "image/jpeg"]}}` | `UNAUTHENTICATED` |

---

## Case, dokumen dan job

| Endpoint | Method | Role | Header Wajib | Query / Request Body | Response (Sukses) | Error Codes |
|---|:---:|:---:|---|---|---|---|
| `API-CASE-01: /cases` | `POST` | STAFF, APPROVER | `Authorization`, `Idempotency-Key` | `{}` | `201 Created` Resource `Case` | `IDEMPOTENCY_CONFLICT` |
| `API-CASE-02: /cases` | `GET` | STAFF, APPROVER | `Authorization` | `page`, `page_size`, `processing_status`, `validation_status`, `vendor_query`, `date_from`, `date_to` | `200 OK` Paged List of `Case` | `INVALID_FILTER_PARAMS` |
| `API-CASE-03: /cases/{id}` | `GET` | STAFF, APPROVER | `Authorization` | Path: `id` (UUID) | `200 OK` Resource `Case Detail` | `CASE_NOT_FOUND` |
| `API-DOC-01: /cases/{id}/documents` | `POST` | STAFF, APPROVER | `Authorization`, `Idempotency-Key` | Multipart: `file` (binary), `doc_type` (hint enum opsional) | `202 Accepted` `{"document_id": "UUID", "job_id": "UUID", "status_url": "/api/v1/jobs/{job_id}"}` | `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA`, `UNREADABLE_DOCUMENT`, `UNSAFE_FILE`, `PAGE_LIMIT_EXCEEDED` |
| `API-DOC-02: /documents/{id}` | `GET` | STAFF, APPROVER | `Authorization` | Path: `id` (UUID), Query: `extraction_id` (opsional) | `200 OK` Resource `Document` + `Extraction` | `DOCUMENT_NOT_FOUND` |
| `API-DOC-03: /documents/{id}/pages/{n}/image` | `GET` | STAFF, APPROVER | `Authorization` | Path: `id`, `n` (halaman >= 1) | `200 OK` Binary `image/png` (`Cache-Control: private, no-store`) | `PAGE_NOT_FOUND`, `IMAGE_RENDER_FAILED` |
| `API-JOB-01: /jobs/{id}` | `GET` | STAFF, APPROVER, OPS | `Authorization` | Path: `id` (UUID) | `200 OK` Resource `Job` (OPS menerima metadata tersanitasi tanpa dokumen) | `JOB_NOT_FOUND` |
| `API-REP-01: /cases/{id}/reprocess` | `POST` | STAFF, APPROVER | `Authorization`, `Idempotency-Key` | `{"expected_version": 2, "reason": "Pembaruan dokumen"}` | `202 Accepted` `{"job_id": "UUID", "status_url": "/api/v1/jobs/{job_id}"}` | `STALE_VERSION`, `INVALID_STATE`, `POLICY_UNRESOLVED` |

---

## Validasi dan review

| Endpoint | Method | Role | Header Wajib | Request Body | Response (Sukses) | Error Codes |
|---|:---:|:---:|---|---|---|---|
| `API-VAL-01: /cases/{id}/validation` | `GET` | STAFF, APPROVER | `Authorization` | Path: `id`, Query: `run_id` (opsional) | `200 OK` Resource `Validation` (Run, Results, Evidence) | `CASE_NOT_FOUND`, `RUN_NOT_FOUND` |
| `API-EXC-01: /exceptions` | `GET` | STAFF, APPROVER | `Authorization` | Query: `page`, `page_size`, `case_id`, `state`, `severity`, `type` | `200 OK` Paged List of `Exception` (Urut: severity, umur FIFO) | `INVALID_FILTER_PARAMS` |
| `API-EXC-02: /exceptions/{id}` | `PATCH` | STAFF, APPROVER | `Authorization`, `Idempotency-Key` | `{"state": "IN_REVIEW", "assigned_to": "UUID", "expected_version": 1}` | `200 OK` Resource `Exception` | `EXCEPTION_NOT_FOUND`, `STALE_VERSION` |
| `API-DEC-01: /cases/{id}/decisions` | `POST` | APPROVER (Hanya Manusia) | `Authorization`, `Idempotency-Key` | `{"run_id": "UUID", "expected_case_version": 2, "decision": "NEEDS_CLARIFICATION", "note": "Klarifikasi harga", "supersedes_id": null}` | `201 Created` Resource `Decision` | `HUMAN_REQUIRED`, `STALE_RUN`, `STALE_VERSION`, `INVALID_DECISION_VOCAB` |
| `API-DEC-02: /cases/{id}/decisions` | `GET` | STAFF, APPROVER | `Authorization` | Path: `id` | `200 OK` Paged List of `Decision` (Riwayat keputusan manusia) | `CASE_NOT_FOUND` |

*Catatan Kritis Otorisasi Keputusan:* Endpoint `POST /cases/{id}/decisions` menolak keras token sistem, service worker, atau peran non-APPROVER dengan HTTP 403 `HUMAN_REQUIRED`.

---

## Export, credit dan notifikasi

| Endpoint | Method | Role | Header Wajib | Request Body | Response (Sukses) | Error Codes |
|---|:---:|:---:|---|---|---|---|
| `API-EXP-01: /exports` | `POST` | STAFF, APPROVER | `Authorization`, `Idempotency-Key` | `{"case_ids": ["UUID"], "format": "CSV"}` | `202 Accepted` `{"export_id": "UUID", "job_id": "UUID", "status_url": "/api/v1/jobs/{job_id}"}` | `UNAUTHORIZED_CASES`, `UNSUPPORTED_FORMAT` |
| `API-EXP-02: /exports/{id}` | `GET` | Pemohon S/P | `Authorization` | Path: `id` | `200 OK` Resource `Export` (`download_url` saat READY) | `EXPORT_NOT_FOUND`, `FORBIDDEN` |
| `API-EXP-03: /exports/{id}/download` | `GET` | Pemohon S/P | `Authorization` | Path: `id` | `200 OK` Binary File Attachment (`no-store`) | `EXPORT_EXPIRED`, `EXPORT_NOT_READY` |
| `API-CRD-01: /credits/current` | `GET` | ADMIN (Managed) | `Authorization` | None | `200 OK` Resource `CreditSummary` (quota, used, remaining, overage, biaya) | `FEATURE_DISABLED` (pada onprem) |
| `API-CRD-02: /credits/history` | `GET` | ADMIN (Managed) | `Authorization` | Query: `page`, `page_size`, `period_from`, `period_to` | `200 OK` Paged List of `CreditSummary` | `FEATURE_DISABLED` (pada onprem) |
| `API-NOT-01: /notifications` | `GET` | ADMIN (Managed) | `Authorization` | Query: `unread_only` (bool) | `200 OK` Paged List of `Notification` | `FEATURE_DISABLED` (pada onprem) |
| `API-NOT-02: /notifications/{id}/read` | `POST` | ADMIN (Managed) | `Authorization` | Path: `id` | `200 OK` Resource `Notification` | `NOTIF_NOT_FOUND` |

---

## Admin dan operasi

| Endpoint | Method | Role | Header Wajib | Request Body | Response (Sukses) | Error Codes |
|---|:---:|:---:|---|---|---|---|
| `API-ADM-01: /admin/users` | `GET` | ADMIN | `Authorization` | Query: `role`, `active`, `page` | `200 OK` Paged List of `User` | `FORBIDDEN` |
| `API-ADM-02: /admin/users` | `POST` | ADMIN | `Authorization`, `Idempotency-Key` | `{"subject": "str", "name": "str", "email": "str", "role": "STAFF", "active": true}` | `201 Created` Resource `User` | `EMAIL_ALREADY_EXISTS`, `INVALID_ROLE` |
| `API-ADM-03: /admin/users/{id}` | `PATCH` | ADMIN | `Authorization`, `Idempotency-Key` | `{"role": "APPROVER", "active": true, "expected_version": 1}` | `200 OK` Resource `User` | `USER_NOT_FOUND`, `STALE_VERSION`, `CANNOT_DISABLE_LAST_ADMIN` |
| `API-ADM-04: /admin/rules` | `GET` | ADMIN | `Authorization` | Query: `code`, `active` | `200 OK` Paged List of `ValidationRule` | `FORBIDDEN` |
| `API-ADM-05: /admin/rules/{id}/params` | `PATCH` | ADMIN | `Authorization`, `Idempotency-Key` | `{"params": {"total_amount_tolerance": "0.00"}, "expected_rule_version": 1, "reason": "Penyesuaian toleransi", "approval_reference": "CR-2026-001"}` | `201 Created` Versi baru Resource `ValidationRule` | `RULE_NOT_FOUND`, `STALE_RULE_VERSION`, `INVALID_RULE_PARAMS` |
| `API-ADM-06: /admin/audit` | `GET` | ADMIN | `Authorization` | Query: `action`, `date_from`, `date_to`, `actor_id` | `200 OK` Paged List of `AuditEntry` | `FORBIDDEN` |
| `API-OPS-01: /ops/health` | `GET` | OPS | `Authorization` | None | `200 OK` `{"api": "UP", "db": "UP", "queue": "UP", "storage": "UP", "model": "UP"}` | `503 SERVICE_UNAVAILABLE` (jika komponen inti down) |
| `API-OPS-02: /ops/jobs` | `GET` | OPS | `Authorization` | Query: `status`, `kind`, `page` | `200 OK` Paged List of `Job` (tersanitasi tanpa isi dokumen/finansial) | `FORBIDDEN` |
| `API-OPS-03: /ops/jobs/{id}/retry` | `POST` | OPS | `Authorization`, `Idempotency-Key` | `{"reason": "Network timeout retry", "expected_attempt": 1}` | `202 Accepted` Resource `Job` | `JOB_NOT_FOUND`, `JOB_ALREADY_SUCCEEDED` |

---

## Error dan versioning

### Format Respons Error Standar (RFC 7807 Terstruktur)
Setiap respons kegagalan (HTTP 4xx dan 5xx) WAJIB mengembalikan envelope JSON berikut:
```json
{
  "error": {
    "code": "STALE_RUN",
    "message": "Hasil validasi telah berubah. Muat ulang halaman sebelum mencatat keputusan.",
    "details": {
      "current_run_id": "33333333-3333-4000-8000-333333333333"
    }
  },
  "request_id": "99999999-9999-4000-8000-999999999999"
}
```

### Katalog Error Terpusat:
| HTTP Status | Kode Error (`error.code`) | Deskripsi Masalah | Tindakan Klien |
|:---:|---|---|---|
| **400** | `INVALID_REQUEST` | Parameter request tidak memenuhi format dasar | Perbaiki format data |
| **401** | `UNAUTHENTICATED` | Token kedaluwarsa, tidak ada, atau tanda tangan tidak sah | Login ulang untuk mendapat token baru |
| **403** | `FORBIDDEN` | Peran pengguna tidak memiliki hak akses aksi ini | Hubungi Admin untuk eskalasi peran |
| **403** | `HUMAN_REQUIRED` | Aksi pencatatan keputusan dicoba oleh service token/AI | Akses hanya boleh melalui manusia berwenang |
| **404** | `NOT_FOUND` | Entitas yang diminta tidak ditemukan dalam tenant aktif | Verifikasi UUID entitas |
| **404** | `FEATURE_DISABLED` | Fitur credit/kuota dinonaktifkan pada skema On-Premise | Sembunyikan fitur pada deployment On-Premise |
| **409** | `IDEMPOTENCY_CONFLICT` | Idempotency-Key sama digunakan dengan payload berbeda | Gunakan UUID idempotensi baru |
| **409** | `STALE_VERSION` | Versi entitas telah berubah di server (concurrency conflict) | Ambil data terbaru dan kirim ulang |
| **409** | `STALE_RUN` | Hasil validasi telah diperbarui oleh run baru | Muat ulang sebelum review keputusan |
| **409** | `INVALID_STATE` | Status entitas tidak mengizinkan operasi yang diminta | Periksa diagram state machine |
| **409** | `POLICY_UNRESOLVED` | Operasi komersial billable diblokir karena kebijakan belum disepakati | Tunggu penyelesaian Discovery |
| **410** | `EXPORT_EXPIRED` | Berkas ekspor telah melewati batas retensi TTL | Buat permohonan ekspor baru |
| **413** | `FILE_TOO_LARGE` | Berkas melebihi batas ukuran (maksimal 50 MB) | Kompres atau pisahkan berkas |
| **415** | `UNSUPPORTED_MEDIA` | Format MIME bukan PDF/PNG/JPEG | Unggah dalam format yang diizinkan |
| **422** | `UNREADABLE_DOCUMENT` | PDF terenkripsi sandi atau file corrupt tidak bisa dibaca | Buka proteksi berkas sebelum unggah |
| **422** | `UNSAFE_FILE` | Berkas terdeteksi mengandung konten berbahaya / malware | Karantina dan periksa berkas |
| **422** | `PAGE_LIMIT_EXCEEDED` | Jumlah halaman berkas melebihi batas (maksimal 150 halaman) | Pisahkan berkas menjadi bagian lebih kecil |
| **429** | `RATE_LIMITED` | Batas kecepatan request terlampaui | Tunggu sesuai header `Retry-After` |
| **503** | `SERVICE_UNAVAILABLE` | Komponen database atau antrean sedang down | Coba kembali beberapa saat lagi |

---

## OpenAPI 3.1 Spesifikasi Ringkas (YAML)

```yaml
openapi: 3.1.0
info:
  title: SIS AI Invoice Intelligence Platform REST API
  version: 1.0.0
  description: Kontrak REST API untuk ekstraksi, validasi silang, dan review invoice PT SIS.
paths:
  /cases:
    post:
      summary: Membuat Case baru untuk bundel invoice
      operationId: createCase
      responses:
        '201':
          description: Case berhasil dibuat
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Case'
    get:
      summary: Mengambil daftar case terpaginasi
      operationId: listCases
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: page_size
          in: query
          schema:
            type: integer
            default: 25
      responses:
        '200':
          description: Daftar case
  /cases/{id}/decisions:
    post:
      summary: Approver manusia mencatat keputusan peninjauan
      operationId: recordDecision
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [run_id, expected_case_version, decision, note]
              properties:
                run_id: { type: string, format: uuid }
                expected_case_version: { type: integer }
                decision: { type: string, enum: [ACCEPTED, REJECTED, NEEDS_CLARIFICATION] }
                note: { type: string }
      responses:
        '201':
          description: Catatan keputusan berhasil disimpan
        '403':
          description: Ditolak jika bukan Approver manusia
components:
  schemas:
    Case:
      type: object
      required: [id, case_number, processing_status, total_pages, version, created_at]
      properties:
        id: { type: string, format: uuid }
        case_number: { type: string }
        processing_status: { type: string, enum: [UPLOADED, PROCESSING, EXTRACTED, VALIDATED, FAILED] }
        validation_status: { type: [string, "null"], enum: [MATCHED, NEEDS_REVIEW, INCOMPLETE, DUPLICATE_SUSPECT, null] }
        total_pages: { type: integer }
        version: { type: integer }
        created_at: { type: string, format: date-time }
```
