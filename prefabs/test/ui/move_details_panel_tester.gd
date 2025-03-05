extends Node2D

@export var runTests: bool = true

@onready var moveDetailsPanel: MoveDetailsPanel = get_node('MoveDetailsPanel')

var tooLongDescriptionMoves: Array[Move] = []

func _ready() -> void:
	if runTests:
		await run_tests()
		print('\nMoves with too long a description:')
		for move: Move in tooLongDescriptionMoves:
			print(move.moveName)
	else:
		moveDetailsPanel.load_move_details_panel()

func run_tests() -> void:
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			print('Testing ', move.moveName)
			moveDetailsPanel.move = move
			moveDetailsPanel.load_move_details_panel()
			await get_tree().process_frame
			test_move_details_panel()

func test_move_details_panel() -> void:
	if moveDetailsPanel.moveDescription.get_v_scroll_bar().visible:
		tooLongDescriptionMoves.append(moveDetailsPanel.move)
