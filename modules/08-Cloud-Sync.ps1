<#
    Modul: Cloud, Konten & Synchronisierung
    Quelle: https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
            (Abschnitte 12, 15, 16, 18.12, 21)
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$sync = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync'
$sys  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$cdp  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP'

@{
    Id          = 'cloud'
    Name        = 'Cloud, Konten & Synchronisierung'
    Description = 'Einstellungssynchronisierung, OneDrive, geräteübergreifende Funktionen (Phone Link, "Auf anderen Geräten fortsetzen"), Karten, Microsoft-Konto-Dienst.'
    Tweaks      = @(
        @{
            Id          = 'cloud.settingsync'
            Name        = 'Einstellungs- und Nachrichtensynchronisierung'
            Risk        = 'Low'
            Description = 'Windows-Einstellungen (Designs, Passwörter, Sprache, ...) und Textnachrichten werden nicht mehr über das Microsoft-Konto synchronisiert.'
            Registry    = @(
                Reg $sync 'DisableSettingSync' 2
                Reg $sync 'DisableSettingSyncUserOverride' 1
                Reg $sync 'DisableApplicationSettingSync' 2
                Reg $sync 'DisableApplicationSettingSyncUserOverride' 1
                Reg $sync 'DisableCredentialsSettingSync' 2
                Reg $sync 'DisableCredentialsSettingSyncUserOverride' 1
                Reg $sync 'DisableWebBrowserSettingSync' 2
                Reg $sync 'DisableWebBrowserSettingSyncUserOverride' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Messaging' 'AllowMessageSync' 0
                Reg 'HKCU:\Software\Microsoft\Messaging' 'CloudServiceSyncEnabled' 0
            )
        }
        @{
            Id          = 'cloud.onedrive-preload'
            Name        = 'OneDrive: kein Netzwerkverkehr vor der Anmeldung'
            Risk        = 'Low'
            Description = 'OneDrive nimmt erst Verbindung auf, wenn sich ein Benutzer bei OneDrive anmeldet.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Microsoft\OneDrive' 'PreventNetworkTrafficPreUserSignIn' 1
            )
        }
        @{
            Id          = 'cloud.cdp'
            Name        = 'Geräteübergreifende Erfahrungen & Phone Link'
            Risk        = 'Medium'
            Description = 'Deaktiviert die Connected Devices Platform ("Auf anderen Geräten fortsetzen", "In der Nähe teilen") und die Verknüpfung von Smartphone und PC (Phone Link).'
            Warning     = '"Smartphone-Link", "In der Nähe teilen" und geräteübergreifendes Fortsetzen funktionieren nicht mehr.'
            Registry    = @(
                Reg $sys 'EnableCdp' 0
                Reg $sys 'EnableMmx' 0
                Reg $cdp 'RomeSdkChannelUserAuthzPolicy' 0
                Reg $cdp 'CdpSessionUserAuthzPolicy' 0
                Reg $cdp 'NearShareChannelUserAuthzPolicy' 0
            )
        }
        @{
            Id          = 'cloud.onesync'
            Name        = 'Synchronisierungshost (Mail, Kalender, Kontakte)'
            Risk        = 'Medium'
            Description = 'Deaktiviert den Synchronisierungshost-Dienst (OneSyncSvc), der Mail-, Kalender- und Kontaktdaten der integrierten Windows-Apps mit Microsoft-Clouddiensten abgleicht.'
            Warning     = 'Die alten Windows-Apps Mail/Kalender/Kontakte synchronisieren nicht mehr.'
            Services    = @('OneSyncSvc')
        }
        @{
            Id          = 'cloud.maps'
            Name        = 'Offline-Karten: automatische Downloads'
            Risk        = 'Low'
            Description = 'Kartendaten werden nicht automatisch heruntergeladen/aktualisiert; der Karten-Broker-Dienst und seine Aufgaben werden deaktiviert.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps' 'AutoDownloadAndUpdateMapData' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps' 'AllowUntriggeredNetworkTrafficOnSettingsPage' 0
            )
            Services    = @('MapsBroker')
            Tasks       = @('\Microsoft\Windows\Maps\MapsToastTask', '\Microsoft\Windows\Maps\MapsUpdateTask')
        }
        @{
            Id          = 'cloud.onedrive'
            Name        = 'OneDrive vollständig sperren'
            Risk        = 'High'
            Description = 'Verhindert die Nutzung von OneDrive zur Dateispeicherung (Richtlinie DisableFileSyncNGSC) und beendet den OneDrive-Client.'
            Warning     = 'Nur Online verfügbare Dateien (Wolkensymbol) sind danach nicht mehr erreichbar! Wenn Desktop/Dokumente/Bilder nach OneDrive umgeleitet sind, vorher alle Dateien lokal verfügbar machen oder die Ordnersicherung beenden.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableLibrariesDefaultSaveToOneDrive' 1
            )
            ScriptInfo  = 'OneDrive-Prozess beenden'
            Script      = { Get-Process -Name 'OneDrive' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
        }
        @{
            Id          = 'cloud.msaccount'
            Name        = 'Microsoft-Konto-Anmelde-Assistent deaktivieren'
            Risk        = 'High'
            Description = 'Deaktiviert den Dienst "Anmelde-Assistent für Microsoft-Konten" (wlidsvc). Apps können sich dann nicht mehr über das Microsoft-Konto anmelden.'
            Warning     = 'Microsoft Store, Xbox-Apps und alle Apps mit Microsoft-Konto-Anmeldung funktionieren nicht mehr. Wird automatisch übersprungen, wenn du dich mit einem Microsoft-Konto an Windows anmeldest.'
            ScriptInfo  = 'Dienst wlidsvc deaktivieren (nur bei lokalem Windows-Konto)'
            Script      = {
                $local = $null
                try { $local = Get-LocalUser -Name $env:USERNAME -ErrorAction Stop } catch { }
                if (-not $local -or "$($local.PrincipalSource)" -ne 'Local') {
                    Write-B2SLog '  Übersprungen: Windows-Anmeldung erfolgt nicht mit einem lokalen Konto (Microsoft-/Arbeitskonto erkannt).' Warn
                    return
                }
                Disable-B2SService -Name 'wlidsvc'
            }
            Test        = { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\wlidsvc' -ErrorAction SilentlyContinue).Start -eq 4 }
        }
    )
}
