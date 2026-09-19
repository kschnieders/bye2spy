<#
    bye2spy - Kernbibliothek

    Stellt alle Aktionen bereit, die die Module verwenden (Registry, Dienste, Aufgaben,
    Apps, optionale Features, Firewall, hosts-Datei, Defender-Einstellungen).
    Jede Änderung wird in einem JSON-Journal protokolliert, damit sie über
    Restore-B2SJournal rückgängig gemacht werden kann.
#>

$script:Journal     = New-Object System.Collections.ArrayList
$script:JournalFile = $null
$script:LogFile     = $null
$script:LogSink     = $null
$script:WhatIfMode  = $false
$script:Stats       = @{ Changed = 0; Unchanged = 0; Warnings = 0 }
$script:AppxCache   = $null
$script:TaskCache   = $null

$script:HostsFile   = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$script:HostsBegin  = '# >>> bye2spy BEGIN (nicht manuell bearbeiten)'
$script:HostsEnd    = '# <<< bye2spy END'

#region Logging ------------------------------------------------------------------

function Set-B2SLogSink {
    param([scriptblock]$Sink)
    $script:LogSink = $Sink
}

function Write-B2SLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Step', 'OK', 'Warn', 'Error', 'Change')]
        [string]$Level = 'Info'
    )
    if ($Level -eq 'Warn' -or $Level -eq 'Error') { $script:Stats.Warnings++ }

    $line = '[{0}] [{1,-6}] {2}' -f (Get-Date -Format 'HH:mm:ss'), $Level.ToUpper(), $Message
    if ($script:LogFile) {
        try { Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 } catch { }
    }
    if ($script:LogSink) {
        & $script:LogSink $Message $Level | Out-Null
        return
    }
    $color = switch ($Level) {
        'Step'   { 'Cyan' }
        'OK'     { 'Green' }
        'Warn'   { 'Yellow' }
        'Error'  { 'Red' }
        'Change' { 'DarkGray' }
        default  { 'Gray' }
    }
    Write-Host $Message -ForegroundColor $color
}

#endregion

#region Sitzung & Journal -----------------------------------------------------------

