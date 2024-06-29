extends NavigationAgent2D
class_name NPCMovement

@onready var NPC: NPCScript = get_parent()

@export var targetPoints: Array[NPCMovePoint] = []
@export var selectedTarget: int = 0
@export var loops: int = 0 # -1 to loop indefinitely
@export var waitsForMoveTrigger: bool = true
@export var disableMovement: bool = false
@export var maxSpeed = 40

var reachedTarget: bool = false
var afterMoveWaitAccum: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = maxSpeed
	if not waitsForMoveTrigger:
		start_movement()

func _physics_process(delta):
	if not disableMovement and reachedTarget and selectedTarget < len(targetPoints):
		afterMoveWaitAccum += delta
		if afterMoveWaitAccum >= targetPoints[selectedTarget].pauseSecs:
			afterMoveWaitAccum = 0
			update_target_pos()
		
	if not disableMovement and SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapNavReady and loops != 0:
		var nextPos = get_next_path_position()
		var vel = nextPos - NPC.position
		if vel.length() > maxSpeed * delta:
			vel = vel.normalized() * maxSpeed * delta
		NPC.position += vel
		if vel.x < 0:
			var flip = NPC.facesRight # if right-facing, flip when moving left
			if NPC.walkBackwards:
				flip = not flip # if walking backwards and would flip, don't
			NPC.npcSprite.flip_h = flip
		if vel.x > 0:
			var flip = not NPC.facesRight # if right-facing, don't flip when moving right
			if NPC.walkBackwards:
				flip = not flip # if walking backwards and would flip, don't
			NPC.npcSprite.flip_h = flip
		if vel.length() > 0:
			if NPC.walkBackwards:
				NPC.npcSprite.play_backwards('walk')
			else:
				NPC.npcSprite.play('walk')
		else:
			NPC.npcSprite.play('stand')

func set_target_pos():
	target_position = targetPoints[selectedTarget].position
	if targetPoints[selectedTarget].relativeToCurrentPos:
		target_position += NPC.position

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
		set_target_pos()

func start_movement():
	if not disableMovement and loops != 0 and len(targetPoints) > 0:
		set_target_pos()

func _on_target_reached():
	reachedTarget = true
	afterMoveWaitAccum = 0
	if targetPoints[selectedTarget].pauseSecs <= 0:
		update_target_pos()

func _on_navigation_finished():
	reachedTarget = true
	afterMoveWaitAccum = 0
	if targetPoints[selectedTarget].pauseSecs <= 0:
		update_target_pos()
