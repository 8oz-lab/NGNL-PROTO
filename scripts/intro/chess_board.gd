class_name ChessBoard
extends Control
## Schachbrett im Anime-Look: Figuren anklicken oder ziehen, Bot rechnet im Hintergrund.

signal move_played(text: String, mine: bool)
signal status_changed(text: String)
signal game_over(result: String)   # "win", "lose", "draw"

const LIGHT := Color("a9e8d6")
const DARK := Color("4d7fd6")
const GLYPH := {1: "♟", 2: "♞", 3: "♝", 4: "♜", 5: "♛", 6: "♚"}

var engine := ChessEngine.new()
var over := false
var thinking := false
var _sel := -1
var _targets: Array = []
var _last := 0
var _drag_from := -1
var _drag_pos := Vector2.ZERO
var _press_pos := Vector2.ZERO
var _seen := {}
var _thread: Thread
var _hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(440, 440)
	reset()


func reset(fen := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") -> void:
	engine.setup(fen)
	over = false
	thinking = false
	_sel = -1
	_targets = []
	_last = 0
	_seen = {engine.key(): 1}
	status_changed.emit("Ihr spielt Weiß. Gewinnt diese Partie, dann öffnet sich die Tür.")
	queue_redraw()


func _cell() -> float:
	return minf(size.x, size.y) / 8.0


func _origin() -> Vector2:
	return (size - Vector2.ONE * _cell() * 8.0) * 0.5


func _square_at(p: Vector2) -> int:
	var c := _cell()
	var q := (p - _origin()) / c
	if q.x < 0 or q.y < 0 or q.x >= 8 or q.y >= 8:
		return -1
	return ChessEngine.sq(int(q.y), int(q.x))


func _rect_of(i: int) -> Rect2:
	var c := _cell()
	var r := (i - 21) / 10
	var f := (i - 21) % 10
	return Rect2(_origin() + Vector2(f, r) * c, Vector2(c, c))


func _gui_input(event: InputEvent) -> void:
	if over or thinking or not engine.white:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		var i := _square_at(mb.position)
		if mb.pressed:
			_press_pos = mb.position
			var target := _target_move(i)
			if _sel != -1 and target != 0:
				_play(target)
				return
			if i != -1 and ChessEngine.is_white_piece(engine.board[i]):
				_select(i)
				_drag_from = i
				_drag_pos = mb.position
			else:
				_select(-1)
		else:
			if _drag_from != -1 and mb.position.distance_to(_press_pos) > 6.0:
				var target := _target_move(i)
				if target != 0:
					_play(target)
			_drag_from = -1
			queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion:
		_hover = _square_at((event as InputEventMouseMotion).position)
		if _drag_from != -1:
			_drag_pos = (event as InputEventMouseMotion).position
		queue_redraw()


func _select(i: int) -> void:
	_sel = i
	_targets = []
	if i != -1:
		for m in engine.legal():
			if ChessEngine.m_from(m) == i:
				_targets.append(m)
	queue_redraw()


func _target_move(i: int) -> int:
	for m in _targets:
		if ChessEngine.m_to(m) == i:
			var promo := ChessEngine.m_promo(m)
			if promo == 0 or ChessEngine.type_of(promo) == ChessEngine.Q:
				return m
	return 0


func _play(m: int) -> void:
	var mine := engine.white
	var text := engine.notate(m)
	engine.make(m)
	_last = m
	_sel = -1
	_targets = []
	_drag_from = -1
	var k := engine.key()
	_seen[k] = _seen.get(k, 0) + 1
	_sound(m)
	if engine.in_check():
		text += "#" if engine.legal().is_empty() else "+"
	move_played.emit(text, mine)
	queue_redraw()
	if _check_end():
		return
	if not engine.white:
		thinking = true
		status_changed.emit("??? denkt nach …")
		var snapshot := engine.copy()
		_thread = Thread.new()
		_thread.start(func(): return snapshot.best_move(1400))
		_wait_for_bot()
	else:
		status_changed.emit("Schach! Ihr seid am Zug." if engine.in_check() else "Ihr seid am Zug.")


func _wait_for_bot() -> void:
	await get_tree().create_timer(0.45).timeout
	while _thread.is_alive():
		await get_tree().process_frame
	var m: int = _thread.wait_to_finish()
	_thread = null
	thinking = false
	if not over and m != 0:
		_play(m)


func _sound(m: int) -> void:
	var p := randf_range(0.94, 1.06)
	if ChessEngine.m_flag(m) == ChessEngine.F_CASTLE_K or ChessEngine.m_flag(m) == ChessEngine.F_CASTLE_Q:
		Flow.play("clack", -2, p)
		get_tree().create_timer(0.12).timeout.connect(func(): Flow.play("clack", -3, p * 0.95))
	elif ChessEngine.m_cap(m):
		Flow.play("capture", 0, p)
	else:
		Flow.play("clack", -2, p)
	if engine.in_check():
		get_tree().create_timer(0.09).timeout.connect(func(): Flow.play("check", -4))


func _check_end() -> bool:
	if engine.legal().is_empty():
		if engine.in_check():
			_finish("lose" if engine.white else "win", "Schachmatt.")
		else:
			_finish("draw", "Patt.")
		return true
	if engine.half >= 100:
		_finish("draw", "50-Züge-Regel.")
		return true
	if engine.insufficient():
		_finish("draw", "Zu wenig Material für ein Matt.")
		return true
	if _seen.get(engine.key(), 0) >= 3:
		_finish("draw", "Dreifache Stellungswiederholung.")
		return true
	return false


func _finish(result: String, why: String) -> void:
	over = true
	match result:
		"win":
			Flow.play("mate")
			status_changed.emit(why + " Ihr habt gewonnen! ??? schreibt: „Genau euch habe ich gesucht.“ … Moment. Das Brett?")
		"lose":
			status_changed.emit(why + " ??? gewinnt. „Schade. Wollt ihr es noch einmal versuchen?“")
		_:
			status_changed.emit("Remis. " + why + " „Ein Unentschieden reicht mir nicht. Noch einmal.“")
	game_over.emit(result)
	queue_redraw()


func resign() -> void:
	if not over:
		_finish("lose", "Ihr habt aufgegeben.")


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


func _draw() -> void:
	var c := _cell()
	var check_sq := -1
	if engine.in_check():
		check_sq = engine.king_w if engine.white else engine.king_b
	var font := Flow.font_ui
	for r in 8:
		for f in 8:
			var i := ChessEngine.sq(r, f)
			var rect := _rect_of(i)
			draw_rect(rect, DARK if (r + f) % 2 else LIGHT)
			if _last and (ChessEngine.m_from(_last) == i or ChessEngine.m_to(_last) == i):
				draw_rect(rect, Color(1, 1, 1, 0.28))
				draw_rect(rect.grow(-1), Color(1.0, 0.83, 0.42), false, 2.0)
			if i == check_sq:
				draw_circle(rect.get_center(), c * 0.5, Color(0.9, 0.1, 0.15, 0.55))
			if i == _sel:
				draw_rect(rect.grow(-1.5), Color("f2a23c"), false, 3.0)
			if f == 0:
				draw_string(font, rect.position + Vector2(3, 12), str(8 - r), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LIGHT if (r + f) % 2 else DARK)
			if r == 7:
				draw_string(font, rect.end - Vector2(10, 4), "abcdefgh"[f], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LIGHT if (r + f) % 2 else DARK)
	for m in _targets:
		var rect := _rect_of(ChessEngine.m_to(m))
		if engine.board[ChessEngine.m_to(m)] == ChessEngine.EMPTY and ChessEngine.m_flag(m) != ChessEngine.F_EP:
			draw_circle(rect.get_center(), c * 0.13, Color(0.1, 0.17, 0.43, 0.5))
		else:
			draw_arc(rect.get_center(), c * 0.42, 0, TAU, 32, Color("f2a23c"), 3.0)
		if ChessEngine.m_to(m) == _hover:
			draw_rect(rect.grow(-2), Color(1, 1, 1, 0.8), false, 3.0)
	for r in 8:
		for f in 8:
			var i := ChessEngine.sq(r, f)
			var p: int = engine.board[i]
			if p == ChessEngine.EMPTY or i == _drag_from:
				continue
			_piece(p, _rect_of(i).get_center(), c)
	if _drag_from != -1 and _drag_pos.distance_to(_press_pos) > 6.0:
		_piece(engine.board[_drag_from], _drag_pos, c * 1.12)
	# Scanlines wie auf einem Röhrenmonitor
	var o := _origin()
	for y in range(0, int(c * 8), 3):
		draw_line(o + Vector2(0, y), o + Vector2(c * 8, y), Color(1, 1, 1, 0.05))


func _piece(p: int, center: Vector2, c: float) -> void:
	var font := Flow.font_ui
	var fs := int(c * 0.78)
	var g: String = GLYPH[ChessEngine.type_of(p)]
	var ts := font.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := center + Vector2(-ts.x * 0.5, fs * 0.36)
	if ChessEngine.is_white_piece(p):
		draw_string_outline(font, pos, g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color("23409a"))
		draw_string(font, pos, g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	else:
		draw_string_outline(font, pos, g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0.56, 0.7, 0.94, 0.7))
		draw_string(font, pos, g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("1b2c6e"))
