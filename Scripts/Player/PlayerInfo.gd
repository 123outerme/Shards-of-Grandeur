extends Resource
class_name PlayerInfo

@export_category("PlayerInfo: Location")
@export var position: Vector2
@export var disableMovement: bool = false
@export var map: String = "TestMap1"
@export var inUnderworld: bool
@export var underworldMap: String
@export var underworldDepth: int
@export var savedPosition: Vector2
@export var scene: String = "Overworld"

@export_category("PlayerInfo: Stats")
@export var stats: Stats
@export var gold: int = 10

@export_category("PlayerInfo: Battle")
@export var inBattle: bool
@export var exitingBattle: bool
@export var encounteredName: String

@export_category("PlayerInfo: UI State")
@export var talkBtnsVisible: bool = false

var save_file = "playerinfo.tres"

func _init(
	i_map = "TestMap1",
	i_inUnderworld = false,
	i_underworldMap = "",
	i_underworldDepth = 0,
	i_savedPosition = Vector2(),
	i_scene = "Overworld",
	i_gold = 10,
	i_inBattle = false,
	i_exitingBattle = false,
	i_encounteredName = "",
	i_talkBtnsVisible = false,
):
	map = i_map
	inUnderworld = i_inUnderworld
	underworldMap = i_underworldMap
	underworldDepth = i_underworldDepth
	savedPosition = i_savedPosition
	scene = i_scene
	gold = i_gold
	inBattle = i_inBattle
	exitingBattle = i_exitingBattle
	encounteredName = i_encounteredName
	talkBtnsVisible = i_talkBtnsVisible


func load_data(save_path):
	if ResourceLoader.exists(save_path + save_file):
		return load(save_path + save_file)
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("PlayerInfo ResourceSaver error: " + err)
