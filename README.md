# NGNL Proto

Ein Spiel-Prototyp in **Godot 4.3**, inspiriert von *No Game No Life*: Sora und Shiro starten mit einem kleinen Grundstück am Stadtrand von Elkia und 100 Münzen. Münzen und Parzellen sind zugleich Besitz und Spieleinsatz.

## Starten

1. Repository auf den PC holen, z. B. mit **GitHub Desktop** → *Clone repository* → `8oz-lab/NGNL-PROTO`.
2. **Godot 4.3** (oder neuer 4.x) öffnen → **Importieren** → die Datei `project.godot` in diesem Ordner auswählen.
3. Beim ersten Öffnen importiert Godot die Modelle (dauert einen Moment).
4. **F5** oder der Play-Knopf oben rechts startet das Spiel.

## Der Anfang

Das Spiel beginnt wie im Anime auf einem alten Windows-Desktop:

1. Im Posteingang landet eine Mail von **???**: „Challenge für 「　」“. Antwort: **Ja** (oder zweimal Nein).
2. Der Schriftzug **ようこそ♪** läuft über den Bildschirm, danach öffnet sich **Schach 98**. Figuren anklicken oder ziehen.
3. Nach dem Sieg bricht das Brett, dann der Bildschirm. Aus der Ich-Perspektive seht ihr den Röhrenmonitor im Zimmer: Er flackert, sprüht Funken, das Glas zerspringt und ein Strudel zieht euch hinein.
4. Sturz durch den Himmel von Disboard (Meer, Küsten, Berge, riesige Schachfiguren, Schwebeinseln, Drachen, unten die Hauptstadt), Teto fliegt mit und erklärt die Zehn Gebote auf Japanisch mit deutschen Untertiteln (Klick/Leertaste: weiter, **V**: Stimme Teto / Brabbeln / aus).
5. Landung auf dem Grundstück. Beim ersten Mal folgt **Tetos Steuerungs-Training**: umsehen, zoomen, laufen, über Hürden springen, goldene Figuren sammeln, durch Ringe sprinten (auf Zeit), Figur wechseln, Schatztruhe öffnen (+50 Münzen).

Auf dem Desktop gibt es außerdem:

- **Liga der Legenden** (Rang 1, Challenger) und **Counter-Spike GO** (Global Elite), jeweils mit Chats von erfundenen Profis
- **Internet** (NetSurfer 98) mit dem Forum *Threadit*: Communities, Beiträge, Kommentare, Abstimmen
- **Startmenü**, Fenster lassen sich verschieben, an Rand und Ecke in der Größe ziehen und minimieren
- Symbole verschieben (auch mehrere per Rahmen), Rechtsklick → **Neuer Ordner / Neues Textdokument**, Umbenennen (F2), Löschen (Entf oder auf den Papierkorb ziehen), in Ordner ziehen. Ordner und Texte werden gespeichert (`user://desktop.json`).

**F8** bzw. **Esc** (in den 3D-Szenen) überspringt das Intro. Zum Testen im Browser als Adresse eingeben: `skip:secret` springt dorthin, wo der Monitor zerbricht und ihr in den PC gezogen werdet (danach Sturz und Landung), `skip:welt` direkt aufs Grundstück.

## Steuerung

| Taste | Aktion |
| --- | --- |
| W A S D / Pfeiltasten | laufen (relativ zur Kamera) |
| Leertaste | springen |
| Shift | sprinten |
| Maus ziehen | Kamera drehen |
| Mausrad | zoomen |
| Q | zwischen Sora und Shiro wechseln |
| E | interagieren (Hütte, Schild, Parzelle), Dialog weiter |
| F1 | Steuerungs-Training starten oder überspringen |

## Aufbau

