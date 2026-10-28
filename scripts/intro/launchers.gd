class_name Launchers
## Gefälschte Spiele-Clients auf dem Desktop: „Liga der Legenden“ (Rang 1) und „Counter-Spike GO“
## (Global Elite), jeweils mit Chats von erfundenen Profis.

const LOL_LINES := ["Suche Gegner …", "Warteschlange: 47:12. Niemand nimmt die Partie an.", "Gegner gefunden … Gegner hat die Partie abgelehnt.", "Hinweis: 312 Spieler haben euch auf ihre Sperrliste gesetzt."]
const CS_LINES := ["Suche Match …", "Match gefunden. Gegner hat das Spiel verlassen.", "Match gefunden. Gegner hat das Spiel verlassen.", "Match gefunden. Alle zehn Gegner haben das Spiel verlassen."]

const LOL_CHATS := [
	{"name": "DämonenKönig_Mid", "tag": "Dreifacher Weltmeister · Mitte", "msgs": ["Hallo.", "Ich spiele seit zehn Jahren auf höchstem Niveau. So habe ich noch nie verloren.", "Ihr wart nach sechs Minuten vier Stufen über mir. Wie?", "Bitte sagt mir ehrlich: Ist das euer Zweitkonto?", "me:Nein. Das ist unser einziges.", "… verstehe. Dann mache ich vielleicht eine Pause."]},
	{"name": "T0PLANE_SCREAMER", "tag": "Streamer · Oben · 2,1 Mio. Follower", "msgs": ["WAS WAR DAS", "DU HAST MICH AUF STUFE 2 IM 1 GEGEN 1 GETÖTET. ALS HEILER.", "SMURF. 100 PROZENT SMURF. ICH MELDE DICH.", "…", "ok du wurdest schon 312-mal gemeldet und nix ist passiert", "respekt. gg. bitte nie wieder gegen mich"]},
	{"name": "JungleGott_KR", "tag": "Profi · Dschungel", "msgs": ["Ich habe euer Replay 40-mal angeschaut.", "Ihr wusstet in Minute 3, wo ich in Minute 9 sein würde.", "Mein Coach sagt, das ist unmöglich.", "Ich sage: Ich habe es mit eigenen Augen gesehen."]},
	{"name": "SupportQueen", "tag": "Weltmeisterin · Unterstützer", "msgs": ["2 / 0 / 41 als Heiler?!", "So viele Vorlagen in 16 Minuten habe ich noch nie gesehen.", "Wie viele Smurf-Konten habt ihr eigentlich?", "Bitte bringt mir das bei. Ich bezahle."]},
	{"name": "Coach_Yun", "tag": "Cheftrainer · Weltmeister-Team", "msgs": ["Wir möchten euch verpflichten.", "Gehalt: Nennt eine Zahl. Wir verhandeln nicht.", "Einzige Bedingung: Kommt einmal persönlich zum Training.", "me:Wie weit ist das?", "Seoul.", "me:Zu weit."]},
]
const CS_CHATS := [
	{"name": "AWP_Legende", "tag": "Mehrfacher Major-Sieger · AWP", "msgs": ["Ich war jahrelang die Nummer eins der Welt.", "War.", "16 : 0. Ich habe in 16 Runden genau einen Treffer gelandet. In eine Wand.", "Ich lege die AWP jetzt erst mal weg."]},
	{"name": "HeadshotMaschine", "tag": "Profi · König der Kopftreffer", "msgs": ["Man nennt mich die Kopftreffer-Maschine.", "Heute: 0 Kopftreffer. Ihr: 97 Prozent.", "Ich habe nicht mal gesehen, woher die Schüsse kamen.", "Bitte schickt mir eure Mausempfindlichkeit.", "me:Wir spielen mit dem Touchpad.", "…"]},
	{"name": "IGL_Professor", "tag": "Ingame-Leader · Taktiker", "msgs": ["Ich hatte 200 Strategien für dieses Match vorbereitet.", "Ihr habt jede einzelne in der ersten Runde gekontert. Auch die, die wir noch nie gespielt haben.", "Habt ihr unsere Teambesprechung abgehört?"]},
	{"name": "Entry_Fragger", "tag": "Profi · Entry", "msgs": ["Ich bin 16-mal als Erster gestorben.", "In 16 Runden.", "Das ist ein persönlicher Rekord, glaube ich.", "Ihr habt euch komplett zerstört. Also mich. Ihr habt mich zerstört."]},
	{"name": "Major-Turnierleitung", "tag": "Organisation", "msgs": ["Bitte nehmt am nächsten Major teil.", "Problem: Alle anderen Teams treten nur an, wenn ihr NICHT kommt.", "Wir wissen ehrlich gesagt nicht, was wir jetzt machen sollen."]},
]

