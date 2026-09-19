<#
    Modul: Defender-Cloud & SmartScreen
    Quellen:
      - https://learn.microsoft.com/defender-endpoint/configure-block-at-first-sight-microsoft-defender-antivirus
      - https://learn.microsoft.com/windows/security/operating-system-security/virus-and-threat-protection/microsoft-defender-smartscreen/
    ACHTUNG: Alles in diesem Modul senkt den Schutz vor Schadsoftware und Phishing.
    Microsoft Defender selbst (lokaler Virenschutz, Signatur-Updates) bleibt aktiv.
    Bei aktivem Manipulationsschutz ("Tamper Protection") ignoriert Defender die
    Cloud-Einstellungen - dann in "Windows-Sicherheit" vorher selbst abschalten.
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}

@{
    Id          = 'defender'
    Name        = 'Defender-Cloud & SmartScreen'
    Description = 'Cloudbasierter Schutz, automatische Beispielübermittlung, SmartScreen und erweiterter Phishingschutz. Sicherheitsrelevant - bewusst nicht in "Empfohlen" enthalten.'
    Tweaks      = @(
        @{
            Id           = 'defender.cloud'
            Name         = 'Defender: Cloudschutz (MAPS) & Beispielübermittlung'
            Risk         = 'High'
            Description  = 'Defender sendet keine Metadaten verdächtiger Dateien und keine Dateiproben mehr an Microsoft (MAPS aus, "Nie senden", kein Block at First Sight).'
            Warning      = 'Neue, noch unbekannte Schadsoftware wird deutlich schlechter erkannt. Bei aktivem Manipulationsschutz wirkungslos.'
            Registry     = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' 'SpynetReporting' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' 'SubmitSamplesConsent' 2
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' 'DisableBlockAtFirstSeen' 1
            )
            MpPreference = @{ MAPSReporting = 0; SubmitSamplesConsent = 2 }
        }
        @{
            Id          = 'defender.smartscreen'
            Name        = 'SmartScreen (Explorer, Store-Apps, Edge)'
            Risk        = 'High'
            Description = 'SmartScreen prüft heruntergeladene Programme und aufgerufene URLs online bei Microsoft. Diese Prüfung wird für Explorer, Store-Apps und Edge abgeschaltet.'
            Warning     = 'Kein Warnhinweis mehr bei bekannten Schadprogrammen und Phishing-Seiten.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled' 'Off' 'String'
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost' 'EnableWebContentEvaluation' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SmartScreenEnabled' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SmartScreenPuaEnabled' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter' 'EnabledV9' 0
            )
        }
        @{
            Id          = 'defender.phishing'
            Name        = 'Erweiterter Phishingschutz (Passworteingabe-Überwachung)'
            Risk        = 'Medium'
            Description = 'Der erweiterte Phishingschutz überwacht, wo das Windows-Passwort eingegeben wird, und meldet Phishing-Seiten an Microsoft. Wird hier deaktiviert.'
            Warning     = 'Keine Warnung mehr, wenn das Windows-Passwort auf einer Phishing-Seite oder in einer unsicheren App eingegeben wird.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' 'ServiceEnabled' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' 'NotifyMalicious' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' 'NotifyPasswordReuse' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' 'NotifyUnsafeApp' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' 'CaptureThreatWindow' 0
            )
        }
    )
}
