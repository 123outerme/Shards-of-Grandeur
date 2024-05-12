extends CharacterBody2D
class_name OverworldEnemy

@export var combatant: Combatant
@export var disableMovement: bool = false
@export var maxSpeed = 40
@export var patrolling: bool = true
@export var patrolWaitSecs: float = 1.0
@export var enemyData: OverworldEnemyData = OverworldEnemyData.new()

var spawner: EnemySpawner = null
var homePoint: Vector2
var patrolRange: float
var encounteredPlayer: bool = false
var waitUntilNavReady: bool = false

@onready var enemySprite: AnimatedSprite2D = get_node("AnimatedEnemySprite")
@onready var navAgent: NavigationAgent2D = get_node("NavAgent")
@onready var chaseRangeShape: CollisionShape2D = get_node("ChaseRange/ChaseRangeShape")

# NOTE: for saving data, the complete filepath comes from the EnemySpawner itself to preserve spawner state
# so all that needs to be used for save/load functionality is the save_path coming through

func _ready():
	combatant = enemyData.combatant
	enemySprite.sprite_frames = combatant.get_sprite_frames()
	position = get_point_around_home() # throw out position and load from random point near home
	#position = enemyData.position
	disableMovement = enemyData.disableMovement
	navAgent.navigation_layers = combatant.get_nav_layer()
	navAgent.radius = (max(combatant.get_max_size().x, combatant.get_max_size().y) / 2) - 1
	navAgent.max_speed = maxSpeed
	var rangeCircle: CircleShape2D = chaseRangeShape.shape as CircleShape2D
	rangeCircle.radius = 48 + (max(combatant.get_max_size().x, combatant.get_max_size().y) / 2)
	if patrolling:
		get_next_patrol_target()

func _process(delta):
	if waitUntilNavReady:
		get_next_patrol_target()
	
	if not disableMovement and SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapNavReady and not PlayerFinder.player.disableMovement:
		if not patrolling:
			navAgent.target_position = PlayerFinder.player.position
		var nextPos = navAgent.get_next_path_position()
		var vel = nextPos - position
		if vel.length() > maxSpeed * delta:
			vel = vel.normalized() * maxSpeed * delta
		position += vel
		if vel.x < 0:
			enemySprite.flip_h = false
		if vel.x > 0:
			enemySprite.flip_h = true
		if vel.length() > 0:
			enemySprite.play('walk')
		else:
			enemySprite.play('stand')

func get_next_patrol_target():
	if SceneLoader.mapLoader != null and not SceneLoader.mapLoader.mapNavReady:
		waitUntilNavReady = true
		return
		
	waitUntilNavReady = false
	
	if patrolRange == 0:
		disableMovement = true
		return
		
	navAgent.target_position = get_point_around_home()

func get_point_around_home() -> Vector2:
	# generate random point on unit circle and ensure it's exactly on the circle, multiplied by a random radius
	# all for a random position inside a circle of size `patrolRange` centered around the home point
	var angleRadians = randf_range(0, 2 * PI)
	var radius: float = randf_range(0, patrolRange / 2.0) # range is diameter, so half that
	return homePoint + Vector2(cos(angleRadians), sin(angleRadians)).normalized() * radius

func pause_movement():
	disableMovement = true
	enemySprite.play('stand')

func unpause_movement():
	if patrolRange != 0:
		disableMovement = false

func _on_chase_range_area_entered(area):
	if area.name == "PlayerEventCollider":
		patrolling = false
		navAgent.avoidance_enabled = true
		
func _on_chase_range_area_exited(area):
	if area.name == "PlayerEventCollider":
		patrolling = true
		navAgent.avoidance_enabled = false
		get_next_patrol_target()

func _on_nav_agent_navigation_finished():
	await get_tree().create_timer(patrolWaitSecs).timeout
	get_next_patrol_target()

func _on_nav_agent_target_reached():
	await get_tree().create_timer(patrolWaitSecs).timeout
	get_next_patrol_target()

func _on_encounter_collider_area_entered(area):
	if area.name == "PlayerEventCollider" and spawner != null:
		if not PlayerFinder.player.inCutscene:
			# start battle encounter
			spawner.spawnerData.spawnedLastEncounter = true
			PlayerResources.playerInfo.encounter = enemyData.encounter
			encounteredPlayer = true
			PlayerFinder.player.start_battle()
			SceneLoader.pause_autonomous_movers()
		else:
			queue_free() # despawn enemy if encountered during a cutscene
