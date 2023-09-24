extends Resource
class_name NPCData

@export var saveName: String = "NPC"
@export_category("NPCData - Position")
@export var position: Vector2
@export var selectedTarget: int = 0
@export var loops: int = 0
@export var disableMovement: bool = false
@export var previousDisableMove: bool = false

@export_category("NPCData - Dialogue")
@export var dialogueItems: Array = []
@export var dialogueIndex: int = -1

@export_category("NPCData - Shopkeeping")
@export var inventory: Inventory
@export var hasShop: bool = false

func _init(
	i_saveName = "npc",
	i_position = Vector2(),
	i_selectedTarget = 0,
	i_loops = 0,
	i_disableMovement = false,
	i_previousDisableMove = false,
	i_dialogueItems = [],
	i_dialogueIndex = -1,
	i_inventory = Inventory.new(),
	i_hasShop = false,
):
	saveName = i_saveName
	position = i_position
	selectedTarget = i_selectedTarget
	loops = i_loops
	disableMovement = i_disableMovement
	previousDisableMove = i_previousDisableMove
	dialogueItems = i_dialogueItems
	dialogueIndex = i_dialogueIndex
	inventory = i_inventory
	hasShop = i_hasShop

func load_data(save_path):
	if ResourceLoader.exists(save_path + save_file()):
		return load(save_path + save_file())
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file())
	if err != 0:
		printerr("NPCData/" + saveName + " ResourceSaver error: " + String.num(err))
		
func save_file() -> String:
	return "npc_" + saveName + ".tres"
