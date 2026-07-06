<#
    Datei-Zeitplaner (PowerShell-Variante)
    Verwaltet Zeitpläne über eine WinForms-Oberfläche und registriert für
    jeden Eintrag eine native Windows-Aufgabe (Task Scheduler), die zur
    geplanten Zeit die gewählte Datei mit dem Standardprogramm öffnet.
    Kein Node.js, kein Electron, keine Installation nötig.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$ScriptDir      = $PSScriptRoot
$OpenFileScript = Join-Path $ScriptDir 'OpenFile.ps1'
$DataDir        = Join-Path $env:APPDATA 'DateiZeitplaner'
$SchedulesPath  = Join-Path $DataDir 'schedules.json'
$LogPath        = Join-Path $DataDir 'verlauf.log'
$TaskFolder     = '\DateiZeitplaner\'

if (-not (Test-Path $OpenFileScript)) {
    [System.Windows.Forms.MessageBox]::Show(
        "OpenFile.ps1 wurde nicht im selben Ordner gefunden:`n$OpenFileScript`n`nBitte beide Skripte zusammen in einen festen Ordner legen.",
        'Datei-Zeitplaner', 'OK', 'Error') | Out-Null
    exit 1
}

if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir | Out-Null }
if (-not (Test-Path $SchedulesPath)) { '[]' | Set-Content -Path $SchedulesPath -Encoding UTF8 }
if (-not (Test-Path $LogPath)) { New-Item -ItemType File -Path $LogPath | Out-Null }

$WeekdayItems = @(
    [PSCustomObject]@{ Name = 'Montag';     Value = 'Monday' }
    [PSCustomObject]@{ Name = 'Dienstag';   Value = 'Tuesday' }
    [PSCustomObject]@{ Name = 'Mittwoch';   Value = 'Wednesday' }
    [PSCustomObject]@{ Name = 'Donnerstag'; Value = 'Thursday' }
    [PSCustomObject]@{ Name = 'Freitag';    Value = 'Friday' }
    [PSCustomObject]@{ Name = 'Samstag';    Value = 'Saturday' }
    [PSCustomObject]@{ Name = 'Sonntag';    Value = 'Sunday' }
)
$WeekdayLabelByValue = @{}
foreach ($w in $WeekdayItems) { $WeekdayLabelByValue[$w.Value] = $w.Name }

function Load-Entries {
    $json = Get-Content -Path $SchedulesPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($json)) { return @() }
    $data = $json | ConvertFrom-Json
    if ($null -eq $data) { return @() }
    return @($data)
}

function Save-Entries($entries) {
    $json = @($entries) | ConvertTo-Json -Depth 5
    Set-Content -Path $SchedulesPath -Value $json -Encoding UTF8
}

function Get-TaskName([string]$id) { "DateiZeitplaner_$id" }

