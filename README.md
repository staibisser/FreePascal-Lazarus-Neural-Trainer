# Free Pascal Neural Trainer 

Dieses Projekt versucht, mit **Free Pascal**, der **CAI Neural API** und **Lazarus GUI** ein neuronales Netz mit grafischer Oberfläche zu erstellen.

Ziel: Zeigen, dass Free Pascal eine leistungsfähige Plattform für Machine Learning und Visualisierung ist – komplett offline, effizient und Open Source.
Dabei wurde Wert auf die Verwendung der **CAI Neural API** gelegt und weniger auf eine optimale GUI.

## ✨ Funktionen

- 📥 CSV-Import & Normalisierung
- 🧠 Netztraining mit CAI Neural API
- 💾 Speichern/Laden von Modellen
- 🔮 Live-Vorhersage per Schieberegler
- 🔁 Rückwärtsoptimierung mit Gradienten
- 📈 Diagramme der Simulationen mit TAChart

Der betrachtete Prozess hat 3 Eingänge und 5 Ausgänge. Das Modell lernt mit den Daten aus der *.csv Datei. Nach dem Training können die Schieber verstellt werden.
Stellen der Eingänge zeigt die zu erwartenden Ausgänge. 
Oder umgekehrt, stellen der Ausgänge zeigt, wie die Eingänge gestellt werden müssten, um die gewünschten Ausgänge zu erhalten. 


## 📦 Aufbau

| Datei                 | Beschreibung                        |
|----------------------|-------------------------------------|
| `/neural-api`       | enthält den API Ordner **/neural** |
| `/Daten/Chart`       | Speicherort des Charts bei Programmende |
| `/Daten/example-data.csv`   | Beispiel für Trainingsdaten         |
| `/Daten/model.nn`           | Beispielmodell (binär)              |
| `/Daten/model.meta`         | INI-Metadaten des Modells, beim Speichern und Laden wird nur *.nn abgefragt       |
| `Anlage.lpi`           | zum Laden des Projektes in die Lazarus IDE         |
| `main.pas`           | Haupt-Unit, GUI, Netzlogik          |
| `Snapshot.jpg`     | GUI-Vorschau                        |



## 🔧 Kompilieren & Starten

1. Öffne `Anlage.lpi` in **Lazarus**
2. Klicke „Starten“ oder drücke `F9`



## 🔌 CAI Neural API einbinden

Damit das Projekt funktioniert, muss die **[CAI Neural API](https://github.com/joaopauloschuler/neural-api)** eingebunden werden.

### So geht's:

1. Lade die Bibliothek von GitHub herunter:  
   🔗 https://github.com/joaopauloschuler/neural-api

2. Kopiere in den **`/neural-api/`-Ordner** des Projekts den API Ordner **/neural/** hinzu und verlinke ihn in den **Projekteinstellungen** unter:  
   - `Projekt > Projekteinstellungen > Compiler-Optionen > Suchpfade > Andere Units (-Fu)`


## 🧠 Über CAI Neural API

Dieses Projekt nutzt die CAI Neural API von João Paulo Schwarz Schuler.  
🔗 GitHub: [https://github.com/joaopauloschuler/neural-api](https://github.com/joaopauloschuler/neural-api)
und wurde mit Hilfe von [https://poe.com/CAI-NEURAL-API-FREE](https://poe.com/CAI-NEURAL-API-FREE) erstellt.

## ⚖️ Lizenz

Dieses Projekt steht unter der GNU GPL v3.
