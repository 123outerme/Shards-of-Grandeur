extends Node2D
class_name EnemySpawner

@export var spawnerData: SpawnerData = SpawnerData.new()
@export var enemyEncounter: EnemyEncounter = null
@export var storyRequirements: StoryRequirements = null
@export var spawnWhenPlayerLocked: bool = false
@export var spawnRange: float = 48.0
@export var enemyPatrolRange: float = 32.0
@export var tilemap: TileMap
@export var enemy: OverworldEnemy = null

var overworldEnemyScene = load("res://prefabs/entities/overworld_enemy.tscn")
var enemiesDir: String = 'enemies/'

@onready var spawnArea: Area2D = get_node('SpawnArea')
@onready var shape: CollisionShape2D = get_node("SpawnArea/SpawnShape")

func _ready():
	if enemyEncounter.combatant1 == null:
		printerr('EnemySpawner ', spawnerData.spawnerId, ' error: no combatant1 provided')
		queue_free()

func _on_area_2d_area_entered(area):
	if enemy == null and area.name == 'PlayerEventCollider' and not spawnerData.disabled and spawnWhenPlayerLocked == PlayerFinder.player.disableMovement:
		var angleRadians = randf_range(0, 2 * PI)
		var radius: float = randf_range(0, spawnRange / 2.0) # range in diameter, so half of that
		var enemyPos: Vector2 = position + (Vector2(cos(angleRadians), sin(angleRadians)).normalized() * radius)
		# generate random point on unit circle and ensure it's exactly on the circle, multiplied by a random radius
		# all for a random position inside a circle of size `spawnRange` centered around the spawner
		enemy = overworldEnemyScene.instantiate()
		enemy.spawner = self
		enemy.enemyData = OverworldEnemyData.new(enemyEncounter.combatant1, enemyPos, false, enemyEncounter)
		enemy.homePoint = position
		enemy.patrolRange = enemyPatrolRange
		tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.
		#print('spawned new enemy')

func save_data(save_path) -> int:
	if spawnerData != null:
		spawnerData.enemyData = null
		if enemy != null and not enemy.encounteredPlayer:
			spawnerData.enemyData = OverworldEnemyData.new(enemyEncounter.combatant1, enemy.position, enemy.disableMovement, enemyEncounter)
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
			enemy = overworldEnemyScene.instantiate()
			enemy.spawner = self
			enemy.enemyData = spawnerData.enemyData
			enemy.homePoint = position
			enemy.patrolRange = enemyPatrolRange
			tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.
		if spawnerData.disabled or importantFight:
			spawnerData.disabled = false # re-enable if this is the second time it's loaded after causing an encounter
		if spawnerData.spawnedLastEncounter:
			spawnerData.spawnedLastEncounter = false
			if not importantFight:
				spawnerData.disabled = true # disable if it caused the last encounter
	if storyRequirements != null and not storyRequirements.is_valid():
		spawnerData.disabled = true

func delete_enemy():
	if enemy != null:
		enemy.queue_free()
	enemy = null
	spawnerData.enemyData = null

func save_file() -> String:
	return enemiesDir
