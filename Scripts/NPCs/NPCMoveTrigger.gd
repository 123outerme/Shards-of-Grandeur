extends Area2D

@onready var NavAgent: NavigationAgent2D = get_node("../NavAgent")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_entered(area):
	if area.name == "PlayerEventCollider":
		NavAgent.update_target_pos()
	pass # Replace with function body.
