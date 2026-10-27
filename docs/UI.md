# Spesifikasi Desain Antarmuka Pengguna (UI)
Tujuan file ini: menetapkan tata letak visual, wireframe ASCII per halaman, komponen split-viewer, token desain, dan teks persis Bahasa Indonesia.
Dibaca oleh / kapan dipakai: tim frontend engineer, perancang UI/UX, dan QA visual saat mengimplementasikan Milestone M3.

## Prinsip dan design tokens
**Berdasarkan Usulan D-009.**
1. **Bahasa Antarmuka:** Seluruh label, tombol, pesan validasi, dan notifikasi menggunakan **Bahasa Indonesia** formal dan profesional. Kode program, nama field, dan endpoint tetap menggunakan English.
2. **Banner Pengingat Tata Kelola Wajib:** Pada setiap halaman detail faktur (`/cases/:id`), sistem WAJIB menampilkan banner informatif di bagian atas:
   > *"Hasil pemeriksaan sistem membantu peninjauan kesesuaian data. Keputusan akhir dan otorisasi pembayaran sepenuhnya wewenang pengguna berwenang PT SIS."*
3. **Pemisahan Visual Status Sistem vs Keputusan Manusia:** Badge status sistem (`MATCHED`, `NEEDS_REVIEW`, `INCOMPLETE`, `DUPLICATE_SUSPECT`) menggunakan komponen visual terpisah dari badge catatan keputusan manusia (`ACCEPTED`, `REJECTED`, `NEEDS_CLARIFICATION`). DILARANG membuat tombol "Setujui Otomatis" atau "Bayar".
4. **Kepatuhan Aksesibilitas WCAG 2.2 AA:** Kontras rasio teks terhadap latar belakang minimal 4.5:1 untuk teks biasa dan 3:1 untuk teks besar/badge. Seluruh aksi memiliki fokus visual dan dapat dinavigasi menggunakan keyboard.

### Tabel Design Tokens:
| Token Desain | Nilai Kode (Hex / Tailwind) | Peruntukan & Keterangan |
|---|---|---|
| `color-bg-canvas` | `#F8FAFC` (`slate-50`) | Latar belakang utama dashboard |
| `color-bg-surface` | `#FFFFFF` (`white`) | Permukaan kartu, tabel, dan panel viewer |
| `color-text-main` | `#0F172A` (`slate-900`) | Teks utama, judul, dan angka transaksi |
| `color-text-muted` | `#475569` (`slate-600`) | Label keterangan dan teks bantuan |
| `color-border` | `#CBD5E1` (`slate-300`) | Garis pembatas komponen dan input field |
| `color-primary` | `#1D4ED8` (`blue-700`) | Tombol aksi utama, tab aktif, dan fokus ring |
| `badge-matched` | Bg: `#DCFCE7`, Teks: `#15803D` (`green-700`) | Status validasi: Seluruh aturan cocok |
| `badge-needs-review` | Bg: `#FEF9C3`, Teks: `#A16207` (`yellow-700`)| Status validasi: Ditemukan selisih data |
| `badge-incomplete` | Bg: `#F1F5F9`, Teks: `#475569` (`slate-600`) | Status validasi: Data/dokumen belum lengkap |
| `badge-duplicate` | Bg: `#FEE2E2`, Teks: `#B91C1C` (`red-700`) | Status validasi: Terindikasi potensi duplikasi |
| `font-family` | Inter, system-ui, sans-serif | Tipografi modern yang mudah dibaca |
| `min-touch-target` | `44px` x `44px` | Target interaksi klik/sentuh tombol |

---

## Halaman dan tabel

