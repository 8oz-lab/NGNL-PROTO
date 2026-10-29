extends Control
## Der Anfang: alter Windows-Desktop, eine Mail von „???“, Willkommens-Schriftzug, Schach, Bildschirm bricht.

const MAILS := [
	["Ranking-Server", "Saisonwertung: 「　」 weiterhin auf Platz 1", "Heute 03:12", ["Glückwunsch!", "Euer Konto „「　」“ belegt in 284 Spielen weiterhin Platz 1 der Weltrangliste.", "Niederlagen in dieser Saison: 0"]],
	["xX_Herausforderer_Xx", "WER SEID IHR?? Revanche!!!", "Heute 02:47", ["Das war doch Cheaten. Niemand spielt so.", "Morgen 20 Uhr. Gleiche Regeln. Diesmal gewinne ich.", "…bitte."]],
	["GM_Eisenhart (verifiziert)", "Partie Nr. 48: Ich gebe auf. Schon wieder.", "Heute 01:30", ["Ich bin seit 22 Jahren Großmeister.", "Ihr habt mich in 19 Zügen mattgesetzt und nebenbei noch zwei andere Partien gespielt.", "Darf ich fragen, wie viele ihr eigentlich seid?"]],
	["Spiele-Support", "Euer Konto wurde 312-mal gemeldet", "Heute 00:05", ["Wir haben die Meldungen geprüft.", "Es wurde kein Regelverstoß festgestellt. Eure Gegner sind einfach schlechter.", "Euer Support-Team"]],
	["Forum · Urban Legends", "Neuer Beitrag: „Wer steckt hinter 「　」?“", "Gestern 23:58", ["Theorie 1: Eine KI aus einem Forschungslabor.", "Theorie 2: Zwanzig Profis, die sich abwechseln.", "Theorie 3: Sie schlafen nie."]],
	["World Gamer Cup", "Finale: Eure Absage Nr. 7", "Gestern 21:15", ["Ihr habt die Einladung zum Weltfinale erneut abgelehnt.", "Euer Grund: „Zu weit weg.“"]],
	["Esports-Agentur Nova", "Sponsoring: 10 Mio. für ein einziges Foto", "Gestern 18:40", ["Wir bieten euch zehn Millionen.", "Einzige Bedingung: ein Foto von euch. Gern auch unscharf."]],
	["Anonym", "Ich weiß, wer ihr seid", "Sa 03:33", ["Ihr seid zu zweit. Einer liest die Gegner, die andere rechnet alles durch.", "Allein seid ihr nur gut. Zusammen unbesiegbar."]],
]
const TET_MAIL := ["???", "Challenge für 「　」", "Gerade eben"]
const TET_TEXT := [
	"Hallo, ihr zwei.",
	"Ich habe eure Partien beobachtet. Wirklich beeindruckend. Deshalb habe ich eine Frage an euch.",
	"Habt ihr manchmal das Gefühl, in der falschen Welt geboren zu sein? In einer Welt ohne klare Regeln und ohne Ziel, in der euer Talent nichts zählt?",
	"Stellt euch eine Welt vor, in der allein Spiele alles entscheiden. Kein Krieg. Keine Gewalt. Nur das bessere Spiel.",
	"Würdet ihr in so einer Welt neu geboren werden wollen?",
]

var mails: Array = []
var selected := 1
var arrived := false

var mail_win: W98Window
var chess_win: W98Window
var mail_rows: VBoxContainer
var preview: VBoxContainer
var status_left: Label
var balloon: PanelContainer
var tray_env: Label
var clock: Label
var taskbar_row: HBoxContainer
var task_spacer: Control
var start_btn: W98Button
var start_menu: StartMenu
var fs := DeskFS.new()
var icons: IconView
var win_layer: Control
var tasks := {}          # Fenster -> Knopf in der Taskleiste
var apps := {}           # "web", "lol", "cs" -> Fenster
var file_wins := {}      # Ordner- oder Datei-id -> Fenster
var board: ChessBoard
var moves_label: Label
var chess_status: Label
var resign_btn: W98Button
var rematch_btn: W98Button
var crack_layer: CrackOverlay
var _no_count := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Win98.TEAL
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_icons()
	win_layer = Control.new()
	win_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_layer.offset_bottom = -38
	win_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(win_layer)
	_build_taskbar()
	_build_mail_window()
	_build_balloon()
	start_menu = StartMenu.new()
	start_menu.visible = false
	start_menu.chosen.connect(func(k):
		_toggle_start(false)
		_open_key(k))
	add_child(start_menu)
	fs.changed.connect(_on_fs_changed)
	# Röhrenmonitor: feine Scanlines und Vignette über allem
	var crt := ColorRect.new()
	crt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
