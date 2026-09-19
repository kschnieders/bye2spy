<#
    Modul: Netzwerk & Systemdienste
    Quelle: https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
            (Abschnitte 4, 6, 10, 14, 20, 22, 23, 28)
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}

# Reine Telemetrie-/Fehlerbericht-Endpunkte. Bewusst KEINE Domains für Windows Update,
# Store, Aktivierung, Defender-Signaturen oder Zertifikatsprüfung (CRL/OCSP).
$telemetryHosts = @(
    'vortex.data.microsoft.com'
    'vortex-win.data.microsoft.com'
    'v10.vortex-win.data.microsoft.com'
    'v10.events.data.microsoft.com'
    'v10c.events.data.microsoft.com'
    'v20.events.data.microsoft.com'
    'eu-v10.events.data.microsoft.com'
    'eu-v10c.events.data.microsoft.com'
    'eu-v20.events.data.microsoft.com'
    'us-v10.events.data.microsoft.com'
    'us-v10c.events.data.microsoft.com'
    'us-v20.events.data.microsoft.com'
    'self.events.data.microsoft.com'
    'mobile.events.data.microsoft.com'
    'umwatson.events.data.microsoft.com'
    'eu-mobile.events.data.microsoft.com'
    'eu-watson.events.data.microsoft.com'
    'telecommand.telemetry.microsoft.com'
    'telemetry.microsoft.com'
    'oca.telemetry.microsoft.com'
    'sqm.telemetry.microsoft.com'
    'watson.telemetry.microsoft.com'
    'watson.microsoft.com'
    'watson.ppe.telemetry.microsoft.com'
    'df.telemetry.microsoft.com'
    'wes.df.telemetry.microsoft.com'
    'reports.wes.df.telemetry.microsoft.com'
    'services.wes.df.telemetry.microsoft.com'
    'sqm.df.telemetry.microsoft.com'
    'survey.watson.microsoft.com'
    'redir.metaservices.microsoft.com'
    'choice.microsoft.com'
    'telemetry.appex.bing.net'
    'telemetry.urs.microsoft.com'
    'vortex-sandbox.data.microsoft.com'
    'settings-sandbox.data.microsoft.com'
    'browser.events.data.msn.com'
    'browser.pipe.aria.microsoft.com'
    'nexus.officeapps.live.com'
    'nexusrules.officeapps.live.com'
)

