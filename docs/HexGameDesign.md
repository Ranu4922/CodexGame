# Hex Game Design Document

Version 3.0

## Vision

Hex Game ist ein 2.5D/Low-Poly-3D Aufbauspiel mit Erkundungselementen in einer mittelalterlich-fantastischen Welt.

Der Spieler beginnt mit wenigen Ressourcen und entwickelt eine kleine Siedlung zu einer lebendigen Stadt. Dabei verbindet das Spiel Survival, Aufbau, Wirtschaft, Erkundung und Bevölkerungsmanagement.

---

## Hintergrundgeschichte

### Der Fall

Vor vielen Jahrzehnten ereignete sich eine Katastrophe, die heute nur noch als "Der Fall" bekannt ist.

Niemand weiß mehr genau, was geschah.

Die großen Reiche brachen zusammen, Städte wurden zerstört und die Handelswege verschwanden. Viele Menschen starben, andere flohen in alle Richtungen.

Gleichzeitig tauchten gefährliche Kreaturen auf und große Teile der Wildnis wurden unbewohnbar.

Die wenigen Überlebenden verloren den Kontakt zueinander und gründeten kleine Lager, Dörfer und Siedlungen.

---

### Spielstart

Der Spieler führt eine kleine Gruppe von Überlebenden an.

Zu Beginn bestehen diese aus dem Spielercharakter und wenigen Bewohnern.

Mit begrenzten Vorräten sucht die Gruppe nach einem Ort, an dem eine neue Heimat entstehen kann.

Dort beginnt der Aufbau der ersten Siedlung.

### Langfristiges Startdesign

Das Dorfzentrum wird später nicht automatisch fest gesetzt.

Der Spieler startet mit wenigen Überlebenden und Startressourcen.

Der Spieler erkundet die Umgebung.

Der Spieler wählt selbst den Standort der ersten Siedlung.

Erst wenn das Dorfzentrum platziert wurde, entsteht das Siedlungsgebiet.

Für den aktuellen MVP darf das Dorfzentrum weiterhin automatisch gesetzt werden.

---

## Spielercharakter

Der Spieler steuert einen eigenen Charakter.

Der Charakter ist der Anführer der Überlebendengruppe und bleibt während des gesamten Spiels relevant.

### Aufgaben des Spielers

Der Spieler kann:

* Die Welt erkunden
* Neue Bewohner finden und rekrutieren
* Ruinen untersuchen
* Monster bekämpfen
* Mit anderen Siedlungen handeln
* Neue Siedlungen gründen
* Außenposten errichten

---

## Siedlungsverwaltung

Siedlungen werden über das jeweilige Dorfzentrum verwaltet.

Der Spieler muss sich zum Dorfzentrum einer Siedlung begeben und mit diesem interagieren.

### Dorfverwaltung

Der Spieler baut nicht jederzeit frei über ein globales Baumenü.

Der Spieler muss später mit dem Dorfzentrum interagieren.

Dadurch öffnet sich die Dorfverwaltungsansicht.

Dort werden Ressourcen, Bewohner, Gebäude, Upgrades und Bauplanung verwaltet.

Die normale Weltansicht bleibt für Bewegung, Erkundung, Kampf und Interaktion.

### Dorfzentrum

Das Dorfzentrum dient als Verwaltungsgebäude der Siedlung.

Beim Interagieren öffnet sich die Verwaltungsoberfläche.

Angezeigt werden unter anderem:

* Bewohnerzahl
* Freie Bewohner
* Nahrung
* Ressourcen
* Lagerbestand
* Verteidigung
* Gebäudeübersicht

### Bauen

Neue Bezirke und Gebäude werden über das Dorfzentrum geplant.

Der Spieler wählt dort die gewünschte Bauoption aus.

Anschließend wechselt das Spiel in eine strategische Planungsansicht der aktuellen Siedlung.

Dort können neue Bezirke platziert und bestehende Bezirke verbessert werden.

### Mehrere Siedlungen

Jede Siedlung besitzt ihr eigenes Dorfzentrum.

Um eine Siedlung zu verwalten, muss der Spieler das entsprechende Dorfzentrum aufsuchen.

Dadurch fühlen sich Siedlungen als echte Orte innerhalb der Spielwelt an.

---

Langfristiges Design:
Das Dorfzentrum wird nicht automatisch dauerhaft gesetzt.
Der Spieler wählt den Standort der ersten Siedlung selbst.

