class_name IconArt
## Kleine Symbole für Desktop und Ordner, direkt gezeichnet (Mittelpunkt c, etwa 40 × 36 Pixel).


static func draw(ci: CanvasItem, kind: String, c: Vector2) -> void:
	match kind:
		"pc":
			ci.draw_rect(Rect2(c + Vector2(-18, -16), Vector2(36, 26)), Win98.FACE)
			ci.draw_rect(Rect2(c + Vector2(-18, -16), Vector2(36, 26)), Color.BLACK, false, 1.0)
			ci.draw_rect(Rect2(c + Vector2(-14, -12), Vector2(28, 18)), Win98.NAVY)
			ci.draw_rect(Rect2(c + Vector2(-10, 12), Vector2(20, 5)), Win98.SHADE)
		"mail":
			ci.draw_rect(Rect2(c + Vector2(-18, -12), Vector2(36, 24)), Color.WHITE)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-18, -12), c + Vector2(0, 2), c + Vector2(18, -12)]), Color.BLACK, 1.5)
			ci.draw_rect(Rect2(c + Vector2(-18, -12), Vector2(36, 24)), Color.BLACK, false, 1.0)
		"games":
			_folder(ci, c, Color("ffd36b"))
			ci.draw_string(Flow.font_ui, c + Vector2(-6, 9), "♟", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)
		"folder":
			_folder(ci, c, Color("ffd36b"))
		"text":
			ci.draw_rect(Rect2(c + Vector2(-13, -17), Vector2(26, 34)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(-13, -17), Vector2(26, 34)), Color.BLACK, false, 1.0)
			for i in 5:
				ci.draw_line(c + Vector2(-8, -10 + i * 6), c + Vector2(8 - (i % 2) * 5, -10 + i * 6), Win98.SHADE, 1.0)
		"trash", "trash_full":
			ci.draw_rect(Rect2(c + Vector2(-12, -10), Vector2(24, 26)), Color("dfdfdf"))
			ci.draw_rect(Rect2(c + Vector2(-12, -10), Vector2(24, 26)), Win98.SHADE, false, 1.0)
			for x in [-6, 0, 6]:
				ci.draw_line(c + Vector2(x, -6), c + Vector2(x, 12), Win98.SHADE, 1.0)
			ci.draw_rect(Rect2(c + Vector2(-15, -14), Vector2(30, 5)), Win98.FACE)
			ci.draw_rect(Rect2(c + Vector2(-15, -14), Vector2(30, 5)), Win98.SHADE, false, 1.0)
			if kind == "trash_full":
				ci.draw_rect(Rect2(c + Vector2(-8, -20), Vector2(10, 7)), Color.WHITE)
				ci.draw_rect(Rect2(c + Vector2(0, -19), Vector2(9, 6)), Color("ffd36b"))
		"lol":
			# Goldenes Wappen mit türkisem Edelstein
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				var r := 18.0 if i % 2 == 0 else 10.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			ci.draw_circle(c, 19, Color("010a13"))
			ci.draw_colored_polygon(pts, Color("c8aa6e"))
			ci.draw_circle(c, 6.5, Color("0ac8b9"))
			ci.draw_arc(c, 19, 0, TAU, 32, Color("785a28"), 1.5)
		"cs":
			ci.draw_rect(Rect2(c + Vector2(-18, -16), Vector2(36, 32)), Color("2b2f33"))
			ci.draw_arc(c, 11, 0, TAU, 32, Color("f0a830"), 2.0)
			ci.draw_line(c + Vector2(-15, 0), c + Vector2(-5, 0), Color("f0a830"), 2.0)
			ci.draw_line(c + Vector2(5, 0), c + Vector2(15, 0), Color("f0a830"), 2.0)
			ci.draw_line(c + Vector2(0, -15), c + Vector2(0, -5), Color("f0a830"), 2.0)
			ci.draw_line(c + Vector2(0, 5), c + Vector2(0, 15), Color("f0a830"), 2.0)
		"web":
			ci.draw_circle(c, 16, Color("1a5fb4"))
			ci.draw_arc(c, 16, 0, TAU, 32, Color("0b2e66"), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -9), c + Vector2(-1, -12), c + Vector2(2, -4), c + Vector2(-4, 2), c + Vector2(-11, -2)]), Color("4fbf5a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(4, 2), c + Vector2(12, 0), c + Vector2(10, 9), c + Vector2(3, 11)]), Color("4fbf5a"))
			ci.draw_arc(c + Vector2(0, 4), 22, -2.4, -0.7, 16, Color("ffd36b"), 2.0)
		_:
			ci.draw_rect(Rect2(c + Vector2(-14, -14), Vector2(28, 28)), Win98.FACE)


static func _folder(ci: CanvasItem, c: Vector2, col: Color) -> void:
	ci.draw_rect(Rect2(c + Vector2(-18, -14), Vector2(14, 6)), col.darkened(0.08))
	ci.draw_rect(Rect2(c + Vector2(-18, -10), Vector2(36, 24)), col)
	ci.draw_rect(Rect2(c + Vector2(-18, -10), Vector2(36, 24)), col.darkened(0.45), false, 1.0)
