param(
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

function Add-Line {
    param([string]$Line = '')
    $script:lines.Add($Line) | Out-Null
}

function Get-DisplayVariant {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Variant
    )

    if ($Variant.id -eq 'default') {
        return $Variant.label
    }

    return $Variant.label
}

function Get-VariantMaxVersion {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Entries
    )

    return (($Entries | ForEach-Object { Get-VersionNumber -Version $_.version } | Measure-Object -Maximum).Maximum)
}

$repoRoot = Get-RepositoryRoot
$config = Read-JsonFile -Path (Join-Path $repoRoot 'devices.json')
$metadata = Read-JsonFile -Path (Join-Path $repoRoot 'firmwares.json')
$entries = @($metadata.firmwares)
$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# DualSense / DualSense Edge Firmwares'
Add-Line
Add-Line 'Official firmware `.bin` archive for PlayStation controllers. The firmware files are stored by device, type, and version under `firmware/`, while device URL patterns and archived firmware metadata live in JSON files.'
Add-Line
Add-Line '> This README is generated from `devices.json` and `firmwares.json`. Run `.\tools\generate-readme.ps1` after metadata changes.'

foreach ($device in @($config.devices)) {
    $deviceEntries = @($entries | Where-Object { $_.device -eq $device.id } | Sort-Object `
        @{ Expression = { Get-VersionNumber -Version $_.version }; Descending = $true }, `
        @{ Expression = { $_.variant }; Ascending = $true }, `
        @{ Expression = { $_.updaterId }; Ascending = $true })

    if ($deviceEntries.Count -eq 0) {
        continue
    }

    Add-Line
    Add-Line "## $($device.name)"

    $variantGroups = @($deviceEntries | Group-Object -Property variant | Sort-Object `
        @{ Expression = { Get-VariantMaxVersion -Entries @($_.Group) }; Descending = $true }, `
        @{ Expression = { $_.Name }; Ascending = $true })

    foreach ($variantGroup in $variantGroups) {
        $variant = Get-VariantConfig -Device $device -VariantId $variantGroup.Name
        $variantEntries = @($variantGroup.Group | Sort-Object `
            @{ Expression = { Get-VersionNumber -Version $_.version }; Descending = $true }, `
            @{ Expression = { $_.updaterId }; Ascending = $true })
        $displayVariant = Get-DisplayVariant -Variant $variant

        Add-Line
        Add-Line ('### {0} / {1}' -f $displayVariant, $variant.updaterId)
        Add-Line
        Add-Line '| Version | Status | File | Official URL | SHA256 |'
        Add-Line '|---|---|---|---|---|'

        foreach ($entry in $variantEntries) {
            $status = if ([bool]$entry.latest) { 'Latest' } else { 'Archived' }
            Add-Line ('| `{0}` | {1} | [{2}.bin]({3}) | [Download]({4}) | `{5}` |' -f $entry.version, $status, $entry.updaterId, $entry.file, $entry.sourceUrl, $entry.sha256)
        }
    }
}

Add-Line
Add-Line '## Metadata'
Add-Line
Add-Line '- `devices.json` defines supported devices, variants, updater IDs, and URL patterns.'
Add-Line '- `firmwares.json` lists every archived firmware file, source URL, SHA256 hash, size, and latest flag.'
Add-Line '- `.\tools\validate.ps1` verifies metadata, files, hashes, sizes, generated URLs, and untracked `.bin` files under `firmware/`.'
Add-Line
Add-Line '## Device URL patterns'
Add-Line
Add-Line '| Device | Variant | Updater path | Updater ID |'
Add-Line '|---|---|---|---|'

foreach ($device in @($config.devices)) {
    foreach ($variant in @($device.variants)) {
        Add-Line ('| {0} | {1} | `{2}` | `{3}` |' -f $device.name, $variant.label, $variant.updaterPath, $variant.updaterId)
    }
}

Add-Line
Add-Line '## Adding firmware'
Add-Line
Add-Line 'Use the interactive helper:'
Add-Line
Add-Line '```powershell'
Add-Line '.\tools\add-firmware.ps1'
Add-Line '```'
Add-Line
Add-Line 'The helper reads `devices.json`, asks for a device, variant, and version, builds the official Sony download URL, downloads the `.bin`, stores it under `firmware/<device>/<type>/<version>/`, updates `firmwares.json`, regenerates this README, and runs validation.'
Add-Line
Add-Line 'To add a new device or updater variant, add it to `devices.json`; the scripts will show it in the menu automatically.'
Add-Line
Add-Line '## Checking for updates'
Add-Line
Add-Line 'Run a report-only check against Sony firmware updater metadata:'
Add-Line
Add-Line '```powershell'
Add-Line '.\tools\check-updates.ps1'
Add-Line '```'
Add-Line
Add-Line 'Download and archive any missing latest firmware reported by Sony:'
Add-Line
Add-Line '```powershell'
Add-Line '.\tools\check-updates.ps1 -Apply'
Add-Line '```'
Add-Line
Add-Line 'GitHub Actions also runs this check daily at 12:00 UTC and can be triggered manually. When updates are found, the workflow downloads them, updates metadata, regenerates this README, validates the repository, and opens a pull request.'
Add-Line
Add-Line '## PlayStation Accessories'
Add-Line
Add-Line '[PlayStation Accessories firmware updater](https://controller.dl.playstation.net/controller/lang/en/fwupdater.html)'
Add-Line
Add-Line '<img width="962" alt="Screenshot 2024-09-29 050231" src="https://github.com/user-attachments/assets/30cd8fc1-f34b-4d1a-ad2a-ea084edf4f0f">'

$content = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
$readmePath = Join-Path $repoRoot 'README.md'

if ($Check) {
    $existing = ''
    if (Test-Path -LiteralPath $readmePath) {
        $existing = Get-Content -LiteralPath $readmePath -Raw
    }

    if ($existing -ne $content) {
        throw 'README.md is out of date. Run .\tools\generate-readme.ps1.'
    }

    Write-Host 'README.md is up to date.'
    return
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($readmePath, $content, $utf8NoBom)
Write-Host 'README.md regenerated.'
