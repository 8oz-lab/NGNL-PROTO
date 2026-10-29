# NGNL Proto – Hinweise für Claude

Spiel-Prototyp in **Godot 4.7** (GDScript), inspiriert von *No Game No Life*. Der Nutzer schreibt
Deutsch, spielt in Godot 4.7 auf Windows und holt Änderungen über GitHub Desktop (Fetch/Pull von
`main`). Antworten, Code-Kommentare, Commit-Texte und Spieltexte auf **Deutsch**.

## Ablauf des Spiels

1. `scenes/intro/desktop.tscn` (Startszene): Win98-Desktop. Mail von „???“ → Ja → Band „ようこそ♪“
   → Schach gegen Bot → Sieg: Brett und Bildschirm reißen. Außerdem LoL-/CS-Clients mit Chats,
   Browser „NetSurfer 98“ mit Forum Threadit, Startmenü, Ordner/Textdateien (`user://desktop.json`).
2. `break_sequence.tscn`: Ich-Perspektive, Röhrenmonitor zerspringt, Strudel zieht hinein.
3. `fall_sequence.tscn`: Sturz über Disboard (Landschaft, Meer, Riesen-Schachfiguren, Schwebeinseln,
   Drachen, Hauptstadt), Teto fliegt mit und spricht die Zehn Gebote (japanisch, deutsche Untertitel).
4. `scenes/main.tscn` → `scripts/world.gd`: Grundstück in Elkia (Sora/Shiro, WASD, Shift, Leertaste
   springen, Q wechseln, E interagieren), Tripo-Häuser, Burg, Stadtmauer, Bäume, gleicher Himmel.
   Nach jedem Sturz startet `scripts/tutorial.gd` (Tetos Steuerungs-Training, F1 startet/überspringt).

Autoloads: `GameState` (Münzen, Parzellen, Tasten, `user://save.json`), `Flow` (Szenenwechsel,
Klänge, Schriften, Entwickler-Argumente). Aufbau-Tabelle steht im README.

## Testen in der Cloud-Session

Der SessionStart-Hook installiert Godot 4.7 als `godot` und importiert das Projekt.

- **Skriptfehler prüfen** (kompiliert alles mit Autoloads; `--check-only` taugt nicht, kennt `Flow` nicht):
  `for s in desktop break fall world; do godot --headless --path . --quit-after 120 -- --start=$s 2>&1 | grep "SCRIPT ERROR"; done`
- **Tests:** `godot --headless --path . --script res://tests/test_chess.gd` (Perft),
  `godot --headless --path . -- --start=world --tutorial --probe=res://tests/tutorial_bot.gd` (Training komplett),
  `xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/desktop_test.tscn` (Desktop-Klicks; verändert `desktop.json`).
- **Testbilder** (llvmpipe, ca. 2 Bilder/s – lange Läufe im Hintergrund starten):
  `xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path . --resolution 1600x900 -- --start=fall --shots=/pfad/bild.png --at=5,40`
- Entwickler-Argumente: `--start=desktop|break|fall|world`, `--shots=` + `--at=`, `--probe=res://…gd`,
  Desktop: `--demo=mail|welcome|chess|win|start`, `--open=lol,cs,web,i1`, `--url=/t/blank`;
  Welt: `--capture=bild.png [--walk]`, `--cam=x,y,z,zx,zy,zz`, `--yaw=`, `--zoom=`, `--tutorial`, `--tutorial-step=sprinten`.
- Im Spiel: Browser-Adresse `skip:secret` → Monitor-Szene, `skip:welt` → Grundstück; F8 überspringt.
- Harmlos im Headless-Modus: `Parameter "m" is null`, `"material" is null`, Ressourcen-Lecks beim Beenden.

## Assets erzeugen

- **Tripo** (3D-Modelle): `python3 tools/tripo_models.py SET [name …]` mit SET = houses, bauten,
  tutorial, figuren, himmel. Der Schlüssel kommt als Network secret der Umgebung für `api.tripo3d.ai`
  (oder `TRIPO_API_KEY`). Kontostand: `curl -sS https://api.tripo3d.ai/v2/openapi/user/balance`.
  Ein Modell ≈ 20 Credits; dem Nutzer Kosten und Restguthaben nennen.
- Tripo-Modelle schauen oft in **+X** statt +Z (Teto, Drache) → im Code um 90° drehen; Größe immer
  über die AABB anpassen, Look mit `Toon.apply_to`. Vorschau: `res://tests/tree_preview.tscn -- --folder=houses`.
- GLB mit Knochen als „matrix“ (Skelett fällt zusammen): `tools/fix_gltf_matrix.py`.
- Bäume: `tools/make_trees.gd` (mit Grafik, nicht headless). Charaktere laufen per BoneMap
  (`assets/models/characters/mixamo_bone_map.tres`) über das Humanoid-Profil.
- **Teto-Stimme:** `tools/make_teto_voice.py` (Kokoro-TTS, Einrichtung im Skript). Japanische Texte
  stehen in `LINES` von `fall_sequence.gd` bzw. `tutorial.gd`. Danach mit einer Spracherkennung
  (sherpa-onnx Whisper) prüfen, ob die Sätze verständlich sind. Teto ist eine eigene, angelehnte Figur
  und Stimme – keine Kopie der Anime-Figur oder der Sprecherin.

## Stolperfallen

- `set_anchors_and_offsets_preset` statt `set_anchors_preset` (sonst Größe 0).
- Sky-Shader: `TIME` nicht in Hilfsfunktionen verwenden (OpenGL-Fehler), als Parameter übergeben.
- Kollisionen nie nur unsichtbar machen: Shape deaktivieren oder Knoten entfernen.
- Nicht mit Größe 0 skalieren und dann `look_at` (det == 0); Modelle erst ausmessen, dann verkleinern.
- Godot 4.7 schreibt `.uid`-Dateien und neue `.import`-Felder: mitcommitten; bei Konflikten in
  `.uid` die Version aus `main` (vom Nutzer) behalten.
- Erfundene Namen für Profis/Promis in Spieltexten, keine echten Personen.

## Arbeitsweise

- Änderungen mit Testbildern prüfen und dem Nutzer zeigen (SendUserFile); ehrlich sagen, was nicht getestet ist.
- Der Nutzer möchte die Ergebnisse in `main`: committen, `git fetch origin main`, mergen, `git push origin main`.
  Mehrere Chats parallel: eigener Branch pro Thema, danach in `main` übernehmen.
- Am Ende kurz auf Deutsch sagen, was neu ist und wie er es holt (Fetch origin → Pull origin, F5).
