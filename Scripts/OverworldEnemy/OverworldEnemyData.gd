extends Resource
class_name OverworldEnemyData

@export var combatant: Combatant = null
@export var position: Vector2 = Vector2()
@export var disableMovement: bool = false

# NOTE: for saving data, the complete filepath comes from the EnemySpawner itself to preserve spawner state
# so all that needs to be used for save/load functionality is the save_path coming through

func _init(
	i_combatant = null,
	i_pos = Vector2(),
	i_disableMove = false,
):
	combatant = i_combatant
	position = i_pos
	disableMovement = i_disableMove

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path):
		data = load(save_path)
		if data != null:
			return data.duplicate(true)
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path)
	if err != 0:
		printerr("OverworldEnemyData " + save_path + " ResourceSaver error: " + String.num(err))
