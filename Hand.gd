extends Node2D

var SlashClass = preload("res://slash.tscn")
var ShotClass = preload("res://shot.tscn")

@rpc("any_peer", "call_local")
func slash(creator, pos, target):
	if not is_multiplayer_authority(): return
	var s = SlashClass.instantiate()
	s.creator = creator
	get_parent().add_child(s, true)
	s.global_position = pos
	s.look_at(target)


@rpc("any_peer", "call_local")
func shot(creator, pos, target):
	if not is_multiplayer_authority(): return
	var s = ShotClass.instantiate()
	s.name = "Shot"+str(randi())
	s.creator = creator
	get_parent().add_child(s, true)
	s.global_position = pos
	s.target = target
