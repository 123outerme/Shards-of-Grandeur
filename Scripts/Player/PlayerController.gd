extends CharacterBody2D

const SPEED = 80
@export var disableMovement: bool

@onready var SaveHandler: SaveHandler = get_node("/root/SaveHandler")

func _physics_process(delta):
	if not disableMovement:
		velocity = Vector2.ZERO
		if Input.is_action_pressed("move_up"):
			velocity += Vector2.UP
		if Input.is_action_pressed("move_down"):
			velocity += Vector2.DOWN
		if Input.is_action_pressed("move_left"):
			velocity += Vector2.LEFT
		if Input.is_action_pressed("move_right"):
			velocity += Vector2.RIGHT
		velocity = velocity.normalized() * SPEED
		move_and_slide()
	
	if Input.is_action_just_pressed("game_pause"):
		SaveHandler.save_data()
