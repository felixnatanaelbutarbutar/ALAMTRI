# Keamanan Informasi dan Perlindungan Data
Tujuan file ini: menetapkan model ancaman STRIDE, matriks RBAC tabular per-endpoint, tata kelola transmisi data AI, dan standar enkripsi.
Dibaca oleh / kapan dipakai: tim arsitek keamanan, backend engineer, auditor independen, dan tim IT Security PT SIS.

## Klasifikasi dan batas
Seluruh berkas dokumen transaksi keuangan (invoice, PO, surat jalan, GR, BAST), gambar render halaman, teks OCR, data ekstraksi finansial, nilai moneter, dan catatan keputusan manusia diklasifikasikan sebagai **SENSITIF & RAHASIA**.
- Kunci API, credential database, dan rahasia JWT diklasifikasikan sebagai **SANGAT RAHASIA (RESTRICTED)**.
- Metrik teknis sistem (latency p50/p95, CPU usage, jumlah antrean) diklasifikasikan sebagai **INTERNAL OPERASIONAL** dan DILARANG memuat label vendor, nomor invoice, atau nominal uang.
- Sistem ini BUKAN alat investigasi fraud, opini perpajakan, atau audit forensik hukum. Seluruh kontrol keamanan dirancang untuk menjaga integritas data dan kepatuhan kerahasiaan korporasi.

---

## Threat model (STRIDE)

| Kategori Ancaman | Deskripsi Skenario Ancaman | Kontrol Mitigasi Sistem | Uji Verifikasi |
|---|---|---|---|
| **Spoofing (Penyamaran)** | Pengguna tidak sah mencoba memalsukan token atau mengaku sebagai Approver untuk mencatat keputusan faktur. | Autentikasi berbasis tanda tangan kriptografis JWT, validasi subjek token ke database user aktif, penolakan token non-interaktif/service worker pada endpoint keputusan (`HUMAN_REQUIRED`). | `TC-RBAC-01`, `TC-SEC-02` |
| **Tampering (Manipulasi)** | Penyerang atau staf korup mencoba mengubah nilai ekstraksi atau memodifikasi riwayat audit log di database. | Hak akses database aplikasi dibatasi (`GRANT INSERT, SELECT`), trigger database menolak `UPDATE`/`DELETE` pada tabel immutable, dan verifikasi integritas rantai hash (`entry_hash`). | `TC-AUD-01`, `TC-SEC-01` |
| **Repudiation (Penyangkalan)** | Approver menyangkal telah mencatat keputusan review pada faktur tertentu. | Tabel `review_decisions` bersifat append-only, mencatat UUID aktor terautentikasi, waktu server UTC, ID snapshot run, dan dicatat atomik ke `audit_log`. | `TC-SEC-02`, `TC-AUD-01` |
| **Information Disclosure (Kebocoran Data)** | Staf tenant A mencoba mengakses dokumen milik tenant B (IDOR) atau data bocor melalui log aplikasi/model AI eksternal. | Isolasi tenant multi-tenant menggunakan composite foreign key `(tenant_id, id)`, penolakan akses lintas tenant dengan 404, redaction otomatis pada logger, dan kebijakan `ALLOW_EXTERNAL_LLM`. | `TC-SEC-01`, `TC-T01` |
| **Denial of Service (Pelemahan Sistem)** | Pengunggahan file PDF raksasa (decompression bomb) atau spam request untuk menguras kuota kredit Managed. | Pemeriksaan magic bytes, batas ukuran berkas maksimum 50 MB, batas halaman maksimum 150 halaman, sandboxing renderer non-root, dan rate limiting per IP/user. | `TC-SEC-03`, `TC-LOAD-01` |
| **Elevation of Privilege (Eskalasi Hak)** | Pengguna dengan peran Staff mencoba mengubah konfigurasi sistem atau parameter aturan validasi. | Matriks RBAC ketat pada level middleware API, validasi peran server-side (dilarang mempercayai klaim body request). | `TC-RBAC-01` |

---

## RBAC dan autentikasi

### Matriks Otorisasi Peran x Aksi API:
| Kelompok Aksi & Endpoint | Finance Staff (STAFF) | Approver (APPROVER) | Admin (ADMIN) | INaAI Ops (OPS) |
|---|:---:|:---:|:---:|:---:|
| **Membuat Case Baru & Unggah Berkas** (`POST /cases/*`) | **YA** | **YA** | DILARANG | DILARANG |
| **Membaca Dokumen & Evidence Gambar** (`GET /cases/*`, `/documents/*`) | **YA** | **YA** | DILARANG | DILARANG |
| **Meninjau & Mengubah Status Exception** (`GET/PATCH /exceptions/*`) | **YA** | **YA** | DILARANG | DILARANG |
| **Mencatat Keputusan Manusia** (`POST /cases/{id}/decisions`) | DILARANG | **YA (Hanya Manusia)** | DILARANG | DILARANG |
| **Mengekspor Snapshot Data** (`POST/GET /exports/*`) | **YA** | **YA** | DILARANG | DILARANG |
| **Melihat Penggunaan Kredit & Kuota** (`GET /credits/*`) | DILARANG | DILARANG | **YA (Managed)** | DILARANG |
| **Mengelola Pengguna & Peran** (`GET/POST/PATCH /admin/users/*`) | DILARANG | DILARANG | **YA** | DILARANG |
| **Menyesuaikan Parameter Toleransi Rule** (`PATCH /admin/rules/*`) | DILARANG | DILARANG | **YA** | DILARANG |
| **Membaca Log Jejak Audit** (`GET /admin/audit`) | DILARANG | DILARANG | **YA** | DILARANG |
| **Melihat Status Kesehatan Teknis** (`GET /ops/health`) | DILARANG | DILARANG | DILARANG | **YA** |
| **Melakukan Retry Teknis Antrean Job** (`POST /ops/jobs/*/retry`) | DILARANG | DILARANG | DILARANG | **YA (Sanitasi)** |

