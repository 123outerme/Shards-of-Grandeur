extends Node

const TEST_DIR: String = 'res://test/'

@onready var label: RichTextLabel = get_node('RichTextLabel')
@onready var closeButton: Button = get_node('CloseButton')

func _ready():
	create_reports()
	#print_report()
	for i: int in range(2, 101):
		print('XP to reach lv ', i, ': ', Stats.get_required_exp(i))

func create_reports():
	closeButton.disabled = true
	var reports: Dictionary = {}
	# add reports one at a time so we can catch and debug errors on a single report easier
	reports['combatants/movepool_report.csv'] = create_report_for_all_combatants_series(
		['Movepool Size', 'Highest Move Lv', 'Highest Lv Move', 'Element Weaknesses', 'Element Resistances', 'Status Resistances', 'Status Immunities'],
		[csv_combatant_movepool_size, csv_combatant_highest_move_lv, csv_combatant_highest_lv_move, csv_combatant_element_weaknesses, csv_combatant_element_resistances, csv_combatant_status_resistances, csv_combatant_status_immunities]
	)
	reports['moves/move_report.csv'] = create_report_for_all_moves_series(
		['Power', 'Orbs', 'Role', 'Dmg Category', 'Element', 'Self Stat Changes', 'Target Stat Changes', 'Status Effect', 'Status Potency', 'Status Chance', 'Status Turns', 'Rune', 'Keywords', 'Level'],
		[csv_move_power, csv_move_orbs, csv_move_role, csv_move_dmg_category, csv_move_element, csv_move_self_stat_changes, csv_move_target_stat_changes, csv_move_status, csv_move_status_potency, csv_move_status_chance, csv_move_status_turns, csv_move_rune, csv_move_keywords, csv_move_level]
	)
	reports['items/equipment_report.csv'] = create_report_for_all_equipment_series(
		['Stat Changes', 'Timing', 'Bonus Orbs', 'Cost'],
		[csv_equipment_stat_boosts, csv_equipment_timing, csv_equipment_orbs, csv_item_cost]
	)
	reports['items/item_report.csv'] = create_report_for_all_items_series(
		['Cost', 'Max Count'],
		[csv_item_cost, csv_item_max_count]
	)
	reports['combatants/reward_report.csv'] = create_report_for_all_combatants_series(
		['Avg Reward Exp', 'Avg Reward Gold'],
		[csv_combatant_avg_reward_xp, csv_combatant_avg_reward_gold]
	)
	
	reports['combatants/levels.csv'] = create_report_for_all_combatants_lvs(100)
	
	reports['combatants/stat_growths.csv'] = create_report_for_all_combatants_stat_growth()
	
	reports['moves/owners_report.csv'] = create_move_owners_report()
	
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		DirAccess.make_dir_recursive_absolute(TEST_DIR)
		
	if not FileAccess.file_exists(TEST_DIR + '.gdignore'):
		var gdIgnoreFile = FileAccess.open(TEST_DIR + '.gdignore', FileAccess.WRITE)
		gdIgnoreFile.close()
	
	for filename: String in reports.keys():
		var subdirs: PackedStringArray = filename.split('/')
		subdirs.remove_at(len(subdirs) - 1) # remove the filename
		var subdir: String = ''
		for subdirPiece in subdirs:
			subdir += subdirPiece + '/'
		#print(subdir)
		
		if not DirAccess.dir_exists_absolute(TEST_DIR + subdir):
			DirAccess.make_dir_recursive_absolute(TEST_DIR + subdir)
		
		var file = FileAccess.open(TEST_DIR + filename, FileAccess.WRITE)
		if file != null:
			file.store_string(reports[filename])
			if file.get_error() != OK:
				printerr('FileAccess error writing CSV content to file ', TEST_DIR + filename, ' (error ', file.get_error(), ')')
			file.close()
		else:
			if FileAccess.get_open_error() != OK:
				printerr('FileAccess error opening file ', TEST_DIR + filename, ' (error ', FileAccess.get_open_error(), ')')
	print('All CSV reports have been saved.')
	label.text = '[center]All CSV reports have been saved.[/center]'
	closeButton.disabled = false