function Start-B2SSession {
    param(
        [Parameter(Mandatory)][string]$Root,
        [switch]$WhatIf
    )
    $script:WhatIfMode = [bool]$WhatIf
    $script:Journal.Clear()
    $script:Stats = @{ Changed = 0; Unchanged = 0; Warnings = 0 }
    $script:AppxCache = $null

    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $logDir = Join-Path $Root 'logs'
    $bakDir = Join-Path $Root 'backups'
    foreach ($d in $logDir, $bakDir) {
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    $script:LogFile = Join-Path $logDir "bye2spy_$stamp.log"
    if ($WhatIf) {
        $script:JournalFile = $null
    }
    else {
        $script:JournalFile = Join-Path $bakDir "bye2spy_$stamp.json"
    }
    [pscustomobject]@{ LogFile = $script:LogFile; JournalFile = $script:JournalFile }
}

function Get-B2SStats { [pscustomobject]$script:Stats }

function Add-B2SJournal {
    param([hashtable]$Entry)
    $Entry.Time = (Get-Date).ToString('s')
    [void]$script:Journal.Add([pscustomobject]$Entry)
    Save-B2SJournal
}

function Save-B2SJournal {
    if (-not $script:JournalFile -or $script:Journal.Count -eq 0) { return }
    ConvertTo-Json -InputObject @($script:Journal.ToArray()) -Depth 6 |
        Set-Content -LiteralPath $script:JournalFile -Encoding UTF8
}

function Restore-B2SJournal {
    param([Parameter(Mandatory)][string]$File)

    Write-B2SLog "Stelle Sicherung wieder her: $File" Step
    $raw = Get-Content -LiteralPath $File -Raw -Encoding UTF8
    $parsed = ConvertFrom-Json -InputObject $raw
    $entries = New-Object System.Collections.ArrayList
    foreach ($e in $parsed) { [void]$entries.Add($e) }
    $entries.Reverse()

    foreach ($e in $entries) {
        try {
            switch ($e.Kind) {
                'Registry' {
                    if ($e.Existed) {
                        $value = ConvertTo-B2SRegValue -Value $e.OldValue -Type $e.OldType
                        if (-not (Test-Path -LiteralPath $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
                        New-ItemProperty -LiteralPath $e.Path -Name $e.Name -Value $value -PropertyType $e.OldType -Force | Out-Null
                        Write-B2SLog "  $($e.Path)\$($e.Name) -> $($e.OldValue)" Change
                    }
                    else {
                        Remove-ItemProperty -LiteralPath $e.Path -Name $e.Name -ErrorAction SilentlyContinue
                        Write-B2SLog "  $($e.Path)\$($e.Name) entfernt" Change
                    }
                }
                'Task' {
                    Enable-ScheduledTask -TaskPath $e.TaskPath -TaskName $e.TaskName -ErrorAction Stop | Out-Null
                    Write-B2SLog "  Aufgabe aktiviert: $($e.TaskPath)$($e.TaskName)" Change
                }
                'Feature' {
                    Enable-WindowsOptionalFeature -Online -FeatureName $e.Name -NoRestart -All -ErrorAction Stop | Out-Null
                    Write-B2SLog "  Optionales Feature aktiviert: $($e.Name)" Change
                }
                'Firewall' {
                    Remove-NetFirewallRule -DisplayName $e.DisplayName -ErrorAction SilentlyContinue
                    Write-B2SLog "  Firewallregel entfernt: $($e.DisplayName)" Change
                }
                'Hosts' {
                    Remove-B2SHostsBlock
                }
                'MpPreference' {
                    $p = @{ $e.Name = $e.OldValue }
                    Set-MpPreference @p -ErrorAction Stop
                    Write-B2SLog "  Defender: $($e.Name) -> $($e.OldValue)" Change
                }
                'Appx' {
                    Write-B2SLog "  App '$($e.Name)' wurde entfernt und muss bei Bedarf manuell aus dem Microsoft Store neu installiert werden." Warn
                }
            }
        }
        catch {
            Write-B2SLog "  Wiederherstellung fehlgeschlagen ($($e.Kind) $($e.Path)$($e.TaskName)$($e.Name)): $($_.Exception.Message)" Warn
        }
    }
    Write-B2SLog 'Wiederherstellung abgeschlossen. Bitte Windows neu starten.' OK
}

#endregion

#region Registry -------------------------------------------------------------------

function Get-B2SRegValue {
    param([string]$Path, [string]$Name)
    $result = [pscustomobject]@{ Exists = $false; Type = $null; Value = $null }
    try {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($key.GetValueNames() -contains $Name) {
            $result.Exists = $true
            $result.Type = $key.GetValueKind($Name).ToString()
            $result.Value = $key.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
        }
    }
    catch { }
    $result
}

function ConvertTo-B2SRegValue {
    param($Value, [string]$Type)
    switch ($Type) {
        'Binary'      { return [byte[]]@($Value) }
        'MultiString' { return [string[]]@($Value) }
        'DWord'       { return [int]$Value }
        'QWord'       { return [long]$Value }
        default       { return [string]$Value }
    }
}

function Test-B2SValueEqual {
    param($A, $B)
    if ($null -eq $A -or $null -eq $B) { return ($null -eq $A -and $null -eq $B) }
    if ($A -is [array] -or $B -is [array]) { return ((@($A) -join "`n") -ceq (@($B) -join "`n")) }
    return ("$A" -eq "$B")
}

function Set-B2SReg {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'MultiString', 'Binary')]
        [string]$Type = 'DWord'
    )
    $old = Get-B2SRegValue -Path $Path -Name $Name
    if ($old.Exists -and (Test-B2SValueEqual $old.Value $Value)) {
        $script:Stats.Unchanged++
        return 'Unchanged'
    }
    $before = if ($old.Exists) { $old.Value } else { '<nicht gesetzt>' }
    if ($script:WhatIfMode) {
        Write-B2SLog "  [Vorschau] $Path\$Name = $Value (vorher: $before)" Change
        return 'WhatIf'
    }
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value (ConvertTo-B2SRegValue $Value $Type) -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    Add-B2SJournal @{ Kind = 'Registry'; Path = $Path; Name = $Name; Existed = $old.Exists; OldType = $old.Type; OldValue = $old.Value }
    $script:Stats.Changed++
    Write-B2SLog "  $Path\$Name = $Value (vorher: $before)" Change
    'Changed'
}

