# Kriteria Penerimaan dan Checklist UAT (Acceptance Criteria)
Tujuan file ini: menetapkan kriteria penerimaan teruji (testable criteria) berbasis skenario Given/When/Then untuk pengujian UAT dan penandatanganan BAST Phase 1.
Dibaca oleh / kapan dipakai: tim QA, Project Manager, Solutions Architect, serta tim Finance dan IT PT SIS saat pelaksanaan UAT.

## Aturan sign-off
1. **Objektivitas Pengujian:** Seluruh kriteria penerimaan di bawah ini WAJIB dapat diuji secara transparan menggunakan skenario konkret.
2. **Penanganan Status [TBD]:** Parameter yang masih berstatus `[TBD]` menggunakan *Default Usulan* dari [DECISIONS](DECISIONS.md) sebagai baseline pengujian internal. Tanda `[TBD]` yang belum disahkan oleh klien PT SIS tidak dapat dianggap lulus otomatis (*PASS*) sebelum kesepakatan tertulis diterbitkan.
3. **Keterlacakan Penuh:** Setiap kriteria penerimaan memiliki kode unik `A-xxx` yang dipetakan secara 1:1 ke User Story (`US-xxx`), Validation Rule (`VR-xxx`), dan Kasus Uji (`TC-xxx`) pada [TRACEABILITY](TRACEABILITY.md).

---

## Upload dan pemrosesan

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-UPLOAD-01** | `US-UPLOAD-01` | **Given** pengguna Finance Staff memilih berkas faktur dalam format PDF/PNG/JPEG berukuran <= 50 MB,<br>**When** berkas diunggah melalui endpoint `POST /cases/{id}/documents`,<br>**Then** sistem menerima berkas, menyimpannya di object storage terisolasi, dan mengembalikan status HTTP 202 Accepted. | `TC-G01`, `TC-F09` |
| **A-MONITOR-01** | `US-MONITOR-01` | **Given** bundel berkas dalam status sedang diproses oleh worker,<br>**When** staf membuka antarmuka dashboard kasus `/cases`,<br>**Then** status pemrosesan menampilkan transisi akurat (`UPLOADED -> PROCESSING -> EXTRACTED -> VALIDATED`) tanpa perlu refresh browser manual. | `TC-REC-01` |
| **A-PAGECOUNT-01** | `US-UPLOAD-01` | **Given** berkas PDF faktur multi-halaman (misal: 4 halaman fisik),<br>**When** berkas selesai diinspeksi oleh modul ingestion,<br>**Then** kolom `documents.page_count` dan `cases.total_pages` mencatat tepat 4 halaman, dan rendering ulang tidak menambah jumlah halaman. | `TC-G02` |

---

## Ekstraksi

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-EXTRACT-01** | `US-EXTRACT-01` | **Given** dokumen faktur komersial standar yang diunggah,<br>**When** proses ekstraksi AI selesai,<br>**Then** field identitas vendor, nomor faktur, tanggal, rincian baris item, kuantitas, harga satuan, pajak, dan total nilai tersimpan dalam skema terstruktur bertipe. | `TC-G01` |
| **A-ACCURACY-01** | `US-EXTRACT-01` | **Given** dataset evaluasi sintetis (*held-out test set*) minimal 100 dokumen,<br>**When** akurasi pembacaan field diukur secara otomatis,<br>**Then** micro-average field accuracy mencapai minimal **>= 85%** sesuai target `Q-009`. | `TC-AI-01` |
| **A-HELDOUT-01** | `US-EXTRACT-01` | **Given** dokumen dari vendor baru dengan tata letak visual yang belum pernah dilatih sebelumnya,<br>**When** diproses oleh pipeline ekstraksi tanpa template vendor,<br>**Then** sistem mampu mengekstrak seluruh field kunci dengan benar tanpa konfigurasi manual tambahan. | `TC-G02` |
| **A-UNREADABLE-01** | `US-EXTRACT-01` | **Given** berkas pindaian berkualitas sangat buruk atau buram (`TC-F06`),<br>**When** diproses oleh ekstraksi AI,<br>**Then** sistem mengisi field yang tidak terbaca dengan nilai `null`, mencatat flag `UNREADABLE`, dan DILARANG mengarang angka palsu. | `TC-F06` |

---