void fragment() {
	float line = step(0.5, fract(FRAGCOORD.y / 3.0)) * 0.05;
	vec2 c = UV - 0.5;
	float vig = smoothstep(0.45, 0.85, length(c * vec2(1.0, 0.9)));
	COLOR = vec4(0.0, 0.0, 0.0, line + vig * 0.35);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	crt.material = mat
	add_child(crt)
	crack_layer = CrackOverlay.new()
	crack_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crack_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crack_layer)

	mails = MAILS.map(func(m): return {"from": m[0], "subj": m[1], "date": m[2], "body": m[3], "unread": false})
	for i in [0, 2, 4]:
		mails[i]["unread"] = true
	_render_rows()
	_show_mail(1)
	mail_win.visible = false
	get_tree().create_timer(1.2).timeout.connect(func(): status_left.text = "Nachrichten werden abgerufen …")
	get_tree().create_timer(2.6).timeout.connect(_deliver)
	# Entwicklerhilfe: `--demo=mail`, `--demo=chess` oder `--demo=win` springt direkt an eine Stelle
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--open="):
			for k in arg.trim_prefix("--open=").split(","):
				_open_key.call_deferred(k if k.contains(":") or k.substr(1).is_valid_int() else "sys:" + k)
		match arg:
			"--demo=mail":
				get_tree().create_timer(3.0).timeout.connect(_open_tet_mail)
			"--demo=start":
				_toggle_start.call_deferred(true)
			"--demo=welcome":
				_deliver.call_deferred()
				get_tree().create_timer(0.5).timeout.connect(_accept)
			"--demo=chess":
				_deliver.call_deferred()
				_open_chess.call_deferred()
			"--demo=win":
				_deliver.call_deferred()
				_open_chess.call_deferred()
				get_tree().create_timer(1.0).timeout.connect(func():
					board.reset("6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1")
					for m in board.engine.legal():
						if ChessEngine.m_from(m) == ChessEngine.sq(7, 0) and ChessEngine.m_to(m) == ChessEngine.sq(0, 0):
							board._play(m))


func _unhandled_input(event: InputEvent) -> void:
	# Entwickler-Abkürzung: F8 überspringt das Intro
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_F8:
		Flow.goto("world")


func _input(event: InputEvent) -> void:
	# Klick irgendwo: Startmenü schließen und das angeklickte Fenster nach vorne holen
	if event is InputEventMouseButton and event.pressed:
		var p: Vector2 = event.position
		if start_menu.visible and not start_menu.get_global_rect().has_point(p) and not start_btn.get_global_rect().has_point(p):
			_toggle_start(false)
		if p.y > size.y - 38:
			return
		var children := win_layer.get_children()
		for i in range(children.size() - 1, -1, -1):
			var w := children[i] as W98Window
			if w and w.visible and w.get_global_rect().has_point(p):
				if not w.active:
					_focus(w)
				return


func _process(_delta: float) -> void:
	_refresh_tasks()
	var t := Time.get_time_dict_from_system()
	clock.text = "%02d:%02d" % [t.hour, t.minute]
	if tray_env.visible:
		tray_env.modulate.a = 1.0 if int(Time.get_ticks_msec() / 500) % 2 == 0 else 0.25


# ------------------------------------------------------------------ Desktop

const SYSTEM_ICONS := [
	{"key": "sys:pc", "title": "Arbeitsplatz", "kind": "pc"},
	{"key": "sys:mail", "title": "Posteingang", "kind": "mail"},
	{"key": "sys:games", "title": "Spiele", "kind": "games"},
	{"key": "sys:lol", "title": "Liga der Legenden", "kind": "lol"},
	{"key": "sys:cs", "title": "Counter-Spike GO", "kind": "cs"},
	{"key": "sys:web", "title": "Internet", "kind": "web"},
	{"key": "sys:trash", "title": "Papierkorb", "kind": "trash"},
]


func _build_icons() -> void:
	icons = IconView.new()
	icons.fs = fs
	icons.system = SYSTEM_ICONS
	icons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icons.offset_bottom = -38
	icons.opened.connect(_open_key)
	add_child(icons)


## Öffnet ein Desktop-Symbol, einen Startmenü-Eintrag oder eine eigene Datei („i“ + id).
func _open_key(key: String) -> void:
	match key:
		"sys:mail", "mail":
			_open_mail()
		"sys:web", "web":
			_open_app("web")
		"sys:lol", "lol":
			_open_app("lol")
		"sys:cs", "cs":
			_open_app("cs")
		"sys:pc":
			_msg("Arbeitsplatz", "Laufwerk C: 3 TB Spielstände. Laufwerk D: noch mehr Spielstände. Freier Speicher: 0 Byte.")
		"sys:games", "games":
			_msg("Spiele", "Der Ordner enthält 1.247 Spiele. Status: alle durchgespielt, alle auf Platz 1.")
		"sys:trash":
			_msg("Papierkorb", ("%d gelöschte Objekte. Der Papierkorb hat sie schon verdaut. Verlorene Partien sind keine dabei." % fs.trashed) if fs.trashed else "Der Papierkorb ist leer. Verlorene Partien gibt es keine.")
		"help":
			_msg("Hilfe", "Hilfe? 「　」 braucht keine Hilfe.")
		"shutdown":
			_msg("Beenden", "Herunterfahren abgebrochen: Es gibt noch Gegner, die nicht verloren haben.")
		"newfolder":
			icons.create_item("folder")
		"newtext":
			icons.create_item("text")
		_:
			var id := key.trim_prefix("i")
			if fs.items.has(id):
				if fs.items[id]["type"] == "folder":
					_open_folder(id)
				else:
					_open_text(id)


