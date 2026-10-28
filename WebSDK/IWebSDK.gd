@abstract
class_name IWebSDK extends Node

signal rewarded_ad_watched()
signal rewarded_ad_closed_early()
signal interstitial_ad_watched()
signal data_loaded()
signal single_player_data_loaded()

var is_initialized: bool = false
var is_ad_block_enabled: bool = true

var current_selected_level: int = 0
var last_unlocked_singleplayer_level: int = 1

#LEAVE LEVELS
const LEAVE_LEVEL_AMOUNT_BEFORE_AD: int = 2
var remain_left_levels: int = 2 

@abstract
func initialize_sdk();
@abstract
func show_rewarded_ad();
@abstract
func show_interstitial_ad();
@abstract
func set_language();
@abstract
func set_game_ready();
@abstract
func level_started();
@abstract
func level_paused();
@abstract
func level_resumed();
@abstract
func level_completed();
@abstract
func level_failed();
@abstract
func save_singleplayer_data();
@abstract
func load_singleplayer_data();
@abstract
func delete_data();
@abstract
func save_multiplayer_data();
@abstract
func load_multiplayer_data() -> void;
@abstract
func check_is_login_supported() -> bool;
@abstract
func check_is_player_logged_in() -> bool;
@abstract
func get_player_id() -> String;
@abstract
func get_player_name() -> String;
@abstract
func check_is_ad_block_enabled() -> bool;
@abstract
func check_is_on_mobile_device() -> bool;
@abstract
func check_is_game_audio_muted() -> bool;
@abstract
func set_audio_mute(is_muted: bool);
