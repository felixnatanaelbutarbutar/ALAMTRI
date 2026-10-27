# Panduan Pengalaman Pengguna dan Interaksi (UX)
Tujuan file ini: merinci alur kerja end-to-end per persona, penanganan 5 skenario tepi (edge cases), aturan prioritas antrean, dan microcopy netral.
Dibaca oleh / kapan dipakai: tim UX designer, frontend developer, product manager, dan peserta UAT saat menguji alur operasional.

## Alur end-to-end
**Berdasarkan Usulan D-009.** Alur operasional platform berjalan secara berurutan dan transparan:
1. **Autentikasi Pengguna:** Pengguna masuk melalui SSO atau portal login terotorisasi; server menetapkan hak akses peran (`STAFF`, `APPROVER`, `ADMIN`, `OPS`).
2. **Pembuatan Kasus & Pengunggahan Berkas:** Finance Staff membuat `Case` baru, memilih berkas faktur beserta dokumen pendukung (PO, Surat Jalan, GR, BAST), dan sistem memvalidasi integritas file (MIME, ukuran, malware).
3. **Pemrosesan Asinkron:** Pipeline worker menghitung total halaman dokumen fisik, mengekstrak data kunci melalui AI, dan mengeksekusi aturan validasi deterministik (VR-001 s.d. VR-009).
4. **Peninjauan Antrean & Investigasi Pengecualian:** Staf dan Approver meninjau ringkasan hasil validasi. Kasus dengan selisih dibuka pada antarmuka split-viewer untuk memeriksa bukti fisik dokumen sumber.
5. **Pencatatan Keputusan Manusia:** Approver manusia menelaah temuan, mengisi catatan keputusan resmi (`ACCEPTED`, `REJECTED`, atau `NEEDS_CLARIFICATION`), dan menyimpannya ke dalam database immutable.
6. **Ekspor & Rekonsiliasi:** Staf mengekspor snapshot data terverifikasi ke spreadsheet (CSV/XLSX) untuk keperluan pelaporan internal.

DILARANG terdapat langkah eksekusi transfer dana atau integrasi approval pembayaran otomatis pada seluruh alur di atas.

---

## Journey per persona

### 1. Finance Staff (Unggah, Verifikasi, & Eskalasi)
- **Tujuan:** Memastikan seluruh faktur yang diterima dari vendor telah lengkap dokumen pendukungnya dan selisih data teridentifikasi jelas.
- **Jalur Interaksi:**
  - Buka `/cases/new` -> Drag-and-drop berkas bundel faktur -> Klik "Mulai Proses".
  - Pantau progress bar pemrosesan di `/cases`.
  - Jika muncul status `NEEDS_REVIEW` atau `INCOMPLETE`, klik nomor kasus untuk membuka viewer dua panel.
  - Periksa kotak highlight pada gambar dokumen asli -> Berikan catatan internal pada pengecualian jika ada klarifikasi dari vendor.
  - Buka `/exports` untuk mengunduh rekap faktur harian.

### 2. Approver PT SIS (Tinjauan Akhir & Otorisasi Catatan)
- **Tujuan:** Menjalankan tata kelola penelaahan faktur secara akuntabel sebelum proses pembayaran manual di sistem ERP internal PT SIS.
- **Jalur Interaksi:**
  - Masuk ke dashboard -> Buka tab filter `Status Validasi = PERLU REVIEW` atau `COCOK`.
  - Buka detail kasus -> Periksa rujukan evidence antara invoice vs PO/GR.
  - Pada panel form keputusan manusia, pilih opsi keputusan: `Diterima (Catatan Pengguna)`, `Ditolak (Catatan Pengguna)`, atau `Perlu Klarifikasi`.
  - Tuliskan alasan pertimbangan pada kolom catatan wajib -> Klik "Simpan Catatan Keputusan".

### 3. Admin PT SIS (Konfigurasi & Pengawasan Biaya)
- **Tujuan:** Mengelola akun pengguna internal, memantau konsumsi kredit kuota Managed, dan menyesuaikan batas toleransi aturan validasi.
- **Jalur Interaksi:**
  - Buka `/credits` untuk melihat grafik pemakaian kuota bulanan dan riwayat overage.
  - Buka `/admin/rules` jika ada kebijakan penyesuaian toleransi selisih nilai transaksi.
  - Buka `/admin/audit` untuk menelusuri aktivitas pengguna jika diperlukan audit kepatuhan internal.

### 4. INaAI Ops (Keandalan Layanan & Dukungan Teknis)
- **Tujuan:** Memastikan infrastruktur server, antrean worker, dan adapter model AI beroperasi sehat tanpa interupsi.
- **Jalur Interaksi:**
  - Buka `/ops` untuk memantau metrik latensi, kegagalan antrean, dan status service.
  - Jika ada job yang mengalami timeout jaringan, picu aksi "Retry Teknis" melalui dashboard tersanitasi (tanpa melihat isi berkas faktur).

