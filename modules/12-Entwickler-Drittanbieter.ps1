<#
    Modul: Entwickler- & Drittanbieter-Telemetrie
    Quellen:
      - https://learn.microsoft.com/dotnet/core/tools/telemetry
      - https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_telemetry
      - https://learn.microsoft.com/visualstudio/ide/visual-studio-experience-improvement-program
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}
$envKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

@{
    Id          = 'dev'
    Name        = 'Entwickler- & Drittanbieter-Telemetrie'
    Description = 'Opt-out-Variablen für .NET, PowerShell, Azure CLI & Co., Visual Studio, NVIDIA.'
    Tweaks      = @(
        @{
            Id          = 'dev.env'
            Name        = 'Telemetrie-Opt-out-Umgebungsvariablen (systemweit)'
            Risk        = 'Low'
            Description = 'Setzt systemweite Umgebungsvariablen, mit denen gängige Entwicklerwerkzeuge ihre Telemetrie abschalten (.NET CLI, PowerShell 7, Azure CLI/Functions, vcpkg, Next.js, Nuxt, Astro, Storybook, Hugging Face, HashiCorp, allgemein DO_NOT_TRACK). Wirkt für neu gestartete Programme.'
            Registry    = @(
                Reg $envKey 'DOTNET_CLI_TELEMETRY_OPTOUT' '1' 'String'
                Reg $envKey 'POWERSHELL_TELEMETRY_OPTOUT' '1' 'String'
                Reg $envKey 'POWERSHELL_UPDATECHECK' 'Off' 'String'
                Reg $envKey 'AZURE_CORE_COLLECT_TELEMETRY' '0' 'String'
                Reg $envKey 'FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT' '1' 'String'
                Reg $envKey 'VCPKG_DISABLE_METRICS' '1' 'String'
                Reg $envKey 'NEXT_TELEMETRY_DISABLED' '1' 'String'
                Reg $envKey 'NUXT_TELEMETRY_DISABLED' '1' 'String'
                Reg $envKey 'ASTRO_TELEMETRY_DISABLED' '1' 'String'
                Reg $envKey 'STORYBOOK_DISABLE_TELEMETRY' '1' 'String'
                Reg $envKey 'HF_HUB_DISABLE_TELEMETRY' '1' 'String'
                Reg $envKey 'CHECKPOINT_DISABLE' '1' 'String'
                Reg $envKey 'DO_NOT_TRACK' '1' 'String'
            )
            ScriptInfo  = 'Änderung der Umgebungsvariablen an laufende Programme melden'
            Script      = {
                # Schreibt denselben Wert erneut über die .NET-API, die WM_SETTINGCHANGE sendet
                [Environment]::SetEnvironmentVariable('DO_NOT_TRACK', '1', 'Machine')
            }
        }
        @{
            Id          = 'dev.visualstudio'
            Name        = 'Visual Studio: Programm zur Verbesserung & Feedback'
            Risk        = 'Low'
            Description = 'Deaktiviert das "Visual Studio Customer Experience Improvement Program" (alle Versionen) und das Feedback-Tool mit E-Mail-/Screenshot-Übermittlung.'
            Registry    = @(
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\SQM' 'OptIn' 0
                Reg 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VSCommon\16.0\SQM' 'OptIn' 0
                Reg 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VSCommon\17.0\SQM' 'OptIn' 0
                Reg 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VSCommon\18.0\SQM' 'OptIn' 0
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableFeedbackDialog' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableEmailInput' 1
                Reg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableScreenshotCapture' 1
                Reg 'HKCU:\Software\Microsoft\VisualStudio\Telemetry' 'TurnOffSwitch' 1
            )
        }
        @{
            Id          = 'dev.nvidia'
            Name        = 'NVIDIA-Telemetrie'
            Risk        = 'Low'
            Description = 'Deaktiviert NVIDIA-Telemetrie-Aufgaben/-Dienst und die Nutzungsdaten-Opt-ins des Treibers (falls vorhanden). Treiber und NVIDIA App funktionieren weiter.'
            Services    = @('NvTelemetryContainer')
            Tasks       = @('\NvTmRep*', '\NvTmMon*')
            ScriptInfo  = 'Nutzungsdaten-Opt-ins in der NVIDIA-Registry abschalten (nur wenn ein NVIDIA-Treiber installiert ist)'
            Script      = {
                if (-not (Test-Path 'HKLM:\SOFTWARE\NVIDIA Corporation')) {
                    Write-B2SLog '  Kein NVIDIA-Treiber gefunden - übersprungen' Info
                    return
                }
                [void](Set-B2SReg -Path 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' -Name 'OptInOrOutPreference' -Value 0)
                foreach ($rid in 'EnableRID44231', 'EnableRID64640', 'EnableRID66610') {
                    [void](Set-B2SReg -Path 'HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS' -Name $rid -Value 0)
                }
            }
        }
    )
}