func _msg(title: String, text: String) -> void:
	var w := W98Window.new()
	w.title = title
	w.resizable = false
	w.minimizable = false
	w.size = Vector2(400, 160)
	w.position = (win_layer.size - w.size) * 0.5
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	w.content.add_child(v)
	var l := Win98.label(text, 13)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(360, 0)
	v.add_child(l)
	var ok := Win98.button("OK")
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	ok.pressed.connect(w.queue_free)
	_register(w, false, false)
	_focus(w)
	Flow.play("blip", -8, 0.8)
	ok.grab_focus()


# ------------------------------------------------------------------ Fenster und Taskleiste

## Nimmt ein Fenster in die Verwaltung auf. persistent: Schließen versteckt es nur.
func _register(w: W98Window, persistent: bool, with_task := true) -> void:
	win_layer.add_child(w)
	w.closed.connect(func():
		_remove_task(w)
		if persistent:
			w.visible = false
		else:
			w.queue_free())
	w.minimized.connect(func(): w.visible = false)
	w.tree_exiting.connect(_remove_task.bind(w))
	if with_task:
		w.set_meta("task", true)


func _show_window(w: W98Window) -> void:
	w.visible = true
	if w.has_meta("task") and not tasks.has(w):
		var b := Win98.button("", 180)
		b.align_left = true
		b.custom_minimum_size = Vector2(180, 28)
		b.pressed.connect(func():
			if not w.visible:
				w.visible = true
				_focus(w)
			elif w.active:
				w.visible = false
			else:
				_focus(w))
		taskbar_row.add_child(b)
		taskbar_row.move_child(b, task_spacer.get_index())
		tasks[w] = b
	_focus(w)


func _remove_task(w: W98Window) -> void:
	if tasks.has(w):
		tasks[w].queue_free()
		tasks.erase(w)


func _focus(w: W98Window) -> void:
	for c in win_layer.get_children():
		if c is W98Window:
			c.active = c == w
	w.move_to_front()


func _refresh_tasks() -> void:
	var top: W98Window = null
	for c in win_layer.get_children():
		if c is W98Window and c.visible:
			top = c
	for w in tasks:
		var b: W98Button = tasks[w]
		var t: String = w.get_meta("task_label") if w.has_meta("task_label") else w.title.get_slice(" – ", 0)
		if b.text != t:
			b.text = t
		b.sunken = w.visible and w == top and w.active


func _build_taskbar() -> void:
	var bar := TaskbarPanel.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -38
	add_child(bar)
	taskbar_row = HBoxContainer.new()
	taskbar_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	taskbar_row.offset_left = 4
	taskbar_row.offset_right = -4
	taskbar_row.offset_top = 5
	taskbar_row.offset_bottom = -5
	taskbar_row.add_theme_constant_override("separation", 4)
	bar.add_child(taskbar_row)
	start_btn = Win98.button("♟ Start", 84)
	start_btn.bold = true
	start_btn.pressed.connect(func(): _toggle_start(not start_menu.visible))
	taskbar_row.add_child(start_btn)
	task_spacer = Control.new()
	task_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	taskbar_row.add_child(task_spacer)
	var tray := HBoxContainer.new()
	tray.add_theme_constant_override("separation", 10)
	taskbar_row.add_child(tray)
	tray_env = Win98.label("✉", 16)
	tray_env.visible = false
	tray_env.mouse_filter = Control.MOUSE_FILTER_STOP
	tray_env.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _open_tet_mail())
	tray.add_child(tray_env)
	clock = Win98.label("03:47", 13)
	tray.add_child(clock)


func _build_balloon() -> void:
	balloon = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffffe1")
	sb.border_color = Color.BLACK
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	balloon.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	balloon.add_child(v)
	v.add_child(Win98.label("Ihr habt 1 neue Nachricht", 13, Color.BLACK, true))
	v.add_child(Win98.label("Von: ??? · Betreff: Challenge für 「　」", 12))
	balloon.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	balloon.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	balloon.grow_vertical = Control.GROW_DIRECTION_BEGIN
	balloon.offset_bottom = -48
	balloon.visible = false
	balloon.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _open_tet_mail())
	add_child(balloon)


func _toggle_start(on: bool) -> void:
	start_menu.visible = on
	start_btn.sunken = on
	if on:
		start_menu.reset_size()
		start_menu.position = Vector2(2, size.y - 38 - start_menu.size.y)
		start_menu.move_to_front()
		Flow.play("blip", -10)


# ------------------------------------------------------------------ Programme