#endregion

#region Dienste, Aufgaben, Features, Apps ----------------------------------------------

function Disable-B2SService {
    param([Parameter(Mandatory)][string]$Name)
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    if (-not (Test-Path -LiteralPath $key)) {
        Write-B2SLog "  Dienst '$Name' nicht vorhanden - übersprungen" Info
        return
    }
    if (-not $script:WhatIfMode) {
        Get-Service -Name $Name, "$($Name)_*" -ErrorAction SilentlyContinue |
            Where-Object Status -ne 'Stopped' |
            Stop-Service -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
    # Starttyp über die Registry, damit der alte Wert im Journal landet (4 = Deaktiviert)
    [void](Set-B2SReg -Path $key -Name 'Start' -Value 4)
}

function Split-B2STaskPath {
    param([string]$Task)
    $idx = $Task.LastIndexOf('\')
    [pscustomobject]@{ Path = $Task.Substring(0, $idx + 1); Name = $Task.Substring($idx + 1) }
}

function Get-B2STask {
    param([string]$Task, [switch]$Cached)
    $t = Split-B2STaskPath $Task
    if ($Cached) {
        # Für Statusabfragen: alle Aufgaben einmal laden statt pro Eintrag abzufragen
        if ($null -eq $script:TaskCache) { $script:TaskCache = @(Get-ScheduledTask -ErrorAction SilentlyContinue) }
        return @($script:TaskCache | Where-Object { $_.TaskPath -like $t.Path -and $_.TaskName -like $t.Name })
    }
    @(Get-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue)
}

function Disable-B2STask {
    param([Parameter(Mandatory)][string]$Task)
    $tasks = Get-B2STask $Task
    if ($tasks.Count -eq 0) {
        Write-B2SLog "  Aufgabe '$Task' nicht vorhanden - übersprungen" Info
        return
    }
    foreach ($t in $tasks) {
        if ($t.State -eq 'Disabled') { $script:Stats.Unchanged++; continue }
        if ($script:WhatIfMode) {
            Write-B2SLog "  [Vorschau] Aufgabe deaktivieren: $($t.TaskPath)$($t.TaskName)" Change
            continue
        }
        Disable-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -ErrorAction Stop | Out-Null
        Add-B2SJournal @{ Kind = 'Task'; TaskPath = $t.TaskPath; TaskName = $t.TaskName }
        $script:Stats.Changed++
        Write-B2SLog "  Aufgabe deaktiviert: $($t.TaskPath)$($t.TaskName)" Change
    }
}

function Get-B2SInstalledAppx {
    if ($null -eq $script:AppxCache) {
        try { $script:AppxCache = @(Get-AppxPackage -AllUsers -ErrorAction Stop | Select-Object -ExpandProperty Name) }
        catch { $script:AppxCache = @(Get-AppxPackage | Select-Object -ExpandProperty Name) }
    }
    $script:AppxCache
}

function Reset-B2SCache {
    $script:AppxCache = $null
    $script:TaskCache = $null
}

function Remove-B2SAppx {
    param([Parameter(Mandatory)][string]$Name)
    # Ohne Adminrechte (nur in der Vorschau möglich) auf den aktuellen Benutzer ausweichen
    try { $packages = @(Get-AppxPackage -AllUsers -Name $Name -ErrorAction Stop) }
    catch { $packages = @(Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue) }
    try { $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object DisplayName -like $Name) }
    catch { $provisioned = @() }
    if ($packages.Count -eq 0 -and $provisioned.Count -eq 0) {
        Write-B2SLog "  App '$Name' nicht installiert" Info
        return
    }
    foreach ($p in $packages) {
        if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] App entfernen: $($p.Name)" Change; continue }
        try {
            Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
        }
        catch {
            # Fallback: nur für den aktuellen Benutzer entfernen
            Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop
        }
        Add-B2SJournal @{ Kind = 'Appx'; Name = $p.Name }
        $script:Stats.Changed++
        Write-B2SLog "  App entfernt: $($p.Name)" Change
    }
    foreach ($p in $provisioned) {
        if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] Bereitgestellte App entfernen: $($p.DisplayName)" Change; continue }
        Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null
        Write-B2SLog "  Bereitstellung entfernt (neue Benutzer): $($p.DisplayName)" Change
    }
    $script:AppxCache = $null
}

