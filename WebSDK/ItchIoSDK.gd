class_name ItchIoSDK extends IWebSDK

var MULTIPLAYER_STORAGE_KEY: String = "multiplayer_data"
var SINGLEPLAYER_STORAGE_KEY: String = "singleplayer_data"

var user

var _join_room_callback
var _join_room_registered: bool = false

func initialize_sdk():
	FusionSdk.id = get_player_id()
	#FusionSdk.my_name = str("MeXa_",randi_range(0, 99999))
	FusionSdk.my_name = get_player_name()
	FusionSdk.my_team_name = FusionSdk.get_random_3_letter_string()
	
	#CrazyGamesBridge.callbacks.ad_started.connect(_on_ad_started)
	#CrazyGamesBridge.callbacks.ad_finished.connect(_on_ad_finished)
	#CrazyGamesBridge.callbacks.ad_error.connect(_on_ad_error)
	check_is_game_audio_muted()
	#load_singleplayer_data()
	#load_multiplayer_data()
	#save_singleplayer_data()
	#delete_data()
	#load_data()
	
	# Listener za situaciju kad je igra vec pokrenuta, a prijatelj klikne "Join"
	register_join_room_listener()
	# Proverava instant multiplayer i inviteParams pri startu igre
	#check_instant_multiplayer_join()

func check_is_on_mobile_device() -> bool:
	return false
	#var system_info: Dictionary = CrazyGamesBridge.get_system_info()
	#var device_type: String = system_info["device"]["type"]
	#var is_mobile: bool = device_type != "desktop"
	#return is_mobile
	#if Bridge.device.type == "desktop":
		#return false
	#return true


func set_language():
	pass
	#Bridge.platform.language
func show_rewarded_ad():
	pass
	#CrazyGames.Ad.requestAd("rewarded", {
		#"adStarted": func():
			#var is_muted_and_paused: bool = true
			#_on_pause_state_changed(is_muted_and_paused),
			#
		#"adFinished": func():
			#var is_muted_and_paused: bool = false
			#_on_pause_state_changed(is_muted_and_paused)
			#rewarded_ad_watched.emit(),
		#
		#
		#"adError": func(error):
			#var is_muted_and_paused: bool = false
			#_on_pause_state_changed(is_muted_and_paused)
			#rewarded_ad_closed_early.emit(),
	#})
func set_game_ready():
	pass
	#Bridge.platform.send_message(Bridge.PlatformMessage.GAME_READY)
func level_started():
	pass
func level_paused():
	pass
func level_resumed():
	pass
func level_completed():
	pass
func level_failed():
	pass
func _on_audio_state_changed(is_enabled):
	var is_muted: bool = not is_enabled
	set_audio_mute(is_muted)
func _on_pause_state_changed(is_paused):
	if not Fusion.is_connected_to_photon():
		get_tree().paused = is_paused
	set_audio_mute(is_paused)
func check_is_game_audio_muted() -> bool:
	return false
	#var is_muted: bool = not Bridge.platform.is_audio_enabled
	#var master_bus_index: int = AudioServer.get_bus_index("Master")
	#AudioServer.set_bus_mute(master_bus_index, is_muted)
	#return is_muted
func set_audio_mute(is_muted: bool):
	AudioManager.is_audio_muted = is_muted
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, is_muted)

func check_is_login_supported() -> bool:
	return true
	#return CrazyGames.User.is_user_account_available()
	#return Bridge.player.is_authorization_supported

func check_is_player_logged_in() -> bool:
	#var user = await CrazyGames.User.get_user_async()
	if user == null:
		return false
	return true
	#return Bridge.player.is_authorized

func save_singleplayer_data():
	pass
func _on_singleplayer_data_saved(success: bool):
	pass

func save_multiplayer_data():
	pass
func get_player_id() -> String:
	return str("Random_ID_", randi_range(0, 999999))
	#return Bridge.player.id
func get_player_name() -> String:
	return str("Guest_",randi_range(0, 999999))

	#var player_name: String = Bridge.player.name
	#if not player_name:
		#player_name = "Player"
	#return player_name

func load_singleplayer_data():
	single_player_data_loaded.emit()
func _on_singleplayer_storage_loaded(success: bool, data):
	pass

func load_multiplayer_data() -> void:
	data_loaded.emit()
	
func delete_data():
	pass

func _on_storage_set_completed(success: bool):
	pass

func _on_multiplayer_data_saved(success: bool):
	pass

func _on_options_storage_set_completed(success: bool):
	pass
func _on_storage_get_completed(success, data):
	if success:
		if data != null:
			pass

func _on_multiplayer_data_loaded(success, data):
	data_loaded.emit()

func _on_storage_delete_completed(success: bool):
	pass

func show_interstitial_ad():
	interstitial_ad_watched.emit()
func _on_interstitial_state_changed(state: String):
	match state:
		"closed":
			interstitial_ad_watched.emit()
		"failed":
			interstitial_ad_watched.emit()

func _on_rewarded_state_changed(state: String):
	match state:
		"rewarded":
			FusionSdk.handle_rewarded_ad_watched(10, 5)
			rewarded_ad_watched.emit()
		"closed":
			rewarded_ad_closed_early.emit()
			
func _on_check_adblock_completed(result: bool):
	pass
	#is_ad_block_enabled = result

func check_is_ad_block_enabled() -> bool:
	return false


# ======================================================================
# INVITE / JOIN ROOM
# ======================================================================

# Poziva se jednom pri startu igre.
# Pokriva: instant multiplayer, invite link (inviteParams) i fallback na URL parametre.

func check_instant_multiplayer_join() -> void:
	if OS.get_name() != "Web":
		return
	is_instant_multiplayer_join = false
	instant_multiplayer_room_name = ""
	
# Cita window.CrazyGames.SDK.game.inviteParams kao JSON, isto kao listener
func _get_initial_invite_params() -> Dictionary:
	if OS.get_name() != "Web":
		return {}
	return {}


func register_join_room_listener() -> void:
	if OS.get_name() != "Web" or _join_room_registered:
		return
	_join_room_callback = JavaScriptBridge.create_callback(_on_join_room_js)
	var window = JavaScriptBridge.get_interface("window")
	window.__godotJoinRoomCb = _join_room_callback
	JavaScriptBridge.eval("""
		window.__godotJoinRoomListener = function(p) {
			window.__godotJoinRoomCb(JSON.stringify(p || {}));
		};
		window.CrazyGames.SDK.game.addJoinRoomListener(window.__godotJoinRoomListener);
	""")
	_join_room_registered = true

func unregister_join_room_listener() -> void:
	if OS.get_name() != "Web" or not _join_room_registered:
		return
	_join_room_registered = false

func _on_join_room_js(args: Array) -> void:
	_handle_invite_params_json(str(args[0]))

func _handle_invite_params_json(json_str: String) -> void:
	return
	#join_room_requested.emit(room_name, is_private)


func generate_invite_url(custom_room_name: String) -> void:
	return
	#invite_url = CrazyGames.Game.request_invite_url({"roomName": custom_room_name, "isPrivate": "true"})

func copy_invite_url() -> void:
	return
	#CrazyGamesBridge.copy_to_clipboard(invite_url)

func get_room_name_from_invite_url() -> String:
	var params: Dictionary = _get_initial_invite_params()
	
	return params["roomName"]

func update_room_status(room_name: String, is_joinable: bool) -> void:
	return

func sdk_left_room() -> void:
	return