const LOL := {
	"bg0": Color("0a323c"), "bg1": Color("010a13"), "gold": Color("c8aa6e"), "gold_dark": Color("463714"),
	"text": Color("f0e6d2"), "muted": Color("a09b8c"), "accent": Color("0ac8b9"), "card": Color(0.004, 0.04, 0.075, 0.6),
	"row": Color("1e2328"), "bubble": Color("1e2328"), "me": Color("463714"), "head_font": "display",
}
const CS := {
	"bg0": Color("2b2f33"), "bg1": Color("121417"), "gold": Color("de9b35"), "gold_dark": Color("3a3f44"),
	"text": Color("e6e6e6"), "muted": Color("8c9196"), "accent": Color("8cb33a"), "card": Color(0, 0, 0, 0.35),
	"row": Color("1b1f23"), "bubble": Color("1b1f23"), "me": Color("4a3a1e"), "head_font": "ui",
}


static func build_lol() -> Control:
	var p := LOL
	var root := Backdrop.new()
	root.c0 = p["bg0"]
	root.c1 = p["bg1"]
	var v := _root_box(root)
	# Kopfzeile
	var top := _bar(Color(0.004, 0.04, 0.075, 0.85), p["gold_dark"])
	v.add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 22)
	top.add_child(th)
	var play := _button("SPIELEN", Color("1e2328"), p["gold"], p["gold"], Flow.font_display, 15)
	th.add_child(play)
	for n in ["Startseite", "Profil", "Sammlung", "Shop"]:
		th.add_child(_lbl(n.to_upper(), 13, p["text"] if n == "Startseite" else p["muted"], Flow.font_display))
	th.add_child(_spacer())
	th.add_child(_lbl("「　」\nStufe 999 · Online", 12, p["text"]))
	# Inhalt in drei Spalten
	var main := _columns(v)
	var rank := _card(p)
	main.add_child(rank)
	var rv := rank.get_child(0) as VBoxContainer
	var crest := Emblem.new()
	crest.kind = "lol"
	rv.add_child(crest)
	rv.add_child(_lbl("Challenger I", 26, p["text"], Flow.font_display, true))
	rv.add_child(_lbl("Rang #1 von 13.402.881", 14, p["accent"], Flow.font_ui, true))
	rv.add_child(_lbl("4.812 LP", 15, p["gold"], Flow.font_ui_bold, true))
	rv.add_child(_stats([["Siege", "2.847"], ["Niederlagen", "0"], ["Siegesserie", "2.847"]], p, 3))
	var msg := _lbl("", 13, p["accent"], Flow.font_ui, true)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(msg)
	_cycle(play, msg, LOL_LINES)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 270
	side.add_theme_constant_override("separation", 4)
	main.add_child(side)
	side.add_child(_lbl("RANGLISTE · SOLO/DUO", 13, p["gold"], Flow.font_display))
	var ladder := [["1", "「　」", "4.812 LP"], ["2", "xX_Herausforderer_Xx", "1.204 LP"], ["3", "Blutrabe", "1.187 LP"], ["4", "GM_Eisenhart", "1.150 LP"], ["5", "ProGamer_Nr5", "1.149 LP"]]
	for i in ladder.size():
		side.add_child(_row(ladder[i], [p["muted"], p["text"], p["muted"]], Color(p["gold"], 0.3) if i == 0 else Color(p["row"], 0.75), Color.TRANSPARENT))
	side.add_child(_gap(8))
	side.add_child(_lbl("LETZTE PARTIEN", 13, p["gold"], Flow.font_display))
	for g in [["Sieg", "Mitte · Magier", "21 / 0 / 14", "14:32"], ["Sieg", "Dschungel · Assassine", "18 / 0 / 22", "15:05"], ["Sieg", "Unterstützer · Heiler", "2 / 0 / 41", "16:48"], ["Sieg", "Oben · Kämpfer", "24 / 0 / 9", "13:51"], ["Sieg", "Unten · Schütze", "27 / 0 / 11", "15:20"]]:
		side.add_child(_row(g, [p["accent"], p["muted"], p["text"], p["muted"]], Color(0.04, 0.2, 0.235, 0.55), p["accent"]))

	var chat := ChatPanel.new()
	chat.palette = p
	chat.convos = LOL_CHATS
	chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(chat)
	return root


