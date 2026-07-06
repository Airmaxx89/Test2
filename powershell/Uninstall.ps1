<#
    Entfernt alle vom Datei-Zeitplaner angelegten Windows-Aufgaben sowie die
    gespeicherten Zeitpläne und den Verlauf. Danach können die Skriptdateien
    gefahrlos gelöscht werden.
#>

$ErrorActionPreference = 'SilentlyContinue'

Get-ScheduledTask -TaskPath '\DateiZeitplaner\' | Unregister-ScheduledTask -Confirm:$false

$dataDir = Join-Path $env:APPDATA 'DateiZeitplaner'
if (Test-Path $dataDir) {
    Remove-Item -Recurse -Force $dataDir
}

Write-Host 'Alle Zeitpläne, Windows-Aufgaben und gespeicherten Daten wurden entfernt.'
