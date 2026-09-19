<#
    Modul: Suche & Cortana
    Quellen:
      - https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services  (Abschnitt 2)
      - https://learn.microsoft.com/windows/client-management/mdm/policy-csp-search
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$ws = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
$ss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'

@{
    Id          = 'search'
    Name        = 'Suche & Cortana'
    Description = 'Websuche/Bing im Startmenü, Cloud-Suche, Suchhighlights und Cortana.'
    Tweaks      = @(
        @{
            Id          = 'search.web'
            Name        = 'Bing-/Websuche im Startmenü abschalten'
            Risk        = 'Low'
            Description = 'Eingaben in der Windows-Suche werden nicht mehr an Bing gesendet; keine Web-Ergebnisse, keine Suchvorschläge aus dem Netz und keine Copilot-Vorschläge im Suchfeld.'
            Registry    = @(
                Reg $ws 'DisableWebSearch' 1
                Reg $ws 'ConnectedSearchUseWeb' 0
                Reg $ws 'ConnectedSearchUseWebOverMeteredConnections' 0
                Reg $ws 'ConnectedSearchPrivacy' 3
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
                Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
            )
        }
        @{
            Id          = 'search.cloud'
            Name        = 'Cloud-Suche & Suchhighlights'
            Risk        = 'Low'
            Description = 'Keine Suche in OneDrive/Outlook/SharePoint-Inhalten über das Microsoft- oder Arbeitskonto, keine täglich wechselnden "Suchhighlights" (Inhalte von Bing).'
            Registry    = @(
                Reg $ws 'AllowCloudSearch' 0
                Reg $ws 'EnableDynamicContentInWSB' 0
                Reg $ss 'IsDynamicSearchBoxEnabled' 0
                Reg $ss 'IsMSACloudSearchEnabled' 0
                Reg $ss 'IsAADCloudSearchEnabled' 0
                Reg $ss 'IsDeviceSearchHistoryEnabled' 0
            )
        }
        @{
            Id          = 'search.cortana'
            Name        = 'Cortana & Standort in der Suche'
            Risk        = 'Low'
            Description = 'Sperrt Cortana (auch auf dem Sperrbildschirm) und verbietet der Suche die Nutzung des Standorts.'
            Registry    = @(
                Reg $ws 'AllowCortana' 0
                Reg $ws 'AllowCortanaAboveLock' 0
                Reg $ws 'AllowSearchToUseLocation' 0
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
            )
            Appx        = @('Microsoft.549981C3F5F10')
        }
    )
}
