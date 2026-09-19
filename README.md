# bye2spy

**Windows 11 Telemetrie, Copilot & KI abschalten – mit einem Befehl, auswählbar, rückgängig machbar.**

bye2spy ist eine Sammlung von PowerShell-Modulen, die alles abschaltet, was Windows 11 an Daten an Microsoft sendet: Diagnosedaten, Copilot, Recall, KI-Agenten, Werbe-IDs, Bing-Suche, Cloud-Synchronisierung, Edge- und Office-Telemetrie. Du wählst in einem Konsolenmenü aus, was deaktiviert wird. Jede Änderung wird gesichert und lässt sich zurücknehmen.

- 12 Module, 75 Einstellungen, jede mit Beschreibung, Risikostufe und Quellenangabe
- Wo möglich werden offizielle Gruppenrichtlinien-Registrywerte von Microsoft verwendet (keine undokumentierten Hacks)
- Statusanzeige: was ist bereits aktiv, was teilweise, was offen
- Vorschau-Modus: zeigt jede Änderung an, ohne etwas zu verändern
- Journal jeder Änderung mit Rückgängig-Funktion, optional ein Systemwiederherstellungspunkt
- Keine Abhängigkeiten, läuft mit der eingebauten Windows PowerShell 5.1

> [!WARNING]
> bye2spy greift tief ins System ein. Einstellungen mit **mittlerem** oder **hohem** Risiko schränken Funktionen oder den Schutz vor Schadsoftware ein. Lies dir die Beschreibung jeder Einstellung durch, bevor du sie anwendest. Nutzung auf eigene Verantwortung.

---

## Schnellstart

PowerShell öffnen (Admin ist nicht nötig, die UAC-Abfrage kommt automatisch) und eingeben:

```powershell
irm https://raw.githubusercontent.com/kschnieders/bye2spy/main/install.ps1 | iex
```

Das lädt die aktuelle Version nach `%ProgramData%\bye2spy` und startet das Auswahlmenü mit Administratorrechten. Beim erneuten Aufruf werden die Programmdateien aktualisiert, deine Sicherungen bleiben erhalten.

**Ohne Menü, direkt die empfohlenen Einstellungen anwenden:**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kschnieders/bye2spy/main/install.ps1))) -Preset Recommended -Yes
```

**Oder lokal aus dem geklonten Repository:**

```powershell
git clone https://github.com/kschnieders/bye2spy.git
cd bye2spy
powershell -ExecutionPolicy Bypass -File .\bye2spy.ps1
```

## Bedienung des Menüs

```
 bye2spy v1.0.0  -  Windows 11 Telemetrie, Copilot & KI abschalten
 Windows 11 Pro 25H2 (Build 26200.9457, Professional)  |  PC\user
 Ausgewählt: 50 / 75   (Mittel: 0, Hoch: 0)   Wiederherstellungspunkt: ja
 --------------------------------------------------------------------------------
 v [x] Telemetrie & Diagnosedaten   10/11 gewählt, 2 aktiv
       [x] Gering  Diagnosedaten auf Minimum setzen                        offen
       [x] Gering  Telemetrie-Dienste und ETW-Logger abschalten            aktiv
       [ ] Mittel  Inventar-, Kompatibilitäts- und "Health"-Dienste        offen
 > [x] Copilot & KI-Funktionen      6/7 gewählt, 0 aktiv
 > [-] Datenschutz & App-Berechtigungen   8/12 gewählt, 1 aktiv