---

## Penanganan 5 skenario tepi (edge cases)

### Skenario 1: Dokumen Hasil Pindai Buram atau Teks Kabur (Low Quality Scan)
- **Kondisi:** Vendor mengunggah foto faktur beresolusi rendah atau miring di mana nomor faktur atau angka nominal tidak terbaca jelas.
- **Respons Sistem:**
  - AI extraction menandai flag `quality_flags: ["UNREADABLE"]` dan mengisi field terkait dengan nilai `null`.
  - Rule `VR-009` menghasilkan status `INCOMPLETE` dengan reason code `LOW_EXTRACTION_QUALITY`.
  - Status agregasi case menjadi `INCOMPLETE`.
  - Antarmuka menampilkan pesan netral: *"Sebagian informasi penting tidak terbaca jelas pada berkas sumber. Periksa dokumen asli atau minta vendor mengunggah berkas dengan resolusi lebih baik."*

### Skenario 2: Dokumen Pendukung Tidak Lengkap (Missing PO / GR / BAST)
- **Kondisi:** Faktur tagihan jasa alat berat diunggah tanpa melampirkan berkas fisik BAST atau nomor PO tidak tercantum pada faktur.
- **Respons Sistem:**
  - Rule `VR-004` atau `VR-005` menghasilkan status `INCOMPLETE` dengan kode `BAST_DOCUMENT_MISSING`.
  - Pada panel kanan split-viewer, baris aturan menampilkan tombol penanda *"Berkas BAST Belum Terlampir"*.
  - Sistem mengizinkan Finance Staff untuk mengunggah berkas susulan ke dalam case yang sama tanpa menghapus data yang telah diproses.

### Skenario 3: Indikasi Potensi Duplikasi Berkas Faktur (Duplicate Suspect)
- **Kondisi:** Vendor mengunggah kembali faktur yang nomor, tanggal, nama vendor, dan total nilainya identik dengan faktur yang sudah diproses 2 minggu lalu.
- **Respons Sistem:**
  - Rule `VR-008` mendeteksi kesamaan parameter kunci dan menghasilkan outcome `FAIL` dengan kode `BUSINESS_FIELDS_DUPLICATE_SUSPECT`.
  - Status agregasi case menjadi `DUPLICATE_SUSPECT`.
  - Sistem DILARANG menolak atau menghapus berkas secara otomatis. Kasus tetap disimpan utuh.
  - Antarmuka menampilkan kartu perbandingan dua kasus berdampingan: *"Faktur ini memiliki identitas identik dengan Kasus #CAS-2026-0812 (Diunggah 12 Okt 2026). Periksa kedua dokumen untuk mencegah pencatatan ganda."*

### Skenario 4: Kuota Kredit Bulanan Terlewati (Quota Exceeded / Overage)
- **Kondisi:** Pada skema Managed, total halaman dokumen yang diproses mencapai 50.005 halaman pada tanggal 25 dalam bulan berjalan.
- **Respons Sistem:**
  - Sistem membuat notifikasi in-app kategori `QUOTA_EXCEEDED` untuk pengguna peran Admin.
  - Pemrosesan berkas baru **TIDAK DIHENTIKAN SAMA SEKALI**. Seluruh proses unggah dan validasi tetap berjalan lancar tanpa hambatan.
  - Halaman `/credits` menampilkan rincian overage transparan: Kuota dasar: 50.000, Terpakai: 50.005, Pemakaian Tambahan: 5 kredit (Estimasi Biaya Tambahan: IDR 2.500).

### Skenario 5: Kegagalan Worker atau Timeout Model AI (Processing Failure)
- **Kondisi:** Worker Celery mengalami crash kehabisan memori atau API model LLM mengalami timeout jaringan saat memproses dokumen 100 halaman.
- **Respons Sistem:**
  - Sistem mendeteksi heartbeat job kedaluwarsa via tabel `processing_jobs`.
  - Worker melakukan retry otomatis maksimal 2 kali dengan exponential backoff.
  - Jika tetap gagal, status job dan dokumen diubah menjadi `FAILED` dengan kode `PROCESSING_TIMEOUT`.
  - Data yang telah berhasil diekstraksi sebagian tidak hilang. Pengguna disajikan tombol interaktif *"Proses Ulang Dokumen"* yang aman dari penagihan kredit ganda.

---

## Prioritas antrean

Antrean Pengecualian (`/exceptions`) dan Kasus (`/cases`) diurutkan secara deterministik menggunakan aturan prioritas berjenjang berikut:

