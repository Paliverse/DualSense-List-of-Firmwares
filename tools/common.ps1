Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepositoryRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "JSON file not found: $Path"
    }

    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [object]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Get-JsonProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [object]$Default = $null
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $Default
    }

    return $property.Value
}

function Normalize-FirmwareVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $trimmed = $Version.Trim()
    if ($trimmed -notmatch '^0x[0-9a-fA-F]{4}$') {
        throw "Firmware version must use the form 0x0000, for example 0x0633. Received: $Version"
    }

    return ('0x' + $trimmed.Substring(2).ToUpperInvariant())
}

function Get-VersionNumber {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $normalized = Normalize-FirmwareVersion -Version $Version
    return [Convert]::ToInt32($normalized.Substring(2), 16)
}

function Get-DeviceConfig {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [string]$DeviceId
    )

    $device = @($Config.devices) | Where-Object { $_.id -eq $DeviceId } | Select-Object -First 1
    if ($null -eq $device) {
        throw "Unknown device '$DeviceId'. Add it to devices.json first."
    }

    return $device
}

function Get-VariantConfig {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Device,

        [Parameter(Mandatory = $true)]
        [string]$VariantId
    )

    $variant = @($Device.variants) | Where-Object { $_.id -eq $VariantId } | Select-Object -First 1
    if ($null -eq $variant) {
        throw "Unknown variant '$VariantId' for device '$($Device.id)'. Add it to devices.json first."
    }

    return $variant
}

function Get-FirmwareSourceUrl {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [object]$Device,

        [Parameter(Mandatory = $true)]
        [object]$Variant,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $template = Get-JsonProperty -Object $Variant -Name 'urlTemplate' -Default $null
    if ($null -eq $template) {
        $template = Get-JsonProperty -Object $Device -Name 'urlTemplate' -Default $null
    }
    if ($null -eq $template) {
        $template = Get-JsonProperty -Object $Config -Name 'urlTemplate' -Default $null
    }
    if ($null -eq $template) {
        throw 'No urlTemplate found in devices.json.'
    }

    $normalizedVersion = Normalize-FirmwareVersion -Version $Version
    return $template.
        Replace('{updaterPath}', $Variant.updaterPath).
        Replace('{version}', $normalizedVersion).
        Replace('{updaterId}', $Variant.updaterId)
}

function Get-FirmwareRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Device,

        [Parameter(Mandatory = $true)]
        [object]$Variant,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $normalizedVersion = Normalize-FirmwareVersion -Version $Version
    $variantPath = Get-JsonProperty -Object $Variant -Name 'path' -Default $null
    if ([string]::IsNullOrWhiteSpace($variantPath)) {
        throw "Variant '$($Variant.id)' for device '$($Device.id)' is missing a path in devices.json."
    }

    return "firmware/$($Device.path)/$variantPath/$normalizedVersion/$($Variant.updaterId).bin"
}

function ConvertTo-NativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRelativePath
    )

    return ($RepoRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Sort-FirmwareEntries {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Entries
    )

    return @($Entries | Sort-Object `
        @{ Expression = { $_.device }; Ascending = $true }, `
        @{ Expression = { Get-VersionNumber -Version $_.version }; Descending = $true }, `
        @{ Expression = { $_.variant }; Ascending = $true }, `
        @{ Expression = { $_.updaterId }; Ascending = $true })
}
