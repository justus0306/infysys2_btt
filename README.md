# TED-Ausschreibungs-Monitoring (UiPath)

Umsetzung des RoboPath „TED-Ausschreibungs-Monitoring" für die fiktive
**Bavaria Tactical Trading GmbH** (HM, Informationssysteme 2).

UiPath-Projekt (Studio, klassisch, VisualBasic, Target Framework **Windows**, getestet mit Studio **2026.0**).
`Main.xaml` ist als **Flowchart** modelliert. Zusätzlich zur reinen Automatisierung enthält der Ablauf
einen **Human-in-the-Loop**: nach dem Auffinden neuer Treffer entscheidet ein Mensch im **UiPath Action Center**
je Treffer **Go/No-Go**, erst nach Freigabe werden Kalender + Mail erzeugt (Long-Running / Orchestration Process).

## Inhalt
```
TED_Ausschreibungs_Monitoring/
├── project.json              UiPath-Projektdatei (Long-Running: supportsPersistence = true)
├── Main.xaml                 Flowchart (5 Daten-Schritte + Go/No-Go-Gate + 2 Entscheidungen + Schleife + Try/Catch)
├── Data/
│   ├── suchkriterien.xlsx    Eingabe: CPV-Codes, Land, Schwellenwert, Prioritaet, Aktiv-Flag
│   └── seen.xlsx             Gesehen-Liste (Dedup-Log), wird vom Bot befüllt
├── Forms/
│   └── GoNoGo.json           Action-Center-Formular für die Freigabe-Aufgabe (Buttons Approve/Reject)
└── README.md
```

## Öffnen / „Importieren"
1. ZIP entpacken.
2. UiPath Studio → **Open** → den Ordner `TED_Ausschreibungs_Monitoring` (bzw. die `project.json`) wählen.
3. Das Projekt ist für Studio **2026.0** vorbereitet. Da die `studioVersion` in der Datei etwas älter ist, bietet Studio beim Öffnen evtl. an, das Projekt **auf deine Version zu aktualisieren** → bestätigen (normaler Vorgang, kein Fehler).
4. Als Abhängigkeit ist nur **UiPath.System.Activities** gesetzt (Version aus der aktuellen 26.x-Generation – das genügt, damit das Projekt fehlerfrei lädt). Liegt sie nicht lokal vor, lädt Studio sie aus dem offiziellen Feed; bietet Studio eine andere/neuere Version an, kannst du das bedenkenlos bestätigen.
5. **Bevor du die echten Aktivitäten baust:** über *Pakete verwalten / Manage Packages* hinzufügen – Studio wählt automatisch die zu 2026.0 passenden Versionen:
   - `UiPath.UIAutomation.Activities` (Browser/TED, Schritte 2–4)
   - `UiPath.Excel.Activities` (suchkriterien.xlsx / seen.xlsx, Schritte 1 & 5)
   - `UiPath.Mail.Activities` (Freigabe-Mail, Schritt 8)
   - `UiPath.Persistence.Activities` (**Human-in-the-Loop**, Schritt 6 – Create Form Task / Wait for Form Task and Resume)
   - `UiPath.Form.Activities` (Form-Designer für `Forms/GoNoGo.json`)
6. Flowchart-Layout: Rechtsklick auf den Canvas → **Auto Arrange** (oder Knoten manuell anordnen) für die saubere Anordnung.

