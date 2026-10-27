# AI-Based Invoice Intelligence Platform
Tujuan file ini: menjadi pintu masuk spesifikasi tunggal proyek PT SIS dan panduan pembacaan seluruh dokumen arsitektur.
Dibaca oleh / kapan dipakai: seluruh agent coding, engineer, project manager, dan auditor sebelum merencanakan atau memodifikasi implementasi.

## Status dan sumber
Dokumentasi pra-pengembangan resmi, berdasarkan instruksi turunan **Proposal Document Version 2, 26 Oktober 2026**.
- **Klien:** PT Saptaindra Sejati (PT SIS)
- **Vendor:** INaAI (PT Teknologi Cerdas Berdaulat Indonesia), AXA Tower Lt. 45, Kuningan, Jakarta Selatan.
- **Tujuan Sistem:** Membantu percepatan pembacaan, ekstraksi, dan validasi silang faktur (invoice) terhadap dokumen pendukung (PO, Surat Jalan/Delivery Note, Goods Receipt, BAST) dari unggahan pengguna.
- **Batas Mutlak Kewenangan:** Keputusan akhir faktur dan otorisasi pembayaran **100% berada pada pengguna berwenang PT SIS**; sistem tidak pernah melakukan approval atau rejection faktur secara otomatis.
- **Sifat Repositori Saat Ini:** Paket ini murni memuat spesifikasi dokumentasi arsitektur dan skrip penguji integritas (`docs/check-docs.ps1`), tanpa kode aplikasi mentah (*application scaffold*).

---

## Urutan baca dan peta dokumen

| Urutan | Dokumen | Ringkasan Isi dan Peruntukan |
|:---:|---|---|
| **1** | [AGENTS](AGENTS.md) | Aturan mutlak kerja agent, contoh BENAR vs SALAH, alur tugas, dan Definition of Done. |
| **2** | [PRD](PRD.md) | Kebutuhan produk, batasan scope, user story standar, diagram state machine, dan model komersial. |
| **3** | [DECISIONS](DECISIONS.md) | Decision Log fakta proposal vs usulan, serta seluruh 17 Open Questions (`Q-xxx`) dengan default usulan. |
| **4** | [VALIDATION_RULES](VALIDATION_RULES.md) | **(Jantung Produk)** Katalog aturan validasi deterministik `VR-xxx`, pseudocode, formula, dan reasoning. |
| **5** | [TRACEABILITY](TRACEABILITY.md) | Matriks keterlacakan end-to-end: Tujuan Bisnis -> F -> US -> VR -> API -> DB -> TC -> A -> Task. |
| **6** | [TECH_STACK](TECH_STACK.md) | Stack teknologi, pemodelan ekonomi biaya AI per halaman vs tarif kredit, dan perintah operasional. |
| **7** | [DATA_MODEL](DATA_MODEL.md) | DDL SQL PostgreSQL lengkap, integritas foreign key, ERD Mermaid, dan strategi partisi volume tinggi. |
| **8** | [API_CONTRACT](API_CONTRACT.md) | Kontrak REST API v1, JSON Schemas, katalog kode error terpusat, dan spesifikasi OpenAPI 3.1 YAML. |
| **9** | [PROMPTS](PROMPTS.md) | Prompt AI versioned (P-001 s.d. P-004), template system + user, chunking dokumen panjang, dan 5+ test cases. |
| **10** | [UI](UI.md) | Wireframe ASCII per halaman, split-screen evidence viewer, token desain visual, dan teks UI Bahasa Indonesia. |
| **11** | [UX](UX.md) | Journey per persona, alur penanganan 5 skenario edge case, aturan prioritas antrean, dan microcopy netral. |
| **12** | [SECURITY](SECURITY.md) | Model ancaman STRIDE, matriks RBAC tabular per-endpoint, enkripsi data, dan kontrol transmisi AI. |
| **13** | [AUDIT](AUDIT.md) | Katalog event audit sistem, skema payload metadata allowlist, dan algoritma hash chain anti-tamper. |
| **14** | [OPERATIONS](OPERATIONS.md) | Prosedur deployment, runbook penutupan bulan (formula overage), penanganan insiden, dan checklist BAST. |
| **15** | [SEED](SEED.md) | Data awal sintetis, akun demo, konfigurasi rule fixture, dan katalog kasus uji bernomor `TC-xxx`. |
| **16** | [TESTING](TESTING.md) | Lapisan pengujian, uji anti-keputusan-otomatis, protokol uji beban ~500.000 hal/bln, dan merge gates. |
| **17** | [ACCEPTANCE](ACCEPTANCE.md) | Kriteria penerimaan teruji format Given/When/Then untuk verifikasi UAT dan serah terima Phase 1. |
| **18** | [IMPLEMENTATION](IMPLEMENTATION.md) | Roadmap tugas teknis implementasi (M0–M6) dengan modul rencana dan checklist Definition of Done. |
| **19** | [_AUDIT_REPORT](_AUDIT_REPORT.md) | Laporan hasil audit mendalam, temuan perbaikan, dry-run builder agent, dan evaluasi skor dokumen. |
| **20** | [_CHANGELOG](_CHANGELOG.md) | Catatan historis perbaikan dokumen yang dipetakan ke ID temuan audit. |
| **21** | [check-docs.ps1](check-docs.ps1) | Skrip penguji integritas dokumentasi otomatis berbasis PowerShell. |