func _open_app(kind: String) -> void:
	if apps.has(kind):
		_show_window(apps[kind])
		return
	var w := W98Window.new()
	match kind:
		"web":
			w.title = "NetSurfer 98"
			w.icon_color = Color("1a5fb4")
			w.size = Vector2(1000, 660)
			w.min_size = Vector2(560, 320)
			var browser := NetSurfer.new()
			browser.title_changed.connect(func(t): w.title = t)
			browser.secret.connect(_secret_skip)
			w.content.add_child(browser)
		"lol":
			w.title = "Liga der Legenden – Client"
			w.icon_color = Color("c8aa6e")
			w.size = Vector2(1180, 640)
			w.min_size = Vector2(900, 480)
			w.content.add_child(Launchers.build_lol())
		"cs":
			w.title = "Counter-Spike: GO"
			w.icon_color = Color("de9b35")
			w.size = Vector2(1120, 620)
			w.min_size = Vector2(860, 460)
			w.content.add_child(Launchers.build_cs())
	w.set_meta("task_label", {"web": "NetSurfer 98", "lol": "Liga der Legenden", "cs": "Counter-Spike GO"}[kind])
	w.size = w.size.min(win_layer.size - Vector2(20, 10))
	w.position = ((win_layer.size - w.size) * 0.5 + Vector2(apps.size() * 28 - 30, apps.size() * 22 - 20)).max(Vector2(4, 4))
	apps[kind] = w
	_register(w, true)
	_show_window(w)


## Testcode aus dem Browser: „break“ = der Bildschirm reißt und man wird in den PC gezogen
## (weiter mit Sturz und Landung), „world“ = direkt aufs Grundstück.
func _secret_skip(target: String) -> void:
	if target == "world":
		Flow.goto("world", Color.WHITE, 0.5, 0.8)
		return
	var screen := Rect2(Vector2.ZERO, size)
	Flow.play("crack")
	crack_layer.start(screen.get_center(), screen.grow(-size.y * 0.3))
	var shake := create_tween().set_loops(12)
	shake.tween_property(self, "position", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
	shake.tween_property(self, "position", Vector2.ZERO, 0.04)
	await get_tree().create_timer(1.5).timeout
	Flow.play("shatter", -8)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	Flow.screen_capture = get_viewport().get_texture().get_image()
	get_tree().change_scene_to_file(Flow.SCENES["break"])


func _open_folder(id: String) -> void:
	if file_wins.has(id):
		_show_window(file_wins[id])
		return
	var w := W98Window.new()
	w.size = Vector2(620, 420)
	w.min_size = Vector2(360, 240)
	w.position = Vector2(220, 80) + Vector2(file_wins.size() * 26, file_wins.size() * 22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	w.content.add_child(v)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 4)
	v.add_child(tools)
	var path := Win98.label("", 12)
	var view := IconView.new()
	view.fs = fs
	view.parent_id = id
	view.light_text = false
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var update := func():
		if not fs.items.has(view.parent_id):
			return
		w.title = fs.items[view.parent_id]["name"]
		path.text = "Adresse:  " + fs.path_of(view.parent_id)
	var nav := func(target: String):
		file_wins.erase(view.parent_id)
		view.parent_id = target
		file_wins[target] = w
		view.selected.clear()
		view.refresh()
		update.call()
	var up := Win98.button("↑ Nach oben", 100)
	up.pressed.connect(func():
		var parent: String = fs.items[view.parent_id]["parent"]
		if parent != "desk":
			nav.call(parent))
	tools.add_child(up)
	var nf := Win98.button("Neuer Ordner", 110)
	nf.pressed.connect(func(): view.create_item("folder"))
	tools.add_child(nf)
	var nt := Win98.button("Neues Textdokument", 150)
	nt.pressed.connect(func(): view.create_item("text"))
	tools.add_child(nt)
	v.add_child(path)
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := Win98.sunken_box()
	sb.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", sb)
	v.add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	scroll.add_child(view)
	var count := Win98.label("", 12)
	v.add_child(count)
	view.opened.connect(func(k: String):
		var cid := k.trim_prefix("i")
		if fs.items.has(cid) and fs.items[cid]["type"] == "folder":
			nav.call(cid)
		else:
			_open_key(k))
	fs.changed.connect(func():
		if is_instance_valid(count) and fs.items.has(view.parent_id):
			count.text = "%d Objekt(e)" % fs.children(view.parent_id).size())
	count.text = "%d Objekt(e)" % fs.children(id).size()
	w.set_meta("folder_view", view)
	file_wins[id] = w
	w.tree_exiting.connect(func(): file_wins.erase(view.parent_id))
	update.call()
	_register(w, false)
	_show_window(w)


func _open_text(id: String) -> void:
	if file_wins.has(id):
		_show_window(file_wins[id])
		return
	var w := W98Window.new()
	w.title = "%s – Editor" % fs.items[id]["name"]
	w.icon_color = Color.WHITE
	w.size = Vector2(560, 400)
	w.position = Vector2(300, 120) + Vector2(file_wins.size() * 26, file_wins.size() * 22)
	var te := TextEdit.new()
	te.text = fs.items[id]["content"]
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.add_theme_font_override("font", Flow.font_ui)
	te.add_theme_font_size_override("font_size", 14)
	te.add_theme_color_override("font_color", Color.BLACK)
	te.add_theme_color_override("caret_color", Color.BLACK)
	te.add_theme_color_override("selection_color", Win98.NAVY)
	te.add_theme_color_override("font_selected_color", Color.WHITE)
	var sb := Win98.sunken_box()
	te.add_theme_stylebox_override("normal", sb)
	te.add_theme_stylebox_override("focus", sb)
	te.text_changed.connect(func():
		if fs.items.has(id):
			fs.items[id]["content"] = te.text
			fs.save(true))
	w.content.add_child(te)
	file_wins[id] = w
	w.tree_exiting.connect(func(): file_wins.erase(id))
	_register(w, false)
	_show_window(w)
	te.grab_focus()


## Gelöschte Ordner und Dateien schließen ihre Fenster; Titel folgen dem neuen Namen.
func _on_fs_changed() -> void:
	for id in file_wins.keys():
		var w: W98Window = file_wins[id]
		if not fs.items.has(id):
			w.queue_free()
		elif fs.items[id]["type"] == "text":
			w.title = "%s – Editor" % fs.items[id]["name"]
		else:
			w.title = fs.items[id]["name"]


# ------------------------------------------------------------------ Posteingang

func _build_mail_window() -> void:
	mail_win = W98Window.new()
	mail_win.title = "Posteingang – PostFach 98"
	mail_win.size = Vector2(820, 680)
	mail_win.position = Vector2(150, 34)
	_register(mail_win, true)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	mail_win.content.add_child(v)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 4)
	v.add_child(tools)
	for spec in [["⟳ Abrufen", "fetch"], ["✎ Neu", "new"], ["↩ Antworten", "reply"], ["✕ Löschen", "del"]]:
		var b := Win98.button(spec[0], 96)
		b.pressed.connect(_tool.bind(spec[1]))
		tools.add_child(b)
	var split := VSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(split)
	var list_frame := SunkenPanel.new()
	list_frame.custom_minimum_size = Vector2(0, 190)
	split.add_child(list_frame)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 3
	scroll.offset_top = 3
	scroll.offset_right = -3
	scroll.offset_bottom = -3
	list_frame.add_child(scroll)
	mail_rows = VBoxContainer.new()
	mail_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mail_rows.add_theme_constant_override("separation", 0)
	scroll.add_child(mail_rows)
	var prev_frame := SunkenPanel.new()
	prev_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(prev_frame)
	var pscroll := ScrollContainer.new()
	pscroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pscroll.offset_left = 12
	pscroll.offset_top = 10
	pscroll.offset_right = -6
	pscroll.offset_bottom = -6
	prev_frame.add_child(pscroll)
	preview = VBoxContainer.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_theme_constant_override("separation", 8)
	pscroll.add_child(preview)
	status_left = Win98.label("Bereit", 12)
	v.add_child(status_left)


