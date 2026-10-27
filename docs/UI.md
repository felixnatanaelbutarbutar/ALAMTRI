# Spesifikasi UI
Tujuan file ini: menetapkan layout, komponen, state dan bahasa dashboard.
Dibaca oleh / kapan dipakai: agent frontend/desainer dan reviewer UAT sebelum M3.

## Prinsip dan design tokens
**Usulan D-009.** UI Bahasa Indonesia, kode English. Banner detail: “Hasil pemeriksaan membantu peninjauan. Keputusan akhir dan otorisasi pembayaran berada pada pengguna berwenang PT SIS.” Sistem tidak membuat keputusan akhir dan tidak mengklaim fraud/pajak/hukum. Tidak ada tombol “Setujui otomatis” atau “Bayar”. Kata keputusan hanya pada formulir/riwayat **catatan manusia**, dibedakan dari badge sistem. Batas [PRD](PRD.md#out-of-scope) berlaku.

| Token | Nilai usulan | Pemakaian |
|---|---|---|
| background / surface / text / muted | #F8FAFC / #FFFFFF / #0F172A / #475569 | Canvas, card, teks |
| primary / focus | #1D4ED8 / #2563EB | Aksi dan fokus keyboard |
| info / warning / danger | #1E40AF / #92400E / #991B1B | Status dengan ikon dan label, bukan warna saja |
| font | system-ui, sans-serif; 14px tabel, 16px body, 24px judul | Line-height 1.5 |
| spacing | 4,8,12,16,24,32px | Grid dan padding konsisten |
| radius / border | 8px / 1px #CBD5E1 | Card/input |
| target / focus ring | >=44px / 2px dengan offset 2px | Aksi sentuh/fokus |
Kontras diuji WCAG AA; token yang gagal saat diterapkan harus disesuaikan dengan audit. Layout desktop sidebar 240px, content fluid; breakpoint usulan 768px collapse sidebar, detail stacked dengan tab Sumber/Data. Viewer tetap dapat dibuka keyboard.

## Halaman dan tabel
| Halaman / route UI | Pengguna | Komponen dan kolom |
|---|---|---|
| Masuk `/login` | Semua | Auth sesuai Q-008; error tanpa membocorkan akun |
| Ringkasan `/dashboard` | S/P | Jumlah case per status pemrosesan dan validasi, tautan antrean; filter tanggal/vendor/status |
| Case `/cases` | S/P | case_number, vendor hasil ekstraksi, tanggal unggah, halaman, processing_status, validation_status, keputusan manusia terakhir/run, aksi Buka; paginasi |
| Unggah `/cases/new` | S/P | Buat case, file picker multi-file, baris status per file, progress dan retry; MIME/limit dari capabilities Q-002 |
| Detail `/cases/:id` | S/P | Header status terpisah, tab Dokumen/Ekstraksi/Validasi/Keputusan; versi run terlihat |
| Pengecualian `/exceptions` | S/P | severity, type, case_number, rule, umur, state, penanggung jawab; sort/filter dan bukti |
| Ekspor `/exports` | S/P pemohon | Filter/case terpilih, format yang diaktifkan Q-003, status job, dibuat, expiry, unduh |
| Pemakaian Credit `/credits` | A Managed | periode, kuota 50.000, terpakai, sisa, overage, estimasi biaya dasar/tambahan/total; riwayat periode |
| Admin Pengguna `/admin/users` | A | nama,email,role,active,last updated; tambah/ubah/nonaktif, tanpa hapus histori |
| Admin Parameter `/admin/rules` | A | code,versi,severity,parameter,aktif; edit existing parameter dengan alasan dan approval_reference; tidak ada tambah logic |
| Jejak Sistem `/admin/audit` | A | waktu,aktor,aksi,jenis/id objek,request_id; filter dan detail metadata aman |
| Operasi `/ops` | O | health komponen, job ID/status/attempt/kode failure; retry teknis tanpa data dokumen |

## Viewer dan evidence
Detail dua panel: kiri viewer halaman asli (zoom, previous/next, nomor halaman); kanan field terstruktur dan rule/exception. Setiap nilai tampil dengan tautan “Lihat sumber, halaman N” yang membuka document_id/page_number versi yang tepat dan highlight bbox bila ada. Evidence tidak memiliki bbox tetap menuju halaman. Tampilkan “Sumber tidak tersedia” untuk field null dengan alasan; tidak membuat halaman palsu. Validasi menampilkan semua result, reasoning singkat, perhitungan kode dan kedua sumber, bukan hanya overall badge. Dokumen dan hasil sensitif tidak disimpan browser storage/cache publik.

Form keputusan hanya P manusia: select “Diterima (catatan pengguna)”, “Ditolak (catatan pengguna)”, “Perlu klarifikasi”; note wajib, run/version terikat dan konfirmasi “Simpan catatan keputusan”. Penjelas: “Catatan ini tidak menjalankan pembayaran.” Q-015 menentukan final vocabulary. Admin tidak melihat tombol ini karena role Admin saja tidak cukup. Run berubah -> nonaktifkan submit, tampilkan ajakan muat ulang, tidak mereset diam-diam. History menampilkan aktor,waktu,run,note,supersedes.

## State wajib
| State | Perilaku |
|---|---|
| Loading | Skeleton pada tabel, aria-busy, jangan tampil nol pemakaian sebelum data termuat |
| Empty | “Belum ada case. Unggah dokumen untuk memulai.”; rule kosong “Kriteria belum dikonfigurasi”, bukan MATCHED |
| Processing | Tahap dan job ID aman; polling, jangan menjanjikan waktu tanpa Q-009 |
| Error | Pesan aman + request_id dan retry; input tidak hilang; tidak menampilkan stack/model output |
| Partial upload | Status tiap file; retry hanya file gagal dengan key yang sama untuk retry request identik |
| Forbidden | Tampilkan halaman tidak diizinkan; data objek tidak ikut termuat |
| Stale version | “Hasil telah berubah. Muat ulang untuk meninjau versi terbaru.” |
| Credit disabled | onprem sembunyikan menu/widget/notifikasi kuota; deep link menampilkan fitur tidak berlaku |
| Quota exhausted | Banner netral dengan overage dan tarif; upload/proses tetap tersedia |
| Export expired | “Berkas ekspor kedaluwarsa. Buat ekspor baru.” |
Microcopy kuota di [UX](UX.md); API/RBAC [API_CONTRACT](API_CONTRACT.md); uji visual dan acceptance [TESTING](TESTING.md), [ACCEPTANCE](ACCEPTANCE.md).
