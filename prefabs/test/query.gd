extends Node

func _ready():
	for_all_combatants_series([print_combatant_weaknesses, print_combatant_status_resistances])
	#for_all_combatants(print_combatant_movepool_size)
	#for_all_combatants(print_combatant_highest_lv_move)
	print('\n---\n')
	for_all_moves(print_move_element)

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

func print_move_element(move: Move):
	print(move.moveName, ' element: ', Move.element_to_string(move.element))
