<#
.SYNOPSIS
    bye2spy - Windows-11-Telemetrie, Copilot/KI und Datenabflüsse an Microsoft abschalten.

.DESCRIPTION
    Master-Skript. Lädt alle Module aus .\modules und bietet
      - ein interaktives Auswahlmenü in der Konsole (Standard, Pfeiltasten + Leertaste),
      - einen unbeaufsichtigten Modus (-Preset / -Module / -Tweak).
    Jede Änderung wird in .\backups protokolliert und kann rückgängig gemacht werden.

.PARAMETER Preset
    Recommended = nur Einstellungen mit geringem Risiko, All = alles (inkl. Mittel/Hoch),
    oder der Name eines Presets aus .\presets (z. B. Kritis). Liste: -List

.PARAMETER Module
    Nur diese Module (IDs, z. B. telemetry,ai). Mit -Preset kombinierbar (Standard: Recommended).

.PARAMETER Tweak
    Genau diese Einstellungen (IDs, z. B. ai.recall,telemetry.services).

.PARAMETER Exclude
    Einstellungen oder ganze Module (IDs), die ausgelassen werden.

.PARAMETER Restore
    Latest, All oder Pfad zu einer Sicherungsdatei aus .\backups.

.EXAMPLE
    .\bye2spy.ps1
    Startet das interaktive Auswahlmenü.

.EXAMPLE
    .\bye2spy.ps1 -Preset Recommended -Yes
    Wendet alle empfohlenen Einstellungen ohne Rückfrage an.

.EXAMPLE
    .\bye2spy.ps1 -Preset All -Exclude defender,network.hosts
    Wendet alles an, außer dem Defender-Modul und der hosts-Sperre.

.EXAMPLE
    .\bye2spy.ps1 -Status
    Zeigt, welche Einstellungen aktuell greifen.

.EXAMPLE
    .\bye2spy.ps1 -Restore Latest
    Macht den letzten Durchlauf rückgängig.
#>
[CmdletBinding()]
param(
    [string]$Preset,
    [string[]]$Module,
    [string[]]$Tweak,
    [string[]]$Exclude,
    [switch]$Status,
    [switch]$List,
    [string]$Restore,
    [switch]$DryRun,
    [switch]$NoRestorePoint,
    [switch]$Yes,
    [switch]$Detailed,
    [switch]$Elevated
)

$Version = '1.0.0'
$Root = $PSScriptRoot
$ScriptPath = $PSCommandPath
$BoundParams = $PSBoundParameters

#region Start: PowerShell-Edition & Adminrechte ------------------------------------------

function Get-ForwardArguments {
    param([switch]$Raw)
    # Start-Process setzt die Argumente ungequotet zusammen, der direkte Aufruf (&) quotet selbst
    $q = if ($Raw) { '{0}' } else { '"{0}"' }
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ($q -f $ScriptPath))
    foreach ($kv in $BoundParams.GetEnumerator()) {
        if ($kv.Key -eq 'Elevated') { continue }
        $v = $kv.Value
        if ($v -is [System.Management.Automation.SwitchParameter]) {
            if ($v.IsPresent) { $a += "-$($kv.Key)" }
        }
        elseif ($v -is [array]) { $a += "-$($kv.Key)"; $a += ($q -f ($v -join ',')) }
        else { $a += "-$($kv.Key)"; $a += ($q -f $v) }
    }
    $a
}

# Die Appx-Cmdlets laufen zuverlässig nur in Windows PowerShell 5.1
if ($PSVersionTable.PSEdition -eq 'Core') {
    $ps51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $ps51 @(Get-ForwardArguments -Raw)
    exit $LASTEXITCODE
}

Import-Module (Join-Path $Root 'lib\Bye2Spy.Core.psm1') -Force -DisableNameChecking

$readOnly = ($List -or $Status -or $DryRun)
if (-not $readOnly -and -not (Test-B2SAdmin)) {
    Write-Host 'bye2spy benötigt Administratorrechte - starte mit Erhöhung neu ...' -ForegroundColor Yellow
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList (@(Get-ForwardArguments) + '-Elevated')
    }
    catch {
        Write-Host 'Die Erhöhung wurde abgebrochen.' -ForegroundColor Red
    }
    exit
}