func print_report():
	#for_all_combatants_series([print_combatant_weaknesses, print_combatant_status_resistances])
	#for_all_combatants_series([print_combatant_movepool_size, print_combatant_highest_lv_move])
	#print('\n---\n')
	#for_all_moves(print_move_element)
	#for_all_moves_series([print_move_effects_overview, print_move_role])
	pass

# CSV combatant queries
func create_report_for_all_combatants_series(columns: Array[String], queries: Array[Callable]) -> String:
	if len(columns) != len(queries):
		printerr('Combatants CSV report error: mismatched column and query lengths')
		return ''
	
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	var reportContents: String = 'Name,'
	for column in columns:
		reportContents += column + ','
	reportContents += '\n'
	
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			reportContents += combatant.save_name() + ','
			for query in queries:
				var val: String = query.call(combatant)
				reportContents += val + ','
			reportContents += '\n'
			var prevEvolution: Evolution = null
			if combatant.evolutions != null:
				for evolution: Evolution in combatant.evolutions.evolutionList:
					combatant.stats.equippedWeapon = evolution.requiredWeapon
					combatant.stats.equippedArmor = evolution.requiredArmor
					combatant.switch_evolution(evolution, prevEvolution)
					reportContents += evolution.evolutionSaveName + ' (evo ' + combatant.save_name() + '),'
					for query in queries:
						var val: String = query.call(combatant)
						reportContents += val + ','
					reportContents += '\n'
					prevEvolution = evolution
	return reportContents

func csv_combatant_movepool_size(combatant: Combatant) -> String:
	return String.num(len(combatant.stats.movepool.pool))

func csv_combatant_highest_lv_move(combatant: Combatant) -> String:
	var highestLvMove: Move = null
	for move: Move in combatant.stats.movepool.pool:
		if highestLvMove == null or highestLvMove.requiredLv < move.requiredLv:
			highestLvMove = move
	if highestLvMove != null:
		return highestLvMove.moveName
	else:
		return ''

func csv_combatant_highest_move_lv(combatant: Combatant) -> String:
	var highestLvMove: Move = null
	for move: Move in combatant.stats.movepool.pool:
		if highestLvMove == null or highestLvMove.requiredLv < move.requiredLv:
			highestLvMove = move
	if highestLvMove != null:
		return String.num(highestLvMove.requiredLv)
	else:
		return ''

func csv_combatant_element_weaknesses(combatant: Combatant) -> String:
	var weaknesses: String = ''
	var moveEffectiveness: MoveEffectiveness = combatant.get_move_effectiveness()
	for elementIdx in range(len(moveEffectiveness.elementWeaknesses)):
		var element: Move.Element = moveEffectiveness.elementWeaknesses[elementIdx]
		weaknesses += Move.element_to_string(element)
		if elementIdx < len(moveEffectiveness.elementWeaknesses) - 1:
			weaknesses += ' | '
	return weaknesses

func csv_combatant_element_resistances(combatant: Combatant) -> String:
	var resistances: String = ''
	var moveEffectiveness: MoveEffectiveness = combatant.get_move_effectiveness()
	for elementIdx in range(len(moveEffectiveness.elementResistances)):
		var element: Move.Element = moveEffectiveness.elementResistances[elementIdx]
		resistances += Move.element_to_string(element)
		if elementIdx < len(moveEffectiveness.elementResistances) - 1:
			resistances += ' | '
	return resistances

func csv_combatant_status_resistances(combatant: Combatant) -> String:
	var resistances: String = ''
	var moveEffectiveness: MoveEffectiveness = combatant.get_move_effectiveness()
	for statusIdx in range(len(moveEffectiveness.statusResistances)):
		var status: StatusEffect.Type = moveEffectiveness.statusResistances[statusIdx]
		resistances += StatusEffect.status_type_to_string(status)
		if statusIdx < len(moveEffectiveness.statusResistances) - 1:
			resistances += ' | '
	return resistances

