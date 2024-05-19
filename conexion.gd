extends Node2D

var address = "localhost"

var emitted = false

func _ready():
	add_to_group("ephimeral")
	$AnimatedSprite2D.play("default")

func destroy():
	if emitted: return
	emitted = true
	Global.emit_signal("conexion", address)
	fade()

func fade():
	await create_tween().tween_property(
		self,
		"scale",
		Vector2(0.1, 0.1),
		1.0
	).finished
	queue_free()
