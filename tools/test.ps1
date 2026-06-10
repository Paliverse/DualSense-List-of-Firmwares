Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common.ps1')

$requiredFiles = @(
    'devices.json',
    'firmwares.json',
    'tools/add-firmware.ps1',
    'tools/check-updates.ps1',
    'tools/generate-readme.ps1',
    'tools/validate.ps1',
    '.github/workflows/check-firmware-updates.yml'
)

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Missing required project file: $relativePath"
    }
}

$sortRegressionEntries = New-Object System.Collections.Generic.List[object]
$sortRegressionEntries.Add([pscustomobject]@{
    device = 'dualsense'
    version = '0x0001'
    variant = 'A'
    updaterId = 'FWUPDATE0004'
}) | Out-Null
$sortedRegressionEntries = @(Sort-FirmwareEntries -Entries $sortRegressionEntries.ToArray())
if ($sortedRegressionEntries.Count -ne 1 -or $sortedRegressionEntries[0].version -ne '0x0001') {
    throw 'Sort-FirmwareEntries failed to handle generic list input.'
}

& (Join-Path $PSScriptRoot 'validate.ps1')
& (Join-Path $PSScriptRoot 'generate-readme.ps1') -Check

$metadata = Get-Content -LiteralPath (Join-Path $repoRoot 'firmwares.json') -Raw | ConvertFrom-Json
foreach ($firmware in @($metadata.firmwares)) {
    if ($firmware.file -notmatch '^firmware/[^/]+/type-[^/]+/0x[0-9A-F]{4}/FWUPDATE[0-9A-F]+\.bin$') {
        throw "Firmware file path should include device, type, version, and bin filename: $($firmware.file)"
    }
}

$readme = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
$dualSenseIndex = $readme.IndexOf('## DualSense')
$addingIndex = $readme.IndexOf('## Adding firmware')
$type000EIndex = $readme.IndexOf('### Type 000E / FWUPDATE000E')
if ($dualSenseIndex -lt 0 -or $addingIndex -lt 0 -or $type000EIndex -lt 0) {
    throw 'README.md is missing expected firmware or maintenance sections.'
}
if ($addingIndex -lt $dualSenseIndex) {
    throw 'README maintenance instructions should appear after firmware tables.'
}
if ($readme.Contains('| Version | Variant | Updater | Status | File | Official URL | SHA256 |')) {
    throw 'README firmware tables should be split by variant instead of repeating Variant and Updater columns.'
}

$testInfoPath = Join-Path $repoRoot '.test-fwupdater-info.json'
try {
    $testInfo = @{
        ApplicationLatestVersion = '2.2.1.2'
        FwUpdate0004LatestVersion = '0x0630'
        FwUpdate000BLatestVersion = '0x0630'
        FwUpdate000ELatestVersion = '0xFFFF'
        FwUpdate0044LatestVersion = '0x0217'
    } | ConvertTo-Json
    Set-Content -LiteralPath $testInfoPath -Value $testInfo -Encoding UTF8

    $updates = @(& (Join-Path $PSScriptRoot 'check-updates.ps1') -InfoJsonPath $testInfoPath -PassThru)
    if ($updates.Count -ne 1) {
        throw "Expected 1 available firmware update from test info.json, found $($updates.Count)."
    }
    if ($updates[0].device -ne 'dualsense' -or $updates[0].variant -ne 'E' -or $updates[0].version -ne '0xFFFF') {
        throw "Unexpected update detected: $($updates[0] | ConvertTo-Json -Compress)"
    }
    if ($updates[0].file -ne 'firmware/dualsense/type-000E/0xFFFF/FWUPDATE000E.bin') {
        throw "Unexpected update file path: $($updates[0].file)"
    }
} finally {
    if (Test-Path -LiteralPath $testInfoPath) {
        Remove-Item -LiteralPath $testInfoPath -Force
    }
}

Write-Host 'All repository checks passed.'
