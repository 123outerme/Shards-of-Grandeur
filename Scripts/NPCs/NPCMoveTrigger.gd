extends Area2D

@onready var NavAgent: NPCMovement = get_node("../NavAgent")

func _on_area_entered(area):
	if area.name == "PlayerEventCollider":
		NavAgent.start_movement()
	pass # Replace with function body.