func _tool(kind: String) -> void:
	match kind:
		"fetch":
			if not arrived:
				_deliver()
			else:
				status_left.text = "Keine neuen Nachrichten"
		"new":
			_msg("Neue Nachricht", "Ihr schreibt niemandem. Euch schreibt man.")
		"reply":
			_msg("Antworten", "Diese Nachricht hat keine Absenderadresse." if mails[selected].get("tet", false) else "Keine Lust. Lieber noch eine Runde spielen.")
		"del":
			_msg("Löschen", "Diese Nachricht lässt sich nicht löschen." if mails[selected].get("tet", false) else "Nichts ausgewählt, das sich zu löschen lohnt.")


func _render_rows() -> void:
	for c in mail_rows.get_children():
		c.queue_free()
	var header := MailRow.new()
	header.cols = ["✉", "Von", "Betreff", "Empfangen"]
	header.header = true
	mail_rows.add_child(header)
	for i in mails.size():
		var m: Dictionary = mails[i]
		var row := MailRow.new()
		row.cols = ["✉" if m["unread"] else "·", m["from"], m["subj"], m["date"]]
		row.bold = m["unread"]
		row.selected = i == selected
		row.fresh = m.get("fresh", false)
		row.clicked.connect(_show_mail.bind(i))
		mail_rows.add_child(row)
	var unread := mails.filter(func(m): return m["unread"]).size()
	mail_win.title = "Posteingang%s – PostFach 98" % (" (%d)" % unread if unread else "")
	status_left.text = "%d Nachrichten, %d ungelesen" % [mails.size(), unread]
	if icons:
		icons.badges["sys:mail"] = unread
		icons.queue_redraw()


