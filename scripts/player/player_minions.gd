extends Resource
class_name PlayerMinions

@export var minionList: Array[String] = []
var minionsDict: Dictionary = {}

var minions_dir = 'minions/'
var save_file = 'minions.tres'

func _init(i_minionList: Array[String] = []):
	minionList = i_minionList

func has_minion(saveName: String) -> bool:
	return minionList.has(saveName)

func set_minion(minion: Combatant):
	if minion == null:
		printerr('Err on set_minion: minion is null')
		return
	minionsDict[minion.save_name()] = minion
	if not (minion.save_name() in minionList):
		minionList.append(minion.save_name())

func get_minion(saveName: String) -> Combatant:
	var minion: Combatant = null
	if has_minion(saveName):
		minion = minionsDict[saveName] as Combatant
	else:
		minion = init_minion(saveName)
	return minion

func init_minion(saveName: String) -> Combatant:
	var minion = Combatant.load_combatant_resource(saveName)
	if minion != null:
		minion.assign_moves_nonplayer()
		minionsDict[saveName] = minion
		if not (minion.save_name() in minionList):
			minionList.append(minion.save_name())
	return minion

func get_minion_list() -> Array[Combatant]:
	var minions: Array[Combatant] = []
	minions.append_array(minionsDict.values())
	return minions

func level_up_minions(newLevel: int):
	for minion in get_minion_list():
		var levelDiff: int = newLevel - minion.stats.level
		if levelDiff > 0:
			minion.stats.level_up(levelDiff)
			minion.currentHp = minion.stats.maxHp
			for i in range(4): # fill in any empty move slots if possible
				if i >= len(minion.stats.moves) or minion.stats.moves[i] == null:
					for move in minion.stats.movepool.pool:
						if minion.stats.level >= move.requiredLv and not (move in minion.stats.moves):
							minion.stats.moves.insert(i, move)
							break

func add_friendship(minionName: String, wasDowned: bool):
	if has_minion(minionName):
		var minion = minionsDict[minionName] as Combatant
		minion.friendship += 1
		if not wasDowned:
			minion.friendship += 1

func which_minion_equipped(item: Item) -> String:
	var saveName: String = ''
	for minion in get_minion_list():
		if (minion.stats.equippedWeapon != null and minion.stats.equippedWeapon.itemName == item.itemName) or (minion.stats.equippedArmor != null and minion.stats.equippedArmor.itemName == item.itemName):
			saveName = minion.save_name()
	return saveName

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = load(save_path + save_file) as PlayerMinions
		if data == null:
			return null
		data._load_data_each_minion(save_path)
	return data

func _load_data_each_minion(save_path):
	for minionName in minionList:
		var minion = null
		if ResourceLoader.exists(save_path + minions_dir + minionName + '.tres'):
			minion = load(save_path + minions_dir + minionName + '.tres') as Combatant
			set_minion(minion)
		if minion == null:
			init_minion(minionName)
	
func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("PlayerMinions ResourceSaver error: ", err)
		return
	for minion: Combatant in minionsDict.values():
		err = ResourceSaver.save(minion, save_path + minions_dir + minion.save_name() + '.tres')
		if err != 0:
			printerr("PlayerMinions save minion ", minion.save_name(), " ResourceSaver error: ", err)
			return
