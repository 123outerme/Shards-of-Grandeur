extends Resource
class_name NPCData

@export var saveName: String = "NPC"
@export var animSet: SpriteFrames = null
@export_category("NPCData - Position")
@export var position: Vector2
@export var flipH: bool = false
@export var visible: bool = true
@export var selectedTarget: int = 0
@export var loops: int = 0
@export var disableMovement: bool = false
@export var previousDisableMove: bool = false
@export var version: String = ''

@export_category("NPCData - Dialogue")
@export var dialogueItems: Array = []
@export var dialogueIndex: int = -1
@export var dialogueItemIdx: int = -1
@export var dialogueLine: int = -1

@export_category("NPCData - Shopkeeping")
@export var inventory: Inventory
@export var hasShop: bool = false

func _init(
	i_saveName = "npc",
	i_animSet = null,
	i_position = Vector2(),
	i_flipH = false,
	i_visible = true,
	i_selectedTarget = 0,
	i_loops = 0,
	i_disableMovement = false,
	i_previousDisableMove = false,
	i_version = '',
	i_dialogueItems = [],
	i_dialogueIndex = -1,
	i_dialogueItemIdx = -1,
	i_dialogueLine = -1,
	i_inventory = Inventory.new(),
	i_hasShop = false,
):
	saveName = i_saveName
	animSet = i_animSet
	position = i_position
	flipH = i_flipH
	visible = i_visible
	selectedTarget = i_selectedTarget
	loops = i_loops
	disableMovement = i_disableMovement
	if i_version != '' or Engine.is_editor_hint():
		version = i_version
	else:
		version = GameSettings.get_game_version()
	previousDisableMove = i_previousDisableMove
	dialogueItems = i_dialogueItems
	dialogueIndex = i_dialogueIndex
	dialogueItemIdx = i_dialogueItemIdx
	dialogueLine = i_dialogueLine
	inventory = i_inventory
	hasShop = i_hasShop

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file()):
		data = load(save_path + save_file())
		if data != null:
			return data
	return data

func save_data(save_path, data):
	version = GameSettings.get_game_version()
	var err = ResourceSaver.save(data, save_path + save_file())
	if err != 0:
		printerr("NPCData/" + saveName + " ResourceSaver error: " + String.num(err))
		
func save_file() -> String:
	return "npc_" + saveName + ".tres"
