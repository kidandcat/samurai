extends Node2D


func _ready():
	for c in get_children():
		c.visible = false

func reaction(name):
	for c in get_children():
		c.visible = false
	get_node(name).visible = true
	await get_tree().create_timer(3.0).timeout
	get_node(name).visible = false
