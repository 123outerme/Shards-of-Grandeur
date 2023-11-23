extends Resource
class_name SpawnerData

@export var spawnerId: String = ''
@export var disabled: bool = false
@export var enemyData: OverworldEnemyData = null
@export var spawnedLastEncounter: bool = false

func _init(
	i_id = '',
	i_disabled = false,
	i_enemyData = null,
	i_lastEncounter = false,
):
	spawnerId = i_id
	disabled = i_disabled
	enemyData = i_enemyData
	spawnedLastEncounter = i_lastEncounter

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file()):
		data = load(save_path + save_file())
		if data != null:
			return data #.duplicate(true)
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file())
	if err != 0:
		printerr("SpawnerData " + save_path + save_file() + " ResourceSaver error: " + String.num(err))

# not sure if I still need the below
'''
func delete_data(save_path):
	if FileAccess.file_exists(save_path + save_file()):
		var err = DirAccess.remove_absolute(save_path + save_file())
		if err != 0:
			printerr("SpawnerData DirAccess remove error: ", err)
'''

func save_file() -> String:
	return spawnerId + '_enemy.tres'
