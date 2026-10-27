# IMPLEMENTATION.md

Urutan kerja untuk agent. Kerjakan berurutan; tiap tugas harus lolos `ACCEPTANCE.md` bagian terkait.

## M0 - Fondasi (Minggu 1-2, paralel dengan Discovery)
- [ ] T0.1 Inisialisasi monorepo sesuai `TECH_STACK.md`
- [ ] T0.2 Docker Compose: postgres, redis, minio, api, worker, web
- [ ] T0.3 Skema DB + migrasi (`DATA_MODEL.md`)
- [ ] T0.4 Auth + RBAC (STAFF / APPROVER / ADMIN)
- [ ] T0.5 CI: lint, test, build
- [ ] T0.6 Siapkan dataset sampel anonim (dari PT SIS saat tersedia)

## M1 - Ingestion & Extraction (Minggu 3-4)
- [ ] T1.1 Upload API + penyimpanan file + hitung halaman
- [ ] T1.2 Pencatatan credit idempotent per dokumen (mode managed)
- [ ] T1.3 Render halaman ke gambar
- [ ] T1.4 `LLMProvider` interface + adapter pertama
- [ ] T1.5 Klasifikasi dokumen (P-001)
- [ ] T1.6 Ekstraksi terstruktur (P-002) + validasi skema + simpan `extractions`
- [ ] T1.7 Normalisasi ke `doc_headers` / `doc_line_items`
- [ ] T1.8 Status pemrosesan + penanganan error/retry

## M2 - Validation Engine (Minggu 5-6)
- [ ] T2.1 Rule engine: rule sebagai konfigurasi (`validation_rules`)
- [ ] T2.2 Rule awal (final setelah Discovery): total invoice vs PO, qty invoice vs GR/DN, harga satuan vs PO, referensi dokumen lengkap, BAST untuk jasa, tanggal logis
- [ ] T2.3 Deteksi duplikasi (hash file + kombinasi vendor/nomor/total/tanggal)
- [ ] T2.4 Pencocokan semantik line item (P-004)
- [ ] T2.5 Reasoning + evidence (P-003)
- [ ] T2.6 Penentuan `validation_status` + prioritas exception

## M3 - Dashboard (Minggu 6-8)
- [ ] T3.1 Login + layout
- [ ] T3.2 Upload + daftar case + status real-time (polling)
- [ ] T3.3 Detail case: viewer dokumen berdampingan dengan data terstruktur
- [ ] T3.4 Panel validasi: hasil, reasoning, evidence yang bisa diklik ke halaman sumber
- [ ] T3.5 Antrian exception + form keputusan (Approver)
- [ ] T3.6 Ekspor CSV/XLSX
- [ ] T3.7 Halaman Credit Usage + notifikasi (hanya managed)
- [ ] T3.8 Admin: user dan parameter rule

## M4 - Hardening & UAT (Minggu 9-10)
- [ ] T4.1 Regression test ekstraksi pada dataset sampel
- [ ] T4.2 Performa: uji batch volume tinggi (target di ACCEPTANCE)
- [ ] T4.3 Perbaikan temuan UAT (dalam scope)
- [ ] T4.4 Audit log lengkap + review keamanan dasar

## M5 - Go-Live (Minggu 11-12)
- [ ] T5.1 Deployment cloud INaAI
- [ ] T5.2 Dokumentasi pengguna + pelatihan
- [ ] T5.3 Kesiapan Maintenance & Credit Metering untuk Phase 2
- [ ] T5.4 BAST Phase 1

## M6 (terpisah) - On-Premise
Paket container, panduan instalasi, aktivasi lisensi, `DEPLOYMENT_MODE=onprem`. Dikerjakan hanya jika PT SIS memilih skema On-Premise.
