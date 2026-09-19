<#
    Modul: Telemetrie & Diagnosedaten
    Quellen:
      - https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
      - https://learn.microsoft.com/windows/client-management/mdm/policy-csp-system
      - https://learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$dc  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
$wer = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'

@{
    Id          = 'telemetry'
    Name        = 'Telemetrie & Diagnosedaten'
    Description = 'Diagnosedaten (DiagTrack/"Connected User Experiences"), Kompatibilitäts-Telemetrie, CEIP, Fehlerberichte und Feedback-Anfragen.'
    Tweaks      = @(
        @{
            Id          = 'telemetry.level'
            Name        = 'Diagnosedaten auf Minimum setzen'
            Risk        = 'Low'
            Description = 'Setzt die Diagnosedatenstufe per Richtlinie auf 0 ("Security"). Unter Home/Pro behandelt Windows 0 wie 1 ("Erforderlich") - der Rest dieses Moduls (Dienst, Aufgaben) unterbindet die Übertragung dann zusätzlich. Sperrt außerdem OneSettings-Downloads, Gerätename in Telemetrie, Diagnosedaten-Viewer und Opt-in-Hinweise.'
            Source      = 'Policy CSP System/AllowTelemetry, DisableOneSettingsDownloads, AllowDeviceNameInDiagnosticData'
            Registry    = @(
                Reg $dc 'AllowTelemetry' 0
                Reg $dc 'MaxTelemetryAllowed' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'MaxTelemetryAllowed' 0
                Reg $dc 'DisableOneSettingsDownloads' 1
                Reg $dc 'DisableTelemetryOptInChangeNotification' 1
                Reg $dc 'DisableTelemetryOptInSettingsUx' 1
                Reg $dc 'AllowDeviceNameInTelemetry' 0
                Reg $dc 'LimitDiagnosticLogCollection' 1
                Reg $dc 'LimitDumpCollection' 1
                Reg $dc 'DisableDiagnosticDataViewer' 1
                Reg $dc 'AllowCommercialDataPipeline' 0
                Reg $dc 'AllowDesktopAnalyticsProcessing' 0
                Reg $dc 'AllowUpdateComplianceProcessing' 0
                Reg $dc 'AllowWUfBCloudProcessing' 0
                Reg $dc 'MicrosoftEdgeDataOptIn' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack' 'ShowedToastAtLevel' 1
            )
        }
        @{
            Id          = 'telemetry.services'
            Name        = 'Telemetrie-Dienste und ETW-Logger abschalten'
            Risk        = 'Low'
            Description = 'Deaktiviert "Benutzererfahrungen und Telemetrie im verbundenen Modus" (DiagTrack), den WAP-Push-Dienst (dmwappushservice) und die AutoLogger-Sitzungen, die Telemetrie bereits beim Booten mitschreiben.'
            Services    = @('DiagTrack', 'dmwappushservice', 'diagnosticshub.standardcollector.service')
            Registry    = @(
                Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener' 'Start' 0
                Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger' 'Start' 0
                Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener' 'Start' 0
            )
        }
        @{
            Id          = 'telemetry.tasks'
            Name        = 'Telemetrie-Aufgaben deaktivieren'
            Risk        = 'Low'
            Description = 'Geplante Aufgaben, die Inventar-, Kompatibilitäts-, Nutzungs- und Gerätedaten sammeln und hochladen (Compatibility Appraiser, CEIP, Device Census, Feedback, Flighting-Nutzungsdaten, Sustainability-Telemetrie).'
            Tasks       = @(
                '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
                '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp'
                '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
                '\Microsoft\Windows\Application Experience\MareBackup'
                '\Microsoft\Windows\Autochk\Proxy'
                '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
                '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
                '\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask'
                '\Microsoft\Windows\Device Information\Device'
                '\Microsoft\Windows\Device Information\Device User'
                '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
                '\Microsoft\Windows\Feedback\Siuf\DmClient'
                '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
                '\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting'
                '\Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing'
                '\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver'
                '\Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting'
                '\Microsoft\Windows\Flighting\OneSettings\RefreshCache'
                '\Microsoft\Windows\Sustainability\SustainabilityTelemetry'
                '\Microsoft\Windows\PI\Sqm-Tasks'
                '\Microsoft\Windows\NetTrace\GatherNetworkInfo'
                '\Microsoft\Windows\CloudExperienceHost\CreateObjectTask'
            )
        }
        @{
            Id          = 'telemetry.ceip'
            Name        = 'Programm zur Verbesserung der Benutzerfreundlichkeit (CEIP) & Inventar'
            Risk        = 'Low'
            Description = 'Schaltet CEIP/SQM, den Inventory Collector, den Steps Recorder (Problemaufzeichnung) und die Application-Impact-Telemetrie ab.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows' 'CEIPEnable' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows' 'CEIPEnable' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\AppV\CEIP' 'CEIPEnable' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Messenger\Client' 'CEIP' 2
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'AITEnable' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableInventory' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableUAR' 1
            )
        }
        @{
            Id          = 'telemetry.appraiser'
            Name        = 'Inventar-, Kompatibilitäts- und "Health"-Dienste'
            Risk        = 'Medium'
            Description = 'Deaktiviert den Inventory-and-Compatibility-Appraisal-Dienst (InventorySvc), "Windows Health and Optimized Experiences" (whesvc) und den Programmkompatibilitäts-Assistenten (PcaSvc).'
            Warning     = 'Der Programmkompatibilitäts-Assistent schlägt bei alten Programmen keine Kompatibilitätseinstellungen mehr vor. Feature-Update-Kompatibilitätsprüfungen werden ungenauer.'
            Services    = @('InventorySvc', 'whesvc', 'PcaSvc')
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA' 1
            )
        }
        @{
            Id          = 'telemetry.wer'
            Name        = 'Windows-Fehlerberichterstattung abschalten'
            Risk        = 'Low'
            Description = 'Absturz- und Fehlerberichte (inkl. Speicherabbilder) werden nicht mehr an Microsoft gesendet. Handschrift-Fehlerberichte ebenfalls.'
            Registry    = @(
                Reg $wer 'Disabled' 1
                Reg $wer 'DontSendAdditionalData' 1
                Reg $wer 'LoggingDisabled' 1
                Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting' 'DoReport' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' 'PreventHandwritingErrorReports' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC' 'PreventHandwritingDataSharing' 1
            )
            Services    = @('WerSvc')
            Tasks       = @('\Microsoft\Windows\Windows Error Reporting\QueueReporting')
        }
        @{
            Id          = 'telemetry.feedback'
            Name        = 'Feedback-Anfragen unterbinden'
            Risk        = 'Low'
            Description = 'Windows fragt nicht mehr nach Feedback ("Wie wahrscheinlich ist es, dass Sie Windows empfehlen...").'
            Registry    = @(
                Reg 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
                Reg 'HKCU:\Software\Microsoft\Siuf\Rules' 'PeriodInNanoSeconds' 0 'QWord'
                Reg $dc 'DoNotShowFeedbackNotifications' 1
            )
        }
        @{
            Id          = 'telemetry.tailored'
            Name        = 'Maßgeschneiderte Erfahrungen mit Diagnosedaten'
            Risk        = 'Low'
            Description = 'Microsoft darf Diagnosedaten nicht für personalisierte Tipps, Werbung und Empfehlungen nutzen.'
            Registry    = @(
                Reg 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
                Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
            )
        }
        @{
            Id          = 'telemetry.diagnostics'
            Name        = 'Online-Problembehandlung & PerfTrack'
            Risk        = 'Low'
            Description = 'Die Problembehandlung lädt keine Skripte mehr von Microsoft-Servern, und PerfTrack (Leistungs-Telemetrie des Diagnosedienstes) wird abgeschaltet.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnosticsProvider\Policy' 'DisableQueryRemoteServer' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnosticsProvider\Policy' 'EnableQueryRemoteServer' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}' 'ScenarioExecutionEnabled' 0
            )
        }
        @{
            Id          = 'telemetry.insider'
            Name        = 'Insider-Programm, Experimente & Flighting'
            Risk        = 'Low'
            Description = 'Blockiert Insider-Builds und Microsoft-Experimente (A/B-Tests über "Flighting") auf dem Gerät und deaktiviert den Insider-Dienst.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' 'AllowBuildPreview' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' 'EnableConfigFlighting' 0
                Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\System' 'AllowExperimentation' 0
            )
            Services    = @('wisvc')
        }
        @{
            Id          = 'telemetry.kms'
            Name        = 'Lizenz-Online-Validierung (KMS Client AVS)'
            Risk        = 'Low'
            Description = 'Verhindert, dass der KMS-Client Validierungs-Tickets an Microsoft sendet. Die normale Windows-Aktivierung ist davon nicht betroffen.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform' 'NoGenTicket' 1
            )
        }
    )
}