### 1. Halaman Ringkasan & Antrean Kasus (`/cases`)
- **Akses Peran:** STAFF, APPROVER.
- **Wireframe ASCII:**
```text
+----------------------------------------------------------------------------------------------------+
|  [LOGO INaAI / PT SIS]  Dashboard    Kasus Faktur    Pengecualian    Ekspor    Kredit (Admin)   [User] |
+----------------------------------------------------------------------------------------------------+
| Kasus Faktur                                                           [+ Unggah Bundel Faktur Baru] |
|                                                                                                    |
| Filter: [Status Validasi: Semua v] [Status Proses: Semua v] [Cari Vendor / No Faktur: ________]    |
|----------------------------------------------------------------------------------------------------|
| No. Kasus     | Vendor                | Tgl Unggah | Hal | Status Proses | Status Validasi | Aksi    |
|---------------|-----------------------|------------|-----|---------------|-----------------|---------|
| CAS-2026-0001 | PT UNITED TRACTORS    | 27/10/2026 |  4  | SELESAI       | [PERLU REVIEW]  | [Buka]  |
| CAS-2026-0002 | PT TRAKTOR NUSANTARA  | 27/10/2026 |  2  | MEMPROSES     | [MEMPROSES]     | [Buka]  |
| CAS-2026-0003 | PT HEXINDO ADIPERKASA | 26/10/2026 |  6  | SELESAI       | [COCOK]         | [Buka]  |
| CAS-2026-0004 | CV MAKMUR JAYA        | 26/10/2026 |  1  | GAGAL         | [TIDAK LENGKAP] | [Buka]  |
|----------------------------------------------------------------------------------------------------|
| Menampilkan 1-10 dari 45 kasus                                          Halaman: [<] 1 [2] [3] [>] |
+----------------------------------------------------------------------------------------------------+
```

### 2. Halaman Antrean Pengecualian (`/exceptions`)
- **Akses Peran:** STAFF, APPROVER.
- **Kolom Tabel:** `Tingkat Keparahan (ERROR/WARN/INFO)`, `Tipe (MISMATCH/DUPLICATE/MISSING)`, `No. Kasus`, `Aturan Terlanggar`, `Ringkasan Selisih`, `Umur Antrean`, `Status (OPEN/IN_REVIEW/RESOLVED)`, `Aksi (Lihat Bukti)`.

### 3. Halaman Pemantauan Kredit Managed (`/credits`)
- **Akses Peran:** ADMIN (Pada deployment On-Premise, tautan menu ini disembunyikan otomatis).
- **Wireframe ASCII:**
```text
+----------------------------------------------------------------------------------------------------+
| Pemantauan Pemakaian Kredit (Managed Subscription)                                                 |
| Periode Aktif: Oktober 2026 (01/10/2026 - 31/10/2026)                                               |
|----------------------------------------------------------------------------------------------------|
| [ TOTAL KUOTA BULANAN ]      [ TOTAL KREDIT TERPAKAI ]      [ SISA KUOTA KREDIT ]      [ ESTIMASI BIAYA ]   |
|      50.000 Kredit                 42.500 Kredit                 7.500 Kredit           IDR 50.000.000     |
| (1 Kredit = 1 Halaman)           (85% Terpakai)              (Tambahan: IDR 0)        (Belum Termasuk PPN) |
|----------------------------------------------------------------------------------------------------|
| Progress Kuota: [==================================================>          ] 85%                |
|                                                                                                    |
| Riwayat Pemotongan Kredit Terakhir:                                                                |
| Waktu (WIB)         | No. Kasus     | Dokumen           | Halaman | Kredit Terpotong | ID Event    |
|---------------------|---------------|-------------------|---------|------------------|-------------|
| 27/10/2026 14:32:01 | CAS-2026-0001 | Invoice_Final.pdf |    2    |     2 Kredit     | EVT-9812401 |
| 27/10/2026 14:32:01 | CAS-2026-0001 | PO_Signed.pdf     |    2    |     2 Kredit     | EVT-9812402 |
+----------------------------------------------------------------------------------------------------+
```

---

## Viewer dan evidence

Halaman Detail Kasus (`/cases/:id`) dirancang dengan antarmuka **Split-Screen Dua Panel** interaktif:

