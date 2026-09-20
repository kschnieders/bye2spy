<#
    bye2spy - Web-Starter

    Ein Befehl in PowerShell genuegt:
        irm https://raw.githubusercontent.com/kschnieders/bye2spy/main/install.ps1 | iex

    Mit Parametern (z. B. das Preset fuer Praxen und Kanzleien):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kschnieders/bye2spy/main/install.ps1))) -Preset Kritis

    Ablauf: fordert zuerst Administratorrechte an (UAC), laedt dann das Repository als ZIP
    von GitHub, legt es nach %ProgramData%\bye2spy (vorhandene Sicherungen und Protokolle
    bleiben erhalten) und startet bye2spy.ps1.

    Hinweis: Diese Datei enthaelt absichtlich nur ASCII-Zeichen und keine BOM-Signatur,
    damit sie per "irm | iex" in jeder PowerShell-Version fehlerfrei ausgefuehrt wird.
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Bye2SpyArgs
)

& {
    param([string[]]$PassArgs)

    $ErrorActionPreference = 'Stop'
    $Repo   = 'kschnieders/bye2spy'
    $Branch = 'main'
    $Target = Join-Path $env:ProgramData 'bye2spy'
    $ps     = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

    # Marker: dieser Aufruf laeuft im neu gestarteten, erhoehten Fenster
    $extra = @($PassArgs | Where-Object { $_ })
    $relaunched = $extra -contains '--relaunched'
    if ($relaunched) { $extra = @($extra | Where-Object { $_ -ne '--relaunched' }) }

    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # Erst Rechte holen, dann herunterladen - sonst scheitert das Schreiben nach ProgramData
        Write-Host ''
        Write-Host '  bye2spy braucht Administratorrechte - bitte die UAC-Abfrage bestaetigen ...' -ForegroundColor Yellow
        $url = "https://raw.githubusercontent.com/$Repo/$Branch/install.ps1"
        $quoted = @($extra + '--relaunched' | ForEach-Object { if ($_ -match '[\s"]') { '"' + $_ + '"' } else { $_ } }) -join ' '
        $inner = "& ([scriptblock]::Create((irm '$url'))) $quoted"
        try {
            Start-Process -FilePath $ps -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$inner`""
        }
        catch {
            Write-Host '  Abgebrochen - ohne Administratorrechte kann bye2spy nichts aendern.' -ForegroundColor Red
        }
        return
    }

    Write-Host ''
    Write-Host '  bye2spy - lade aktuelle Version von GitHub ...' -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $tmp = Join-Path $env:TEMP ('bye2spy_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $zip = Join-Path $tmp 'repo.zip'
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$Repo/archive/refs/heads/$Branch.zip" -OutFile $zip
        Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
        $src = Get-ChildItem -LiteralPath $tmp -Directory | Select-Object -First 1
        if (-not $src -or -not (Test-Path (Join-Path $src.FullName 'bye2spy.ps1'))) {
            throw 'bye2spy.ps1 wurde im heruntergeladenen Archiv nicht gefunden.'
        }

        # Programmdateien ersetzen, Sicherungen (backups) und Protokolle (logs) behalten
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
        foreach ($d in 'lib', 'modules', 'presets') {
            Remove-Item -LiteralPath (Join-Path $Target $d) -Recurse -Force -ErrorAction SilentlyContinue
        }
        foreach ($item in 'bye2spy.ps1', 'lib', 'modules', 'presets', 'README.md') {
            $p = Join-Path $src.FullName $item
            if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $Target -Recurse -Force }
        }
        Get-ChildItem -LiteralPath $Target -Recurse -File | Unblock-File
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "  Installiert nach $Target" -ForegroundColor DarkGray
    $main = Join-Path $Target 'bye2spy.ps1'
    $runArgs = $extra
    # Im eigenen Fenster am Ende auf eine Taste warten, damit die Ausgabe lesbar bleibt
    if ($relaunched -and $runArgs.Count) { $runArgs += '-Elevated' }
    & $ps -NoProfile -ExecutionPolicy Bypass -File $main @runArgs
} $Bye2SpyArgs
