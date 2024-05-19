extends Node2D

signal finished

func play():
	visible = true
	$Dying.connect("animation_finished", emit_f)
	$B2.play("default")
	$B3.play("default")
	$Dying.play("default")

func emit_f():
	$B1.play("default")
	await $B1.animation_finished
	await get_tree().create_timer(3.0).timeout
	emit_signal("finished")
