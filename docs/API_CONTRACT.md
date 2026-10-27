# Kontrak REST API
Tujuan file ini: mendefinisikan endpoint, schema, akses dan perilaku error yang dapat diuji.
Dibaca oleh / kapan dipakai: agent API/frontend dan pembuat contract test sebelum implementasi.

## Konvensi kontrak
**Usulan D-009/D-013**, base `/api/v1`, UTF-8 JSON kecuali multipart/file. Token dari AuthProvider; login produksi Q-008. UUID/ISO-8601 UTC; nilai uang/qty berupa decimal string, bukan float; nullable eksplisit. Seluruh enum/field entitas mengikuti [DATA_MODEL](DATA_MODEL.md); schema ringkas di bawah adalah normatif, `?` opsional/nullable, `[]` array, field tidak dikenal ditolak 422. OpenAPI pada implementasi harus mengembangkan seluruh referensi schema, bukan membiarkan tipe any.

Akses: S=STAFF, P=APPROVER, A=ADMIN, O=OPS. S/P akses Finance dalam tenant dan scope case Q-008. A tidak mewarisi hak keputusan, O hanya health/job metadata tersanitasi. Semua resource tenant-scoped, pemeriksaan objek di server. Forbidden lintas tenant memberi 404, role salah dalam tenant memberi 403. Role tidak boleh dipilih dari body/token tak tervalidasi.

Mutasi menerima `Idempotency-Key` wajib (termasuk multipart, decision, export, reprocess, admin); retry actor+route+key+payload sama mengembalikan hasil awal, payload berbeda 409 IDEMPOTENCY_CONFLICT. Identitas ini bukan keputusan komersial billable. PATCH memakai `If-Match` version, konflik 409 STALE_VERSION. Pagination semua list: `page`>=1 default 1, `page_size` 1..100 default 25 (usulan teknis), envelope `{items:[],page,page_size,total}`; order stabil `created_at,id`. Query tak dikenal 422. Envelope single `{data:Resource,request_id:uuid}`; 202 berisi job_id dan status_url. Tidak ada endpoint approval otomatis, ERP, pembayaran, vendors master atau pembuatan rule logic.

## Schema sumber daya
| Nama | Field wajib / opsional |
|---|---|
| User | id:uuid,name:string,email:string,role:enum,active:boolean,version:int |
| Case | id:uuid,case_number:string,processing_status:enum,validation_status:enum/null,total_pages:int,current_run_id:uuid/null,version:int,created_at:timestamp |
| Document | id:uuid,case_id:uuid,doc_type:enum,filename:string,mime_type:string,page_count:int,state:enum,sha256:string,error_code:string/null,extraction:Extraction/null |
| Extraction | id:uuid,model_id:string,prompt_version:string,schema_version:string,header:Header,line_items:LineItem[],evidence:Evidence[],quality_flags:string[] |
| Header / LineItem | Seluruh field doc_headers/doc_line_items di DATA_MODEL kecuali tenant/DB metadata; numeric -> decimal string/null; references_json -> references {po,dn,gr,bast:string/null} |
| Evidence | id:uuid,extraction_id:uuid,document_id:uuid,page_number:int,field_path:string,value:JSON scalar/null,bbox:number[4]/null |
| Validation | id:uuid,case_id:uuid,status:enum,overall_status:enum/null,rules_snapshot:{code,rule_version,params}[],extraction_ids:uuid[],results:Result[],finished_at:timestamp/null |
| Result | id:uuid,rule_code:string,rule_version:int,outcome:enum,reason_code:string,reasoning:string,computed_values:object scalar decimal strings,evidence:Evidence[] |
| Exception | id:uuid,case_id:uuid,run_id:uuid,result_id:uuid,type:enum,severity:enum,state:enum,summary:string,assigned_to:uuid/null,created_at:timestamp,version:int |
| Decision | id:uuid,case_id:uuid,run_id:uuid,decided_by:uuid,decision:enum,note:string,supersedes_id:uuid/null,decided_at:timestamp |
| Job | id:uuid,status:enum,attempt:int,failure_code:string/null,created_at:timestamp,completed_at:timestamp/null |
| Export | id:uuid,status:enum,format:CSV/XLSX,run_ids:uuid[],expires_at:timestamp/null,download_url:string/null |
| CreditSummary | period_key:string,starts_at:timestamp,ends_at:timestamp,quota:int,used:int,remaining:int,overage:int,estimated_base_idr:string,estimated_additional_idr:string,estimated_total_idr:string,state:OPEN/CLOSED,policy_version:string |
| Notification | id:uuid,period_key:string,type:enum,read_at:timestamp/null,created_at:timestamp |
| Rule | id:uuid,code:string,rule_version:int,params:object,active:boolean,severity:enum,description:string |
| AuditEntry | id:uuid,actor_id:uuid/null,actor_type:enum,action:string,entity_type:string,entity_id:uuid/null,metadata:allowlisted object,occurred_at:timestamp,request_id:uuid |
Case detail ajoute `documents:Document[]`, `latest_decision:Decision/null`. Document extraction harus versi aktif; riwayat dapat dipilih `extraction_id` yang sah. Tidak pernah mengekspos object_key, password_hash, secret atau raw model input. `computed_values` keys ditetapkan per rule di schema konfigurasi, bukan arbitrary log payload.

