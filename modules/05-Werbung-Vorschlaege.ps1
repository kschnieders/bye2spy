<#
    Modul: Werbung, Vorschläge & Cloud-Inhalte
    Quellen:
      - https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience
      - https://learn.microsoft.com/windows/configuration/start/policy-settings
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$ccM = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
$ccU = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

@{
    Id          = 'ads'
    Name        = 'Werbung, Vorschläge & Cloud-Inhalte'
    Description = 'Automatisch installierte Werbe-Apps, Tipps, Vorschläge im Startmenü/Einstellungen, Spotlight, Widgets/News.'
    Tweaks      = @(
        @{
            Id          = 'ads.cdm'
            Name        = 'Content Delivery Manager: Werbung & stille App-Installationen'
            Risk        = 'Low'
            Description = 'Stoppt das automatische Installieren "empfohlener" Apps, Vorschläge im Startmenü, in den Einstellungen und auf dem Sperrbildschirm sowie Tipps und das "Willkommen"-Erlebnis nach Updates.'
            Registry    = @(
                Reg $cdm 'ContentDeliveryAllowed' 0
                Reg $cdm 'FeatureManagementEnabled' 0
                Reg $cdm 'OemPreInstalledAppsEnabled' 0
                Reg $cdm 'PreInstalledAppsEnabled' 0
                Reg $cdm 'PreInstalledAppsEverEnabled' 0
                Reg $cdm 'SilentInstalledAppsEnabled' 0
                Reg $cdm 'SubscribedContentEnabled' 0
                Reg $cdm 'SystemPaneSuggestionsEnabled' 0
                Reg $cdm 'SoftLandingEnabled' 0
                Reg $cdm 'SubscribedContent-310093Enabled' 0
                Reg $cdm 'SubscribedContent-338387Enabled' 0
                Reg $cdm 'SubscribedContent-338388Enabled' 0
                Reg $cdm 'SubscribedContent-338389Enabled' 0
                Reg $cdm 'SubscribedContent-338393Enabled' 0
                Reg $cdm 'SubscribedContent-353694Enabled' 0
                Reg $cdm 'SubscribedContent-353696Enabled' 0
                Reg $cdm 'SubscribedContent-353698Enabled' 0
                Reg $cdm 'SubscribedContent-88000326Enabled' 0
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
            )
        }
        @{
            Id          = 'ads.cloudcontent'
            Name        = 'Microsoft-Consumer-Features & Cloud-Inhalte'
            Risk        = 'Low'
            Description = 'Richtlinien gegen "Microsoft Consumer Experiences" (automatische Store-App-Installationen), kontobezogene Hinweise, cloudoptimierte Inhalte, Tipps und Drittanbieter-Vorschläge.'
            Registry    = @(
                Reg $ccM 'DisableWindowsConsumerFeatures' 1
                Reg $ccM 'DisableConsumerAccountStateContent' 1
                Reg $ccM 'DisableCloudOptimizedContent' 1
                Reg $ccM 'DisableSoftLanding' 1
                Reg $ccU 'DisableThirdPartySuggestions' 1
                Reg $ccU 'DisableWindowsSpotlightWindowsWelcomeExperience' 1
                Reg $ccU 'DisableWindowsSpotlightOnSettings' 1
                Reg $ccU 'DisableWindowsSpotlightOnActionCenter' 1
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'AllowOnlineTips' 0
            )
        }
        @{
            Id          = 'ads.start'
            Name        = 'Startmenü, Explorer & Benachrichtigungen ohne Empfehlungen'
            Risk        = 'Low'
            Description = 'Keine Empfehlungen für Tipps/Apps/Websites im Startmenü, keine Kontohinweise ("Microsoft-Konto sichern"), keine OneDrive-/Office.com-Werbung und -Dateien im Explorer, keine "Tipps und Vorschläge"-Benachrichtigungen, keine Einrichtungs-Nags.'
            Registry    = @(
                Reg $adv 'Start_IrisRecommendations' 0
                Reg $adv 'Start_AccountNotifications' 0
                Reg $adv 'ShowSyncProviderNotifications' 0
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowCloudFilesInQuickAccess' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableGraphRecentItems' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'HideRecommendedPersonalizedSites' 1
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications' 'EnableAccountNotifications' 0
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested' 'Enabled' 0
            )
        }
        @{
            Id          = 'ads.widgets'
            Name        = 'Widgets / Neuigkeiten und Interessen'
            Risk        = 'Low'
            Description = 'Deaktiviert das Widgets-Board mit MSN-Nachrichten, das beim Öffnen und im Hintergrund Inhalte von Microsoft-Servern lädt, und blendet die Widgets-Schaltfläche aus.'
            Warning     = 'Auf manchen Windows-11-Installationen sind die beiden Richtlinien-Schlüssel schreibgeschützt; dann meldet bye2spy zwei Hinweise. Widgets lassen sich in dem Fall über Einstellungen > Personalisierung > Taskleiste abschalten oder über das Modul "Bloatware" ganz entfernen (bloat/apps.widgets).'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 0
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0
            )
        }
        @{
            Id          = 'ads.spotlight'
            Name        = 'Windows-Spotlight vollständig abschalten'
            Risk        = 'Medium'
            Description = 'Kein Spotlight auf Sperrbildschirm und Desktop (Bilder, "Weitere Infos zu diesem Bild", Werbeeinblendungen).'
            Warning     = 'Die wechselnden Spotlight-Hintergrundbilder entfallen; es wird ein statisches Bild verwendet.'
            Registry    = @(
                Reg $ccU 'DisableWindowsSpotlightFeatures' 1
                Reg $ccU 'DisableSpotlightCollectionOnDesktop' 1
                Reg $cdm 'RotatingLockScreenEnabled' 0
                Reg $cdm 'RotatingLockScreenOverlayEnabled' 0
            )
        }
    )
}
