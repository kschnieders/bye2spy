<#
    Modul: Microsoft 365 / Office
    Quellen:
      - https://learn.microsoft.com/microsoft-365-apps/privacy/manage-privacy-controls
      - https://learn.microsoft.com/microsoft-365-apps/privacy/configure-diagnostic-data
    Die Office-Richtlinien gelten pro Benutzer (HKCU).
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$o  = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Common'
$ct = 'HKCU:\Software\Policies\Microsoft\Office\Common\ClientTelemetry'

@{
    Id          = 'office'
    Name        = 'Microsoft 365 / Office'
    Description = 'Diagnosedaten, Feedback, Telemetrie-Aufgaben und "verbundene Erfahrungen" (inkl. Copilot) in Office.'
    Tweaks      = @(
        @{
            Id          = 'office.telemetry'
            Name        = 'Office-Diagnosedaten & Feedback'
            Risk        = 'Low'
            Description = 'Diagnosedatenstufe "Keine" (SendTelemetry = 3), kein CEIP, kein Feedback/Umfragen/Screenshots, keine Telemetrie-Protokollierung (OSM), keine LinkedIn-Funktionen. Deaktiviert zusätzlich Office-Telemetrie-Aufgaben.'
            Registry    = @(
                Reg $ct 'SendTelemetry' 3
                Reg $ct 'DisableTelemetry' 1
                Reg 'HKCU:\Software\Microsoft\Office\Common\ClientTelemetry' 'SendTelemetry' 3
                Reg 'HKCU:\Software\Microsoft\Office\Common\ClientTelemetry' 'DisableTelemetry' 1
                Reg $o 'qmenable' 0
                Reg $o 'sendcustomerdata' 0
                Reg $o 'updatereliabilitydata' 0
                Reg $o 'linkedin' 0
                Reg "$o\Feedback" 'enabled' 0
                Reg "$o\Feedback" 'includescreenshot' 0
                Reg "$o\Feedback" 'surveyenabled' 0
                Reg 'HKCU:\Software\Policies\Microsoft\Office\16.0\OSM' 'EnableLogging' 0
                Reg 'HKCU:\Software\Policies\Microsoft\Office\16.0\OSM' 'EnableUpload' 0
                Reg 'HKCU:\Software\Policies\Microsoft\Office\16.0\OSM' 'EnableFileObfuscation' 1
            )
            Tasks       = @(
                '\Microsoft\Office\OfficeTelemetryAgentLogOn*'
                '\Microsoft\Office\OfficeTelemetryAgentFallBack*'
                '\Microsoft\Office\Office Performance Monitor'
            )
        }
        @{
            Id          = 'office.connected'
            Name        = 'Verbundene Erfahrungen & Copilot in Office'
            Risk        = 'Medium'
            Description = 'Deaktiviert alle optionalen und inhaltsanalysierenden "verbundenen Erfahrungen" von Office: Copilot, Designer, Editor-Cloudprüfung, Übersetzer, Diktat, Online-Vorlagen/-Bilder u. a. Office sendet dann keine Dokumentinhalte mehr an Clouddienste.'
            Warning     = 'Speichern in OneDrive/SharePoint, Online-Vorlagen, Copilot, Diktat und Übersetzen stehen in Office nicht mehr zur Verfügung.'
            Registry    = @(
                Reg "$o\Privacy" 'DisconnectedState' 2
                Reg "$o\Privacy" 'UserContentDisabled' 2
                Reg "$o\Privacy" 'DownloadContentDisabled' 2
                Reg "$o\Privacy" 'ControllerConnectedServicesEnabled' 2
            )
        }
    )
}
