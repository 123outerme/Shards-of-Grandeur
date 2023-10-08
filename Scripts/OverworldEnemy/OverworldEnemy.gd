extends CharacterBody2D
class_name OverworldEnemy

@export var combatant: Combatant
@export var combatantLevel: int = 1
@export var disableMovement: bool = false
@export var maxSpeed = 40
@export var patrolling: bool = false
@export var patrolWaitSecs: float = 1.0
@export var enemyData: OverworldEnemyData = OverworldEnemyData.new()

var homePoint: Vector2
var patrolRange: float
var saveFile: String
var encounteredPlayer: bool = false

@onready var enemySprite: Sprite2D = get_node("EnemySprite")
@onready var navAgent: NavigationAgent2D = get_node("NavAgent")

# NOTE: for saving data, the complete filepath comes from the EnemySpawner itself to preserve spawner state
# so all that needs to be used for save/load functionality is the save_path coming through

func _ready():
	enemySprite.texture = combatant.sprite

func _process(delta):
	if not disableMovement and SceneLoader.mapLoader != null:
		if not patrolling and SceneLoader.mapLoader.mapNavReady:
			navAgent.target_position = PlayerFinder.player.position
		var nextPos = navAgent.get_next_path_position()
		var vel = nextPos - position
		if vel.length() > maxSpeed * delta:
			vel = vel.normalized() * maxSpeed * delta
		position += vel

func get_next_patrol_target():
	if SceneLoader.mapLoader != null and not SceneLoader.mapLoader.mapNavReady:
		return
	var angleRadians = randf_range(0, 2 * PI)
	var radius: float = randf_range(0, patrolRange)
	var patrolPos: Vector2 = homePoint + Vector2(cos(angleRadians), sin(angleRadians)).normalized() * radius
	# generate random point on unit circle and ensure it's exactly on the circle, multiplied by a random radius
	# all for a random position inside a circle of size `patrolRange` centered around the home point
	navAgent.target_position = patrolPos

func pause_movement():
	disableMovement = true

func unpause_movement():
	disableMovement = false

func save_data(save_path):
	if not encounteredPlayer:
		enemyData.combatant = combatant
		enemyData.position = position
		enemyData.disableMovement = disableMovement
		enemyData.save_data(save_path, enemyData)
	else:
		delete_data(save_path)
	return
	
func load_data(save_path) -> bool:
	enemyData = OverworldEnemyData.new(combatant)
	var newData = enemyData.load_data(save_path)
	if newData != null:
		enemyData = newData # only load the new enemy data if it exists
		combatant = enemyData.combatant
		position = enemyData.position
		disableMovement = enemyData.disableMovement
		return true
	return false
	
func delete_data(save_path):
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		# SaveHandler.save_file_location is the same as save_path in the save/load functions
		if err != 0:
			printerr("OverworldEnemy DirAccess remove error: ", err)

func _on_chase_range_area_entered(area):
	if area.name == "PlayerEventCollider":
		patrolling = false
		
func _on_chase_range_area_exited(area):
	if area.name == "PlayerEventCollider":
		patrolling = true
		get_next_patrol_target()

func _on_nav_agent_navigation_finished():
	await get_tree().create_timer(patrolWaitSecs).timeout
	get_next_patrol_target()

func _on_nav_agent_target_reached():
	await get_tree().create_timer(patrolWaitSecs).timeout
	get_next_patrol_target()

func _on_encounter_collider_area_entered(area):
	if area.name == "PlayerEventCollider":
		PlayerResources.playerInfo.encounteredName = combatant.save_name()
		PlayerResources.playerInfo.encounteredLevel = combatantLevel
		encounteredPlayer = true
		SaveHandler.save_data()
		SceneLoader.load_battle()
