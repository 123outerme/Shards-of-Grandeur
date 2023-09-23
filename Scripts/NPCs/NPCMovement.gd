extends NavigationAgent2D
class_name NPCMovement

@onready var NPC: CharacterBody2D = get_parent()

@export var targetPoints: Array[Vector2] = []
@export var selectedTarget: int = 0
@export var loops: int = 0 # -1 to loop indefinitely
@export var disableMovement: bool = false
@export var maxSpeed = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not disableMovement:
		var nextPos = get_next_path_position()
		var vel = nextPos - NPC.position
		if vel.length() > maxSpeed * delta:
			vel = vel.normalized() * maxSpeed * delta
		NPC.position += vel
	pass

func update_target_pos():
	if len(targetPoints) > 0:
		selectedTarget = (selectedTarget + 1) % len(targetPoints)
		if selectedTarget == 0:
			if loops == 0 or len(targetPoints) == 1:
				disableMovement = true
				return
			if loops > 0:
				loops -= 1 # don't need to keep track of loops when looping indefinitely
		target_position = targetPoints[selectedTarget]

func start_movement():
	if not disableMovement:
		target_position = targetPoints[selectedTarget]

func _on_target_reached():
	if not disableMovement:
		update_target_pos()
	pass # Replace with function body.
