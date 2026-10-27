# Product Requirements
Tujuan file ini: menetapkan produk, kebutuhan pengguna dan batas bisnis.
Dibaca oleh / kapan dipakai: agent implementasi dan peserta Discovery/UAT sebelum menetapkan fitur.

## Masalah dan tujuan
PT SIS menerima invoice dan PO, DN, GR, BAST dari beragam vendor. Ilustrasi proposal: sekitar 5.000 invoice/bulan × 100 halaman/bundel = sekitar 500.000 halaman/bulan; pemeriksaan manual memerlukan 12–13 personel dengan 20 hari kerja dan 8 jam/hari. Ini ilustrasi beban, bukan kapasitas terjamin atau komitmen penggunaan. Volume tersebut berbeda dari kuota Managed 50.000 credit.

Tujuan: Reduce Invoice Processing Cost melalui biaya terukur dan pengurangan pekerjaan berulang; Increase Scalability and Processing Speed tanpa pertumbuhan SDM sebanding. Pendekatan: adaptive document understanding, policy-driven cross-document validation, transparent reasoning dengan human control. Kualitas hasil bergantung sumber; tanpa template vendor. Sistem tidak membuat keputusan akhir, tidak mengotorisasi pembayaran, dan tidak mengklaim fraud/pajak/hukum.

