<#
    Modul: Datenschutz & App-Berechtigungen
    Quellen:
      - https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services  (Abschnitt 18)
      - https://learn.microsoft.com/windows/client-management/mdm/policy-csp-privacy
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$ap  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
$sys = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'

@{
    Id          = 'privacy'
    Name        = 'Datenschutz & App-Berechtigungen'
    Description = 'Werbe-ID, Aktivitätsverlauf, Freihand/Eingabe, Spracherkennung, Standort und App-Zugriffe auf persönliche Daten.'
    Tweaks      = @(
        @{
            Id          = 'privacy.adid'
            Name        = 'Werbe-ID deaktivieren'
            Risk        = 'Low'
            Description = 'Apps können keine geräteübergreifende Werbe-ID mehr für personalisierte Werbung nutzen.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
            )
        }
        @{
            Id          = 'privacy.tracking'
            Name        = 'Sprachliste & App-Start-Tracking'
            Risk        = 'Low'
            Description = 'Websites erhalten keinen Zugriff auf die Sprachliste; Windows verfolgt keine App-Starts mehr für Start/Suche.'
            Registry    = @(
                Reg 'HKCU:\Control Panel\International\User Profile' 'HttpAcceptLanguageOptOut' 1
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0
            )
        }
        @{
            Id          = 'privacy.activity'
            Name        = 'Aktivitätsverlauf abschalten'
            Risk        = 'Low'
            Description = 'Kein Sammeln, Veröffentlichen oder Hochladen von Benutzeraktivitäten (Timeline/Activity Feed).'
            Registry    = @(
                Reg $sys 'EnableActivityFeed' 0
                Reg $sys 'PublishUserActivities' 0
                Reg $sys 'UploadUserActivities' 0
            )
        }
        @{
            Id          = 'privacy.inking'
            Name        = 'Freihand- und Eingabepersonalisierung'
            Risk        = 'Low'
            Description = 'Keine Sammlung von Tipp- und Handschriftmustern, keine Kontakt-Auswertung, keine Tipp-Einblicke, keine Übermittlung von Sprachdaten zur Verbesserung.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
                Reg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
                Reg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
                Reg 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0
                Reg 'HKCU:\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0
                Reg 'HKCU:\Software\Microsoft\Input\TIPC' 'Enabled' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TextInput' 'AllowLinguisticDataCollection' 0
            )
        }
        @{
            Id          = 'privacy.speech'
            Name        = 'Online-Spracherkennung'
            Risk        = 'Low'
            Description = 'Spracheingaben werden nicht an Microsoft-Clouddienste gesendet; keine automatischen Sprachmodell-Updates.'
            Registry    = @(
                Reg 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Speech' 'AllowSpeechModelUpdate' 0
            )
        }
        @{
            Id          = 'privacy.apppermissions'
            Name        = 'App-Zugriff auf persönliche Daten sperren'
            Risk        = 'Low'
            Description = 'Store-Apps dürfen nicht auf Kontoinfos, Kontakte, Kalender, Anrufliste, E-Mail, Nachrichten, Telefon, Funkmodule, Bewegungsdaten, Aufgaben, Benachrichtigungen, App-Diagnose, gekoppelte Geräte, Blickerfassung und räumliche Wahrnehmung zugreifen. (2 = Verweigern erzwingen; betrifft nur Store/UWP-Apps.)'
            Registry    = @(
                Reg $ap 'LetAppsAccessAccountInfo' 2
                Reg $ap 'LetAppsAccessContacts' 2
                Reg $ap 'LetAppsAccessCalendar' 2
                Reg $ap 'LetAppsAccessCallHistory' 2
                Reg $ap 'LetAppsAccessEmail' 2
                Reg $ap 'LetAppsAccessMessaging' 2
                Reg $ap 'LetAppsAccessPhone' 2
                Reg $ap 'LetAppsAccessRadios' 2
                Reg $ap 'LetAppsAccessMotion' 2
                Reg $ap 'LetAppsAccessTasks' 2
                Reg $ap 'LetAppsAccessNotifications' 2
                Reg $ap 'LetAppsGetDiagnosticInfo' 2
                Reg $ap 'LetAppsSyncWithDevices' 2
                Reg $ap 'LetAppsAccessTrustedDevices' 2
                Reg $ap 'LetAppsAccessGazeInput' 2
                Reg $ap 'LetAppsAccessBackgroundSpatialPerception' 2
            )
        }
        @{
            Id          = 'privacy.voice'
            Name        = 'Sprachaktivierung von Apps'
            Risk        = 'Low'
            Description = 'Apps dürfen nicht dauerhaft auf ein Sprach-Schlüsselwort lauschen (auch nicht auf dem Sperrbildschirm).'
            Registry    = @(
                Reg $ap 'LetAppsActivateWithVoice' 2
                Reg $ap 'LetAppsActivateWithVoiceAboveLock' 2
            )
        }
        @{
            Id          = 'privacy.clipboard'
            Name        = 'Cloud-Zwischenablage & vorgeschlagene Aktionen'
            Risk        = 'Low'
            Description = 'Die Zwischenablage wird nicht mehr geräteübergreifend über die Microsoft-Cloud synchronisiert. Der lokale Zwischenablageverlauf (Win+V) bleibt nutzbar. "Vorgeschlagene Aktionen" beim Kopieren von Telefonnummern/Terminen werden abgeschaltet.'
            Registry    = @(
                Reg $sys 'AllowCrossDeviceClipboard' 0
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard' 'Disabled' 1
            )
        }
        @{
            Id          = 'privacy.location'
            Name        = 'Standortdienste abschalten'
            Risk        = 'Medium'
            Description = 'Schaltet die Windows-Standortermittlung (inkl. WLAN-basierter Ortung über Microsoft) systemweit ab und deaktiviert den Geolocation-Dienst.'
            Warning     = 'Automatische Zeitzone, Wetter, Karten und "Mein Gerät suchen" funktionieren danach nicht mehr.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableWindowsLocationProvider' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting' 1
                Reg $ap 'LetAppsAccessLocation' 2
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' 'String'
            )
            Services    = @('lfsvc')
        }
        @{
            Id          = 'privacy.findmydevice'
            Name        = '"Mein Gerät suchen" deaktivieren'
            Risk        = 'Medium'
            Description = 'Das Gerät meldet seinen Standort nicht mehr regelmäßig an das Microsoft-Konto.'
            Warning     = 'Bei Verlust/Diebstahl kann das Gerät nicht mehr über account.microsoft.com geortet werden.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' 'AllowFindMyDevice' 0
            )
        }
        @{
            Id          = 'privacy.background'
            Name        = 'Hintergrund-Apps verbieten'
            Risk        = 'Medium'
            Description = 'Store-Apps dürfen nicht im Hintergrund laufen (und damit auch nicht unbemerkt Daten übertragen).'
            Warning     = 'Store-Apps wie Teams (neu), WhatsApp oder Mail zeigen im Hintergrund keine Benachrichtigungen mehr an.'
            Registry    = @(
                Reg $ap 'LetAppsRunInBackground' 2
            )
        }
        @{
            Id          = 'privacy.camera-mic'
            Name        = 'Kamera & Mikrofon für Store-Apps sperren'
            Risk        = 'High'
            Description = 'Store/UWP-Apps erhalten keinen Zugriff auf Kamera und Mikrofon. Klassische Desktop-Programme (Browser, Zoom, Discord ...) sind nicht betroffen.'
            Warning     = 'Kamera-App, das neue Teams, Sprachaufzeichnung, Windows Hello-Einrichtung per Kamera-App u. a. funktionieren nicht mehr.'
            Registry    = @(
                Reg $ap 'LetAppsAccessCamera' 2
                Reg $ap 'LetAppsAccessMicrophone' 2
            )
        }
    )
}
