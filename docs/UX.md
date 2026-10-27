# Journey dan interaksi
Tujuan file ini: merinci alur kerja manusia, recovery dan microcopy netral.
Dibaca oleh / kapan dipakai: agent produk/frontend dan peserta UAT saat memeriksa alur end-to-end.

## Alur end-to-end
Usulan D-009: login -> buat Case -> pilih invoice + dokumen pendukung -> unggah tiap file -> pantau proses -> buka hasil -> periksa exception/evidence -> Approver mencatat keputusan -> ekspor snapshot. Tidak ada langkah pembayaran/ERP. Batas [PRD](PRD.md#out-of-scope) berlaku; halaman dan state di [UI](UI.md).

1. Capabilities menampilkan format/limit sebelum unggah (Q-002). User mengelompokkan satu invoice dengan dokumen terkait; file campuran diberi peringatan Q-006.
2. Upload menampilkan sukses/gagal per file dan total halaman. Retry request yang sama memakai key yang sama; upload baru atau reprocess diberi estimasi hanya setelah kebijakan Q-011 disepakati. Jangan menjanjikan gratis/berbayar sebelum jawaban.
3. Status pemrosesan berubah, failure teknis dibedakan dari hasil validasi. Case incomplete tetap dapat direview sebagai informasi belum lengkap.
4. Antrian exception membuka evidence langsung. Staff dapat assign/ubah state exception sesuai izin; menutup exception tidak memutuskan invoice.
5. Approver membaca run terbaru, mengisi keputusan dan note; server mengecek actor dan versi saat submit. Bila run berubah, minta review ulang, bukan auto-resubmit keputusan.
6. Ekspor snapshot menyebut case/run/tanggal; sebelum download status akses diverifikasi ulang. Ekspor tidak mengubah decision atau menandai pembayaran.

## Journey per persona
| Persona | Tujuan | Jalur | Bukti selesai |
|---|---|---|---|
| Finance Staff | Menyiapkan data dan memeriksa kelengkapan | Unggah -> monitoring -> evidence -> assign/resolve exception -> ekspor | US-UPLOAD-01, US-MONITOR-01, US-EXTRACT-01, US-VALIDATE-01, US-EXPORT-01 |
| Approver | Mencatat keputusan setelah review | Antrean -> sumber -> keputusan/note -> history | US-REVIEW-01; riwayat dengan actor/run |
| Admin | Mengontrol akses, parameter dan biaya terukur | Users -> existing rules -> credit/history -> audit | US-ADMIN-01, US-CREDIT-01 |
| INaAI Ops | Memulihkan layanan | Health -> sanitized failed job -> retry -> verifikasi recovery | US-OPS-01; tanpa akses default dokumen |
Kewenangan delegasi/multi-role dan keputusan pengganti Q-015. Jangan menampilkan aktivitas admin sebagai review manusia invoice.

## Prioritas antrean
Usulan awal untuk diuji bersama PT SIS, Q-001: severity ERROR > WARN > INFO, lalu created_at paling lama, tie-break ID. Severity berasal parameter rule yang disepakati, bukan LLM. Dalam case tampil semua exception meski overall status hanya satu. Jangan menganggap nilai transaksi besar/duplikasi sebagai fraud atau otomatis menempatkannya di posisi teratas tanpa kebijakan. Filter type/state/assignee tidak menyembunyikan status incomplete.

## Microcopy dan notifikasi
| Situasi | Teks usulan |
|---|---|
| MATCHED | “Tidak ditemukan perbedaan pada kriteria yang dijalankan. Tetap memerlukan keputusan pengguna berwenang.” |
| NEEDS_REVIEW | “Ditemukan perbedaan data. Periksa nilai dan sumber terkait.” |
| INCOMPLETE | “Informasi belum lengkap atau belum terbaca. Periksa dokumen sumber.” |
| DUPLICATE_SUSPECT | “Terdapat kemiripan dengan invoice lain. Periksa kedua dokumen.” |
| Scan buram | “Sebagian informasi tidak terbaca. Periksa sumber atau unggah dokumen yang tersedia dengan kualitas lebih baik.” |
| Mendekati kuota | “Pemakaian mendekati kuota periode ini. Pemrosesan tetap berjalan.” |
| Kuota habis | “Kuota 50.000 credit telah terpakai. Pemrosesan tetap berjalan; tambahan pemakaian IDR 500/credit.” |
| Melebihi kuota | “Pemakaian di atas kuota: {overage} credit. Estimasi tambahan: {additional_idr}. Pemrosesan tetap berjalan.” |
| Gagal teknis | “Dokumen belum selesai diproses. Coba ulang atau hubungi dukungan dengan ID {request_id}.” |
| Keputusan tersimpan | “Catatan keputusan pengguna tersimpan untuk hasil pemeriksaan versi ini.” |
Ambang mendekati kuota Q-012, tidak mengarang persentase. Notifikasi in-app satu per jenis/periode/recipient; tidak kirim email/slack. Mode onprem tidak menampilkan copy kuota. Sistem bukan jasa perbaikan/digitalisasi sumber; permintaan sumber pengganti dilakukan manusia.

## Recovery dan aksesibilitas
Simpan progres unggah per file; koneksi terputus tidak menciptakan charge ulang dari retry identik. Jika session habis, login ulang lalu muat state server; jangan simpan dokumen dalam localStorage. Error permission tidak menampilkan nama dokumen. Raw model failure diterjemahkan menjadi kode aman. Quota tidak pernah mematikan tombol proses.

Usulan standar aksesibilitas WCAG 2.2 AA: navigasi keyboard, focus visible dan kembali ke pemicu setelah modal, label form/aria-describedby error, live region untuk status, kontras minimal 4.5:1 teks normal dan 3:1 teks besar, informasi selain warna, target >=44px, zoom 200% tanpa kehilangan tindakan utama. Viewer memiliki tabel field alternatif yang dapat dibaca screen reader; nomor halaman dapat diketik. Verifikasi manual screen reader dan keyboard dalam [TESTING](TESTING.md), acceptance [ACCEPTANCE](ACCEPTANCE.md). Untuk penghapusan/retensi, alur belum diaktifkan sebelum Q-005; jangan membuat tombol hapus produksi tanpa kebijakan.
