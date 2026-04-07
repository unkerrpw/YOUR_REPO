extends Node2D

func _ready():
	queue_redraw()

func _draw():
	var ss = get_meta("screen_size") if has_meta("screen_size") else Vector2(414, 896)
	var c = Color(0.15, 0.15, 0.3, 0.18)
	for x in range(0, int(ss.x) + 1, 40):
		draw_line(Vector2(x, 0), Vector2(x, ss.y), c, 1)
	for y in range(0, int(ss.y) + 1, 40):
		draw_line(Vector2(0, y), Vector2(ss.x, y), c, 1)