| Pfad | Inhalt |
| --- | --- |
| `scenes/intro/` | Intro: `desktop.tscn` (Startszene), `break_sequence.tscn`, `fall_sequence.tscn` |
| `scripts/intro/` | Desktop, Win98-Bausteine, Schach-Engine und Brett, Monitor-Zerstörung, Sturz mit Teto |
| `scripts/intro/launchers.gd`, `net_surfer.gd`, `threadit.gd` | Spiele-Clients mit Chats, Browser und Forum |
| `scripts/intro/icon_view.gd`, `desk_fs.gd` | Desktop-Symbole, Ordner und Textdateien |
| `scripts/flow.gd` | Autoload `Flow`: Szenenwechsel mit Blende, Klänge, Schriften |
| `scenes/main.tscn` | Grundstück, baut über `world.gd` die Welt auf |
| `scripts/world.gd` | Gelände, Parzellen, Hütte, Nachbarschaft, Steuerung, Interaktionen |
| `scripts/tutorial.gd` | Steuerungs-Training mit Teto (Aufgaben, Tasten-Anzeige, Wegsteine, Hürden, Ringe, Truhe); Test: `tests/tutorial_bot.gd` |
| `scripts/hero.gd` | Sora/Shiro: Modell, Animationen (Stehen, Gehen, Rennen), Bewegung |
| `scripts/camera_rig.gd` | Kamera hinter der Figur mit Kollision (SpringArm) |
| `scripts/hud.gd` | Anzeige: Münzen, Parzellen, aktive Figur, Parzellen-Info, Dialoge |
| `scripts/game_state.gd` | Autoload `GameState`: Münzen, Parzellen, Speichern, Tastenbelegung |
| `scripts/toon.gd` | Toon-Materialien mit Umrisslinie |
| `assets/shaders/` | Toon-Shader (3 Lichtstufen) und Umriss-Shader |
| `assets/models/` | GLB-Modelle aus Tripo. Figuren: `sora_neu.glb`, `shiro_neu.glb`; fehlende Animationen kommen per Humanoid-Retargeting (`mixamo_bone_map.tres`) aus `sora.glb`/`shiro.glb` |
| `assets/audio/teto/` | Tetos gesprochene Zeilen, erzeugt mit `tools/make_teto_voice.py` (Kokoro-TTS, Apache-2.0; Anleitung im Skript) |
| `assets/models/trees/` | Baum-Modelle im Toon-Stil (Laubbaum, großer Laubbaum, Kirschbaum, Tanne, Birke, Busch), erzeugt mit `tools/make_trees.gd`; Vorschau: `tests/tree_preview.tscn` |
| `assets/models/houses/` | Haus-Modelle (GLB) – jede Datei erscheint automatisch an der Straße; erzeugen mit `tools/tripo_models.py houses` (Tripo-API: Schlüssel als Network secret für api.tripo3d.ai oder als `TRIPO_API_KEY`) |
| `assets/models/buildings/` | Burg, Stadtmauer, Mauerturm, Stadttor (Tripo, `tools/tripo_models.py bauten`); ohne Dateien baut das Spiel einfache Ersatzformen |
| `assets/shaders/sky.gdshader`, `scripts/sky_look.gd` | Himmel von Disboard (Sturz und Spiel): Verlauf, Haufen- und Federwolken, Sternenschleier; `distant.gdshader` für die riesigen Schachfiguren am Horizont |
| `assets/shaders/terrain*.gdshader`, `ocean.gdshader` | Landschaft und Meer unter dem Sturz |
| `assets/models/sky/` | Hauptstadt, Schwebeinsel, Drache (Tripo, `tools/tripo_models.py himmel`) |
| `tools/fix_gltf_matrix.py` | Repariert GLB-Dateien, deren Knochen als Matrix gespeichert sind (sonst fällt das Skelett in Godot zusammen) |

Der Spielstand wird beim Betreten der Hütte gespeichert (`user://save.json`).

## Automatischer Test (für Entwicklung)

```
godot --path . -- --start=world --capture=bild.png --walk
```

startet direkt auf dem Grundstück, läuft ein Stück nach vorne, speichert drei Bilder und beendet sich.

```
godot --path . -- --start=fall --shots=bild.png --at=3,10
godot --path . -- --demo=win --shots=bild.png --at=2,5,9
```

springt in einen Teil des Intros (auf dem Grundstück zusätzlich `--cam=x,y,z,zx,zy,zz` für eine freie Kamera, `--yaw=` und `--zoom=`) (`desktop`, `break`, `fall`, `world`) bzw. spielt am Desktop direkt den Mattzug (`--demo=mail|welcome|chess|win`) und speichert Bilder zu den angegebenen Sekunden.

```
godot --headless --script res://tests/test_chess.gd
```

prüft die Schach-Engine (Perft-Zählungen) und misst die Bedenkzeit des Bots.

```
godot --path . res://tests/desktop_test.tscn
```

klickt sich durch den Desktop (Datei anlegen, umbenennen, in Ordner und Papierkorb ziehen, Rahmenauswahl, Fenster ziehen und minimieren). Achtung: verändert die eigene `desktop.json`.

Am Desktop öffnet `-- --open=lol,cs,web` Programme direkt, `--url=/t/blank` springt im Browser auf eine Seite, `--demo=start` zeigt das Startmenü.
