# Panduan Operasional, Pemeliharaan, dan Penutupan Kredit
Tujuan file ini: merinci prosedur deployment, penutupan periode kredit bulanan, runbook penanganan insiden, tata kelola Change Request, dan checklist serah terima BAST.
Dibaca oleh / kapan dipakai: tim DevOps/SRE INaAI, tim infrastruktur PT SIS, dan project manager saat persiapan go-live dan operasional rutin.

## Batas dan prasyarat
**Berdasarkan Usulan D-002/D-010/D-013.**
1. **Batas Tanggung Jawab Operasional:** Sistem ini tidak terhubung ke core banking atau gateway pembayaran; penagihan overage kredit adalah perhitungan laporan administratif yang ditagihkan secara offline melalui faktur resmi INaAI.
2. **Kepatuhan Out of Scope:** DILARANG menambahkan skrip migrasi data massal atau konektor integrasi ERP otomatis pada runbook operasional ini.
3. **Prasyarat Hak Akses:** Akses ke server produksi hanya diizinkan melalui saluran aman (VPN / SSH bastion dengan autentikasi kunci publik dan MFA).

---

## Deployment Managed
Prosedur deployment pada cloud yang disediakan dan dikelola oleh INaAI:
1. **Penyediaan Infrastruktur:** Siapkan kluster container (Kubernetes / Docker Compose), PostgreSQL 16 terkelola, Redis 7 terkelola, dan S3 object storage terisolasi.
2. **Konfigurasi Secret Produksi:** Pasang nilai secret manager (database password, JWT secret, LLM API key) pada mount volume aman `/run/secrets/*`.
3. **Inisialisasi Database:** Jalankan perintah migrasi skema `alembic upgrade head`.
4. **Deploy Service:** Deploy container `web`, `api`, dan `worker` dengan variabel `DEPLOYMENT_MODE=managed`.
5. **Smoke Test Otomatis:** Eksekusi script pengujian end-to-end sintetis untuk memverifikasi alur unggah -> ekstraksi -> validasi -> keputusan manusia -> pencatatan kredit.

---

## On-Premise
Prosedur implementasi pada infrastruktur mandiri milik PT SIS:
1. **Tanggung Jawab Infrastruktur PT SIS:** PT SIS menyediakan server fisik/virtual (32 vCPU, 64 GB RAM, 1 TB NVMe), OS Linux (RHEL/Ubuntu LTS), jaringan lokal terisolasi, dan object storage lokal MinIO.
2. **Penyediaan Paket Aplikasi:** INaAI menyerahkan paket image kontainer OCI bertanda tangan digital dan panduan instalasi. Source code DILARANG diserahkan.
3. **Aktivasi Lisensi Offline:** Pasang file lisensi kriptografis offline yang telah divalidasi tanda tangan digitalnya. Masa berlaku lisensi 12 bulan sejak sistem aktif terkonfigurasi.
4. **Konfigurasi Mode:** Atur variabel `DEPLOYMENT_MODE=onprem`. Sistem secara otomatis menonaktifkan seluruh modul penagihan kredit dan menyembunyikan menu kredit.
5. **Dukungan Pemeliharaan:** Sesuai kontrak proposal, INaAI mengalokasikan waktu dukungan pemeliharaan On-Premise sebanyak **1 hari kerja per minggu**.

---