function Register-EntryTask($entry) {
    $taskName = Get-TaskName $entry.Id

    $argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$OpenFileScript`" -Id `"$($entry.Id)`" -Store `"$SchedulesPath`" -LogPath `"$LogPath`""
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argument

    switch ($entry.Type) {
        'Once' {
            $dt = [datetime]::ParseExact("$($entry.Date) $($entry.Time)", 'yyyy-MM-dd HH:mm', $null)
            $trigger = New-ScheduledTaskTrigger -Once -At $dt
        }
        'Daily' {
            $parts = $entry.Time -split ':'
            $at = (Get-Date).Date.AddHours([int]$parts[0]).AddMinutes([int]$parts[1])
            $trigger = New-ScheduledTaskTrigger -Daily -At $at
        }
        'Weekly' {
            $parts = $entry.Time -split ':'
            $at = (Get-Date).Date.AddHours([int]$parts[0]).AddMinutes([int]$parts[1])
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $entry.Weekday -At $at
        }
    }

    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask -TaskName $taskName -TaskPath $TaskFolder -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

    if (-not $entry.Enabled) {
        Disable-ScheduledTask -TaskName $taskName -TaskPath $TaskFolder | Out-Null
    }
}

function Remove-EntryTask([string]$id) {
    $taskName = Get-TaskName $id
    Get-ScheduledTask -TaskName $taskName -TaskPath $TaskFolder -ErrorAction SilentlyContinue |
        Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
}

function Format-Schedule($entry) {
    switch ($entry.Type) {
        'Once' {
            $suffix = if ($entry.DoneOnce) { ' (bereits ausgeführt)' } else { '' }
            "Einmalig am $($entry.Date) um $($entry.Time)$suffix"
        }
        'Daily'  { "Täglich um $($entry.Time)" }
        'Weekly' { "Jeden $($WeekdayLabelByValue[$entry.Weekday]) um $($entry.Time)" }
    }
}

# ---------- GUI ----------

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Datei-Zeitplaner'
$form.Size = New-Object System.Drawing.Size(780, 720)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false

# --- Gruppe: Neuer Eintrag ---
$grpNew = New-Object System.Windows.Forms.GroupBox
$grpNew.Text = 'Neuen Eintrag anlegen'
$grpNew.Location = New-Object System.Drawing.Point(12, 12)
$grpNew.Size = New-Object System.Drawing.Size(740, 180)
$form.Controls.Add($grpNew)

$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = 'Datei:'
$lblFile.Location = New-Object System.Drawing.Point(10, 30)
$lblFile.Size = New-Object System.Drawing.Size(50, 20)
$grpNew.Controls.Add($lblFile)

$txtFile = New-Object System.Windows.Forms.TextBox
$txtFile.Location = New-Object System.Drawing.Point(65, 27)
$txtFile.Size = New-Object System.Drawing.Size(480, 22)
$txtFile.ReadOnly = $true
$grpNew.Controls.Add($txtFile)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = 'Durchsuchen...'
$btnBrowse.Location = New-Object System.Drawing.Point(555, 25)
$btnBrowse.Size = New-Object System.Drawing.Size(110, 26)
$grpNew.Controls.Add($btnBrowse)

$lblType = New-Object System.Windows.Forms.Label
$lblType.Text = 'Wiederholung:'
$lblType.Location = New-Object System.Drawing.Point(10, 68)
$lblType.Size = New-Object System.Drawing.Size(90, 20)
$grpNew.Controls.Add($lblType)

$cmbType = New-Object System.Windows.Forms.ComboBox
$cmbType.Location = New-Object System.Drawing.Point(105, 65)
$cmbType.Size = New-Object System.Drawing.Size(140, 22)
$cmbType.DropDownStyle = 'DropDownList'
[void]$cmbType.Items.AddRange(@('Einmalig', 'Täglich', 'Wöchentlich'))
$cmbType.SelectedIndex = 0
$grpNew.Controls.Add($cmbType)

$lblDate = New-Object System.Windows.Forms.Label
$lblDate.Text = 'Datum:'
$lblDate.Location = New-Object System.Drawing.Point(260, 68)
$lblDate.Size = New-Object System.Drawing.Size(55, 20)
$grpNew.Controls.Add($lblDate)

$dtpDate = New-Object System.Windows.Forms.DateTimePicker
$dtpDate.Location = New-Object System.Drawing.Point(320, 65)
$dtpDate.Size = New-Object System.Drawing.Size(140, 22)
$dtpDate.Format = 'Short'
$dtpDate.MinDate = (Get-Date).Date
$grpNew.Controls.Add($dtpDate)

$lblWeekday = New-Object System.Windows.Forms.Label
$lblWeekday.Text = 'Wochentag:'
$lblWeekday.Location = New-Object System.Drawing.Point(260, 68)
$lblWeekday.Size = New-Object System.Drawing.Size(70, 20)
$lblWeekday.Visible = $false
$grpNew.Controls.Add($lblWeekday)

$cmbWeekday = New-Object System.Windows.Forms.ComboBox
$cmbWeekday.Location = New-Object System.Drawing.Point(320, 65)
$cmbWeekday.Size = New-Object System.Drawing.Size(140, 22)
$cmbWeekday.DropDownStyle = 'DropDownList'
$cmbWeekday.DisplayMember = 'Name'
$cmbWeekday.ValueMember = 'Value'
$cmbWeekday.DataSource = @($WeekdayItems | ForEach-Object { $_ })
$cmbWeekday.Visible = $false
$grpNew.Controls.Add($cmbWeekday)

$lblTime = New-Object System.Windows.Forms.Label
$lblTime.Text = 'Uhrzeit:'
$lblTime.Location = New-Object System.Drawing.Point(475, 68)
$lblTime.Size = New-Object System.Drawing.Size(55, 20)
$grpNew.Controls.Add($lblTime)

$dtpTime = New-Object System.Windows.Forms.DateTimePicker
$dtpTime.Location = New-Object System.Drawing.Point(535, 65)
$dtpTime.Size = New-Object System.Drawing.Size(100, 22)
$dtpTime.Format = 'Time'
$dtpTime.ShowUpDown = $true
$grpNew.Controls.Add($dtpTime)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = 'Zeitplan hinzufügen'
$btnAdd.Location = New-Object System.Drawing.Point(10, 130)
$btnAdd.Size = New-Object System.Drawing.Size(160, 30)
$grpNew.Controls.Add($btnAdd)

$cmbType.Add_SelectedIndexChanged({
    $isOnce = $cmbType.SelectedItem -eq 'Einmalig'
    $isWeekly = $cmbType.SelectedItem -eq 'Wöchentlich'
    $lblDate.Visible = $isOnce
    $dtpDate.Visible = $isOnce
    $lblWeekday.Visible = $isWeekly
    $cmbWeekday.Visible = $isWeekly
})

# --- Gruppe: Geplante Einträge ---
$grpList = New-Object System.Windows.Forms.GroupBox
$grpList.Text = 'Geplante Einträge'
$grpList.Location = New-Object System.Drawing.Point(12, 200)
$grpList.Size = New-Object System.Drawing.Size(740, 280)
$form.Controls.Add($grpList)

$lvEntries = New-Object System.Windows.Forms.ListView
$lvEntries.Location = New-Object System.Drawing.Point(10, 22)
$lvEntries.Size = New-Object System.Drawing.Size(720, 200)
$lvEntries.View = 'Details'
$lvEntries.FullRowSelect = $true
$lvEntries.GridLines = $true
$lvEntries.MultiSelect = $false
[void]$lvEntries.Columns.Add('Datei', 260)
[void]$lvEntries.Columns.Add('Zeitplan', 230)
[void]$lvEntries.Columns.Add('Status', 90)
[void]$lvEntries.Columns.Add('Zuletzt geöffnet', 130)
$grpList.Controls.Add($lvEntries)

$btnToggle = New-Object System.Windows.Forms.Button
$btnToggle.Text = 'Aktivieren/Deaktivieren'
$btnToggle.Location = New-Object System.Drawing.Point(10, 232)
$btnToggle.Size = New-Object System.Drawing.Size(170, 30)
$grpList.Controls.Add($btnToggle)

$btnOpenNow = New-Object System.Windows.Forms.Button
$btnOpenNow.Text = 'Jetzt öffnen'
$btnOpenNow.Location = New-Object System.Drawing.Point(190, 232)
$btnOpenNow.Size = New-Object System.Drawing.Size(120, 30)
$grpList.Controls.Add($btnOpenNow)

$btnDelete = New-Object System.Windows.Forms.Button
$btnDelete.Text = 'Löschen'
$btnDelete.Location = New-Object System.Drawing.Point(320, 232)
$btnDelete.Size = New-Object System.Drawing.Size(120, 30)
$grpList.Controls.Add($btnDelete)

# --- Gruppe: Verlauf ---
$grpLog = New-Object System.Windows.Forms.GroupBox
$grpLog.Text = 'Verlauf'
$grpLog.Location = New-Object System.Drawing.Point(12, 490)
$grpLog.Size = New-Object System.Drawing.Size(740, 170)
$form.Controls.Add($grpLog)

$lstLog = New-Object System.Windows.Forms.ListBox
$lstLog.Location = New-Object System.Drawing.Point(10, 22)
$lstLog.Size = New-Object System.Drawing.Size(720, 135)
$grpLog.Controls.Add($lstLog)

# ---------- Aktionen ----------

function Refresh-EntryList {
    $selectedId = $null
    if ($lvEntries.SelectedItems.Count -gt 0) { $selectedId = $lvEntries.SelectedItems[0].Tag }

    $lvEntries.Items.Clear()
    foreach ($entry in (Load-Entries)) {
        $status = if ($entry.Enabled) { 'Aktiv' } else { 'Inaktiv' }
        $lastOpened = if ($entry.LastOpened) { ([datetime]$entry.LastOpened).ToString('dd.MM.yyyy HH:mm') } else { '-' }

        $item = New-Object System.Windows.Forms.ListViewItem($entry.FilePath)
        [void]$item.SubItems.Add((Format-Schedule $entry))
        [void]$item.SubItems.Add($status)
        [void]$item.SubItems.Add($lastOpened)
        $item.Tag = $entry.Id
        [void]$lvEntries.Items.Add($item)

        if ($entry.Id -eq $selectedId) { $item.Selected = $true }
    }
}

function Refresh-Log {
    $lines = Get-Content -Path $LogPath -Tail 200 -ErrorAction SilentlyContinue
    $lstLog.Items.Clear()
    if ($lines) {
        [array]::Reverse($lines)
        foreach ($line in $lines) { [void]$lstLog.Items.Add($line) }
    }
}

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Datei auswählen'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtFile.Text = $dlg.FileName
    }
})

$btnAdd.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtFile.Text)) {
        [System.Windows.Forms.MessageBox]::Show('Bitte zuerst eine Datei auswählen.', 'Datei-Zeitplaner') | Out-Null
        return
    }

    $type = switch ($cmbType.SelectedItem) {
        'Einmalig'    { 'Once' }
        'Täglich'     { 'Daily' }
        'Wöchentlich' { 'Weekly' }
    }

    $entry = [PSCustomObject]@{
        Id         = [guid]::NewGuid().ToString()
        FilePath   = $txtFile.Text
        Type       = $type
        Date       = if ($type -eq 'Once') { $dtpDate.Value.ToString('yyyy-MM-dd') } else { $null }
        Weekday    = if ($type -eq 'Weekly') { $cmbWeekday.SelectedValue } else { $null }
        Time       = $dtpTime.Value.ToString('HH:mm')
        Enabled    = $true
        DoneOnce   = $false
        LastOpened = $null
        CreatedAt  = (Get-Date).ToString('o')
    }

    $entries = @(Load-Entries) + $entry
    Save-Entries $entries

    try {
        Register-EntryTask $entry
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Konnte Windows-Aufgabe nicht anlegen:`n$($_.Exception.Message)", 'Datei-Zeitplaner', 'OK', 'Error') | Out-Null
    }

    $txtFile.Clear()
    $cmbType.SelectedIndex = 0
    Refresh-EntryList
})

