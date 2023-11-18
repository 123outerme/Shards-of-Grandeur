extends Node2D
class_name EnemySpawner

@export var spawnerData: SpawnerData = SpawnerData.new()
@export var combatant: Combatant
@export var setReward: Reward = null
@export var bossBattle: bool = false
@export var specialBattleId: String = ''
@export var storyRequirements: StoryRequirements = null
@export var combatantLevel: int = 1
@export var spawnRange: float = 48.0
@export var enemyPatrolRange: float = 32.0
@export var tilemap: TileMap
@export var enemy: OverworldEnemy = null


var overworldEnemyScene = preload("res://Prefabs/Entities/OverworldEnemy.tscn")
var enemiesDir: String = 'enemies/'

@onready var shape: CollisionShape2D = get_node("SpawnArea/SpawnShape")

func _ready():
	if storyRequirements != null and not storyRequirements.is_valid():
		spawnerData.disabled = true

func _on_area_2d_area_entered(area):
	if enemy == null and area.name == 'PlayerEventCollider' and not spawnerData.disabled:
		var angleRadians = randf_range(0, 2 * PI)
		var radius: float = randf_range(0, spawnRange / 2.0) # range in diameter, so half of that
		var enemyPos: Vector2 = position + (Vector2(cos(angleRadians), sin(angleRadians)).normalized() * radius)
		# generate random point on unit circle and ensure it's exactly on the circle, multiplied by a random radius
		# all for a random position inside a circle of size `spawnRange` centered around the spawner
		enemy = overworldEnemyScene.instantiate()
		enemy.spawner = self
		enemy.enemyData = OverworldEnemyData.new(combatant, setReward, enemyPos, false, combatantLevel, bossBattle, specialBattleId)
		enemy.homePoint = position
		enemy.patrolRange = enemyPatrolRange
		tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.
		#print('spawned new enemy')

func save_data(save_path):
	if spawnerData != null:
		if enemy != null:
			if enemy.encounteredPlayer:
				delete_enemy()
			else:
				spawnerData.enemyData = OverworldEnemyData.new(combatant, setReward, enemy.position, enemy.disableMovement, enemy.enemyData.combatantLevel, bossBattle, specialBattleId)
		else:
			spawnerData.enemyData = null
		spawnerData.save_data(save_path + enemiesDir, spawnerData)

func load_data(save_path):
	var newData = spawnerData.load_data(save_path + enemiesDir)
	if newData != null:
		spawnerData = newData
		if spawnerData.enemyData != null:
			enemy = overworldEnemyScene.instantiate()
			enemy.spawner = self
			enemy.enemyData = spawnerData.enemyData
			enemy.homePoint = position
			enemy.patrolRange = enemyPatrolRange
			tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.
		if spawnerData.disabled:
			spawnerData.disabled = false # re-enable if this is the second time it's loaded after causing an encounter
		if spawnerData.spawnedLastEncounter:
			spawnerData.spawnedLastEncounter = false
			spawnerData.disabled = true # disable if it caused the last encounter

func delete_enemy():
	enemy.queue_free()
	enemy = null
	spawnerData.enemyData = null

func save_file() -> String:
	return enemiesDir