## Endpoint identitas dan konfigurasi
| Method/path | RBAC | Request | Response |
|---|---|---|---|
| POST `/auth/login` | Publik terbatas rate limit, adapter lokal dev saja | {email:string,password:string} | 200 {access_token:string,token_type:Bearer,expires_in:int}; mode produksi nonlokal 404 FEATURE_DISABLED |
| POST `/auth/logout` | S/P/A/O | {} | 200 {logged_out:true}; revoke session/token sesuai adapter |
| GET `/auth/me` | S/P/A/O | — | 200 User |
| GET `/capabilities` | S/P/A/O | — | 200 {deployment_mode:managed/onprem,credit_enabled:bool,export_formats:string[],upload_limits:{max_bytes:int,max_pages:int,mime_types:string[]},policy_ready:bool} |
SSO flow via adapter AuthProvider; URL/callback/issuer contract ditetapkan sesudah Q-008, jangan membuat konektor sistem bisnis internal. Password tidak masuk audit/log.

## Case, dokumen dan job
| Method/path | RBAC | Request | Response |
|---|---|---|---|
| POST `/cases` | S/P | {} | 201 Case; case_number server generated |
| GET `/cases` | S/P | filter processing_status,validation_status,date_from,date_to,vendor_query; sort created_at/-created_at | 200 paged Case |
| GET `/cases/{id}` | S/P | — | 200 Case detail |
| POST `/cases/{id}/documents` | S/P | multipart `file` satu file/request, `doc_type` hint opsional | 202 {document_id,job_id,status_url}; file banyak memakai request per file |
| GET `/documents/{id}` | S/P | extraction_id? | 200 Document |
| GET `/documents/{id}/pages/{n}/image` | S/P | n integer>=1 | 200 image/png; Cache-Control private,no-store; halaman di luar range 404 |
| GET `/jobs/{id}` | S/P; O sanitized | — | 200 Job; hanya job dari resource yang diizinkan |
| POST `/cases/{id}/reprocess` | S/P | {expected_version:int,reason:string} | 202 {job_id,status_url}; policy billable Q-011, 409 POLICY_UNRESOLVED bila belum diputuskan |
No hard delete sampai Q-005. Upload limit/MIME Q-002; inspect magic bytes, malware quarantine, PDF password/malformed 422 UNREADABLE_DOCUMENT; konten tidak aman 422 UNSAFE_FILE. Kebijakan file campuran Q-006, tidak membagi otomatis tanpa persetujuan. Model failure tidak membuang dokumen; retry job sama tidak membuat upload baru. Status polling GET, tanpa kewajiban websocket.

## Validasi dan review
| Method/path | RBAC | Request | Response |
|---|---|---|---|
| GET `/cases/{id}/validation` | S/P | run_id? default current | 200 Validation; belum ada run 200 {data:null,request_id} |
| GET `/exceptions` | S/P | state,type,severity,case_id; sort severity/-created_at | 200 paged Exception |
| PATCH `/exceptions/{id}` | S/P | {state:enum,assigned_to:uuid/null,expected_version:int}; tidak mengubah severity | 200 Exception; audit perubahan |
| POST `/cases/{id}/decisions` | P manusia | {run_id:uuid,expected_case_version:int,decision:enum,note:string,supersedes_id:uuid/null} | 201 Decision |
| GET `/cases/{id}/decisions` | S/P | — | 200 paged Decision |
Run harus selesai dan current; run stale 409 STALE_RUN, processing 409 INVALID_STATE. Note nonempty, escaped saat render. Keputusan tersimpan append-only bersama audit dalam satu transaksi. System/service token selalu 403 HUMAN_REQUIRED bahkan bila mengklaim role. Perubahan keputusan sesuai Q-015 dan tidak mengeksekusi pembayaran. PATCH exception RESOLVED tidak menghasilkan decision.

## Export, credit dan notifikasi
| Method/path | RBAC | Request | Response |
|---|---|---|---|
| POST `/exports` | S/P | {case_ids:uuid[],format:CSV/XLSX}; kandidat format Q-003 | 202 {export_id,job_id,status_url}; seluruh case harus authorized, snapshot current run IDs |
| GET `/exports/{id}` | Pemohon S/P | — | 200 Export; download_url berupa same-origin `/api/v1/exports/{id}/download` bila READY |
| GET `/exports/{id}/download` | Pemohon S/P | — | 200 file, attachment, no-store; expired 410 EXPORT_EXPIRED |
| GET `/credits/current` | A | — | 200 CreditSummary |
| GET `/credits/history` | A | period_from?,period_to? | 200 paged CreditSummary |
| GET `/notifications` | A, recipient sendiri | unread? | 200 paged Notification |
| POST `/notifications/{id}/read` | A recipient | {} | 200 Notification |
Onprem: seluruh `/credits/*` dan quota `/notifications*` 404 FEATURE_DISABLED, tidak membuat ledger/quota notification; page_count statistik tetap ada. Managed: overage tidak memberi 402/429 karena kuota. 429 hanya rate/security/capacity dengan retry-after, tidak dipicu credit. Billing summary formula [OPERATIONS](OPERATIONS.md), bukan invoice pembayaran; policy unresolved memberi 409 POLICY_UNRESOLVED untuk operasi billable produksi. Export field/format final Q-003, expiry Q-005; CSV formula injection ditangani.