function Disable-B2SOptionalFeature {
    param([Parameter(Mandatory)][string]$Name)
    try { $feature = Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction Stop }
    catch {
        if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] Feature deaktivieren (falls vorhanden): $Name" Change; return }
        throw
    }
    if (-not $feature) {
        Write-B2SLog "  Optionales Feature '$Name' nicht vorhanden - übersprungen" Info
        return
    }
    if ("$($feature.State)" -like 'Disabled*') { $script:Stats.Unchanged++; return }
    if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] Feature deaktivieren: $Name" Change; return }
    Disable-WindowsOptionalFeature -Online -FeatureName $Name -NoRestart -ErrorAction Stop | Out-Null
    Add-B2SJournal @{ Kind = 'Feature'; Name = $Name }
    $script:Stats.Changed++
    Write-B2SLog "  Optionales Feature deaktiviert: $Name (Neustart nötig)" Change
}

#endregion

#region Firewall, hosts, Defender ----------------------------------------------------------

function Add-B2SFirewallBlock {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Program,
        [string]$Service
    )
    $displayName = "bye2spy - $Name"
    if (Get-NetFirewallRule -DisplayName $displayName -ErrorAction SilentlyContinue) {
        $script:Stats.Unchanged++
        return
    }
    if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] Firewall blockiert ausgehend: $Name" Change; return }
    $params = @{
        DisplayName = $displayName
        Group       = 'bye2spy'
        Direction   = 'Outbound'
        Action      = 'Block'
        Profile     = 'Any'
        Enabled     = 'True'
        ErrorAction = 'Stop'
    }
    if ($Program) { $params.Program = $Program }
    if ($Service) { $params.Service = $Service }
    New-NetFirewallRule @params | Out-Null
    Add-B2SJournal @{ Kind = 'Firewall'; DisplayName = $displayName }
    $script:Stats.Changed++
    Write-B2SLog "  Firewallregel angelegt: $displayName" Change
}

function Test-B2SFirewallBlock {
    param([string]$Name)
    [bool](Get-NetFirewallRule -DisplayName "bye2spy - $Name" -ErrorAction SilentlyContinue)
}

function Get-B2SHostsContentWithoutBlock {
    $lines = @(Get-Content -LiteralPath $script:HostsFile -ErrorAction SilentlyContinue)
    $out = New-Object System.Collections.ArrayList
    $inside = $false
    foreach ($l in $lines) {
        if ($l -eq $script:HostsBegin) { $inside = $true; continue }
        if ($l -eq $script:HostsEnd) { $inside = $false; continue }
        if (-not $inside) { [void]$out.Add($l) }
    }
    , $out.ToArray()
}

function Test-B2SHostsBlock {
    (Get-Content -LiteralPath $script:HostsFile -ErrorAction SilentlyContinue) -contains $script:HostsBegin
}

function Add-B2SHostsBlock {
    param([Parameter(Mandatory)][string[]]$Domains)
    if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] hosts-Datei: $($Domains.Count) Domains auf 0.0.0.0" Change; return }
    $existed = Test-B2SHostsBlock
    $content = New-Object System.Collections.ArrayList
    foreach ($l in (Get-B2SHostsContentWithoutBlock)) { [void]$content.Add($l) }
    [void]$content.Add($script:HostsBegin)
    foreach ($d in $Domains) { [void]$content.Add("0.0.0.0 $d") }
    [void]$content.Add($script:HostsEnd)
    Set-Content -LiteralPath $script:HostsFile -Value $content.ToArray() -Encoding ASCII -ErrorAction Stop
    try { Clear-DnsClientCache -ErrorAction SilentlyContinue } catch { }
    if (-not $existed) { Add-B2SJournal @{ Kind = 'Hosts' } }
    $script:Stats.Changed++
    Write-B2SLog "  hosts-Datei: $($Domains.Count) Telemetrie-Domains blockiert" Change
}

