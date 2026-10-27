# AGENTS.md - Aturan untuk AI Agent

Baca file ini sebelum mengubah apa pun di repo.

## Konteks Singkat
Sistem validasi invoice berbasis AI untuk Finance PT SIS. Detail di `PRD.md`.

## Aturan Mutlak (Non-Negotiable)
1. **Human decision control.** Sistem TIDAK PERNAH menyetujui/menolak invoice atau mengotorisasi pembayaran. Sistem hanya memberi status validasi + reasoning. Keputusan akhir dibuat user dan dicatat sebagai `review_decisions`.
2. **Tanpa integrasi ERP/sistem internal.** Jangan membuat konektor ke ERP, payment, atau sistem lain. Data masuk hanya lewat unggahan.
3. **Reasoning harus traceable.** Setiap hasil validasi wajib merujuk dokumen sumber, halaman, dan field. Tidak boleh ada hasil tanpa evidence.
4. **Bukan fraud/tax/legal tool.** Hanya tandai selisih data dan potensi duplikasi. Jangan menulis fitur atau teks UI yang mengklaim kesimpulan audit, pajak, atau hukum.
5. **Format-agnostic.** Dilarang membuat template/parser per-vendor. Ekstraksi berbasis konteks AI.
6. **1 credit = 1 halaman** yang diunggah. Pencatatan credit harus akurat dan idempotent. Notifikasi kuota tidak boleh menghentikan pemrosesan.
7. **Aturan validasi terpusat.** Rule disimpan sebagai konfigurasi, bukan hardcode tersebar. Rule baru = Change Request, parameter rule yang sudah ada boleh diubah terkendali.
8. **Jangan commit secret.** API key, kredensial, dan dokumen asli PT SIS tidak boleh masuk repo.
9. **Dokumen finansial = data sensitif.** Jangan log isi dokumen/nilai transaksi mentah di log aplikasi.

## Cara Bekerja
- Kerjakan satu milestone/tugas dari `IMPLEMENTATION.md` per sesi. Jangan loncat.
- Jika spesifikasi ambigu, cek `DECISIONS.md` (bagian Open Questions). Jika belum terjawab, **tanya**, jangan mengarang aturan bisnis.
- Setiap perubahan skema DB, endpoint, atau prompt harus memperbarui `DATA_MODEL.md` / `API_CONTRACT.md` / `PROMPTS.md` pada perubahan yang sama.
- Keputusan teknis baru dicatat di `DECISIONS.md`.
- Tulis test sesuai `TESTING.md` sebelum menandai tugas selesai.
- Perubahan kecil dan terfokus; jangan refactor besar tanpa diminta.

## Definisi Selesai (per tugas)
- Kode berjalan dan lolos lint + test.
- Dokumen terkait diperbarui.
- Tidak melanggar Aturan Mutlak di atas.
- Kriteria terkait di `ACCEPTANCE.md` dapat didemonstrasikan.

## Hal yang Harus Ditanyakan ke Manusia
- Toleransi angka (pembulatan/selisih harga, qty, pajak).
- Rule validasi baru atau perubahan makna status.
- Format ekspor final.
- Pemilihan provider LLM untuk produksi / on-premise.

## Bahasa
- Kode, nama variabel, nama tabel/endpoint: English.
- Teks UI: Bahasa Indonesia (default). Dokumen internal boleh campuran.
