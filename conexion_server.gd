extends Node2D


var emitted = false

func destroy():
	if emitted: return
	emitted = true
	Global.emit_signal("conexion_server")
	queue_free()
