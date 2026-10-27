# Strategi dan Protokol Pengujian Sistem (Testing Strategy)
Tujuan file ini: mendefinisikan lapisan pengujian perangkat lunak, uji wajib anti-keputusan-otomatis, evaluasi metrik akurasi AI, dan protokol uji beban ~500.000 halaman/bulan.
Dibaca oleh / kapan dipakai: tim QA engineer, pengembang software, dan tim evaluator UAT sebelum merge kode ke branch utama dan sebelum deployment rilis.

## Lapisan uji
**Berdasarkan Usulan D-007.** Pengujian sistem dijalankan secara berjenjang untuk memvalidasi keandalan fungsional dan integritas data:

| Lapisan Uji | Perkakas Uji (Tools) | Cakupan Komponen & Verifikasi |
|---|---|---|
| **Unit Testing** | `pytest`, `pytest-cov`, `Vitest` | Evaluasi aturan validasi deterministik (VR-001, VR-002, VR-003, VR-004, VR-005, VR-006, VR-007, VR-008, VR-009), kalkulasi `Decimal`, mesin state machine, normalisasi tanggal/angka, dan kalkulasi kredit Managed. |
| **Integration Testing** | `pytest`, `Testcontainers` (PostgreSQL, Redis, MinIO) | Siklus transaksi database, integritas foreign key composite, jaminan append-only, kunci idempotensi API, upload multipart, dan kontrak REST OpenAPI. |
| **End-to-End (E2E)** | `Playwright` | Alur lengkap di antarmuka browser: Staff mengunggah berkas -> memantau progress -> memeriksa viewer evidence -> Approver mencatat keputusan resmi -> ekspor CSV/XLSX. |
| **AI Regression & Safety** | Automated Python Eval Runner | Evaluasi akurasi ekstraksi field pada held-out dataset sintetis, uji ketahanan terhadap prompt injection, dan verifikasi ketiadaan kata terlarang. |
| **Load & Stress Testing** | `Locust` / `k6` | Simulasi beban tinggi throughput ~500.000 halaman/bulan (rata-rata 700 halaman/jam, burst hingga 1.500 halaman/jam) untuk memverifikasi konkurensi worker. |
| **Operasional & Restore Drill** | Bash / CLI Scripting | Uji pemulihan point-in-time database PostgreSQL dari berkas WAL arsip dan rekonsiliasi total kredit pada buku besar. |

---

## Tes wajib

Seluruh suite pengujian otomatis berikut WAJIB dijalankan dan lulus 100% pada pipeline CI/CD:

1. **Uji Matriks RBAC & Anti-IDOR (`TC-RBAC-01`):**
   - Menguji seluruh endpoint API terhadap 4 peran (`STAFF`, `APPROVER`, `ADMIN`, `OPS`) dan status unauthenticated.
   - Memverifikasi bahwa upaya akses lintas-tenant (IDOR) menghasilkan HTTP 404 tanpa kebocoran data.
2. **Uji Anti-Keputusan-Otomatis (Strict Human Decision Gate - `TC-SEC-02`):**
   - Output LLM yang mencoba menyisipkan kata "ACCEPTED" atau "REJECTED" WAJIB ditolak oleh skema validator.
   - Token internal service worker atau script otomatis yang mencoba melakukan `INSERT` ke tabel `review_decisions` WAJIB ditolak dengan HTTP 403 `HUMAN_REQUIRED`.
   - Penyelesaian seluruh pengecualian (`RESOLVED`) dan status validasi `MATCHED` terbukti TIDAK MENGUBAH keputusan akhir faktur menjadi disetujui.
3. **Uji Idempotensi Kredit (`TC-C01`):**
   - Pengiriman 10 request upload paralel dengan `billing_event_key` yang sama terbukti hanya menghasilkan tepat 1 baris pemotongan kredit di `credit_ledger`.
   - Simulasi worker Celery mati mendadak (SIGKILL) saat pemrosesan tidak mengakibatkan penagihan kredit ganda saat job di-retry.
4. **Uji Formula Kuota & Overage (`TC-C02`):**
   - Memverifikasi transisi batas kuota: 49.999 -> 50.000 -> 50.001 kredit.
   - Pemrosesan halaman ke-50.001 terbukti tetap berjalan lancar tanpa interupsi, menghasilkan notifikasi `QUOTA_EXCEEDED`, dan mencatat estimasi tarif tambahan IDR 500 / kredit secara presisi.
   - Pada mode `DEPLOYMENT_MODE=onprem`, verifikasi bahwa tidak ada entri kredit yang dibuat dan endpoint `/credits/*` merespons 404 `FEATURE_DISABLED`.
5. **Uji Validitas Evidence 100% (`TC-EVD-01`):**
   - Setiap nilai field ekstraksi non-null terbukti memiliki rujukan `document_id`, `page_number`, dan koordinat bounding box yang valid.
   - Dokumen pendukung yang tidak terlampir terbukti menghasilkan status `INCOMPLETE` dengan keterangan eksplisit tanpa menciptakan tautan evidence fiktif.
