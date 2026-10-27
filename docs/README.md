# AI-Based Invoice Intelligence Platform
Tujuan file ini: menjadi pintu masuk spesifikasi tunggal proyek PT SIS.
Dibaca oleh / kapan dipakai: semua agent dan reviewer sebelum merencanakan implementasi.

## Status dan sumber
Dokumentasi pra-pengembangan, berdasarkan instruksi turunan Proposal Document Version 2, 26 Oktober 2026. Proposal asli tidak dilampirkan; jangan menganggap rincian tambahan telah disetujui. Klien: PT Saptaindra Sejati (PT SIS). Vendor: INaAI, PT Teknologi Cerdas Berdaulat Indonesia, AXA Tower Lt. 45, Kuningan, Jakarta Selatan. Platform membantu pembacaan dan validasi invoice dari unggahan; keputusan akhir dan otorisasi pembayaran milik manusia PT SIS. Paket ini hanya dokumentasi dan skrip pemeriksa, tanpa kode aplikasi.

## Urutan baca dan peta dokumen
| Urutan | Dokumen | Isi |
|---|---|---|
| 1 | [AGENTS](AGENTS.md) | Aturan mutlak dan Definition of Done |
| 2 | [PRD](PRD.md) | Produk, scope, persona, story, komersial |
| 3 | [DECISIONS](DECISIONS.md) | Fakta proposal, usulan, seluruh Open Questions |
| 4 | [TECH_STACK](TECH_STACK.md) | Stack usulan, versi, adapter, environment |
| 5 | [DATA_MODEL](DATA_MODEL.md) | Tabel, constraint, ERD, migrasi |
| 6 | [API_CONTRACT](API_CONTRACT.md) | REST, schema, RBAC, error |
| 7 | [PROMPTS](PROMPTS.md) | Prompt versioned dan schema keluaran |
| 8 | [UI](UI.md) | Halaman, komponen, state, tokens |
| 9 | [UX](UX.md) | Journey, antrean, microcopy, aksesibilitas |
| 10 | [SECURITY](SECURITY.md) | Ancaman, akses, perlindungan data |
| 11 | [AUDIT](AUDIT.md) | Jejak sistem dan keputusan manusia |
| 12 | [OPERATIONS](OPERATIONS.md) | Deployment, maintenance, credit, pemulihan |
| 13 | [SEED](SEED.md) | Fixture sintetis dan rule contoh |
| 14 | [TESTING](TESTING.md) | Strategi, metrik, gate |
| 15 | [ACCEPTANCE](ACCEPTANCE.md) | Kriteria penerimaan dan pemetaan story |
| 16 | [IMPLEMENTATION](IMPLEMENTATION.md) | Milestone dan tugas dengan dependensi |
| 17 | [check-docs.ps1](check-docs.ps1) | Pemeriksa integritas dokumentasi |

## Konvensi
Semua spesifikasi teknis berstatus **Usulan**, lihat D-002, D-003, D-007, D-009 sampai D-013 di [DECISIONS](DECISIONS.md). Hanya baris Disetujui-proposal yang merupakan fakta bisnis dari instruksi. [TBD] berarti belum diketahui, bukan nilai default. Dokumen terkait wajib dibaca bersama; konflik menghentikan pekerjaan yang bergantung pada keputusan tersebut.

## Glossary
| Istilah | Makna tunggal |
|---|---|
| Case | Bundel unggahan terkait satu invoice untuk pemeriksaan; bukan transaksi pembayaran |
| Document | Satu file unggahan; pemisahan dokumen campuran belum diputuskan, Q-006 |
| Page | Halaman file yang berhasil dihitung oleh ingestion, bukan jumlah token atau render ulang |
| Credit | Unit komersial Managed: 1 credit = 1 halaman; pemicu penagihan lihat Q-011 |
| Evidence | Rujukan versi ekstraksi, dokumen, halaman, field dan opsional bounding box yang mendukung hasil |
| Exception | Pengecualian pemeriksaan: selisih, informasi hilang, potensi duplikasi |
| Validation status | Ringkasan pemeriksaan sistem; bukan keputusan invoice |
| Review decision | Catatan keputusan manusia berwenang PT SIS, tanpa eksekusi pembayaran |
| PO | Purchase Order, dokumen pesanan yang diunggah |
| DN | Delivery Note, dokumen pengiriman yang diunggah |
| GR | Goods Receipt, dokumen penerimaan yang diunggah |
| BAST dokumen | Berita Acara Serah Terima pendukung invoice |
| BAST Phase 1 | Berita acara penerimaan implementasi platform; berbeda dari BAST dokumen |
| Additional Usage | Credit Managed di atas 50.000 per periode bulanan |
| Rule | Logic validasi terpusat dengan parameter versioned |
| Change Request (CR) | Persetujuan perubahan scope/logic/fitur, bukan perubahan parameter biasa |
| Soft delete | Sembunyikan data operasional tanpa menghapus riwayat immutable |
| INaAI Ops | Operator layanan; bukan Approver invoice |

## Batas lingkup bersama
Batas normatif untuk seluruh file: delapan pengecualian di [PRD](PRD.md#out-of-scope). Tidak ada integrasi ERP/pembayaran, pembuatan PO, pengelolaan vendor, keputusan sistem, atau penilaian fraud/pajak/hukum. Source code tidak diserahkan dalam kedua skema. Semua contoh data wajib sintetis.
