extends Node2D

@export var DEBUG = false

const EXPAND_ANIMATION = 2.0
var SIZE = 1.0

###################################
# Black gandalf magic starts here #
###################################


func _ready():
	if DisplayServer.get_name() == "headless":
		return
	if DEBUG: SIZE = 0.5
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	get_tree().get_root().set_transparent_background(true)
	var w = get_window()
	var screen_size = DisplayServer.screen_get_size()
	w.size = w.size/2
	w.position = Vector2(screen_size.x/2-w.size.x/2, screen_size.y/2-w.size.y/2)

var activated = false
func black_magic():
	if activated: return
	activated = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Cursor.visible = true
	var w = get_window()
	var target_size = Vector2i(DisplayServer.screen_get_size()*SIZE)
	# Size
	create_tween().tween_property(
		w, "size", target_size, EXPAND_ANIMATION
	).set_ease(Tween.EASE_OUT)
	# Position
	var t = create_tween()
	t.tween_property(w, "position", Vector2i.ZERO, EXPAND_ANIMATION)
	t.set_ease(Tween.EASE_OUT)
	t.connect("finished", play)
	# Hide START button
	create_tween().tween_property(
		$Control/NinePatchRect.material, 
		"shader_parameter/dissolve_value", 
		0.0, EXPAND_ANIMATION
	).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(
		$Control/Label, 
		"modulate", 
		Color(1.0, 1.0, 1.0, 0.0), EXPAND_ANIMATION
	).set_ease(Tween.EASE_OUT)

#########################
# You can breathe again #
#########################


const SceneClass = preload("res://scene.tscn")
func reload():
	var v = $SubViewport
	for c in v.get_children():
		c.name = "Deprecated"
		c.queue_free()
	var s = SceneClass.instantiate()
	$SubViewport.add_child(s)
	Global.emit_signal("play")
	get_tree().paused = false

################
# Game starts! #
################
func play():
	# Change cursor color
	create_tween().tween_property(
		$Cursor, 
		"modulate", 
		Color(0.0, 0.0, 1.0, 1.0), EXPAND_ANIMATION
	).set_ease(Tween.EASE_OUT)
	$Control.visible = false
	get_tree().paused = false
	Global.emit_signal("play")

func _on_nine_patch_rect_gui_input(event):
	if event is InputEventMouseButton:
		black_magic()

func _process(_delta):
	if get_node_or_null("SubViewport/Scene/"+str(multiplayer.get_unique_id())):
		$Cursor.global_position = get_global_mouse_position()
		var p_pos = get_node_or_null("SubViewport/Scene/"+str(multiplayer.get_unique_id())).global_position
		var target = Vector2(p_pos.x+50, p_pos.y+50)
		$Cursor.look_at(target)

func _on_nick_text_changed(new_text: String):
	Global.nick = new_text
	if new_text.length() > 2:
		$Control/NinePatchRect2.connect("gui_input", _on_nine_patch_rect_gui_input)
		create_tween().tween_property(
			$Control/NinePatchRect2.material, 
			"shader_parameter/dissolve_value", 
			1.0, EXPAND_ANIMATION
		).set_ease(Tween.EASE_OUT)
		create_tween().tween_property(
			$Control/Label, 
			"modulate", 
			Color(1.0, 1.0, 1.0, 1.0), EXPAND_ANIMATION
		).set_ease(Tween.EASE_OUT)
	else:
		$Control/NinePatchRect2.disconnect("gui_input", _on_nine_patch_rect_gui_input)
		create_tween().tween_property(
			$Control/NinePatchRect2.material, 
			"shader_parameter/dissolve_value", 
			0.0, EXPAND_ANIMATION
		).set_ease(Tween.EASE_OUT)
		create_tween().tween_property(
			$Control/Label, 
			"modulate", 
			Color(1.0, 1.0, 1.0, 0.0), EXPAND_ANIMATION
		).set_ease(Tween.EASE_OUT)