func csv_combatant_status_immunities(combatant: Combatant) -> String:
	var immunities: String = ''
	var moveEffectiveness: MoveEffectiveness = combatant.get_move_effectiveness()
	for statusIdx in range(len(moveEffectiveness.statusImmunities)):
		var status: StatusEffect.Type = moveEffectiveness.statusImmunities[statusIdx]
		immunities += StatusEffect.status_type_to_string(status)
		if statusIdx < len(moveEffectiveness.statusImmunities) - 1:
			immunities += ' | '
	return immunities

func csv_combatant_avg_reward_xp(combatant: Combatant) -> String:
	var sum: float = 0
	var count: int = 0
	if combatant.dropTable != null:
		for reward: WeightedReward in combatant.dropTable.weightedRewards:
			sum += reward.reward.experience
			count += 1
	return String.num(sum / count)

func csv_combatant_avg_reward_gold(combatant: Combatant) -> String:
	var sum: float = 0
	var count: int = 0
	if combatant.dropTable != null:
		for reward: WeightedReward in combatant.dropTable.weightedRewards:
			sum += reward.reward.gold
			count += 1
	return String.num(sum / count)

# special CSV query for report
func create_move_owners_report() -> String:
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	var combatantMovepools: Dictionary[String, MovePool] = {}
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			combatantMovepools[combatant.disp_name()] = combatant.stats.movepool
			if combatant.evolutions:
				for evolution: Evolution in combatant.evolutions.evolutionList:
					combatantMovepools[evolution.stats.displayName + ' (evo ' + combatant.disp_name() + ')'] = evolution.stats.movepool
	
	var moves: Array[Move] = []
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			moves.append(move)
	
	var reportContents: String = 'Move'
	for combatantName: String in combatantMovepools.keys():
		reportContents += ',' + combatantName
	
	reportContents += '\n'
	for move: Move in moves:
		reportContents += move.moveName + ','
		for movepool: MovePool in combatantMovepools.values():
			if move in movepool.pool:
				reportContents += 'X'
			reportContents += ','
		reportContents += '\n'
	
	return reportContents

# special CSV query for reporting (one random instance of a) combatant's stats at all levels
func create_report_for_all_combatants_lvs(maxLv: int = 100) -> String:
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	var reportContents: String = 'Stats for All Combatants For Levels 1 - ' + String.num(maxLv) + '\n\n'
	
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			reportContents += combatant.save_name() + '\n'
			reportContents += csv_combatant_all_lvs_report_helper(combatant, maxLv) + '\n'
			if combatant.evolutions != null:
				var prevEvolution: Evolution = null
				for evolution: Evolution in combatant.evolutions.evolutionList:
					combatant = Combatant.load_combatant_resource(dir)
					combatant.stats.equippedWeapon = evolution.requiredWeapon
					combatant.stats.equippedArmor = evolution.requiredArmor
					combatant.switch_evolution(evolution, prevEvolution)
					reportContents += evolution.evolutionSaveName + ' (evo ' + combatant.save_name() + ')\n'
					reportContents += csv_combatant_all_lvs_report_helper(combatant, maxLv) + '\n'
					prevEvolution = evolution
	return reportContents

func csv_combatant_all_lvs_report_helper(combatant: Combatant, maxLv: int = 100) -> String:
	var reportContents: String = 'Level,Max HP,Phys Attack,Magic Attack,Affinity,Resistance,Speed\n'
	for lv: int in range(1, maxLv + 1):
		combatant.level_up_nonplayer(lv)
		reportContents += String.num(lv) + ',' + String.num(combatant.stats.maxHp) + ','
		reportContents += String.num(combatant.stats.physAttack) + ',' + String.num(combatant.stats.magicAttack) + ','
		reportContents += String.num(combatant.stats.affinity) + ',' + String.num(combatant.stats.resistance) + ','
		reportContents += String.num(combatant.stats.speed) + '\n'
	return reportContents

