# Hex Game Design Document

Version 0.1

## Vision

Hex Game ist ein 2.5D-Survival-Aufbauspiel in einer mittelalterlich-fantastischen Welt.

Der Spieler beginnt mit wenigen Ressourcen und entwickelt eine kleine Siedlung zu einer lebendigen Stadt. Dabei verbindet das Spiel Survival, Aufbau, Wirtschaft, Erkundung und Bevölkerungsmanagement.

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

Jedes Hex-Feld besitzt genau ein Hauptelement:

* Gelände
* Ressource
* Gebäude

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