@{
    Id          = 'network'
    Name        = 'Netzwerk & Systemdienste'
    Description = 'Übermittlungsoptimierung, Verbindungstest, Teredo, Schriftarten-/Geräte-Metadaten, WLAN-Hotspot-Berichte, Firewall- und hosts-Sperren für Telemetrie.'
    Tweaks      = @(
        @{
            Id          = 'network.deliveryopt'
            Name        = 'Übermittlungsoptimierung ohne Peer-to-Peer'
            Risk        = 'Low'
            Description = 'Windows- und Store-Updates werden nicht mehr mit anderen PCs im Internet geteilt (Download-Modus 99 = einfach, ohne Peering und ohne Cloud-Dienst der Übermittlungsoptimierung). Updates funktionieren weiterhin normal.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 99
            )
        }
        @{
            Id          = 'network.rollout'
            Name        = '"Neueste Updates sofort erhalten" & Update-Funktionsrollouts'
            Risk        = 'Low'
            Description = 'Schaltet die Option ab, neue Funktionen (u. a. KI-Funktionen) per "Controlled Feature Rollout" vorzeitig zu erhalten. Sicherheitsupdates sind nicht betroffen.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'IsContinuousInnovationOptedIn' 0
            )
        }
        @{
            Id          = 'network.metadata'
            Name        = 'Schriftarten-, Geräte- und Datenträger-Metadaten aus dem Netz'
            Risk        = 'Low'
            Description = 'Keine Schriftarten-Streams, keine Gerätemetadaten (Symbole/Infos) aus dem Internet, keine Modell-Updates für die Datenträgerzustandsanalyse, keine Windows-Media-Player-Metadatenabrufe.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableFontProviders' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata' 'PreventDeviceMetadataFromNetwork' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageHealth' 'AllowDiskHealthModelUpdates' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer' 'PreventCDDVDMetadataRetrieval' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer' 'PreventMusicFileMetadataRetrieval' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer' 'PreventRadioPresetsRetrieval' 1
                Reg 'HKCU:\Software\Microsoft\MediaPlayer\Preferences' 'UsageTracking' 0
            )
        }
        @{
            Id          = 'network.wifi'
            Name        = 'WLAN-Sense & Hotspot-Berichte'
            Risk        = 'Low'
            Description = 'Keine automatische Verbindung zu vorgeschlagenen offenen Hotspots und keine Meldung von Hotspot-Informationen an Microsoft.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'value' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'value' 0
            )
        }
        @{
            Id          = 'network.teredo'
            Name        = 'Teredo-Tunnel deaktivieren'
            Risk        = 'Low'
            Description = 'Teredo (IPv6-über-IPv4-Tunnel über Microsoft-Server) wird abgeschaltet.'
            Warning     = 'Ältere Xbox-Live-Multiplayer-Funktionen können eine "strikte NAT" melden.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition' 'Teredo_State' 'Disabled' 'String'
            )
            ScriptInfo  = 'netsh interface teredo set state disabled'
            Script      = { & netsh.exe interface teredo set state disabled | Out-Null }
        }
        @{
            Id          = 'network.retaildemo'
            Name        = 'Einzelhandelsdemo-Dienst'
            Risk        = 'Low'
            Description = 'Deaktiviert den Dienst für den Einzelhandels-Demomodus.'
            Services    = @('RetailDemo')
        }
        @{
            Id          = 'network.firewall'
            Name        = 'Firewall: Telemetrie-Programme ausgehend blockieren'
            Risk        = 'Low'
            Description = 'Legt ausgehende Sperrregeln (Gruppe "bye2spy") für die Telemetrie-Programme und den DiagTrack-Dienst an. So wird selbst dann nichts gesendet, wenn ein Update die Dienste wieder aktiviert.'
            Firewall    = @(
                @{ Name = 'DiagTrack-Dienst'; Program = '%SystemRoot%\System32\svchost.exe'; Service = 'DiagTrack' }
                @{ Name = 'CompatTelRunner'; Program = '%SystemRoot%\System32\CompatTelRunner.exe' }
                @{ Name = 'DeviceCensus'; Program = '%SystemRoot%\System32\DeviceCensus.exe' }
                @{ Name = 'wsqmcons (CEIP)'; Program = '%SystemRoot%\System32\wsqmcons.exe' }
                @{ Name = 'Fehlerberichterstattung (wermgr)'; Program = '%SystemRoot%\System32\wermgr.exe' }
                @{ Name = 'Fehlerberichterstattung (WerFault)'; Program = '%SystemRoot%\System32\WerFault.exe' }
            )
        }
        @{
            Id          = 'network.push'
            Name        = 'Cloud-Push-Benachrichtigungen (WNS)'
            Risk        = 'Medium'
            Description = 'Apps können keine Benachrichtigungen und Live-Kacheln mehr über den Windows-Push-Notification-Dienst von Microsoft erhalten.'
            Warning     = 'Store-Apps (Teams neu, WhatsApp, Mail, Kalender ...) zeigen keine Push-Benachrichtigungen mehr an.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoCloudApplicationNotification' 1
            )
        }
        @{
            Id          = 'network.ncsi'
            Name        = 'Aktiven Internet-Verbindungstest (NCSI) abschalten'
            Risk        = 'Medium'
            Description = 'Windows ruft nicht mehr bei jeder Netzwerkverbindung www.msftconnecttest.com auf.'
            Warning     = 'Das Netzwerksymbol kann "Kein Internet" anzeigen; manche Apps (Store, Outlook) halten sich dann für offline, und Hotel-/WLAN-Anmeldeseiten öffnen sich nicht mehr automatisch.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator' 'NoActiveProbe' 1
            )
        }
        @{
            Id          = 'network.hosts'
            Name        = 'hosts-Datei: Telemetrie-Domains sperren'
            Risk        = 'High'
            Description = 'Leitet bekannte reine Telemetrie- und Fehlerbericht-Domains auf 0.0.0.0 um. Der Block wird mit Markierungen eingefügt und bei der Wiederherstellung sauber entfernt.'
            Warning     = 'Microsoft Defender stuft Einträge für Microsoft-Domains in der hosts-Datei teils als "SettingsModifier:Win32/HostsFileHijack" ein und setzt sie zurück - dann in Defender "Zulassen" wählen. Einige Windows-Komponenten umgehen die hosts-Datei. Die Firewall-Regeln sind der zuverlässigere Weg.'
            Hosts       = $telemetryHosts
        }
    )
}
