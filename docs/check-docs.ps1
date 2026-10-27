# Tujuan file ini: memeriksa integritas dokumentasi arsitektur tanpa dependensi aplikasi.
# Dibaca oleh / kapan dipakai: agent pembangun dan pipeline CI/CD setelah modifikasi docs/.
# Jalankan: powershell -NoProfile -ExecutionPolicy Bypass -File docs/check-docs.ps1
# Atau:    pwsh -NoProfile -File docs/check-docs.ps1

[CmdletBinding()]
param([string]$DocsPath = '')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DocsPath)) {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $DocsPath = $PSScriptRoot
    } elseif (Test-Path -LiteralPath (Join-Path (Get-Location).Path 'docs') -PathType Container) {
        $DocsPath = Join-Path (Get-Location).Path 'docs'
    } else {
        $DocsPath = (Get-Location).Path
    }
}
$root = [IO.Path]::GetFullPath($DocsPath)

$issues = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$checks = 0

$required = [ordered]@{
    'README.md' = @('Status dan sumber', 'Urutan baca dan peta dokumen', 'Glossary', 'Batas lingkup bersama')
    'AGENTS.md' = @('Aturan Mutlak', 'Alur kerja per tugas', 'Kapan wajib bertanya kepada manusia', 'Definition of Done', 'Bahasa dan pemeliharaan spesifikasi')
    'PRD.md' = @('Masalah dan tujuan', 'Persona dan akses usulan', 'Fitur dan user stories', 'Status dan aturan perilaku', 'In scope', 'Out of scope', 'Model komersial', 'Timeline implementasi', 'Asumsi dan metrik sukses')
    'TECH_STACK.md' = @('Status dan versi', 'Struktur monorepo usulan', 'Deployment dan adapter', 'Environment template')
    'DATA_MODEL.md' = @('Konvensi skema', 'Tabel dan kolom', 'ERD', 'Aturan transaksi dan proses pemakai', 'Retensi dan migrasi')
    'API_CONTRACT.md' = @('Konvensi kontrak', 'Schema sumber daya', 'Endpoint identitas dan konfigurasi', 'Case, dokumen dan job', 'Validasi dan review', 'Export, credit dan notifikasi', 'Admin dan operasi', 'Error dan versioning')
    'PROMPTS.md' = @('Kebijakan bersama', 'Schema dasar JSON', 'P-001 Klasifikasi 1.0.0', 'P-002 Ekstraksi 1.0.0', 'P-004 Pencocokan Semantik Line Item 1.0.0', 'P-003 Penjelasan Validasi 1.0.0', 'Failure dan evaluasi')
    'UI.md' = @('Prinsip dan design tokens', 'Halaman dan tabel', 'Viewer dan evidence', 'State wajib')
    'UX.md' = @('Alur end-to-end', 'Journey per persona', 'Prioritas antrean', 'Microcopy dan notifikasi', 'Recovery dan aksesibilitas')
    'SECURITY.md' = @('Klasifikasi dan batas', 'Threat model (STRIDE)', 'RBAC dan autentikasi', 'Enkripsi dan secret', 'Logging dan isolasi', 'Retensi dan LLM', 'Gate keamanan')
    'AUDIT.md' = @('Batas dan format', 'Event wajib', 'Immutability dan akses', 'Keputusan manusia dan jejak versi', 'Laporan minimum')
    'OPERATIONS.md' = @('Batas dan prasyarat', 'Deployment Managed', 'On-Premise', 'Environment dan readiness', 'Credit metering dan penutupan bulan', 'Backup, restore dan monitoring', 'Runbook insiden', 'Maintenance Phase 2', 'Change Request dan handover')
    'SEED.md' = @('Batas seed', 'Tenant dan user demo', 'Rule awal untuk fixture', 'Dataset golden dan faults', 'Cara membuat dokumen sintetis')
    'TESTING.md' = @('Lapisan uji', 'Tes wajib', 'Dataset dan evaluasi AI', 'Metrik', 'Gate sebelum merge dan UAT')
    'ACCEPTANCE.md' = @('Aturan sign-off', 'Upload dan pemrosesan', 'Ekstraksi', 'Validasi', 'Human control', 'Dashboard dan ekspor', 'Credit', 'Kinerja dan keandalan', 'Serah terima', 'Keamanan dan administrasi', 'Matriks cakupan dan keputusan penerimaan')
    'IMPLEMENTATION.md' = @('Konvensi dan dependensi', 'M0 Fondasi', 'M1 Ingestion dan extraction', 'M2 Validation Engine', 'M3 Dashboard', 'M4 Hardening dan UAT', 'M5 Operational Adoption dan Go-Live', 'M6 On-Premise', 'Definition of milestone done')
    'DECISIONS.md' = @('Decision Log', 'Open Questions', 'Prosedur perubahan')
    'VALIDATION_RULES.md' = @('Prinsip dan kebijakan validasi', 'Aturan agregasi status validasi', 'Parameter konfigurasi terpusat', 'Aturan normalisasi data', 'Katalog aturan validasi', 'Penanganan exception dan prioritas')
    'TRACEABILITY.md' = @('Prinsip Keterlacakan', 'Konvensi Standar Identifier', 'Matriks Keterlacakan Komprehensif', 'Matriks Pemetaan Aturan Validasi ke Test Case & Acceptance', 'Verifikasi Integritas Matriks')
    '_AUDIT_REPORT.md' = @('Ringkasan Eksekutif', 'Tabel Temuan Audit Lengkap', 'Dry-Run Builder Agent (Simulasi Membangun M0 - M5)', 'Tabel Skor Dokumen Sebelum Perbaikan', 'Rencana Aksi Perbaikan (Fase B)')
    '_CHANGELOG.md' = @('Ringkasan Perubahan', 'Tabel Riwayat Perubahan Detail')
    'check-docs.ps1' = @()
}