Ablauf:
- Spieler startet mit wenigen Überlebenden und Startressourcen.
- Spieler erkundet die Umgebung.
- Spieler platziert das erste Dorfzentrum an einem geeigneten Ort.
- Erst danach entsteht das Siedlungsgebiet.
- Bauen von Wohnhäusern und Produktionsgebäuden ist an dieses Dorfzentrum gebunden.

Für den aktuellen MVP darf das Dorfzentrum weiterhin automatisch gesetzt werden.
Später wird daraus eine manuelle Platzierung.

---

### Ziel

Der Spieler bleibt aktiv Teil der Welt und verwaltet seine Siedlungen nicht über ein globales Menü.

Das Dorfzentrum bildet das Herz jeder Siedlung.

Der Spieler entwickelt sich vom Anführer einer kleinen Gruppe von Überlebenden zum Herrscher eines Netzwerks aus Siedlungen, Handelsrouten und Außenposten.

-

### Langfristiges Ziel

Das Ziel des Spielers ist nicht nur das Überleben.

Aus einer kleinen Gruppe von Überlebenden soll erneut eine blühende Zivilisation entstehen.

Durch Erkundung, Besiedlung, Handel und Verteidigung wird die verlorene Welt Schritt für Schritt zurückerobert.

---

### Aufgaben der Bewohner

Bewohner übernehmen die alltägliche Arbeit innerhalb der Siedlungen.

Dazu gehören:

* Holzfällerei
* Bergbau
* Landwirtschaft
* Jagd
* Produktion

Der Spieler muss diese Arbeiten nicht selbst ausführen.

---

### Nahrung

Es existieren zwei getrennte Nahrungssysteme.

#### Spielernahrung

Der Spieler benötigt Nahrung für längere Expeditionen und Reisen.

#### Siedlungsnahrung

Bewohner verbrauchen Nahrung aus dem Lager ihrer Siedlung.

Nahrungsmangel kann zu Unzufriedenheit, verringerter Produktivität, Abwanderung oder langfristig zum Tod von Bewohnern führen.

---

## Welt

* Prozedural generierte Welt
* Hex-Raster als Grundlage
* Freie Erkundung in alle Richtungen
* Unterschiedliche Biome
* Ressourcen abhängig vom Biom

### Hex-Felder

Hex-Felder repräsentieren Gebiete und keine einzelnen Objekte.

Beispiele:

* Waldgebiet
* Wohngebiet
* Farmgebiet
* Erzgebiet
* Stadtblock
* Handelsviertel

Ein Hex-Feld kann mehrere Objekte enthalten:

* Häuser
* Bäume
* Wege
* NPCs
* Monster
* Dekorationen

Hex-Felder dienen hauptsächlich der Verwaltung, dem Bau und strategischen Entscheidungen.

Der Spieler bewegt sich frei innerhalb der Welt und ist nicht auf die Bewegung von Hex zu Hex beschränkt.

---

## Monsternester

Monster entstehen aus Monsternestern, die in der Welt verteilt sind.

Monsternester stellen eine dauerhafte Bedrohung dar und beeinflussen die Sicherheit der umliegenden Region.

---

### Bedrohungsgebiet

Jedes Nest besitzt ein Einflussgebiet.

Siedlungen, Außenposten, Straßen und Handelsrouten innerhalb dieses Gebietes können häufiger von Monstern angegriffen werden.

Je näher eine Siedlung an einem aktiven Nest liegt, desto höher ist das Risiko von Angriffen.

Dadurch entsteht ein strategischer Konflikt zwischen:

* sicheren Standorten
* ressourcenreichen Standorten

---

### Nest-Stufen

Monsternester besitzen unterschiedliche Entwicklungsstufen.

#### Stufe 1 – Versteck

* Kleine Monstergruppen
* Geringes Einflussgebiet
* Frühes Spiel

#### Stufe 2 – Lager

* Größere Monstergruppen
* Angriffe auf Händler und Außenposten möglich

#### Stufe 3 – Brutstätte

* Regelmäßige Angriffe auf Siedlungen
* Großes Einflussgebiet

#### Stufe 4 – Festung

* Sehr starke Monstergruppen
* Monsterpatrouillen möglich

#### Stufe 5 – Ursprungsnest

* Endgame-Bedrohung
* Erzeugt besonders starke Monsterwellen
* Stellt eine regionale Großgefahr dar

---

### Entwicklung

Monsternester entwickeln sich mit der Zeit weiter.

Werden sie ignoriert, können sie aufsteigen und gefährlicher werden.

Frühzeitiges Eingreifen kann spätere Probleme verhindern.

---

### Regionale Unterschiede

