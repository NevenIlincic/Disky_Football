extends Node2D

signal match_searching_started()
signal match_found()
signal pre_match_info_showed()
signal money_spent(amount: int)
signal fans_spent(amount: int)
signal leveled_up()

signal player_introduced()
signal custom_lobby_full()

var ready_players: Dictionary = {}

var id: String
var room_id: int
var match_scene: PackedScene
var my_name: String = str("MeXa", "_", randi())   
var my_team_name: String

var is_in_private_room: bool = false

var names: Dictionary = {}                 # player_id -> ime
var teams: Dictionary = {} #player_id -> naziv_tima
var formations: Dictionary = {}
var ball_effects: Dictionary = {}
var levels: Dictionary = {}
var skins: Dictionary = {}

#PLAYER STATS
var current_level = 1
var money_amount = 0
var fans_amount = 0
var experience_amount = 0

var level_experience_map: Dictionary = {
	1: 10,
	2: 20,
	3: 30,
	4: 40,
	5: 50,
	6: 60,
	7: 70,
	8: 80,
	9: 90,
	10: 100
}
const MAX_LEVEL: int = 10

var has_connection_lost: bool = false
var has_disconnected_intentionally: bool = false

func get_needed_experience_amount_to_level_up() -> int:
	return level_experience_map[current_level]

func check_is_max_level() -> bool:
	return current_level == MAX_LEVEL
#Returns has reached


func reset_multiplayer_data() -> void:
	current_level = 1
	money_amount = 0
	fans_amount = 0
	experience_amount = 0
	my_team_name = ""
	SkinsManager.selected_skin = 0
	SkinsManager.purchased_skins_ids = [0]
	BallEffects.selected_effect = 0
	BallEffects.purchased_effects_id = [0]
	FormationsManager.selected_formation = 0
	FormationsManager.purchased_formations_id = [0]

func _exit_tree() -> void:
	if Fusion.connected_to_photon.is_connected(_on_connected):
		Fusion.connected_to_photon.disconnect(_on_connected)
	if Fusion.room_joined.is_connected(_on_room_joined):
		Fusion.room_joined.disconnect(_on_room_joined)
	if Fusion.player_joined.is_connected(_on_player_joined):
		Fusion.player_joined.disconnect(_on_player_joined)
	if Fusion.connection_status_changed.is_connected(_on_connection_status_changed):
		Fusion.connection_status_changed.disconnect(_on_connection_status_changed)
	
	
func _ready():
	randomize()
	Fusion.register_broadcast_receiver(self)

	#id = str(randi(), my_name)
	#my_team_name = get_random_3_letter_string()
	connect_to_signals()

func connect_to_signals():
	Fusion.connected_to_photon.connect(_on_connected)
	Fusion.room_joined.connect(_on_room_joined)
	Fusion.player_joined.connect(_on_player_joined)
	Fusion.connection_status_changed.connect(_on_connection_status_changed)
func _on_connection_status_changed(status):
	match status:
		Fusion.ConnectionStatus.STATUS_DISCONNECTED:
			has_connection_lost = true
			get_tree().change_scene_to_file("res://Scenes/Menus/Menu_Scene.tscn")


func connect_to_server():
	Fusion.connect_to_photon(id)

func _on_connected():
	#id = WebSdk.SDK.get_player_id()
	id = str(randi_range(0, 99999))
	WebSdk.SDK.load_multiplayer_data()
	#WebSDK.load_multiplayer_data()
	#money_amount = 100
	#fans_amount = 100
	#current_level = 2
	#experience_amount = 19


func create_or_join_private_room(custom_room_name: String) -> void:
	is_in_private_room = true
	match_searching_started.emit()
	var room_options: FusionRoomOptions = FusionRoomOptions.new()
	room_options.max_players = 2
	room_options.is_visible = false
	room_options.custom_properties = {
		"fusion_map_data": "default_map"
	}
	
	Fusion.join_or_create_room(custom_room_name, room_options)
	
	
func create_quick_match_room() -> void:
	is_in_private_room = false
	match_searching_started.emit()
	var room_options: FusionRoomOptions = FusionRoomOptions.new()
	room_options.max_players = 2
	room_options.is_visible = true
	room_options.custom_properties = {
		"fusion_map_data": "default_map"
	}
	Fusion.join_or_create_room("", room_options)

