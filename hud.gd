extends Control


func _ready():
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	Global.connect("show_ui", show_ui)
	Global.connect("hide_ui", hide_ui)
	Global.connect("hit", hit)
	Global.connect("mana", mana)
	Global.connect("winner", winner)
	Global.connect("loser", loser)
	Global.connect("countdown", countdown)
	
func winner():
	$Winner.visible = true

func loser():
	$Loser.visible = true
	
func countdown(n):
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	$Emojis.visible = false
	$Winner.visible = false
	$Loser.visible = false
	$HP.visible = false
	$MP.visible = false
	$Countdown.visible = true
	$Countdown.text = str(n)
	
func show_ui():
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(
		self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5
	)
	$Countdown.visible = false
	$Winner.visible = false
	$Loser.visible = false
	$Emojis.visible = true
	$HP.visible = true
	$MP.visible = true
	$HP.value = 3
	$MP.value = $MP.max_value
	
func hide_ui():
	create_tween().tween_property(
		self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5
	)
	
func hit():
	if $HP.value-1 == 0:
		Global.emit_signal("died")
	create_tween().tween_property(
		$HP, "value", $HP.value-1, 0.5
	)
	$HP/Blood.visible = true
	$HP/Blood.play("default")
	await $HP/Blood.animation_finished
	$HP/Blood.visible = false
	
func mana(amount = 1):
	create_tween().tween_property(
		$MP, "value", amount, 0.5
	)
