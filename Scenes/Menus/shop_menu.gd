class_name ShopMenu extends Node2D

signal fans_spent()
signal money_spent()

const PLAYER_EFFECTS_CARD = preload("uid://duy1m0sfo276v")
const PLAYER_FORMATION_CARD = preload("uid://bqt1r1yn31w8f")

@onready var h_box_container: HBoxContainer = $Cards_Scroll_Container/HBoxContainer

func _ready() -> void:
	FusionSdk.pre_match_info_showed.connect(_on_match_found)
	show_disks_tab()
	add_tab_buttons_to_group()
	
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


func show_disks_tab() -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	for i in range(2):
		var effects_card: EffectsPurchasableCard = PLAYER_EFFECTS_CARD.instantiate()
		effects_card.fast_review_enabled.connect(_on_fast_preview_enabled)
		effects_card.card_selected.connect(_on_effect_selected)
		h_box_container.add_child(effects_card)
		effects_card.set_card_id(i)
	
	var control_dummy_node: Control = Control.new()
	h_box_container.add_child(control_dummy_node)

func show_ball_effects_tab() -> void:
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
