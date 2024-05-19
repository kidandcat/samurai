extends Node2D

const PlayerClass = preload("res://player.tscn")
const ConnexionClass = preload("res://conexion.tscn")
const COUNTDOWN = 4

var REGISTRY = "https://galax.be/"
var PORT = 9000
var enet_peer = ENetMultiplayerPeer.new()
var myaddress = null
var rng = RandomNumberGenerator.new()

func _ready():
	if DisplayServer.get_name() == "headless":
		dedicated_server()
		return
	var game = get_node_or_null("/root/Game")
	if game and game.DEBUG:
		REGISTRY = "http://localhost:8080/" 
	Global.connect("play", start_client)
	Global.connect("reset", reset)
	Global.connect("hit", adjust_battle_music)

func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP discover failed! %s", discover_result)
		myaddress = str(PORT)
		return
	print("Found %s devices" % upnp.get_device_count())
	print("Gateway: %s"%upnp.get_gateway())
	var map_result = upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP map failed! %s", map_result)
		myaddress = str(PORT)
		return
	print("Success! Join Address: %s" % upnp.query_external_address())
	myaddress = upnp.query_external_address()+":"+str(PORT)

func register():
	if myaddress:
		$Register.request(REGISTRY, [], HTTPClient.METHOD_POST, myaddress)

func _on_register_request_completed(_result, _response_code, _headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data: return
	for key in data:
		var value = data[key]
		if get_node_or_null(key.validate_node_name()): continue
		var i = ConnexionClass.instantiate()
		i.address = key
		i.name = key
		add_child(i)
		i.global_position = Vector2(value.x, value.y)

func start_server():
	$Battle.stop()
	$Ambient.play(0.0)
	Global.emit_signal("hide_ui")
	var err = null
	while err != OK:
		PORT += 1
		err = enet_peer.create_server(PORT)
	print("Server created at port ", enet_peer.host.get_local_port())
	multiplayer.multiplayer_peer = enet_peer
	if multiplayer.peer_connected.is_connected(start_match):
		multiplayer.peer_connected.disconnect(start_match)
	multiplayer.peer_connected.connect(start_match)
	if multiplayer.peer_disconnected.is_connected(reset):
		multiplayer.peer_disconnected.disconnect(reset)
	multiplayer.peer_disconnected.connect(reset)
	if multiplayer.server_disconnected.is_connected(reset):
		multiplayer.server_disconnected.disconnect(reset)
	multiplayer.server_disconnected.connect(reset)
	upnp_setup()
	remove_players()
	add_player(1, Vector2(420, 300))
	$Ping.start()
	get_tree().paused = false
	
func start_client():
	var address = "galax.be:9000"
	var game = get_node_or_null("/root/Game")
	if game and game.DEBUG:
		address = "localhost:9000"
	$Ping.stop()
	remove_players()
	enet_peer.close()
	var s = address.split(":")
	var err = enet_peer.create_client(s[0], int(s[1]))
	if err != OK:
		print("Error connecting to client")
		start_server()
		return
	multiplayer.multiplayer_peer = enet_peer
	$Ambient.stop()
	$Battle.volume_db = -25
	$Battle.play(0.0)
	Global.emit_signal("show_ui")
	
	
func reset(_peer = null):
	get_tree().paused = true
	remove_players()
	await get_tree().create_timer(0.5).timeout
	enet_peer.close()
	multiplayer.multiplayer_peer = null
	get_node("/root/Game").reload()
	
var countdown_ticks = 0
func _on_countdown_timeout():
	countdown_ticks -= 1
	Global.emit_signal("countdown", countdown_ticks)
	if countdown_ticks == 0:
		$Countdown.stop()
		get_tree().paused = false
		Global.emit_signal("show_ui")
	
func start_match(peer_id):
	$Ambient.stop()
	$Battle.volume_db = -25
	$Battle.play(0.0)
	countdown_ticks = COUNTDOWN
	get_tree().paused = true
	$Countdown.start()
	if not is_multiplayer_authority(): return
	$Ping.stop()
	remove_players()
	await get_tree().create_timer(1.0).timeout
	for c in get_tree().get_nodes_in_group("ephimeral"):
		c.fade()
	add_player(1, Vector2(220, 300))
	add_player(peer_id, Vector2(420, 300))
	
func add_player(peer_id, pos):
	var player = PlayerClass.instantiate()
	player.name = str(peer_id)
	add_child(player)
	player.initial_position.rpc(pos)

func remove_players():
	for p in get_tree().get_nodes_in_group("players"):
		p.name = "Deprecated"+p.name
		p.queue_free()

func focus(pos: Vector2):
	$ParallaxBackground.scroll_offset = Vector2(700-pos.x, 300-pos.y)

func adjust_battle_music():
	$Battle.volume_db += 3


##########


func dedicated_server():
	print("dedicated_server")
	var dedicated_port = 9000
	for c in OS.get_cmdline_args():
		if "port" in c:
			dedicated_port = c.split("=")[1]
	print("Starting server at ", dedicated_port)
	var err = enet_peer.create_server(dedicated_port)
	if err != OK:
		print("Error creating server ", err)
		get_tree().quit(err)
	print("Server created at port ", enet_peer.host.get_local_port())
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(dedicated_connected)
	multiplayer.peer_disconnected.connect(remove_player)
	call_deferred("remove_players")
	
func remove_player(peer_id):
	for c in get_children():
		if c.name == str(peer_id):
			c.queue_free()

func dedicated_connected(peer_id):
	print("Player connected ", peer_id)
	add_player(peer_id, Vector2(
		rng.randi_range(50, 600),
		rng.randi_range(50, 300)
	))

func _on_wind_maker_timeout():
	if not is_multiplayer_authority(): return
	Global.wind += randi_range(-5, 5)
	if Global.wind > 50: Global.wind = 50
	if Global.wind < -50: Global.wind = -50
