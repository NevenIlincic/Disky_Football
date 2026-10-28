class_name ShopMenu extends Node2D

signal fans_spent()
signal money_spent()

const PLAYER_EFFECTS_CARD = preload("uid://duy1m0sfo276v")
const PLAYER_FORMATION_CARD = preload("uid://bqt1r1yn31w8f")
const PLAYER_SKIN_CARD = preload("uid://spp2rnvppf0f")

@onready var h_box_container: HBoxContainer = $Cards_Scroll_Container/HBoxContainer

enum CurrentTab {
	DISKS,
	BALL_EFFECTS,
	FORMATIONS
}

var current_tab: CurrentTab = CurrentTab.DISKS
@onready var disk_tab_button: TextureButton = $Disk_Tab_Button
@onready var ball_effects_tab_button: TextureButton = $Ball_Effects_Tab_Button
@onready var formations_tab_button: TextureButton = $Formations_Tab_Button

func _exit_tree() -> void:
	if FusionSdk.pre_match_info_showed.is_connected(_on_match_found):
		FusionSdk.pre_match_info_showed.disconnect(_on_match_found)
	if 	WebSdk.SDK.data_loaded.is_connected(_on_data_loaded):
		WebSdk.SDK.data_loaded.disconnect(_on_data_loaded)
	if WebSdk.SDK.rewarded_ad_watched.is_connected(_on_rewarded_ad_watched):
		WebSdk.SDK.rewarded_ad_watched.disconnect(_on_rewarded_ad_watched)

func _ready() -> void:
	FusionSdk.pre_match_info_showed.connect(_on_match_found)
	WebSdk.SDK.data_loaded.connect(_on_data_loaded)
	WebSdk.SDK.rewarded_ad_watched.connect(_on_rewarded_ad_watched)
	add_tab_buttons_to_group()
	#show_disks_tab()

func _on_data_loaded() -> void:
	show_disks_tab()

func _on_rewarded_ad_watched() -> void:
	match current_tab:
		CurrentTab.DISKS:
			show_disks_tab()
		CurrentTab.BALL_EFFECTS:
			show_ball_effects_tab()
		CurrentTab.FORMATIONS:
			show_formations_tab()

func _on_match_found() -> void:
	visible = false

func add_tab_buttons_to_group():
	var button_group: ButtonGroup = ButtonGroup.new()
	for button in get_tree().get_nodes_in_group("tab_button"):
		var tab_button: TextureButton = button as TextureButton
		tab_button.button_group = button_group
func _on_fast_preview_enabled(card_id: int):
	for child in h_box_container.get_children():
		if child is not EffectsPurchasableCard:
			continue
		var card: EffectsPurchasableCard = child as EffectsPurchasableCard
		if card.card_id == card_id:
			continue
		card.effect_preview_button.button_pressed = false

func _on_effect_selected(card_id: int):
	for child in h_box_container.get_children():
		if child is not EffectsPurchasableCard:
			continue
		var card: EffectsPurchasableCard = child as EffectsPurchasableCard
		card.update_card_display()

func _on_formation_selected(card_id: int):
	for child in h_box_container.get_children():
		if child is not FormationsPurchasableCard:
			continue
		var card: FormationsPurchasableCard = child as FormationsPurchasableCard
		card.update_card_display()

func _on_disk_skin_selected(card_id: int):
	for child in h_box_container.get_children():
		if child is not SkinsPurchasableCard:
			continue
		var card: SkinsPurchasableCard = child as SkinsPurchasableCard
		card.update_card_display()

func show_disks_tab() -> void:
	current_tab = CurrentTab.DISKS
	for child in h_box_container.get_children():
		child.queue_free()
	for i in range(SkinsManager.skins.size()):
		var skin_card: SkinsPurchasableCard = PLAYER_SKIN_CARD.instantiate()
		skin_card.card_selected.connect(_on_disk_skin_selected)
		h_box_container.add_child(skin_card)
		skin_card.set_card_id(i)
	
	var control_dummy_node: Control = Control.new()
	h_box_container.add_child(control_dummy_node)

func show_ball_effects_tab() -> void:
	current_tab = CurrentTab.BALL_EFFECTS
	for child in h_box_container.get_children():
		child.queue_free()
	for i in range(BallEffects.effects.size()):
		var effects_card: EffectsPurchasableCard = PLAYER_EFFECTS_CARD.instantiate()
		effects_card.fast_review_enabled.connect(_on_fast_preview_enabled)
		effects_card.card_selected.connect(_on_effect_selected)
		h_box_container.add_child(effects_card)
		effects_card.set_card_id(i)
	
	var control_dummy_node: Control = Control.new()
	h_box_container.add_child(control_dummy_node)

func show_formations_tab() -> void:
	current_tab = CurrentTab.FORMATIONS
	for child in h_box_container.get_children():
		child.queue_free()
	for i in range(FormationsManager.formations.size()):
		var formations_card: FormationsPurchasableCard = PLAYER_FORMATION_CARD.instantiate()
		formations_card.card_selected.connect(_on_formation_selected)
		h_box_container.add_child(formations_card)
		formations_card.set_card_id(i)
	
	var control_dummy_node: Control = Control.new()
	h_box_container.add_child(control_dummy_node)

func _on_disk_tab_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_disks_tab()


func _on_ball_effects_tab_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_ball_effects_tab()


func _on_formations_tab_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_formations_tab()


func _on_disk_tab_button_mouse_entered() -> void:
	if not disk_tab_button.button_pressed:
		AudioManager.play_hover_sound()


func _on_ball_effects_tab_button_mouse_entered() -> void:
	if not ball_effects_tab_button.button_pressed:
		AudioManager.play_hover_sound()


func _on_formations_tab_button_mouse_entered() -> void:
	if not formations_tab_button.button_pressed:
		AudioManager.play_hover_sound()
