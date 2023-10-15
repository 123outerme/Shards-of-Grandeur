extends Resource
class_name PlayerMinions

@export var minionList: Dictionary = {}

var save_file = 'minions.tres'

func _init(i_minionList: Dictionary = {}):
	minionList = i_minionList

func has_minion(saveName: String) -> bool:
	return minionList.has(saveName)

func set_minion(minion: Combatant):
	minionList[minion.save_name()] = minion

func get_minion(saveName: String) -> Combatant:
	var minion: Combatant = null
	if has_minion(saveName):
		minion = minionList[saveName] as Combatant
	else:
		minion = Combatant.load_combatant_resource(saveName)
		minionList[saveName] = minion
	return minion

func get_minion_list() -> Array[Combatant]:
	var minions: Array[Combatant] = []
	minions.append_array(minionList.values())
	return minions

func level_up_minions(newLevel: int):
	for minion in get_minion_list():
		var levelDiff: int = newLevel - minion.stats.level
		if levelDiff > 0:
			minion.stats.level_up(levelDiff)

func which_minion_equipped(item: Item) -> String:
	var dispName: String = ''
	for minion in get_minion_list():
		if (minion.stats.equippedWeapon != null and minion.stats.equippedWeapon.itemName == item.itemName) or (minion.stats.equippedArmor != null and minion.stats.equippedArmor.itemName == item.itemName):
			dispName = minion.disp_name()
	return dispName

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = load(save_path + save_file)
		if data != null:
			return data
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("PlayerMinions ResourceSaver error: ", err)
