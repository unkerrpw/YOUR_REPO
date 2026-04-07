extends Node2D

const BallScene     = preload("res://scenes/Ball.tscn")
const PlatformScene = preload("res://scenes/Platform.tscn")
const OrbScene      = preload("res://scenes/EnergyOrb.tscn")

var ball: CharacterBody2D = null
var screen_size: Vector2
var score: int = 0
var platform_list: Array = []
var touches: Dictionary = {}

var score_label: Label
var energy_fill: ColorRect
var cam: Camera2D
var full_label: Label

func _ready():
	screen_size = get_viewport_rect().size
	_setup_bg()
	_setup_cam()
	_setup_ui()
	_spawn_ball()
	_spawn_platforms()
	_spawn_orbs(6)

func _setup_cam():
	cam = Camera2D.new()
	cam.position = screen_size / 2
	add_child(cam)

func _setup_bg():
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.14)
	bg.size = screen_size
	bg.z_index = -10
	add_child(bg)
	# Subtle grid lines
	var grid = Node2D.new()
	grid.z_index = -9
	grid.set_script(load("res://scripts/Grid.gd"))
	grid.set_meta("screen_size", screen_size)
	add_child(grid)

func _setup_ui():
	var ui = CanvasLayer.new()
	add_child(ui)
	
	score_label = Label.new()
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.size = Vector2(screen_size.x, 64)
	score_label.position = Vector2(0, 20)
	score_label.add_theme_font_size_override("font_size", 52)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.6))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(score_label)
	
	var bar_y = screen_size.y - 55
	var bar_w = screen_size.x - 40
	var bar_bg = ColorRect.new()
	bar_bg.size = Vector2(bar_w, 18)
	bar_bg.position = Vector2(20, bar_y)
	bar_bg.color = Color(0.12, 0.12, 0.22)
	ui.add_child(bar_bg)
	
	energy_fill = ColorRect.new()
	energy_fill.size = Vector2(0, 18)
	energy_fill.position = Vector2(20, bar_y)
	energy_fill.color = Color(1.0, 0.75, 0.1)
	ui.add_child(energy_fill)
	
	var elbl = Label.new()
	elbl.text = "ENERGY"
	elbl.position = Vector2(20, bar_y - 26)
	elbl.add_theme_font_size_override("font_size", 16)
	elbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	ui.add_child(elbl)
	
	full_label = Label.new()
	full_label.text = "TAP = SUPER BLAST!"
	full_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	full_label.size = Vector2(screen_size.x, 36)
	full_label.position = Vector2(0, bar_y - 50)
	full_label.add_theme_font_size_override("font_size", 20)
	full_label.add_theme_color_override("font_color", Color(1, 0.4, 0.1))
	full_label.visible = false
	ui.add_child(full_label)
	
	var hint = Label.new()
	hint.text = "SWIPE: направление  |  TAP: ускорение"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(screen_size.x, 24)
	hint.position = Vector2(0, bar_y + 24)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	ui.add_child(hint)

func _spawn_ball():
	ball = BallScene.instantiate()
	ball.position = Vector2(screen_size.x / 2, screen_size.y * 0.72)
	ball.velocity = Vector2(1, -1.1).normalized() * 440
	add_child(ball)
	ball.energy_changed.connect(_on_energy)
	ball.exploded.connect(_on_explode)

func _on_energy(val: float):
	var mw = screen_size.x - 40
	if energy_fill:
		energy_fill.size.x = mw * (val / 100.0)
		if val >= 100.0:
			energy_fill.color = Color(1, 0.3, 0.1)
			if full_label: full_label.visible = true
		else:
			energy_fill.color = Color(1.0, 0.75, 0.1)
			if full_label: full_label.visible = false

func _on_explode(pos: Vector2):
	_shake(14.0, 0.45)
	for p in platform_list:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			var d = p.global_position.distance_to(pos)
			if d < 380:
				var f = (p.global_position - pos).normalized() * (380 - d) * 4.5
				p.take_hit(f)

