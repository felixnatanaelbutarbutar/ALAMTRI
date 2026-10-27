# Audit Jejak Sistem dan Integritas Riwayat
Tujuan file ini: mendefinisikan katalog event audit, skema payload metadata terdaftar (allowlist), dan mekanisme integritas hash chain anti-manipulasi.
Dibaca oleh / kapan dipakai: tim backend engineer, administrator sistem, petugas kepatuhan data, dan auditor independen.

## Batas dan format
**Berdasarkan Usulan D-011/D-013.**
1. **Definisi Lingkup:** Ini adalah **audit jejak sistem dan operasional perangkat lunak**, BUKAN audit investigasi fraud, opini perpajakan, atau pemeriksaan hukum pidana.
2. **Kerahasiaan Konten Audit:** Log audit DILARANG memuat isi teks dokumen mentah, hasil OCR utuh, nilai nominal transaksi moneter, rincian rekening bank, atau catatan review bebas. Metadata audit HANYA menyimpan pengenal unik (UUID), kode status, referensi dokumen, dan parameter perubahan konfigurasi yang diizinkan (allowlist).
3. **Format JSON Log Audit Terstandar:**
```json
{
  "id": "aaaaaaaa-aaaa-4000-8000-aaaaaaaaaaaa",
  "tenant_id": "11111111-1111-4000-8000-111111111111",
  "actor_id": "22222222-2222-4000-8000-222222222222",
  "actor_type": "HUMAN",
  "action": "REVIEW_DECISION_RECORDED",
  "entity_type": "review_decisions",
  "entity_id": "33333333-3333-4000-8000-333333333333",
  "request_id": "44444444-4444-4000-8000-444444444444",
  "metadata": {
    "case_id": "55555555-5555-4000-8000-555555555555",
    "run_id": "66666666-6666-4000-8000-666666666666",
    "decision": "NEEDS_CLARIFICATION",
    "has_note": true
  },
  "occurred_at": "2026-10-27T10:00:00Z",
  "previous_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "entry_hash": "b5a92a4e929b9f7a7019f88c88086055d7b5f543949c81b5c46e01a88b8e018d"
}
```

---

## Event wajib

Seluruh mutasi data penting pada sistem WAJIB menghasilkan rekaman audit dalam blok transaksi database yang sama (jika penulisan audit gagal, mutasi bisnis dibatalkan/rollback).

| Grup Event | Action Name | Pemicu (Trigger) | Skema Payload Metadata (Allowlisted) |
|---|---|---|---|
| **Autentikasi** | `AUTH_LOGIN_SUCCEEDED` | Pengguna berhasil login | `{"subject": "str", "auth_method": "SSO\|LOCAL"}` |
| **Autentikasi** | `AUTH_LOGIN_FAILED` | Percobaan login gagal | `{"attempted_email": "str", "reason": "INVALID_CREDENTIALS"}` |
| **Autentikasi** | `ACCESS_DENIED` | Percobaan akses terlarang (403) | `{"route": "str", "required_role": "str", "actual_role": "str"}` |
| **Manajemen Kasus** | `CASE_CREATED` | Pembuatan Case baru | `{"case_id": "uuid", "case_number": "str"}` |
| **Ingestion Berkas** | `DOCUMENT_ACCEPTED` | Berkas lolos karantina & dihitung halamannya | `{"document_id": "uuid", "page_count": 4, "sha256": "str"}` |
| **Ingestion Berkas** | `DOCUMENT_REJECTED` | Berkas ditolak saat upload | `{"filename": "str", "rejection_code": "FILE_TOO_LARGE"}` |
| **Pipeline AI** | `EXTRACTION_COMPLETED`| AI selesai ekstraksi dokumen | `{"document_id": "uuid", "model_id": "str", "prompt_version": "str"}` |
| **Validasi Silang** | `VALIDATION_COMPLETED`| Rule engine selesai evaluasi | `{"case_id": "uuid", "run_id": "uuid", "overall_status": "MATCHED\|NEEDS_REVIEW"}` |
| **Pengecualian** | `EXCEPTION_ASSIGNED` | Pengecualian ditugaskan ke staf | `{"exception_id": "uuid", "assigned_to": "uuid"}` |
| **Pengecualian** | `EXCEPTION_RESOLVED` | Pengecualian ditandai selesai | `{"exception_id": "uuid", "resolution_reason": "str"}` |
| **Keputusan Manusia**| `REVIEW_DECISION_RECORDED` | Approver menyimpan keputusan | `{"case_id": "uuid", "run_id": "uuid", "decision": "ACCEPTED", "has_note": true}` |
| **Parameter Aturan** | `RULE_PARAMS_VERSIONED` | Admin mengubah parameter rule | `{"rule_code": "str", "version_before": 1, "version_after": 2, "approval_ref": "str"}` |
| **Kredit Managed** | `CREDIT_CHARGED` | Pemotongan kredit transaksi | `{"period_id": "uuid", "pages": 4, "credits": 4, "billing_key": "str"}` |
| **Kredit Managed** | `CREDIT_PERIOD_CLOSED`| Penutupan bulan periode kredit | `{"period_key": "YYYY-MM", "total_used": 42500, "overage": 0}` |
| **Notifikasi Kuota** | `QUOTA_NOTIFIED` | Pemicu notifikasi batas kuota | `{"period_id": "uuid", "type": "NEAR_QUOTA\|QUOTA_REACHED"}` |
| **Ekspor Data** | `EXPORT_DOWNLOADED` | Pengguna mengunduh file ekspor | `{"export_id": "uuid", "format": "CSV\|XLSX"}` |
| **Operasi Sistem** | `BACKUP_VERIFIED` | Hasil verifikasi restore backup | `{"backup_id": "str", "status": "VERIFIED", "duration_sec": 45}` |

