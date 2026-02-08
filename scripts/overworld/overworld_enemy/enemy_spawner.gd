extends Node2D
class_name EnemySpawner

const enemiesDir: String = 'enemies/'

## the spawner's unique data
@export var spawnerData: SpawnerData = SpawnerData.new()

## the encounter to trigger when the enemy hits the player
@export var enemyEncounter: EnemyEncounter = null

## if not valid, will disable the spawner
@export var storyRequirements: Array[StoryRequirements] = []

## if true, this spawner can spawn an enemy when the player cannot move. Useful for spawning enemies as part of a cutscene
@export var spawnWhenPlayerLocked: bool = false

## radius of the circle the enemy can spawn in
@export var spawnRange: float = 48.0

## radius of the circle the enemy will patrol in
@export var enemyPatrolRange: float = 32.0

## Only if overrides, radius of the circle the enemy will chase the player within
@export var enemyChaseRange: float = 48.0

## Only if overrides, radius of the circle the enemy will chase the player within while the player is running
@export var enemyRunningChaseRange: float = 96

## if true, the above values will override the combatant's chase ranges
@export var overrideEnemyRanges: bool = false

## Once the enemy gets this many units away from the player, they will automatically despawn
@export var enemyDespawnRange: float = 960.0

## Only if overrides, the max speed of the enemy
@export var enemyMaxSpeed: float = 40

## Only if overrides, the max speed of the enemy while it is chasing a player that it caught running
@export var enemyRunningMaxSpeed: float = 80

## if true, the above values will override the combatant's speeds
@export var overrideEnemySpeeds: bool = false

## set before loading; points to the tilemap to place the enemy object in
@export var tilemap: Node2D

## if true, will not print errors/warnings when data is invalid. ONLY FOR USE FOR WIP SPAWNERS IN WIP AREAS
@export var quietWarnings: bool = false

@export_storage var enemy: OverworldEnemy = null

var spawnedLastEncounterDisabled: bool = false
var overworldEnemyScene = load("res://prefabs/entities/overworld_enemy.tscn")

@onready var spawnArea: Area2D = get_node('SpawnArea')
@onready var shape: CollisionShape2D = get_node("SpawnArea/SpawnShape")

func _ready():
	if spawnerData == null:
		if not quietWarnings:
			printerr('EnemySpawner (name ', name, ') error: no spawner data defined')
		queue_free()
		return
	if enemyEncounter == null:
		if not quietWarnings:
			printerr('EnemySpawner ', spawnerData.spawnerId, ' (name ', name, ') error: no encounter defined')
		queue_free()
		return
	if tilemap == null:
		if not quietWarnings:
			printerr('EnemySpawner ', spawnerData.spawnerId, ' (name ', name, ') error: Tilemap root node not defined')
		queue_free()
		return
	if enemyEncounter.combatant1 == null:
		if not quietWarnings:
			printerr('EnemySpawner ', spawnerData.spawnerId, ' (name ', name, ') error: no combatant1 provided')
		queue_free()
	
	PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	_story_reqs_updated()
	
	spawn_enemy()

func _on_area_2d_area_entered(area):
	if enemy == null and area.name == 'PlayerEventCollider' and not spawnerData.disabled and (not PlayerFinder.player.disableMovement or spawnWhenPlayerLocked):
		spawn_enemy()
	if enemy != null and area.name == 'PlayerEventCollider' and enemy.disabled and not spawnerData.disabled and (not PlayerFinder.player.disableMovement or spawnWhenPlayerLocked):
		enemy.disabled = false
		var angleRadians = randf_range(0, 2 * PI)
		var radius: float = randf_range(0, spawnRange / 2.0) # range in diameter, so half of that
		var enemyPos: Vector2 = position + (Vector2(cos(angleRadians), sin(angleRadians)).normalized() * radius)
		# generate random point on unit circle and ensure it's exactly on the circle, multiplied by a random radius
		# all for a random position inside a circle of size `spawnRange` centered around the spawner
		enemy.position = enemyPos
		enemy.enemyData.position = enemyPos

func spawn_enemy() -> void:
	if enemy == null and enemyEncounter != null and enemyEncounter.combatant1 != null:
		enemy = overworldEnemyScene.instantiate()
		enemy.disabled = true
		enemy.spawner = self
		enemy.enemyData = OverworldEnemyData.new(enemyEncounter.combatant1.copy(), Vector2.ZERO, false, enemyEncounter, false)
		enemy.homePoint = position
		enemy.patrolRange = enemyPatrolRange
		enemy.despawnRange = enemyDespawnRange
		enemy.chaseRange = enemyChaseRange
		enemy.runningChaseRange = enemyRunningChaseRange
		enemy.overrideRanges = overrideEnemyRanges
		enemy.maxSpeed = enemyMaxSpeed
		enemy.runningMaxSpeed = enemyRunningMaxSpeed
		enemy.overrideSpeeds = overrideEnemySpeeds
		tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.
		#print('spawned new enemy')

func save_data(save_path) -> int:
	if spawnerData != null:
		spawnerData.enemyData = null
		if enemy != null and not enemy.encounteredPlayer:
			spawnerData.enemyData = OverworldEnemyData.new(enemyEncounter.combatant1, enemy.position, enemy.disableMovement, enemyEncounter, enemy.runningChaseMode, enemy.disabled)
		return spawnerData.save_data(save_path + enemiesDir, spawnerData)
	else:
		return 0

func load_data(save_path):
	var newData = spawnerData.load_data(save_path + enemiesDir)
	if newData != null:
		spawnerData = newData
		var importantFight: bool = false
		if enemyEncounter is StaticEncounter:
			var staticEncounter: StaticEncounter = enemyEncounter as StaticEncounter
			importantFight = staticEncounter.bossBattle or not staticEncounter.canEscape
		if spawnerData.enemyData != null:
			if enemy == null:
				spawn_enemy()
			if enemy != null:
				enemy.disabled = spawnerData.enemyData.disabled
				enemy.spawner = self
				enemy.enemyData = spawnerData.enemyData
				enemy.position = spawnerData.enemyData.position
			if spawnerData.disabled or importantFight:
				spawnerData.disabled = false # re-enable if this is the second time it's loaded after causing an encounter
		if spawnerData.spawnedLastEncounter:
			spawnerData.spawnedLastEncounter = false
			if not importantFight:
				spawnerData.disabled = true # disable if it caused the last encounter
				spawnedLastEncounterDisabled = true
	if storyRequirements != null and not StoryRequirements.list_is_valid(storyRequirements):
		spawnerData.disabled = true

func delete_enemy():
	if enemy != null:
		enemy.queue_free()
	enemy = null
	spawnerData.enemyData = null

func get_save_filename() -> String:
	return enemiesDir

func _story_reqs_updated() -> void:
	if storyRequirements != null and not StoryRequirements.list_is_valid(storyRequirements):
		spawnerData.disabled = true
		if enemy != null:
			enemy.disabled = true
	elif not spawnedLastEncounterDisabled:
		spawnerData.disabled = false
