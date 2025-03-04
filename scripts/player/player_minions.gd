extends Resource
class_name PlayerMinions

var minion_reqs: Dictionary[String, StoryRequirements] = {
	'king_rat': load('res://gamedata/story_requirements/minions/king_rat_reqs.tres') as StoryRequirements
}

@export var minionList: Array[String] = []
@export var changedMinions: Array[String] = []
var minionsDict: Dictionary[String, Combatant] = {}

var minions_dir = 'minions/'
var save_file = 'minions.tres'

func _init(i_minionList: Array[String] = [], i_changedMinions: Array[String] = []):
	minionList = i_minionList
	changedMinions = i_changedMinions

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
		# remove the drop table because it's unneeded now
		minion.dropTable = null
		minionsDict[saveName] = minion
		if not (minion.save_name() in minionList):
			mark_minion_as_changed(minion.save_name())
			minionList.append(minion.save_name())
	return minion

func get_minion_list() -> Array[Combatant]:
	var minions: Array[Combatant] = []
	for minion: String in minionList:
		if minionsDict.has(minion):
			minions.append(minionsDict[minion])
		else:
			minions.append(init_minion(minion))
	return minions

func is_minion_marked_changed(minionSaveName: String) -> bool:
	return minionSaveName in changedMinions

func mark_minion_as_changed(minionSaveName: String) -> void:
	if not is_minion_marked_changed(minionSaveName):
		changedMinions.append(minionSaveName)

func clear_minion_changed(minionSaveName: String) -> void:
	changedMinions.erase(minionSaveName)

func level_up_minion(minion: Combatant, newLevel: int, newMinion: bool = false):
	var levelDiff: int = newLevel - minion.stats.level
	if levelDiff > 0:
		minion.stats.level_up(levelDiff)
		minion.currentHp = minion.stats.maxHp
		if minion.should_auto_alloc_stat_pts():
			if minion.get_stat_allocation_strategy() == null:
				printerr('Minion ', minion.save_name(), ' has no stat allocation strategy and is levelling up with automatic stat allocation!')
			else:
				minion.get_stat_allocation_strategy().allocate_stats(minion.stats)
	
	if (levelDiff > 0 or newMinion) and len(minion.stats.moves) < Stats.MAX_MOVES:
		minion.assign_moves_nonplayer()

func level_up_minions(newLevel: int):
	for minion in get_minion_list():
		level_up_minion(minion, newLevel)
		
func add_friendship(minionName: String, wasDowned: bool = true, friendshipMultiplier: float = 1.0):
	if has_minion(minionName):
		var minion = minionsDict[minionName] as Combatant
		var friendship: int = 1
		if not wasDowned:
			friendship = 2
		# cap friendship at maximum
		minion.friendship = min(minion.friendship + friendship * friendshipMultiplier, minion.maxFriendship)

func which_minion_equipped(item: Item) -> String:
	var saveName: String = ''
	for minion: Combatant in get_minion_list():
		if (minion.stats.equippedWeapon != null and minion.stats.equippedWeapon.itemName == item.itemName) or (minion.stats.equippedArmor != null and minion.stats.equippedArmor.itemName == item.itemName):
			saveName = minion.save_name()
	return saveName

func has_fully_attuned_minion() -> bool:
	for minion: Combatant in get_minion_list():
		if minion.friendship >= minion.maxFriendship:
			return true
	return false

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

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = ResourceLoader.load(save_path + save_file, '', ResourceLoader.CACHE_MODE_IGNORE) as PlayerMinions
		if data == null:
			return null
		data._load_data_each_minion(save_path)
	return data

func _load_data_each_minion(save_path):
	var removeMinionNames: Array[String] = []
	for minionName in minionList:
		var minion = null
		var passesReqs: bool = true
		if minion_reqs.has(minionName):
			var reqs: StoryRequirements = minion_reqs.get(minionName) as StoryRequirements
			if reqs != null:
				passesReqs = reqs.is_valid()
			else:
				printerr('Minion load WARNING: story requirements for ', minionName, ' were null')
		
		if passesReqs and ResourceLoader.exists(save_path + minions_dir + minionName + '.tres'):
			minion = ResourceLoader.load(save_path + minions_dir + minionName + '.tres', '', ResourceLoader.CACHE_MODE_IGNORE) as Combatant
			if minion == null: # or GameSettings.get_version_differences(minion.version) >= GameSettings.VersionDiffs.MINOR
				print('minion ', minionName, ' failed load validation')
				var savedFriendship: int = 0
				var savedMaxFriendship: int = 0
				var savedNickname: String = ''
				# currently unused because the only way to get here is if the minions doesn't load
				# in the future, some additional test may be added that fails validation and requires the whole minion to be rebuilt
				if minion != null:
					savedFriendship = minion.friendship
					savedMaxFriendship = minion.maxFriendship
					savedNickname = minion.nickname
				minion = init_minion(minionName)
				if savedMaxFriendship != 0:
					# if we saved the friendship of the minion:
					if savedMaxFriendship != minion.maxFriendship:
						# if the minion's max friendship was saved: keep the friendship ratio
						minion.friendship = roundi((savedFriendship / (savedMaxFriendship as float)) * minion.maxFriendship)
					else:
						# if the max friendship didn't change, no need to recalculate with the friendship ratio
						minion.friendship = savedFriendship
				minion.nickname = savedNickname
			validate_minion_moves(minion)
			# validate evolution stats data structure, and validate all stat totals (resetting if invalid)
			minion.validate_all_evolutions_stat_totals()
			# validate that the base minion object has an allocation strategy, and if not, give it the base one from its combatant "blueprint"
			minion.validate_allocation_strategy_non_null()
			# now, the minion is valid and can be added to the list
			set_minion(minion)
		elif not passesReqs:
			removeMinionNames.append(minionName)
	
	for name: String in removeMinionNames:
		minionList.erase(name)
		print('WARNING: Minion ', name, ' no longer passes story requirements. Removing.')

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
