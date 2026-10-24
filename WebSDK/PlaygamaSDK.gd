class_name PlaygamaSDK extends IWebSDK

var MULTIPLAYER_STORAGE_KEY: String = "multiplayer_data"
var SINGLEPLAYER_STORAGE_KEY: String = "singleplayer_data"

func initialize_sdk():
	is_initialized = true
	Bridge.advertisement.set_minimum_delay_between_interstitial(30)
	Bridge.platform.connect("audio_state_changed", Callable(self, "_on_audio_state_changed"))
	Bridge.platform.connect("pause_state_changed", Callable(self, "_on_pause_state_changed"))
	Bridge.advertisement.connect("interstitial_state_changed", Callable(self, "_on_interstitial_state_changed"))
	Bridge.advertisement.connect("rewarded_state_changed", Callable(self, "_on_rewarded_state_changed"))
	Bridge.advertisement.check_adblock(Callable(self, "_on_check_adblock_completed"))
	check_is_game_audio_muted()
	load_singleplayer_data()
	#save_singleplayer_data()
	#delete_data()
	#load_data()

func set_language():
	Bridge.platform.language
func show_rewarded_ad():
	Bridge.advertisement.show_rewarded("test_placement")
func set_game_ready():
	Bridge.platform.send_message(Bridge.PlatformMessage.GAME_READY)
func level_started():
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_STARTED)
func level_paused():
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_PAUSED)
func level_resumed():
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_RESUMED)
func level_completed():
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_COMPLETED)
func level_failed():
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_FAILED)

func _on_audio_state_changed(is_enabled):
	var is_muted: bool = not is_enabled
	set_audio_mute(is_muted)
func _on_pause_state_changed(is_paused):
	get_tree().paused = is_paused
	set_audio_mute(is_paused)
func check_is_game_audio_muted():
	var is_muted: bool = not Bridge.platform.is_audio_enabled
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, is_muted)
func set_audio_mute(is_muted: bool):
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, is_muted)

func check_is_login_supported() -> bool:
	return Bridge.player.is_authorization_supported

func check_is_player_logged_in() -> bool:
	return Bridge.player.is_authorized

func save_singleplayer_data():
	Bridge.storage.set(SINGLEPLAYER_STORAGE_KEY, last_unlocked_singleplayer_level, Callable(self, "_on_singleplayer_data_saved"))

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
	
	Bridge.storage.set(MULTIPLAYER_STORAGE_KEY, data_json, Callable(self, "_on_multiplayer_data_saved"))

func get_player_id() -> String:
	return Bridge.player.id
func get_player_name() -> String:
	var player_name: String = Bridge.player.name
	if not player_name:
		player_name = "Player"
	return player_name

func load_singleplayer_data():
	Bridge.storage.get(SINGLEPLAYER_STORAGE_KEY, Callable(self, "_on_singleplayer_storage_loaded"))

func _on_singleplayer_storage_loaded(success: bool, data):
	if success:
		if data != null and data != "":
			last_unlocked_singleplayer_level = int(data)
			current_selected_level = last_unlocked_singleplayer_level
			single_player_data_loaded.emit()

func load_multiplayer_data() -> void:
	Bridge.storage.get(MULTIPLAYER_STORAGE_KEY, Callable(self, "_on_multiplayer_data_loaded"))

func delete_data():
	Bridge.storage.delete([MULTIPLAYER_STORAGE_KEY], Callable(self, "_on_storage_delete_completed"))

func _on_storage_set_completed(success: bool):
	pass

func _on_multiplayer_data_saved(success: bool):
	if success:
		print("Multiplayer data saved!")

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
				data_loaded.emit()
		else:
			FusionSdk.reset_multiplayer_data()
			save_multiplayer_data()
			data_loaded.emit()

func _on_storage_delete_completed(success: bool):
	pass

func show_interstitial_ad():
	Bridge.advertisement.show_interstitial()

func _on_interstitial_state_changed(state: String):
	pass

func _on_rewarded_state_changed(state: String):
	match state:
		"rewarded":
			FusionSdk.handle_rewarded_ad_watched(10, 5)
			rewarded_ad_watched.emit()
		"closed":
			rewarded_ad_closed_early.emit()
			
func _on_check_adblock_completed(result: bool):
	is_ad_block_enabled = result

func check_is_ad_block_enabled() -> bool:
	return is_ad_block_enabled