# special CSV query for reporting (one random instance of a) combatant's stats at all levels
func create_report_for_all_combatants_stat_growth() -> String:
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	var reportContents: String = 'Stat Growths for All Combatants\n\n'
	reportContents += 'Combatant,Initial Max HP,Max HP,Phys Attack,Magic Attack,Affinity,Resistance,Speed\n'
	
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			reportContents += combatant.save_name() + ','
			reportContents += csv_combatant_all_stat_growths_helper(combatant)
			if combatant.evolutions != null:
				var prevEvolution: Evolution = null
				for evolution: Evolution in combatant.evolutions.evolutionList:
					combatant = Combatant.load_combatant_resource(dir)
					combatant.stats.equippedWeapon = evolution.requiredWeapon
					combatant.stats.equippedArmor = evolution.requiredArmor
					combatant.switch_evolution(evolution, prevEvolution)
					reportContents += evolution.evolutionSaveName + ' (evo ' + combatant.save_name() + '),'
					reportContents += csv_combatant_all_stat_growths_helper(combatant)
					prevEvolution = evolution
	return reportContents

func csv_combatant_all_stat_growths_helper(combatant: Combatant) -> String:
	var reportContents: String = String.num(combatant.stats.statGrowth.initialMaxHp) + ',' + String.num(combatant.stats.statGrowth.hpGrowth) + ','
	reportContents += String.num(combatant.stats.statGrowth.physAtkGrowth) + ',' + String.num(combatant.stats.statGrowth.magicAtkGrowth) + ','
	reportContents += String.num(combatant.stats.statGrowth.affinityGrowth) + ',' + String.num(combatant.stats.statGrowth.resistanceGrowth) + ','
	reportContents += String.num(combatant.stats.statGrowth.speedGrowth) + '\n'
	return reportContents

# CSV move queries
func create_report_for_all_moves_series(columns: Array[String], queries: Array[Callable]) -> String:
	if len(columns) != len(queries):
		printerr('Moves CSV report error: mismatched column and query lengths')
		return ''
	
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	var reportContents: String = 'Name,Surge?,'
	for column in columns:
		reportContents += column + ','
	reportContents += '\n'
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			reportContents += move.moveName + ',Charge,'
			for query in queries:
				var val: String = query.call(move, false)
				reportContents += val + ','
			reportContents += '\n' + move.moveName + ',Surge,'
			for query in queries:
				var val: String = query.call(move, true)
				reportContents += val + ','
			reportContents += '\n'
	return reportContents

func csv_move_dmg_category(move: Move, _isSurge: bool) -> String:
	return Move.dmg_category_to_string(move.category)

func csv_move_element(move: Move, _isSurge: bool) -> String:
	return Move.element_to_string(move.element)

