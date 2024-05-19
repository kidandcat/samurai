extends Node2D

var creator = null
var launched = false
var apply_damage = true

func _ready():
	add_to_group("ephimeral")

func start():
	$Area2D.connect("body_entered", _on_area_2d_body_entered)
	if not is_multiplayer_authority(): return
	for area in $Area2D.get_overlapping_areas():
		area.get_parent().destroy()
		apply_damage = false
	$Slash.play("default")
	if apply_damage:
		for body in $Area2D.get_overlapping_bodies():
			_on_area_2d_body_entered(body)
	
func hit_sound():
	$Hit.play()
	await $Hit.finished
	queue_free()

func _physics_process(_delta):
	if not is_multiplayer_authority(): return
	if not launched:
		launched = true
		start()

func destroy():
	if not is_multiplayer_authority(): return
	apply_damage = false
	$Area2D.collision_layer = 0
	$Area2D.collision_mask = 0
	$Slash.visible = false
	$Break.visible = true
	$Break.play("default")
	await $Break.animation_finished
	queue_free()


func _on_area_2d_body_entered(body):
	if body.name == creator: return
	if body.has_method("cut"):
		body.cut.rpc()
	if body.has_method("hit"):
		hit_sound()
		body.hit.rpc(self.global_position)


func _on_slash_animation_finished():
	queue_free()
