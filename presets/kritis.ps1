<#
    Preset: KRITIS / Medizin & Praxis

    Gedacht für Arbeitsplätze, an denen Patienten- oder andere besonders schützenswerte
    Daten (Art. 9 DSGVO) verarbeitet werden: Praxen, MVZ, Kliniken, Labore, Apotheken,
    Pflegedienste - ebenso für Kanzleien und andere Berufsgeheimnisträger (§ 203 StGB).

    Grundgedanke:
      1. Alles abschalten, was Daten nach außen gibt oder Bildschirminhalte auswertet.
      2. Alles entfernen, was ein Arbeitsplatz-PC im medizinischen Umfeld nicht braucht.
      3. Schutzfunktionen bleiben AN. Defender-Cloudschutz, SmartScreen und
         Phishingschutz werden bewusst nicht angetastet - ein Praxis-PC ohne
         Schadsoftwareschutz wäre das größere Risiko (Art. 32 DSGVO: Sicherheit
         der Verarbeitung).

    Basis sind alle Einstellungen mit geringem Risiko ("Empfohlen"), erweitert um die
    unten aufgeführten Punkte mit mittlerem/hohem Risiko.
#>
@{
    Id          = 'Kritis'
    Name        = 'KRITIS / Medizin & Praxis'
    Description = 'Maximale Datensparsamkeit für Arbeitsplätze mit Patienten- oder Mandantendaten, ohne die Schutzfunktionen von Windows zu schwächen.'
    Base        = 'Recommended'

    # Zusätzlich zu "Empfohlen" (Einstellungen mit mittlerem/hohem Risiko)
    Include     = @(
        'telemetry.appraiser'   # Inventar-/Kompatibilitätsdienste, melden installierte Software
        'ai.m365-app'           # "Microsoft 365 Copilot"-App
        'privacy.location'      # Standortermittlung - am Praxis-PC nicht nötig
        'privacy.findmydevice'  # Gerätestandort im Microsoft-Konto
        'privacy.background'    # Store-Apps im Hintergrund
        'ads.spotlight'         # Spotlight lädt Bilder und Werbung von Microsoft
        'edge.cloud'            # Edge: keine Synchronisierung, kein Cloud-Editor, kein Autofill
        'office.connected'      # Office darf Dokumentinhalte nicht an Clouddienste geben
        'cloud.cdp'             # Geräteübergreifende Erfahrungen, Phone Link
        'cloud.onesync'         # Synchronisierungshost für Mail/Kalender/Kontakte
        'cloud.onedrive'        # OneDrive sperren - Patientendaten gehören nicht in die Cloud
        'network.push'          # Push-Benachrichtigungen über Microsoft-Server
        'apps.cloudapps'        # Clipchamp, To Do, Power Automate, Dev Home, Karten, Family
        'apps.outlook'          # neues Outlook (spiegelt Postfächer inkl. Zugangsdaten)
        'apps.phonelink'        # Smartphone-Kopplung
        'apps.widgets'          # Widgets-Plattform
        'apps.gamebar'          # Game Bar inkl. Gaming Copilot
        'bloat.msapps'          # Skype, Paint 3D, Groove, Whiteboard, ...
        'bloat.xbox'            # Xbox-Apps und -Dienste
        'bloat.oem'             # Hersteller-Software
    )

    # Bewusst NICHT enthalten, auch nicht über die Basis
    Exclude     = @(
        'defender.cloud'        # Cloudschutz muss aktiv bleiben
        'defender.smartscreen'  # Schutz vor Schadsoftware und Phishing muss aktiv bleiben
        'defender.phishing'
        'network.hosts'         # wird von Defender als Manipulation gewertet
        'network.ncsi'          # "Kein Internet"-Anzeige verwirrt und stört Fachanwendungen
        'privacy.camera-mic'    # Videosprechstunde/Teams brauchen Kamera und Mikrofon
        'cloud.msaccount'       # würde Store-Updates und Anmeldungen blockieren
        'apps.teams'            # Teams wird in vielen Einrichtungen für Besprechungen genutzt
    )

    Notes       = @(
        'Schutzfunktionen bleiben aktiv: Defender-Cloudschutz, SmartScreen und Phishingschutz werden NICHT abgeschaltet.'
        'OneDrive wird gesperrt. Vorher prüfen, ob Dateien nur online liegen oder ob Desktop/Dokumente dorthin umgeleitet sind.'
        'Das neue Outlook, Phone Link, Widgets und die Game Bar werden entfernt; Teams bleibt erhalten.'
        'Praxisverwaltungssoftware (z. B. DS-WIN, CGM, medatixx), TI-Konnektor und Kartenterminals sind nicht betroffen - trotzdem nach dem Neustart kurz testen.'
        'bye2spy ist ein technisches Hilfsmittel, keine Zertifizierung und kein Ersatz für Risikoanalyse, Verarbeitungsverzeichnis oder Datenschutzbeauftragten.'
    )
}