```text
+----------------------------------------------------------------------------------------------------+
| [Kembali ke Daftar]  Kasus #CAS-2026-0001   Status: [SELESAI]   Hasil Validasi: [PERLU REVIEW]     |
| [!] Hasil pemeriksaan membantu peninjauan. Keputusan akhir dan otorisasi pembayaran berada pada    |
|     pengguna berwenang PT SIS.                                                                     |
+------------------------------------------------------------------+---------------------------------+
| PANEL KIRI: Dokumen Asli (PDF/Scan Viewer)                       | PANEL KANAN: Hasil & Validasi   |
| [Invoice_UT.pdf v] [Hal: 1 / 4]  [Zoom - / +]  [Rotasi]          | [Tab: Validasi] [Tab: Dokumen]  |
|------------------------------------------------------------------|---------------------------------|
| +--------------------------------------------------------------+ | ATURAN VALIDASI (2 Selisih):    |
| | PT UNITED TRACTORS TBK                    INVOICE            | |                                 |
| | Jl. Raya Bekasi Km 22, Jakarta                               | | [!] VR-001: Total Nilai       |
| |                                                              | | Status: GAGAL (Beda 10 jt)    |
| | Nomor Faktur: INV/2026/10/0912          Tanggal: 25/10/2026  | | Invoice: IDR 110.000.000      |
| | No. PO      : PO-SIS-2026-4401                               | | PO     : IDR 100.000.000      |
| |                                                              | | [Lihat Bukti Hal. 1] (Klik)   |
| | Rincian Barang:                                              | |                                 |
| | 1. Hydraulic Filter PC2000 ... Qty: 10 ... IDR 100.000.000   | | [OK] VR-003: Kuantitas GR     |
| |                                                              | | Status: COCOK (10 EA = 10 EA) |
| | +----------------------------------------------------------+ | |                                 |
| | | Subtotal  : IDR 100.000.000                              | | |---------------------------------|
| | | PPN 11%   : IDR  11.000.000  << [KOTAK HIGHLIGHT EVIDENCE] | | CATATAN KEPUTUSAN REVIEW:     |
| | | TOTAL     : IDR 110.000.000                              | | (Hanya Approver Berwenang)    |
| | +----------------------------------------------------------+ | | Keputusan:                    |
| +--------------------------------------------------------------+ | (o) Diterima (Catatan Pengguna) |
|                                                                  | ( ) Ditolak (Catatan Pengguna)  |
| [Navigasi Halaman]: [< Sebelumnya] [1] [2] [3] [4] [Berikutnya >]| ( ) Perlu Klarifikasi           |
|                                                                  | Catatan Wajib:                  |
|                                                                  | [Selisih 10 jt biaya kirim ... ]|
|                                                                  | [ SIMPAN CATATAN KEPUTUSAN ]    |
+------------------------------------------------------------------+---------------------------------+
```

### Mekanisme Interaksi Evidence:
1. Ketika pengguna mengklik tombol link `[Lihat Bukti Hal. N]` pada baris aturan validasi di panel kanan, panel kiri otomatis berpindah ke halaman dokumen terkait (`page_number`) dan menggambar kotak sorotan berwarna (`bbox highlight overlay`).
2. Jika suatu field berstatus `null` (data tidak ditemukan pada dokumen asli), panel kanan menampilkan label netral: *"Sumber tidak tersedia pada dokumen"* tanpa menciptakan tautan palsu.
3. Form keputusan manusia di panel kanan bawah hanya aktif jika pengguna memiliki peran `APPROVER`. Kolom catatan (`note`) wajib diisi minimal 5 karakter sebelum tombol submit aktif.

---

## State wajib

Setiap komponen dan halaman web WAJIB menangani kondisi antarmuka berikut dengan elegan:

| Kondisi (State) | Tampilan Komponen & Perilaku Antarmuka | Microcopy / Teks Persis Bahasa Indonesia |
|---|---|---|
| **Loading** | Menampilkan animasi skeleton placeholder pada tabel dan viewer; atribut `aria-busy="true"` aktif. | *"Memuat data dokumen..."* |
| **Empty Table** | Menampilkan ilustrasi folder kosong dengan tombol aksi panduan. | *"Belum ada kasus faktur yang diproses. Unggah bundel dokumen baru untuk memulai."* |
| **Partial Upload** | Menampilkan daftar berkas dengan status individual; tombol retry tersedia khusus untuk berkas yang gagal. | *"3 dari 4 berkas berhasil diunggah. 1 berkas gagal diverifikasi."* |
| **Error Network** | Menampilkan kartu peringatan merah dengan ID pelacakan request. | *"Gagal terhubung ke server. Silakan coba kembali atau hubungi dukungan dengan menyertakan ID: {request_id}"* |
| **Stale Version** | Menonaktifkan form submit dan menampilkan baris peringatan kuning jika hasil validasi telah diperbarui run lain. | *"Hasil validasi telah diperbarui oleh proses terbaru. Silakan muat ulang halaman sebelum mencatat keputusan."* |
| **Quota Exhausted** | Banner peringatan informatif berwarna kuning di bagian atas dashboard (Managed). Proses unggah dan validasi **tetap berfungsi normal**. | *"Kuota 50.000 kredit bulanan telah tercapai. Pemrosesan dokumen tetap berjalan normal dengan biaya pemakaian tambahan IDR 500 / kredit."* |
| **Feature Disabled**| Pada deployment On-Premise, menu pemantauan kredit dihilangkan; jika user membuka URL langsung, tampilkan: | *"Fitur pemantauan kredit dinonaktifkan pada skema On-Premise."* |
