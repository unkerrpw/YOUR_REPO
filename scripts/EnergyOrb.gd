extends Area2D

signal collected

var pulse: float = 0.0
var float_offset: float = 0.0
var base_y: float = 0.0
var _collected: bool = false

func _ready():
	base_y = position.y
	float_offset = randf() * TAU
	body_entered.connect(_on_body)
	queue_redraw()

func _process(delta):
	pulse += delta * 2.8
	float_offset += delta
	position.y = base_y + sin(float_offset * 2.0) * 5.0
	queue_redraw()

func _draw():
	var r = 14.0
	var t = (sin(pulse) + 1.0) * 0.5
	# Outer glow
	for i in range(5):
		var gr = r + 4 + i * 3.5 + t * 3
		draw_circle(Vector2.ZERO, gr, Color(1.0, 0.85, 0.0, 0.06 - i * 0.01))
	# Main orb
	var c1 = Color(1.0, 0.85, 0.15)
	var c2 = Color(1.0, 0.5, 0.05)
	var bc = c1.lerp(c2, t)
	draw_circle(Vector2.ZERO, r, bc)
	# Inner shine
	draw_circle(Vector2(-3, -4), r * 0.38, Color(1, 1, 0.7, 0.5))
	# Ring
	draw_arc(Vector2.ZERO, r + 3, 0, TAU, 32, Color(1, 0.9, 0.3, 0.5 + t * 0.4), 2.0)
	# Lightning symbol
	draw_string(ThemeDB.fallback_font, Vector2(-5, 6), "⚡", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _on_body(_body):
	if _collected: return
	_collected = true
	collected.emit()