function Remove-B2SHostsBlock {
    if (-not (Test-B2SHostsBlock)) { return }
    Set-Content -LiteralPath $script:HostsFile -Value (Get-B2SHostsContentWithoutBlock) -Encoding ASCII -ErrorAction Stop
    try { Clear-DnsClientCache -ErrorAction SilentlyContinue } catch { }
    Write-B2SLog '  bye2spy-Block aus der hosts-Datei entfernt' Change
}

function Set-B2SMpPreference {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Value)
    $pref = Get-MpPreference -ErrorAction Stop
    $old = $pref.$Name
    if (Test-B2SValueEqual $old $Value) { $script:Stats.Unchanged++; return }
    if ($script:WhatIfMode) { Write-B2SLog "  [Vorschau] Defender: $Name = $Value (vorher: $old)" Change; return }
    $p = @{ $Name = $Value }
    Set-MpPreference @p -ErrorAction Stop
    $new = (Get-MpPreference).$Name
    if (-not (Test-B2SValueEqual $new $Value)) {
        Write-B2SLog "  Defender: $Name konnte nicht geändert werden (Manipulationsschutz aktiv?)" Warn
        return
    }
    Add-B2SJournal @{ Kind = 'MpPreference'; Name = $Name; OldValue = $old }
    $script:Stats.Changed++
    Write-B2SLog "  Defender: $Name = $Value (vorher: $old)" Change
}

#endregion

#region Module & Tweaks --------------------------------------------------------------------

function Import-B2SModules {
    param([Parameter(Mandatory)][string]$Directory)
    $modules = New-Object System.Collections.ArrayList
    foreach ($file in (Get-ChildItem -LiteralPath $Directory -Filter '*.ps1' | Sort-Object Name)) {
        try {
            $m = & $file.FullName
            if (-not ($m -is [hashtable]) -or -not $m.Id -or -not $m.Tweaks) {
                Write-Warning "Modul '$($file.Name)' hat kein gültiges Format und wird ignoriert."
                continue
            }
            $m.File = $file.Name
            foreach ($t in $m.Tweaks) {
                $t.ModuleId = $m.Id
                $t.ModuleName = $m.Name
                if (-not $t.Risk) { $t.Risk = 'Low' }
                if ($null -eq $t.Recommended) { $t.Recommended = ($t.Risk -eq 'Low') }
            }
            [void]$modules.Add($m)
        }
        catch {
            Write-Warning "Modul '$($file.Name)' konnte nicht geladen werden: $($_.Exception.Message)"
        }
    }
    , $modules.ToArray()
}

function Get-B2SRiskLabel {
    param([string]$Risk)
    switch ($Risk) {
        'Low'    { 'Gering' }
        'Medium' { 'Mittel' }
        'High'   { 'Hoch' }
        default  { $Risk }
    }
}

