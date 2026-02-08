extends Node

const MOVES_PATH = 'res://gamedata/moves/'
var resultStrings: Array[String] = []

func _ready() -> void:
	execute_for_all_moves(test_move_has_anim)
	print('-------------------')
	execute_for_all_moves(test_rune_move_has_rune_anims)
	print('-------------------')
	execute_for_all_moves(test_move_has_surge_changes)
	get_tree().quit()

func test_move_has_anim(move: Move) -> void:
	if move.moveAnimation == null:
		resultStrings.append('Move ' + move.moveName + ' missing animation data!')

func test_rune_move_has_rune_anims(move: Move) -> void:
	if move.chargeEffect.rune != null:
		if move.chargeEffect.rune.runeSpriteAnim == null:
			resultStrings.append('Move ' + move.moveName + ' missing charge rune animation data!')
		if len(move.chargeEffect.rune.triggerAnims) == 0:
			resultStrings.append('Move ' + move.moveName + ' missing charge rune trigger animation(s)!')
	if move.surgeEffect.rune != null:
		if move.surgeEffect.rune.runeSpriteAnim == null:
			resultStrings.append('Move ' + move.moveName + ' missing surge rune animation data!')
		if len(move.surgeEffect.rune.triggerAnims) == 0:
			resultStrings.append('Move ' + move.moveName + ' missing surge rune trigger animation(s)!')

func test_move_has_surge_changes(move: Move) -> void:
	if move.surgeEffect.surgeChanges == null:
		resultStrings.append('Move ' + move.moveName + ' missing surge changes!')
	if move.surgeEffect.rune != null:
		if move.surgeEffect.rune.surgeChanges == null:
			resultStrings.append('Move ' + move.moveName + ' missing Rune surge changes!')

func execute_for_all_moves(callable: Callable) -> void:
	resultStrings = []
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(MOVES_PATH)
	for dir: String in moveDirs:
		var move: Move = load(MOVES_PATH + dir + '/' + dir + '.tres') as Move
		if move != null:
			callable.call(move)
	for strng: String in resultStrings:
		print(strng)
