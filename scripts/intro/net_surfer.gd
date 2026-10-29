class_name NetSurfer
extends VBoxContainer
## Browser „NetSurfer 98“ mit dem Forum Threadit.
## Testcodes: `skip:secret` springt dorthin, wo der Monitor zerbricht und man hineingezogen wird,
## `skip:welt` direkt aufs Grundstück.

signal secret(target: String)
signal title_changed(text: String)

const HOST := "http://www.threadit.net"
const BG := "#dae0e6"

var addr: LineEdit
var page: ScrollContainer
var body: VBoxContainer
var status: Label
var back_btn: W98Button
var fwd_btn: W98Button
var hist: Array = []
var hi := 0
var votes := {}
var _load := 0
var _url_re := RegEx.create_from_string("^(?:https?://)?(?:www\\.)?threadit\\.net(/.*)?$")


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	add_child(nav)
	back_btn = Win98.button("◀", 34)
	back_btn.pressed.connect(func():
		if hi > 0:
			hi -= 1
			_show(hist[hi]))
	nav.add_child(back_btn)
	fwd_btn = Win98.button("▶", 34)
	fwd_btn.pressed.connect(func():
		if hi < hist.size() - 1:
			hi += 1
			_show(hist[hi]))
	nav.add_child(fwd_btn)
	var reload := Win98.button("⟳", 34)
	reload.pressed.connect(func(): _show(hist[hi]))
	nav.add_child(reload)
	var home := Win98.button("⌂", 34)
	home.pressed.connect(func(): go(HOST + "/"))
	nav.add_child(home)
	var al := Win98.label("Adresse", 12)
	nav.add_child(al)
	addr = LineEdit.new()
	addr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	addr.add_theme_font_override("font", Flow.font_ui)
	addr.add_theme_font_size_override("font_size", 13)
	addr.add_theme_color_override("font_color", Color.BLACK)
	addr.add_theme_color_override("selection_color", Win98.NAVY)
	addr.add_theme_color_override("font_selected_color", Color.WHITE)
	addr.add_theme_color_override("caret_color", Color.BLACK)
	var sb := Win98.sunken_box()
	sb.set_content_margin_all(4)
	addr.add_theme_stylebox_override("normal", sb)
	addr.add_theme_stylebox_override("focus", sb)
	addr.text_submitted.connect(func(t): go(t))
	nav.add_child(addr)
	var go_btn := Win98.button("Los", 50)
	go_btn.pressed.connect(func(): go(addr.text))
	nav.add_child(go_btn)

	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var psb := Win98.sunken_box(Color(BG))
	psb.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", psb)
	add_child(frame)
	page = ScrollContainer.new()
	page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(page)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	page.add_child(body)
	status = Win98.label("Fertig", 12)
	add_child(status)
	hist = [HOST + "/"]
	hi = 0
	_show(hist[0])
	# Entwicklerhilfe: `--url=/t/blank/simultan` öffnet direkt eine Seite
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--url="):
			go(HOST + arg.trim_prefix("--url="))


func go(url: String) -> void:
	var code := url.strip_edges().to_lower()
	if code == "skip:secret" or code == "skip:welt":
		addr.text = ""
		status.text = "Geheimcode akzeptiert …"
		Flow.play("welcome", -6)
		secret.emit("break" if code == "skip:secret" else "world")
		return
	hist = hist.slice(0, hi + 1)
	hist.append(url)
	hi = hist.size() - 1
	_show(url)


func _show(url: String, keep_scroll := false) -> void:
	var m := _url_re.search(url.strip_edges())
	var path := ""
	if m:
		path = m.get_string(1) if m.get_string(1) != "" else "/"
	var res := _route(path) if m else {}
	if res.is_empty():
		res = _error_page(url)
	addr.text = HOST + path if m else url
	back_btn.modulate.a = 1.0 if hi > 0 else 0.5
	fwd_btn.modulate.a = 1.0 if hi < hist.size() - 1 else 0.5
	_load += 1
	var my := _load
	if keep_scroll:
		var sc := page.scroll_vertical
		_fill(res)
		await get_tree().process_frame
		page.scroll_vertical = sc
		return
	status.text = "Seite wird geöffnet: %s …" % addr.text
	page.modulate.a = 0.55
	await get_tree().create_timer(0.28).timeout
	if my != _load:
		for n in res["nodes"]:
			n.queue_free()
		return
	_fill(res)
	page.scroll_vertical = 0
	page.modulate.a = 1.0
	status.text = "Fertig"
	title_changed.emit("%s – NetSurfer 98" % res["title"])


func _fill(res: Dictionary) -> void:
	for c in body.get_children():
		c.queue_free()
	for n in res["nodes"]:
		body.add_child(n)


