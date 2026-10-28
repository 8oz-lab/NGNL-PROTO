class_name ChessEngine
extends RefCounted
## Schach-Regeln und Bot (Alpha-Beta mit Schlagzug-Suche, etwas Zufall für menschliche Fehler).
## Brett als 10×12-Feld: Index 21..98, Reihe 0 = 8. Reihe (oben). Figuren: 1–6 Weiß (B S L T D K), +8 = Schwarz.

const EMPTY := 0
const OFF := 7
const P := 1
const N := 2
const B := 3
const R := 4
const Q := 5
const K := 6
const BLACK := 8

const F_DOUBLE := 1
const F_EP := 2
const F_CASTLE_K := 3
const F_CASTLE_Q := 4

const KN := [-21, -19, -12, -8, 8, 12, 19, 21]
const KG := [-11, -10, -9, -1, 1, 9, 10, 11]
const DIAG := [-11, -9, 9, 11]
const ORTH := [-10, -1, 1, 10]
const VAL := [0, 100, 320, 330, 500, 900, 0]

const PST := {
	1: [0,0,0,0,0,0,0,0, 50,50,50,50,50,50,50,50, 10,10,20,30,30,20,10,10, 5,5,10,25,25,10,5,5, 0,0,0,20,20,0,0,0, 5,-5,-10,0,0,-10,-5,5, 5,10,10,-20,-20,10,10,5, 0,0,0,0,0,0,0,0],
	2: [-50,-40,-30,-30,-30,-30,-40,-50, -40,-20,0,0,0,0,-20,-40, -30,0,10,15,15,10,0,-30, -30,5,15,20,20,15,5,-30, -30,0,15,20,20,15,0,-30, -30,5,10,15,15,10,5,-30, -40,-20,0,5,5,0,-20,-40, -50,-40,-30,-30,-30,-30,-40,-50],
	3: [-20,-10,-10,-10,-10,-10,-10,-20, -10,0,0,0,0,0,0,-10, -10,0,5,10,10,5,0,-10, -10,5,5,10,10,5,5,-10, -10,0,10,10,10,10,0,-10, -10,10,10,10,10,10,10,-10, -10,5,0,0,0,0,5,-10, -20,-10,-10,-10,-10,-10,-10,-20],
	4: [0,0,0,0,0,0,0,0, 5,10,10,10,10,10,10,5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, 0,0,0,5,5,0,0,0],
	5: [-20,-10,-10,-5,-5,-10,-10,-20, -10,0,0,0,0,0,0,-10, -10,0,5,5,5,5,0,-10, -5,0,5,5,5,5,0,-5, 0,0,5,5,5,5,0,-5, -10,5,5,5,5,5,0,-10, -10,0,5,0,0,0,0,-10, -20,-10,-10,-5,-5,-10,-10,-20],
	6: [-30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30, -20,-30,-30,-40,-40,-30,-30,-20, -10,-20,-20,-20,-20,-20,-20,-10, 20,20,0,0,0,0,20,20, 20,30,10,0,0,10,30,20],
	7: [-50,-40,-30,-20,-20,-30,-40,-50, -30,-20,-10,0,0,-10,-20,-30, -30,-10,20,30,30,20,-10,-30, -30,-10,30,40,40,30,-10,-30, -30,-10,30,40,40,30,-10,-30, -30,-10,20,30,30,20,-10,-30, -30,-30,0,0,0,0,-30,-30, -50,-30,-30,-30,-30,-30,-30,-50],
}

var board := PackedByteArray()
var white := true
var castle := 15        # 1 = Weiß kurz, 2 = Weiß lang, 4 = Schwarz kurz, 8 = Schwarz lang
var ep := -1
var half := 0
var king_w := 95
var king_b := 25
var _stack: Array = []
var _cr := PackedByteArray()
var _deadline := 0
var _aborted := false