---

## Panduan Menjalankan Skrip Pemeriksa
Skrip `check-docs.ps1` dapat dijalankan menggunakan PowerShell standar (Windows PowerShell 5.1) maupun PowerShell Core (`pwsh`):

```powershell
# Menggunakan Windows PowerShell bawaan:
powershell -NoProfile -ExecutionPolicy Bypass -File docs/check-docs.ps1

# Menggunakan PowerShell Core (jika terpasang):
pwsh -NoProfile -File docs/check-docs.ps1
```

---

## Glossary
Definisi istilah teknis dan operasional resmi:

| Istilah | Makna Tunggal & Baku |
|---|---|
| **Case** | Wadah (bundel) pengelompokan satu berkas invoice beserta seluruh dokumen pendukung terkaitnya untuk diverifikasi silang. Bukan transaksi pembayaran. |
| **Document** | Satu berkas fisik digital yang diunggah ke dalam Case (PDF, scan PNG/JPEG). |
| **Page** | Halaman fisik dokumen yang berhasil dihitung dan dirender oleh modul ingestion; unit dasar komersial Managed. |
| **Credit** | Satuan konsumsi komersial pada skema Managed: **1 credit = 1 halaman dokumen**. |
| **Evidence** | Rujukan visual yang memuat tautan dokumen, nomor halaman asli, dan koordinat bounding box yang membuktikan kebenaran nilai hasil ekstraksi. |
| **Exception** | Pengecualian operasional yang terdeteksi oleh aturan validasi (selisih nilai/qty, informasi belum lengkap, atau indikasi duplikasi). |
| **Validation Status** | Ringkasan teknis hasil evaluasi aturan (`MATCHED`, `NEEDS_REVIEW`, `INCOMPLETE`, `DUPLICATE_SUSPECT`). BUKAN status persetujuan pembayaran. |
| **Review Decision** | Catatan resmi peninjauan yang dicatat oleh Approver manusia (`ACCEPTED`, `REJECTED`, `NEEDS_CLARIFICATION`). Tidak mengeksekusi transfer dana. |
| **PO** | Purchase Order (Surat Pesanan Pembelian resmi yang diterbitkan PT SIS). |
| **DN** | Delivery Note (Surat Jalan pengiriman barang dari vendor). |
| **GR** | Goods Receipt (Bukti Penerimaan Barang di gudang/site tambang PT SIS). |
| **BAST Dokumen** | Berita Acara Serah Terima pekerjaan/jasa yang diterbitkan vendor pendukung invoice. |
| **BAST Phase 1** | Berita Acara Serah Terima penyelesaian implementasi proyek platform antara PT SIS dan INaAI; pemicu dimulainya masa langganan 12 bulan. |
| **Additional Usage** | Pemakaian kredit dokumen di atas kuota 50.000 kredit per bulan pada skema Managed (dikenakan tarif IDR 500 / kredit). |
| **Rule** | Aturan logika bisnis deterministik yang mengevaluasi kesesuaian data lintas-dokumen berbasis kode `Decimal`. |
| **Change Request (CR)** | Prosedur formal perubahan lingkup kerja, penambahan fitur baru, atau penambahan format dokumen di luar kontrak awal. |
| **Soft Delete** | Penandaan baris data sebagai terhapus melalui kolom `deleted_at` tanpa menghapus riwayat fisik database. |
| **INaAI Ops** | Operator teknis penyedia layanan; bertugas memantau server dan antrean job tanpa akses membaca isi data finansial. |
| **Idempotency Key** | Pengenal unik pada header mutasi API untuk mencegah eksekusi dan penagihan kredit ganda saat terjadi retry jaringan. |
| **Outbox Job** | Pola penyimpanan antrean tugas di database relasional sebelum dikirimkan ke worker broker Redis/Celery untuk menjamin durabilitas transaksi. |

---

## Batas lingkup bersama
Batas mutlak yang berlaku bagi seluruh dokumen spesifikasi:
1. Tidak ada integrasi langsung via API/database ke ERP/SAP atau modul pembayaran perbankan; input hanya melalui berkas yang diunggah pengguna.
2. Keputusan akhir faktur 100% wewenang Approver manusia PT SIS.
3. Analisis format-agnostic berbasis AI tanpa template statis per vendor.
4. Bukan sistem investigasi fraud, opini perpajakan, atau audit forensik hukum.
5. Source code aplikasi tidak diserahkan pada kedua skema deployment (Managed maupun On-Premise).
6. Seluruh contoh data, nomor faktur, dan nama vendor dalam repositori ini wajib murni sintetis.