func csv_move_role(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	return MoveEffect.role_to_string(moveEffect.role)

func csv_move_level(move: Move, isSurge: bool) -> String:
	return String.num_int64(move.requiredLv)

func csv_move_keywords(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	return TextUtils.string_arr_to_string(moveEffect.keywords).replace(', ', ' | ')

func csv_move_power(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	return String.num(moveEffect.power)

func csv_move_orbs(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	return String.num(moveEffect.orbChange)

func csv_move_self_stat_changes(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	var statMultipliersText: Array[StatMultiplierText] = []
	if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
		statMultipliersText = moveEffect.selfStatChanges.get_multipliers_text()
	return StatMultiplierText.multiplier_text_list_to_string(statMultipliersText).replace(', ', ' | ')

func csv_move_target_stat_changes(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	var statMultipliersText: Array[StatMultiplierText] = []
	if moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes():
		statMultipliersText = moveEffect.targetStatChanges.get_multipliers_text()
	return StatMultiplierText.multiplier_text_list_to_string(statMultipliersText).replace(', ', ' | ')

func csv_move_status(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	if moveEffect.statusEffect != null:
		var statusDesc: String = moveEffect.statusEffect.get_status_type_string()
		if moveEffect.statusEffect.overwritesOtherStatuses:
			statusDesc += ' | Replaces'
		if moveEffect.selfGetsStatus:
			statusDesc += ' (On Self)'
		return statusDesc
	else:
		return ''

func csv_move_status_potency(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	if moveEffect.statusEffect != null:
		return StatusEffect.potency_to_string(moveEffect.statusEffect.potency)
	else:
		return ''

func csv_move_status_chance(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	if moveEffect.statusChance > 0:
		return String.num(moveEffect.statusChance * 100) + '%'
	else:
		return ''

func csv_move_status_turns(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	if moveEffect.statusEffect != null:
		return String.num_int64(moveEffect.statusEffect.turnsLeft)
	else:
		return ''


func csv_move_rune(move: Move, isSurge: bool) -> String:
	var moveEffect: MoveEffect = move.surgeEffect if isSurge else move.chargeEffect
	if moveEffect.rune != null:
		return moveEffect.rune.get_long_rune_type()
	else:
		return ''

# CSV equipment queries
func create_report_for_all_equipment_series(columns: Array[String], queries: Array[Callable]) -> String:
	if len(columns) != len(queries):
		printerr('Equipment CSV report error: mismatched column and query lengths')
		return ''
	
	var armorPath: String = 'res://gamedata/items/armor/'
	var weaponPath: String = 'res://gamedata/items/weapon/'
	var accessoryPath: String = 'res://gamedata/items/accessory/'
	var armors: PackedStringArray = DirAccess.get_files_at(armorPath)
	var weapons: PackedStringArray = DirAccess.get_files_at(weaponPath)
	var accessories: PackedStringArray = DirAccess.get_files_at(accessoryPath)
	
	var reportContents = 'Name,Type,'
	for column in columns:
		reportContents += column + ','
	reportContents += '\n'
	for armorFile: String in armors:
		var armor: Armor = load(armorPath + armorFile) as Armor
		if armor != null:
			reportContents += armor.itemName.replace(',', ' | ') + ',Armor,'
			for query in queries:
				var val: String = query.call(armor)
				reportContents += val + ','
			reportContents += '\n'
	for weaponFile: String in weapons:
		var weapon: Weapon = load(weaponPath + weaponFile) as Weapon
		if weapon != null:
			reportContents += weapon.itemName.replace(',', ' | ') + ',Weapon,'
			for query in queries:
				var val: String = query.call(weapon)
				reportContents += val + ','
			reportContents += '\n'
	for accessoryFile: String in accessories:
		var accessory: Accessory = load(accessoryPath + accessoryFile) as Accessory
		if accessory != null:
			reportContents += accessory.itemName.replace(',', ' | ') + ',Accessory,'
			for query in queries:
				var val: String = query.call(accessory)
				reportContents += val + ','
			reportContents += '\n'
	
	return reportContents

func csv_equipment_stat_boosts(equipment: Item) -> String:
	var multipliersText: Array[StatMultiplierText] = []
	if equipment.itemType == Item.Type.ARMOR:
		var armor: Armor = equipment as Armor
		if armor != null and armor.statChanges != null and armor.statChanges.has_stat_changes():
			multipliersText = armor.statChanges.get_multipliers_text()
	elif equipment.itemType == Item.Type.WEAPON:
		var weapon: Weapon = equipment as Weapon
		if weapon != null and weapon.statChanges != null and weapon.statChanges.has_stat_changes():
			multipliersText = weapon.statChanges.get_multipliers_text()
	return StatMultiplierText.multiplier_text_list_to_string(multipliersText).replace(',', ' | ')

func csv_equipment_timing(equipment: Item) -> String:
	var text: String = ''
	if equipment.itemType == Item.Type.ARMOR:
		var armor: Armor = equipment as Armor
		if armor != null:
			text = BattleCommand.apply_timing_to_string(armor.timing)
	elif equipment.itemType == Item.Type.WEAPON:
		var weapon: Weapon = equipment as Weapon
		if weapon != null:
			text = BattleCommand.apply_timing_to_string(weapon.timing)
	return text

func csv_equipment_orbs(equipment: Item) -> String:
	var text: String = ''
	if equipment.itemType == Item.Type.ARMOR:
		var armor: Armor = equipment as Armor
		if armor != null:
			text = String.num_int64(armor.bonusOrbs)
	elif equipment.itemType == Item.Type.WEAPON:
		var weapon: Weapon = equipment as Weapon
		if weapon != null:
			text = String.num_int64(weapon.bonusOrbs)
	elif equipment.itemType == Item.Type.ACCESSORY:
		var accessory: Accessory = equipment as Accessory
		if accessory != null:
			text = String.num_int64(accessory.bonusOrbs)
	return text

# CSV item queries
func create_report_for_all_items_series(columns: Array[String], queries: Array[Callable]) -> String:
	if len(columns) != len(queries):
		printerr('Items CSV report error: mismatched column and query lengths')
		return ''
	
	var itemsDir: String = 'res://gamedata/items/'
	var itemTypeDirs: PackedStringArray = DirAccess.get_directories_at(itemsDir)
	
	var reportContents = 'Name,Type,'
	for column in columns:
		reportContents += column + ','
	reportContents += '\n'
	
	for itemTypeDir: String in itemTypeDirs:
		var items: PackedStringArray = DirAccess.get_files_at(itemsDir + itemTypeDir)
		for itemFile: String in items:
			var item: Item = load(itemsDir + itemTypeDir + '/' + itemFile) as Item
			if item != null:
				reportContents += item.itemName.replace(',', ' | ') + ',' + Item.type_to_string(item.itemType) + ','
				for query in queries:
					var val: String = query.call(item)
					reportContents += val + ','
				reportContents += '\n'
			
	return reportContents

func csv_item_cost(item: Item) -> String:
	if item.cost < 0:
		return 'N/A'
	return String.num(item.cost)

func csv_item_max_count(item: Item) -> String:
	return String.num(item.maxCount)

# Print combatant queries
func for_all_combatants(query: Callable):
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			query.call(combatant)

func for_all_combatants_series(queries: Array[Callable]):
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			for query in queries:
				query.call(combatant)

func print_combatant_weaknesses(combatant: Combatant):
	if combatant.moveEffectiveness == null:
		print(combatant.save_name(), ' has no effectiveness data')
		return
	
	if len(combatant.moveEffectiveness.elementWeaknesses) == 0 and len(combatant.moveEffectiveness.elementResistances) == 0:
		print(combatant.save_name(), ' has no element weaknesses/resistances')
	else:
		if len(combatant.moveEffectiveness.elementWeaknesses) > 0:
			var printStr: String = combatant.save_name() + ' is weak to '
			for weakness: Move.Element in combatant.moveEffectiveness.elementWeaknesses:
				printStr += Move.element_to_string(weakness) + ' '
			print(printStr)
		else:
			print(combatant.save_name(), ' has no element weaknesses')
		if len(combatant.moveEffectiveness.elementResistances) > 0:
			var printStr: String = combatant.save_name() + ' element resists '
			for resistance: Move.Element in combatant.moveEffectiveness.elementResistances:
				printStr += Move.element_to_string(resistance) + ' '
			print(printStr)
		else:
			print(combatant.save_name(), ' has no element resistances')
	if combatant.evolutions != null:
		for evolution: Evolution in combatant.evolutions.evolutionList:
			if evolution.moveEffectiveness == null:
				print(evolution.evolutionSaveName, ' has no effectiveness data')
				continue
			if len(evolution.moveEffectiveness.elementWeaknesses) == 0 and len(evolution.moveEffectiveness.elementResistances) == 0:
				print(evolution.evolutionSaveName, ' has no element weaknesses/resistances')
			else:
				if len(evolution.moveEffectiveness.elementWeaknesses) > 0:
					var printStr = evolution.evolutionSaveName + ' is weak to '
					for weakness: Move.Element in evolution.moveEffectiveness.elementWeaknesses:
						printStr += Move.element_to_string(weakness) + ' '
					print(printStr)
				else:
					print(evolution.evolutionSaveName, ' has no element weaknesses')
				if len(evolution.moveEffectiveness.elementResistances) > 0:
					var printStr = evolution.evolutionSaveName + ' element resists '
					for resistance: Move.Element in evolution.moveEffectiveness.elementResistances:
						printStr += Move.element_to_string(resistance) + ' '
					print(printStr)
				else:
					print(evolution.evolutionSaveName, ' has no element resistances')

func print_combatant_status_resistances(combatant: Combatant):
	if combatant.moveEffectiveness == null:
		print(combatant.save_name(), ' has no effectiveness data')
		return
	
	if len(combatant.moveEffectiveness.statusResistances) == 0 and len(combatant.moveEffectiveness.statusImmunities) == 0:
		print(combatant.save_name(), ' has no status resistances/immunities')
	else:
		if len(combatant.moveEffectiveness.statusResistances) > 0:
			var printStr: String = combatant.save_name() + ' resists '
			for statusType: StatusEffect.Type in combatant.moveEffectiveness.statusResistances:
				printStr += StatusEffect.status_type_to_string(statusType) + ' '
			print(printStr)
		else:
			print(combatant.save_name(), ' has no status resistances')
		if len(combatant.moveEffectiveness.statusImmunities) > 0:
			var printStr: String = combatant.save_name() + ' is immune to '
			for statusType: StatusEffect.Type in combatant.moveEffectiveness.statusImmunities:
				printStr += StatusEffect.status_type_to_string(statusType) + ' '
			print(printStr)
		else:
			print(combatant.save_name(), ' has no status immunities')
	if combatant.evolutions != null:
		for evolution: Evolution in combatant.evolutions.evolutionList:
			if len(evolution.moveEffectiveness.statusResistances) == 0 and len(evolution.moveEffectiveness.statusImmunities) == 0:
				print(evolution.evolutionSaveName, ' has no status resistances/immunities')
			else:
				if len(evolution.moveEffectiveness.statusResistances) > 0:
					var printStr: String = evolution.evolutionSaveName + ' resists '
					for statusType: StatusEffect.Type in evolution.moveEffectiveness.statusResistances:
						printStr += StatusEffect.status_type_to_string(statusType) + ' '
					print(printStr)
				else:
					print(evolution.evolutionSaveName, ' has no status resistances')
				if len(evolution.moveEffectiveness.statusImmunities) > 0:
					var printStr: String = evolution.evolutionSaveName + ' is immune to '
					for statusType: StatusEffect.Type in evolution.moveEffectiveness.statusImmunities:
						printStr += StatusEffect.status_type_to_string(statusType) + ' '
					print(printStr)
				else:
					print(evolution.evolutionSaveName, ' has no status immunities')

func print_combatant_movepool_size(combatant: Combatant):
	print(combatant.save_name(), ' has ', len(combatant.stats.movepool.pool), ' moves')
	if combatant.evolutions != null:
			for evolution: Evolution in combatant.evolutions.evolutionList:
				print(evolution.evolutionSaveName, ' has ', len(evolution.stats.movepool.pool), ' moves')

func print_combatant_highest_lv_move(combatant: Combatant):
	var highestLvMove: Move = null
	for move: Move in combatant.stats.movepool.pool:
		if highestLvMove == null or move.requiredLv > highestLvMove.requiredLv:
			highestLvMove = move
	print(combatant.save_name(), '\'s highest lv move is ', highestLvMove.moveName, ' @ lv ', highestLvMove.requiredLv)
	if combatant.evolutions != null:
			for evolution: Evolution in combatant.evolutions.evolutionList:
				highestLvMove = null
				for move: Move in evolution.stats.movepool.pool:
					if highestLvMove == null or move.requiredLv > highestLvMove.requiredLv:
						highestLvMove = move
				print(evolution.evolutionSaveName, '\'s highest lv move is ', highestLvMove.moveName, ' @ lv ', highestLvMove.requiredLv)

# Print move queries
func for_all_moves(query: Callable):
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			query.call(move)

func for_all_moves_series(queries: Array[Callable]):
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			for query in queries:
				query.call(move)

func print_move_element(move: Move):
	print(move.moveName, ' element: ', Move.element_to_string(move.element))

func print_move_role(move: Move):
	print(move.moveName, ' Charge role: ', MoveEffect.role_to_string(move.chargeEffect.role))
	print(move.moveName, ' Surge role: ', MoveEffect.role_to_string(move.surgeEffect.role))

func print_move_effects_overview(move: Move):
	# charge effect
	var printStr: String = move.moveName + ' Charge: ' + String.num(move.chargeEffect.power) \
			+ ' ' + Move.element_to_string(move.element) + ' Power, +' \
			+ String.num(move.chargeEffect.orbChange) + ' Orbs, ' + BattleCommand.targets_to_string(move.chargeEffect.targets)
	
	if move.chargeEffect.selfStatChanges != null and move.chargeEffect.selfStatChanges.has_stat_changes():
		printStr += ', Self StatCh: '
		var statChangesText: Array[StatMultiplierText] = move.chargeEffect.selfStatChanges.get_multipliers_text()
		printStr += StatMultiplierText.multiplier_text_list_to_string(statChangesText)
	
	if move.chargeEffect.targetStatChanges != null and move.chargeEffect.targetStatChanges.has_stat_changes():
		printStr += ', Target StatCh: '
		var statChangesText: Array[StatMultiplierText] = move.chargeEffect.targetStatChanges.get_multipliers_text()
		printStr += StatMultiplierText.multiplier_text_list_to_string(statChangesText)
	
	if move.chargeEffect.statusEffect != null:
		printStr += ', ' + StatusEffect.potency_to_string(move.chargeEffect.statusEffect.potency) + ' ' \
				+ move.chargeEffect.statusEffect.get_status_type_string() + ' (' \
				+ String.num(move.chargeEffect.statusChance * 100) + '%)'
		if move.chargeEffect.selfGetsStatus:
			printStr += ' on self'

	print(printStr)
	
	# surge effect
	printStr = move.moveName + ' Surge: ' + String.num(move.surgeEffect.power) \
			+ ' ' + Move.element_to_string(move.element) + ' Power, ' \
			+ String.num(move.surgeEffect.orbChange) + ' Orbs, ' + BattleCommand.targets_to_string(move.surgeEffect.targets)
	
	if move.surgeEffect.selfStatChanges != null and move.surgeEffect.selfStatChanges.has_stat_changes():
		printStr += ', Self StatCh: '
		var statChangesText: Array[StatMultiplierText] = move.surgeEffect.selfStatChanges.get_multipliers_text()
		printStr += StatMultiplierText.multiplier_text_list_to_string(statChangesText)
	
	if move.surgeEffect.targetStatChanges != null and move.surgeEffect.targetStatChanges.has_stat_changes():
		printStr += ', Target StatCh: '
		var statChangesText: Array[StatMultiplierText] = move.surgeEffect.targetStatChanges.get_multipliers_text()
		printStr += StatMultiplierText.multiplier_text_list_to_string(statChangesText)
	
	if move.surgeEffect.statusEffect != null:
		printStr += ', ' + StatusEffect.potency_to_string(move.surgeEffect.statusEffect.potency) + ' ' \
				+ move.surgeEffect.statusEffect.get_status_type_string() + ' (' \
				+ String.num(move.surgeEffect.statusChance * 100) + '%)'
		if move.surgeEffect.selfGetsStatus:
			printStr += ' on self'

	print(printStr)

func _on_close_button_pressed() -> void:
	get_tree().quit()
