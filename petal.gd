extends CharacterBody2D

const PetalClass = preload("res://petal1.tscn")

var ROTATION_SPEED = 10
var GRAVITY = 5
var initial_force = Vector2.ZERO

func _ready():
	add_to_group("ephimeral")
	ROTATION_SPEED = randi_range(1, 5)
	GRAVITY = randi_range(3, 10)
	
@rpc("any_peer", "call_local")
func cut():
	if not is_multiplayer_authority(): return
	if initial_force != Vector2.ZERO: return
	var p = PetalClass.instantiate()
	p.global_position = global_position
	p.initial_force = Vector2(randi_range(5, 15), randi_range(5, 15))
	get_parent().add_child(p, true)
	initial_force = p.initial_force * -1
	await get_tree().create_timer(2.0)
	p.destroy()
	destroy()

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	$Sprite.rotate(ROTATION_SPEED*delta)
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.x += randi_range(Global.wind-5, Global.wind+5) * delta
	elif $Die.is_stopped():
		$Die.start(randf_range(0.5, 2.0))
	if initial_force != Vector2.ZERO:
		velocity = initial_force
		initial_force -= initial_force*delta
	move_and_slide()

func destroy():
	if not is_multiplayer_authority(): return
	await create_tween().tween_property(
		self,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		1.0
	).finished
	queue_free()