# Kommagetrennte Werte zulassen (nötig, wenn über -File aufgerufen)
function Split-List([string[]]$Value) {
    @($Value | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
$Module  = Split-List $Module
$Tweak   = Split-List $Tweak
$Exclude = Split-List $Exclude

$Modules = Import-B2SModules -Directory (Join-Path $Root 'modules')
$AllTweaks = @($Modules | ForEach-Object { $_.Tweaks })
$Presets = Import-B2SPresets -Directory (Join-Path $Root 'presets')
$BackupDir = Join-Path $Root 'backups'

#endregion

#region Gemeinsame Logik ------------------------------------------------------------------

function Write-Banner {
    Write-Host ''
    Write-Host '  bye2spy' -ForegroundColor Cyan -NoNewline
    Write-Host "  v$Version - Windows 11 Telemetrie, Copilot & KI abschalten" -ForegroundColor Gray
    $i = Get-B2SSystemInfo
    Write-Host ("  {0} {1} (Build {2}, {3})  |  Benutzer: {4}" -f $i.ProductName, $i.Version, $i.Build, $i.Edition, $i.RunAs) -ForegroundColor DarkGray
    foreach ($w in (Get-EnvironmentWarnings)) { Write-Host "  ! $w" -ForegroundColor Yellow }
    Write-Host ''
}

function Get-EnvironmentWarnings {
    $i = Get-B2SSystemInfo
    $w = @()
    if (-not $i.IsAdmin) { $w += 'Keine Administratorrechte - nur Anzeige/Vorschau möglich.' }
    if ($i.LoggedOn -and $i.RunAs -and ($i.LoggedOn -ne $i.RunAs)) {
        $w += "Angemeldet ist '$($i.LoggedOn)', das Skript läuft als '$($i.RunAs)'. Benutzerbezogene Einstellungen (HKCU) gelten nur für '$($i.RunAs)'."
    }
    if ($i.Edition -notmatch 'Enterprise|Education|IoT') {
        $w += "Edition $($i.Edition): Einige Richtlinien (z. B. Diagnosedaten-Stufe 0, einige Copilot-Richtlinien) wirken nur unter Enterprise/Education vollständig - die übrigen Maßnahmen greifen trotzdem."
    }
    $w
}

function Get-Preset {
    param([string]$Name)
    if (-not $Name) { return $null }
    @($Presets | Where-Object { $_.Id -eq $Name })[0]
}

function Get-PresetNames {
    @('Recommended', 'All') + @($Presets | ForEach-Object { $_.Id })
}

function Get-PresetTweaks {
    <# Einstellungen eines Presets aus .\presets (Basis + Include - Exclude). #>
    param([hashtable]$PresetDef)
    $base = if ($PresetDef.Base -eq 'All') { $AllTweaks } else { @($AllTweaks | Where-Object { $_.Recommended }) }
    $known = @($AllTweaks | ForEach-Object { $_.Id })
    foreach ($id in @($PresetDef.Include) + @($PresetDef.Exclude)) {
        if ($known -notcontains $id) { Write-Warning "Preset '$($PresetDef.Id)': unbekannte ID '$id'" }
    }
    $ids = @(@($base | ForEach-Object { $_.Id }) + @($PresetDef.Include)) | Select-Object -Unique
    @($AllTweaks | Where-Object { $ids -contains $_.Id -and @($PresetDef.Exclude) -notcontains $_.Id })
}

function Show-PresetInfo {
    param([hashtable]$PresetDef, [int]$Count)
    Write-Host ''
    Write-Host "  Preset: $($PresetDef.Name)" -ForegroundColor Cyan
    Write-Host "  $($PresetDef.Description)" -ForegroundColor Gray
    Write-Host "  $Count Einstellungen" -ForegroundColor DarkGray
    foreach ($n in @($PresetDef.Notes)) { Write-Host "    - $n" -ForegroundColor DarkYellow }
    Write-Host ''
}

function Select-Tweaks {
    param([string]$PresetName, [string[]]$ModuleIds, [string[]]$TweakIds, [string[]]$ExcludeIds)
    $known = @($AllTweaks | ForEach-Object { $_.Id }) + @($Modules | ForEach-Object { $_.Id })
    foreach ($id in @($ModuleIds) + @($TweakIds) + @($ExcludeIds)) {
        if ($id -and $known -notcontains $id) { Write-Warning "Unbekannte ID: $id  (Liste mit -List)" }
    }
    $presetDef = Get-Preset $PresetName
    if ($TweakIds.Count) {
        $sel = @($AllTweaks | Where-Object { $TweakIds -contains $_.Id })
    }
    elseif ($presetDef) {
        $sel = Get-PresetTweaks $presetDef
        if ($ModuleIds.Count) { $sel = @($sel | Where-Object { $ModuleIds -contains $_.ModuleId }) }
    }
    else {
        $sel = $AllTweaks
        if ($ModuleIds.Count) { $sel = @($sel | Where-Object { $ModuleIds -contains $_.ModuleId }) }
        if ($PresetName -ne 'All') { $sel = @($sel | Where-Object { $_.Recommended }) }
    }
    if ($ExcludeIds.Count) {
        $sel = @($sel | Where-Object { $ExcludeIds -notcontains $_.Id -and $ExcludeIds -notcontains $_.ModuleId })
    }
    , @($sel)
}

#region Ausgabe ---------------------------------------------------------------------------

$script:Ui = @{
    Plain    = $false   # true = keine Cursor-Tricks (umgeleitete Ausgabe oder -Detailed)
    BarShown = $false
    Width    = 80
    Warnings = $null
}

# Zeichen: Kästchen/Balken aus dem Unicode-Block, mit ASCII-Rückfall
$script:Glyph = @{
    Rule = [char]0x2500; Full = [char]0x2588; Empty = [char]0x2591
    Ok   = [char]0x2713; Warn = '!'; Skip = [char]0x00B7; Run = [char]0x203A; Sep = [char]0x203A
}

function Initialize-B2SUi {
    param([switch]$ForcePlain)
    $redirected = $true
    try { $redirected = [Console]::IsOutputRedirected } catch { }
    $script:Ui.Plain = [bool]$ForcePlain -or $redirected
    try { $script:Ui.Width = [Math]::Max(60, [Math]::Min(120, [Console]::WindowWidth - 1)) } catch { $script:Ui.Width = 80 }
    if ($script:Ui.Plain) {
        $script:Glyph = @{ Rule = '-'; Full = '#'; Empty = '.'; Ok = '+'; Warn = '!'; Skip = '.'; Run = '>'; Sep = '>' }
    }
}

function Write-UiRule {
    Write-Host ('  ' + ([string]$script:Glyph.Rule) * ($script:Ui.Width - 3)) -ForegroundColor DarkGray
}

function Format-UiCut {
    param([string]$Text, [int]$Max)
    if ($Max -lt 4) { return '' }
    if ($Text.Length -le $Max) { return $Text }
    $Text.Substring(0, $Max - 1) + [char]0x2026
}

function Show-RunHeader {
    param($Sys, [int]$Count, [switch]$Preview, [bool]$RestorePoint)
    Write-Host ''
    Write-Host '  bye2spy ' -ForegroundColor Cyan -NoNewline
    Write-Host $Version -ForegroundColor DarkCyan -NoNewline
    if ($Preview) { Write-Host '   VORSCHAU - es wird nichts verändert' -ForegroundColor Yellow }
    else { Write-Host '   Einstellungen werden angewendet' -ForegroundColor Gray }
    Write-UiRule
    Write-Host ("  {0} {1}  {3} Build {2}  {3} {4}" -f $Sys.ProductName, $Sys.Version, $Sys.Build, $script:Glyph.Skip, $Sys.RunAs) -ForegroundColor DarkGray
    $rp = if ($Preview) { 'entfällt' } elseif ($RestorePoint) { 'ja' } else { 'nein' }
    Write-Host ("  {0} Einstellungen  {1} Wiederherstellungspunkt: {2}" -f $Count, $script:Glyph.Skip, $rp) -ForegroundColor DarkGray
    foreach ($w in (Get-EnvironmentWarnings)) {
        Write-Host "  $($script:Glyph.Warn) " -NoNewline -ForegroundColor Yellow
        Write-Host (Format-UiCut $w ($script:Ui.Width - 6)) -ForegroundColor DarkYellow
    }
    Write-UiRule
    Write-Host ''
}

function Write-RunningLine {
    <# Laufende Einstellung mit Fortschrittsbalken - wird danach überschrieben. #>
    param([hashtable]$Tweak, [int]$Index, [int]$Total)
    if ($script:Ui.Plain) { return }

    $counter = '  [{0}/{1}] ' -f $Index.ToString().PadLeft($Total.ToString().Length), $Total
    $barWidth = 14
    $ratio = if ($Total -gt 0) { ($Index - 1) / $Total } else { 0 }
    $fill = [int][Math]::Round($barWidth * $ratio)
    $percent = '{0,3:0}% ' -f ($ratio * 100)
    $rest = $script:Ui.Width - $counter.Length - $barWidth - $percent.Length - 4
    $text = Format-UiCut ("$($Tweak.ModuleName) $($script:Glyph.Sep) $($Tweak.Name)") ([Math]::Max(10, $rest))

    Write-Host "`r$counter" -NoNewline -ForegroundColor DarkGray
    Write-Host (([string]$script:Glyph.Full) * $fill) -NoNewline -ForegroundColor Cyan
    Write-Host (([string]$script:Glyph.Empty) * ($barWidth - $fill)) -NoNewline -ForegroundColor DarkGray
    Write-Host " $percent" -NoNewline -ForegroundColor DarkGray
    Write-Host $text.PadRight([Math]::Max(0, $script:Ui.Width - $counter.Length - $barWidth - $percent.Length - 3)) -NoNewline -ForegroundColor DarkGray
}

function Write-TweakLine {
    <# Ergebniszeile einer Einstellung. #>
    param(
        [hashtable]$Tweak, [int]$Index, [int]$Total,
        [string]$Symbol, [string]$Status = '', [string]$StatusColor = 'DarkGray'
    )
    $counter = '  [{0}/{1}] ' -f $Index.ToString().PadLeft($Total.ToString().Length), $Total
    $prefix = "$(Format-UiCut $Tweak.ModuleName 24) $($script:Glyph.Sep) "
    $nameSpace = $script:Ui.Width - $counter.Length - 2 - $prefix.Length - $Status.Length - 3
    $name = Format-UiCut $Tweak.Name ([Math]::Max(10, $nameSpace))
    $pad = ' ' * [Math]::Max(1, $script:Ui.Width - $counter.Length - 2 - $prefix.Length - $name.Length - $Status.Length - 2)

    if (-not $script:Ui.Plain) { Write-Host "`r" -NoNewline }
    Write-Host $counter -NoNewline -ForegroundColor DarkGray
    Write-Host "$Symbol " -NoNewline -ForegroundColor $StatusColor
    Write-Host $prefix -NoNewline -ForegroundColor DarkGray
    Write-Host $name -NoNewline -ForegroundColor Gray
    Write-Host $pad -NoNewline
    Write-Host $Status -ForegroundColor $StatusColor
}

function Show-RunFooter {
    param($Stats, $Session, [switch]$Preview, [timespan]$Elapsed, [string[]]$Warnings)
    Write-Host ''
    Write-UiRule
    if ($Preview) {
        Write-Host '  ' -NoNewline
        Write-Host ("{0} {1} Änderungen wären nötig" -f $script:Glyph.Run, $Stats.Planned) -NoNewline -ForegroundColor Cyan
        Write-Host ("     {0} {1} bereits gesetzt" -f $script:Glyph.Skip, $Stats.Unchanged) -NoNewline -ForegroundColor DarkGray
        Write-Host ("     {0:mm\:ss}" -f $Elapsed) -ForegroundColor DarkGray
        Write-Host '  Vorschau - es wurde nichts verändert.' -ForegroundColor Yellow
    }
    else {
        Write-Host '  ' -NoNewline
        Write-Host ("{0} {1} Änderungen" -f $script:Glyph.Ok, $Stats.Changed) -NoNewline -ForegroundColor $(if ($Stats.Changed) { 'Green' } else { 'DarkGray' })
        Write-Host ("     {0} {1} bereits gesetzt" -f $script:Glyph.Skip, $Stats.Unchanged) -NoNewline -ForegroundColor DarkGray
        Write-Host ("     {0} {1} Hinweise" -f $script:Glyph.Warn, $Stats.Warnings) -NoNewline -ForegroundColor $(if ($Stats.Warnings) { 'Yellow' } else { 'DarkGray' })
        Write-Host ("     {0:mm\:ss}" -f $Elapsed) -ForegroundColor DarkGray
    }
    if ($Warnings.Count) {
        Write-Host ''
        Write-Host '  Hinweise:' -ForegroundColor Yellow
        foreach ($w in $Warnings) { Write-Host "    $($script:Glyph.Warn) $w" -ForegroundColor DarkYellow }
    }
    Write-Host ''
    if ($Session.JournalFile -and (Test-Path -LiteralPath $Session.JournalFile)) {
        Write-Host '  Sicherung    ' -NoNewline -ForegroundColor DarkGray
        Write-Host $Session.JournalFile -ForegroundColor Gray
        Write-Host '  Rückgängig   ' -NoNewline -ForegroundColor DarkGray
        Write-Host 'bye2spy.ps1 -Restore Latest' -ForegroundColor Gray
    }
    Write-Host '  Protokoll    ' -NoNewline -ForegroundColor DarkGray
    Write-Host $Session.LogFile -ForegroundColor Gray
    if (-not $Preview -and $Stats.Changed -gt 0) {
        Write-Host ''
        Write-Host "  $($script:Glyph.Run) Neustart empfohlen, damit alle Richtlinien greifen." -ForegroundColor Cyan
    }
    Write-Host ''
}

#endregion

function Invoke-Bye2Spy {
    param([object[]]$Tweaks, [switch]$Preview, [bool]$RestorePoint = $true)

    Initialize-B2SUi -ForcePlain:$Detailed
    $session = Start-B2SSession -Root $Root -WhatIf:$Preview
    $sys = Get-B2SSystemInfo
    $start = Get-Date
    $script:Ui.Warnings = New-Object System.Collections.ArrayList

    # Ausgabe übernehmen: alles landet weiterhin im Protokoll, auf der Konsole nur das Wesentliche
    Set-B2SLogSink {
        param($Message, $Level)
        $text = "$Message".Trim()
        if ($Level -eq 'Warn' -or $Level -eq 'Error') {
            if ($text) { [void]$script:Ui.Warnings.Add($text) }
            if ($script:Ui.Plain -and $text) { Write-Host "      $($script:Glyph.Warn) $text" -ForegroundColor Yellow }
            return
        }
        # Im ausführlichen Modus nur die Detailzeilen - die Überschrift liefert die Ergebniszeile
        if (-not $script:Ui.Plain -or $Level -eq 'Step') { return }
        if ($text) { Write-Host "      $text" -ForegroundColor DarkGray }
    }

    try {
        Write-B2SLog "bye2spy $Version - $($sys.ProductName) $($sys.Version) (Build $($sys.Build)) - $($Tweaks.Count) Einstellungen" Step
        Show-RunHeader -Sys $sys -Count $Tweaks.Count -Preview:$Preview -RestorePoint $RestorePoint

        if ($RestorePoint -and -not $Preview) {
            $before = (Get-B2SStats).Warnings
            if (-not $script:Ui.Plain) {
                Write-Host "  $($script:Glyph.Run) Systemwiederherstellungspunkt wird erstellt ..." -NoNewline -ForegroundColor DarkGray
            }
            New-B2SRestorePoint
            if (-not $script:Ui.Plain) {
                $failed = (Get-B2SStats).Warnings -gt $before
                Write-Host "`r  " -NoNewline
                if ($failed) { Write-Host "$($script:Glyph.Warn) Systemwiederherstellungspunkt nicht erstellt (siehe Hinweise)      " -ForegroundColor Yellow }
                else { Write-Host "$($script:Glyph.Ok) Systemwiederherstellungspunkt erstellt                         " -ForegroundColor Green }
            }
            Write-Host ''
        }

        $n = 0
        foreach ($t in $Tweaks) {
            $n++
            Write-RunningLine -Tweak $t -Index $n -Total $Tweaks.Count

            $before = Get-B2SStats
            $warnBefore = $script:Ui.Warnings.Count
            Invoke-B2STweak -Tweak $t
            $after = Get-B2SStats

            $changed = ($after.Changed - $before.Changed) + ($after.Planned - $before.Planned)
            $warned = $script:Ui.Warnings.Count - $warnBefore
            if ($warned -gt 0) {
                $sym = $script:Glyph.Warn; $color = 'Yellow'
                $status = "$warned Hinweis$(if ($warned -gt 1) { 'e' })"
            }
            elseif ($changed -gt 0) {
                $sym = $script:Glyph.Ok; $color = 'Green'
                $status = if ($Preview) { "$changed offen" } else { "$changed geändert" }
                if ($Preview) { $color = 'Cyan' }
            }
            else {
                $sym = $script:Glyph.Skip; $color = 'DarkGray'
                $status = 'bereits aktiv'
            }
            Write-TweakLine -Tweak $t -Index $n -Total $Tweaks.Count -Symbol $sym -Status $status -StatusColor $color
            if ($warned -gt 0 -and -not $script:Ui.Plain) {
                foreach ($w in $script:Ui.Warnings[($warnBefore)..($script:Ui.Warnings.Count - 1)]) {
                    Write-Host ('      ' + (Format-UiCut $w ($script:Ui.Width - 8))) -ForegroundColor DarkYellow
                }
            }
        }
    }
    finally {
        # Abschlusszeilen nur ins Protokoll (die Konsole bekommt die Zusammenfassung unten)
        $stats = Get-B2SStats
        Write-B2SLog ('Fertig: {0} Änderungen, {1} Werte waren bereits gesetzt, {2} Warnungen.' -f $stats.Changed, $stats.Unchanged, $stats.Warnings) OK
        if ($session.JournalFile -and (Test-Path -LiteralPath $session.JournalFile)) {
            Write-B2SLog "Sicherung (für Rückgängig): $($session.JournalFile)" Info
        }
        Write-B2SLog "Protokoll: $($session.LogFile)" Info
        Set-B2SLogSink $null
    }

    Show-RunFooter -Stats $stats -Session $session -Preview:$Preview -Elapsed ((Get-Date) - $start) -Warnings @($script:Ui.Warnings)
    $stats
}

function Get-BackupFiles {
    @(Get-ChildItem -LiteralPath $BackupDir -Filter 'bye2spy_*.json' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
}

function Invoke-Bye2SpyRestore {
    param([string[]]$Files)
    [void](Start-B2SSession -Root $Root)
    # Neueste zuerst, damit mehrere Durchläufe sauber zurückgerollt werden
    foreach ($f in ($Files | Sort-Object -Descending)) {
        Restore-B2SJournal -File $f
        Rename-Item -LiteralPath $f -NewName ((Split-Path $f -Leaf) + '.restored') -ErrorAction SilentlyContinue
    }
}

function Resolve-RestoreSpec {
    param([string]$Spec)
    $all = Get-BackupFiles
    switch ($Spec) {
        'Latest' { @($all | Select-Object -First 1 | ForEach-Object { $_.FullName }) }
        'All'    { @($all | ForEach-Object { $_.FullName }) }
        default  { @((Resolve-Path -LiteralPath $Spec -ErrorAction Stop).Path) }
    }
}

function Get-StatusColor([string]$State) {
    switch ($State) {
        'Aktiv'     { 'Green' }
        'Teilweise' { 'Yellow' }
        'Offen'     { 'Gray' }
        default     { 'DarkGray' }
    }
}

function Show-TweakTable {
    param([switch]$WithStatus)
    Reset-B2SCache
    foreach ($m in $Modules) {
        Write-Host ''
        Write-Host ("{0}  [{1}]" -f $m.Name, $m.Id) -ForegroundColor Cyan
        foreach ($t in $m.Tweaks) {
            $rec = if ($t.Recommended) { '*' } else { ' ' }
            if ($WithStatus) {
                $s = Get-B2STweakStatus -Tweak $t
                Write-Host ('  {0,-10}{1} {2,-7} {3,-28} {4}' -f $s, $rec, (Get-B2SRiskLabel $t.Risk), $t.Id, $t.Name) -ForegroundColor (Get-StatusColor $s)
            }
            else {
                Write-Host ('  {0} {1,-7} {2,-28} {3}' -f $rec, (Get-B2SRiskLabel $t.Risk), $t.Id, $t.Name)
            }
        }
    }
    Write-Host ''
    Write-Host '  * = in "Empfohlen" enthalten' -ForegroundColor DarkGray
    if ($Presets.Count) {
        Write-Host ''
        Write-Host '  Presets (-Preset <Name>)' -ForegroundColor Cyan
        Write-Host '    Recommended   alle Einstellungen mit geringem Risiko' -ForegroundColor Gray
        Write-Host '    All           alles, auch mittleres und hohes Risiko' -ForegroundColor Gray
        foreach ($p in $Presets) {
            Write-Host ("    {0,-13} {1} ({2} Einstellungen)" -f $p.Id, $p.Description, (Get-PresetTweaks $p).Count) -ForegroundColor Gray
        }
    }
}

function Wait-IfElevated {
    if ($Elevated) { [void](Read-Host "`nEnter drücken zum Schließen") }
}

#endregion

#region Konsolenmenü ----------------------------------------------------------------------

function Confirm-Console {
    param([object[]]$Tweaks)
    $high = @($Tweaks | Where-Object { $_.Risk -eq 'High' })
    $med = @($Tweaks | Where-Object { $_.Risk -eq 'Medium' })
    Write-Host ''
    Write-Host "$($Tweaks.Count) Einstellungen werden angewendet ($($med.Count) mit mittlerem, $($high.Count) mit hohem Risiko)." -ForegroundColor Cyan
    foreach ($t in @($med) + @($high)) {
        Write-Host ("  [{0}] {1}" -f (Get-B2SRiskLabel $t.Risk), $t.Name) -ForegroundColor $(if ($t.Risk -eq 'High') { 'Red' } else { 'Yellow' })
        if ($t.Warning) { Write-Host "         $($t.Warning)" -ForegroundColor DarkGray }
    }
    $a = Read-Host 'Fortfahren? (j/n)'
    return ($a -match '^(j|ja|y|yes)$')
}

function Wait-AnyKey {
    param([string]$Text = 'Beliebige Taste = zurück zum Menü')
    Write-Host ''
    Write-Host $Text -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
}

function Get-WrappedText {
    param([string]$Text, [int]$Width, [int]$MaxLines)
    $out = @()
    $line = ''
    foreach ($word in ($Text -split '\s+')) {
        if (($line.Length + $word.Length + 1) -gt $Width) {
            $out += $line
            $line = $word
            if ($out.Count -ge $MaxLines) { break }
        }
        else { $line = if ($line) { "$line $word" } else { $word } }
    }
    if ($out.Count -lt $MaxLines -and $line) { $out += $line }
    elseif ($out.Count -ge $MaxLines -and $line) { $out[$MaxLines - 1] = $out[$MaxLines - 1] + ' ...' }
    while ($out.Count -lt $MaxLines) { $out += '' }
    $out
}

function Write-Row {
    <# Schreibt eine Bildschirmzeile aus farbigen Segmenten, auf Fensterbreite gekürzt/aufgefüllt. #>
    param([object[]]$Segments, [bool]$Highlight = $false)
    $w = [Console]::WindowWidth - 1
    $bg = if ($Highlight) { [ConsoleColor]::DarkCyan } else { $script:MenuBg }
    $used = 0
    foreach ($s in $Segments) {
        $txt = [string]$s[0]
        if ($used + $txt.Length -gt $w) { $txt = $txt.Substring(0, [Math]::Max(0, $w - $used)) }
        if ($txt.Length) {
            $fg = if ($Highlight) { [ConsoleColor]::White } else { $s[1] }
            Write-Host $txt -NoNewline -ForegroundColor $fg -BackgroundColor $bg
        }
        $used += $txt.Length
    }
    Write-Host (' ' * [Math]::Max(0, $w - $used)) -BackgroundColor $bg
}

function Get-RiskColor([string]$Risk) {
    switch ($Risk) {
        'High'   { 'Red' }
        'Medium' { 'Yellow' }
        default  { 'Green' }
    }
}

function Get-MenuRows {
    param([hashtable]$Expanded)
    $rows = New-Object System.Collections.ArrayList
    foreach ($m in $Modules) {
        [void]$rows.Add([pscustomobject]@{ Type = 'Module'; Module = $m; Tweak = $null })
        if ($Expanded[$m.Id]) {
            foreach ($t in $m.Tweaks) { [void]$rows.Add([pscustomobject]@{ Type = 'Tweak'; Module = $m; Tweak = $t }) }
        }
    }
    , $rows.ToArray()
}

function Update-MenuStatus {
    param([hashtable]$State)
    Clear-Host
    Write-Host ''
    Write-Host '  Prüfe den aktuellen Zustand aller Einstellungen (einige Sekunden) ...' -ForegroundColor Cyan
    Reset-B2SCache
    foreach ($t in $AllTweaks) { $State[$t.Id] = Get-B2STweakStatus -Tweak $t }
    Clear-Host
}

function Show-MenuScreen {
    param($Rows, [int]$Cursor, [int]$Top, [int]$ListHeight, [hashtable]$Selected, [hashtable]$Expanded, [hashtable]$State, [bool]$RestorePoint, [string]$Message)

    $w = [Console]::WindowWidth - 1
    $i = $script:SysInfo
    $selCount = @($AllTweaks | Where-Object { $Selected[$_.Id] }).Count
    $med = @($AllTweaks | Where-Object { $Selected[$_.Id] -and $_.Risk -eq 'Medium' }).Count
    $high = @($AllTweaks | Where-Object { $Selected[$_.Id] -and $_.Risk -eq 'High' }).Count

    [Console]::SetCursorPosition(0, 0)
    Write-Row @(@(" bye2spy v$Version", 'Cyan'), @('  -  Windows 11 Telemetrie, Copilot & KI abschalten', 'Gray'))
    Write-Row @(, @((" {0} {1} (Build {2}, {3})  |  {4}{5}" -f $i.ProductName, $i.Version, $i.Build, $i.Edition, $i.RunAs, $(if ($i.IsAdmin) { '' } else { '  |  OHNE ADMINRECHTE' })), 'DarkGray'))
    Write-Row @(
        @(" Ausgewählt: $selCount / $($AllTweaks.Count)", 'White'),
        @("   (Mittel: $med, Hoch: $high)", $(if ($high) { 'Red' } elseif ($med) { 'Yellow' } else { 'DarkGray' })),
        @("   Wiederherstellungspunkt: $(if ($RestorePoint) { 'ja' } else { 'nein' })", 'DarkGray')
    )
    Write-Row @(, @(('-' * $w), 'DarkGray'))

    for ($r = $Top; $r -lt $Top + $ListHeight; $r++) {
        if ($r -ge $Rows.Count) { Write-Row @(, @('', 'Gray')); continue }
        $row = $Rows[$r]
        $hl = ($r -eq $Cursor)
        if ($row.Type -eq 'Module') {
            $m = $row.Module
            $n = @($m.Tweaks | Where-Object { $Selected[$_.Id] }).Count
            $active = @($m.Tweaks | Where-Object { $State[$_.Id] -eq 'Aktiv' }).Count
            $box = if ($n -eq $m.Tweaks.Count) { '[x]' } elseif ($n -gt 0) { '[-]' } else { '[ ]' }
            $arrow = if ($Expanded[$m.Id]) { 'v' } else { '>' }
            Write-Row @(
                @(" $arrow $box ", 'White'),
                @($m.Name, 'Cyan'),
                @("   $n/$($m.Tweaks.Count) gewählt, $active aktiv", 'DarkGray')
            ) $hl
        }
        else {
            $t = $row.Tweak
            $box = if ($Selected[$t.Id]) { '[x]' } else { '[ ]' }
            $st = $State[$t.Id]
            $stText = switch ($st) { 'Aktiv' { 'aktiv' } 'Teilweise' { 'teilweise' } 'Offen' { 'offen' } default { '-' } }
            $prefix = "       $box "
            $risk = '{0,-7}' -f (Get-B2SRiskLabel $t.Risk)
            $nameWidth = [Math]::Max(10, $w - $prefix.Length - $risk.Length - 12)
            $name = $t.Name
            if ($name.Length -gt $nameWidth) { $name = $name.Substring(0, $nameWidth - 3) + '...' }
            Write-Row @(
                @($prefix, 'White'),
                @($risk, (Get-RiskColor $t.Risk)),
                @($name.PadRight($nameWidth), 'Gray'),
                @((' ' + $stText.PadLeft(10)), (Get-StatusColor $st))
            ) $hl
        }
    }

    Write-Row @(, @(('-' * $w), 'DarkGray'))
    $cur = $Rows[$Cursor]
    if ($cur.Type -eq 'Module') { $desc = $cur.Module.Description }
    else {
        $desc = $cur.Tweak.Description
        if ($cur.Tweak.Warning) { $desc = "ACHTUNG: $($cur.Tweak.Warning)  |  $desc" }
    }
    $descColor = if ($cur.Type -eq 'Tweak' -and $cur.Tweak.Warning) { 'Yellow' } else { 'Gray' }
    foreach ($l in (Get-WrappedText -Text $desc -Width ($w - 2) -MaxLines 3)) { Write-Row @(, @(" $l", $descColor)) }
    Write-Row @(, @(('-' * $w), 'DarkGray'))
    Write-Row @(, @(' Pfeile bewegen  Leertaste an/aus  Enter/Rechts aufklappen  Links zuklappen  Tab alle auf/zu  D Details', 'DarkGray'))
    Write-Row @(, @(' E Empfohlen  K Preset  A Alles  N Nichts  S Status  V Vorschau  W ANWENDEN  R Rückgängig  P Wiederherst.punkt  Q Ende', 'DarkGray'))
    Write-Row @(, @(" $Message", 'Yellow'))
}

function Get-PresetChoices {
    <# Wählbare Presets: die beiden eingebauten plus die Dateien aus .\presets. #>
    $choices = New-Object System.Collections.ArrayList
    [void]$choices.Add([pscustomobject]@{
        Name        = 'Empfohlen'
        Description = 'Alle Einstellungen mit geringem Risiko - der sichere Standard.'
        Notes       = @()
        Tweaks      = @($AllTweaks | Where-Object { $_.Recommended })
    })
    [void]$choices.Add([pscustomobject]@{
        Name        = 'Alles'
        Description = 'Jede Einstellung, auch mit mittlerem und hohem Risiko. Vor dem Anwenden prüfen.'
        Notes       = @()
        Tweaks      = @($AllTweaks)
    })
    foreach ($p in $Presets) {
        [void]$choices.Add([pscustomobject]@{
            Name        = $p.Name
            Description = $p.Description
            Notes       = @($p.Notes)
            Tweaks      = @(Get-PresetTweaks $p)
        })
    }
    , $choices.ToArray()
}

function Show-PresetScreen {
    param($Choices, [int]$Cursor, [int]$Top, [int]$ListHeight, [int]$NoteHeight)

    $w = [Console]::WindowWidth - 1
    [Console]::SetCursorPosition(0, 0)
    Write-Row @(@(' Presets', 'Cyan'), @('  -  fertige Zusammenstellungen übernehmen', 'Gray'))
    Write-Row @(, @(('-' * $w), 'DarkGray'))

    $nameWidth = [Math]::Max(12, [Math]::Min(34, $w - 42))
    for ($r = $Top; $r -lt $Top + $ListHeight; $r++) {
        if ($r -ge $Choices.Count) { Write-Row @(, @('', 'Gray')); continue }
        $c = $Choices[$r]
        $med = @($c.Tweaks | Where-Object { $_.Risk -eq 'Medium' }).Count
        $high = @($c.Tweaks | Where-Object { $_.Risk -eq 'High' }).Count
        $name = $c.Name
        if ($name.Length -gt $nameWidth) { $name = $name.Substring(0, $nameWidth - 3) + '...' }
        Write-Row @(
            @('   ', 'White'),
            @($name.PadRight($nameWidth), 'Cyan'),
            @(('{0,3} Einstellungen' -f $c.Tweaks.Count), 'Gray'),
            @("   (Mittel: $med, Hoch: $high)", $(if ($high) { 'Red' } elseif ($med) { 'Yellow' } else { 'DarkGray' }))
        ) ($r -eq $Cursor)
    }

    Write-Row @(, @(('-' * $w), 'DarkGray'))
    $cur = $Choices[$Cursor]
    foreach ($l in (Get-WrappedText -Text $cur.Description -Width ($w - 2) -MaxLines 2)) { Write-Row @(, @(" $l", 'Gray')) }
    $notes = @(@($cur.Notes) | ForEach-Object { "  - $_" })
    while ($notes.Count -lt $NoteHeight) { $notes += '' }
    for ($n = 0; $n -lt $NoteHeight; $n++) { Write-Row @(, @(" $($notes[$n])", 'DarkYellow')) }
    Write-Row @(, @(('-' * $w), 'DarkGray'))
    Write-Row @(, @(' Pfeile bewegen  Enter übernehmen  Esc zurück zum Menü', 'DarkGray'))
}

function Show-PresetPicker {
    <# Preset-Auswahl mit Pfeiltasten. Gibt das gewählte Preset zurück oder $null. #>
    $choices = Get-PresetChoices
    # Notizbereich so hoch wie das Preset mit den meisten Hinweisen, damit das Bild nicht springt
    $noteHeight = [Math]::Min(6, [Math]::Max(1, (@($choices | ForEach-Object { @($_.Notes).Count }) | Measure-Object -Maximum).Maximum))
    $cursor = 0
    $top = 0
    $lastSize = ''
    while ($true) {
        $size = '{0}x{1}' -f [Console]::WindowWidth, [Console]::WindowHeight
        if ($size -ne $lastSize) { Clear-Host; $lastSize = $size }

        $listHeight = [Math]::Max(3, [Math]::Min($choices.Count, [Console]::WindowHeight - 7 - $noteHeight))
        if ($cursor -lt $top) { $top = $cursor }
        if ($cursor -ge $top + $listHeight) { $top = $cursor - $listHeight + 1 }
        if ($top -gt [Math]::Max(0, $choices.Count - $listHeight)) { $top = [Math]::Max(0, $choices.Count - $listHeight) }

        Show-PresetScreen -Choices $choices -Cursor $cursor -Top $top -ListHeight $listHeight -NoteHeight $noteHeight

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow'   { $cursor-- }
            'DownArrow' { $cursor++ }
            'PageUp'    { $cursor -= $listHeight }
            'PageDown'  { $cursor += $listHeight }
            'Home'      { $cursor = 0 }
            'End'       { $cursor = $choices.Count - 1 }
            'Enter'     { Clear-Host; return $choices[$cursor] }
            'Spacebar'  { Clear-Host; return $choices[$cursor] }
            'Escape'    { Clear-Host; return $null }
            'LeftArrow' { Clear-Host; return $null }
            default {
                if ("$($key.KeyChar)".ToUpper() -eq 'Q') { Clear-Host; return $null }
            }
        }
        # Am Rand umlaufen, die Liste ist kurz
        if ($cursor -lt 0) { $cursor = $choices.Count - 1 }
        if ($cursor -ge $choices.Count) { $cursor = 0 }
    }
}

function Show-RestoreMenu {
    Clear-Host
    $files = Get-BackupFiles
    if (-not $files.Count) {
        Write-Host ''
        Write-Host '  Keine Sicherungen vorhanden.' -ForegroundColor Yellow
        Wait-AnyKey
        return
    }
    Write-Host ''
    Write-Host '  Vorhandene Sicherungen (neueste zuerst):' -ForegroundColor Cyan
    for ($i = 0; $i -lt $files.Count; $i++) { Write-Host ('  {0,3}) {1}' -f ($i + 1), $files[$i].Name) }
    Write-Host '    A) alle Sicherungen (neueste zuerst)'
    Write-Host ''
    $r = (Read-Host '  Welche Sicherung wiederherstellen? (leer = abbrechen)').Trim()
    if ($r -match '^[aA]$') { Invoke-Bye2SpyRestore -Files ($files | ForEach-Object { $_.FullName }) }
    elseif ($r -match '^\d+$' -and [int]$r -ge 1 -and [int]$r -le $files.Count) { Invoke-Bye2SpyRestore -Files @($files[[int]$r - 1].FullName) }
    else { return }
    Wait-AnyKey
}

function Show-Menu {
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
        Write-Host 'Keine interaktive Konsole verfügbar. Nutze z. B.: .\bye2spy.ps1 -Preset Recommended   (Hilfe: Get-Help .\bye2spy.ps1 -Full)' -ForegroundColor Yellow
        return
    }

    try { $Host.UI.RawUI.WindowTitle = "bye2spy $Version" } catch { }
    $script:SysInfo = Get-B2SSystemInfo
    $script:MenuBg = $Host.UI.RawUI.BackgroundColor
    if ([int]$script:MenuBg -lt 0 -or [int]$script:MenuBg -gt 15) { $script:MenuBg = [ConsoleColor]::Black }

    $selected = @{}
    foreach ($t in $AllTweaks) { $selected[$t.Id] = [bool]$t.Recommended }
    $expanded = @{}
    foreach ($m in $Modules) { $expanded[$m.Id] = $false }
    $state = @{}
    $restorePoint = -not $NoRestorePoint
    $cursor = 0
    $top = 0
    $message = 'Empfohlene Einstellungen sind vorausgewählt. Mit Enter ein Modul aufklappen.'

    # Beim Start Hinweise zu Adminrechten/Edition einmal anzeigen
    $warnings = @(Get-EnvironmentWarnings)
    Update-MenuStatus $state
    if ($warnings.Count) {
        Write-Host ''
        foreach ($w in $warnings) { Write-Host "  ! $w" -ForegroundColor Yellow }
        Wait-AnyKey 'Beliebige Taste = weiter'
        Clear-Host
    }

    $lastSize = ''
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            $size = '{0}x{1}' -f [Console]::WindowWidth, [Console]::WindowHeight
            if ($size -ne $lastSize) { Clear-Host; $lastSize = $size }

            $rows = Get-MenuRows $expanded
            if ($cursor -ge $rows.Count) { $cursor = $rows.Count - 1 }
            if ($cursor -lt 0) { $cursor = 0 }
            $listHeight = [Math]::Max(3, [Console]::WindowHeight - 13)
            if ($cursor -lt $top) { $top = $cursor }
            if ($cursor -ge $top + $listHeight) { $top = $cursor - $listHeight + 1 }
            if ($top -gt [Math]::Max(0, $rows.Count - $listHeight)) { $top = [Math]::Max(0, $rows.Count - $listHeight) }

            Show-MenuScreen -Rows $rows -Cursor $cursor -Top $top -ListHeight $listHeight -Selected $selected `
                -Expanded $expanded -State $state -RestorePoint $restorePoint -Message $message
            $message = ''

            $key = [Console]::ReadKey($true)
            $row = $rows[$cursor]
            $char = "$($key.KeyChar)".ToUpper()

            switch ($key.Key) {
                'UpArrow'   { $cursor--; continue }
                'DownArrow' { $cursor++; continue }
                'PageUp'    { $cursor -= $listHeight; continue }
                'PageDown'  { $cursor += $listHeight; continue }
                'Home'      { $cursor = 0; continue }
                'End'       { $cursor = $rows.Count - 1; continue }
                'Spacebar' {
                    if ($row.Type -eq 'Module') {
                        $all = @($row.Module.Tweaks | Where-Object { -not $selected[$_.Id] }).Count -eq 0
                        foreach ($t in $row.Module.Tweaks) { $selected[$t.Id] = -not $all }
                    }
                    else { $selected[$row.Tweak.Id] = -not $selected[$row.Tweak.Id] }
                    continue
                }
                'RightArrow' { if ($row.Type -eq 'Module') { $expanded[$row.Module.Id] = $true }; continue }
                'LeftArrow' {
                    if ($row.Type -eq 'Tweak') {
                        $expanded[$row.Module.Id] = $false
                        # Cursor auf die Modulzeile in der eingeklappten Liste setzen
                        $cursor = 0
                        foreach ($r in (Get-MenuRows $expanded)) { if ($r.Type -eq 'Module' -and $r.Module.Id -eq $row.Module.Id) { break }; $cursor++ }
                    }
                    else { $expanded[$row.Module.Id] = $false }
                    continue
                }
                'Tab' {
                    $anyOpen = @($expanded.Values | Where-Object { $_ }).Count -gt 0
                    foreach ($m in $Modules) { $expanded[$m.Id] = -not $anyOpen }
                    if ($anyOpen) { $cursor = 0; $top = 0 }
                    continue
                }
                'Enter' {
                    if ($row.Type -eq 'Module') { $expanded[$row.Module.Id] = -not $expanded[$row.Module.Id]; continue }
                    $char = 'D'
                }
                'Escape' { $char = 'Q' }
            }

            switch ($char) {
                'E' { foreach ($t in $AllTweaks) { $selected[$t.Id] = [bool]$t.Recommended }; $message = 'Empfohlene Auswahl gesetzt (nur geringes Risiko).' }
                'K' {
                    $pick = Show-PresetPicker
                    if ($pick) {
                        $ids = @($pick.Tweaks | ForEach-Object { $_.Id })
                        foreach ($t in $AllTweaks) { $selected[$t.Id] = ($ids -contains $t.Id) }
                        $message = "Preset '$($pick.Name)' übernommen: $($ids.Count) Einstellungen ausgewählt."
                    }
                    else { $message = 'Preset-Auswahl abgebrochen.' }
                    Clear-Host
                }
                'A' { foreach ($t in $AllTweaks) { $selected[$t.Id] = $true }; $message = 'ALLES ausgewählt - inkl. Einstellungen mit mittlerem/hohem Risiko. Vor dem Anwenden prüfen!' }
                'N' { foreach ($t in $AllTweaks) { $selected[$t.Id] = $false }; $message = 'Auswahl geleert.' }
                'P' { $restorePoint = -not $restorePoint }
                'D' {
                    if ($row.Type -eq 'Tweak') {
                        Clear-Host
                        Write-Host ''
                        Write-Host (Get-B2STweakDetails -Tweak $row.Tweak)
                        Write-Host ('Aktueller Status: ' + $state[$row.Tweak.Id]) -ForegroundColor (Get-StatusColor $state[$row.Tweak.Id])
                        Wait-AnyKey
                        Clear-Host
                    }
                    else { $message = 'Details gibt es für einzelne Einstellungen - Modul mit Enter aufklappen.' }
                }
                'S' { Update-MenuStatus $state; $message = 'Status aktualisiert.' }
                'V' {
                    $sel = @($AllTweaks | Where-Object { $selected[$_.Id] })
                    if (-not $sel.Count) { $message = 'Nichts ausgewählt.'; break }
                    Clear-Host
                    [Console]::CursorVisible = $true
                    [void](Invoke-Bye2Spy -Tweaks $sel -Preview)
                    Wait-AnyKey 'VORSCHAU beendet - es wurde nichts geändert. Beliebige Taste = zurück (nach oben scrollen für Details)'
                    [Console]::CursorVisible = $false
                    Clear-Host
                }
                'W' {
                    $sel = @($AllTweaks | Where-Object { $selected[$_.Id] })
                    if (-not $sel.Count) { $message = 'Nichts ausgewählt.'; break }
                    if (-not $script:SysInfo.IsAdmin) { $message = 'Zum Anwenden sind Administratorrechte nötig.'; break }
                    Clear-Host
                    [Console]::CursorVisible = $true
                    if (Confirm-Console $sel) {
                        $stats = @(Invoke-Bye2Spy -Tweaks $sel -RestorePoint $restorePoint)[-1]
                        if ($stats.Changed -gt 0 -and (Read-Host "`nJetzt neu starten? (j/n)") -match '^(j|ja|y|yes)$') { Restart-Computer -Force }
                        Update-MenuStatus $state
                        $message = "Angewendet: $($stats.Changed) Änderungen, $($stats.Warnings) Warnungen. Neustart empfohlen."
                    }
                    else { $message = 'Abgebrochen.' }
                    [Console]::CursorVisible = $false
                    Clear-Host
                }
                'R' {
                    [Console]::CursorVisible = $true
                    Show-RestoreMenu
                    [Console]::CursorVisible = $false
                    Update-MenuStatus $state
                }
                'Q' {
                    Clear-Host
                    return
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }
}