---

## Enkripsi dan secret
1. **Enkripsi Saat Transit (In-Transit):**
   - Wajib menggunakan protokol **TLS 1.3** (atau minimal TLS 1.2 dengan cipher suite modern PFS).
   - Seluruh koneksi eksternal dan antar-layanan internal (web ke API, API ke database, worker ke Redis) wajib terenkripsi TLS.
2. **Enkripsi Saat Diam (At-Rest):**
   - Database PostgreSQL: Tablespace terenkripsi menggunakan modul enkripsi bawaan atau enkripsi block-level Linux LUKS (AES-256).
   - Object Storage (MinIO / S3): Server-Side Encryption dengan kunci yang dikelola (SSE-KMS / SSE-S3 AES-256).
   - Teks sensitif OCR (`document_pages.ocr_text_encrypted`) dienkripsi pada layer aplikasi menggunakan algoritma **AES-256-GCM** sebelum disimpan ke database.
3. **Manajemen Rahasia (Secret Management):**
   - DILARANG MENYIMPAN SECRET (password, API key, JWT secret) di dalam repositori kode git atau berkas `.env` publik.
   - Pada produksi, secret disuplai melalui file mount yang aman (`/run/secrets/*`) atau integrasi Secret Manager korporat.

---

## Logging dan isolasi
1. **Daftar Larangan Logging (Strict Logging Blacklist):**
   - DILARANG mencatat isi teks dokumen mentah, hasil OCR utuh, atau transkrip prompt LLM.
   - DILARANG mencatat nomor rekening, nomor NPWP, nama vendor riil, atau nilai nominal transaksi faktur pada log level INFO/DEBUG.
   - DILARANG mencatat password, token Bearer, atau kunci akses API.
2. **Daftar Izin Logging (Logging Whitelist):**
   - Hanya diizinkan mencatat: `timestamp`, `request_id`, `actor_id` (pseudonim UUID), `tenant_id`, `endpoint_route`, `http_status`, `error_code`, `latency_ms`, dan `page_count` agregat.
3. **Isolasi Log Audit:**
   - Log audit sistem (`audit_log`) disimpan pada tabel partisi terpisah dan dikirimkan secara berkala ke penyimpanan off-site immutable bertanda tangan digital.

---

## Retensi dan LLM
1. **Tata Kelola Pengiriman Data ke LLM Eksternal:**
   - Variabel `ALLOW_EXTERNAL_LLM` mengontrol izin egress: jika diset `false`, sistem memblokir seluruh panggilan jaringan ke API cloud luar dan mewajibkan penggunaan model lokal on-premise.
   - Hanya teks halaman dan koordinat layout yang dikirim ke LLM; metadata kredensial pengguna atau data tenant lain DILARANG disertakan dalam prompt.
   - Kontrak kerja sama dengan provider cloud LLM WAJIB menyertakan klausul **Zero Data Retention (ZDR)** dan penegasan bahwa data klien PT SIS DILARANG digunakan untuk pelatihan model (model training/fine-tuning).
2. **Kebijakan Retensi Berkas Dokumen (Mengacu Q-005):**
   - Dokumen transaksi keuangan dipertahankan selama masa retensi legal perpajakan (default usulan: 7 tahun).
   - Berkas unduhan ekspor sementara otomatis dihapus setelah 24 jam (`EXPORT_TTL_SECONDS=86400`).

---

## Gate keamanan
Sebelum rilis ke lingkungan produksi atau pelaksanaan UAT, sistem WAJIB lolos seluruh pengujian gerbang keamanan berikut:
1. **Automated SAST & Dependency Vulnerability Scan:** Bebas dari kerentanan kritis (Critical/High CVE) pada lockfile pustaka.
2. **Secret Leak Detection:** Pemindaian repositori git bersih dari kebocoran credential (menggunakan gitleaks/trufflehog).
3. **Automated IDOR & Multi-Tenant Regression Test:** 100% endpoint lulus uji akses silang antar-tenant dengan respons 404.
4. **Anti-Prompt Injection Test Suite:** Seluruh kasus uji serangan injeksi dokumen (`SYN-F07`) terbukti tidak mampu mengekstrak instruksi atau mengubah status keputusan sistem.
