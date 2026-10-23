class_name LoggedPlayerStats extends Node2D

#LABELS
@onready var player_name_label: Label = $Player_Name_Label
@onready var fans_amount_label: Label = $Fans_Amount_Label
@onready var money_amount_label: Label = $Money_Amount_Label
@onready var current_level_label: Label = $Current_Level_Label
@onready var team_name_label: Label = $Team_Name_Label
@onready var percentage_to_new_level_label: Label = $Progress_Bar/Percentage_To_New_Level_Label
#OTHER NODES
@onready var edit_team_name_button: TextureButton = $Edit_Team_Name_Button
@onready var progress_bar: TextureProgressBar = $Progress_Bar/Progress_Bar

signal edit_team_name_button_pressed()

const NAME_CHANGE_COST: int = 5

var experience_percentage_amount: int
var experience_amount_flat: String

func _ready() -> void:
	connect_to_signals()

func _exit_tree() -> void:
	if FusionSdk.money_spent.is_connected(_on_money_spent):
		FusionSdk.money_spent.disconnect(_on_money_spent)
	if FusionSdk.fans_spent.is_connected(_on_fans_spent):
		FusionSdk.fans_spent.disconnect(_on_fans_spent)

func connect_to_signals():
	FusionSdk.money_spent.connect(_on_money_spent)
	FusionSdk.fans_spent.connect(_on_fans_spent)
	WebSdk.SDK.data_loaded.connect(_on_data_loaded)

func _on_money_spent(amount: int):
	money_amount_label.text = str(FusionSdk.money_amount)

func _on_fans_spent(amount: int):
	fans_amount_label.text = str(FusionSdk.fans_amount)
	
func hide_stats():
	visible = false

func _on_data_loaded() -> void:
	set_player_stats()
#DOBAVITI IZ PLAYGAMA SDK
func set_player_stats():
	get_player_name()
	get_fans_amount()
	get_money_amount()
	get_current_level()
	get_player_team_name()
	get_experience_amount_percentage()
	check_has_money_for_team_name_change()

func get_player_name() -> void:
	player_name_label.text = str("COACH: ", FusionSdk.my_name)
func get_fans_amount() -> void:
	fans_amount_label.text = str(FusionSdk.fans_amount)
func get_money_amount() -> void:
	money_amount_label.text = str(FusionSdk.money_amount)
func get_current_level() -> void:
	current_level_label.text = str(FusionSdk.current_level)
func get_player_team_name() -> void:
	team_name_label.text = str("TEAM: ", FusionSdk.my_team_name)
func get_experience_amount_percentage() -> void:
	var current_experience_amount: float = float(FusionSdk.experience_amount)
	var current_level: int = FusionSdk.current_level
	var experience_to_next_level: float = float(FusionSdk.level_experience_map[current_level])
	experience_percentage_amount = int((current_experience_amount / experience_to_next_level) * 100)
	percentage_to_new_level_label.text = str(experience_percentage_amount, "%")
	progress_bar.value = experience_percentage_amount
	
	experience_amount_flat = str(int(current_experience_amount), "/", int(experience_to_next_level))


func show_experience_amount_flat() -> void:
	percentage_to_new_level_label.text = experience_amount_flat

func show_experience_amount_percentage() -> void:
	percentage_to_new_level_label.text = str(experience_percentage_amount, "%")

func set_player_team_name(team_name: String) -> void:
	var new_display_name: String = str("TEAM: ", team_name)
	team_name_label.text = new_display_name
	FusionSdk.handle_initial_team_name_change(team_name)
	check_has_money_for_team_name_change()
	#PlayGamaSDK.set_team_name()

func check_has_money_for_team_name_change() -> void:
	if FusionSdk.money_amount >= NAME_CHANGE_COST:
		edit_team_name_button.visible = true
	else:
		edit_team_name_button.visible = false


func _on_edit_team_name_button_pressed() -> void:
	edit_team_name_button_pressed.emit()


func _on_percentage_to_new_level_label_mouse_entered() -> void:
	show_experience_amount_flat()


func _on_percentage_to_new_level_label_mouse_exited() -> void:
	show_experience_amount_percentage()