## Admin dan operasi
| Method/path | RBAC | Request | Response |
|---|---|---|---|
| GET `/admin/users` | A | role?,active? | 200 paged User |
| POST `/admin/users` | A | {subject,name,email,role,active} | 201 User; password provision lewat auth adapter |
| PATCH `/admin/users/{id}` | A | {name?,role?,active?,expected_version:int} | 200 User; subject immutable; cegah menonaktifkan Admin aktif terakhir |
| GET `/admin/rules` | A | code?,active? | 200 paged Rule |
| PATCH `/admin/rules/{id}/params` | A | {params:typed rule params,expected_rule_version:int,reason:string,approval_reference:string} | 201 Rule versi baru; schema param/range disepakati Q-001; logic/code/active tak boleh lewat body |
| GET `/admin/audit` | A | action?,entity_id?,date_from?,date_to? | 200 paged AuditEntry |
| GET `/ops/health` | O | — | 200 {api:UP/DOWN,db:UP/DOWN,queue:UP/DOWN,storage:UP/DOWN,model:UP/DOWN} atau 503 |
| GET `/ops/jobs` | O | status?,kind? | 200 paged Job, tanpa filename/data finansial |
| POST `/ops/jobs/{id}/retry` | O | {reason:string,expected_attempt:int} | 202 Job; hanya failure teknis, run versioned dan ledger event sama |
Rule baru dan aktivasi logic melalui CR/release, bukan endpoint CRUD rule. Ops tidak menulis review_decisions. Semua write dan akses sensitif dicatat sesuai [AUDIT](AUDIT.md).

## Error dan versioning
```json
{"error":{"code":"STALE_RUN","message":"Hasil berubah. Muat ulang sebelum mencatat keputusan.","details":{"current_run_id":"00000000-0000-4000-8000-000000000001"}},"request_id":"00000000-0000-4000-8000-000000000002"}
```
400 INVALID_REQUEST; 401 UNAUTHENTICATED; 403 FORBIDDEN/HUMAN_REQUIRED; 404 NOT_FOUND/FEATURE_DISABLED; 409 IDEMPOTENCY_CONFLICT/STALE_VERSION/STALE_RUN/INVALID_STATE/POLICY_UNRESOLVED; 410 EXPORT_EXPIRED; 413 FILE_TOO_LARGE; 415 UNSUPPORTED_MEDIA; 422 SCHEMA_INVALID/UNREADABLE_DOCUMENT/UNSAFE_FILE; 429 RATE_LIMITED; 503 SERVICE_UNAVAILABLE. Error tidak menyalin isi dokumen/model response. Retryable response menyertakan Retry-After; limit retry konfigurasi Q-009.

Contoh data sintetis untuk response validation (envelope ringkas):
```json
{"data":{"id":"00000000-0000-4000-8000-000000000003","case_id":"00000000-0000-4000-8000-000000000004","status":"COMPLETED","overall_status":"NEEDS_REVIEW","rules_snapshot":[{"code":"TOTAL_COMPARE","rule_version":1,"params":{"tolerance":"0"}}],"extraction_ids":["00000000-0000-4000-8000-000000000005"],"results":[{"id":"00000000-0000-4000-8000-000000000006","rule_code":"TOTAL_COMPARE","rule_version":1,"outcome":"FAIL","reason_code":"TOTAL_DIFF","reasoning":"Nilai total pada invoice dan PO berbeda; periksa sumber.","computed_values":{"invoice_total":"110000000","po_total":"100000000","difference":"10000000"},"evidence":[{"id":"00000000-0000-4000-8000-000000000007","extraction_id":"00000000-0000-4000-8000-000000000005","document_id":"00000000-0000-4000-8000-000000000008","page_number":1,"field_path":"total_amount","value":"110000000","bbox":null}]}],"finished_at":"2026-10-27T00:00:00Z"},"request_id":"00000000-0000-4000-8000-000000000009"}
```
Nilai toleransi contoh bukan rule PT SIS. Produksi setiap perbandingan memiliki evidence kedua sumber atau explicit missing source. Perubahan breaking ke `/api/v2`; additive nullable field backward compatible, client mengabaikan response unknown fields. Uji kontrak mengikuti [TESTING](TESTING.md); implementasi di [IMPLEMENTATION](IMPLEMENTATION.md).