#endregion

#region Einstieg -----------------------------------------------------------------------

if ($List) {
    Write-Banner
    Show-TweakTable
    exit
}

if ($Status) {
    Write-Banner
    Show-TweakTable -WithStatus
    Wait-IfElevated
    exit
}

if ($Restore) {
    Write-Banner
    $files = @(Resolve-RestoreSpec $Restore)
    if (-not $files.Count) { Write-Host 'Keine Sicherung gefunden.' -ForegroundColor Yellow; Wait-IfElevated; exit 1 }
    if (-not $Yes) {
        $files | ForEach-Object { Write-Host "  $_" }
        if ((Read-Host 'Diese Sicherung(en) zurückspielen? (j/n)') -notmatch '^(j|ja|y|yes)$') { exit }
    }
    Invoke-Bye2SpyRestore -Files $files
    Wait-IfElevated
    exit
}

if ($Preset -or $Module.Count -or $Tweak.Count) {
    Initialize-B2SUi -ForcePlain:$Detailed
    if ($Preset -and (Get-PresetNames) -notcontains $Preset) {
        Write-Host ''
        Write-Host "  Unbekanntes Preset: $Preset" -ForegroundColor Red
        Write-Host "  Verfügbar: $((Get-PresetNames) -join ', ')" -ForegroundColor Gray
        Wait-IfElevated
        exit 1
    }
    $sel = Select-Tweaks -PresetName $Preset -ModuleIds $Module -TweakIds $Tweak -ExcludeIds $Exclude
    if (-not $sel.Count) { Write-Host 'Keine Einstellungen ausgewählt.' -ForegroundColor Yellow; Wait-IfElevated; exit 1 }
    $presetDef = Get-Preset $Preset
    if ($presetDef) { Show-PresetInfo -PresetDef $presetDef -Count $sel.Count }
    if (-not $Yes -and -not $DryRun) {
        if (-not (Confirm-Console $sel)) { exit }
    }
    [void](Invoke-Bye2Spy -Tweaks $sel -Preview:$DryRun -RestorePoint (-not $NoRestorePoint))
    Wait-IfElevated
    exit
}

Show-Menu

#endregion