Nicht alle Regionen besitzen gleich starke Nester.

Gefährliche Gebiete können bereits zu Spielbeginn starke Nester enthalten.

Dadurch entstehen natürliche Hochrisikogebiete, die oft wertvolle Ressourcen enthalten.

---

### Monsterwellen

Die allgemeine Monsteraktivität der Welt wird teilweise durch aktive Monsternester beeinflusst.

Je mehr starke Nester existieren, desto größer ist die Wahrscheinlichkeit für starke Monsterwellen und koordinierte Angriffe.

Das Zerstören von Nestern erhöht langfristig die Sicherheit der Welt.

---

### Monster

Seit dem Fall ist die Wildnis gefährlich.

In der Welt existieren verschiedene Monster und Kreaturen, die Menschen, Händler, Außenposten und Siedlungen bedrohen können.

Große Teile der Welt gelten noch immer als ungesichert.

---

## Grafikstil

Das Spiel verwendet einen stilisierten Low-Poly-3D-Look.

Die Welt basiert weiterhin auf Hex-Feldern.

Die Kamera bleibt in einer schrägen Vogelperspektive.

Gebäude, Bewohner, Monster und Ressourcen werden als einfache Low-Poly-3D-Modelle dargestellt.

Der Fokus liegt auf Übersichtlichkeit, guter Performance und einer lebendigen Welt.

---

## Kern-Gameplay

Gameplay-Schleife:

1. Ressourcen sammeln
2. Gebäude errichten
3. Bewohner versorgen
4. Produktion ausbauen
5. Neue Gebiete erkunden
6. Handel betreiben
7. Außenposten gründen
8. Weitere Siedlungen aufbauen

---

## Welt

* Prozedural generierte Welt
* Hex-Raster als Grundlage
* Freie Erkundung in alle Richtungen
* Unterschiedliche Biome
* Ressourcen abhängig vom Biom

Ein Hex-Feld steht primär für ein Gebiet oder einen Bezirk.

Visuell kann ein Hex mehrere Objekte enthalten, zum Beispiel Häuser, Bäume, Wege oder Dekorationen.

Für die Spielverwaltung besitzt ein Hex weiterhin einen primären Gebietstyp oder Gebäudetyp.

---

## Spieler

Der Spieler bewegt sich frei durch die Welt.

Der Spieler bleibt während des gesamten Spiels relevant durch:

* Erkundung
* Handel
* Diplomatie
* Rekrutierung
* Expansion

Der Spieler ist nicht nur Verwalter, sondern auch aktiver Charakter.

---

## Bewohner

Bewohner besitzen:

* Individuelle Fähigkeiten
* Bedürfnisse
* Berufe

Beispiele:

* Zimmermann
* Bauer
* Händler
* Holzfäller

Bedürfnisse:

* Wohnraum
* Nahrung
* Bezahlung

Unzufriedene Bewohner können die Siedlung verlassen.

---

## Wohngebiete

Jede Siedlung besitzt genau ein Dorfzentrum oder Stadtzentrum.

Wohnhäuser und Wohngebiete müssen direkt angrenzen an:

* das Dorfzentrum
* oder ein bestehendes Wohnhaus oder Wohngebiet derselben Siedlung

Dadurch entstehen zusammenhängende Wohnviertel.

Isolierte Wohnhäuser sind nicht erlaubt.

Neue entfernte Wohngebiete sind erst möglich, wenn dort später ein Außenposten oder neues Stadtzentrum gegründet wird.

Produktionsgebäude wie Holzfällerhütte, Steinmine, Bauernhof, Beerensammler und Lagerhaus folgen weiterhin ihren eigenen Platzierungsregeln.

Diese Gebäude müssen nicht an Wohnhäuser angrenzen.

---

## Ressourcengebäude

Ressourcengebäude nutzen passende Ressourcen-Hexfelder in ihrem Arbeitsradius.

Beispiele:

* Holzfällerhütte → Wald-Hexe
* Mine → Stein- oder Erz-Hexe
* Jagdhütte → Wildnis-Hexe

### Automatische Zuweisung

Beim Bau eines Ressourcengebäudes werden geeignete Ressourcen-Hexfelder im Arbeitsradius automatisch zugewiesen.

Das Gebäude wählt standardmäßig die besten verfügbaren Felder.

### Reservierung

Ein Ressourcen-Hexfeld kann immer nur einem Ressourcengebäude gleichzeitig zugewiesen sein.

Dadurch kann dieselbe Ressource nicht mehrfach von verschiedenen Gebäuden genutzt werden.

### Manuelle Optimierung

