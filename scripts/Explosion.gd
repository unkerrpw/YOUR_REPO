extends Node2D

var particles: Array = []
var lifetime: float = 0.55
var elapsed: float = 0.0
var ex_color: Color = Color(1, 0.55, 0.1)
var ex_radius: float = 60.0

func _ready():
	ex_radius = get_meta("radius") if has_meta("radius") else 60.0
	ex_color  = get_meta("color")  if has_meta("color")  else Color(1, 0.55, 0.1)
	lifetime  = 0.4 + ex_radius * 0.003
	
	var count = int(clampf(ex_radius * 0.7, 8, 40))
	for i in range(count):
		var ang = randf() * TAU
		var spd = randf_range(60, 280) * (ex_radius / 55.0)
		var sz  = randf_range(3, 9) * (ex_radius / 55.0)
		var hue_shift = randf_range(-0.08, 0.08)
		var pc = Color.from_hsv(
			fmod(ex_color.h + hue_shift, 1.0),
			randf_range(0.6, 1.0),
			randf_range(0.8, 1.0)
		)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"sz": sz, "col": pc, "ring": false
		})
	# Shockwave ring
	particles.append({"pos": Vector2.ZERO, "vel": Vector2.ZERO,
		"sz": ex_radius, "col": Color(1, 0.95, 0.6, 0.7), "ring": true})
	# Bright core flash
	particles.append({"pos": Vector2.ZERO, "vel": Vector2.ZERO,
		"sz": ex_radius * 0.55, "col": Color(1, 1, 0.9, 0.9), "ring": false, "core": true})

func _process(delta):
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	var t = elapsed / lifetime
	for p in particles:
		p.pos += p.vel * delta
		p.vel *= 0.88
	queue_redraw()

func _draw():
	var t = elapsed / lifetime
	for p in particles:
		var alpha = (1.0 - t)
		var c = p.col
		if p.get("ring", false):
			var rr = p.sz * (1.0 + t * 0.9)
			draw_arc(Vector2.ZERO, rr, 0, TAU, 40, Color(c.r, c.g, c.b, alpha * 0.55 * (1 - t)), 4.0)
		elif p.get("core", false):
			var cr = p.sz * (1.0 - t * 0.8)
			if cr > 0:
				draw_circle(Vector2.ZERO, cr, Color(c.r, c.g, c.b, alpha * 0.4 * (1 - t)))
		else:
			var sz = p.sz * (1.0 - t * 0.5)
			if sz > 0.1:
				draw_circle(p.pos, sz, Color(c.r, c.g, c.b, alpha))
