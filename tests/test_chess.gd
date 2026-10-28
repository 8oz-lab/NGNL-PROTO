extends SceneTree
## Prüft die Zuggenerierung mit bekannten Perft-Zahlen und misst die Bot-Zeit.
## Aufruf: godot --headless --path . --script res://tests/test_chess.gd

func perft(e: ChessEngine, d: int) -> int:
	if d == 0:
		return 1
	var n := 0
	for m in e.legal():
		e.make(m)
		n += perft(e, d - 1)
		e.undo(m)
	return n


func _init() -> void:
	var cases := [
		["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 3, 8902],
		["r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", 2, 2039],
		["8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1", 4, 43238],
		["r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", 3, 9467],
		["rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8", 2, 1486],
	]
	var ok := true
	for c in cases:
		var e := ChessEngine.new(c[0])
		var n := perft(e, c[1])
		print("perft ", c[1], ": ", n, " erwartet ", c[2], " ", "OK" if n == c[2] else "FEHLER")
		ok = ok and n == c[2]
	var e := ChessEngine.new()
	for i in 6:
		var t := Time.get_ticks_msec()
		var m := e.best_move(1500)
		print(e.notate(m), " ", Time.get_ticks_msec() - t, " ms")
		e.make(m)
	print("ALLE OK" if ok else "FEHLER GEFUNDEN")
	quit()