```

| Taste | Funktion |
|---|---|
| ↑ ↓, Bild↑ Bild↓, Pos1, Ende | bewegen |
| Leertaste | Einstellung bzw. ganzes Modul an/aus |
| Enter, → | Modul aufklappen (auf einer Einstellung: Details) |
| ←, Tab | Modul zuklappen, Tab = alle auf/zu |
| D | Details: genau welche Registrywerte, Dienste, Aufgaben, Apps geändert werden |
| E / A / N | Empfohlen / Alles / Nichts auswählen |
| S | Status neu prüfen |
| V | Vorschau: zeigt alle Änderungen, ändert nichts |
| W | Auswahl anwenden (mit Rückfrage) |
| R | Rückgängig: frühere Sicherung zurückspielen |
| P | Systemwiederherstellungspunkt an/aus |
| Q, Esc | Beenden |

Beim Start sind die **empfohlenen** Einstellungen (geringes Risiko) vorausgewählt.

## Risikostufen

| Stufe | Bedeutung | In „Empfohlen“ |
|---|---|:-:|
| **Gering** | Reine Datenschutz- und Telemetrie-Einstellungen, keine spürbaren Nachteile | ✓ |
| **Mittel** | Schaltet Komfortfunktionen ab (z. B. Standort, Phone Link, Push-Benachrichtigungen, Office-Cloudfunktionen) | – |
| **Hoch** | Kann Funktionen brechen oder senkt den Schutz (SmartScreen, Defender-Cloud, OneDrive-Sperre, hosts-Datei) | – |

Mit **A** bzw. `-Preset All` wird wirklich alles ausgewählt. Vor dem Anwenden werden alle Einstellungen mit mittlerem und hohem Risiko samt Warnhinweis aufgelistet.

## Kommandozeile

```powershell
.\bye2spy.ps1                                   # interaktives Menü
.\bye2spy.ps1 -Status                           # Zustand aller Einstellungen anzeigen
.\bye2spy.ps1 -List                             # alle IDs auflisten
.\bye2spy.ps1 -Preset Recommended               # empfohlene Einstellungen (mit Rückfrage)
.\bye2spy.ps1 -Preset All -Exclude defender,network.hosts -Yes
.\bye2spy.ps1 -Module telemetry,ai              # nur empfohlene Einstellungen dieser Module
.\bye2spy.ps1 -Module ai -Preset All            # alles aus dem KI-Modul
.\bye2spy.ps1 -Tweak ai.recall,ai.clicktodo     # genau diese Einstellungen
.\bye2spy.ps1 -Preset All -DryRun               # Vorschau, ändert nichts
.\bye2spy.ps1 -Restore Latest                   # letzten Durchlauf rückgängig machen
.\bye2spy.ps1 -Restore All                      # alle Durchläufe rückgängig machen
```

Weitere Schalter: `-NoRestorePoint` (keinen Wiederherstellungspunkt erstellen), `-Yes` (keine Rückfrage). Ausführliche Hilfe: `Get-Help .\bye2spy.ps1 -Full`.

## Sicherung & Rückgängig

- Vor jeder Änderung wird der alte Wert in `backups\bye2spy_<Datum>.json` gespeichert: Registrywerte samt Typ, Dienst-Starttypen, geplante Aufgaben, optionale Features, Firewallregeln, hosts-Einträge, Defender-Einstellungen.
- **R** im Menü bzw. `-Restore` spielt diese Werte zurück (neueste zuerst). Zurückgespielte Sicherungen werden in `*.json.restored` umbenannt.
- Standardmäßig wird zusätzlich ein Systemwiederherstellungspunkt erstellt. Dafür wird der Computerschutz für das Systemlaufwerk eingeschaltet.
- **Ausnahme:** Entfernte Apps (Modul „Vorinstallierte Apps“) lassen sich nicht automatisch zurückholen, sondern nur über den Microsoft Store neu installieren.
- Protokolle jedes Durchlaufs liegen in `logs\`.

## Module & Einstellungen

Jede Einstellung ist im jeweiligen Modul unter `modules\` dokumentiert (Registrypfade, Dienste, Aufgaben, Quellen). Im Menü zeigt **D** diese Details an.

### Telemetrie & Diagnosedaten (`telemetry`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `telemetry.level` | Diagnosedaten auf Minimum setzen | Gering | ✓ |
| `telemetry.services` | Telemetrie-Dienste und ETW-Logger abschalten | Gering | ✓ |
| `telemetry.tasks` | Telemetrie-Aufgaben deaktivieren | Gering | ✓ |
| `telemetry.ceip` | Programm zur Verbesserung der Benutzerfreundlichkeit (CEIP) & Inventar | Gering | ✓ |
| `telemetry.appraiser` | Inventar-, Kompatibilitäts- und "Health"-Dienste | Mittel |  |
| `telemetry.wer` | Windows-Fehlerberichterstattung abschalten | Gering | ✓ |
| `telemetry.feedback` | Feedback-Anfragen unterbinden | Gering | ✓ |
| `telemetry.tailored` | Maßgeschneiderte Erfahrungen mit Diagnosedaten | Gering | ✓ |
| `telemetry.diagnostics` | Online-Problembehandlung & PerfTrack | Gering | ✓ |
| `telemetry.insider` | Insider-Programm, Experimente & Flighting | Gering | ✓ |
| `telemetry.kms` | Lizenz-Online-Validierung (KMS Client AVS) | Gering | ✓ |

### Copilot & KI-Funktionen (`ai`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `ai.copilot` | Windows Copilot abschalten | Gering | ✓ |
| `ai.copilot-app` | Copilot-App entfernen | Gering | ✓ |
| `ai.m365-app` | App "Microsoft 365 Copilot" (Office Hub) entfernen | Mittel |  |
| `ai.recall` | Recall (Bildschirm-Snapshots) vollständig abschalten | Gering | ✓ |
| `ai.clicktodo` | Click to Do deaktivieren | Gering | ✓ |
| `ai.agents` | KI-Agenten, Agent-Workspaces & MCP-Connectoren sperren | Gering | ✓ |
| `ai.apps` | KI in Editor (Notepad) und Paint abschalten | Gering | ✓ |

### Datenschutz & App-Berechtigungen (`privacy`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `privacy.adid` | Werbe-ID deaktivieren | Gering | ✓ |
| `privacy.tracking` | Sprachliste & App-Start-Tracking | Gering | ✓ |
| `privacy.activity` | Aktivitätsverlauf abschalten | Gering | ✓ |
| `privacy.inking` | Freihand- und Eingabepersonalisierung | Gering | ✓ |
| `privacy.speech` | Online-Spracherkennung | Gering | ✓ |
| `privacy.apppermissions` | App-Zugriff auf persönliche Daten sperren | Gering | ✓ |
| `privacy.voice` | Sprachaktivierung von Apps | Gering | ✓ |
| `privacy.clipboard` | Cloud-Zwischenablage & vorgeschlagene Aktionen | Gering | ✓ |
| `privacy.location` | Standortdienste abschalten | Mittel |  |
| `privacy.findmydevice` | "Mein Gerät suchen" deaktivieren | Mittel |  |
| `privacy.background` | Hintergrund-Apps verbieten | Mittel |  |
| `privacy.camera-mic` | Kamera & Mikrofon für Store-Apps sperren | Hoch |  |

### Suche & Cortana (`search`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `search.web` | Bing-/Websuche im Startmenü abschalten | Gering | ✓ |
| `search.cloud` | Cloud-Suche & Suchhighlights | Gering | ✓ |
| `search.cortana` | Cortana & Standort in der Suche | Gering | ✓ |

### Werbung, Vorschläge & Cloud-Inhalte (`ads`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `ads.cdm` | Content Delivery Manager: Werbung & stille App-Installationen | Gering | ✓ |
| `ads.cloudcontent` | Microsoft-Consumer-Features & Cloud-Inhalte | Gering | ✓ |
| `ads.start` | Startmenü, Explorer & Benachrichtigungen ohne Empfehlungen | Gering | ✓ |
| `ads.widgets` | Widgets / Neuigkeiten und Interessen | Gering | ✓ |
| `ads.spotlight` | Windows-Spotlight vollständig abschalten | Mittel |  |

### Microsoft Edge (`edge`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `edge.telemetry` | Edge-Diagnosedaten & Personalisierung | Gering | ✓ |
| `edge.copilot` | Copilot, Seitenleiste & KI-Funktionen in Edge | Gering | ✓ |
| `edge.promos` | Werbung, Shopping & Empfehlungen in Edge | Gering | ✓ |
| `edge.cloud` | Cloud-Dienste & Synchronisierung in Edge | Mittel |  |

### Microsoft 365 / Office (`office`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `office.telemetry` | Office-Diagnosedaten & Feedback | Gering | ✓ |
| `office.connected` | Verbundene Erfahrungen & Copilot in Office | Mittel |  |

### Cloud, Konten & Synchronisierung (`cloud`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `cloud.settingsync` | Einstellungs- und Nachrichtensynchronisierung | Gering | ✓ |
| `cloud.onedrive-preload` | OneDrive: kein Netzwerkverkehr vor der Anmeldung | Gering | ✓ |
| `cloud.cdp` | Geräteübergreifende Erfahrungen & Phone Link | Mittel |  |
| `cloud.onesync` | Synchronisierungshost (Mail, Kalender, Kontakte) | Mittel |  |
| `cloud.maps` | Offline-Karten: automatische Downloads | Gering | ✓ |
| `cloud.onedrive` | OneDrive vollständig sperren | Hoch |  |
| `cloud.msaccount` | Microsoft-Konto-Anmelde-Assistent deaktivieren | Hoch |  |

### Netzwerk & Systemdienste (`network`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `network.deliveryopt` | Übermittlungsoptimierung ohne Peer-to-Peer | Gering | ✓ |
| `network.rollout` | "Neueste Updates sofort erhalten" & Update-Funktionsrollouts | Gering | ✓ |
| `network.metadata` | Schriftarten-, Geräte- und Datenträger-Metadaten aus dem Netz | Gering | ✓ |
| `network.wifi` | WLAN-Sense & Hotspot-Berichte | Gering | ✓ |
| `network.teredo` | Teredo-Tunnel deaktivieren | Gering | ✓ |
| `network.retaildemo` | Einzelhandelsdemo-Dienst | Gering | ✓ |
| `network.firewall` | Firewall: Telemetrie-Programme ausgehend blockieren | Gering | ✓ |
| `network.push` | Cloud-Push-Benachrichtigungen (WNS) | Mittel |  |
| `network.ncsi` | Aktiven Internet-Verbindungstest (NCSI) abschalten | Mittel |  |
| `network.hosts` | hosts-Datei: Telemetrie-Domains sperren | Hoch |  |

### Defender-Cloud & SmartScreen (`defender`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `defender.cloud` | Defender: Cloudschutz (MAPS) & Beispielübermittlung | Hoch |  |
| `defender.smartscreen` | SmartScreen (Explorer, Store-Apps, Edge) | Hoch |  |
| `defender.phishing` | Erweiterter Phishingschutz (Passworteingabe-Überwachung) | Mittel |  |

### Vorinstallierte Apps entfernen (`apps`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `apps.bing` | Bing-Apps (News, Wetter, Suche, Finanzen, Sport) | Gering | ✓ |
| `apps.feedback` | Feedback-Hub, Hilfe, Tipps, Solitaire | Gering | ✓ |
| `apps.cloudapps` | Weitere Cloud-Apps (Clipchamp, To Do, Power Automate, Dev Home, Family, Karten) | Mittel |  |
| `apps.outlook` | Neues Outlook & alte Mail/Kalender-App | Mittel |  |
| `apps.phonelink` | Smartphone-Link (Phone Link) & Cross Device | Mittel |  |
| `apps.teams` | Microsoft Teams (vorinstalliert) & Chat-Symbol | Mittel |  |
| `apps.widgets` | Widgets-Plattform (Windows Web Experience Pack) | Mittel |  |
| `apps.gamebar` | Xbox Game Bar inkl. Gaming Copilot | Mittel |  |

### Entwickler- & Drittanbieter-Telemetrie (`dev`)

| ID | Einstellung | Risiko | Empfohlen |
|---|---|---|:-:|
| `dev.env` | Telemetrie-Opt-out-Umgebungsvariablen (systemweit) | Gering | ✓ |
| `dev.visualstudio` | Visual Studio: Programm zur Verbesserung & Feedback | Gering | ✓ |
| `dev.nvidia` | NVIDIA-Telemetrie | Gering | ✓ |

## Was bewusst *nicht* abgeschaltet wird

Diese Verbindungen zu Microsoft bleiben absichtlich bestehen, weil ihr Abschalten die Sicherheit des Systems gefährdet:

| Komponente | Warum sie bleibt |
|---|---|
| **Windows Update** und Defender-Signaturupdates | Ohne Sicherheitsupdates ist das System angreifbar. Nur Peer-to-Peer-Verteilung und vorzeitige Funktionsrollouts werden abgeschaltet. |
| **Automatische Root-Zertifikat-Updates** | Ohne sie schlagen HTTPS-Verbindungen zu Websites mit neuen Zertifizierungsstellen fehl. |
| **Zertifikatsperrprüfung (CRL/OCSP)** | Lässt sich laut Microsoft nicht sinnvoll abschalten und schützt vor gesperrten Zertifikaten. |
| **Zeitsynchronisierung (NTP)** | Eine falsche Uhrzeit bricht TLS, Anmeldungen und Updates. |
| **Smart App Control** | Kann nach dem Abschalten nur durch eine Neuinstallation von Windows wieder aktiviert werden. |
| **Microsoft Defender selbst** | Nur die Cloud-Anbindung ist optional abschaltbar (Modul „Defender-Cloud & SmartScreen“, hohes Risiko). |
| **Windows-Aktivierung** | Nötig für ein lizenziertes System. |

## Grenzen & Hinweise

- **Windows Home/Pro:** Die Diagnosedaten-Stufe „0 / Security“ und einige Copilot-Richtlinien (z. B. `RemoveMicrosoftCopilotApp`) wirken laut Microsoft nur unter Enterprise/Education vollständig. Unter Home/Pro wird die Stufe als „Erforderlich“ behandelt. bye2spy schaltet deshalb zusätzlich den Telemetrie-Dienst, die AutoLogger, die Sammelaufgaben und (optional) den ausgehenden Datenverkehr per Firewall ab.
- **Feature-Updates** (z. B. 25H2 → 26H2) setzen manche Einstellungen zurück oder bringen neue Funktionen mit. Nach größeren Updates bye2spy erneut ausführen und mit **S** den Status prüfen.
- **Benutzerbezogene Einstellungen (HKCU)** gelten für das Konto, unter dem bye2spy läuft. Führe es als der Benutzer aus, den du schützen willst (bei der UAC-Abfrage mit einem eigenen Administratorkonto bestätigen, nicht mit einem anderen Admin-Konto). Für weitere Benutzer bye2spy einmal pro Benutzer starten.
- **Manipulationsschutz (Tamper Protection):** Solange er aktiv ist, ignoriert Defender die Cloud-Einstellungen aus dem Defender-Modul. Wer das wirklich will, schaltet den Manipulationsschutz vorher in „Windows-Sicherheit“ aus.
- **hosts-Datei:** Defender meldet Einträge für Microsoft-Domains teilweise als „SettingsModifier:Win32/HostsFileHijack“. Die Firewallregeln (`network.firewall`) sind der zuverlässigere Weg.
- Einige Richtlinien im KI-Modul (Agent-Workspaces, Agent-Connectoren) sind aktuell nur in Insider-/Enterprise-Builds wirksam. Sie werden trotzdem gesetzt, damit sie greifen, sobald die Funktionen ausgerollt werden.
- Nicht abgedeckt: Telemetrie anderer Browser (Chrome, Firefox), VS Code (`"telemetry.telemetryLevel": "off"` in den Einstellungen) und Webdienste, die du selbst aufrufst.

## Projektstruktur

```
bye2spy/
├── install.ps1          # Web-Starter für "irm ... | iex" (reines ASCII)
├── bye2spy.ps1          # Master-Skript: Menü, Kommandozeile, Anwenden, Rückgängig
├── lib/
│   └── Bye2Spy.Core.psm1  # Aktionen mit Journal: Registry, Dienste, Aufgaben, Apps, Firewall, hosts, Defender
└── modules/
    ├── 01-Telemetrie.ps1
    ├── 02-Copilot-KI.ps1
    ├── ...
    └── 12-Entwickler-Drittanbieter.ps1
