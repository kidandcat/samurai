extends CharacterBody2D


const SPEED = 180.0
const GRAVITY = 800
const AIR_SPEED_MODIFIER = 0.70
const MAX_MANA = 15
const JUMP_VELOCITY = -300.0
const MAX_JUMP_POWERUP = 3

var mana = MAX_MANA
var initial_position_set = false
var running = false
var crouch = false

@rpc("any_peer", "call_local")
func initial_position(v):
	if initial_position_set: return
	global_position = v
	initial_position_set = true

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	Global.connect("died", died)
	add_to_group("players")
	$BloodContainer/Blood.connect("animation_finished", hide_blood)
	$SpriteIdle.play("default")
	$SpriteRunLeft.play("default")
	$SpriteRunRight.play("default")
	var color = Color(0.0, 0.0, 1.0, 1.0)
	if not is_multiplayer_authority():
		color = Color(1.0, 0.0, .0, 1.0)
	else:
		$Nick.text = Global.nick
	var blue = [$SpriteIdle, $SpriteRunLeft, $SpriteRunRight, $Dead/Dying, $SpriteCrouch]
	for item in blue:
		create_tween().tween_property(
			item,
			"self_modulate",
			color,
			1.0
		)

func set_nick(nick):
	$Nick.text = nick

@rpc("any_peer")
func win():
	if not is_multiplayer_authority(): return
	Global.emit_signal("winner")
	Global.emit_signal("show_ui")

func died():
	if not is_multiplayer_authority(): return
	get_tree().paused = true
	for p in get_tree().get_nodes_in_group("players"):
		if p.name == name: continue
		p.win.rpc()
	Global.emit_signal("loser")
	await get_tree().create_timer(0.5).timeout
	reset()
	$Dead.play()
	await $Dead.finished
	Global.emit_signal("reset")

func reset():
	$SpriteIdle.visible = false
	$SpriteRunLeft.visible = false
	$SpriteRunRight.visible = false
	$SpriteCrouch.visible = false
	

@rpc("any_peer", "call_local")
func hit(from):
	$BloodContainer.look_at(from)
	$BloodContainer.visible = true
	$BloodContainer/Blood.play("default")
	if not is_multiplayer_authority(): return
	Global.emit_signal("hit")
	
func hide_blood():
	$BloodContainer.visible = false
	
	
var slash_allowed = true
func _on_slash_cooldown_timeout():
	slash_allowed = true
	
var jump_powerup_allowed = true
func _on_jump_powerup_timeout():
	jump_powerup_allowed = true
	jump_powerup += 1

var jump_powerup = 0
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	if get_tree().paused: return
	get_parent().focus(global_position)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_powerup = 0
		jump_powerup_allowed = false
		$JumpPowerup.start()
		$AudioJump.play()
		
	if Input.is_action_pressed("jump") and not is_on_floor() and jump_powerup < MAX_JUMP_POWERUP and jump_powerup_allowed:
		velocity.y += JUMP_VELOCITY
		jump_powerup_allowed = false
		$JumpPowerup.start()
		if velocity.y < JUMP_VELOCITY:
			velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("slash") and slash_allowed and mana >= 3:
		slash_allowed = false
		$Cooldown.start()
		mana -= 3
		Global.emit_signal("mana", mana)
		var mpos = $"/root/Game/Cursor".global_position
		var target = Vector2(mpos.x-60, mpos.y-60)
		$"../EntitySpawner".slash.rpc(name, global_position, target)
		
	if Input.is_action_just_pressed("shot") and slash_allowed and mana >= 5:
		slash_allowed = false
		$Cooldown.start()
		mana -= 5
		Global.emit_signal("mana", mana)
		var mpos = $"/root/Game/Cursor".global_position
		var target = Vector2(mpos.x-60, mpos.y-60)
		$"../EntitySpawner".shot.rpc(name, global_position, target)
		
	if Input.is_action_just_pressed("move_down"):
		crouch = true
		$MainCollision.disabled = true
		$CrouchCollision.disabled = false
		set_collision_mask_value(3, false)
	if Input.is_action_just_released("move_down"):
		crouch = false
		$MainCollision.disabled = false
		$CrouchCollision.disabled = true
		set_collision_mask_value(3, true)
		

	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if crouch: velocity.x = 0
		
	if abs(velocity.x) > 0 and not running:
		running = true
	elif velocity.x == 0 and running:
		running = false
		
	if not is_on_floor():
		velocity.x *= AIR_SPEED_MODIFIER
		running = false
		
	if running and $RunningTimer.is_stopped():
		$RunningTimer.start()
	elif not running and not $RunningTimer.is_stopped():
		$RunningTimer.stop()

		
	reset()
	if crouch:
		$SpriteCrouch.visible = true
	elif velocity.x == 0:
		$SpriteIdle.visible = true
	elif velocity.x > 0:
		$SpriteRunRight.visible = true
	else:
		$SpriteRunLeft.visible = true
		
	move_and_slide()
	
	if Input.is_action_just_pressed("reaction1"):
		$Emojis.reaction("Wink")
	if Input.is_action_just_pressed("reaction2"):
		$Emojis.reaction("Joke")
	if Input.is_action_just_pressed("reaction3"):
		$Emojis.reaction("Shit")
	if Input.is_action_just_pressed("reaction4"):
		$Emojis.reaction("Question")
	if Input.is_action_just_pressed("reaction5"):
		$Emojis.reaction("Zzz")


func _on_mana_refill_timeout():
	if mana < MAX_MANA: 
		mana += 1
		Global.emit_signal("mana", mana)