function Get-B2STweakDetails {
    param([Parameter(Mandatory)][hashtable]$Tweak)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine($Tweak.Name)
    [void]$sb.AppendLine(('Risiko: {0}    Empfohlen: {1}    ID: {2}' -f (Get-B2SRiskLabel $Tweak.Risk), $(if ($Tweak.Recommended) { 'ja' } else { 'nein' }), $Tweak.Id))
    [void]$sb.AppendLine('')
    if ($Tweak.Description) { [void]$sb.AppendLine($Tweak.Description); [void]$sb.AppendLine('') }
    if ($Tweak.Warning) { [void]$sb.AppendLine("ACHTUNG: $($Tweak.Warning)"); [void]$sb.AppendLine('') }

    $reg = @($Tweak.Registry | Where-Object { $_ })
    if ($reg.Count) {
        [void]$sb.AppendLine('Registry:')
        foreach ($r in $reg) { [void]$sb.AppendLine("  $($r.Path)\$($r.Name) = $($r.Value)") }
    }
    $sections = [ordered]@{
        'Dienste (deaktivieren)'          = $Tweak.Services
        'Geplante Aufgaben (deaktivieren)' = $Tweak.Tasks
        'Apps (entfernen)'                = $Tweak.Appx
        'Optionale Features (deaktivieren)' = $Tweak.OptionalFeatures
    }
    foreach ($s in $sections.GetEnumerator()) {
        $items = @($s.Value | Where-Object { $_ })
        if ($items.Count) {
            [void]$sb.AppendLine("$($s.Key):")
            foreach ($i in $items) { [void]$sb.AppendLine("  $i") }
        }
    }
    $fw = @($Tweak.Firewall | Where-Object { $_ })
    if ($fw.Count) {
        [void]$sb.AppendLine('Firewall (ausgehend blockieren):')
        foreach ($f in $fw) { [void]$sb.AppendLine("  $($f.Name)  $($f.Program)$($f.Service)") }
    }
    if ($Tweak.MpPreference) {
        [void]$sb.AppendLine('Microsoft Defender:')
        foreach ($k in $Tweak.MpPreference.Keys) { [void]$sb.AppendLine("  $k = $($Tweak.MpPreference[$k])") }
    }
    $hosts = @($Tweak.Hosts | Where-Object { $_ })
    if ($hosts.Count) {
        [void]$sb.AppendLine("hosts-Datei ($($hosts.Count) Domains auf 0.0.0.0):")
        foreach ($h in $hosts) { [void]$sb.AppendLine("  $h") }
    }
    if ($Tweak.ScriptInfo) { [void]$sb.AppendLine("Zusätzliche Aktion: $($Tweak.ScriptInfo)") }
    if ($Tweak.Source) { [void]$sb.AppendLine(''); [void]$sb.AppendLine("Quelle: $($Tweak.Source)") }
    $sb.ToString()
}

function Invoke-B2STweak {
    param([Parameter(Mandatory)][hashtable]$Tweak)

    Write-B2SLog "> [$($Tweak.ModuleName)] $($Tweak.Name)" Step

    foreach ($r in @($Tweak.Registry | Where-Object { $_ })) {
        $type = if ($r.Type) { $r.Type } else { 'DWord' }
        try { [void](Set-B2SReg -Path $r.Path -Name $r.Name -Value $r.Value -Type $type) }
        catch { Write-B2SLog "  Registry $($r.Path)\$($r.Name): $($_.Exception.Message)" Warn }
    }
    foreach ($s in @($Tweak.Services | Where-Object { $_ })) {
        try { Disable-B2SService -Name $s }
        catch { Write-B2SLog "  Dienst $($s): $($_.Exception.Message)" Warn }
    }
    foreach ($t in @($Tweak.Tasks | Where-Object { $_ })) {
        try { Disable-B2STask -Task $t }
        catch { Write-B2SLog "  Aufgabe $($t): $($_.Exception.Message)" Warn }
    }
    foreach ($a in @($Tweak.Appx | Where-Object { $_ })) {
        try { Remove-B2SAppx -Name $a }
        catch { Write-B2SLog "  App $($a): $($_.Exception.Message)" Warn }
    }
    foreach ($f in @($Tweak.OptionalFeatures | Where-Object { $_ })) {
        try { Disable-B2SOptionalFeature -Name $f }
        catch { Write-B2SLog "  Feature $($f): $($_.Exception.Message)" Warn }
    }
    foreach ($fw in @($Tweak.Firewall | Where-Object { $_ })) {
        try { Add-B2SFirewallBlock -Name $fw.Name -Program $fw.Program -Service $fw.Service }
        catch { Write-B2SLog "  Firewall $($fw.Name): $($_.Exception.Message)" Warn }
    }
    if ($Tweak.MpPreference) {
        foreach ($k in $Tweak.MpPreference.Keys) {
            try { Set-B2SMpPreference -Name $k -Value $Tweak.MpPreference[$k] }
            catch { Write-B2SLog "  Defender $($k): $($_.Exception.Message)" Warn }
        }
    }
    $hosts = @($Tweak.Hosts | Where-Object { $_ })
    if ($hosts.Count) {
        try { Add-B2SHostsBlock -Domains $hosts }
        catch { Write-B2SLog "  hosts-Datei: $($_.Exception.Message)" Warn }
    }
    if ($Tweak.Script) {
        if ($script:WhatIfMode) {
            Write-B2SLog "  [Vorschau] Zusätzliche Aktion: $($Tweak.ScriptInfo)" Change
        }
        else {
            try { & $Tweak.Script }
            catch { Write-B2SLog "  Zusätzliche Aktion: $($_.Exception.Message)" Warn }
        }
    }
}