func create_room():
	match_searching_started.emit()
	var room_options: FusionRoomOptions = FusionRoomOptions.new()
	room_options.max_players = 2
	room_options.custom_properties = {
		"fusion_map_data": "deafult_map"
	}
	
	#var room_name: String = "Room_" + str(randi_range(100000, 999999))
	Fusion.join_or_create_room("", room_options)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Fusion.unregister_broadcast_receiver(self)
		Fusion.disconnect_from_photon()
		get_tree().quit()

func leave_room() -> void:
	is_in_private_room = false
	ready_players.clear()
	names.clear()
	teams.clear()
	ball_effects.clear()
	formations.clear()
	levels.clear()
	skins.clear()
	Fusion.leave_room()

func join_private_room(room_name: String) -> void:
	is_in_private_room = true
	match_searching_started.emit()
	var room_options: FusionRoomOptions = FusionRoomOptions.new()
	room_options.max_players = 2
	room_options.custom_properties = {
		"fusion_map_data": "deafult_map"
	}
	Fusion.join_room(room_name, room_options)

func _on_player_joined(player_id: int, user_id: String):
	if id == user_id:
		room_id = player_id

@rpc("any_peer", "call_local")
func player_ready(received_data_array: PackedByteArray):
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.data_array = received_data_array
	if not Fusion.is_master_client():
		return
	var player_id: String = buffer.get_utf8_string()
	ready_players[player_id] = true
	if ready_players.size() == 2:
		if not is_in_private_room:
			match_found.emit()
		else:
			custom_lobby_full.emit()
		#Fusion.rpc(start_match)

@rpc("any_peer", "call_local")
func start_match():
	get_tree().change_scene_to_file.call_deferred("res://Scenes/Multiplayer/Multiplayer_Scene.tscn")


func _on_room_joined():
	names[id] = my_name
	teams[id] = my_team_name
	formations[id] = FormationsManager.selected_formation
	ball_effects[id] = BallEffects.selected_effect
	levels[id] = current_level
	skins[id] = SkinsManager.selected_skin
	
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.put_utf8_string(id)
	buffer.put_utf8_string(my_name)
	buffer.put_utf8_string(my_team_name)
	buffer.put_u8(FormationsManager.selected_formation)
	buffer.put_u8(BallEffects.selected_effect)
	buffer.put_u8(current_level)
	buffer.put_u8(SkinsManager.selected_skin)
	
	#Fusion.rpc(introduce, id, my_name, my_team_name, FormationsManager.selected_formation, BallEffects.selected_effect, current_level, SkinsManager.selected_skin)
	Fusion.rpc(introduce, buffer.data_array)
	
	buffer.clear()
	buffer.put_utf8_string(id)
	
	Fusion.rpc(player_ready, buffer.data_array)

#@rpc("any_peer", "call_remote")
#func introduce(received_data_array: PackedByteArray):
	#print("PRIMLJEN INTRODUCE, velicina bajtova: ", received_data_array.size())
	#var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	#buffer.data_array = received_data_array
	#var player_id: String = buffer.get_utf8_string()
	#var is_new = not names.has(player_id)
	#var player_name: String = buffer.get_utf8_string()
	#var player_team_name: String = buffer.get_utf8_string()
	#var player_formation_id: int = buffer.get_u8()
	#var player_ball_effect_id: int = buffer.get_u8()
	#var player_level: int = buffer.get_u8()
	#var player_skin_id: int = buffer.get_u8()
	#
	#names[player_id] = player_name
	#teams[player_id] = player_team_name
	#formations[player_id] = player_formation_id
	#ball_effects[player_id] = player_ball_effect_id
	#levels[player_id] = player_level
	#skins[player_id] = player_skin_id
	#if is_new:
		#Fusion.rpc(introduce, received_data_array)

