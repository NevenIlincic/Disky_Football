class_name CrazyGamesSdkClass extends IWebSDK

var MULTIPLAYER_STORAGE_KEY: String = "multiplayer_data"
var SINGLEPLAYER_STORAGE_KEY: String = "singleplayer_data"

var user

func initialize_sdk():
	await CrazyGames.is_initialised_async()
	is_initialized = true
	is_ad_block_enabled = CrazyGames.has_adblock
	user = await CrazyGames.User.get_user_async()
	#FusionSdk.id = str(randi_range(0, 99999))
	FusionSdk.id = get_player_id()
	#FusionSdk.my_name = str("MeXa_",randi_range(0, 99999))
	FusionSdk.my_name = get_player_name()
	
	#check_instant_multiplayer_join()
	#CrazyGamesBridge.callbacks.ad_started.connect(_on_ad_started)
	#CrazyGamesBridge.callbacks.ad_finished.connect(_on_ad_finished)
	#CrazyGamesBridge.callbacks.ad_error.connect(_on_ad_error)
	check_is_game_audio_muted()
	#load_singleplayer_data()
	#load_multiplayer_data()
	#save_singleplayer_data()
	#delete_data()
	#load_data()

func check_is_on_mobile_device() -> bool:
	var system_info: Dictionary = CrazyGamesBridge.get_system_info()
	var device_type: String = system_info["device"]["type"]
	var is_mobile: bool = device_type != "desktop"
	return is_mobile
	#if Bridge.device.type == "desktop":
		#return false
	#return true


func set_language():
	pass
	#Bridge.platform.language
func show_rewarded_ad():
	CrazyGames.Ad.requestAd("rewarded", {
		"adStarted": func():
			var is_muted_and_paused: bool = true
			_on_pause_state_changed(is_muted_and_paused),
			
		"adFinished": func():
			var is_muted_and_paused: bool = false
			_on_pause_state_changed(is_muted_and_paused)
			rewarded_ad_watched.emit(),
		
		
		"adError": func(error):
			var is_muted_and_paused: bool = false
			_on_pause_state_changed(is_muted_and_paused)
			rewarded_ad_closed_early.emit(),
	})
func set_game_ready():
	pass
	#Bridge.platform.send_message(Bridge.PlatformMessage.GAME_READY)
func level_started():
	CrazyGames.Game.gameplay_start()
func level_paused():
	CrazyGames.Game.gameplay_stop()
func level_resumed():
	CrazyGames.Game.gameplay_start()
func level_completed():
	CrazyGames.Game.gameplay_stop()
func level_failed():
	CrazyGames.Game.gameplay_stop()
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
	return CrazyGames.User.is_user_account_available()
	#return Bridge.player.is_authorization_supported

func check_is_player_logged_in() -> bool:
	#var user = await CrazyGames.User.get_user_async()
	if user == null:
		return false
	return true
	#return Bridge.player.is_authorized

func save_singleplayer_data():
	CrazyGames.Data.data_set_item(SINGLEPLAYER_STORAGE_KEY, str(last_unlocked_singleplayer_level))

func _on_singleplayer_data_saved(success: bool):
	pass

func save_multiplayer_data():
	var data_to_save: Dictionary = {
		"team_name": FusionSdk.my_team_name,
		"money": FusionSdk.money_amount,
		"fans": FusionSdk.fans_amount,
		"experience": FusionSdk.experience_amount,
		"level": FusionSdk.current_level,
		"selected_skin_id": SkinsManager.get_selected_skin_id(),
		"purchased_skins_ids": SkinsManager.get_purchased_skins_ids(),
		"selected_ball_effect_id": BallEffects.get_selected_ball_effect_id(),
		"purchased_ball_effects_ids": BallEffects.get_purchased_ball_effects_ids(),
		"selected_formation_id": FormationsManager.get_selected_formation_id(),
		"purchased_formations_ids": FormationsManager.get_purchased_formations_id()
	}
	var data_json: String = JSON.stringify(data_to_save)
	CrazyGames.Data.data_set_item(MULTIPLAYER_STORAGE_KEY, data_json)
	#Bridge.storage.set(MULTIPLAYER_STORAGE_KEY, data_json, Callable(self, "_on_multiplayer_data_saved"))