---

## Immutability dan akses

### Algoritma Hash Chain Anti-Tamper:
Untuk menjamin bahwa rekaman audit tidak dapat disisipkan, dihapus, atau diubah tanpa terdeteksi oleh pihak internal berakses superuser database:
1. Setiap baris audit menyimpan hash entri sebelumnya (`previous_hash`) dalam tenant yang sama.
2. Kolom `entry_hash` dihitung secara deterministik menggunakan fungsi kriptografis SHA-256 dengan kanonikalisasi JSON:
   $$\text{canonical\_payload} = \text{SortKeys}(\text{tenant\_id} + \text{actor\_id} + \text{action} + \text{occurred\_at} + \text{metadata})$$
   $$\text{entry\_hash} = \text{SHA256}(\text{previous\_hash} + \text{canonical\_payload})$$
3. **Penyimpanan Checkpoint Eksternal:** Setiap 24 jam sekali, hash entri terakhir ditandatangani secara digital (digital signature) dan diekspor ke penyimpanan terpisah (WORM / Write Once Read Many object storage) yang memiliki proteksi legal hold.

### Hak Akses Audit:
- Peran `ADMIN` memiliki hak baca paginasi audit tenant melalui `/admin/audit`.
- Peran `STAFF` dan `APPROVER` hanya dapat melihat riwayat keputusan manusia untuk kasus yang diotorisasi.
- Peran `OPS` hanya dapat melihat log operasi sistem teknis tanpa akses ke entri audit dokumen bisnis.

---

## Keputusan manusia dan jejak versi
1. **Pemisahan Entitas Audit vs Keputusan:**
   - Tabel `review_decisions` menyimpan catatan otorisasi manusia secara fungsional.
   - Tabel `audit_log` mencatat event kejadian penyimpanan keputusan tersebut sebagai saksi kriptografis.
2. **Kekebalan dari Modifikasi Ulang:**
   - Keputusan manusia tidak pernah di-*UPDATE* atau di-*DELETE*.
   - Jika Approver ingin mengubah keputusannya setelah konfirmasi klarifikasi baru, sistem membuat baris baru di `review_decisions` dengan mengisi kolom `supersedes_id` yang merujuk pada UUID keputusan lama. Kedua versi keputusan tetap terbaca jelas dalam linimasa riwayat.

---

## Laporan minimum
Platform menyediakan antarmuka bagi Admin untuk menghasilkan laporan rekapitulasi jejak audit dalam rentang tanggal tertentu:
1. **Laporan Aktivitas Peninjauan Faktur:** Rekap seluruh keputusan yang dicatat oleh para Approver beserta jangka waktu verifikasi sejak berkas diunggah.
2. **Laporan Rekonsiliasi Konsumsi Kredit:** Rekap harian jumlah halaman dokumen yang diproses vs kredit yang terpotong pada buku besar `credit_ledger`.
3. **Laporan Perubahan Kebijakan Aturan:** Rekap riwayat penyesuaian parameter toleransi aturan validasi, mencakup siapa pengubahnya, tanggal, dan nomor surat persetujuan (*approval reference*).