func _on_meta(meta) -> void:
	var s := str(meta)
	if s.begins_with("go:"):
		go(HOST + s.substr(3))
	elif s.begins_with("vote:"):
		var parts := s.split(":")
		var key := parts[1]
		var dir := int(parts[2])
		votes[key] = 0 if votes.get(key, 0) == dir else dir
		Flow.play("blip", -10, 1.2 if dir > 0 else 0.8)
		_show(hist[hi], true)
	elif s == "more":
		status.text = "Zu viele Leute lesen gerade über 「　」. Bitte später erneut versuchen."
	elif s == "join":
		status.text = "Beigetreten. Willkommen in der Community!"


# ------------------------------------------------------------------ Seiten

static func esc(t: String) -> String:
	return t.replace("[", "[lb]")


static func kfmt(n: int) -> String:
	return ("%.1fk" % (n / 1000.0)).replace(".", ",") if n >= 1000 else str(n)


func _route(path: String) -> Dictionary:
	var parts := Array(path.split("/", false))
	if parts.is_empty():
		var feed: Array = Threadit.THREADS.duplicate()
		feed.sort_custom(func(a, b): return (1e9 if a.get("pinned", false) else 0.0) + a["score"] > (1e9 if b.get("pinned", false) else 0.0) + b["score"])
		var main: Array = [_rtl("[b]Beliebt[/b]     [color=#878a8c]Neu     Top[/color]", "#ffffff", 10)]
		for t in feed:
			main.append(_post(t, false))
		return {"title": "Threadit – Die Startseite des Internets", "nodes": [_head(), _layout(main, _side(""))]}
	if parts[0] == "t" and parts.size() >= 2 and Threadit.SUBS.has(parts[1]):
		var s: String = parts[1]
		var S: Dictionary = Threadit.SUBS[s]
		var banner := _rtl("[font_size=26][color=#ffffff][b]%s   %s[/b][/color][/font_size]\n[color=#dddddd]t/%s[/color]" % [esc(S["icon"]), S["name"], S["name"]], S["color"], 18)
		if parts.size() == 2:
			var main := []
			for t in Threadit.THREADS:
				if t["sub"] == s:
					main.append(_post(t, false))
			return {"title": "t/" + S["name"], "nodes": [_head(), banner, _layout(main, _side(s))]}
		var t := Threadit.find(s, parts[2])
		if not t.is_empty():
			var c := "[b]Kommentare[/b]     [color=#878a8c]Sortiert nach: Beste[/color]\n\n" + _comments(t["comments"], t["id"], 0)
			c += "[url=more][color=#0079d3][b]Weitere Kommentare laden[/b][/color][/url]"
			return {"title": t["title"], "nodes": [_head(), banner, _layout([_post(t, true), _rtl(c, "#ffffff", 16)], _side(s))]}
	return {}


## Textblock mit Links (BBCode), optional auf farbigem Grund.
func _rtl(bb: String, bg := "", pad := 12) -> Control:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.selection_enabled = true
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.meta_underlined = false
	r.add_theme_font_override("normal_font", Flow.font_ui)
	r.add_theme_font_override("bold_font", Flow.font_ui_bold)
	r.add_theme_font_size_override("normal_font_size", 14)
	r.add_theme_font_size_override("bold_font_size", 14)
	r.add_theme_color_override("default_color", Color("1c1c1c"))
	r.add_theme_constant_override("line_separation", 3)
	r.meta_clicked.connect(_on_meta)
	r.text = bb
	if bg == "":
		return r
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg)
	sb.set_content_margin_all(pad)
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(r)
	return pc


func _head() -> Control:
	return _rtl("[font_size=24][b][url=go:/][color=#ff4500]thread[/color][color=#1c1c1c]it[/color][/url][/b][/font_size]          [color=#878a8c]Threadit durchsuchen                         Anmelden[/color]", "#ffffff", 12)


func _layout(main: Array, side: Array) -> Control:
	var m := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)
	var feed := VBoxContainer.new()
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed.add_theme_constant_override("separation", 10)
	h.add_child(feed)
	for n in main:
		feed.add_child(n)
	var sv := VBoxContainer.new()
	sv.custom_minimum_size.x = 250
	sv.add_theme_constant_override("separation", 10)
	h.add_child(sv)
	for n in side:
		sv.add_child(n)
	return m


func _vote(key: String, score: int) -> String:
	var v: int = votes.get(key, 0)
	var up := "#ff4500" if v == 1 else "#878a8c"
	var down := "#7193ff" if v == -1 else "#878a8c"
	var col := "#ff4500" if v == 1 else ("#7193ff" if v == -1 else "#1c1c1c")
	return "[url=vote:%s:1][color=%s]▲[/color][/url] [color=%s][b]%s[/b][/color] [url=vote:%s:-1][color=%s]▼[/color][/url]" % [key, up, col, kfmt(score + v), key, down]


