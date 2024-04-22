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
		level_up_minion(minion, PlayerResources.playerInfo.combatant.stats.level, true)
		minionsDict[saveName] = minion
		if not (minion.save_name() in minionList):
			minionList.append(minion.save_name())
	return minion

func get_minion_list() -> Array[Combatant]:
	var minions: Array[Combatant] = []
	for minion in minionList:
		minions.append(minionsDict[minion])
	return minions

func level_up_minion(minion: Combatant, newLevel: int, newMinion: bool = false):
	var levelDiff: int = newLevel - minion.stats.level
	if levelDiff > 0:
		minion.stats.level_up(levelDiff)
		minion.currentHp = minion.stats.maxHp
	
	if (levelDiff > 0 or newMinion) and len(minion.stats.moves) < 4:
		minion.assign_moves_nonplayer()

func level_up_minions(newLevel: int):
	for minion in get_minion_list():
		level_up_minion(minion, newLevel)
		
func add_friendship(minionName: String, wasDowned: bool):
	if has_minion(minionName):
		var minion = minionsDict[minionName] as Combatant
		var friendship: int = 1
		if not wasDowned:
			friendship = 2
		# cap friendship at maximum
		minion.friendship = min(minion.friendship + friendship, minion.maxFriendship)

func which_minion_equipped(item: Item) -> String:
	var saveName: String = ''
	for minion in get_minion_list():
		if (minion.stats.equippedWeapon != null and minion.stats.equippedWeapon.itemName == item.itemName) or (minion.stats.equippedArmor != null and minion.stats.equippedArmor.itemName == item.itemName):
			saveName = minion.save_name()
	return saveName

func reorder_minion(chosenMinion: Combatant, aboveMinion: Combatant) -> int:
	var idx = minionList.find(aboveMinion.save_name())
	if idx != -1:
		minionList.erase(chosenMinion.save_name())
		minionList.insert(idx, chosenMinion.save_name())
	else:
		printerr('Minion Reorder error: could not find target minion ' + aboveMinion.save_name())
	return idx

func fully_attune(saveName: String):
	var minion: Combatant = null
	if not has_minion(saveName): # if minion is not in minions, add it
		minion = init_minion(saveName)
	else:
		minion = get_minion(saveName)
	if minion != null: # set max friendship on minion
		minion.friendship = minion.maxFriendship
	else:
		printerr('Fully attune minion ', saveName, ' ERROR, null minion')

func validate_minion_moves(minion: Combatant):
	var invalidIdxs: Array[int] = []
	for idx in range(len(minion.stats.moves)):
		# if the move is not in the minion's movepool:
		if not (minion.stats.moves[idx] in minion.stats.movepool.pool):
			invalidIdxs.append(idx) # gather list of all invalid move indices
			
	for idx in invalidIdxs: # for each invalid move slot:
		for move: Move in minion.stats.movepool.pool: # for each move in the pool
			# if the minion can learn this move and has not already done so
			if move.requiredLv <= minion.stats.level and move not in minion.stats.moves:
				minion.stats.moves[idx] = move # set this move in the previously invalid move slot
				break

func validate_minion_stats(minion: Combatant):
	if not minion.stats.is_stat_total_valid():
		printerr('Minion ' + minion.disp_name() + ' had invalid stats! Resetting.')
		minion.stats.reset_stat_points()

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = ResourceLoader.load(save_path + save_file, '', ResourceLoader.CACHE_MODE_IGNORE) as PlayerMinions
		if data == null:
			return null
		data._load_data_each_minion(save_path)
	return data

func _load_data_each_minion(save_path):
	for minionName in minionList:
		var minion = null
		if ResourceLoader.exists(save_path + minions_dir + minionName + '.tres'):
			minion = load(save_path + minions_dir + minionName + '.tres') as Combatant
			validate_minion_moves(minion)
			validate_minion_stats(minion)
			set_minion(minion)
		if minion == null:
			init_minion(minionName)
	
func save_data(save_path, data) -> int:
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("PlayerMinions ResourceSaver error: ", err)
		return err
	for minion: Combatant in minionsDict.values():
		err = ResourceSaver.save(minion, save_path + minions_dir + minion.save_name() + '.tres')
		if err != 0:
			printerr("PlayerMinions save minion ", minion.save_name(), " ResourceSaver error: ", err)
			return err
	return 0
