class_name Goal extends StaticBody3D

signal goal_scored(goal_owner: GoalOwner)

enum GoalOwner{
	ME,
	ENEMY
}

var is_scored: bool = false
@export var goal_owner: GoalOwner = GoalOwner.ME

func reset_entity():
	is_scored = false


func _on_goal_detection_area_body_entered(body: Node3D) -> void:
	if body is Ball:
		if not is_scored:
			is_scored = true
			goal_scored.emit(goal_owner)