static func build_cs() -> Control:
	var p := CS
	var root := Backdrop.new()
	root.c0 = p["bg0"]
	root.c1 = p["bg1"]
	var v := _root_box(root)
	var top := _bar(Color("0e1012"), p["gold"])
	v.add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 20)
	top.add_child(th)
	var logo := RichTextLabel.new()
	logo.bbcode_enabled = true
	logo.fit_content = true
	logo.autowrap_mode = TextServer.AUTOWRAP_OFF
	logo.scroll_active = false
	logo.add_theme_font_override("bold_font", Flow.font_ui_bold)
	logo.add_theme_font_size_override("bold_font_size", 16)
	logo.text = "[b][color=#ffffff]COUNTER-SPIKE[/color] [color=#de9b35]GO[/color][/b]"
	logo.custom_minimum_size = Vector2(190, 0)
	th.add_child(logo)
	for n in ["Spielen", "Inventar", "Statistik", "Optionen"]:
		th.add_child(_lbl(n.to_upper(), 12, Color.WHITE if n == "Spielen" else p["muted"]))
	th.add_child(_spacer())
	var play := _button("▶ LOS", Color("5b7a1e"), Color("8cb33a"), Color.WHITE, Flow.font_ui_bold, 14)
	th.add_child(play)

	var main := _columns(v)
	var rank := _card(p)
	main.add_child(rank)
	var rv := rank.get_child(0) as VBoxContainer
	var emb := Emblem.new()
	emb.kind = "cs"
	rv.add_child(emb)
	rv.add_child(_lbl("THE GLOBAL ELITE", 22, p["gold"], Flow.font_ui_bold, true))
	rv.add_child(_lbl("Wettkampfrang · Profilrang 40", 12, p["muted"], Flow.font_ui, true))
	rv.add_child(_stats([["Siege", "9.999"], ["K/D", "48,3"], ["Kopftreffer", "97 %"], ["Spielzeit", "31.522 h"]], p, 2))
	var msg := _lbl("", 13, p["accent"], Flow.font_ui, true)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(msg)
	_cycle(play, msg, CS_LINES)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 270
	side.add_theme_constant_override("separation", 4)
	main.add_child(side)
	side.add_child(_lbl("LETZTE MATCHES", 12, p["muted"]))
	for g in [["de_dunst", "16 : 0", "42 Kills"], ["de_lagune", "16 : 0", "39 Kills"], ["de_bahnhof", "16 : 0", "45 Kills"], ["de_vulkan", "16 : 0", "Gegner aufgegeben"], ["de_kloster", "16 : 0", "40 Kills"]]:
		side.add_child(_row(g, [p["text"], p["accent"], p["muted"]], p["row"], p["accent"]))
	side.add_child(_gap(8))
	side.add_child(_lbl("MELDUNGEN", 12, p["muted"]))
	var note := _lbl("Als Cheater gemeldet: 4.211-mal\nBestätigt: 0-mal\nAnti-Cheat-Kommentar: „Die sind einfach so.“", 12, p["text"])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(note)

	var chat := ChatPanel.new()
	chat.palette = p
	chat.convos = CS_CHATS
	chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(chat)
	return root


# ------------------------------------------------------------------ Bausteine

static func _root_box(root: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 0)
	root.add_child(v)
	return v


static func _columns(v: VBoxContainer) -> HBoxContainer:
	var m := MarginContainer.new()
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 14)
	v.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)
	return h


