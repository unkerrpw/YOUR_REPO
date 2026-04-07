extends RigidBody2D

signal destroyed(points)

const ExplosionScene = preload("res://scenes/Explosion.tscn")

var platform_color: Color = Color(0.8, 0.3, 0.3)
var hp: int = 1
var width: float = 120.0
var height: float = 24.0
var _hit_flash: float = 0.0
var _alive: bool = true

func _ready():
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	gravity_scale = 1.2
	add_to_group("platforms")
	# Resize collision shape to match width/height
	var col = get_node_or_null("Col")
	if col and col.shape:
		col.shape.size = Vector2(width, height)
	queue_redraw()

func _process(delta):
	if _hit_flash > 0:
		_hit_flash -= delta * 6.0
		queue_redraw()

func _draw():
	var w = width; var h = height
	var r = Rect2(-w/2, -h/2, w, h)
	# Shadow
	draw_rect(Rect2(-w/2+2, -h/2+3, w, h), Color(0, 0, 0, 0.35))
	# Flash lerp
	var fc = platform_color.lerp(Color.WHITE, clampf(_hit_flash, 0, 1))
	draw_rect(r, fc)
	# Gradient highlight
	draw_rect(Rect2(-w/2+2, -h/2+2, w-4, h*0.45), Color(1, 1, 1, 0.18))
	# Border
	draw_rect(r, Color(1, 1, 1, 0.22), false, 2.0)
	# HP pips
	for i in range(hp):
		var px = -6.0 * (hp - 1) * 0.5 + i * 6.0
		draw_circle(Vector2(px, 0), 2.5, Color(1, 1, 1, 0.55))

func take_hit(force: Vector2):
	if not _alive: return
	hp -= 1
	_hit_flash = 1.0
	if hp <= 0:
		_alive = false
		collision_layer = 0
		freeze = false
		apply_central_impulse(force * 0.28)
		apply_torque_impulse(randf_range(-400, 400))
		
		var ex = ExplosionScene.instantiate()
		ex.position = global_position
		ex.set_meta("radius", 50.0)
		ex.set_meta("color", platform_color)
		get_parent().add_child(ex)
		
		destroyed.emit(10 + hp * 3)
		get_tree().create_timer(3.2).timeout.connect(queue_free)
	else:
		queue_redraw()
