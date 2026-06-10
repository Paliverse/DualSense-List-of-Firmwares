param(
    [string]$Device,
    [string]$Variant,
    [string]$Version,
    [switch]$MarkLatest,
    [switch]$DoNotMarkLatest,
    [switch]$Force,
    [switch]$SkipReadme
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

function Select-ItemFromMenu {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items,

        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Label
    )

    for ($i = 0; $i -lt $Items.Count; $i++) {
        $number = $i + 1
        Write-Host "[$number] $(& $Label $Items[$i])"
    }

    while ($true) {
        $selection = Read-Host $Prompt
        $index = 0
        if ([int]::TryParse($selection, [ref]$index) -and $index -ge 1 -and $index -le $Items.Count) {
            return $Items[$index - 1]
        }

        Write-Host "Enter a number from 1 to $($Items.Count)."
    }
}

if ($MarkLatest -and $DoNotMarkLatest) {
    throw 'Use either -MarkLatest or -DoNotMarkLatest, not both.'
}

$repoRoot = Get-RepositoryRoot
$devicesPath = Join-Path $repoRoot 'devices.json'
$firmwaresPath = Join-Path $repoRoot 'firmwares.json'
$config = Read-JsonFile -Path $devicesPath

if ([string]::IsNullOrWhiteSpace($Device)) {
    $selectedDevice = Select-ItemFromMenu `
        -Items @($config.devices) `
        -Prompt 'Choose device' `
        -Label { param($item) "$($item.name) [$($item.id)]" }
} else {
    $selectedDevice = Get-DeviceConfig -Config $config -DeviceId $Device
}

if ([string]::IsNullOrWhiteSpace($Variant)) {
    $selectedVariant = Select-ItemFromMenu `
        -Items @($selectedDevice.variants) `
        -Prompt 'Choose variant' `
        -Label { param($item) "$($item.label) [$($item.id)]" }
} else {
    $selectedVariant = Get-VariantConfig -Device $selectedDevice -VariantId $Variant
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Read-Host 'Firmware version, for example 0x0633'
}
$normalizedVersion = Normalize-FirmwareVersion -Version $Version

if (-not $MarkLatest -and -not $DoNotMarkLatest) {
    $latestAnswer = Read-Host 'Mark this firmware as latest for this device/variant? [Y/n]'
    if ([string]::IsNullOrWhiteSpace($latestAnswer) -or $latestAnswer -match '^(y|yes)$') {
        $MarkLatest = $true
    } else {
        $DoNotMarkLatest = $true
    }
}

$relativeFile = Get-FirmwareRelativePath -Device $selectedDevice -Variant $selectedVariant -Version $normalizedVersion
$nativeRelativeFile = ConvertTo-NativePath -RepoRelativePath $relativeFile
$destination = Join-Path $repoRoot $nativeRelativeFile
$destinationDirectory = Split-Path -Parent $destination
$sourceUrl = Get-FirmwareSourceUrl -Config $config -Device $selectedDevice -Variant $selectedVariant -Version $normalizedVersion

if ((Test-Path -LiteralPath $destination) -and -not $Force) {
    throw "Firmware file already exists: $relativeFile. Re-run with -Force to replace it."
}

New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
$temporaryFile = "$destination.download"

try {
    Write-Host "Downloading $sourceUrl"
    Invoke-WebRequest -Uri $sourceUrl -OutFile $temporaryFile -UseBasicParsing

    $downloaded = Get-Item -LiteralPath $temporaryFile
    if ($downloaded.Length -le 0) {
        throw "Downloaded file is empty: $sourceUrl"
    }

    Move-Item -LiteralPath $temporaryFile -Destination $destination -Force
} catch {
    if (Test-Path -LiteralPath $temporaryFile) {
        Remove-Item -LiteralPath $temporaryFile -Force
    }
    throw
}

$file = Get-Item -LiteralPath $destination
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash

$metadata = Read-JsonFile -Path $firmwaresPath
$entries = @($metadata.firmwares)
$updatedEntries = New-Object System.Collections.Generic.List[object]

foreach ($entry in $entries) {
    $sameEntry = (
        $entry.device -eq $selectedDevice.id -and
        $entry.version -eq $normalizedVersion -and
        $entry.variant -eq $selectedVariant.id -and
        $entry.updaterId -eq $selectedVariant.updaterId
    )

    if ($sameEntry) {
        continue
    }

    if ($MarkLatest -and $entry.device -eq $selectedDevice.id -and $entry.variant -eq $selectedVariant.id) {
        $entry.latest = $false
    }

    $updatedEntries.Add($entry) | Out-Null
}

$newEntry = [pscustomobject][ordered]@{
    device = $selectedDevice.id
    version = $normalizedVersion
    variant = $selectedVariant.id
    updaterId = $selectedVariant.updaterId
    file = $relativeFile
    sourceUrl = $sourceUrl
    sha256 = $hash
    size = $file.Length
    latest = [bool]$MarkLatest
}
$updatedEntries.Add($newEntry) | Out-Null

$newMetadata = [pscustomobject][ordered]@{
    schemaVersion = 1
    firmwares = @(Sort-FirmwareEntries -Entries $updatedEntries.ToArray())
}
Write-JsonFile -Path $firmwaresPath -Value $newMetadata

if (-not $SkipReadme) {
    & (Join-Path $PSScriptRoot 'generate-readme.ps1')
}

& (Join-Path $PSScriptRoot 'validate.ps1')

Write-Host "Added $($selectedDevice.name) firmware $normalizedVersion ($($selectedVariant.id)) to $relativeFile"
