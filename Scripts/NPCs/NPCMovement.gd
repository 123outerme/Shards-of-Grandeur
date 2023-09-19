extends NavigationAgent2D

@onready var NPC: CharacterBody2D = get_parent()

@export var target_points: Array[Vector2] = []
@export var selected_target: int = 0
@export var loops: int = -1
@export var disableMovement: bool = false
@export var maxSpeed = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not disableMovement:
		var nextPos = get_next_path_position()
		var velocity = nextPos - NPC.position
		if velocity.length() > maxSpeed * delta:
			velocity = velocity.normalized() * maxSpeed * delta
		NPC.position += velocity
	pass

func update_target_pos():
	if len(target_points) > 0:
		selected_target = (selected_target + 1) % len(target_points)
		if selected_target == 0:
			loops -= 1
			if loops == 0:
				disableMovement = true
				return
		target_position = target_points[selected_target]


func _on_target_reached():
	if not disableMovement:
		update_target_pos()
	pass # Replace with function body.