@rpc("any_peer", "call_remote")
func introduce(received_data_array: PackedByteArray):
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.data_array = received_data_array
	
	var player_id: String = buffer.get_utf8_string()
	var player_name: String = buffer.get_utf8_string()
	var player_team_name: String = buffer.get_utf8_string()
	var player_formation_id: int = buffer.get_u8()
	var player_ball_effect_id: int = buffer.get_u8()
	var player_level: int = buffer.get_u8()
	var player_skin_id: int = buffer.get_u8()
	
	var is_new = not names.has(player_id)
	
	names[player_id] = player_name
	teams[player_id] = player_team_name
	formations[player_id] = player_formation_id
	ball_effects[player_id] = player_ball_effect_id
	levels[player_id] = player_level
	skins[player_id] = player_skin_id
		
	if is_new and player_id != id:
		var reply_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
		reply_buffer.put_utf8_string(id)
		reply_buffer.put_utf8_string(my_name)
		reply_buffer.put_utf8_string(my_team_name)
		reply_buffer.put_u8(FormationsManager.selected_formation)
		reply_buffer.put_u8(BallEffects.selected_effect)
		reply_buffer.put_u8(current_level)
		reply_buffer.put_u8(SkinsManager.selected_skin)
		
		Fusion.rpc(introduce, reply_buffer.data_array)
		player_introduced.emit()
		

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

func get_opponents_formation_id() -> int:
	var opponents_formation_id: int
	for player_id: String in formations:
		if player_id != id:
			opponents_formation_id = formations[player_id]
			break
	return opponents_formation_id
	
func get_opponents_ball_effect_id() -> int:
	var opponents_ball_effect_id: int
	for player_id: String in ball_effects:
		if player_id != id:
			opponents_ball_effect_id = ball_effects[player_id]
			break
	return opponents_ball_effect_id

func get_opponents_level() -> int:
	var opponents_level: int
	for player_id: String in levels:
		if player_id != id:
			opponents_level = levels[player_id]
			break
	return opponents_level

func get_opponents_skin_id() -> int:
	var opponents_skin_id: int
	for player_id: String in skins:
		if player_id != id:
			opponents_skin_id = skins[player_id]
			break
	return opponents_skin_id


func remove_opponents_data() -> void:
	for player_id in names.keys():
		if player_id != id:
			names.erase(player_id)
			teams.erase(player_id)
			formations.erase(player_id)
			ball_effects.erase(player_id)
			levels.erase(player_id)
			skins.erase(player_id)
			ready_players.erase(player_id)


func get_team_name() -> String:
	return get_random_3_letter_string()

func get_random_3_letter_string() -> String:
	var alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var result: String = ""
	
	for i in range(3):
		var random_index = randi() % alphabet.length()
		result += alphabet[random_index]
		
	return result

func handle_team_name_change(new_team_name: String):
	my_team_name = new_team_name
	handle_money_spend(5)

func handle_initial_team_name_change(new_team_name: String):
	my_team_name = new_team_name
	WebSdk.SDK.save_multiplayer_data()

func handle_money_spend(amount: int):
	money_amount -= amount
	#SACUVATI U PLAYGAMA SDK
	WebSdk.SDK.save_multiplayer_data()
	money_spent.emit(amount)

func handle_fans_spend(amount: int):
	fans_amount -= amount
	#SACUVATI U PLAYGAMA SDK
	WebSdk.SDK.save_multiplayer_data()
	fans_spent.emit(amount)

func handle_money_gained(amount: int):
	money_amount += amount
	WebSdk.SDK.save_multiplayer_data()
	#SACUVATI U PLAYGAMA SDK
func handle_fans_gained(amount: int):
	fans_amount += amount
	WebSdk.SDK.save_multiplayer_data()
	#SACUVATI U PLAYGAMA SDK

func handle_fans_and_money_spent(fan_cost: int, money_cost: int) -> void:
	fans_amount -= fan_cost
	money_amount -= money_cost
	WebSdk.SDK.save_multiplayer_data()
	money_spent.emit(money_cost)
	fans_spent.emit(fan_cost)

func handle_rewarded_ad_watched(new_fans_amount: int, new_money_amount: int):
	fans_amount += new_fans_amount
	money_amount += new_money_amount
	WebSdk.SDK.save_multiplayer_data()

func handle_fans_and_money_gained(fans_gained_amount: int, money_gained_amount: int) -> void:
	fans_amount += fans_gained_amount
	money_amount += money_gained_amount
	WebSdk.SDK.save_multiplayer_data()
