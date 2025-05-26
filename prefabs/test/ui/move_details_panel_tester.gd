extends Node2D

@export var runTests: bool = true
@export var allowSurge: bool = true
@export var allowRunes: bool = true

@onready var moveDetailsPanel: MoveDetailsPanel = get_node('MoveDetailsPanel')

var tooLongDescriptionMoves: Array[Move] = []
var noDescriptionMoves: Array[Move] = []

func _ready() -> void:
	if allowSurge:
		# enable the battle text to show whether a move was charged or surged 
		PlayerResources.questInventory.currentAct = 1
		PlayerResources.playerInfo.set_dialogue_seen('grandstone_dr_ildran', 'surge')
	if allowRunes:
		PlayerResources.playerInfo.set_cutscene_seen('standstill_helia_approach')
	if runTests:
		await run_tests()
		print('--------\nMoves with too long a description:')
		for move: Move in tooLongDescriptionMoves:
			print(move.moveName)
		print('--------\nMoves with NO description:')
		for move: Move in noDescriptionMoves:
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
			if move.description == '':
				noDescriptionMoves.append(move)
			moveDetailsPanel.move = move
			moveDetailsPanel.load_move_details_panel()
			await get_tree().process_frame
			test_move_details_panel()

func test_move_details_panel() -> void:
	if moveDetailsPanel.moveDescription.get_v_scroll_bar().visible:
		tooLongDescriptionMoves.append(moveDetailsPanel.move)
