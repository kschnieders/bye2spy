<#
    Modul: Microsoft Edge
    Quelle: https://learn.microsoft.com/deployedge/microsoft-edge-policies
    Hinweis: Edge zeigt unter edge://policy alle aktiven Richtlinien an. Unbekannte oder
    veraltete Richtlinien werden von Edge ignoriert und richten keinen Schaden an.
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$e = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'

@{
    Id          = 'edge'
    Name        = 'Microsoft Edge'
    Description = 'Diagnosedaten, Copilot/Seitenleiste, Werbung und Cloud-Dienste in Edge (per Richtlinie, gilt für alle Profile).'
    Tweaks      = @(
        @{
            Id          = 'edge.telemetry'
            Name        = 'Edge-Diagnosedaten & Personalisierung'
            Risk        = 'Low'
            Description = 'Keine optionalen Diagnosedaten, keine Personalisierung über den Browserverlauf, kein Feedback, keine Experimente (ECS im eingeschränkten Modus), Do-Not-Track an, keine Fehlerseiten-/Navigationshilfe über Webdienste, kein Vorladen von Seiten.'
            Registry    = @(
                Reg $e 'DiagnosticData' 0
                Reg $e 'MetricsReportingEnabled' 0
                Reg $e 'SendSiteInfoToImproveServices' 0
                Reg $e 'PersonalizationReportingEnabled' 0
                Reg $e 'UserFeedbackAllowed' 0
                Reg $e 'ExperimentationAndConfigurationServiceControl' 0
                Reg $e 'ConfigureDoNotTrack' 1
                Reg $e 'ResolveNavigationErrorsUseWebService' 0
                Reg $e 'AlternateErrorPagesEnabled' 0
                Reg $e 'NetworkPredictionOptions' 2
                Reg $e 'InAppSupportEnabled' 0
                Reg $e 'LocalProvidersEnabled' 0
                Reg $e 'AddressBarMicrosoftSearchInBingProviderEnabled' 0
                Reg $e 'RelatedMatchesCloudServiceEnabled' 0
            )
        }
        @{
            Id          = 'edge.copilot'
            Name        = 'Copilot, Seitenleiste & KI-Funktionen in Edge'
            Risk        = 'Low'
            Description = 'Blendet die Edge-Seitenleiste (inkl. Copilot) aus, verbietet Copilot den Zugriff auf Seiteninhalte, deaktiviert "Mit Copilot schreiben", Copilot auf der Neuer-Tab-Seite, KI-Verlaufssuche, KI-Designs, visuelle Suche und das lokale KI-Grundmodell.'
            Source      = 'HubsSidebarEnabled, CopilotPageContext, EdgeEntraCopilotPageContext, CopilotCDPPageContext, ComposeInlineEnabled, GenAILocalFoundationalModelSettings'
            Registry    = @(
                Reg $e 'HubsSidebarEnabled' 0
                Reg $e 'CopilotPageContext' 0
                Reg $e 'EdgeEntraCopilotPageContext' 0
                Reg $e 'CopilotCDPPageContext' 0
                Reg $e 'Microsoft365CopilotChatIconEnabled' 0
                Reg $e 'ComposeInlineEnabled' 0
                Reg $e 'DiscoverPageContextEnabled' 0
                Reg $e 'NewTabPageBingChatEnabled' 0
                Reg $e 'EdgeHistoryAISearchEnabled' 0
                Reg $e 'AIGenThemesEnabled' 0
                Reg $e 'GenAILocalFoundationalModelSettings' 1
                Reg $e 'SearchInSidebarEnabled' 2
                Reg $e 'VisualSearchEnabled' 0
                Reg $e 'QuickSearchShowMiniMenu' 0
            )
        }
        @{
            Id          = 'edge.promos'
            Name        = 'Werbung, Shopping & Empfehlungen in Edge'
            Risk        = 'Low'
            Description = 'Kein Shopping-Assistent, keine Rewards, keine Empfehlungen/Spotlight, keine Werbe-Tabs, keine Standardbrowser-Kampagnen, kein Wallet/Krypto, keine Follow-Funktion, kein MSN-Feed auf der Neuer-Tab-Seite, kein Hintergrundbetrieb/Startup-Boost.'
            Registry    = @(
                Reg $e 'EdgeShoppingAssistantEnabled' 0
                Reg $e 'ShowMicrosoftRewards' 0
                Reg $e 'SpotlightExperiencesAndRecommendationsEnabled' 0
                Reg $e 'ShowRecommendationsEnabled' 0
                Reg $e 'PromotionalTabsEnabled' 0
                Reg $e 'DefaultBrowserSettingsCampaignEnabled' 0
                Reg $e 'HideFirstRunExperience' 1
                Reg $e 'EdgeFollowEnabled' 0
                Reg $e 'CryptoWalletEnabled' 0
                Reg $e 'EdgeWalletCheckoutEnabled' 0
                Reg $e 'NewTabPageContentEnabled' 0
                Reg $e 'NewTabPageHideDefaultTopSites' 1
                Reg $e 'WebWidgetAllowed' 0
                Reg $e 'EdgeEDropEnabled' 0
                Reg $e 'ShowPDFDefaultRecommendationsEnabled' 0
                Reg $e 'StartupBoostEnabled' 0
                Reg $e 'BackgroundModeEnabled' 0
            )
        }
        @{
            Id          = 'edge.cloud'
            Name        = 'Cloud-Dienste & Synchronisierung in Edge'
            Risk        = 'Medium'
            Description = 'Keine Suchvorschläge während der Eingabe, keine Microsoft-Editor-Rechtschreibung/Textvorhersage (Cloud), keine Übersetzung über Microsoft-Server, keine Synchronisierung/Anmeldung, kein Autofill für Adressen/Karten, strikte Tracking-Verhinderung.'
            Warning     = 'Favoriten, Passwörter usw. werden nicht mehr zwischen Geräten synchronisiert, Anmeldung im Browser wird deaktiviert, einzelne Websites können durch strikte Tracking-Verhinderung Fehler zeigen.'
            Registry    = @(
                Reg $e 'SearchSuggestEnabled' 0
                Reg $e 'MicrosoftEditorProofingEnabled' 0
                Reg $e 'MicrosoftEditorSynonymsEnabled' 0
                Reg $e 'TextPredictionEnabled' 0
                Reg $e 'TranslateEnabled' 0
                Reg $e 'SyncDisabled' 1
                Reg $e 'BrowserSignin' 0
                Reg $e 'ImplicitSignInEnabled' 0
                Reg $e 'AutofillAddressEnabled' 0
                Reg $e 'AutofillCreditCardEnabled' 0
                Reg $e 'TrackingPrevention' 3
            )
        }
    )
}
