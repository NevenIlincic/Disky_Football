class_name Goal extends StaticBody3D

signal goal_scored(goal_owner: GoalOwner)

enum GoalOwner{
	ME,
	ENEMY
}

var is_scored: bool = false
@export var goal_owner: GoalOwner = GoalOwner.ME

var scene: MultiplayerScene

func _ready() -> void:
	scene = get_tree().get_first_node_in_group("multiplayer_scene")

func reset_entity():
	is_scored = false


func _on_goal_detection_area_body_entered(body: Node3D) -> void:
	if body is Ball:
		if not is_scored:
			is_scored = true
			goal_scored.emit(goal_owner)
			return		
	
	if body is MultiplayerBall and scene.is_my_turn:
		if not is_scored:
			is_scored = true
			goal_scored.emit(goal_owner)
			return
