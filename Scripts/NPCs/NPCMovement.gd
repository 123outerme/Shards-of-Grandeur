extends NavigationAgent2D
class_name NPCMovement

@onready var NPC: NPCScript = get_parent()

@export var targetPoints: Array[Vector2] = []
@export var selectedTarget: int = 0
@export var loops: int = 0 # -1 to loop indefinitely
@export var waitsForMoveTrigger: bool = true
@export var disableMovement: bool = false
@export var maxSpeed = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	if not waitsForMoveTrigger:
		start_movement()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not disableMovement and SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapNavReady and loops != 0:
		var nextPos = get_next_path_position()
		var vel = nextPos - NPC.position
		if vel.length() > maxSpeed * delta:
			vel = vel.normalized() * maxSpeed * delta
		NPC.position += vel
		if vel.length() > 0:
			NPC.npcSprite.play('walk')
		else:
			NPC.npcSprite.play('stand')
		if vel.x < 0:
			NPC.npcSprite.flip_h = true
		if vel.x > 0:
			NPC.npcSprite.flip_h = false

func update_target_pos():
	if disableMovement:
		return
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
	if not disableMovement and loops != 0:
		target_position = targetPoints[selectedTarget]

func _on_target_reached():
	update_target_pos()

func _on_navigation_finished():
	update_target_pos()