$btnToggle.Add_Click({
    if ($lvEntries.SelectedItems.Count -eq 0) { return }
    $id = $lvEntries.SelectedItems[0].Tag
    $entries = Load-Entries
    $entry = $entries | Where-Object { $_.Id -eq $id }
    if (-not $entry) { return }

    $entry.Enabled = -not $entry.Enabled
    $taskName = Get-TaskName $id

    if ($entry.Enabled) {
        if ($entry.Type -eq 'Once') { $entry.DoneOnce = $false }
        Enable-ScheduledTask -TaskName $taskName -TaskPath $TaskFolder -ErrorAction SilentlyContinue | Out-Null
    } else {
        Disable-ScheduledTask -TaskName $taskName -TaskPath $TaskFolder -ErrorAction SilentlyContinue | Out-Null
    }

    Save-Entries $entries
    Refresh-EntryList
})

$btnOpenNow.Add_Click({
    if ($lvEntries.SelectedItems.Count -eq 0) { return }
    $id = $lvEntries.SelectedItems[0].Tag
    $entries = Load-Entries
    $entry = $entries | Where-Object { $_.Id -eq $id }
    if (-not $entry) { return }

    try {
        Start-Process -FilePath $entry.FilePath
        Add-Content -Path $LogPath -Value "$((Get-Date).ToString('s')) | Manuell geöffnet: $($entry.FilePath)"
        $entry.LastOpened = (Get-Date).ToString('o')
        Save-Entries $entries
    } catch {
        Add-Content -Path $LogPath -Value "$((Get-Date).ToString('s')) | Fehler beim manuellen Öffnen von $($entry.FilePath): $($_.Exception.Message)"
    }

    Refresh-EntryList
    Refresh-Log
})

$btnDelete.Add_Click({
    if ($lvEntries.SelectedItems.Count -eq 0) { return }
    $id = $lvEntries.SelectedItems[0].Tag
    $confirm = [System.Windows.Forms.MessageBox]::Show('Diesen Eintrag wirklich löschen?', 'Datei-Zeitplaner', 'YesNo', 'Question')
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $entries = @(Load-Entries | Where-Object { $_.Id -ne $id })
    Save-Entries $entries
    Remove-EntryTask $id
    Refresh-EntryList
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({ Refresh-EntryList; Refresh-Log })

$form.Add_Shown({
    Refresh-EntryList
    Refresh-Log
    $timer.Start()
})
$form.Add_FormClosing({ $timer.Stop() })

[void]$form.ShowDialog()