func get_player_id() -> String:
	if user:
		return user["__dangerousUserId"]
	return ""
	#return Bridge.player.id
func get_player_name() -> String:
	if user:
		return user["username"]
	return ""
	#var player_name: String = Bridge.player.name
	#if not player_name:
		#player_name = "Player"
	#return player_name

func load_singleplayer_data():
	if CrazyGames.Data.data_has_key(SINGLEPLAYER_STORAGE_KEY):
		last_unlocked_singleplayer_level = int(CrazyGames.Data.data_get_item(SINGLEPLAYER_STORAGE_KEY))
		current_selected_level = last_unlocked_singleplayer_level
	else:
		last_unlocked_singleplayer_level = 1
		current_selected_level = 0
		save_singleplayer_data()
		
	await get_tree().create_timer(0.2).timeout
	single_player_data_loaded.emit()
func _on_singleplayer_storage_loaded(success: bool, data):
	pass
	#if success:
		#if data != null and data != "":
			#last_unlocked_singleplayer_level = int(data)
			#current_selected_level = last_unlocked_singleplayer_level
		#else:
			#last_unlocked_singleplayer_level = 1
			#current_selected_level = 0
			#save_singleplayer_data()
	#
	#await get_tree().create_timer(0.1).timeout
	#single_player_data_loaded.emit()

func load_multiplayer_data() -> void:
	if CrazyGames.Data.data_has_key(MULTIPLAYER_STORAGE_KEY):
		var data: String = CrazyGames.Data.data_get_item(MULTIPLAYER_STORAGE_KEY)
		if data == "":
				FusionSdk.reset_multiplayer_data()
				save_multiplayer_data()
				return
		var json: JSON = JSON.new()
		var parse_result = json.parse(data)
		if parse_result == OK:
			var multiplayer_stats: Dictionary = json.data
			FusionSdk.my_team_name = multiplayer_stats["team_name"]
			FusionSdk.money_amount = int(multiplayer_stats["money"])
			FusionSdk.fans_amount = int(multiplayer_stats["fans"])
			FusionSdk.experience_amount = int(multiplayer_stats["experience"])
			FusionSdk.current_level = int(multiplayer_stats["level"])
			SkinsManager.selected_skin = int(multiplayer_stats["selected_skin_id"])
			SkinsManager.purchased_skins_ids.assign(multiplayer_stats["purchased_skins_ids"].map(func(v): return int(v)))
			BallEffects.selected_effect = int(multiplayer_stats["selected_ball_effect_id"])
			BallEffects.purchased_effects_id.assign(multiplayer_stats["purchased_ball_effects_ids"].map(func(v): return int(v)))
			FormationsManager.selected_formation = int(multiplayer_stats["selected_formation_id"])
			FormationsManager.purchased_formations_id.assign(multiplayer_stats["purchased_formations_ids"].map(func(v): return int(v)))
		else:
			FusionSdk.reset_multiplayer_data()
			save_multiplayer_data()
	else:
		FusionSdk.reset_multiplayer_data()
		save_multiplayer_data()
	
	await get_tree().create_timer(0.5).timeout
	data_loaded.emit()
	
	#Bridge.storage.get(MULTIPLAYER_STORAGE_KEY, Callable(self, "_on_multiplayer_data_loaded"))

func delete_data():
	pass
	#Bridge.storage.delete([MULTIPLAYER_STORAGE_KEY], Callable(self, "_on_storage_delete_completed"))

func _on_storage_set_completed(success: bool):
	pass

func _on_multiplayer_data_saved(success: bool):
	pass
	#if success:
		#print("Multiplayer data saved!")

func _on_options_storage_set_completed(success: bool):
	pass
func _on_storage_get_completed(success, data):
	if success:
		if data != null:
			pass

