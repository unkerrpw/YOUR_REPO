extends CharacterBody2D

signal energy_changed(val)
signal exploded(pos)

const ExplosionScene = preload("res://scenes/Explosion.tscn")
const RADIUS = 22.0
const BASE_SPEED = 440.0
const MAX_ENERGY = 100.0

var energy: float = 0.0
var trail: Array = []
var screen_size: Vector2
var boosting: bool = false
var boost_timer: float = 0.0
var pulse: float = 0.0

func _ready():
	screen_size = get_viewport_rect().size

func _physics_process(delta):
	pulse += delta * 3.0
	if boosting:
		boost_timer -= delta
		if boost_timer <= 0: boosting = false
	
	# Wall bounce
	var spd = velocity.length()
	if position.x < RADIUS:
		velocity.x = abs(velocity.x); position.x = RADIUS
		_wall_fx()
	elif position.x > screen_size.x - RADIUS:
		velocity.x = -abs(velocity.x); position.x = screen_size.x - RADIUS
		_wall_fx()
	if position.y < RADIUS:
		velocity.y = abs(velocity.y); position.y = RADIUS
		_wall_fx()
	elif position.y > screen_size.y - RADIUS:
		velocity.y = -abs(velocity.y); position.y = screen_size.y - RADIUS
		_wall_fx()
	
	# Move and collide with platforms
	var col = move_and_collide(velocity * delta)
	if col:
		velocity = velocity.bounce(col.get_normal())
		var hit = col.get_collider()
		if hit and hit.has_method("take_hit"):
			var force = velocity.normalized() * spd * 0.35
			hit.take_hit(force)
			_hit_fx(col.get_position())
	
	# Clamp min speed
	if velocity.length() < 300:
		velocity = velocity.normalized() * 300
	
	# Trail
	trail.append(global_position)
	if trail.size() > 18: trail.pop_front()
	
	queue_redraw()

func _draw():
	# Trail
	for i in range(trail.size()):
		var lp = trail[i] - global_position
		var t = float(i) / max(trail.size() - 1, 1)
		draw_circle(lp, max(RADIUS * 0.75 * t, 1), Color(0.3, 0.8, 1.0, t * 0.38))
	
	# Outer glow rings
	var glow_r = RADIUS + 4 + sin(pulse) * 2
	for i in range(4):
		var a = 0.14 - i * 0.03
		var r = glow_r + i * 4.0
		var gc = Color(0.2, 0.6, 1.0) if not boosting else Color(1.0, 0.5, 0.0)
		draw_circle(Vector2.ZERO, r, Color(gc.r, gc.g, gc.b, a))
	
	# Main ball
	var bc = Color(0.25, 0.75, 1.0) if not boosting else Color(1.0, 0.65, 0.1)
	draw_circle(Vector2.ZERO, RADIUS, bc)
	# Specular highlight
	draw_circle(Vector2(-6, -7), RADIUS * 0.38, Color(1, 1, 1, 0.30))
	
	# Energy arc
	if energy > 0:
		var arc_frac = energy / MAX_ENERGY
		var arc_col = Color(1.0, 0.85, 0.0) if energy < MAX_ENERGY else Color(1.0, 0.3, 0.05)
		draw_arc(Vector2.ZERO, RADIUS + 7, -PI * 0.5, -PI * 0.5 + TAU * arc_frac, 40, arc_col, 3.0)
		# Spark at arc tip
		var ang = -PI * 0.5 + TAU * arc_frac
		var sp = Vector2(cos(ang), sin(ang)) * (RADIUS + 7)
		draw_circle(sp, 4.5, Color(1, 1, 0.5))

func boost():
	if energy >= MAX_ENERGY:
		_super_blast()
	else:
		boosting = true
		boost_timer = 0.48
		velocity = velocity.normalized() * BASE_SPEED * 1.65

func set_direction(dir: Vector2):
	var spd = velocity.length()
	velocity = dir * max(spd, BASE_SPEED)

func add_energy(amt: float):
	energy = minf(energy + amt, MAX_ENERGY)
	energy_changed.emit(energy)
	if energy >= MAX_ENERGY:
		modulate = Color(2, 1.5, 0.4)
		var tw = create_tween().set_loops(0)
		tw.tween_property(self, "modulate", Color(1.5, 1.0, 0.3), 0.4)
		tw.tween_property(self, "modulate", Color(2, 1.5, 0.4), 0.4)

func _super_blast():
	energy = 0.0
	energy_changed.emit(energy)
	modulate = Color.WHITE
	
	var ex = ExplosionScene.instantiate()
	ex.position = global_position
	ex.set_meta("radius", 140.0)
	ex.set_meta("color", Color(1.0, 0.5, 0.05))
	get_parent().add_child(ex)
	
	exploded.emit(global_position)
	velocity = velocity.normalized() * BASE_SPEED * 1.8

func _hit_fx(pos: Vector2):
	var ex = ExplosionScene.instantiate()
	ex.position = pos
	ex.set_meta("radius", 38.0)
	ex.set_meta("color", Color(0.9, 0.6, 0.1))
	get_parent().add_child(ex)

func _wall_fx():
	var ex = ExplosionScene.instantiate()
	ex.position = global_position
	ex.set_meta("radius", 22.0)
	ex.set_meta("color", Color(0.4, 0.8, 1.0))
	get_parent().add_child(ex)