static func _bar(bg: Color, line: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = line
	sb.border_width_bottom = 2
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	return pc


static func _card(p: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size.x = 280
	var sb := StyleBoxFlat.new()
	sb.bg_color = p["card"]
	sb.border_color = p["gold_dark"]
	sb.set_border_width_all(1)
	sb.set_content_margin_all(14)
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	return pc


static func _lbl(text: String, size := 13, color := Color.WHITE, font: Font = null, center := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else Flow.font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


static func _button(text: String, bg: Color, border: Color, fg: Color, font: Font, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, fg)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg.lightened(0.12) if state == "hover" else (bg.darkened(0.2) if state == "pressed" else bg)
		sb.border_color = border
		sb.set_border_width_all(2)
		sb.content_margin_left = 24
		sb.content_margin_right = 24
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		if state == "hover":
			sb.shadow_color = Color(border, 0.6)
			sb.shadow_size = 8
		b.add_theme_stylebox_override(state, sb)
	return b


static func _cycle(btn: Button, msg: Label, lines: Array) -> void:
	var n := [0]
	btn.pressed.connect(func():
		msg.text = lines[n[0] % lines.size()]
		n[0] += 1
		Flow.play("blip", -6))


static func _stats(list: Array, p: Dictionary, cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for s in list:
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color = p["row"] if p == CS else Color("010a13")
		sb.border_color = p["gold"] if p == CS else p["row"]
		if p == CS:
			sb.border_width_left = 3
		else:
			sb.set_border_width_all(1)
		sb.set_content_margin_all(6)
		pc.add_theme_stylebox_override("panel", sb)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		pc.add_child(v)
		v.add_child(_lbl(s[0], 11, p["muted"]))
		v.add_child(_lbl(s[1], 16, p["text"], Flow.font_ui_bold))
		g.add_child(pc)
	return g


static func _row(cols: Array, colors: Array, bg: Color, edge: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.border_width_left = 3 if edge.a > 0 else 0
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	pc.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pc.add_child(h)
	for i in cols.size():
		var l := _lbl(cols[i], 12, colors[i], Flow.font_ui_bold if i == 0 and edge.a > 0 else Flow.font_ui)
		if i == 1:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		h.add_child(l)
	return pc


## Hintergrund mit diagonalem Farbverlauf.
class Backdrop extends Control:
	var c0 := Color.BLACK
	var c1 := Color.BLACK

	func _ready() -> void:
		clip_contents = true
		resized.connect(queue_redraw)

	func _draw() -> void:
		var steps := 32
		for i in steps:
			var t := float(i) / (steps - 1)
			draw_rect(Rect2(0, size.y * i / steps, size.x, size.y / steps + 1), c0.lerp(c1, smoothstep(0.0, 0.75, t)))


## Rangabzeichen: Liga-Wappen oder Global-Elite-Flügel.
class Emblem extends Control:
	var kind := "lol"

	func _ready() -> void:
		custom_minimum_size = Vector2(170, 120 if kind == "lol" else 96)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var c := size * 0.5
		if kind == "lol":
			draw_circle(c, 56, Color(0.04, 0.78, 0.72, 0.12))
			var pts := PackedVector2Array()
			for i in 16:
				var a := -PI / 2 + i * TAU / 16
				var r := 54.0 if i % 2 == 0 else 32.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, Color("c8aa6e"))
			pts.append(pts[0])
			draw_polyline(pts, Color("785a28"), 2.0)
			draw_circle(c, 20, Color("f0e6d2"))
			draw_circle(c, 16, Color("0ac8b9"))
			draw_circle(c + Vector2(-5, -5), 5, Color("cdfafa"))
		else:
			# Stern mit Lorbeerflügeln
			for side in [-1.0, 1.0]:
				for i in 6:
					var p := c + Vector2(side * (26 + i * 11), 12 - i * 5 + i * i * 0.8)
					var leaf := PackedVector2Array([p, p + Vector2(side * 16, -10), p + Vector2(side * 22, 2), p + Vector2(side * 6, 6)])
					draw_colored_polygon(leaf, Color("de9b35").lerp(Color("f6d28a"), i / 6.0))
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				star.append(c + Vector2(cos(a), sin(a)) * (30.0 if i % 2 == 0 else 13.0))
			draw_colored_polygon(star, Color("f6d28a"))
			star.append(star[0])
			draw_polyline(star, Color("8a5a14"), 2.0)
			draw_circle(c, 6, Color("de9b35"))


## Chatliste mit Verlauf; neue Chats werden Nachricht für Nachricht „getippt“.
class ChatPanel extends VBoxContainer:
	var palette := {}
	var convos: Array = []
	var _read: Array = []
	var _active := -1
	var _token := 0
	var _head: Label
	var _list: VBoxContainer
	var _who: Label
	var _msgs: VBoxContainer
	var _scroll: ScrollContainer

	func _ready() -> void:
		add_theme_constant_override("separation", 6)
		_read.resize(convos.size())
		_read.fill(false)
		_head = Launchers._lbl("", 13, palette["gold"], Flow.font_display if palette["head_font"] == "display" else Flow.font_ui_bold)
		add_child(_head)
		var h := HBoxContainer.new()
		h.size_flags_vertical = Control.SIZE_EXPAND_FILL
		h.add_theme_constant_override("separation", 8)
		add_child(h)
		_list = VBoxContainer.new()
		_list.custom_minimum_size.x = 190
		_list.add_theme_constant_override("separation", 3)
		h.add_child(_list)
		var thread := PanelContainer.new()
		thread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(palette["bg1"], 0.75)
		sb.border_color = palette["gold_dark"]
		sb.set_border_width_all(1)
		sb.set_content_margin_all(8)
		thread.add_theme_stylebox_override("panel", sb)
		h.add_child(thread)
		var tv := VBoxContainer.new()
		thread.add_child(tv)
		_who = Launchers._lbl("Wähle links einen Chat.", 13, palette["muted"])
		tv.add_child(_who)
		_scroll = ScrollContainer.new()
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tv.add_child(_scroll)
		_msgs = VBoxContainer.new()
		_msgs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_msgs.add_theme_constant_override("separation", 6)
		_scroll.add_child(_msgs)
		_render_list()

	func _render_list() -> void:
		for c in _list.get_children():
			c.queue_free()
		var unread := _read.count(false)
		_head.text = "CHAT" + ("   %d ungelesen" % unread if unread else "")
		for i in convos.size():
			var b := Button.new()
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = ("●  " if not _read[i] else "") + convos[i]["name"] + "\n" + convos[i]["tag"]
			b.clip_text = true
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.add_theme_font_override("font", Flow.font_ui)
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", palette["text"])
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			for state in ["normal", "hover", "pressed", "focus"]:
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(palette["row"], 0.85).lightened(0.08 if state == "hover" else 0.0)
				sb.border_color = palette["gold"] if i == _active else (palette["accent"] if not _read[i] else Color.TRANSPARENT)
				sb.border_width_left = 3
				sb.set_content_margin_all(6)
				b.add_theme_stylebox_override(state, sb)
			b.pressed.connect(_open.bind(i))
			_list.add_child(b)

	func _open(i: int) -> void:
		_token += 1
		var my := _token
		var was_read: bool = _read[i]
		_read[i] = true
		_active = i
		_render_list()
		_who.text = "%s  ·  %s" % [convos[i]["name"], convos[i]["tag"]]
		_who.add_theme_color_override("font_color", palette["text"])
		for c in _msgs.get_children():
			c.queue_free()
		var msgs: Array = convos[i]["msgs"]
		if was_read:
			for m in msgs:
				_bubble(m)
			return
		for m in msgs:
			if my != _token or not is_inside_tree():
				return
			var typing := _bubble("schreibt …", true)
			await get_tree().create_timer(0.5 + minf(1.2, String(m).length() * 0.018)).timeout
			if my != _token or not is_inside_tree():
				return
			typing.queue_free()
			_bubble(m)
			Flow.play("blip", -12, 1.3)
			await get_tree().create_timer(0.35).timeout

	func _bubble(m: String, typing := false) -> Control:
		var me := m.begins_with("me:")
		var text := m.substr(3) if me else m
		var row := HBoxContainer.new()
		if me:
			row.add_child(Launchers._spacer())
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = palette["me"] if me else palette["bubble"]
		sb.border_color = palette["gold"] if me else palette["accent"]
		if me:
			sb.border_width_right = 2
		else:
			sb.border_width_left = 2
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		pc.add_theme_stylebox_override("panel", sb)
		var l := Launchers._lbl(text, 13, palette["muted"] if typing else palette["text"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = minf(320.0, Flow.font_ui.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 4)
		pc.add_child(l)
		row.add_child(pc)
		_msgs.add_child(row)
		_scroll_down.call_deferred()
		return row

	func _scroll_down() -> void:
		await get_tree().process_frame
		if is_instance_valid(_scroll):
			_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
