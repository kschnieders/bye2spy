<#
    Modul: Bloatware entfernen (herstellerunabhängig)

    Entfernt vorinstallierte Apps, die niemand braucht: Microsoft-Beigaben,
    Hersteller-Software (HP, Lenovo, Dell, Acer, ASUS, MSI, Samsung, ...) und
    Werbe-Apps von Drittanbietern (Spotify, TikTok, Candy Crush, ...).

    Sicherheitsnetz: Bei den Hersteller-Apps werden Pakete verschont, deren Name auf
    eine Treiber-Begleit-App hindeutet (Audio, Grafik, Kamera, Touchpad, Stift, Akku),
    weil davon Hardwarefunktionen abhängen können.

    Wiederherstellung: Apps lassen sich nur über den Microsoft Store neu installieren.
    Damit Windows sie nicht selbst wieder nachinstalliert, zusätzlich die Einstellungen
    "ads.cdm" und "ads.cloudcontent" aus dem Modul "Werbung, Vorschläge & Cloud-Inhalte"
    anwenden.
#>
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}

@{
    Id          = 'bloat'
    Name        = 'Bloatware entfernen (alle Hersteller)'
    Description = 'Vorinstallierte Microsoft-Beigaben, Hersteller-Software (OEM) und Werbe-Apps von Drittanbietern. Nicht über das Journal rückgängig zu machen - Neuinstallation nur über den Microsoft Store.'
    Tweaks      = @(
        @{
            Id          = 'bloat.promo'
            Name        = 'Werbe- und Partner-Apps von Drittanbietern'
            Risk        = 'Low'
            Description = 'Entfernt die Spiele- und Streaming-Apps, die Windows und OEMs als Werbung mitliefern (Candy Crush, Spotify, TikTok, Netflix, Disney+, Instagram, Facebook, Amazon, Booking, Duolingo, Roblox, WinZip-Werbeversionen u. a.). Wenn du eine davon bewusst nutzt, vorher die Detailansicht (D) prüfen.'
            Appx        = @(
                'king.com.*'
                '*CandyCrush*'
                '*BubbleWitch*'
                '*MarchofEmpires*'
                '*Asphalt*'
                '*RoyalRevolt*'
                '*Sway*'
                'SpotifyAB.SpotifyMusic'
                '*Netflix*'
                '*DisneyMagicKingdoms*'
                '*Disney*'
                '*Hulu*'
                '*Facebook*'
                '*Instagram*'
                '*TikTok*'
                '*Twitter*'
                '*LinkedIn*'
                '*Amazon*'
                '*Booking*'
                '*Duolingo*'
                '*Roblox*'
                '*PicsArt*'
                '*Plex*'
                '*WinZip*'
                '*Dropbox*'
                '*AdobeExpress*'
                '*AdobePhotoshopExpress*'
                '*EclipseManager*'
                '*ActiproSoftware*'
                '*Flipboard*'
                '*Wunderlist*'
                '*Keeper*'
                '*Speedtest*'
            )
        }
        @{
            Id          = 'bloat.msapps'
            Name        = 'Nicht benötigte Microsoft-Beigaben'
            Risk        = 'Medium'
            Description = 'Entfernt Microsoft-Apps, die die meisten nie nutzen: Skype, 3D-Viewer, Paint 3D, Print 3D, Mixed Reality Portal, Groove-Musik, Filme & TV, Whiteboard, Wallet, Journal, OneConnect sowie die Store-Variante von OneNote.'
            Warning     = 'Prüfe vorher die Detailansicht (D). Sicherheitsrelevante oder täglich genutzte Apps (Fotos, Kamera, Rechner, Snipping Tool, Terminal, Store) werden bewusst nicht angefasst.'
            Appx        = @(
                'Microsoft.SkypeApp'
                'Microsoft.Microsoft3DViewer'
                'Microsoft.MSPaint'
                'Microsoft.Print3D'
                'Microsoft.3DBuilder'
                'Microsoft.MixedReality.Portal'
                'Microsoft.ZuneMusic'
                'Microsoft.ZuneVideo'
                'Microsoft.Whiteboard'
                'Microsoft.Wallet'
                'Microsoft.WindowsSoundRecorder'
                'Microsoft.Office.OneNote'
                'Microsoft.OneConnect'
                'Microsoft.MicrosoftJournal'
                'Microsoft.WindowsAlarms'
            )
        }
        @{
            Id          = 'bloat.xbox'
            Name        = 'Xbox-Apps und Xbox-Dienste'
            Risk        = 'Medium'
            Description = 'Entfernt die Xbox-Apps (Konsolenbegleiter, Xbox-App, Identitätsanbieter, Sprachüberlagerung) und deaktiviert die zugehörigen Hintergrunddienste.'
            Warning     = 'Nur wählen, wenn du nicht über den PC Game Pass oder Xbox-Dienste spielst. Steam, GOG, Epic und Spiele ohne Xbox-Anbindung sind nicht betroffen.'
            Appx        = @(
                'Microsoft.XboxApp'
                'Microsoft.GamingApp'
                'Microsoft.XboxGameOverlay'
                'Microsoft.XboxIdentityProvider'
                'Microsoft.XboxSpeechToTextOverlay'
                'Microsoft.Xbox.TCUI'
            )
            Services    = @('XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc')
        }
        @{
            Id          = 'bloat.oem'
            Name        = 'Hersteller-Software (HP, Lenovo, Dell, Acer, ASUS, MSI, Samsung ...)'
            Risk        = 'Medium'
            Description = 'Entfernt vorinstallierte Store-Apps der PC-Hersteller (Support-Assistenten, Werbe- und Registrierungs-Apps, eigene "Zentralen"). Pakete, deren Name auf eine Treiber-Begleit-App hindeutet (Audio, Dolby, Realtek, Nahimic, Grafik, Kamera, Touchpad, Stift, Akku, Firmware), werden übersprungen.'
            Warning     = 'Herstellerwerkzeuge für Treiber- und BIOS-Updates (z. B. Lenovo Vantage, HP Support Assistant, MyASUS) fallen damit weg. Updates musst du dann selbst über die Hersteller-Website einspielen.'
            ScriptInfo  = 'Alle Store-Apps der bekannten OEM-Herausgeber entfernen, Treiber-Begleit-Apps ausgenommen'
            Script      = {
                $publishers = @(
                    'AD2F1837.*'                 # HP
                    'LenovoCorporation.*'        # Lenovo
                    'E046963F.*'                 # Lenovo (Vantage & Co.)
                    'E0469640.*'                 # Lenovo
                    'DellInc.*'                  # Dell
                    'DellTechnologies.*'
                    'AcerIncorporated.*'         # Acer
                    'ASUSTeKCOMPUTERINC.*'       # ASUS
                    'B9ECED6F.*'                 # ASUS (MyASUS)
                    'MicroStarINTERNATIONALCO.LTD.*'  # MSI
                    'SAMSUNGELECTRONICSCO.LTD.*' # Samsung
                    'ToshibaCorporation.*'       # Toshiba/Dynabook
                    'Fujitsu*'
                    '*.HPPrinterControl'
                    '*HPJumpStart*'
                    '*HPSupportAssistant*'
                    '*LenovoUtility*'
                    '*LenovoVantage*'
                    '*DellCustomerConnect*'
                    '*DellDigitalDelivery*'
                    '*MyASUS*'
                )
                # Diese Pakete gehören zu Hardwarefunktionen und bleiben erhalten
                $keep = 'Audio|Sound|Dolby|Realtek|Nahimic|Waves|DTS|Grafik|Graphics|Display|Camera|Kamera|Touch|Pen|Stift|Battery|Akku|Power|Firmware|Driver|Treiber|Intel|AMD|NVIDIA|Bluetooth|WLAN|WiFi|Fingerprint|Smartcard|Docking|Thunderbolt|Printer|Scanner'

                $all = @()
                try { $all = @(Get-AppxPackage -AllUsers -ErrorAction Stop) }
                catch { $all = @(Get-AppxPackage -ErrorAction SilentlyContinue) }

                $hits = @()
                foreach ($p in $all) {
                    foreach ($pattern in $publishers) {
                        if ($p.Name -like $pattern -or $p.PackageFamilyName -like $pattern) { $hits += $p; break }
                    }
                }
                $hits = @($hits | Sort-Object Name -Unique)
                if (-not $hits.Count) {
                    Write-B2SLog '  Keine Hersteller-Apps gefunden.' Info
                    return
                }
                foreach ($p in $hits) {
                    if ($p.Name -match $keep) {
                        Write-B2SLog "  Übersprungen (Hardware-/Treiber-App): $($p.Name)" Info
                        continue
                    }
                    Remove-B2SAppx -Name $p.Name
                }
            }
            Test        = {
                $keep = 'Audio|Sound|Dolby|Realtek|Nahimic|Waves|DTS|Grafik|Graphics|Display|Camera|Kamera|Touch|Pen|Stift|Battery|Akku|Power|Firmware|Driver|Treiber|Intel|AMD|NVIDIA|Bluetooth|WLAN|WiFi|Fingerprint|Smartcard|Docking|Thunderbolt|Printer|Scanner'
                $patterns = 'AD2F1837.*', 'LenovoCorporation.*', 'E046963F.*', 'E0469640.*', 'DellInc.*', 'DellTechnologies.*',
                'AcerIncorporated.*', 'ASUSTeKCOMPUTERINC.*', 'B9ECED6F.*', 'MicroStarINTERNATIONALCO.LTD.*',
                'SAMSUNGELECTRONICSCO.LTD.*', 'ToshibaCorporation.*', 'Fujitsu*'
                $rest = @(Get-B2SInstalledAppx | Where-Object { $n = $_; (@($patterns | Where-Object { $n -like $_ }).Count -gt 0) -and $n -notmatch $keep })
                $rest.Count -eq 0
            }
        }
        @{
            Id          = 'bloat.win32'
            Name        = 'Vorinstallierte Windows-Programme auflisten (Testversionen & Co.)'
            Risk        = 'Low'
            Description = 'Klassische Programme (kein Store) lassen sich nicht gefahrlos automatisch entfernen - viele Deinstallationsroutinen fragen nach oder brauchen einen Neustart. Diese Einstellung ändert deshalb nichts, sondern listet gefundene Kandidaten (McAfee-/Norton-Testversionen, WildTangent-Spiele, Hersteller-Assistenten, Booking-/ExpressVPN-Werbung) im Protokoll auf, damit du sie gezielt über "Einstellungen > Apps > Installierte Apps" entfernen kannst.'
            ScriptInfo  = 'Nur auflisten - es wird nichts deinstalliert'
            Script      = {
                $patterns = 'McAfee|Norton|WildTangent|Booking\.com|ExpressVPN|Avast|AVG |Dropbox Promotion|HP Support Assistant|HP Wolf|Lenovo Vantage|Lenovo Now|Dell SupportAssist|Dell Digital Delivery|MyASUS|Acer Jumpstart|Killer Control|Trial'
                $keys = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                )
                $found = @(Get-ItemProperty $keys -ErrorAction SilentlyContinue |
                        Where-Object { $_.DisplayName -and $_.DisplayName -match $patterns } |
                        Select-Object -ExpandProperty DisplayName -Unique)
                if (-not $found.Count) {
                    Write-B2SLog '  Keine bekannten vorinstallierten Programme gefunden.' Info
                    return
                }
                Write-B2SLog '  Gefunden (bitte bei Bedarf manuell deinstallieren):' Warn
                foreach ($f in ($found | Sort-Object)) { Write-B2SLog "    - $f" Info }
            }
        }
    )
}