func _show_mail(i: int) -> void:
	selected = i
	var m: Dictionary = mails[i]
	m["unread"] = false
	m["fresh"] = false
	if m.get("tet", false):
		balloon.visible = false
		tray_env.visible = false
	_render_rows()
	for c in preview.get_children():
		c.queue_free()
	var head := Win98.label("Von: %s%s\nAn: 「　」\nBetreff: %s" % [m["from"], "  <keine Adresse>" if m.get("tet", false) else "", m["subj"]], 13, Color("333333"))
	preview.add_child(head)
	var sep := HSeparator.new()
	preview.add_child(sep)
	var body: Array = TET_TEXT if m.get("tet", false) else m["body"]
	for line in body:
		var l := Win98.label(line, 14)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(700, 0)
		preview.add_child(l)
	if m.get("tet", false):
		_no_count = 0
		var no_line := Win98.label("Wirklich? Ihr habt noch nie ein Spiel abgelehnt.", 14, Color("800000"))
		no_line.visible = false
		preview.add_child(no_line)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		preview.add_child(row)
		var yes := Win98.button("Ja", 110)
		yes.bold = true
		yes.pressed.connect(_accept)
		row.add_child(yes)
		var no := Win98.button("Nein", 110)
		no.pressed.connect(func():
			_no_count += 1
			if _no_count == 1:
				no_line.visible = true
			else:
				no.text = "Ja"
				no.bold = true
				no.pressed.connect(_accept))
		row.add_child(no)


func _deliver() -> void:
	if arrived:
		return
	arrived = true
	var tet := {"from": TET_MAIL[0], "subj": TET_MAIL[1], "date": TET_MAIL[2], "body": [], "unread": true, "fresh": true, "tet": true}
	mails.push_front(tet)
	selected += 1
	_render_rows()
	balloon.visible = true
	tray_env.visible = true
	Flow.play("mail", -3)


func _open_mail() -> void:
	_show_window(mail_win)


func _open_tet_mail() -> void:
	_open_mail()
	for i in mails.size():
		if mails[i].get("tet", false):
			_show_mail(i)
			return


# ------------------------------------------------------------------ Willkommen und Schach

func _accept() -> void:
	if chess_win:
		_show_window(chess_win)
		return
	var banner := WelcomeBanner.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(banner)
	Flow.play("welcome", -2)
	await banner.finished
	_open_chess()


func _open_chess() -> void:
	chess_win = W98Window.new()
	chess_win.title = "Schach 98 – Herausforderung von ???"
	chess_win.icon_color = Color("4d7fd6")
	chess_win.closable = false
	chess_win.size = Vector2(760, 560)
	chess_win.position = Vector2((size.x - 760) * 0.5, 20)
	chess_win.min_size = Vector2(620, 460)
	_register(chess_win, true)
	_show_window(chess_win)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	chess_win.content.add_child(row)
	board = ChessBoard.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(500, 500)
	row.add_child(board)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(220, 0)
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	var opp := SunkenPanel.new()
	opp.custom_minimum_size = Vector2(0, 84)
	side.add_child(opp)
	var ol := Win98.label("Gegner\n???\nKeine Angaben", 13)
	ol.position = Vector2(10, 6)
	opp.add_child(ol)
	side.add_child(Win98.label("Züge", 12))
	var mframe := SunkenPanel.new()
	mframe.custom_minimum_size = Vector2(0, 200)
	side.add_child(mframe)
	var ms := ScrollContainer.new()
	ms.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ms.offset_left = 8
	ms.offset_top = 6
	ms.offset_right = -4
	ms.offset_bottom = -4
	mframe.add_child(ms)
	moves_label = Win98.label("", 12)
	ms.add_child(moves_label)
	var sframe := SunkenPanel.new()
	sframe.custom_minimum_size = Vector2(0, 110)
	side.add_child(sframe)
	chess_status = Win98.label("", 13)
	chess_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chess_status.position = Vector2(8, 6)
	chess_status.size = Vector2(204, 100)
	sframe.add_child(chess_status)
	resign_btn = Win98.button("Aufgeben", 100)
	side.add_child(resign_btn)
	rematch_btn = Win98.button("Neue Partie", 100)
	rematch_btn.visible = false
	side.add_child(rematch_btn)
	var moves: Array[String] = []
	board.move_played.connect(func(t, mine):
		moves.append(t)
		var lines := PackedStringArray()
		for i in range(0, moves.size(), 2):
			lines.append("%d.  %s   %s" % [i / 2 + 1, moves[i], moves[i + 1] if i + 1 < moves.size() else ""])
		moves_label.text = "\n".join(lines))
	board.status_changed.connect(func(t): chess_status.text = t)
	board.game_over.connect(func(r):
		resign_btn.visible = false
		rematch_btn.visible = r != "win"
		if r == "win":
			_win_sequence())
	resign_btn.pressed.connect(board.resign)
	rematch_btn.pressed.connect(func():
		moves.clear()
		moves_label.text = ""
		resign_btn.visible = true
		rematch_btn.visible = false
		board.reset())
	board.reset()


