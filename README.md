# NGNL Proto

Ein Spiel-Prototyp in **Godot 4.3**, inspiriert von *No Game No Life*: Sora und Shiro starten mit einem kleinen Grundstück am Stadtrand von Elkia und 100 Münzen. Münzen und Parzellen sind zugleich Besitz und Spieleinsatz.

## Starten

1. Repository auf den PC holen, z. B. mit **GitHub Desktop** → *Clone repository* → `8oz-lab/NGNL-PROTO`.
2. **Godot 4.3** (oder neuer 4.x) öffnen → **Importieren** → die Datei `project.godot` in diesem Ordner auswählen.
3. Beim ersten Öffnen importiert Godot die Modelle (dauert einen Moment).
4. **F5** oder der Play-Knopf oben rechts startet das Spiel.

## Steuerung

| Taste | Aktion |
| --- | --- |
| W A S D / Pfeiltasten | laufen (relativ zur Kamera) |
| Shift | sprinten |
| Maus ziehen | Kamera drehen |
| Mausrad | zoomen |
| Q | zwischen Sora und Shiro wechseln |
| E | interagieren (Hütte, Schild, Parzelle), Dialog weiter |

## Aufbau

| Pfad | Inhalt |
| --- | --- |
| `scenes/main.tscn` | Startszene, baut über `world.gd` das Grundstück auf |
| `scripts/world.gd` | Gelände, Parzellen, Hütte, Nachbarschaft, Steuerung, Interaktionen |
| `scripts/hero.gd` | Sora/Shiro: Modell, Animationen (Stehen, Gehen, Rennen), Bewegung |
| `scripts/camera_rig.gd` | Kamera hinter der Figur mit Kollision (SpringArm) |
| `scripts/hud.gd` | Anzeige: Münzen, Parzellen, aktive Figur, Parzellen-Info, Dialoge |
| `scripts/game_state.gd` | Autoload `GameState`: Münzen, Parzellen, Speichern, Tastenbelegung |
| `scripts/toon.gd` | Toon-Materialien mit Umrisslinie |
| `assets/shaders/` | Toon-Shader (3 Lichtstufen) und Umriss-Shader |
| `assets/models/` | GLB-Modelle aus Tripo (Figuren mit Mixamo-Rig) |

Der Spielstand wird beim Betreten der Hütte gespeichert (`user://save.json`).

## Automatischer Test (für Entwicklung)

```
godot --path . -- --capture=bild.png --walk
```

startet das Spiel, läuft ein Stück nach vorne, speichert drei Bilder und beendet sich.
