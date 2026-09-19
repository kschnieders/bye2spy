<#
    Modul: Vorinstallierte Apps entfernen
    Apps werden für alle Benutzer und aus dem Bereitstellungsabbild (neue Benutzer) entfernt.
    Eine Wiederherstellung ist nur über den Microsoft Store möglich.
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}

@{
    Id          = 'apps'
    Name        = 'Vorinstallierte Apps entfernen'
    Description = 'Apps, die Nutzungsdaten, Inhalte oder Zugangsdaten an Microsoft-Clouddienste senden oder Werbung einblenden. Nicht über das Journal rückgängig zu machen - Neuinstallation über den Microsoft Store.'
    Tweaks      = @(
        @{
            Id          = 'apps.bing'
            Name        = 'Bing-Apps (News, Wetter, Suche, Finanzen, Sport)'
            Risk        = 'Low'
            Description = 'Diese Apps laden personalisierte MSN-/Bing-Inhalte und übertragen Nutzungsdaten.'
            Appx        = @('Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.BingSearch', 'Microsoft.BingFinance', 'Microsoft.BingSports', 'Microsoft.BingTravel')
        }
        @{
            Id          = 'apps.feedback'
            Name        = 'Feedback-Hub, Hilfe, Tipps, Solitaire'
            Risk        = 'Low'
            Description = 'Feedback-Hub (sendet Diagnosedaten mit), "Hilfe anfordern", "Tipps"/"Erste Schritte" und die werbefinanzierte Solitaire Collection.'
            Appx        = @('Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftSolitaireCollection')
        }
        @{
            Id          = 'apps.cloudapps'
            Name        = 'Weitere Cloud-Apps (Clipchamp, To Do, Power Automate, Dev Home, Family, Karten)'
            Risk        = 'Medium'
            Description = 'Apps, die überwiegend mit Microsoft-Clouddiensten arbeiten.'
            Warning     = 'Nur auswählen, wenn du diese Apps nicht benutzt.'
            Appx        = @('Clipchamp.Clipchamp', 'Microsoft.Todos', 'Microsoft.PowerAutomateDesktop', 'Microsoft.Windows.DevHome', 'MicrosoftCorporationII.MicrosoftFamily', 'Microsoft.WindowsMaps', 'Microsoft.People')
        }
        @{
            Id          = 'apps.outlook'
            Name        = 'Neues Outlook & alte Mail/Kalender-App'
            Risk        = 'Medium'
            Description = 'Das neue Outlook für Windows synchronisiert auch IMAP/POP-Konten über Microsoft-Server - inklusive der Zugangsdaten. Entfernt das neue Outlook und die alte Mail-/Kalender-App (klassisches Outlook aus Office ist nicht betroffen).'
            Warning     = 'Wer das neue Outlook als E-Mail-Programm nutzt, verliert es.'
            Appx        = @('Microsoft.OutlookForWindows', 'microsoft.windowscommunicationsapps')
        }
        @{
            Id          = 'apps.phonelink'
            Name        = 'Smartphone-Link (Phone Link) & Cross Device'
            Risk        = 'Medium'
            Description = 'Entfernt Phone Link und die Cross-Device-Komponente, die Smartphone-Daten (SMS, Fotos, Anrufe) über Microsoft-Dienste mit dem PC koppeln.'
            Appx        = @('Microsoft.YourPhone', 'MicrosoftWindows.CrossDevice')
        }
        @{
            Id          = 'apps.teams'
            Name        = 'Microsoft Teams (vorinstalliert) & Chat-Symbol'
            Risk        = 'Medium'
            Description = 'Entfernt die vorinstallierte Teams-App und blendet das Chat-Symbol in der Taskleiste per Richtlinie aus.'
            Warning     = 'Wer Teams benutzt, muss es danach neu installieren.'
            Appx        = @('MSTeams', 'MicrosoftTeams')
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 3
            )
        }
        @{
            Id          = 'apps.widgets'
            Name        = 'Widgets-Plattform (Windows Web Experience Pack)'
            Risk        = 'Medium'
            Description = 'Entfernt das Paket hinter Widgets/MSN-Feed komplett (zusätzlich zur Richtlinie im Modul "Werbung").'
            Warning     = 'Auch Widgets von Drittanbietern stehen danach nicht mehr zur Verfügung.'
            Appx        = @('MicrosoftWindows.Client.WebExperience')
        }
        @{
            Id          = 'apps.gamebar'
            Name        = 'Xbox Game Bar inkl. Gaming Copilot'
            Risk        = 'Medium'
            Description = 'Die Game Bar enthält "Gaming Copilot", der Screenshots des Spiels zur Analyse an Microsoft senden kann. Entfernt Game Bar und Edge Game Assist und schaltet Spielaufzeichnung ab, damit keine "ms-gamingoverlay"-Fehlermeldungen erscheinen.'
            Warning     = 'Keine Game-Bar-Aufnahmen, kein Leistungs-Overlay; manche Xbox-Controller-Funktionen (Guide-Taste) öffnen nichts mehr.'
            Appx        = @('Microsoft.XboxGamingOverlay', 'Microsoft.Edge.GameAssist')
            Registry    = @(
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
                Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
            )
        }
    )
}
