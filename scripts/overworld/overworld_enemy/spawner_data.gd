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
	if ResourceLoader.exists(save_path + get_save_filename()):
		data = ResourceLoader.load(save_path + get_save_filename(), '', ResourceLoader.CACHE_MODE_IGNORE)
		if data != null:
			return data #.duplicate(true)
	return data

func save_data(save_path, data) -> int:
	var err = ResourceSaver.save(data, save_path + get_save_filename())
	if err != 0:
		printerr("SpawnerData " + save_path + get_save_filename() + " ResourceSaver error: " + String.num_int64(err))
	return err

# not sure if I still need the below
func delete_data(save_path) -> int:
	if FileAccess.file_exists(save_path + get_save_filename()):
		var err = DirAccess.remove_absolute(save_path + get_save_filename())
		if err != 0:
			printerr("SpawnerData DirAccess remove error: ", err)
			return err
	return 0

func get_save_filename() -> String:
	return spawnerId + '_enemy.tres'