6. **Uji Ketahanan Injeksi & Keamanan Dokumen (`TC-F07`, `TC-SEC-03`, `TC-SEC-04`):**
   - Berkas PDF yang disisipi teks instruksi jahat (prompt injection) terbukti tidak memicu tool execution atau manipulasi status sistem.
   - Berkas berbahaya (malware / zip bomb) dan PDF terenkripsi sandi terbukti berhasil dikarantina dan ditolak dengan pesan error yang aman.
   - Berkas ekspor CSV terbukti membersihkan formula berbahaya (`=`, `+`, `-`, `@`) untuk mencegah CSV formula injection.
7. **Uji Beban Skala Tinggi 500.000 Halaman/Bulan (`TC-LOAD-01`):**
   - Simulasi pemrosesan beban kontinu sebesar **700 halaman per jam** selama durasi 4 jam pengujian terbukti mempertahankan p95 latency <= 30 detik per halaman tanpa memory leak pada Celery worker.

---

## Dataset dan evaluasi AI
Evaluasi performa model AI dijalankan menggunakan dataset sintetis terpisah (*held-out set*) di `fixtures/synthetic` yang belum pernah dilihat model saat penyusunan prompt:
1. **Komposisi Dataset Pengujian:** Minimal 100 bundel kasus sintetis mencakup variasi tata letak visual vendor alat berat, faktur barang sparepart, faktur jasa sewa kendaraan, dan surat jalan tambang.
2. **Evaluasi Keamanan Teks (Microcopy Blacklist Check):** Setiap teks narasi reasoning yang dihasilkan oleh prompt P-003 diuji secara otomatis melalui regex blacklist. Pipeline CI/CD akan gagal jika ditemukan kata: `fraud`, `penipuan`, `layak bayar`, atau `ditolak otomatis`.

---

## Metrik

| Nama Metrik | Formula / Definisi Kuantitatif | Nilai Target Minimum | Referensi Terkait |
|---|---|:---:|:---:|
| **Field Extraction Accuracy** | $\frac{\text{Jumlah Field Terbaca Benar}}{\text{Total Seluruh Field Expected}} \times 100\%$ | **>= 85%** | `Q-009`, `A-ACCURACY-01` |
| **Fault Detection Recall** | $\frac{\text{True Positive (Selisih Terdeteksi)}}{\text{True Positive} + \text{False Negative}} \times 100\%$ | **>= 95%** | `Q-009`, `A-RULES-01` |
| **False Positive Rate** | $\frac{\text{False Positive (Salah Menandai Selisih)}}{\text{False Positive} + \text{True Negative}} \times 100\%$ | **<= 5%** | `Q-009`, `A-RULES-01` |
| **Throughput Pemrosesan** | Jumlah halaman dokumen yang selesai diproses per jam | **>= 700 hal/jam** (Burst >= 1.500 hal/jam) | `Q-009`, `A-PERF-01` |
| **Kecepatan Pemrosesan (p95)**| Waktu selesai end-to-end per halaman pada persentil ke-95 | **<= 30 detik** / halaman | `Q-009`, `A-PERF-01` |
| **Biaya Komputasi AI per Halaman**| Total biaya token LLM aktual yang dikeluarkan per halaman dokumen | **<= IDR 25** / halaman | `TECH_STACK.md` |
| **Validitas Rujukan Evidence** | Rasio koordinat halaman & bbox yang valid terhadap seluruh evidence | **100% Valid** (Invarian Teknis Wajib) | `A-EVIDENCE-01` |

---

## Gate sebelum merge dan UAT

### 1. Merge Gate (Pipeline CI/CD Otomatis)
Setiap Pull Request WAJIB lulus seluruh kriteria berikut sebelum dapat digabungkan ke branch utama (`main`):
- [x] Linter dan static typechecker lulus 100% (`flake8`, `mypy`, `npm run typecheck`).
- [x] Seluruh unit dan integration test lulus dengan **code coverage minimal >= 85%**.
- [x] Skrip pemeriksa integritas dokumentasi (`check-docs.ps1`) lulus dengan exit code 0.
- [x] Tidak ada secret atau credential yang terdeteksi dalam commit.
- [x] Skrip migrasi database berhasil dieksekusi `upgrade` dan `downgrade` tanpa error.
- [x] Uji anti-keputusan-otomatis (`TC-SEC-02`) dan uji idempotensi kredit (`TC-C01`) lulus 100%.

### 2. UAT Gate (Kesiapan Pengujian Klien PT SIS)
Sebelum sistem diserahkan kepada tim Finance PT SIS untuk pelaksanaan UAT:
- [x] Lingkungan UAT terisolasi dengan data sintetis siap digunakan.
- [x] Akurasi ekstraksi field mencapai target minimal >= 85% pada dataset sampel UAT.
- [x] Recall deteksi kesalahan mencapai target minimal >= 95%.
- [x] Hasil uji beban membuktikan sistem stabil pada throughput 700 halaman/jam.
- [x] Seluruh kriteria penerimaan pada [ACCEPTANCE](ACCEPTANCE.md) berstatus terverifikasi atau memiliki kesepakatan tertulis.