function Add-Issue([string]$msg) { $issues.Add($msg) }
function Add-Warn([string]$msg) { $warnings.Add($msg) }

function Get-Prose([string]$content) {
    return [regex]::Replace($content, '(?ms)^```[^\r\n]*\r?\n.*?^```\s*$', '')
}

function Get-Slug([string]$heading) {
    $s = $heading.Trim().ToLowerInvariant() -replace '[^\p{L}\p{Nd}_\-\s]', ''
    return $s -replace '\s+', '-'
}

$contents = @{}
$headings = @{}

try {
    # 1. PEMERIKSAAN KEBERADAAN FILE, HEADING, DAN PLACEHOLDER
    foreach ($name in $required.Keys) {
        $checks++
        $path = Join-Path $root $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Add-Issue "File wajib hilang: $name"
            continue
        }
        if ($name -eq 'check-docs.ps1') { continue }
        
        $raw = Get-Content -LiteralPath $path -Raw -Encoding utf8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            Add-Issue "${name}: File kosong"
            continue
        }
        
        $contents[$name] = $raw
        $prose = Get-Prose $raw
        $hs = @([regex]::Matches($prose, '(?m)^#{1,6}\s+(.+?)\s*#*\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() })
        $headings[$name] = $hs
        
        foreach ($h in $required[$name]) {
            $checks++
            $found = $false
            foreach ($existingH in $hs) {
                if ($existingH -like "*$h*") { $found = $true; break }
            }
            if (-not $found) {
                Add-Issue "${name}: Heading wajib hilang atau tidak cocok: $h"
            }
        }
        
        $checks++
        if ($raw -notmatch '(?m)^Tujuan file ini:' -or $raw -notmatch '(?m)^Dibaca oleh / kapan dipakai:') {
            Add-Issue "${name}: Ringkasan awal wajib (Tujuan / Dibaca oleh) tidak lengkap"
        }
        
        # Pemeriksaan placeholder tanpa penanda [TBD]
        $lineNo = 0
        foreach ($line in ($raw -split '\r?\n')) {
            $lineNo++
            $checks++
            if ($line -match '(?i)\b(TODO|FIXME|lorem|ipsum|TBA)\b') {
                Add-Issue "${name}:${lineNo}: Ditemukan placeholder terlarang ($($Matches[1]))"
            }
            if ($line -match '(?i)\bTBD\b' -and $line -notmatch '\[TBD\]') {
                Add-Issue "${name}:${lineNo}: TBD ditemukan tanpa penanda kurung siku formal [TBD]"
            }
        }
    }

    # 2. PEMERIKSAAN TAUTAN RELATIF DAN ANCHOR
    foreach ($name in $contents.Keys) {
        $prose = Get-Prose $contents[$name]
        foreach ($match in [regex]::Matches($prose, '(?<!\!)\[[^\]\r\n]+\]\(([^)\r\n]+)\)')) {
            $checks++
            $target = $match.Groups[1].Value.Trim().Trim('<','>')
            if ($target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' -or $target.StartsWith('//')) { continue }
            
            $parts = $target -split '#', 2
            $rel = $parts[0].Trim()
            
            $targetPath = $null
            try {
                if ([string]::IsNullOrEmpty($rel)) {
                    $targetPath = Join-Path $root $name
                } else {
                    $cleanRel = [Uri]::UnescapeDataString($rel).Replace('/', [IO.Path]::DirectorySeparatorChar)
                    $targetPath = [IO.Path]::GetFullPath((Join-Path $root $cleanRel))
                }
            } catch {
                Add-Issue "${name}: Tautan dengan path tidak valid '$target': $($_.Exception.Message)"
                continue
            }
            
            if (-not $targetPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                Add-Issue "${name}: Tautan mengarah keluar folder docs/: $target"
                continue
            }
            if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
                Add-Issue "${name}: Tautan relatif rusak (file tidak ada): $target"
                continue
            }
            
            if ($parts.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace($parts[1]) -and [IO.Path]::GetExtension($targetPath) -eq '.md') {
                $destName = [IO.Path]::GetFileName($targetPath)
                $destHeadings = if ($headings.ContainsKey($destName)) { $headings[$destName] } else { @() }
                $slugs = @($destHeadings | ForEach-Object { Get-Slug $_ })
                $anchor = [Uri]::UnescapeDataString($parts[1].Trim().ToLowerInvariant())
                
                $anchorFound = $false
                foreach ($slug in $slugs) {
                    if ($slug -eq $anchor -or $slug -like "*$anchor*") { $anchorFound = $true; break }
                }
                if (-not $anchorFound) {
                    # Anchor check warning/issue
                    Add-Warn "${name}: Anchor mungkin tidak persis sama: #$anchor di $destName"
                }
            }
        }
    }

    # 3. VERIFIKASI USER STORIES ANTARA PRD, ACCEPTANCE, DAN TRACEABILITY
    if ($contents.ContainsKey('PRD.md') -and $contents.ContainsKey('ACCEPTANCE.md')) {
        $prdStories = @([regex]::Matches($contents['PRD.md'], '\bUS-[A-Z]+-\d{2}\b') | ForEach-Object Value | Sort-Object -Unique)
        $accStories = @([regex]::Matches($contents['ACCEPTANCE.md'], '\bUS-[A-Z]+-\d{2}\b') | ForEach-Object Value | Sort-Object -Unique)
        $trcStories = if ($contents.ContainsKey('TRACEABILITY.md')) {
            @([regex]::Matches($contents['TRACEABILITY.md'], '\bUS-[A-Z]+-\d{2}\b') | ForEach-Object Value | Sort-Object -Unique)
        } else { @() }

        if ($prdStories.Count -eq 0) { Add-Issue 'PRD.md: Tidak ditemukan ID User Story (US-*)' }
        foreach ($id in $prdStories) {
            $checks++
            if ($accStories -notcontains $id) { Add-Issue "ACCEPTANCE.md: User story tidak terpetakan: $id" }
            if ($trcStories -notcontains $id) { Add-Issue "TRACEABILITY.md: User story tidak terpetakan: $id" }
        }
    }

    # 4. VERIFIKASI VALIDATION RULES (VR-*)
    if ($contents.ContainsKey('VALIDATION_RULES.md')) {
        $vrRules = @([regex]::Matches($contents['VALIDATION_RULES.md'], '\bVR-\d{3}\b') | ForEach-Object Value | Sort-Object -Unique)
        if ($vrRules.Count -eq 0) { Add-Issue 'VALIDATION_RULES.md: Tidak ditemukan definisi aturan (VR-*)' }
        
        $testContent = if ($contents.ContainsKey('TESTING.md')) { $contents['TESTING.md'] } else { '' }
        $trcContent = if ($contents.ContainsKey('TRACEABILITY.md')) { $contents['TRACEABILITY.md'] } else { '' }
        
        foreach ($vr in $vrRules) {
            $checks++
            if ($testContent -notmatch [regex]::Escape($vr)) { Add-Issue "TESTING.md: Aturan $vr tidak diuji di strategi pengujian" }
            if ($trcContent -notmatch [regex]::Escape($vr)) { Add-Issue "TRACEABILITY.md: Aturan $vr tidak terdaftar dalam matriks" }
        }
    } else {
        Add-Issue "File kritis VALIDATION_RULES.md belum ada"
    }

    # 5. VERIFIKASI TUGAS IMPLEMENTATION.MD
    if ($contents.ContainsKey('IMPLEMENTATION.md')) {
        $taskRows = @([regex]::Matches($contents['IMPLEMENTATION.md'], '(?m)^\|\s*(\*{0,2}T[0-6]\.[1-9]\d*\*{0,2})\s*\|\s*\[\s*\]'))
        $taskIds = @()
        foreach ($row in $taskRows) {
            $checks++
            $rawId = $row.Groups[1].Value.Trim().Replace('*', '')
            if ($rawId -notmatch '^T[0-6]\.[1-9]\d*$') { Add-Issue "IMPLEMENTATION.md: Format ID tugas salah: $rawId" }
            $taskIds += $rawId
        }
        if ($taskRows.Count -eq 0) { Add-Issue 'IMPLEMENTATION.md: Tidak ada tugas yang terdefinisi' }
        foreach ($g in ($taskIds | Group-Object | Where-Object Count -gt 1)) {
            Add-Issue "IMPLEMENTATION.md: ID tugas duplikat: $($g.Name)"
        }
    }

    # 6. VERIFIKASI OPEN QUESTIONS (Q-*) DI DECISIONS.MD
    if ($contents.ContainsKey('DECISIONS.md')) {
        $decContent = $contents['DECISIONS.md']
        $qIds = @([regex]::Matches($decContent, '(?m)^\|\s*\*{0,2}(Q-\d{3})\*{0,2}\s*\|') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
        
        $otherDocsCombined = ($contents.Keys | Where-Object { $_ -ne 'DECISIONS.md' } | ForEach-Object { $contents[$_] }) -join "`n"
        
        foreach ($qid in $qIds) {
            $checks++
            if ($otherDocsCombined -notmatch [regex]::Escape($qid)) {
                Add-Issue "DECISIONS.md: Open Question $qid tidak dirujuk oleh dokumen terdampak lain"
            }
        }
    }

    # 7. PEMERIKSAAN KATA TERLARANG DI UI/UX
    foreach ($uiDoc in @('UI.md', 'UX.md')) {
        if ($contents.ContainsKey($uiDoc)) {
            $lines = $contents[$uiDoc] -split '\r?\n'
            $lNum = 0
            foreach ($l in $lines) {
                $lNum++
                $checks++
                # Cek jika baris bukan baris aturan/larangan atau blacklist
                if ($l -notmatch '(?i)(DILARANG|Blacklist|Larangan|larangan|Kamus|terminologi|kata-kata|kata terlarang)' -and $l -notmatch '(?i)Bukan') {
                    if ($l -match '(?i)\b(fraud|penipuan|layak bayar|ditolak otomatis)\b') {
                        Add-Issue "${uiDoc}:${lNum}: Ditemukan penggunaan frasa terlarang: '$($Matches[1])'"
                    }
                }
            }
        }
    }

} catch {
    Add-Issue "Pemeriksaan skrip terhenti karena exception: $($_.Exception.Message)"
}

Write-Output "============================================================"
Write-Output "HASIL PEMERIKSAAN INTEGRITAS DOKUMENTASI (check-docs.ps1)"
Write-Output "============================================================"
Write-Output "Total Dokumen Wajib : $($required.Count)"
Write-Output "Total Titik Cek     : $checks"
Write-Output "Total Peringatan    : $($warnings.Count)"
Write-Output "Total Temuan Error  : $($issues.Count)"
Write-Output "------------------------------------------------------------"

if ($warnings.Count -gt 0) {
    foreach ($w in $warnings) { Write-Output "WARN: $w" }
    Write-Output "------------------------------------------------------------"
}

if ($issues.Count -gt 0) {
    foreach ($err in $issues) { Write-Output "FAIL: $err" }
    Write-Output "============================================================"
    Write-Output "STATUS: GAGAL (Terdapat $($issues.Count) pelanggaran integritas)"
    exit 1
}

Write-Output "STATUS: PASS (Seluruh file, heading, ID, keterlacakan, dan aturan integritas terpenuhi 100%)"
Write-Output "============================================================"
exit 0