## Sieg: Riss durchs Brett, dann über den ganzen Bildschirm, dann Wechsel in die 3D-Szene.
func _win_sequence() -> void:
	await get_tree().create_timer(1.4).timeout
	var r := board.get_global_rect()
	Flow.play("crack")
	crack_layer.start(r.get_center(), r)
	var shake := create_tween().set_loops(12)
	shake.tween_property(self, "position", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
	shake.tween_property(self, "position", Vector2.ZERO, 0.04)
	await get_tree().create_timer(1.6).timeout
	Flow.play("shatter", -8)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	Flow.screen_capture = get_viewport().get_texture().get_image()
	get_tree().change_scene_to_file(Flow.SCENES["break"])


# ------------------------------------------------------------------ kleine Bausteine

class SunkenPanel extends Control:
	func _draw() -> void:
		Win98.bevel(self, Rect2(Vector2.ZERO, size), false, Color.WHITE)


class TaskbarPanel extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Win98.FACE)
		draw_line(Vector2(0, 1), Vector2(size.x, 1), Win98.HI)


class MailRow extends Control:
	signal clicked
	var cols: Array = []
	var header := false
	var bold := false
	var selected := false
	var fresh := false
	var _t := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 24)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		if fresh:
			_t += delta
			queue_redraw()
			if _t > 2.0:
				fresh = false

	func _gui_input(event: InputEvent) -> void:
		if not header and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Flow.play("blip", -10)
			clicked.emit()

	func _draw() -> void:
		var widths := [28.0, size.x * 0.27, size.x - 28.0 - size.x * 0.27 - 110.0, 110.0]
		if header:
			var x := 0.0
			for i in 4:
				Win98.bevel(self, Rect2(x, 0, widths[i], size.y), true)
				draw_string(Flow.font_ui, Vector2(x + 6, 17), cols[i], HORIZONTAL_ALIGNMENT_LEFT, widths[i] - 10, 12, Color.BLACK)
				x += widths[i]
			return
		if selected:
			draw_rect(Rect2(Vector2.ZERO, size), Win98.NAVY)
		elif fresh and int(_t * 4.0) % 2 == 0:
			draw_rect(Rect2(Vector2.ZERO, size), Color("ffff80"))
		var font := Flow.font_ui_bold if bold else Flow.font_ui
		var col := Color.WHITE if selected else Color.BLACK
		var x := 0.0
		for i in 4:
			draw_string(font, Vector2(x + 6, 17), cols[i], HORIZONTAL_ALIGNMENT_LEFT, widths[i] - 10, 13, col)
			x += widths[i]


## Riss-Linien, die von einem Punkt aus über den Bildschirm wachsen.
class CrackOverlay extends Control:
	var lines: Array = []
	var t := -1.0
	var origin := Vector2.ZERO
	var board_rect := Rect2()

	func start(o: Vector2, r: Rect2) -> void:
		origin = o
		board_rect = r
		lines.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		# zuerst ein senkrechter Riss durchs Brett, dann Äste über den ganzen Bildschirm
		var main := PackedVector2Array()
		var y := r.position.y
		while y <= r.end.y:
			main.append(Vector2(o.x + rng.randf_range(-r.size.x * 0.06, r.size.x * 0.06), y))
			y += r.size.y / 9.0
		lines.append({"pts": main, "w": 3.5, "delay": 0.0})
		for i in 11:
			_grow(o, i / 11.0 * TAU + rng.randf() * 0.4, 0, rng, 0.45)
		t = 0.0
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _grow(p: Vector2, ang: float, depth: int, rng: RandomNumberGenerator, delay: float) -> void:
		var pts := PackedVector2Array([p])
		var sz := get_viewport_rect().size
		while p.x > -50 and p.y > -50 and p.x < sz.x + 50 and p.y < sz.y + 50 and pts.size() < 60:
			ang += rng.randf_range(-0.16, 0.16)
			p += Vector2(cos(ang), sin(ang)) * rng.randf_range(30, 70)
			pts.append(p)
			if depth < 2 and rng.randf() < 0.1:
				_grow(p, ang + rng.randf_range(0.4, 0.9) * (1 if rng.randf() < 0.5 else -1), depth + 1, rng, delay + 0.1)
		if pts.size() >= 2:
			lines.append({"pts": pts, "w": 2.4 if depth == 0 else 1.3, "delay": delay})

	func _process(delta: float) -> void:
		if t >= 0.0:
			t += delta
			queue_redraw()

	func _draw() -> void:
		if t < 0.0:
			return
		for l in lines:
			var p := clampf((t - l["delay"]) / 1.1, 0.0, 1.0)
			var pts: PackedVector2Array = l["pts"]
			var n := clampi(int(pts.size() * p), 2, pts.size())
			if p <= 0.0:
				continue
			var part := pts.slice(0, n)
			draw_polyline(part, Color(0.25, 0.9, 1.0, 0.5), l["w"] + 4.0)
			draw_polyline(part, Color.WHITE, l["w"])


