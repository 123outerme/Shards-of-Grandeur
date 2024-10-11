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
var followerMode: bool = false
var returnToFollowerHome: bool = false
var lastNonzeroPlayerVelocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = maxSpeed
	if not waitsForMoveTrigger:
		start_movement()

func _physics_process(delta):
	if not disableMovement:
		if not followerMode and not returnToFollowerHome and reachedTarget and selectedTarget < len(targetPoints):
			afterMoveWaitAccum += delta
			if afterMoveWaitAccum >= targetPoints[selectedTarget].pauseSecs:
				afterMoveWaitAccum = 0
				update_target_pos()
		elif followerMode or returnToFollowerHome:
			update_target_pos()
	
	var vel: Vector2 = Vector2.ZERO
	if not disableMovement and SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapNavReady and (loops != 0 or followerMode or returnToFollowerHome):
		#print(NPC.name, ' ', target_position)
		var nextPos: Vector2 = get_next_path_position()
		if followerMode and not is_target_reachable():
			nextPos = get_following_target_position()
		vel = nextPos - NPC.position
		if disableMovement:
			# if movement is disabled by calculating the next path: cancel this movement now
			vel = Vector2.ZERO
		
		if vel.length() > max_speed * delta:
			vel = vel.normalized() * max_speed * delta
		NPC.position += vel
		if vel.x < 0:
			var flip: bool = NPC.facesRight # if right-facing, flip when moving left
			if NPC.walkBackwards:
				flip = not flip # if walking backwards and would flip, don't
			NPC.npcSprite.flip_h = flip
		if vel.x > 0:
			var flip: bool = not NPC.facesRight # if right-facing, don't flip when moving right
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
	if not followerMode and not returnToFollowerHome:
		target_position = targetPoints[selectedTarget].position
		if targetPoints[selectedTarget].relativeToCurrentPos:
			target_position += NPC.position
		max_speed = maxSpeed
	if not followerMode and returnToFollowerHome and NPC.data.followerHomeSet:
		target_position = NPC.data.followerHomePosition
	if followerMode and PlayerFinder.player != null:
		target_position = get_following_target_position()
		max_speed = PlayerFinder.player.speed * 1.2

func update_target_pos():
	if disableMovement:
		return
	if not followerMode and not returnToFollowerHome and len(targetPoints) > 0:
		selectedTarget = (selectedTarget + 1) % len(targetPoints)
		reachedTarget = false
		if selectedTarget == 0:
			if loops == 0 or len(targetPoints) == 1:
				disableMovement = true
				return
			if loops > 0:
				loops -= 1 # don't need to keep track of loops when looping indefinitely
		set_target_pos()
	elif followerMode or returnToFollowerHome:
		set_target_pos()

func start_movement():
	if not disableMovement and ((loops != 0 and len(targetPoints) > 0) or followerMode or returnToFollowerHome):
		set_target_pos()

func set_follower_mode(following: bool, returnToHome: bool) -> void:
	followerMode = following
	if not followerMode:
		max_speed = maxSpeed
	returnToFollowerHome = returnToHome

func get_following_target_position() -> Vector2:
	var playerVelocity: Vector2 = PlayerFinder.player.velocity
	if playerVelocity.length_squared() != 0:
		lastNonzeroPlayerVelocity = playerVelocity
	else:
		playerVelocity = lastNonzeroPlayerVelocity
	var targetPos: Vector2 = PlayerFinder.player.position
	if playerVelocity.x != 0 and playerVelocity.y != 0:
		# move to a diagonal of the player (1.15x the size of the NPC away, cuz diagonal) if the player's moving at a diagonal as well
		if playerVelocity.x > 0:
			targetPos.x -= NPC.spriteSize.x * 1.4 # target left of player to move next to
		else:
			targetPos.x += NPC.spriteSize.x * 1.4 # target right of player to move next to
		if playerVelocity.y > 0:
			targetPos.y -= NPC.spriteSize.y * 1.4 # target bottom of player to move next to
		else:
			targetPos.y += NPC.spriteSize.y * 1.4 # target top of player to move next to
	elif playerVelocity.x != 0:
		# player is moving along X, meaning move to left/right of player (1.5x the size of the NPC away)
		if playerVelocity.x > 0:
			targetPos.x -= NPC.spriteSize.x * 1.5 # target left of player to move next to
		else:
			targetPos.x += NPC.spriteSize.x * 1.5 # target right of player to move next to
	elif playerVelocity.y != 0:
		# player is moving along Y, meaning move to top/bottom of player (1.5x the size of the NPC away)
		if playerVelocity.y > 0:
			targetPos.y -= NPC.spriteSize.y * 1.5 # target bottom of player to move next to
		else:
			targetPos.y += NPC.spriteSize.y * 1.5 # target top of player to move next to
	return targetPos

func _on_target_reached():
	if not followerMode and not returnToFollowerHome and selectedTarget < len(targetPoints):
		reachedTarget = true
		afterMoveWaitAccum = 0
		if targetPoints[selectedTarget].pauseSecs <= 0:
			update_target_pos()
	elif returnToFollowerHome:
		returnToFollowerHome = false
		print('target reached now')
		disableMovement = NPC.data.previousDisableMove or len(targetPoints) == 0 or loops == 0

func _on_navigation_finished():
	if not followerMode and not returnToFollowerHome and selectedTarget < len(targetPoints):
		reachedTarget = true
		afterMoveWaitAccum = 0
		if targetPoints[selectedTarget].pauseSecs <= 0:
			update_target_pos()
	elif returnToFollowerHome:
		returnToFollowerHome = false
		print('finish now')
		disableMovement = NPC.data.previousDisableMove or len(targetPoints) == 0 or loops == 0
