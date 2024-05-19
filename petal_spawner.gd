extends Marker2D

const PetalClass = preload("res://petal1.tscn")

func _on_timer_timeout():
	if not is_multiplayer_authority(): return
	var p = PetalClass.instantiate()
	p.global_position = global_position
	get_parent().add_child(p, true)
	$Timer.start(randi_range(10, 30))
