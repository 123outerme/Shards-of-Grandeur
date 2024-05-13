extends Node

func _ready():
	#for_all_combatants(print_combatant_weaknesses)
	for_all_combatants(print_combatant_movepool_size)
	#for_all_moves(print_move_element)

func for_all_combatants(query: Callable):
	var combatantsPath = 'res://gamedata/combatants/'
	var combatantDirs: PackedStringArray = DirAccess.get_directories_at(combatantsPath)
	for dir: String in combatantDirs:
		var combatant: Combatant = Combatant.load_combatant_resource(dir)
		if combatant != null:
			query.call(combatant)

func for_all_moves(query: Callable):
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			query.call(move)

func print_combatant_weaknesses(combatant: Combatant):
	if combatant.moveEffectiveness == null:
		print(combatant.save_name(), ' has no effectiveness data')
		return
	
	if len(combatant.moveEffectiveness.elementWeaknesses) == 0:
		print(combatant.save_name(), ' has no weaknesses')
	else:
		var printStr: String = combatant.save_name() + ' is weak to '
		for weakness: Move.Element in combatant.moveEffectiveness.elementWeaknesses:
			printStr += Move.element_to_string(weakness) + ' '
		print(printStr)
	if combatant.evolutions != null:
		for evolution: Evolution in combatant.evolutions.evolutionList:
			if evolution.moveEffectiveness == null:
				print(evolution.evolutionSaveName, ' has no effectiveness data')
				continue
			if len(evolution.moveEffectiveness.elementWeaknesses) == 0:
				print(evolution.evolutionSaveName, ' has no weaknesses')
			else:
				var printStr = evolution.evolutionSaveName + ' is weak to '
				for weakness: Move.Element in evolution.moveEffectiveness.elementWeaknesses:
					printStr += Move.element_to_string(weakness) + ' '
				print(printStr)

func print_combatant_movepool_size(combatant: Combatant):
	print(combatant.save_name(), ' has ', len(combatant.stats.movepool.pool), ' moves')
	if combatant.evolutions != null:
			for evolution: Evolution in combatant.evolutions.evolutionList:
				print(evolution.evolutionSaveName, ' has ', len(evolution.stats.movepool.pool), ' moves')

func print_move_element(move: Move):
	print(move.moveName, ' element: ', Move.element_to_string(move.element))