func _sub_link(s: String) -> String:
	return "[url=go:/t/%s][color=#1c1c1c][b]t/%s[/b][/color][/url]" % [s, Threadit.SUBS[s]["name"]]


func _post(t: Dictionary, full: bool) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Color("cccccc")
	sb.set_border_width_all(1)
	pc.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	pc.add_child(h)
	var v := _rtl("[center]%s[/center]" % _vote(t["id"], t["score"]).replace("[/url] [color", "[/url]\n[color").replace("[/color] [url", "[/color]\n[url"), "#f8f9fa", 8)
	v.custom_minimum_size.x = 64
	v.size_flags_horizontal = Control.SIZE_FILL
	h.add_child(v)
	var meta := "[font_size=12]%s [color=#878a8c]· Gepostet von u/%s · %s[/color]%s[/font_size]" % [_sub_link(t["sub"]), esc(t["author"]), t["age"], "  [color=#46d160]· angepinnt[/color]" if t.get("pinned", false) else ""]
	var link := "/t/%s/%s" % [t["sub"], t["id"]]
	var title := "[font_size=18][b]%s[/b][/font_size]" % esc(t["title"])
	if not full:
		title = "[url=go:%s][color=#1c1c1c]%s[/color][/url]" % [link, title]
	var text := ""
	if full:
		for p in t["body"]:
			text += esc(p) + "\n"
	else:
		text = "[color=#555555]%s[/color]\n" % esc(t["body"][0])
	var flair := "   [bgcolor=#edeff1][font_size=12] %s [/font_size][/bgcolor]" % esc(t["flair"])
	var actions := "[font_size=12][url=go:%s][color=#878a8c][b]%s Kommentare[/b][/color][/url]      [color=#878a8c][b]Teilen      Speichern[/b][/color][/font_size]" % [link, t["ncom"]]
	h.add_child(_rtl("%s\n%s%s\n%s%s" % [meta, title, flair, text, actions], "#ffffff", 10))
	return pc


func _comments(list: Array, path: String, depth: int) -> String:
	var out := ""
	for i in list.size():
		var c: Array = list[i]
		var key := "%s.%d" % [path, i]
		var mod := "  [bgcolor=#46d160][color=#ffffff][b] MOD [/b][/color][/bgcolor]" if c[0] == "Mod_Bot" else ""
		var line := "[font_size=12][b]u/%s[/b]%s[/font_size]\n%s\n[font_size=12]%s[/font_size]\n" % [esc(c[0]), mod, esc(c[2]), _vote(key, c[1])]
		for d in depth:
			line = "[indent]" + line + "[/indent]"
		out += line + "\n"
		if c.size() > 3:
			out += _comments(c[3], key, depth + 1)
	return out


func _side(s: String) -> Array:
	if s != "":
		var S: Dictionary = Threadit.SUBS[s]
		return [_card("Über t/" + S["name"], S["color"], "%s\n\n[b]%s[/b]  [color=#878a8c]Mitglieder[/color]\n[b]%s[/b]  [color=#878a8c]Online[/color]\n\n[url=join][bgcolor=#0079d3][color=#ffffff][b]   Beitreten   [/b][/color][/bgcolor][/url]" % [esc(S["desc"]), S["members"], S["online"]])]
	var list := ""
	var n := 1
	for k in Threadit.SUBS:
		list += "%d.  %s  [color=#878a8c][font_size=12]%s[/font_size][/color]\n" % [n, _sub_link(k), Threadit.SUBS[k]["members"]]
		n += 1
	return [_card("Beliebte Communities", "#0079d3", list), _card("Heute im Trend", "#0079d3", "[url=go:/t/blank/simultan][color=#0079d3]Top 10 der Schachwelt simultan geschlagen[/color][/url]")]


func _card(title: String, color: String, bb: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(_rtl("[color=#ffffff][b]%s[/b][/color]" % esc(title), color, 10))
	v.add_child(_rtl(bb, "#ffffff", 12))
	return v


func _error_page(url: String) -> Dictionary:
	var b := "[font_size=20][b]Die Seite kann nicht angezeigt werden[/b][/font_size]\n\nDie Adresse [b]%s[/b] ist nicht erreichbar. Möglicherweise existiert sie nicht, oder der Server hat Angst vor 「　」.\n\n•  Prüfen Sie die Schreibweise der Adresse.\n•  Öffnen Sie die [url=go:/][color=#0000ee]Startseite von Threadit[/color][/url].\n\n[color=#878a8c]HTTP 404 · Datei nicht gefunden[/color]" % esc(url)
	return {"title": "Seite nicht gefunden", "nodes": [_rtl(b, "#ffffff", 30)]}
