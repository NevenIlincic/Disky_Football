extends Node2D

var ready_players: Dictionary = {}

var id: String
var match_scene: PackedScene
var my_name: String = str("AA", "_", randi())   
var names: Dictionary = {}                 # player_id -> ime


signal match_found()

func _ready():
	match_scene = preload("uid://dpsnlw7g6wmfq")
	Fusion.register_broadcast_receiver(self)

	id = str(Time.get_ticks_usec(),"_", randi())
	connect_to_signals()

func connect_to_signals():
	Fusion.connected_to_photon.connect(_on_connected)
	Fusion.room_joined.connect(_on_room_joined)
	Fusion.player_joined.connect(_on_player_joined)


func connect_to_server():
	Fusion.connect_to_photon(id)

func _on_connected():
	pass

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

func leave_room() -> void:
	Fusion.leave_room()

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
		match_found.emit()
		#Fusion.rpc(start_match)

@rpc("any_peer", "call_local")
func start_match():
	get_tree().change_scene_to_file.call_deferred("res://Scenes/Menus/Multiplayer_Scene.tscn")

func _on_room_joined():
	names[id] = my_name
	
	Fusion.rpc(introduce, id, my_name)
	Fusion.rpc(player_ready, id)

@rpc("any_peer", "call_remote")
func introduce(player_id: String, player_name: String):
	var is_new = not names.has(player_id)
	names[player_id] = player_name
	if is_new:
		Fusion.rpc(introduce, player_id, names[player_id])

func get_opponents_name() -> String:
	var opponents_name: String
	for player_id: String in names:
		if player_id != id:
			opponents_name = names[player_id]
			break
	return opponents_name