## Environment dan readiness
Sebelum sistem dinyatakan siap melayani pengguna produksi (*Operational Readiness*), seluruh parameter konfigurasi pada [TECH_STACK](TECH_STACK.md#environment-template) WAJIB tervalidasi:
- `DEPLOYMENT_MODE` terisi `managed` atau `onprem`.
- URL database dan Redis dapat dihubungi dengan latency <= 5ms.
- Object storage bucket memiliki izin baca/tulis dan enkripsi at-rest aktif.
- Batasan unggah terpasang: `UPLOAD_MAX_BYTES=52428800` (50 MB) dan `UPLOAD_MAX_PAGES=150`.

---

## Credit metering dan penutupan bulan

### Rumus Perhitungan Tagihan Bulanan Managed:
Sesuai model komersial proposal:
- **Biaya Dasar Langganan Bulanan:** IDR 50.000.000 / bulan (termasuk kuota 50.000 kredit).
- **Tarif Pemakaian Tambahan (Overage):** IDR 500 / kredit di atas kuota 50.000.
- **Formula Tagihan Administratif:**

$$\text{Overage} = \max(0, \text{Total Kredit Terpakai} - 50.000)$$
$$\text{Biaya Tambahan} = \text{Overage} \times \text{IDR } 500$$
$$\text{Total Estimasi Tagihan} = \text{IDR } 50.000.000 + \text{Biaya Tambahan}$$

*Contoh Perhitungan:* Jika dalam 1 bulan kalender total halaman yang diproses adalah 52.000 halaman:
- Total Kredit Terpakai = 52.000 kredit.
- Overage = 52.000 - 50.000 = 2.000 kredit.
- Biaya Tambahan = 2.000 x IDR 500 = IDR 1.000.000.
- Total Tagihan = IDR 50.000.000 + IDR 1.000.000 = **IDR 51.000.000** (belum termasuk PPN 11%).
- Sisa kuota tidak rollover ke bulan berikutnya.

### Runbook Langkah-demi-Langkah Penutupan Periode Kredit (Month-Close):
Prosedur ini dijalankan otomatis oleh cron scheduler pada hari terakhir setiap bulan kalender pukul 23:59:59 UTC:
1. **Langkah 1 - Kunci Transaksi Periode:** Worker mengeksekusi row-lock `SELECT ... FOR UPDATE` pada baris periode aktif di tabel `credit_periods`.
2. **Langkah 2 - Rekonsiliasi Buku Besar:** Hitung jumlah total kredit dari `credit_ledger` untuk periode bersangkutan: `SELECT SUM(credits) FROM credit_ledger WHERE period_id = :current_period_id`.
3. **Langkah 3 - Tutup Periode Aktif:** Update status periode menjadi `CLOSED` dan simpan waktu `closed_at`.
4. **Langkah 4 - Buat Periode Baru:** Insert entri baru di `credit_periods` untuk bulan berikutnya dengan `quota = 50000`, `state = 'OPEN'`, dan `period_key = 'YYYY-MM'`.
5. **Langkah 5 - Checkpoint Integritas:** Buat rekaman audit `CREDIT_PERIOD_CLOSED` dan kirimkan ringkasan pemakaian ke email pengelola penagihan INaAI.

---

## Backup, restore dan monitoring

### Kebijakan Backup Otomatis:
- **Database PostgreSQL:** Snapshot harian penuh (Full Backup) setiap pukul 02:00 WIB + Continuous WAL Archiving setiap 15 menit ke penyimpanan terpisah terenkripsi.
- **Target RPO (Recovery Point Objective):** <= 1 jam (kehilangan data maksimal 1 jam).
- **Target RTO (Recovery Time Objective):** <= 4 jam (waktu pemulihan layanan hingga operasional normal).

### Prosedur Uji Pemulihan (Restore Drill):
Uji restore wajib dilakukan setiap 3 bulan sekali ke lingkungan terisolasi:
1. Unduh snapshot database dan berkas WAL arsip.
2. Lakukan restorasi ke instance PostgreSQL pengujian: `pg_restore -d test_restore_db snapshot.dump`.
3. Jalankan script verifikasi integritas: pastikan seluruh relasi foreign key valid, checksum SHA-256 berkas dokumen cocok dengan tabel `documents`, dan total kredit pada `credit_ledger` konsisten.

### Monitoring & Peringatan Sistem:
- Memantau metrik API p95 latency, kedalaman antrean worker Celery, sisa kapasitas storage, dan status koneksi database.
- Peringatan instan (alert) dikirimkan ke tim DevOps jika error rate HTTP 5xx > 1% dalam 5 menit atau worker queue macet > 15 menit.

---

## Runbook insiden

| Jenis Insiden | Dampak | Tindakan Penanganan Segera | Bukti Pemulihan Wajib |
|---|---|---|---|
| **API Provider LLM Timeout / Down** | Proses ekstraksi dokumen tertahan di status `PROCESSING`. | 1. Worker menahan antrean job outbox.<br>2. Lakukan retry bertahap dengan exponential backoff.<br>3. DILARANG mengalihkan ke model publik lain tanpa persetujuan Q-004. | Job berhasil diselesaikan setelah API pulih; tidak ada double charge pada kredit. |
| **Worker Celery Mengalami OOM Crash** | Job pemrosesan terhenti di tengah jalan. | 1. Celery supervisor otomatis merestart container worker.<br>2. Worker baru mendeteksi job terbengkalai berdasarkan lease timeout.<br>3. Job diproses ulang secara aman berkat `idempotency_key`. | Dokumen beralih ke status `VALIDATED`; verifikasi tidak ada duplikasi entri extractions. |
| **Berkas Rusak / Terenkripsi Diunggah** | Pemrosesan gagal membaca isi berkas. | 1. Sistem menandai dokumen `state = FAILED` dengan error `UNREADABLE_DOCUMENT`.<br>2. Status case menjadi `FAILED`.<br>3. Tampilkan pesan netral bagi Finance Staff untuk mengunggah berkas baru. | Log audit mencatat `DOCUMENT_REJECTED` dengan kode aman; tidak terjadi error 500. |

---

## Maintenance Phase 2
Cakupan layanan pemeliharaan Managed setelah serah terima BAST Phase 1 (berlaku minimum 12 bulan langganan):
1. **Preventive Maintenance:** Pemantauan berkala kesehatan server, optimasi indeks database, pembersihan temporary cache, dan verifikasi backup.
2. **Corrective Maintenance:** Perbaikan bug perangkat lunak, investigasi insiden, dan penanganan kegagalan sistem.
3. **Proactive Advisory:** Pemberian rekomendasi penyesuaian infrastruktur dan evaluasi performa kuota berkala.

*Batasan:* Maintenance Phase 2 DILARANG mencakup pengembangan fitur baru di luar spesifikasi awal.

---

## Change Request dan handover

### Alur Formal Tiket Change Request (CR):
1. **Pengajuan Kebutuhan:** PT SIS atau INaAI mengajukan formulir CR tertulis yang merinci perubahan kebutuhan bisnis atau penambahan format dokumen.
2. **Analisis Dampak & Estimasi:** INaAI melakukan evaluasi dampak terhadap timeline, biaya tambahan, dan arsitektur sistem.
3. **Persetujuan Bersama:** Penandatanganan dokumen Addendum Kontrak CR oleh pihak berwenang kedua belah pihak.
4. **Implementasi & UAT:** Fitur baru dikembangkan di branch terpisah, diuji melalui suite pengujian otomatis, dan diuji bersama tim UAT sebelum dideploy ke produksi.

### Checklist Kesiapan Go-Live & Serah Terima BAST Phase 1:
- [ ] 100% kasus uji UAT disetujui bersama oleh PT SIS dan INaAI tanpa defect Blocker/Major yang terbuka.
- [ ] Dokumen Panduan Pengguna (*User Manual*) dan Panduan Administrator (*Operations Guide*) telah diserahkan.
- [ ] Pelatihan operasional bagi Finance Staff dan Approver PT SIS telah selesai diselenggarakan dengan daftar hadir lengkap.
- [ ] Uji pemulihan data (Restore Drill) berhasil didemonstrasikan di hadapan tim IT PT SIS.
- [ ] Dokumen Berita Acara Serah Terima (BAST) Phase 1 ditandatangani oleh Project Sponsor kedua belah pihak.
