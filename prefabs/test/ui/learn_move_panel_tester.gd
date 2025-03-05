extends Node2D

@export var runTests: bool = true

@onready var itemUsePanel: ItemUsePanel = get_node('ItemUsePanel')
@onready var audioHandler: AudioHandler = get_node('AudioHandler')

var tooLongLearnTextMoves: Array[Move] = []

func _ready() -> void:
	SceneLoader.audioHandler = audioHandler
	if runTests:
		await run_tests()
		print('\nMoves with too long of learn text:')
		for move: Move in tooLongLearnTextMoves:
			print(move.moveName)
	else:
		itemUsePanel.load_item_use_panel()

func run_tests() -> void:
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			print('Testing ', move.moveName)
			itemUsePanel.learnedMove = move
			itemUsePanel.load_item_use_panel()
			await get_tree().process_frame
			test_use_item_learn_move_panel()
			itemUsePanel._on_ok_button_pressed()

func test_use_item_learn_move_panel() -> void:
	if itemUsePanel.itemUsedEffects.get_v_scroll_bar().visible:
		tooLongLearnTextMoves.append(itemUsePanel.learnedMove)