> Hinweis StudioX: Das ist ein **Studio**-Projekt (klassische Aktivitäten + Flowchart). Du kannst es in derselben UiPath-Studio-App öffnen. Wenn dein Kurs strikt StudioX verlangt, nutze es als Struktur-Blaupause und baue die Schritte mit den modernen Karten („Excel-Datei verwenden", „Anwendung/Browser verwenden", „Outlook-Mail senden") nach – die Logik, Variablen und die CPV-Mechanik bleiben identisch.

## Suchkriterien (`Data/suchkriterien.xlsx`)
Die CPV-Codes sind auf das Sortiment der Bavaria Tactical Trading GmbH zugeschnitten –
**Surplus military equipment, Munition und taktische Ausruestung**. Abgedeckt sind vier Bloecke:

- **Waffen & Munition** (35300000 Waffen/Munition, 35320000 Schusswaffen, 35330000 Munition, 35340000 Teile, 35310000 sonstige Waffen)
- **Persoenliche / taktische Ausruestung & Koerperschutz** (35800000/35810000 Ausruestung, 35815000/35815100 ballistischer Schutz & kugelsichere Westen, 35813000 Helme, 35811300/35812000 Uniformen)
- **Militaerfahrzeuge** (35400000 Fahrzeuge, 35420000 Teile, 35410000 gepanzert)
- **Taktische Bekleidung & Schuhe** (35113400 Schutzkleidung, 18100000 Spezialarbeitskleidung, 18800000 Einsatzstiefel)

Drei Spalten steuern die Logik des Bots und sind die Stellschrauben fuer die Auswertung:

| Spalte | Wirkung |
|---|---|
| `Aktiv` (Ja/Nein) | Nur `Ja`-Zeilen werden gescannt. `Nein` = bewusst ausserhalb Sortiment (z. B. gepanzerte Fahrzeuge zu gross, Gasmasken/See-Munition off-topic) – zeigt den Filter. |
| `Min_Auftragswert_EUR` | Untergrenze als Rauschfilter; Treffer darunter werden verworfen. |
| `Prioritaet` (Hoch/Mittel/Niedrig) | Sortiert bzw. hebt Treffer in der Mail hervor (Kerngeschaeft Waffen/Munition/Koerperschutz = `Hoch`). |

`Land`: `DE`/`AT` filtern auf das Auftraggeber-Land, `EU` = EU-weit (kein Laenderfilter).
Die Werte sind plausible Beispiele und in der xlsx frei anpassbar.

> **CPV-Stand:** Aktuell ist weiterhin **CPV 2008** (Verordnung (EG) Nr. 213/2008) – das ist die
> gueltige Version fuer TED-Suche und Notice-Ausfuellung; eine neuere CPV-Fassung ist (Stand 2026)
> nicht veroeffentlicht. Die EU-Kommission ueberarbeitet das Vokabular seit 2022 (u. a. fehlende
> Kategorien wie KI/Cloud/Cybersecurity), ein Ergebnis steht aber noch aus.

## Lauffähig „out of the box"
`NewHitCount` ist mit **0** vorbelegt. Beim Start läuft der Flow also sauber durch (Zweig **nein** → warten → Schleife) und protokolliert jeden Schritt per *Log Message* – ohne Crash. So kannst du den 24/7-Loop sofort demonstrieren und dann Schritt für Schritt die echten Aktivitäten ergänzen.

> Test-Tipp: `PollIntervalMinutes` (Variable im Flowchart) für Tests auf 1 setzen, später wieder auf 30.

## Was noch konfiguriert werden muss (am echten System)
Jeder Knoten enthält eine **Annotation** mit der konkreten Aufgabe. In Kürze:

| Schritt | System | Einzubauende Aktivität |
|---|---|---|
| 1 | Excel | *Excel-Anwendungsbereich* + *Bereich lesen* → `dt_Criteria` |
| 2 | Browser | *Anwendung/Browser verwenden* → `https://ted.europa.eu` |
| 3 | TED | *Text eingeben* (CPV + Filter), *Klicken* (Suche) je aktiver Zeile |
| 4 | TED + seen.xlsx | *Tabellendaten extrahieren* → `dt_Hits`; `seen.xlsx` → `dt_Seen`; Dedup → `dt_NewHits`; `NewHitCount = dt_NewHits.Rows.Count` |
| 5 | Excel (R/W) | *Bereich anhängen* der neuen Notice-IDs in `seen.xlsx` |
| **6** | **Action Center** | **Create Form Task** (FormData aus `dt_NewHits`, Formular `Forms/GoNoGo.json`) → **Wait for Form Task and Resume** → `HumanDecision = TaskAction` |
| 7 | iCalendar/FS | pro **freigegebenem** Treffer eine `.ics` (VEVENT, `DTSTART` = Abgabefrist) |
| 8 | Outlook | *Outlook-Mail senden* (HTML-Body der **freigegebenen** Treffer) |
| 9 | UiPath Log | Lauf protokollieren / Per-Step-Fehlerbehandlung |
| 9b | UiPath Log | **abgelehnte** Treffer protokollieren / eskalieren |

Selektoren (Schritte 2–5) müssen **live** gegen die TED-Seite aufgenommen werden – die hängen am realen DOM und lassen sich nicht vorab generieren.

## Human-in-the-Loop (Action Center) — Schritt 6
Genau der „Mensch entscheidet Go/No-Go"-Teil aus dem RoboPath. Nach der Entscheidung
**„Neue Treffer ≥ 1?"** geht der Ablauf in den Knoten **„6. Go/No-Go im Action Center"**.
Danach folgt eine zweite Entscheidung **„Freigegeben?"**:

- **freigegeben** → 7. `.ics`-Kalender + 8. Freigabe-Mail + 9. Logging → Schleife
- **abgelehnt** → 9b. Logging / Eskalation → Schleife

Das Gerüst läuft sofort durch (Variable `HumanDecision` ist mit `Approve` vorbelegt; bei
`NewHitCount = 0` wird der Knoten ohnehin nicht erreicht). So baust du die zwei echten Aktivitäten ein:

1. In Knoten 6 ein **Create Form Task** ablegen:
   - *Form file path* → `Forms\GoNoGo.json` (oder das Formular im **Form Designer** öffnen/anpassen).
   - *FormData* → je Treffer die Felder `Titel`, `Frist`, `Land`, `CPV`, `Auftragswert`, `Link` (Schlüssel = die Feld-Keys im Formular) aus der jeweiligen Zeile von `dt_NewHits`.
   - *TaskObject* → Ausgabe-Variable (Typ `FormTaskData`).
2. Direkt danach **Wait for Form Task and Resume**:
   - *TaskObject (In)* → die eben erzeugte `FormTaskData`.
   - *TaskAction (Out)* → in die Variable `HumanDecision` schreiben.
3. Die Entscheidung **„Freigegeben?"** prüft `HumanDecision = "Approve"` – das muss zum
   **Approve-Button** im Formular passen (`Forms/GoNoGo.json`: Buttons `Approve` / `Reject`).

Bei mehreren Treffern: entweder pro Zeile eine Aufgabe (in einer `For Each`-Schleife – Hinweis:
`Wait …`-Aktivitäten nicht direkt in den `For Each`-Body legen, sondern dem Orchestration-Muster
folgen) oder eine Sammel-Aufgabe mit allen Treffern in einer Tabelle.

**Voraussetzung:** Action Center + Orchestrator (in der **UiPath Community Cloud** kostenlos enthalten).
Long-Running-Jobs werden beim `Wait …` **suspendiert** (Variablen werden in Orchestrator gespeichert)
und nach der menschlichen Entscheidung automatisch fortgesetzt. Zum Ausprobieren in Studio: das Projekt
ist bereits als **Orchestration Process** markiert (`supportsPersistence = true`, prüfbar unter
*Projekteinstellungen*); das Debuggen erfolgt in einer Benutzersitzung. Alternativ kannst du das Projekt
auch direkt aus der Studio-Vorlage **Home → Orchestration Process** aufsetzen.

## Hinweis zur TED-Suche (Browser, Schritte 2–4)
Die Recherche läuft per **Browser-Automatisierung** – die Suchmaske auf `ted.europa.eu` wird
mit den CPV-Codes ausgefüllt und durchgeklickt (so wie im RoboPath vorgesehen). Praktische Punkte
für die Umsetzung:
- **UiPath-Browser-Extension** installieren (Studio → Tools), sonst funktioniert das Ansteuern der Seite nicht.
- TED ist eine **dynamische Web-App** → Selektoren live aufnehmen, mit *Check App State* auf geladene Elemente warten statt mit festen Delays. Cookie-Banner als optionalen Klick behandeln.
- Treffer sind **Karten/Listeneinträge** (kein klassisches `<table>`) → den *Daten-extrahieren*-Assistenten auf die ersten Trefferkarten anwenden; Paginierung aktivieren.
- Falls die **Abgabefrist** nicht in der Trefferliste steht, pro neuem Treffer kurz die Detailseite öffnen und sie auslesen (wird für den `.ics`-Eintrag in Schritt 7 gebraucht).

## Hinweis zur Schleife (24/7)
Alle Endzweige (Logging nach Freigabe **9**, Ablehnung **9b**, sowie „keine neuen Treffer") münden in ein Warte-/Poll-Intervall und schleifen zurück zum Start – kontinuierliches Monitoring passend zu „0 verpasste Deadlines". Willst du statt des Endlos-Loops das **END** wie auf der Folie, verbinde den letzten Logging-Knoten mit einem End-Knoten. Sauberer für den Produktivbetrieb ist ein zeitgesteuerter **Orchestrator-Trigger** (z. B. täglich) statt der Endlosschleife.
