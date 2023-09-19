extends CharacterBody2D

const SPEED = 80
@export var disableMovement: bool

@onready var SaveHandler: SaveHandler = get_node("/root/SaveHandler")

func _physics_process(delta):
	if not disableMovement:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * SPEED
		move_and_slide()
	
	if Input.is_action_just_pressed("game_pause"):
		SaveHandler.save_data()