1. **Tingkat 1 - Tingkat Keparahan (Severity):**
   - Kasus dengan severity `ERROR` (selisih nilai/qty melebihi toleransi, duplikasi) didahulukan paling atas.
   - Diikuti oleh severity `WARN` (dokumen pendukung belum lengkap / `INCOMPLETE`).
   - Terakhir severity `INFO` (selisih pembulatan kecil dalam batas toleransi).
2. **Tingkat 2 - Usia Antrean (FIFO - First In First Out):**
   - Dokumen yang diunggah lebih awal (`created_at ASC`) diprioritaskan untuk mencegah pelanggaran Service Level Agreement (SLA) pembayaran ke vendor.
3. **Tingkat 3 - Nominal Selisih Transaksi (Tie-Breaker):**
   - Jika keparahan dan tanggal sama, kasus dengan nilai selisih nominal absolut terbesar (`abs(difference) DESC`) ditempatkan lebih atas.
4. **Tingkat 4 - Konsistensi ID:** UUID `id ASC` sebagai penentu urutan akhir yang stabil.

---

## Microcopy dan notifikasi

### Standar Bahasa & Larangan Terminologi Negatif
Dalam rangka menjaga netralitas dan objektivitas operasional, sistem **DILARANG KERAS MENGGUNAKAN KATA-KATA BERIKUT** pada seluruh UI, pesan error, reasoning, maupun notifikasi:
- ❌ **DILARANG:** *"fraud"*, *"penipuan"*, *"kecurangan"*, *"manipulasi"*.
- ❌ **DILARANG:** *"layak bayar"*, *"disetujui otomatis"*, *"lulus pembayaran"*.
- ❌ **DILARANG:** *"ditolak otomatis"*, *"faktur ilegal"*, *"tagihan palsu"*.

### Kamus Microcopy Terstandar (Bahasa Indonesia):
| Status / Situasi | Teks Pesan Antarmuka Baku |
|---|---|
| **Kesesuaian Sempurna (MATCHED)** | *"Tidak ditemukan perbedaan data pada seluruh kriteria pemeriksaan yang dijalankan. Tetap memerlukan peninjauan dan keputusan pengguna berwenang PT SIS."* |
| **Ditemukan Selisih (NEEDS_REVIEW)**| *"Ditemukan perbedaan data antara faktur dan dokumen pemesanan/penerimaan. Silakan periksa rincian nilai dan dokumen sumber terkait."* |
| **Data Belum Lengkap (INCOMPLETE)**| *"Informasi belum lengkap atau berkas pendukung belum terlampir. Silakan lengkapi berkas untuk melanjutkan evaluasi."* |
| **Potensi Duplikasi (DUPLICATE_SUSPECT)** | *"Terdeteksi kemiripan identitas dengan faktur lain dalam sistem. Silakan lakukan verifikasi silang kedua dokumen."* |
| **Mendekati Batas Kuota (NEAR_QUOTA)**| *"Pemakaian kredit telah mencapai {percentage}% dari kuota periode ini. Pemrosesan dokumen tetap berjalan normal."* |
| **Melampaui Kuota (QUOTA_EXCEEDED)**| *"Pemakaian kredit telah melampaui kuota bulanan ({overage} kredit di atas kuota). Pemrosesan dokumen tetap berjalan lancar dengan tarif pemakaian tambahan IDR 500 / kredit."* |
| **Catatan Keputusan Tersimpan** | *"Catatan keputusan peninjauan pengguna berhasil disimpan secara permanen untuk versi pemeriksaan ini."* |

---

## Recovery dan aksesibilitas

1. **Pemulihan Sesi Kerja (Session Resilience):**
   - Jika koneksi internet pengguna terputus saat mengunggah berkas besar, antarmuka menyimpan checkpoint berkas yang sudah berhasil diterima sehingga pengguna hanya perlu mengunggah ulang berkas yang terputus tanpa mengulang dari awal.
   - Jika sesi login kedaluwarsa saat Approver sedang mengetik catatan keputusan, antarmuka menyimpan draf teks di memory komponen dan memunculkan modal login popup tanpa me-refresh halaman utama, sehingga catatan tidak hilang.
2. **Kepatuhan Aksesibilitas Lengkap:**
   - **Navigasi Keyboard Penuh:** Seluruh menu, baris tabel, tombol zoom viewer, dan form keputusan dapat dioperasikan penuh menggunakan tombol `Tab`, `Enter`, `Space`, dan panah arah.
   - **Screen Reader Support:** Setiap tombol ikon memiliki atribut `aria-label` deskriptif (misal: `aria-label="Perbesar tampilan dokumen halaman 1"`).
   - **Tampilan Zoom 200%:** Desain antarmuka responsif dan tidak mengalami tumpang tindih teks atau kehilangan tombol aksi ketika browser diperbesar hingga skala zoom 200%.
