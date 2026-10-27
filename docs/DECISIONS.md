# Keputusan dan pertanyaan terbuka
Tujuan file ini: membedakan fakta proposal dari usulan dan keputusan yang belum tersedia.
Dibaca oleh / kapan dipakai: agent, PT SIS, dan INaAI sebelum menetapkan perilaku produksi.

## Decision Log
| ID | Keputusan | Alasan | Status |
|---|---|---|---|
| D-001 | Pemahaman context-aware, format-agnostic tanpa parser vendor | Variasi format vendor | Disetujui-proposal |
| D-002 | Container dan adapter LLM/storage/auth, managed lebih dahulu | Portabilitas dua skema | Usulan |
| D-003 | Hitung angka dan evaluasi rule dengan kode; LLM memberi ekstraksi, kandidat semantik dan penjelasan terbatas | Reproduksibilitas dan evidence | Usulan |
| D-004 | Keputusan akhir dan otorisasi pembayaran hanya manusia PT SIS; simpan keputusan terpisah | Batas tanggung jawab | Disetujui-proposal |
| D-005 | Input hanya unggahan; tidak ada koneksi ERP/internal/payment | Batas scope | Disetujui-proposal |
| D-006 | Source code tidak diserahkan, termasuk On-Premise | Ketentuan komersial | Disetujui-proposal |
| D-007 | Stack dan versi kandidat di TECH_STACK; belum memilih provider produksi | Implementasi dapat direproduksi setelah pin lockfile | Usulan |
| D-008 | Notifikasi kuota tidak menghentikan proses; On-Premise tanpa kuota/Additional Usage | Model komersial | Disetujui-proposal |
| D-009 | Status, role, API, model data dan desain UI pada dokumen terkait | Kontrak teknis konsisten | Usulan |
| D-010 | Ledger append-only dengan billing event idempotent dan penyesuaian terpisah | Hindari pencatatan ganda; semantik billable tetap Q-011 | Usulan |
| D-011 | Snapshot rule, extraction, evidence dan version optimistic concurrency untuk review | Cegah review hasil kedaluwarsa | Usulan |
| D-012 | CSV/XLSX sebagai kandidat ekspor; seed hanya sintetis | Portabilitas dan kerahasiaan | Usulan |
| D-013 | Isolasi tenant, deny-by-default, transaksi dan outbox job | Batas akses serta pemulihan kegagalan | Usulan |

## Open Questions
Semua berstatus **Terbuka**, pemilik jawaban PT SIS bersama INaAI kecuali disebut lain. Jawaban wajib mencatat tanggal, pemilik, bukti persetujuan dan dokumen terdampak. Tidak ada nilai produksi tersirat. [TBD] pada acceptance memblokir sign-off kriteria terkait sampai disepakati; pekerjaan fondasi dapat berjalan dengan fixture sintetis yang dilabeli.

| ID | Pertanyaan / keputusan diperlukan | Gate | Referensi pemakaian |
|---|---|---|---|
| Q-001 | Rule final, toleransi qty/harga/total/pajak, rounding, dokumen wajib per jenis transaksi, partial delivery/partial invoice, metode semantic match dan prioritas? | Discovery; validasi produksi | [SEED](SEED.md), [PRD](PRD.md) |
| Q-002 | Jenis dokumen tambahan dan format/MIME/ukuran file/jumlah halaman yang diterima? | Ingestion produksi | [API_CONTRACT](API_CONTRACT.md) |
| Q-003 | Format ekspor final, kolom, ruang lingkup dan aturan mask? | Ekspor UAT | [UI](UI.md), [API_CONTRACT](API_CONTRACT.md) |
| Q-004 | Provider/model LLM produksi, lokasi pemrosesan, izin API eksternal, retensi provider, model lokal dan hardware? | Sebelum dokumen klien dikirim ke model | [SECURITY](SECURITY.md), [TECH_STACK](TECH_STACK.md) |
| Q-005 | Retensi dokumen/ekstraksi/audit/backup/ekspor, kewenangan penghapusan, legal hold dan purge? | Go-live | [SECURITY](SECURITY.md), [DATA_MODEL](DATA_MODEL.md) |
| Q-006 | Satu file campuran perlu segmentasi otomatis? Cara memetakan beberapa invoice ke case? | Klasifikasi produksi | [PROMPTS](PROMPTS.md) |
| Q-007 | Mata uang selain IDR, bahasa/format angka/tanggal, rounding dan konversi? Tidak ada kurs otomatis sebelum disepakati. | Normalisasi produksi | [PROMPTS](PROMPTS.md) |
| Q-008 | Auth produksi SSO/AD atau lokal, MFA, session timeout dan assignment role/akses case? | Auth produksi | [SECURITY](SECURITY.md) |
| Q-009 | Target field accuracy/recall/false-positive, latency p50/p95, throughput, beban/concurrency UAT, dataset dan biaya model/halaman? | Baseline UAT | [TESTING](TESTING.md), [ACCEPTANCE](ACCEPTANCE.md) |
| Q-010 | Bahasa dokumen Indonesia/Inggris/campuran atau lainnya? | Evaluasi model | [PROMPTS](PROMPTS.md) |
| Q-011 | Kapan halaman billable: upload/accepted/processed? Upload ulang, reprocess, gagal, pembatalan dan koreksi charge? | Credit produksi/invoice tagihan | [OPERATIONS](OPERATIONS.md), [API_CONTRACT](API_CONTRACT.md) |
| Q-012 | Zona waktu/batas bulan, tanggal awal siklus, ambang mendekati kuota, penutupan terlambat dan koreksi periode? | Credit produksi | [OPERATIONS](OPERATIONS.md) |
| Q-013 | SLA/support hours, escalation contact, RPO/RTO, jadwal backup dan uji restore? | Operasi produksi | [OPERATIONS](OPERATIONS.md) |
| Q-014 | Infrastruktur/cloud region, kapasitas, jaringan/air gap, registry, lisensi dependency, offline activation dan patch on-prem? | Deployment | [TECH_STACK](TECH_STACK.md), [OPERATIONS](OPERATIONS.md) |
| Q-015 | Siapa Approver, hak multi-role, vocabulary keputusan dan kewenangan mengganti keputusan terdahulu? | Review produksi | [UX](UX.md), [AUDIT](AUDIT.md) |
| Q-016 | Pihak penandatangan BAST Phase 1, artefak handover, klasifikasi defect dan waiver UAT? | Serah terima | [ACCEPTANCE](ACCEPTANCE.md) |
| Q-017 | Lingkup pencarian duplikasi (periode/case/vendor), normalisasi identitas dan ambang kandidat? | Duplikasi produksi | [DATA_MODEL](DATA_MODEL.md), [SEED](SEED.md) |

## Prosedur perubahan
Parameter rule existing: Admin mengajukan nilai, alasan dan versi expected; pihak berwenang sesuai Q-001 menyetujui; publikasikan versi baru dan audit before/after. Rule/logic/jenis dokumen/fitur baru melalui CR di [OPERATIONS](OPERATIONS.md). Jangan mengganti fakta komersial dengan keputusan teknis. Pembaruan keputusan disertai [ACCEPTANCE](ACCEPTANCE.md) dan [IMPLEMENTATION](IMPLEMENTATION.md).
