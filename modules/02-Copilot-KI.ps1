<#
    Modul: Copilot & KI-Funktionen
    Quellen:
      - https://learn.microsoft.com/windows/client-management/mdm/policy-csp-windowsai  (Stand 08/2026)
      - https://learn.microsoft.com/windows/client-management/manage-notepad
      - https://4sysops.com/archives/uninstall-copilot-from-windows-11-with-removemicrosoftcopilotapp-group-policy-powershell-or-intune/
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$aiM = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
$aiU = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI'

@{
    Id          = 'ai'
    Name        = 'Copilot & KI-Funktionen'
    Description = 'Windows Copilot, Recall, Click to Do, KI-Agenten, KI in Paint und Editor sowie die Copilot-Apps.'
    Tweaks      = @(
        @{
            Id          = 'ai.copilot'
            Name        = 'Windows Copilot abschalten'
            Risk        = 'Low'
            Description = 'Setzt die Richtlinie "Windows Copilot deaktivieren" für Benutzer und Gerät und blendet die Copilot-Schaltfläche in der Taskleiste aus. Microsoft führt die Richtlinie als veraltet, sie wirkt aber weiterhin und verhindert die Neuinstallation bei Upgrades.'
            Source      = 'WindowsAI/TurnOffWindowsCopilot'
            Registry    = @(
                Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
            )
        }
        @{
            Id          = 'ai.copilot-app'
            Name        = 'Copilot-App entfernen'
            Risk        = 'Low'
            Description = 'Deinstalliert die Microsoft-Copilot-App (für alle Benutzer und für neue Benutzerprofile) und setzt zusätzlich die Richtlinie RemoveMicrosoftCopilotApp (ab 25H2, Enterprise/Education).'
            Source      = 'WindowsAI/RemoveMicrosoftCopilotApp'
            Registry    = @(
                Reg $aiM 'RemoveMicrosoftCopilotApp' 1
                Reg $aiU 'RemoveMicrosoftCopilotApp' 1
            )
            Appx        = @('Microsoft.Copilot', 'Microsoft.Windows.Ai.Copilot.Provider', 'MicrosoftWindows.Client.CoPilot')
        }
        @{
            Id          = 'ai.m365-app'
            Name        = 'App "Microsoft 365 Copilot" (Office Hub) entfernen'
            Risk        = 'Medium'
            Description = 'Entfernt die vorinstallierte App "Microsoft 365 Copilot" (früher "Office"). Installierte Office-Programme (Word, Excel, ...) bleiben erhalten.'
            Warning     = 'Wer die App als Startseite für Office nutzt, verliert diese Übersicht.'
            Appx        = @('Microsoft.MicrosoftOfficeHub')
        }
        @{
            Id               = 'ai.recall'
            Name             = 'Recall (Bildschirm-Snapshots) vollständig abschalten'
            Risk             = 'Low'
            Description      = 'Recall darf nicht aktiviert werden, es werden keine Snapshots gespeichert (vorhandene werden gelöscht), kein Export. Zusätzlich wird das optionale Feature "Recall" entfernt.'
            Source           = 'WindowsAI/AllowRecallEnablement, DisableAIDataAnalysis, AllowRecallExport'
            Registry         = @(
                Reg $aiM 'AllowRecallEnablement' 0
                Reg $aiM 'DisableAIDataAnalysis' 1
                Reg $aiU 'DisableAIDataAnalysis' 1
                Reg $aiM 'AllowRecallExport' 0
            )
            OptionalFeatures = @('Recall')
        }
        @{
            Id          = 'ai.clicktodo'
            Name        = 'Click to Do deaktivieren'
            Risk        = 'Low'
            Description = 'Click to Do erstellt bei Aufruf einen Screenshot und analysiert den Bildschirminhalt. Die Richtlinie entfernt die Funktion und alle Einstiegspunkte.'
            Source      = 'WindowsAI/DisableClickToDo'
            Registry    = @(
                Reg $aiM 'DisableClickToDo' 1
                Reg $aiU 'DisableClickToDo' 1
            )
        }
        @{
            Id          = 'ai.agents'
            Name        = 'KI-Agenten, Agent-Workspaces & MCP-Connectoren sperren'
            Risk        = 'Low'
            Description = 'Sperrt die neuen agentischen Funktionen: Agent-Workspaces, lokale und entfernte Agent-Connectoren (MCP) und den KI-Agenten in der Einstellungen-Suche. Einige dieser Richtlinien sind noch Insider/Enterprise-only; auf anderen Systemen werden die Werte ignoriert und greifen, sobald die Funktion ausgerollt wird.'
            Source      = 'WindowsAI/DisableAgentWorkspaces, DisableAgentConnectors, DisableRemoteAgentConnectors, DisableSettingsAgent'
            Registry    = @(
                Reg $aiM 'DisableAgentWorkspaces' 2
                Reg $aiM 'DisableAgentConnectors' 2
                Reg $aiM 'DisableRemoteAgentConnectors' 2
                Reg $aiM 'ConfigureAgentConnectors' 2
                Reg $aiM 'DisableSettingsAgent' 1
            )
        }
        @{
            Id          = 'ai.apps'
            Name        = 'KI in Editor (Notepad) und Paint abschalten'
            Risk        = 'Low'
            Description = 'Deaktiviert Copilot/"Umschreiben"/"Zusammenfassen" im Editor sowie Cocreator, generatives Füllen und Image Creator in Paint. Diese Funktionen senden Inhalte an Cloud-Modelle.'
            Source      = 'WindowsNotepad/DisableAIFeatures, WindowsAI/DisableCocreator, DisableGenerativeFill, DisableImageCreator'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\WindowsNotepad' 'DisableAIFeatures' 1
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableCocreator' 1
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableGenerativeFill' 1
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableImageCreator' 1
            )
        }
    )
}
