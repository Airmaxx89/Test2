<#
    Wird von den Windows-Scheduled-Tasks aufgerufen, die DateiZeitplaner.ps1
    anlegt. Öffnet die zum Eintrag gehörende Datei mit dem Standardprogramm
    und aktualisiert Verlauf/Status in schedules.json.
#>

param(
    [Parameter(Mandatory = $true)][string]$Id,
    [Parameter(Mandatory = $true)][string]$Store,
    [Parameter(Mandatory = $true)][string]$LogPath
)

$ErrorActionPreference = 'Stop'

function Load-Entries {
    if (-not (Test-Path $Store)) { return @() }
    $json = Get-Content -Path $Store -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($json)) { return @() }
    $data = $json | ConvertFrom-Json
    if ($null -eq $data) { return @() }
    return @($data)
}

function Save-Entries($entries) {
    $json = @($entries) | ConvertTo-Json -Depth 5
    Set-Content -Path $Store -Value $json -Encoding UTF8
}

$entries = Load-Entries
$entry = $entries | Where-Object { $_.Id -eq $Id }

if (-not $entry) {
    Add-Content -Path $LogPath -Value "$((Get-Date).ToString('s')) | Fehler: Eintrag $Id nicht gefunden."
    exit 1
}

try {
    Start-Process -FilePath $entry.FilePath -ErrorAction Stop
    Add-Content -Path $LogPath -Value "$((Get-Date).ToString('s')) | Geöffnet: $($entry.FilePath)"

    $entry.LastOpened = (Get-Date).ToString('o')
    if ($entry.Type -eq 'Once') {
        $entry.DoneOnce = $true
    }
    Save-Entries $entries
} catch {
    Add-Content -Path $LogPath -Value "$((Get-Date).ToString('s')) | Fehler beim Öffnen von $($entry.FilePath): $($_.Exception.Message)"
}
