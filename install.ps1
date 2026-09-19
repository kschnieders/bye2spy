<#
    bye2spy - Web-Starter

    Ein Befehl in PowerShell genuegt:
        irm https://raw.githubusercontent.com/kschnieders/bye2spy/main/install.ps1 | iex

    Mit Parametern (z. B. unbeaufsichtigt nur die empfohlenen Einstellungen):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kschnieders/bye2spy/main/install.ps1))) -Preset Recommended -Yes

    Ablauf: laedt das Repository als ZIP von GitHub, legt es nach %ProgramData%\bye2spy
    (vorhandene Sicherungen und Protokolle bleiben erhalten) und startet bye2spy.ps1 mit
    Administratorrechten.

    Hinweis: Diese Datei enthaelt absichtlich nur ASCII-Zeichen, damit sie per
    "irm | iex" in jeder PowerShell-Version fehlerfrei ausgefuehrt wird.
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
    $extra  = @($PassArgs | Where-Object { $_ })

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
        foreach ($d in 'lib', 'modules') {
            Remove-Item -LiteralPath (Join-Path $Target $d) -Recurse -Force -ErrorAction SilentlyContinue
        }
        foreach ($item in 'bye2spy.ps1', 'lib', 'modules', 'README.md') {
            $p = Join-Path $src.FullName $item
            if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $Target -Recurse -Force }
        }
        Get-ChildItem -LiteralPath $Target -Recurse -File | Unblock-File
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    $main = Join-Path $Target 'bye2spy.ps1'
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    Write-Host "  Installiert nach $Target" -ForegroundColor DarkGray

    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        & $ps -NoProfile -ExecutionPolicy Bypass -File $main @extra
    }
    else {
        Write-Host '  Starte mit Administratorrechten - bitte die UAC-Abfrage bestaetigen ...' -ForegroundColor Yellow
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$main`"") + $extra + '-Elevated'
        Start-Process -FilePath $ps -Verb RunAs -ArgumentList $argList
    }
} $Bye2SpyArgs