## „ようこそ♪ / WILLKOMMEN“ auf einem durchlaufenden Schachbrett-Band.
class WelcomeBanner extends Control:
	signal finished
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_t = maxf(_t, 3.8)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > 4.2 and not _done:
			_done = true
			finished.emit()
			queue_free()

	func _draw() -> void:
		var open := clampf(_t / 0.35, 0.0, 1.0) * (1.0 - clampf((_t - 3.8) / 0.35, 0.0, 1.0))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0.16, 0.35 * open))
		var h := size.y * 0.34 * open
		var band := Rect2(0, size.y * 0.5 - h * 0.5, size.x, h)
		if h < 2.0:
			return
		var tile := 110.0
		var shift := fmod(_t * 40.0, tile * 2.0)
		var x := -tile * 2.0 + shift
		while x < size.x:
			var y := band.position.y
			var row := 0
			while y < band.end.y:
				for k in 2:
					var tx := x + k * tile
					var even := (k + row) % 2 == 0
					var r := Rect2(tx, y, tile, tile).intersection(band)
					if r.size.x > 0 and r.size.y > 0:
						draw_rect(r, Color("5b86d6") if even else Color("a8e6d2"))
				y += tile
				row += 1
			x += tile * 2.0
		for edge in [band.position.y + 6.0, band.end.y - 14.0]:
			var ex := 0.0
			while ex < size.x:
				draw_rect(Rect2(ex, edge, 6, 8), Color("ffe08a"))
				draw_rect(Rect2(ex + 6, edge, 6, 8), Color("f2a23c"))
				ex += 18.0
		for sy in range(int(band.position.y), int(band.end.y), 3):
			draw_line(Vector2(0, sy), Vector2(size.x, sy), Color(1, 1, 1, 0.07))
		if open > 0.95:
			var appear := clampf((_t - 0.3) / 0.4, 0.0, 1.0)
			var glitch := (1.0 - appear) * 24.0 * sin(_t * 60.0)
			var jp := "ようこそ♪"
			var fs := int(minf(size.x * 0.12, 150.0))
			var f := Flow.font_pixel
			var w := f.get_string_size(jp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := Vector2((size.x - w) * 0.5 + glitch, size.y * 0.5 + fs * 0.25)
			draw_string(f, pos + Vector2(-5, 0), jp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.16, 0.47, 0.55 * appear))
			draw_string(f, pos + Vector2(5, 0), jp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0.9, 1, 0.55 * appear))
			draw_string_outline(f, pos, jp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color("2b3f8e", appear))
			draw_string(f, pos, jp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, appear))
			var en := "WILLKOMMEN"
			var w2 := Flow.font_ui_bold.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			var p2 := Vector2((size.x - w2) * 0.5, size.y * 0.5 + fs * 0.25 + 40)
			draw_string_outline(Flow.font_ui_bold, p2, en, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color("2b3f8e", appear))
			draw_string(Flow.font_ui_bold, p2, en, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, appear))



## Startmenü mit senkrechtem Band „「　」 OS 98“.
class StartMenu extends PanelContainer:
	signal chosen(key: String)
	const ENTRIES := [["✉  Posteingang", "mail"], ["♟  Spiele", "games"], ["◍  Internet", "web"], ["⚔  Liga der Legenden", "lol"], ["⌖  Counter-Spike GO", "cs"], ["?  Hilfe", "help"], ["", ""], ["＋  Neuer Ordner", "newfolder"], ["✎  Neues Textdokument", "newtext"], ["", ""], ["⏻  Beenden …", "shutdown"]]

	func _ready() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Win98.FACE
		sb.border_color = Win98.DARK
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.content_margin_left = 30
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		sb.content_margin_right = 3
		add_theme_stylebox_override("panel", sb)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		add_child(v)
		for e in ENTRIES:
			if e[0] == "":
				var sep := HSeparator.new()
				v.add_child(sep)
				continue
			var b := Button.new()
			b.text = e[0]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size = Vector2(230, 32)
			b.add_theme_font_override("font", Flow.font_ui)
			b.add_theme_font_size_override("font_size", 14)
			b.add_theme_color_override("font_color", Color.BLACK)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			b.add_theme_color_override("font_pressed_color", Color.WHITE)
			b.add_theme_color_override("font_focus_color", Color.BLACK)
			var flat := StyleBoxEmpty.new()
			flat.content_margin_left = 10
			var hover := StyleBoxFlat.new()
			hover.bg_color = Win98.NAVY
			hover.content_margin_left = 10
			b.add_theme_stylebox_override("normal", flat)
			b.add_theme_stylebox_override("focus", flat)
			b.add_theme_stylebox_override("hover", hover)
			b.add_theme_stylebox_override("pressed", hover)
			b.pressed.connect(func(): chosen.emit(e[1]))
			v.add_child(b)

	func _draw() -> void:
		draw_rect(Rect2(3, 3, 24, size.y - 6), Win98.SHADE.lerp(Win98.NAVY, 0.7))
		draw_set_transform(Vector2(21, size.y - 10), -PI / 2)
		draw_string(Flow.font_ui_bold, Vector2.ZERO, "「　」", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		draw_string(Flow.font_ui, Vector2(52, 0), "OS 98", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c0c0c0"))
		draw_set_transform(Vector2.ZERO)