func _init(fen := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") -> void:
	_cr.resize(120)
	_cr.fill(15)
	_cr[95] = 12
	_cr[98] = 14
	_cr[91] = 13
	_cr[25] = 3
	_cr[28] = 11
	_cr[21] = 7
	setup(fen)


static func sq(r: int, f: int) -> int:
	return 21 + r * 10 + f


static func is_white_piece(p: int) -> bool:
	return p >= 1 and p <= 6


static func is_black_piece(p: int) -> bool:
	return p >= 9 and p <= 14


static func type_of(p: int) -> int:
	return p & 7


func setup(fen: String) -> void:
	board.resize(120)
	board.fill(OFF)
	var parts := fen.split(" ")
	var rows := parts[0].split("/")
	var letters := "pnbrqk"
	for r in 8:
		var f := 0
		for ch in rows[r]:
			if ch.is_valid_int():
				for i in int(ch):
					board[sq(r, f)] = EMPTY
					f += 1
			else:
				var t := letters.find(ch.to_lower()) + 1
				var p := t if ch == ch.to_upper() else t + BLACK
				board[sq(r, f)] = p
				if p == K:
					king_w = sq(r, f)
				elif p == K + BLACK:
					king_b = sq(r, f)
				f += 1
	white = parts[1] == "w"
	castle = 0
	if parts[2].contains("K"): castle |= 1
	if parts[2].contains("Q"): castle |= 2
	if parts[2].contains("k"): castle |= 4
	if parts[2].contains("q"): castle |= 8
	ep = -1
	if parts[3] != "-":
		ep = sq(8 - int(parts[3][1]), parts[3].unicode_at(0) - 97)
	half = int(parts[4]) if parts.size() > 4 else 0
	_stack.clear()


func copy() -> ChessEngine:
	var e := ChessEngine.new()
	e.board = board.duplicate()
	e.white = white
	e.castle = castle
	e.ep = ep
	e.half = half
	e.king_w = king_w
	e.king_b = king_b
	return e


# ------------------------------------------------------------ Züge (als Zahl kodiert)

static func mv(from: int, to: int, piece: int, cap: int, promo := 0, flag := 0) -> int:
	return from | (to << 7) | (piece << 14) | (cap << 18) | (promo << 22) | (flag << 26)

static func m_from(m: int) -> int: return m & 127
static func m_to(m: int) -> int: return (m >> 7) & 127
static func m_piece(m: int) -> int: return (m >> 14) & 15
static func m_cap(m: int) -> int: return (m >> 18) & 15
static func m_promo(m: int) -> int: return (m >> 22) & 15
static func m_flag(m: int) -> int: return (m >> 26) & 7


func attacked(t: int, by_white: bool) -> bool:
	var add := 0 if by_white else BLACK
	if by_white:
		if board[t + 9] == P or board[t + 11] == P:
			return true
	elif board[t - 9] == P + BLACK or board[t - 11] == P + BLACK:
		return true
	for d in KN:
		if board[t + d] == N + add:
			return true
	for d in KG:
		if board[t + d] == K + add:
			return true
	for d in DIAG:
		var x: int = t + d
		while board[x] == EMPTY:
			x += d
		if board[x] == B + add or board[x] == Q + add:
			return true
	for d in ORTH:
		var x: int = t + d
		while board[x] == EMPTY:
			x += d
		if board[x] == R + add or board[x] == Q + add:
			return true
	return false


func _mine(p: int) -> bool:
	return is_white_piece(p) if white else is_black_piece(p)


func _theirs(p: int) -> bool:
	return is_black_piece(p) if white else is_white_piece(p)


func gen(caps_only := false) -> PackedInt32Array:
	var ms := PackedInt32Array()
	var add := 0 if white else BLACK
	for r in 8:
		for f in 8:
			var from := 21 + r * 10 + f
			var p: int = board[from]
			if not _mine(p):
				continue
			var t := type_of(p)
			if t == P:
				var dir := -10 if white else 10
				var last := 1 if white else 6
				var start := 6 if white else 1
				var one := from + dir
				if board[one] == EMPTY:
					if r == last:
						for pr in [Q, N, R, B]:
							ms.append(mv(from, one, p, 0, pr + add))
					elif not caps_only:
						ms.append(mv(from, one, p, 0))
						if r == start and board[one + dir] == EMPTY:
							ms.append(mv(from, one + dir, p, 0, 0, F_DOUBLE))
				for to in [one - 1, one + 1]:
					if _theirs(board[to]):
						if r == last:
							for pr in [Q, N, R, B]:
								ms.append(mv(from, to, p, board[to], pr + add))
						else:
							ms.append(mv(from, to, p, board[to]))
					elif to == ep:
						ms.append(mv(from, to, p, P + (BLACK if white else 0), 0, F_EP))
			elif t == N or t == K:
				for d in (KN if t == N else KG):
					var to: int = from + d
					var c: int = board[to]
					if c == EMPTY:
						if not caps_only:
							ms.append(mv(from, to, p, 0))
					elif _theirs(c):
						ms.append(mv(from, to, p, c))
				if t == K and not caps_only:
					if white and from == 95:
						if castle & 1 and board[96] == EMPTY and board[97] == EMPTY and board[98] == R and not attacked(95, false) and not attacked(96, false) and not attacked(97, false):
							ms.append(mv(95, 97, p, 0, 0, F_CASTLE_K))
						if castle & 2 and board[94] == EMPTY and board[93] == EMPTY and board[92] == EMPTY and board[91] == R and not attacked(95, false) and not attacked(94, false) and not attacked(93, false):
							ms.append(mv(95, 93, p, 0, 0, F_CASTLE_Q))
					elif not white and from == 25:
						if castle & 4 and board[26] == EMPTY and board[27] == EMPTY and board[28] == R + BLACK and not attacked(25, true) and not attacked(26, true) and not attacked(27, true):
							ms.append(mv(25, 27, p, 0, 0, F_CASTLE_K))
						if castle & 8 and board[24] == EMPTY and board[23] == EMPTY and board[22] == EMPTY and board[21] == R + BLACK and not attacked(25, true) and not attacked(24, true) and not attacked(23, true):
							ms.append(mv(25, 23, p, 0, 0, F_CASTLE_Q))
			else:
				var dirs: Array = DIAG if t == B else (ORTH if t == R else KG)
				for d in dirs:
					var to: int = from + d
					while board[to] == EMPTY:
						if not caps_only:
							ms.append(mv(from, to, p, 0))
						to += d
					if _theirs(board[to]):
						ms.append(mv(from, to, p, board[to]))
	return ms


func make(m: int) -> void:
	_stack.append([castle, ep, half])
	var from := m_from(m)
	var to := m_to(m)
	var piece := m_piece(m)
	var promo := m_promo(m)
	var flag := m_flag(m)
	board[to] = promo if promo else piece
	board[from] = EMPTY
	if flag == F_EP:
		board[to + (10 if white else -10)] = EMPTY
	elif flag == F_CASTLE_K:
		if white:
			board[96] = R
			board[98] = EMPTY
		else:
			board[26] = R + BLACK
			board[28] = EMPTY
	elif flag == F_CASTLE_Q:
		if white:
			board[94] = R
			board[91] = EMPTY
		else:
			board[24] = R + BLACK
			board[21] = EMPTY
	if piece == K:
		king_w = to
	elif piece == K + BLACK:
		king_b = to
	castle &= _cr[from] & _cr[to]
	ep = (from + to) / 2 if flag == F_DOUBLE else -1
	half = 0 if (type_of(piece) == P or m_cap(m) != 0) else half + 1
	white = not white


func undo(m: int) -> void:
	var st: Array = _stack.pop_back()
	castle = st[0]
	ep = st[1]
	half = st[2]
	white = not white
	var from := m_from(m)
	var to := m_to(m)
	var piece := m_piece(m)
	var flag := m_flag(m)
	board[from] = piece
	if flag == F_EP:
		board[to] = EMPTY
		board[to + (10 if white else -10)] = m_cap(m)
	else:
		board[to] = m_cap(m)
	if flag == F_CASTLE_K:
		if white:
			board[98] = R
			board[96] = EMPTY
		else:
			board[28] = R + BLACK
			board[26] = EMPTY
	elif flag == F_CASTLE_Q:
		if white:
			board[91] = R
			board[94] = EMPTY
		else:
			board[21] = R + BLACK
			board[24] = EMPTY
	if piece == K:
		king_w = from
	elif piece == K + BLACK:
		king_b = from


## Steht nach einem Zug der König der Seite, die gerade gezogen hat, im Schach?
func _left_in_check() -> bool:
	return attacked(king_b if white else king_w, white)


func in_check() -> bool:
	return attacked(king_w if white else king_b, not white)


func legal() -> PackedInt32Array:
	var out := PackedInt32Array()
	for m in gen():
		make(m)
		if not _left_in_check():
			out.append(m)
		undo(m)
	return out


func insufficient() -> bool:
	var minors := 0
	for i in range(21, 99):
		var p: int = board[i]
		if p == EMPTY or p == OFF:
			continue
		var t := type_of(p)
		if t == K:
			continue
		if t == N or t == B:
			minors += 1
		else:
			return false
	return minors <= 1


func key() -> String:
	return board.hex_encode() + ("w" if white else "b") + str(castle) + str(ep)


# ------------------------------------------------------------ Bewertung und Suche

func evaluate() -> int:
	var score := 0
	var heavy := 0
	for i in range(21, 99):
		var p: int = board[i]
		if p != EMPTY and p != OFF:
			var t := type_of(p)
			if t != P and t != K:
				heavy += VAL[t]
	var endgame := heavy <= 1300
	for r in 8:
		for f in 8:
			var p: int = board[21 + r * 10 + f]
			if p == EMPTY:
				continue
			var t := type_of(p)
			var table: Array = PST[7 if (t == K and endgame) else t]
			if is_white_piece(p):
				score += VAL[t] + table[r * 8 + f]
			else:
				score -= VAL[t] + table[(7 - r) * 8 + f]
	return score if white else -score


func _order_key(m: int) -> int:
	var k := 0
	if m_cap(m):
		k = 1000 + 10 * VAL[type_of(m_cap(m))] - VAL[type_of(m_piece(m))]
	if m_promo(m):
		k += 800
	return k


func _ordered(ms: PackedInt32Array) -> Array:
	var arr := Array(ms)
	arr.sort_custom(func(a, b): return _order_key(a) > _order_key(b))
	return arr


func _quiesce(alpha: int, beta: int, depth: int) -> int:
	var stand := evaluate()
	if stand >= beta:
		return stand
	if stand > alpha:
		alpha = stand
	if depth >= 3:
		return alpha
	for m in _ordered(gen(true)):
		make(m)
		if _left_in_check():
			undo(m)
			continue
		var v := -_quiesce(-beta, -alpha, depth + 1)
		undo(m)
		if v >= beta:
			return v
		if v > alpha:
			alpha = v
	return alpha


func _search(depth: int, alpha: int, beta: int, ply: int) -> int:
	if Time.get_ticks_msec() > _deadline:
		_aborted = true
		return 0
	if half >= 100:
		return 0
	if depth <= 0:
		return _quiesce(alpha, beta, 0)
	var any := false
	for m in _ordered(gen()):
		make(m)
		if _left_in_check():
			undo(m)
			continue
		any = true
		var v := -_search(depth - 1, -beta, -alpha, ply + 1)
		undo(m)
		if _aborted:
			return 0
		if v >= beta:
			return v
		if v > alpha:
			alpha = v
	if not any:
		return -100000 + ply if in_check() else 0
	return alpha


## Bester Zug mit Zeitlimit; tiefer rechnen, solange Zeit bleibt. Etwas Zufall macht den Bot menschlicher.
func best_move(time_ms := 1500, max_depth := 3) -> int:
	var moves := legal()
	if moves.is_empty():
		return 0
	_deadline = Time.get_ticks_msec() + time_ms
	var best_scored: Array = []
	for depth in range(1, max_depth + 1):
		_aborted = false
		var scored: Array = []
		for m in _ordered(moves):
			make(m)
			var v := -_search(depth - 1, -1000000, 1000000, 1)
			undo(m)
			if _aborted:
				break
			scored.append([m, v + randi_range(-20, 20)])
		if _aborted:
			break
		scored.sort_custom(func(a, b): return a[1] > b[1])
		best_scored = scored
	if best_scored.is_empty():
		return moves[0]
	var top: int = best_scored[0][1]
	if absi(top) < 50000 and randf() < 0.12:
		var ok := best_scored.filter(func(x): return x[1] > top - 130)
		return ok[randi() % ok.size()][0]
	return best_scored[0][0]


func notate(m: int) -> String:
	var names := ["", "", "S", "L", "T", "D", "K"]
	if m_flag(m) == F_CASTLE_K:
		return "O-O"
	if m_flag(m) == F_CASTLE_Q:
		return "O-O-O"
	var s: String = names[type_of(m_piece(m))] + _sq_name(m_from(m)) + ("×" if m_cap(m) else "–") + _sq_name(m_to(m))
	if m_promo(m):
		s += names[type_of(m_promo(m))]
	return s


static func _sq_name(i: int) -> String:
	return "abcdefgh"[(i - 21) % 10] + str(8 - (i - 21) / 10)