## Validasi

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-RULES-01** | `US-VALIDATE-01` | **Given** berkas faktur beserta seluruh dokumen pendukungnya (PO, DN, GR, BAST),<br>**When** rule engine deterministik dieksekusi,<br>**Then** seluruh aturan aktif (`VR-001` s.d. `VR-009`) dievaluasi menggunakan aritmatika kode `Decimal` dengan fault detection recall **>= 95%**. | `TC-G01`, `TC-F01` s.d. `TC-F04` |
| **A-EVIDENCE-01** | `US-VALIDATE-01` | **Given** hasil evaluasi aturan yang membandingkan nilai antar dua dokumen (misal: Total Invoice vs PO),<br>**When** hasil validasi dibuka pada antarmuka split-viewer,<br>**Then** sistem menampilkan rujukan nomor halaman dan koordinat bounding box pada KEDUA dokumen sumber secara tepat. | `TC-EVD-01` |
| **A-PRECEDENCE-01** | `US-VALIDATE-01` | **Given** sebuah kasus faktur yang menghasilkan 1 hasil `INCOMPLETE` dan 1 hasil `FAIL`,<br>**When** status akhir kasus diagregasikan,<br>**Then** status validasi akhir kasus adalah `INCOMPLETE` sesuai aturan preseden (`INCOMPLETE > DUPLICATE_SUSPECT > NEEDS_REVIEW > MATCHED`). | `TC-F04` |
| **A-DUPLICATE-01** | `US-VALIDATE-01` | **Given** faktur baru diunggah dengan nomor, vendor, dan total yang identik dengan faktur lama (`TC-F05`),<br>**When** aturan `VR-008` dievaluasi,<br>**Then** sistem menandai status kasus sebagai `DUPLICATE_SUSPECT`, menampilkan rujukan ke kedua kasus, dan DILARANG menghapus berkas otomatis. | `TC-F05` |

---

## Human control

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-HUMAN-01** | `US-REVIEW-01` | **Given** kasus faktur berstatus validasi apapun (termasuk `MATCHED`),<br>**When** sistem menyelesaikan evaluasi,<br>**Then** sistem DILARANG membuat keputusan persetujuan faktur atau memicu pembayaran otomatis; keputusan sepenuhnya menunggu tindakan Approver. | `TC-SEC-02` |
| **A-APPROVER-01** | `US-REVIEW-01` | **Given** pengguna terautentikasi dengan peran `APPROVER`,<br>**When** mengirimkan catatan keputusan resmi melalui `POST /cases/{id}/decisions`,<br>**Then** keputusan (`ACCEPTED`/`REJECTED`/`NEEDS_CLARIFICATION`) bersama catatan wajib tersimpan ke tabel append-only `review_decisions` dan diaudit. | `TC-RBAC-01` |
| **A-NEUTRAL-01** | `US-REVIEW-01` | **Given** seluruh teks penjelasan reasoning dan pesan antarmuka yang dihasilkan sistem,<br>**When** dianalisis melalui pemindai teks otomatis,<br>**Then** terbukti 100% bebas dari kata terlarang (*"fraud"*, *"penipuan"*, *"layak bayar"*, *"ditolak otomatis"*). | `TC-AI-01` |
| **A-QUEUE-01** | `US-REVIEW-01` | **Given** antrean pengecualian pada `/exceptions`,<br>**When** daftar ditampilkan ke pengguna,<br>**Then** daftar terurut secara deterministik berdasarkan tingkat keparahan (`ERROR > WARN > INFO`), usia pembuatan terlama (FIFO), dan selisih nominal transaksi. | `TC-G01` |

---

## Dashboard dan ekspor

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-EXPORT-01** | `US-EXPORT-01` | **Given** pengguna Finance Staff memilih sekumpulan kasus terotorisasi,<br>**When** meminta ekspor ke format CSV atau XLSX melalui `POST /exports`,<br>**Then** berkas snapshot terstruktur terbuat, selaras dengan data database, dan seluruh karakter berawalan `=`, `+`, `-`, `@` dibersihkan dari formula injection. | `TC-SEC-04` |

---

## Credit

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-CREDITMETER-01**| `US-CREDIT-01` | **Given** skema Managed aktif dengan kuota 50.000 kredit/bulan,<br>**When** berkas 4 halaman berhasil diunggah dan lolos verifikasi (`doc_state=ACCEPTED`),<br>**Then** buku besar `credit_ledger` mencatat tepat pemotongan 4 kredit (1 kredit = 1 halaman) secara idempotent per event key. | `TC-C01` |
| **A-CREDITQUOTA-01**| `US-CREDIT-01` | **Given** total pemakaian kredit mencapai 50.010 kredit pada bulan aktif,<br>**When** dashboard `/credits` dibuka oleh Admin,<br>**Then** sistem menampilkan total terpakai 50.010, kuota 50.000, pemakaian tambahan 10 kredit, dan estimasi biaya tambahan IDR 5.000 (10 x IDR 500). | `TC-C02` |
| **A-CREDITNOTIF-01**| `US-CREDIT-01` | **Given** pemakaian kredit mencapai ambang batas 80% (40.000 kredit) atau 100%,<br>**When** transaksi berikutnya diproses,<br>**Then** notifikasi in-app terkirim ke Admin dan proses pemrosesan dokumen **TETAP BERJALAN NORMAL TANPA INTERUPSI**. | `TC-C02` |
| **A-ONPREM-01** | `US-CREDIT-01` | **Given** sistem dideploy dengan konfigurasi `DEPLOYMENT_MODE=onprem`,<br>**When** pengguna mengakses endpoint `/credits/*`,<br>**Then** sistem merespons HTTP 404 `FEATURE_DISABLED` dan antarmuka web menyembunyikan seluruh modul pemantauan kredit. | `TC-ONPREM-01` |

