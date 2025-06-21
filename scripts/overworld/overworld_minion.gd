extends CharacterBody2D
class_name OverworldMinion

const MAX_SEPARATION_DISTANCE: float = 100.0

@export var minion: Combatant = null

var facesRight: bool = false
var spriteOffset: Vector2 = Vector2.ZERO
var spriteSize: Vector2 = Vector2.ZERO

var disableMovement: bool = false
var speed: float = 40
var maxSpeed: float = 40
var targetPos: Vector2 = Vector2.ZERO
var lastNonzeroPlayerVelocity: Vector2 = Vector2.ZERO


@onready var sprite: AnimatedSprite2D = get_node('MinionSprite')
@onready var navAgent: NavigationAgent2D = get_node('NavAgent')

func _process(delta: float) -> void:
	if can_move():
		set_target_pos()
	
	var vel: Vector2 = Vector2.ZERO
	if can_move() and SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapNavReady:
		#print(NPC.name, ' ', target_position)
		var nextPos: Vector2 = navAgent.get_next_path_position()
		# if the follower is not able to go to the next target pos; ignore nav meshes and move straight there
		#if not navAgent.is_target_reachable():
		#	nextPos = get_following_target_position()
		
		# if the target is no longer reachable and the follower is too far from it; teleport there
		if not navAgent.is_target_reachable() and (position - targetPos).length() > MAX_SEPARATION_DISTANCE:
			position = targetPos
			sprite.play('stand')
			# TODO: maybe play a special animation for the teleport?
			return
		
		vel = nextPos - position
		if disableMovement:
			# if movement is disabled by calculating the next path: cancel this movement now
			vel = Vector2.ZERO
		
		if vel.length() > maxSpeed * delta:
			vel = vel.normalized() * maxSpeed * delta
		position += vel
		if vel.x < -maxSpeed * 0.1 * delta:
			var flip: bool = facesRight # if right-facing, flip when moving left
			sprite.flip_h = flip
			update_facing()
		if vel.x > maxSpeed * 0.1 * delta:
			var flip: bool = not facesRight # if right-facing, don't flip when moving right
			sprite.flip_h = flip
			update_facing()
		if vel.length_squared() > 0:
			sprite.play('walk')
		else:
			sprite.play('stand')

func load_overworld_minion(resetPosition: bool = false) -> void:
	if minion == null:
		visible = false
		disableMovement = true
		return
	
	visible = true
	disableMovement = false
	sprite.sprite_frames = minion.get_sprite_frames()
	facesRight = minion.get_sprite_obj().spriteFacesRight
	sprite.flip_h = facesRight
	update_facing()
	sprite.play('stand')
	var combatantOverworld: CombatantOverworld = minion.get_sprite_obj().combatantOverworld
	if combatantOverworld != null:
		spriteOffset = combatantOverworld.encounterSpriteOffset
		sprite.offset = spriteOffset
	
	if resetPosition:
		position = PlayerFinder.player.position
	navAgent.navigation_layers = minion.get_nav_layer()
	navAgent.radius = (max(minion.get_max_size().x, minion.get_max_size().y) / 2) - 1

func set_target_pos():
	if PlayerFinder.player != null:
		targetPos = get_following_target_position()
		navAgent.target_position = targetPos
		maxSpeed = PlayerFinder.player.speed * 1.2

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
			targetPos.x -= spriteSize.x * 1.4 # target left of player to move next to
		else:
			targetPos.x += spriteSize.x * 1.4 # target right of player to move next to
		if playerVelocity.y > 0:
			targetPos.y -= spriteSize.y * 1.4 # target bottom of player to move next to
		else:
			targetPos.y += spriteSize.y * 1.4 # target top of player to move next to
	elif playerVelocity.x != 0:
		# player is moving along X, meaning move to left/right of player (1.5x the size of the NPC away)
		if playerVelocity.x > 0:
			targetPos.x -= spriteSize.x * 1.5 # target left of player to move next to
		else:
			targetPos.x += spriteSize.x * 1.5 # target right of player to move next to
	elif playerVelocity.y != 0:
		# player is moving along Y, meaning move to top/bottom of player (1.5x the size of the NPC away)
		if playerVelocity.y > 0:
			targetPos.y -= spriteSize.y * 1.5 # target bottom of player to move next to
		else:
			targetPos.y += spriteSize.y * 1.5 # target top of player to move next to
	return targetPos

func can_move() -> bool:
	return not disableMovement and not (PlayerFinder.player != null and PlayerFinder.player.inCutscene)

func update_facing() -> void:
	sprite.offset = spriteOffset
	if sprite.flip_h != facesRight:
		sprite.offset.x *= -1
