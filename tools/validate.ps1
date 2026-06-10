Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Get-RepositoryRoot
$config = Read-JsonFile -Path (Join-Path $repoRoot 'devices.json')
$metadata = Read-JsonFile -Path (Join-Path $repoRoot 'firmwares.json')
$entries = @($metadata.firmwares)
$errors = New-Object System.Collections.Generic.List[string]
$seenKeys = @{}
$seenFiles = @{}
$latestByVariant = @{}

function Add-ValidationError {
    param([string]$Message)
    $script:errors.Add($Message) | Out-Null
}

foreach ($entry in $entries) {
    $deviceId = Get-JsonProperty -Object $entry -Name 'device' -Default ''
    $version = Get-JsonProperty -Object $entry -Name 'version' -Default ''
    $variantId = Get-JsonProperty -Object $entry -Name 'variant' -Default ''
    $updaterId = Get-JsonProperty -Object $entry -Name 'updaterId' -Default ''
    $file = Get-JsonProperty -Object $entry -Name 'file' -Default ''
    $sourceUrl = Get-JsonProperty -Object $entry -Name 'sourceUrl' -Default ''
    $sha256 = Get-JsonProperty -Object $entry -Name 'sha256' -Default ''
    $size = Get-JsonProperty -Object $entry -Name 'size' -Default $null
    $latest = [bool](Get-JsonProperty -Object $entry -Name 'latest' -Default $false)

    if ([string]::IsNullOrWhiteSpace($deviceId) -or [string]::IsNullOrWhiteSpace($version) -or [string]::IsNullOrWhiteSpace($variantId) -or [string]::IsNullOrWhiteSpace($updaterId)) {
        Add-ValidationError "Entry has missing identity fields: $($entry | ConvertTo-Json -Compress)"
        continue
    }

    try {
        $normalizedVersion = Normalize-FirmwareVersion -Version $version
        if ($version -ne $normalizedVersion) {
            Add-ValidationError "Version '$version' should be normalized as '$normalizedVersion'."
        }
    } catch {
        Add-ValidationError $_.Exception.Message
        continue
    }

    try {
        $device = Get-DeviceConfig -Config $config -DeviceId $deviceId
        $variant = Get-VariantConfig -Device $device -VariantId $variantId
    } catch {
        Add-ValidationError $_.Exception.Message
        continue
    }

    $key = "$deviceId|$version|$variantId|$updaterId"
    if ($seenKeys.ContainsKey($key)) {
        Add-ValidationError "Duplicate firmware entry: $key"
    }
    $seenKeys[$key] = $true

    if ($seenFiles.ContainsKey($file)) {
        Add-ValidationError "Multiple metadata entries point to the same file: $file"
    }
    $seenFiles[$file] = $true

    if ($updaterId -ne $variant.updaterId) {
        Add-ValidationError "Entry $key has updaterId '$updaterId', expected '$($variant.updaterId)' from devices.json."
    }

    $expectedFile = Get-FirmwareRelativePath -Device $device -Variant $variant -Version $version
    if ($file -ne $expectedFile) {
        Add-ValidationError "Entry $key has file '$file', expected '$expectedFile'."
    }

    $expectedUrl = Get-FirmwareSourceUrl -Config $config -Device $device -Variant $variant -Version $version
    if ($sourceUrl -ne $expectedUrl) {
        Add-ValidationError "Entry $key has sourceUrl '$sourceUrl', expected '$expectedUrl'."
    }

    $nativeFile = ConvertTo-NativePath -RepoRelativePath $file
    $fullPath = Join-Path $repoRoot $nativeFile
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Add-ValidationError "Missing firmware file for entry $key`: $file"
        continue
    }

    $actualFile = Get-Item -LiteralPath $fullPath
    if ($null -eq $size -or [int64]$size -ne $actualFile.Length) {
        Add-ValidationError "Entry $key has size '$size', expected '$($actualFile.Length)'."
    }

    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $fullPath).Hash
    if ($sha256 -ne $actualHash) {
        Add-ValidationError "Entry $key has SHA256 '$sha256', expected '$actualHash'."
    }

    if ($latest) {
        $latestKey = "$deviceId|$variantId"
        if ($latestByVariant.ContainsKey($latestKey)) {
            Add-ValidationError "Multiple latest firmwares for $latestKey`: $($latestByVariant[$latestKey]) and $version."
        }
        $latestByVariant[$latestKey] = $version
    }
}

$firmwareRoot = Join-Path $repoRoot 'firmware'
if (Test-Path -LiteralPath $firmwareRoot) {
    $actualBins = Get-ChildItem -LiteralPath $firmwareRoot -Recurse -File -Filter '*.bin'
    foreach ($actualBin in $actualBins) {
        $relative = $actualBin.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        if (-not $seenFiles.ContainsKey($relative)) {
            Add-ValidationError "Firmware file is missing from firmwares.json: $relative"
        }
    }
}

if ($errors.Count -gt 0) {
    throw "Validation failed:`n - $($errors -join "`n - ")"
}

Write-Host "Validation passed for $($entries.Count) firmware entries."