```

### Eigenes Modul hinzufügen

Eine neue Datei `modules\NN-Name.ps1` wird automatisch geladen. Sie gibt eine Hashtable zurück, und das Master-Skript übernimmt Anwenden, Status, Vorschau und Rückgängig:

```powershell
function Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
}

@{
    Id          = 'beispiel'
    Name        = 'Mein Modul'
    Description = 'Wofür das Modul da ist.'
    Tweaks      = @(
        @{
            Id          = 'beispiel.eins'
            Name        = 'Etwas abschalten'
            Risk        = 'Low'            # Low | Medium | High  (Low = in "Empfohlen")
            Description = 'Was passiert und warum.'
            Warning     = 'Optional: was danach nicht mehr funktioniert.'
            Registry    = @( Reg 'HKLM:\SOFTWARE\Policies\...' 'WertName' 0 )
            Services    = @('DienstName')                        # Starttyp -> Deaktiviert
            Tasks       = @('\Microsoft\Windows\Pfad\Aufgabe')   # Platzhalter * erlaubt
            Appx        = @('Hersteller.AppName')                # für alle Benutzer entfernen
            OptionalFeatures = @('FeatureName')
            Firewall    = @( @{ Name = 'Regel'; Program = '%SystemRoot%\System32\x.exe' } )
            Script      = { <# eigene Aktion, z. B. mit Set-B2SReg #> }
            ScriptInfo  = 'Beschreibung der eigenen Aktion'
            Test        = { <# $true, wenn die eigene Aktion bereits aktiv ist #> }
        }
    )
}
```

## Quellen

- Microsoft: [Manage connections from Windows operating system components to Microsoft services](https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services)
- Microsoft: [WindowsAI Policy CSP](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-windowsai) (Recall, Click to Do, Copilot, Agenten, Paint)
- Microsoft: [Manage Notepad](https://learn.microsoft.com/windows/client-management/manage-notepad) (KI-Funktionen im Editor)
- Microsoft: [Microsoft Edge Browser Policy Documentation](https://learn.microsoft.com/deployedge/microsoft-edge-policies)
- Microsoft: [Manage Microsoft Copilot Chat](https://learn.microsoft.com/copilot/manage) (Copilot in Edge)
- Microsoft: [Privacy controls for Microsoft 365 Apps](https://learn.microsoft.com/microsoft-365-apps/privacy/manage-privacy-controls)
- 4sysops: [Uninstall Copilot with RemoveMicrosoftCopilotApp](https://4sysops.com/archives/uninstall-copilot-from-windows-11-with-removemicrosoftcopilotapp-group-policy-powershell-or-intune/)
- Windows Latest: [How I disabled 13 AI features in Windows 11](https://www.windowslatest.com/2026/02/06/how-i-disabled-13-ai-features-in-windows-11-safely-no-third-party-apps-needed/)

## Haftungsausschluss

bye2spy ist ein privates Projekt ohne Verbindung zu Microsoft. Die Nutzung erfolgt auf eigene Gefahr. Teste neue Versionen zuerst mit der Vorschau (**V** bzw. `-DryRun`).