func _shake(intensity: float, dur: float):
	if not cam: return
	var tween = create_tween()
	var steps = int(dur * 24)
	for _i in range(steps):
		tween.tween_callback(func():
			cam.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		)
		tween.tween_interval(dur / steps)
	tween.tween_callback(func(): cam.offset = Vector2.ZERO)

func _spawn_platforms():
	platform_list = platform_list.filter(func(p):
		return is_instance_valid(p) and not p.is_queued_for_deletion()
	)
	var colors = [
		Color(1.0, 0.22, 0.22),
		Color(0.2, 0.88, 0.42),
		Color(0.22, 0.52, 1.0),
		Color(1.0, 0.78, 0.1),
		Color(0.78, 0.2, 1.0),
	]
	var rows = 5
	var cols = 3
	var pad = 50.0
	var uw = screen_size.x - pad * 2
	for row in range(rows):
		for col in range(cols):
			if randf() < 0.12: continue
			var p = PlatformScene.instantiate()
			p.position = Vector2(pad + col * (uw / (cols - 1)), 165 + row * 85)
			p.platform_color = colors[row % colors.size()]
			p.hp = 1 + int(row * 0.5)
			p.width = randf_range(90, 140)
			p.destroyed.connect(_on_platform_destroyed.bind(p))
			add_child(p)
			platform_list.append(p)

func _on_platform_destroyed(pts: int, p: Node):
	score += pts
	score_label.text = str(score)
	# Score pop animation
	var tween = create_tween()
	tween.tween_property(score_label, "modulate", Color(1.5, 1.5, 0.5), 0.08)
	tween.tween_property(score_label, "modulate", Color.WHITE, 0.15)
	
	get_tree().create_timer(0.1).timeout.connect(func():
		platform_list = platform_list.filter(func(pl):
			return is_instance_valid(pl) and not pl.is_queued_for_deletion()
		)
		if platform_list.size() < 4:
			get_tree().create_timer(1.4).timeout.connect(_spawn_platforms)
	)

func _spawn_orbs(n: int):
	for _i in range(n): _spawn_single_orb()

func _spawn_single_orb():
	if not is_inside_tree(): return
	var orb = OrbScene.instantiate()
	orb.position = Vector2(
		randf_range(38, screen_size.x - 38),
		randf_range(150, screen_size.y - 90)
	)
	add_child(orb)
	orb.collected.connect(_on_orb_collected.bind(orb))

func _on_orb_collected(orb: Node):
	if ball and is_instance_valid(ball): ball.add_energy(26)
	if is_instance_valid(orb): orb.queue_free()
	get_tree().create_timer(randf_range(2.2, 4.5)).timeout.connect(_spawn_single_orb)

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = {"start": event.position, "time": Time.get_ticks_msec(), "done": false}
		else:
			if event.index in touches:
				var d = touches[event.index]
				var dist = event.position.distance_to(d.start)
				var ms = Time.get_ticks_msec() - d.time
				if dist < 45 and ms < 380 and not d.done:
					_tap()
				touches.erase(event.index)
	elif event is InputEventScreenDrag:
		if event.index in touches:
			var d = touches[event.index]
			var drag = event.position - d.start
			if drag.length() > 52 and not d.done:
				d.done = true
				touches[event.index] = d
				_swipe(drag.normalized())
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				touches[-1] = {"start": event.position, "time": Time.get_ticks_msec(), "done": false}
			else:
				if -1 in touches:
					var d = touches[-1]
					if event.position.distance_to(d.start) < 45 and not d.done: _tap()
					touches.erase(-1)
	elif event is InputEventMouseMotion:
		if -1 in touches and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			var d = touches[-1]
			var drag = event.position - d.start
			if drag.length() > 52 and not d.done:
				d.done = true; touches[-1] = d
				_swipe(drag.normalized())

func _tap():
	if ball and is_instance_valid(ball):
		ball.boost()
		_shake(5.0, 0.16)

func _swipe(dir: Vector2):
	if ball and is_instance_valid(ball): ball.set_direction(dir)