## Persona dan akses usulan
| Peran | Tanggung jawab | Batas |
|---|---|---|
| Finance Staff (STAFF) | Upload, monitoring, membaca evidence, exception, ekspor | Tidak mencatat keputusan final |
| Approver (APPROVER) | Akses Finance dan mencatat keputusan manusia | Tidak mengeksekusi pembayaran |
| Admin (ADMIN) | Kelola user, parameter existing, credit dan audit | Bukan Approver secara otomatis |
| INaAI Ops (OPS) | Health, job recovery, maintenance | Tidak membaca dokumen/nilai finansial atau memutuskan invoice secara default |
Assignment dan akses per case belum final, lihat [Q-008 dan Q-015](DECISIONS.md#open-questions). Role adalah single role pada usulan awal; perubahan multi-role menunggu Q-015.

## Fitur dan user stories
| Fitur | Story | Kebutuhan dan acceptance ringkas | AC |
|---|---|---|---|
| F1 Upload & Monitoring | US-UPLOAD-01 | Staff membuat Case dan mengunggah PDF/scan/digital; halaman dihitung, file invalid ditolak aman | [A1, A3](ACCEPTANCE.md#upload-dan-pemrosesan) |
| F1 | US-MONITOR-01 | Staff memantau tahap/failure/retry tanpa unggah ulang wajib | [A2](ACCEPTANCE.md#upload-dan-pemrosesan) |
| F2 Capture & Structure | US-EXTRACT-01 | Field vendor, nomor/referensi/tanggal, item/qty/harga/pajak/total tersimpan; null bila tidak terbaca; evidence tersedia | [B1–B4](ACCEPTANCE.md#ekstraksi) |
| F3 Multi-Document Validation | US-VALIDATE-01 | Rule terpusat memeriksa invoice terhadap PO/DN/GR/BAST sesuai kebijakan; selisih/duplikasi/incomplete disertai evidence | [C1–C5](ACCEPTANCE.md#validasi) |
| F4 Exception Review | US-REVIEW-01 | Pengguna membuka exception dan sumber halaman; hanya Approver mencatat keputusan, tidak pernah AI | [D1–D3, E1](ACCEPTANCE.md#human-control) |
| F5 Export | US-EXPORT-01 | Finance mengekspor snapshot terstruktur dalam format disepakati; cocok dengan DB dan hak akses | [E2](ACCEPTANCE.md#dashboard-dan-ekspor) |
| F6 Credit Usage | US-CREDIT-01 | Admin melihat pemakaian/riwayat/overage dan notifikasi tanpa penghentian; On-Premise nonaktif | [F1–F4](ACCEPTANCE.md#credit) |
| Pendukung F1–F6 | US-ADMIN-01 | Admin mengelola user dan parameter rule existing dengan audit dan versioning | [I1](ACCEPTANCE.md#keamanan-dan-administrasi) |
| Pendukung F1–F6 | US-OPS-01 | Ops memulihkan layanan, memverifikasi backup/restore dan memonitor tanpa isi dokumen | [G1–G3, I2](ACCEPTANCE.md#kinerja-dan-keandalan) |
| Prepare for Operational Use | US-HANDOVER-01 | Peserta UAT menerima penyempurnaan dalam scope, dokumentasi, pelatihan, deployment dan BAST Phase 1 | [H1–H3](ACCEPTANCE.md#serah-terima) |

## Status dan aturan perilaku
Tiga dimensi terpisah (Usulan D-009):
- Processing: `UPLOADED -> PROCESSING -> EXTRACTED -> VALIDATED`; tahap aktif boleh menuju `FAILED`. Retry membuat processing attempt baru; run lama immutable. Case draft tanpa file tetap UPLOADED dengan total_pages=0.
- Validation: null sebelum run selesai; `MATCHED`, `NEEDS_REVIEW`, `INCOMPLETE`, `DUPLICATE_SUSPECT`. Ringkasan usulan precedence: INCOMPLETE > DUPLICATE_SUSPECT > NEEDS_REVIEW > MATCHED; semua temuan tetap terlihat. Rule belum disepakati/nonaktif tidak boleh menghasilkan MATCHED; keluarkan INCOMPLETE dengan coverage yang belum tersedia (Q-001).
- Human decision: `ACCEPTED`, `REJECTED`, `NEEDS_CLARIFICATION` sebagai catatan manusia (Q-015), tidak mengubah hasil validasi. Setelah run baru, keputusan lama ditandai terkait run lama, tidak diwariskan otomatis.
Rule PASS/FAIL/INCOMPLETE/SKIPPED adalah hasil teknis, bukan penolakan invoice. Missing evidence menahan hasil sebagai INCOMPLETE. Failure teknis tidak disamakan dengan ketidaksesuaian bisnis.

## In scope
Design Business Process & Validation Framework (mapping, kriteria validasi dan acceptance bersama PT SIS); capture/structure/validate dokumen yang disepakati; reasoning dan exception; Finance Operations Dashboard; UAT/refinement/deployment/dokumentasi/pelatihan; operasi sesuai skema. Parameter rule boleh disesuaikan terkendali; logic baru lewat CR.

## Out of scope
1. Sistem mengambil keputusan akhir invoice atau otorisasi pembayaran. Catatan keputusan manusia tetap in scope.
2. Penyiapan, perbaikan kualitas, digitalisasi dokumen sumber dan migrasi historis massal di luar sampel.
3. Konektivitas langsung ERP, sistem internal atau pembayaran; input hanya unggahan.
4. Procure-to-pay end-to-end: membuat/approve PO, mencatat penerimaan barang/jasa, manajemen vendor, posting ERP, pencairan/pembayaran.
5. Fraud, tax, regulatory assessment, audit investigatif, pendapat pajak/hukum atau kesimpulan kepatuhan. Membandingkan angka pajak dokumen tidak menilai kepatuhan pajak.
6. Penyerahan source code pada kedua skema, termasuk On-Premise.
7. Pengadaan hardware/software pendukung; tanggung jawab PT SIS pada On-Premise.
8. Managed maintenance tidak mencakup fitur baru, jenis dokumen baru atau perubahan di luar scope; wajib CR.
Batas ini normatif untuk seluruh dokumen melalui [README](README.md#batas-lingkup-bersama).

## Model komersial
| Aspek | Managed Subscription Service | On-Premise Licensed Deployment |
|---|---|---|
| Infrastruktur | Cloud disediakan/dikelola INaAI | Disediakan/dikelola PT SIS |
| Project Fee | IDR 500.000.000 | IDR 1.500.000.000 |
| Berulang | IDR 50.000.000/bulan; server, infra, AI credits, maintenance support | IDR 500.000.000/tahun; lisensi, support, maintenance |
| Pemrosesan | 50.000 credit/bulan; 1 credit = 1 halaman; tambahan IDR 500/credit | Sesuai kapasitas infrastruktur; tanpa credit/Additional Usage |
| Tahun pertama | IDR 1.100.000.000 | IDR 2.000.000.000 |
| Masa | Minimum 12 bulan sejak BAST Phase 1 | 12 bulan sejak aplikasi terkonfigurasi dan lisensi aktif |
| Credit Monitoring | Aktif | Tidak berlaku |
Managed: kuota dibayar penuh terlepas pemakaian, tidak rollover; tagihan bulanan = IDR 50.000.000 + Additional Usage × IDR 500. Tahun pertama Managed di atas adalah nilai dasar proposal, belum overage. Semua nilai belum PPN dan Out-of-Pocket (reimbursement realisasi). Phase 1: 50% saat kick-off, 50% setelah BAST Phase 1. Maintenance On-Premise: alokasi 1 hari kerja/minggu. Platform hanya memonitor estimasi credit, tidak memproses pembayaran tagihan. Semantik billable Q-011, siklus Q-012.

## Timeline
| Skema | Minggu | Aktivitas |
|---|---|---|
| Managed | 1–2 | Discovery & Solution Design |
| Managed | 3–8 | Engine & Dashboard Development |
| Managed | 9–10 | UAT |
| Managed | 11–12 | Operational Adoption & Go-Live, BAST Phase 1 |
| On-Premise | 1–4 | Infrastructure Understanding & Readiness Planning |
| On-Premise | 5–6 | Discovery & Solution Design |
| On-Premise | 7–10 | Engine & Dashboard Development |
| On-Premise | 11–12 | Infrastructure Preparation & System Initialization |
| On-Premise | 13–14 | UAT |
| On-Premise | 15–16 | Operational Adoption & Go-Live |
On-Premise memerlukan tambahan 2–3 bulan pengadaan infrastruktur; jangan menjanjikan selesai dalam 16 minggu kalender termasuk pengadaan.

## Asumsi dan metrik sukses
Usulan: satu Case untuk satu invoice, multi dokumen terkait; file campuran Q-006. Bahasa, mata uang, toleransi, dokumen wajib dan kapasitas bukan asumsi terselesaikan (Q-001/002/007/009/010). Ukur baseline biaya manual dan waktu review lalu bandingkan setelah UAT; target penghematan [TBD] Q-009. Field accuracy, fault recall, false-positive, latency, throughput dan biaya LLM/halaman ditetapkan di [TESTING](TESTING.md), seluruh target [TBD] sampai disepakati. Kriteria verifikasi ada di [ACCEPTANCE](ACCEPTANCE.md); urutan build di [IMPLEMENTATION](IMPLEMENTATION.md).
