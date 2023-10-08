extends Node2D
class_name EnemySpawner

@export var spawnerId: String
@export var combatant: Combatant
@export var combatantLevel: int = 1
@export var enemy: OverworldEnemy = null
@export var spawnRange: float = 48.0
@export var enemyPatrolRange: float = 32.0
@export var tilemap: TileMap

var overworldEnemyScene = preload("res://Prefabs/Entities/OverworldEnemy.tscn")
var enemiesDir: String = 'enemies/'

@onready var shape: CollisionShape2D = get_node("SpawnArea/SpawnShape")

func _on_area_2d_area_entered(area):
	if enemy == null and area.name == 'PlayerEventCollider':
		var angleRadians = randf_range(0, 2 * PI)
		var radius: float = randf_range(0, spawnRange)
		var enemyPos: Vector2 = position + (Vector2(cos(angleRadians), sin(angleRadians)).normalized() * radius)
		# generate random point on unit circle and ensure it's exactly on the circle, multiplied by a random radius
		# all for a random position inside a circle of size `spawnRange` centered around the spawner
		enemy = overworldEnemyScene.instantiate()
		enemy.position = enemyPos
		enemy.combatant = combatant
		enemy.combatantLevel = combatantLevel
		enemy.homePoint = position
		enemy.patrolRange = enemyPatrolRange
		enemy.saveFile = save_file()
		tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.
		print('spawned new enemy')

func save_data(save_path):
	if enemy != null:
		enemy.save_data(save_path + save_file())

func load_data(save_path):
	enemy = overworldEnemyScene.instantiate()
	if not enemy.load_data(save_path + save_file()):
		enemy.free() # free enemy immediately; it isn't a saved enemy
		enemy = null
	else:
		enemy.saveFile = save_file()
		enemy.homePoint = position
		enemy.patrolRange = enemyPatrolRange
		# enemy.restore_from_load()
		tilemap.call_deferred('add_child', enemy) # add enemy to tilemap so it can be y-sorted, etc.

func delete_enemy():
	if enemy != null:
		enemy.delete_data(SaveHandler.save_file_location + save_file())

func save_file() -> String:
	return enemiesDir + spawnerId + '_enemy.tres'