Der Spieler kann die automatisch gewählten Ressourcen-Hexfelder später manuell anpassen.

Dadurch können Produktionsketten optimiert werden, ohne dass Mikromanagement erforderlich wird.

### Ziel

Das System soll:

* einfach zu verstehen sein
* Mikromanagement vermeiden
* strategische Entscheidungen ermöglichen
* unbegrenzte Produktionsskalierung verhindern

---

## Gebäude

### Holzfällerhütte

Produziert Holz.

Aktuell bekannte Werte:

* Benötigt angrenzende Wald-Hexe
* Produktion abhängig von Wald in Reichweite

---

## Ressourcen

Geplant:

* Holz
* Stein
* Nahrung
* Eisen
* Kohle
* Zucker

---

## Handel

Siedlungen können Ressourcen austauschen.

Beispiel:

* Siedlung A besitzt Eisen
* Siedlung B besitzt Zucker

Durch Handelsrouten profitieren beide Siedlungen.

---

## Außenposten

Außenposten dienen dazu:

* Ressourcenquellen zu sichern
* Neue Gebiete zu erschließen
* Handelsnetzwerke auszubauen

---

## Langfristiges Ziel

Von einer kleinen Ansiedlung zu einem Netzwerk mehrerer Städte wachsen.

Es gibt kein festes Spielende.

Der Fortschritt wird durch Expansion, Wohlstand und Einfluss bestimmt.

---

# In Planung

Noch nicht final entschieden.

* Arbeitersystem
* Kampfsystem
* Jahreszeiten
* Forschungssystem
* Diplomatie
* Fraktionen

Bedrohungssystem

- Wilde Tiere
- Monster
- Banditen

Dörfer und Handelsrouten können angegriffen werden.

Neue und schwache Dörfer benötigen Schutz.

Der Spieler kann Verteidigungen, Wachen und Garnisonen errichten.
---

# Ideenparkplatz

Ideen, die später geprüft werden.

* Schiffe
* Burgen
* Magiesystem
* Große Weltwunder
* Mehrstufige Handelsgesellschaften

---

## Siedlungslager

Jede Siedlung besitzt ein eigenes Lager.

Produzierte Ressourcen werden automatisch im Lager der jeweiligen Siedlung gespeichert.

Es gibt kein globales Lager des Spielers.

Jede Siedlung verwaltet ihren eigenen Bestand an Rohstoffen, Nahrung, Waren und Gold.

### Handelsrouten

Der Spieler erstellt Handelsrouten zwischen Siedlungen.

Handelsrouten können einmalige Lieferungen oder Daueraufträge sein.

Beispiele:

* 20 Eisen pro Tag von Bergdorf zur Hauptstadt
* 50 Fisch pro Woche vom Küstendorf zum Bergdorf
* 100 Gold pro Woche von der Hauptstadt zu einem Außenposten

Der Spieler entscheidet:

* Welche Ressourcen transportiert werden
* In welcher Menge sie transportiert werden
* Wie häufig Lieferungen stattfinden

NPCs führen die Transporte anschließend automatisch aus.

### Spielerinventar

Das Inventar des Spielers ist von den Siedlungslagern getrennt.

Dort werden persönliche Gegenstände gelagert, beispielsweise:

* Werkzeuge
* Waffen
* Baumaterialien
* Questgegenstände

### Imperiumsübersicht

Zusätzlich gibt es eine Übersicht über den Gesamtbestand aller Siedlungen.

Diese Übersicht dient nur zur Information.

Intern bleiben alle Lager voneinander getrennt.

---

## Changelog

### Version 0.2

* Eigenständige Siedlungslager eingeführt
* Keine globale Ressourcenlagerung
* Handelsrouten und Daueraufträge festgelegt
* Imperiumsübersicht als Gesamtanzeige geplant

### Version 0.3

* Hintergrundgeschichte "Der Fall" hinzugefügt
* Spieler startet als Anführer einer Überlebendengruppe
* Überlebende, Dörfer und Ruinen in der Welt festgelegt
* Monster als Bedrohung der Wildnis übernommen
* Langfristiges Ziel: Wiederaufbau der Zivilisation

### Version 0.5

* Monsternester eingeführt
* Bedrohungsgebiete für Nester festgelegt
* 5 Nest-Stufen definiert
* Nester entwickeln sich mit der Zeit weiter
* Regionale Unterschiede bei Nest-Stärken eingeführt
* Monsternester beeinflussen Monsterwellen
* Expansion in gefährliche Regionen als Risiko-/Belohnungssystem festgelegt



