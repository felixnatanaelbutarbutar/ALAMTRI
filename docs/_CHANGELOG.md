# Catatan Riwayat Perubahan Dokumentasi (Changelog)
Tujuan file ini: mencatat setiap tindakan perbaikan yang dilakukan terhadap dokumentasi spesifikasi, dipetakan ke ID temuan audit.
Dibaca oleh / kapan dipakai: Project Manager, Lead Architect, dan auditor kualitas dokumentasi.

## Ringkasan Perubahan
Seluruh 32 temuan dari hasil audit mendalam (6 BLOCKER, 16 MAJOR, 10 MINOR) yang tercatat pada `docs/_AUDIT_REPORT.md` telah diperbaiki secara tuntas pada **Fase B (Perbaikan)**:
- **Penyusunan Berkas Pondasi Baru:** Menambahkan katalog aturan validasi deterministik formal `VALIDATION_RULES.md` dan matriks keterlacakan end-to-end `TRACEABILITY.md`.
- **Penguatan Standar Teknis:** Menghadirkan DDL SQL PostgreSQL lengkap dengan strategi partisi bulanan volume tinggi di `DATA_MODEL.md`, skema OpenAPI 3.1 dan katalog error terpusat di `API_CONTRACT.md`, serta template prompt lengkap dengan parameter inferensi di `PROMPTS.md`.
- **Penutupan Ambiguitas Bisnis:** Melengkapi seluruh 17 Open Questions di `DECISIONS.md` dengan *Default Usulan* konkret untuk mencegah hambatan pembangunan.
- **Standarisasi Pengujian & UI/UX:** Menyediakan kasus uji konkret `TC-xxx` dan pengujian beban 500k halaman di `SEED.md` & `TESTING.md`, wireframe ASCII di `UI.md`, skenario edge case di `UX.md`, dan runbook bulanan di `OPERATIONS.md`.
- **Otomasi Pemeriksa Integritas:** Memperbarui `check-docs.ps1` agar kompatibel penuh dengan Windows PowerShell dan memverifikasi seluruh aturan normatif.

---

## Tabel Riwayat Perubahan Detail

