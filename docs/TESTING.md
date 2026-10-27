# TESTING.md

## Lapisan Uji
| Lapisan | Alat | Cakupan |
|---|---|---|
| Unit | pytest, Vitest | Rule engine, normalisasi angka/tanggal, hitung credit, RBAC |
| Integrasi | pytest + Docker | Upload -> worker -> DB; API contract |
| E2E | Playwright | Alur Finance: upload -> review -> keputusan -> ekspor |
| Regression AI | Skrip evaluasi | Akurasi ekstraksi dan deteksi selisih pada dataset sampel |

## Prinsip
- Rule validasi dievaluasi deterministik oleh kode, jadi wajib punya unit test per rule (lolos, gagal, data hilang, di batas toleransi).
- Panggilan LLM dimock pada unit/integrasi test; uji nyata hanya di regression AI.
- Tidak ada dokumen asli PT SIS di repo. Gunakan dokumen sintetis atau yang sudah dianonimkan.

## Dataset Evaluasi
- `golden/` berisi dokumen + JSON ekspektasi (field benar).
- Sertakan: variasi format vendor, scan buram, halaman miring, multi-halaman, item banyak.
- `faults/` berisi kasus yang disuntik selisih: total berbeda, qty lebih, harga beda, referensi hilang, invoice duplikat.

## Metrik
- Field-level accuracy (per field kunci)
- Fault detection recall dan false positive rate
- Rata-rata waktu per halaman
- Biaya LLM per halaman (pantau terhadap tarif IDR 500/credit)

## Wajib Sebelum Merge
- Lint + unit + integrasi lulus
- Regression AI tidak turun dari baseline jika prompt/model diubah
- Tes RBAC: STAFF tidak bisa memutuskan, hanya APPROVER
- Tes idempotensi credit
