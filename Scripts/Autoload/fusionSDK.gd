extends Node2D

var ready_players: Dictionary = {}

var id: String
var room_id: int
var match_scene: PackedScene
var my_name: String = str("MeXa", "_", randi())   
var my_team_name: String = "AAA"
var names: Dictionary = {}                 # player_id -> ime
var teams: Dictionary = {} #player_id -> naziv_tima

signal match_found()

func _ready():
	randomize()
	Fusion.register_broadcast_receiver(self)

	id = str(Time.get_ticks_usec(),"_", randi())
	#my_team_name = get_random_3_letter_string()
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
#
	var room_options: FusionRoomOptions = FusionRoomOptions.new()
	room_options.max_players = 2
	room_options.custom_properties = {
		"fusion_map_data": "deafult_map"
	}
	
	var room_name: String = "Room_" + str(randi_range(100000, 999999))
	Fusion.join_or_create_room("", room_options)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Fusion.unregister_broadcast_receiver(self)
		Fusion.disconnect_from_photon()
		get_tree().quit()

func leave_room() -> void:
	ready_players.clear()
	names.clear()
	teams.clear()
	Fusion.leave_room()

func join_room() -> void:
	#var room_options: FusionRoomOptions = FusionRoomOptions.new()
	#room_options.custom_properties = {
		#"fusion_map_data": "default_map"
	#}
	Fusion.join_room("TEST_ROOM_1")

func _on_player_joined(player_id: int, user_id: String):
	if id == user_id:
		room_id = player_id

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
	get_tree().change_scene_to_file.call_deferred("res://Scenes/Multiplayer/Multiplayer_Scene.tscn")

func _on_room_joined():
	names[id] = my_name
	teams[id] = my_team_name
	
	Fusion.rpc(introduce, id, my_name, my_team_name)
	Fusion.rpc(player_ready, id)

@rpc("any_peer", "call_remote")
func introduce(player_id: String, player_name: String, player_team_name: String):
	var is_new = not names.has(player_id)
	names[player_id] = player_name
	teams[player_id] = player_team_name
	if is_new:
		Fusion.rpc(introduce, player_id, names[player_id], teams[player_id])

func get_opponents_name() -> String:
	var opponents_name: String
	for player_id: String in names:
		if player_id != id:
			opponents_name = names[player_id]
			break
	return opponents_name

func get_opponents_team_name() -> String:
	var opponents_team_name: String
	for player_id: String in teams:
		if player_id != id:
			opponents_team_name = teams[player_id]
			break
	return opponents_team_name

func get_team_name() -> String:
	#ZAMENITI SA PLAYGAMA SDK
	return get_random_3_letter_string()

func get_random_3_letter_string() -> String:
	var alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" # ili "abcdefghijklmnopqrstuvwxyz" za mala slova
	var result: String = ""
	
	for i in range(3):
		var random_index = randi() % alphabet.length()
		result += alphabet[random_index]
		
	return result