| ID Temuan Audit | Berkas yang Diubah | Kategori Perubahan | Ringkasan Tindakan Perbaikan yang Dilakukan |
|---|---|---|---|
| **AUD-01** | `check-docs.ps1` | BLOCKER | Memperbaiki bug path parsing `GetFullPath` pada Windows PowerShell; memperluas pemeriksaan ketat untuk ID keterlacakan (`US-`, `VR-`, `Q-`), validasi heading baru, dan deteksi kata terlarang di UI/UX. |
| **AUD-02** | `VALIDATION_RULES.md` | BLOCKER | Membuat dokumen baru yang mendefinisikan 9 aturan validasi deterministik (`VR-001` s.d. `VR-009`) lengkap dengan formula, pseudocode `Decimal`, normalisasi, toleransi konfigurasi, evidence wajib, dan template reasoning Bahasa Indonesia. |
| **AUD-03** | `TRACEABILITY.md` | BLOCKER | Membuat dokumen matriks keterlacakan end-to-end yang menghubungkan Tujuan Bisnis -> Fitur (`F-`) -> User Story (`US-`) -> Validation Rule (`VR-`) -> Endpoint (`API-`) -> Tabel DB -> Test Case (`TC-`) -> Acceptance (`A-`) -> Task (`T-`). |
| **AUD-04** | `DATA_MODEL.md` | BLOCKER | Menambahkan skrip DDL SQL PostgreSQL 16 lengkap (21 tabel, tipe ENUM, composite FK, CHECK constraint, index partial, dan strategi partisi bulanan untuk skala 500k halaman/bulan). |
| **AUD-05** | `API_CONTRACT.md` | BLOCKER | Menambahkan skema JSON Schema terstruktur, tabel katalog kode error terpusat (HTTP status & action), spesifikasi OpenAPI 3.1 YAML ringkas, dan penegasan status 404 `FEATURE_DISABLED` pada skema On-Premise. |
| **AUD-06** | `PROMPTS.md` | BLOCKER | Melengkapi prompt P-001 hingga P-004 dengan template system dan user utuh, parameter inferensi (`temperature: 0.0`), strategi chunking multi-halaman dokumen tebal, mitigasi prompt injection, dan 5 test case per prompt. |
| **AUD-07** | `PRD.md` | MAJOR | Menambahkan diagram Mermaid state machine dan tabel transisi lengkap (trigger, actor, guard, efek samping, audit event) untuk 5 entitas siklus hidup: case, document, exception, credit_period, dan export. |
| **AUD-08** | `UI.md` | MAJOR | Menambahkan wireframe visual ASCII untuk halaman daftar kasus `/cases`, antrean pengecualian `/exceptions`, pemantauan kredit `/credits`, dan komponen split-screen viewer dokumen dengan highlight evidence interaktif. |
| **AUD-09** | `UX.md` | MAJOR | Merinci alur end-to-end per persona, 5 skenario edge case (scan buram, berkas kurang, duplikasi, overage kuota, kegagalan worker/LLM), aturan prioritas antrean terukur, dan larangan penggunaan kata terlarang. |
| **AUD-10** | `DECISIONS.md` | MAJOR | Melengkapi seluruh 17 Open Questions (`Q-001` s.d. `Q-017`) dengan kolom Mengapa Penting, Default Usulan, Pihak Penjawab, Tenggat Waktu, dan Tindakan Fallback untuk unblock implementasi M0-M5. |
| **AUD-11** | Semua File | MAJOR | Melakukan standarisasi seluruh ID hierarkis (`F-xxx`, `US-xxx`, `VR-xxx`, `API-xxx`, `TC-xxx`, `A-xxx`, `T-xxx`, `D-xxx`, `Q-xxx`) secara seragam dan konsisten di seluruh repositori. |
| **AUD-12** | Semua File | MAJOR | Mengganti frasa kabur dengan ambang batas terukur dan menegakkan penggunaan kata normatif RFC 2119 (WAJIB, HARUS, SEBAIKNYA, BOLEH, DILARANG) di seluruh teks spesifikasi. |
| **AUD-13** | `TECH_STACK.md` | MAJOR | Menambahkan pemodelan ekonomi unit biaya inferensi LLM per halaman (~IDR 12,74/halaman) vs tarif overage IDR 500/kredit (gross margin 97,45%), tabel alternatif teknologi yang ditolak, dan panduan perintah CLI monorepo. |
| **AUD-14** | `PRD.md` | MAJOR | Menulis ulang seluruh user story ke format baku "Sebagai <peran>, saya ingin <aksi>, agar <manfaat>" dengan Given/When/Then, serta mencantumkan tabel NFR kuantitatif (throughput 700 hal/jam, p95 <= 30 dtk, availability 99.5%). |
| **AUD-15** | `SECURITY.md` | MAJOR | Merestrukturisasi threat model ke standar STRIDE ringkas, melengkapi tabel matriks otorisasi RBAC (4 peran x seluruh aksi API), serta menetapkan kontrol transmisi LLM eksternal (`ALLOW_EXTERNAL_LLM`). |
| **AUD-16** | `OPERATIONS.md` | MAJOR | Menambahkan runbook penutupan bulan (rumus tagihan `IDR 50 jt + overage * 500`), prosedur uji pemulihan restore drill, alur Change Request resmi, dan checklist kesiapan go-live & serah terima BAST Phase 1. |
| **AUD-17** | `SEED.md` & `TESTING.md` | MAJOR | Menghadirkan katalog kasus uji bernomor `TC-xxx` (TC-G01, TC-G02, TC-F01 s.d. TC-F09, TC-C01, TC-C02, TC-T01, TC-LOAD-01), protokol uji beban 500k halaman/bulan, dan kriteria merge gate CI/CD. |
| **AUD-18** | `ACCEPTANCE.md` | MAJOR | Menstandarisasi seluruh kriteria penerimaan ke kode `A-xxx` berbasis Given/When/Then yang dapat diuji otomatis, dipetakan ke US, VR, dan TC. |
| **AUD-19** | `IMPLEMENTATION.md` | MAJOR | Merinci setiap tugas implementasi (`T0.1` s.d. `T6.4`) dengan modul rencana spesifik, langkah-langkah implementasi, dan Definition of Done per tugas. |
| **AUD-20** | `AUDIT.md` | MAJOR | Melengkapi katalog event audit dengan skema payload metadata allowlist per aksi dan menjabarkan algoritma hash chain kriptografis `SHA256(prev_hash + canonical_json)`. |
| **AUD-21** | `README.md` | MINOR | Melengkapi kamus istilah glossary, memperbarui daftar peta dokumen arsitektur, dan menambahkan panduan eksekusi `check-docs.ps1` untuk Windows PowerShell dan pwsh. |
| **AUD-22** | `AGENTS.md` | MINOR | Menyediakan contoh konkret implementasi "BENAR vs SALAH" untuk aturan human-decision, evaluasi angka, dan idempotensi kredit, serta format baku laporan penyelesaian tugas. |
| **AUD-23** | `DATA_MODEL.md` | MINOR | Menyelaraskan nama tipe data dan representasi field antara DDL PostgreSQL dengan skema sumber daya `API_CONTRACT.md`. |
| **AUD-24** | `TECH_STACK.md` | MINOR | Memperjelas pohon struktur folder monorepo dengan penjelasan deskriptif per direktori kerja. |
| **AUD-25** | `PRD.md` | MINOR | Menambahkan rincian timeline dan peta kaitan tahapan implementasi 12 minggu Managed vs 16 minggu On-Premise. |
| **AUD-26** | `SECURITY.md` | MINOR | Menambahkan pembedaan penanganan enkripsi in-transit dan at-rest untuk mode Managed dan On-Premise. |
| **AUD-27** | `SEED.md` | MINOR | Menyertakan contoh konkret format berkas manifest JSON sintetis untuk pengujian otomatis. |
| **AUD-28** | `UI.md` | MINOR | Melengkapi tabel design token dengan hex color, nama kelas Tailwind CSS, dan rasio kontras WCAG AA. |
| **AUD-29** | `UX.md` | MINOR | Menyusun kamus microcopy pesan antarmuka terstandar dalam Bahasa Indonesia formal. |
| **AUD-30** | `OPERATIONS.md` | MINOR | Menambahkan tabel matriks penanganan insiden operasional beserta bukti verifikasi pemulihannya. |
| **AUD-31** | `TESTING.md` | MINOR | Menetapkan ambang batas target metrik kuantitatif (akurasi >= 85%, recall >= 95%, FPR <= 5%). |
| **AUD-32** | `DECISIONS.md` | MINOR | Menambahkan tanggal pengesahan dan otoritas penanggung jawab pada setiap baris Decision Log D-xxx. |
