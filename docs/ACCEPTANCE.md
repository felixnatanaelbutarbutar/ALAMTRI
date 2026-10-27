# ACCEPTANCE.md

> Draf. Kriteria final disepakati bersama PT SIS di Discovery (minggu 1-2) dan dipakai untuk UAT. Item bertanda **[TBD]** butuh angka dari PT SIS.

## A. Upload & Pemrosesan
- [ ] A1 User dapat mengunggah PDF, scanned image, dan dokumen digital ke dalam satu case.
- [ ] A2 Status pemrosesan terlihat dan berubah sesuai tahap; kegagalan menampilkan pesan jelas.
- [ ] A3 Jumlah halaman terhitung benar untuk setiap file.

## B. Ekstraksi
- [ ] B1 Field wajib (vendor, nomor, tanggal, line item, qty, harga satuan, pajak, total) terekstrak dari invoice dan dokumen pendukung pada sampel UAT.
- [ ] B2 Akurasi ekstraksi field kunci >= **[TBD]%** pada dataset sampel yang disepakati.
- [ ] B3 Vendor dengan format baru (tidak ada di sampel awal) tetap terbaca tanpa konfigurasi template.
- [ ] B4 Field tak terbaca bernilai null dan ditandai, bukan ditebak.

## C. Validasi
- [ ] C1 Rule yang disepakati dijalankan lintas invoice, PO, DN, GR, BAST.
- [ ] C2 Setiap hasil punya reasoning dan evidence (dokumen, halaman, field) yang bisa dibuka dari UI.
- [ ] C3 Selisih yang sengaja disuntikkan pada dokumen uji terdeteksi (recall >= **[TBD]%**).
- [ ] C4 Invoice duplikat uji terdeteksi sebagai `DUPLICATE_SUSPECT`.
- [ ] C5 Dokumen tidak lengkap ditandai `INCOMPLETE`.

## D. Human Control
- [ ] D1 Tidak ada jalur yang membuat keputusan accept/reject otomatis oleh sistem.
- [ ] D2 Hanya Approver yang dapat mencatat keputusan; tercatat di audit log.
- [ ] D3 UI tidak memuat klaim fraud, pajak, atau hukum.

## E. Dashboard & Ekspor
- [ ] E1 Antrian exception tersortir berdasar prioritas.
- [ ] E2 Hasil ekstraksi dapat diekspor dalam format yang disepakati dan isinya sesuai database.

## F. Credit (Managed)
- [ ] F1 1 halaman = 1 credit; pencatatan tidak dobel pada upload ulang yang sama.
- [ ] F2 Dashboard menampilkan pemakaian, sisa kuota (dari 50.000), overage, dan riwayat bulanan.
- [ ] F3 Notifikasi muncul saat mendekati, mencapai, dan melewati kuota; pemrosesan tidak berhenti.
- [ ] F4 Pada mode On-Premise fitur credit tidak aktif.

## G. Kinerja & Keandalan
- [ ] G1 Waktu pemrosesan per halaman rata-rata <= **[TBD]** detik.
- [ ] G2 Mampu memproses beban setara 5.000 invoice/bulan (~500.000 halaman) tanpa antrean menumpuk di luar batas **[TBD]**.
- [ ] G3 Backup dan restore database terverifikasi (Managed).

## H. Serah Terima
- [ ] H1 Dokumentasi pengguna diserahkan.
- [ ] H2 Pelatihan untuk pengguna yang ditunjuk selesai.
- [ ] H3 BAST Phase 1 ditandatangani.