---

## Kinerja dan keandalan

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-PERF-01** | `US-OPS-01` | **Given** pengujian beban kerja simulasi throughput 500.000 halaman/bulan (~700 halaman/jam),<br>**When** diuji selama 4 jam berturut-turut,<br>**Then** latensi pemrosesan p95 tetap <= 30 detik/halaman dan ketersediaan sistem >= 99.5%. | `TC-LOAD-01` |
| **A-RECOVERY-01** | `US-OPS-01` | **Given** worker Celery dimatikan paksa (crash) saat proses ekstraksi berlangsung,<br>**When** worker baru dihidupkan kembali,<br>**Then** outbox job yang terputus diklaim ulang dan diselesaikan tanpa duplikasi pencatatan kredit di `credit_ledger`. | `TC-REC-01` |
| **A-RESTORE-01** | `US-OPS-01` | **Given** backup database harian dan arsip WAL,<br>**When** diuji restorasi ke lingkungan staging terisolasi,<br>**Then** integritas database utuh 100%, seluruh relasi FK valid, dan waktu pemulihan (RTO) <= 4 jam. | `TC-RESTORE-01` |

---

## Serah terima

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-HANDOVERDOC-01**| `US-HANDOVER-01` | **Given** penyelesaian fase implementasi Phase 1,<br>**When** persiapan serah terima dilakukan,<br>**Then** berkas Panduan Pengguna, Panduan Operasional Administrator, dan Laporan Hasil UAT diserahkan lengkap tanpa source code. | Seluruh Suite Uji |
| **A-TRAINING-01** | `US-HANDOVER-01` | **Given** jadwal pelatihan pengguna akhir yang disepakati,<br>**When** sesi pelatihan diselenggarakan untuk Finance Staff dan Approver PT SIS,<br>**Then** pelatihan terlaksana dengan materi simulasi mandiri dan daftar hadir bertanda tangan. | Sesi Simulasi |
| **A-SIGNBAST-01** | `US-HANDOVER-01` | **Given** 100% kriteria UAT disetujui tanpa defect Blocker,<br>**When** proses serah terima formal diselenggarakan,<br>**Then** dokumen Berita Acara Serah Terima (BAST) Phase 1 ditandatangani oleh Project Sponsor PT SIS dan INaAI. | BAST Phase 1 Sign-off |

---

## Keamanan dan administrasi

| ID Kriteria | User Story | Skenario Pengujian (Given / When / Then) | Kasus Uji |
|---|---|---|:---:|
| **A-ADMIN-01** | `US-ADMIN-01` | **Given** pengguna dengan peran `ADMIN`,<br>**When** mengubah batas toleransi aturan validasi melalui `PATCH /admin/rules/{id}/params`,<br>**Then** sistem membuat record aturan versi baru dengan alasan tertulis dan mencatat perubahannya pada log audit. | `TC-AUD-01` |
| **A-SECURITY-01** | `US-OPS-01` | **Given** pengujian celah keamanan otomatis (SAST, secret scan, IDOR, prompt injection),<br>**When** suite pengujian keamanan dieksekusi,<br>**Then** tidak ditemukan kerentanan berstatus High/Critical dan rantai hash audit (`audit_log.entry_hash`) terbukti valid tanpa kerusakan. | `TC-SEC-01` s.d. `TC-SEC-04` |

---

## Matriks cakupan dan keputusan penerimaan
- **100% User Story Terpetakan:** Seluruh 10 User Story (`US-UPLOAD-01` s.d. `US-HANDOVER-01`) telah memiliki kriteria penerimaan terukur dengan format baku.
- **Kemandirian Sign-off:** Setiap kriteria penerimaan dapat diverifikasi secara independen oleh tim QA dan delegasi bisnis PT SIS.
- **Batas Kepatuhan Kontrak:** Penandatanganan BAST Phase 1 mengonfirmasi penyelesaian implementasi Phase 1 dan memicu aktivasi masa berlangganan minimum 12 bulan (Managed) atau lisensi 12 bulan (On-Premise).