func _on_multiplayer_data_loaded(success, data):
	if success:
		if data != null:
			if data == "":
				FusionSdk.reset_multiplayer_data()
				save_multiplayer_data()
				return
			var json: JSON = JSON.new()
			var parse_result = json.parse(data)
			if parse_result == OK:
				var multiplayer_stats: Dictionary = json.data
				FusionSdk.my_team_name = multiplayer_stats["team_name"]
				FusionSdk.money_amount = int(multiplayer_stats["money"])
				FusionSdk.fans_amount = int(multiplayer_stats["fans"])
				FusionSdk.experience_amount = int(multiplayer_stats["experience"])
				FusionSdk.current_level = int(multiplayer_stats["level"])
				SkinsManager.selected_skin = int(multiplayer_stats["selected_skin_id"])
				SkinsManager.purchased_skins_ids.assign(multiplayer_stats["purchased_skins_ids"].map(func(v): return int(v)))
				BallEffects.selected_effect = int(multiplayer_stats["selected_ball_effect_id"])
				BallEffects.purchased_effects_id.assign(multiplayer_stats["purchased_ball_effects_ids"].map(func(v): return int(v)))
				FormationsManager.selected_formation = int(multiplayer_stats["selected_formation_id"])
				FormationsManager.purchased_formations_id.assign(multiplayer_stats["purchased_formations_ids"].map(func(v): return int(v)))
		else:
			FusionSdk.reset_multiplayer_data()
			save_multiplayer_data()
	await get_tree().create_timer(0.5).timeout
	data_loaded.emit()

func _on_storage_delete_completed(success: bool):
	pass

func show_interstitial_ad():
	interstitial_ad_watched.emit()
	#CrazyGames.Ad.requestAd("midgame", {
		#"adStarted": func():
			#var is_muted_and_paused: bool = true
			#_on_pause_state_changed(is_muted_and_paused),
			#
		#"adFinished": func():
			#var is_muted_and_paused: bool = false
			#_on_pause_state_changed(is_muted_and_paused)
			#interstitial_ad_watched.emit(),
		#
		#
		#"adError": func(error):
			#var is_muted_and_paused: bool = false
			#_on_pause_state_changed(is_muted_and_paused)
			#interstitial_ad_watched.emit(),
	#})

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
	return CrazyGames.has_adblock

func check_instant_multiplayer_join() -> void:
	if OS.get_name() == "Web":
		var is_instant: bool = bool(JavaScriptBridge.eval("!!(window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game && window.CrazyGames.SDK.game.isInstantMultiplayer)"))
		print("INSTANT: ", is_instant)
		if is_instant:
			is_instant_multiplayer_join = true
			instant_multiplayer_room_name = ""
			if not Fusion.is_connected_to_photon():
				await FusionSdk.connect_to_server()
		else:
			is_instant_multiplayer_join = false
			var room_name: String = CrazyGames.Game.get_invite_link_param("roomName")
			var is_private_str: String = CrazyGames.Game.get_invite_link_param("isPrivate")
			
			if is_private_str != "":
				FusionSdk.is_in_private_room = true if is_private_str == "true" else false
				print("IS PRIVATE ROOM: ", FusionSdk.is_in_private_room)
			if room_name != "":
				instant_multiplayer_room_name = room_name
				print("[INSTANT MULTIPLAYER] Detektovan ulaz preko SDK-a: ", room_name)
				if not Fusion.is_connected_to_photon():
					await FusionSdk.connect_to_server()
			else:
				instant_multiplayer_room_name = ""				
			
				
func generate_invite_url(custom_room_name: String) -> void:
	invite_url = CrazyGames.Game.request_invite_url({"roomName": custom_room_name, "isPrivate": "true"})

func copy_invite_url() -> void:
	CrazyGamesBridge.copy_to_clipboard(invite_url)

func get_room_name_from_invite_url() -> String:
	return CrazyGames.Game.get_invite_link_param("roomName")

func update_room_status(room_name: String, is_joinable: bool) -> void:
	if not Fusion.is_connected_to_photon() or not Fusion.is_master_client():
		return
		
	if OS.get_name() == "Web":
		var is_private_room_str: String = "true" if FusionSdk.is_in_private_room else "false"
		var joinable_str = "true" if is_joinable else "false"
		var js_code = """
			if (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game) {
				window.CrazyGames.SDK.game.updateRoom({
					roomId: '%s',
					isJoinable: %s,
					inviteParams: { 
						roomName: '%s',
						isPrivate: %s }
				});
			}
		""" % [room_name, joinable_str, room_name, is_private_room_str]
		
		JavaScriptBridge.eval(js_code)

func sdk_left_room() -> void:
	if OS.get_name() == "Web":
		var js_code = """
			if (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game) {
				window.CrazyGames.SDK.game.leftRoom();
			}
		"""
		JavaScriptBridge.eval(js_code)