function Get-B2STweakStatus {
    <# Liefert 'Aktiv', 'Teilweise', 'Offen' oder 'Unbekannt'. #>
    param([Parameter(Mandatory)][hashtable]$Tweak)
    $total = 0; $ok = 0

    foreach ($r in @($Tweak.Registry | Where-Object { $_ })) {
        $total++
        $v = Get-B2SRegValue -Path $r.Path -Name $r.Name
        if ($v.Exists -and (Test-B2SValueEqual $v.Value $r.Value)) { $ok++ }
    }
    foreach ($s in @($Tweak.Services | Where-Object { $_ })) {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$s"
        if (-not (Test-Path -LiteralPath $key)) { continue }
        $total++
        if ((Get-B2SRegValue -Path $key -Name 'Start').Value -eq 4) { $ok++ }
    }
    foreach ($t in @($Tweak.Tasks | Where-Object { $_ })) {
        foreach ($task in (Get-B2STask $t -Cached)) {
            $total++
            if ($task.State -eq 'Disabled') { $ok++ }
        }
    }
    $appx = @($Tweak.Appx | Where-Object { $_ })
    if ($appx.Count) {
        $installed = Get-B2SInstalledAppx
        foreach ($a in $appx) {
            $total++
            if (-not ($installed | Where-Object { $_ -like $a })) { $ok++ }
        }
    }
    foreach ($fw in @($Tweak.Firewall | Where-Object { $_ })) {
        $total++
        if (Test-B2SFirewallBlock $fw.Name) { $ok++ }
    }
    if (@($Tweak.Hosts | Where-Object { $_ }).Count) {
        $total++
        if (Test-B2SHostsBlock) { $ok++ }
    }
    if ($Tweak.Test) {
        $total++
        try { if (& $Tweak.Test) { $ok++ } } catch { }
    }

    if ($total -eq 0) { 'Unbekannt' }
    elseif ($ok -eq $total) { 'Aktiv' }
    elseif ($ok -eq 0) { 'Offen' }
    else { 'Teilweise' }
}

#endregion

#region System -------------------------------------------------------------------------

function Test-B2SAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-B2SSystemInfo {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $loggedOn = $null
    try { $loggedOn = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).UserName } catch { }
    [pscustomobject]@{
        Edition     = $cv.EditionID
        ProductName = $(if ([int]$cv.CurrentBuild -ge 22000) { $cv.ProductName -replace 'Windows 10', 'Windows 11' } else { $cv.ProductName })
        Version     = $cv.DisplayVersion
        Build       = "$($cv.CurrentBuild).$($cv.UBR)"
        RunAs       = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        LoggedOn    = $loggedOn
        IsAdmin     = (Test-B2SAdmin)
    }
}

function New-B2SRestorePoint {
    if ($script:WhatIfMode) { Write-B2SLog '[Vorschau] Wiederherstellungspunkt würde erstellt' Info; return }
    Write-B2SLog 'Erstelle Systemwiederherstellungspunkt ...' Step
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $old = Get-B2SRegValue -Path $key -Name 'SystemRestorePointCreationFrequency'
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        # Windows erlaubt standardmäßig nur einen Punkt pro 24 h - kurzzeitig aufheben
        New-ItemProperty -LiteralPath $key -Name 'SystemRestorePointCreationFrequency' -Value 0 -PropertyType DWord -Force | Out-Null
        Checkpoint-Computer -Description 'bye2spy - vor Änderungen' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-B2SLog 'Wiederherstellungspunkt erstellt.' OK
    }
    catch {
        Write-B2SLog "Wiederherstellungspunkt konnte nicht erstellt werden: $($_.Exception.Message)" Warn
    }
    finally {
        if ($old.Exists) {
            New-ItemProperty -LiteralPath $key -Name 'SystemRestorePointCreationFrequency' -Value $old.Value -PropertyType DWord -Force | Out-Null
        }
        else {
            Remove-ItemProperty -LiteralPath $key -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue
        }
    }
}

#endregion

Export-ModuleMember -Function *-B2S*
