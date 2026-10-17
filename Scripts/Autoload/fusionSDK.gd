extends Node2D

var ready_players: Dictionary = {}

var id: String
var match_scene: PackedScene

func _ready():
	match_scene = preload("uid://dpsnlw7g6wmfq")
	Fusion.register_broadcast_receiver(self)
	#Fusion.set_scene_load_mode(Fusion.SCENE_LOAD_AUTO)
	#Fusion.set_scene_parent(get_tree().root)
	id = str(Time.get_ticks_usec(),"_", randi())
	connect_to_signals()

func connect_to_signals():
	Fusion.connected_to_photon.connect(_on_connected)
	Fusion.room_joined.connect(_on_room_joined)
	Fusion.player_joined.connect(_on_player_joined)

func _on_scene_load_requested(index: int, scene: PackedScene):
	#var match_instance = scene.instantiate()
#
	#var old_scene = get_tree().current_scene
	#if old_scene:
		#old_scene.queue_free()
#
	#get_tree().root.add_child(match_instance)
	#get_tree().current_scene = match_instance
#
	#Fusion.notify_scene_ready(match_instance, index)
	print("ZATRAZIO: ", id)

func _on_scene_ready(index: int):
	print("AAAA")
	var current_scene: Node = get_tree().current_scene
	if current_scene:
		current_scene.queue_free()
	
func connect_to_server():
	Fusion.connect_to_photon(id)

func _on_connected():
	print(id)
	#Fusion.join_or_create_room()

func create_room():
	var room_options: FusionRoomOptions = FusionRoomOptions.new()
	room_options.max_players = 2
	room_options.custom_properties = {
		"fusion_map_data": "default_map"
	}
	Fusion.join_or_create_room("TEST_ROOM_1", room_options)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Fusion.unregister_broadcast_receiver(self)
		Fusion.disconnect_from_photon()
		get_tree().quit()


func join_room() -> void:
	#var room_options: FusionRoomOptions = FusionRoomOptions.new()
	#room_options.custom_properties = {
		#"fusion_map_data": "default_map"
	#}
	Fusion.join_room("TEST_ROOM_1", null)

func _on_player_joined(player_id: int, user_id: String):
	pass

@rpc("any_peer", "call_local")
func player_ready(player_id: String):
	if not Fusion.is_master_client():
		return
	ready_players[player_id] = true
	if ready_players.size() == 2:
		Fusion.rpc(start_match)

@rpc("any_peer", "call_local")
func start_match():
	print(names)
	get_tree().change_scene_to_file.call_deferred("res://Scenes/Menus/Multiplayer_Scene.tscn")

var my_name := str("AA", "_", randi())   
var names := {}                 # player_id -> ime

func _on_room_joined():
	names[id] = my_name
	
	Fusion.rpc(introduce, id, my_name)
	#Fusion.rpc(request_names, id)
	Fusion.rpc(player_ready, id)

@rpc("any_peer", "call_remote")
func introduce(player_id: String, player_name: String):
	var is_new = not names.has(player_id)
	names[player_id] = player_name
	if is_new:
		Fusion.rpc(introduce, player_id, names[player_id])
