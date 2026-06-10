param(
    [switch]$Apply,
    [string]$InfoUrl = 'https://fwupdater.dl.playstation.net/fwupdater/info.json',
    [string]$InfoJsonPath,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

function Get-SonyLatestVersionProperty {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UpdaterId
    )

    if ($UpdaterId -notmatch '^FWUPDATE(.+)$') {
        throw "Updater ID must use the form FWUPDATE####. Received: $UpdaterId"
    }

    return "FwUpdate$($Matches[1])LatestVersion"
}

function Read-FwUpdaterInfo {
    param(
        [string]$Path,
        [string]$Url
    )

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        return Read-JsonFile -Path $Path
    }

    Write-Host "Fetching $Url"
    return Invoke-RestMethod -Uri $Url
}

$repoRoot = Get-RepositoryRoot
$config = Read-JsonFile -Path (Join-Path $repoRoot 'devices.json')
$metadata = Read-JsonFile -Path (Join-Path $repoRoot 'firmwares.json')
$info = Read-FwUpdaterInfo -Path $InfoJsonPath -Url $InfoUrl
$updates = New-Object System.Collections.Generic.List[object]

foreach ($device in @($config.devices)) {
    foreach ($variant in @($device.variants)) {
        $latestProperty = Get-SonyLatestVersionProperty -UpdaterId $variant.updaterId
        $latestVersion = Get-JsonProperty -Object $info -Name $latestProperty -Default $null

        if ($null -eq $latestVersion) {
            Write-Warning "Sony info.json does not contain '$latestProperty' for $($device.name) / $($variant.label)."
            continue
        }

        $normalizedVersion = Normalize-FirmwareVersion -Version $latestVersion
        $existing = @($metadata.firmwares | Where-Object {
            $_.device -eq $device.id -and
            $_.variant -eq $variant.id -and
            $_.updaterId -eq $variant.updaterId -and
            $_.version -eq $normalizedVersion
        })

        if ($existing.Count -gt 0) {
            continue
        }

        $updates.Add([pscustomobject][ordered]@{
            device = $device.id
            deviceName = $device.name
            variant = $variant.id
            variantLabel = $variant.label
            updaterId = $variant.updaterId
            infoProperty = $latestProperty
            version = $normalizedVersion
            file = Get-FirmwareRelativePath -Device $device -Variant $variant -Version $normalizedVersion
            sourceUrl = Get-FirmwareSourceUrl -Config $config -Device $device -Variant $variant -Version $normalizedVersion
        }) | Out-Null
    }
}

if ($updates.Count -eq 0) {
    Write-Host 'No new firmware updates found.'
} else {
    Write-Host "Found $($updates.Count) firmware update(s):"
    foreach ($update in $updates) {
        Write-Host " - $($update.deviceName) / $($update.variantLabel): $($update.version) ($($update.updaterId))"
    }
}

if ($Apply -and $updates.Count -gt 0) {
    foreach ($update in $updates) {
        & (Join-Path $PSScriptRoot 'add-firmware.ps1') `
            -Device $update.device `
            -Variant $update.variant `
            -Version $update.version `
            -MarkLatest `
            -SkipReadme
    }

    & (Join-Path $PSScriptRoot 'generate-readme.ps1')
    & (Join-Path $PSScriptRoot 'validate.ps1')
}

if ($PassThru) {
    $updates
}
