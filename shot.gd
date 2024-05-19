extends CharacterBody2D

const ROTATION_SPEED = 0.5
const SPEED = 5

var stop = false
var creator = null
var launched = false
var apply_damage = true
var target = null
var target_to_pos = null

func _ready():
	add_to_group("ephimeral")
	$Slash.frame = 1

func _on_area_2d_area_entered(area):
	_on_area_2d_body_entered(area.get_parent())
func _on_area_2d_body_shape_entered(_1, body, _2, _3):
	_on_area_2d_body_entered(body)
func _on_area_2d_body_entered(body):
	if not is_multiplayer_authority(): return
	if body.name == creator: return
	if not apply_damage: return
	if body.has_method("cut"):
		body.cut.rpc()
		return
	if body.has_method("hit"):
		$Hit.play()
		body.hit.rpc(self.global_position)
		destroy()
		return
	if body.has_method("destroy"):
		body.destroy()
		destroy()
		return
	destroy(true)
	
@rpc("any_peer", "call_local")
func hit(_from):
	destroy()

func _physics_process(_delta):
	if not is_multiplayer_authority(): return
	if stop: return
	$Slash.rotate(ROTATION_SPEED)
	if target:
		if not target_to_pos:
			target_to_pos = target-global_position
		move_and_collide(target_to_pos.normalized() * SPEED)

func destroy(slow = false):
	stop = true
	apply_damage = false
	collision_layer = 0
	collision_mask = 0
	$Area2D.collision_layer = 0
	$Area2D.collision_mask = 0
	if slow: 
		await get_tree().create_timer(1.0).timeout
		await create_tween().tween_property(
			self,
			"modulate",
			Color(1.0, 1.0, 1.0, 0.0),
			1.0
		).finished
	else:
		$Slash.play("default")
		await $Slash.animation_finished
	queue_free()







