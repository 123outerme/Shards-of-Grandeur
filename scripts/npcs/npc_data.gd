extends Resource
class_name NPCData

@export var saveName: String = "NPC"
@export var animSet: SpriteFrames = null
@export var spriteState: String = 'default'
@export var animation: String = 'stand'
@export_category("NPCData - Position")
@export var position: Vector2
@export var flipH: bool = false
@export var visible: bool = true
@export var selectedTarget: int = 0
@export var loops: int = 0
@export var disableMovement: bool = false
@export var previousDisableMove: bool = false
@export var afterMoveWaitAccum: float = 0
@export var followerHomePosition: Vector2
@export var followingPlayer: bool = false
@export var followerHomeSet: bool = false
@export var combatMode: bool = false
@export var version: String = ''

@export_category("NPCData - Dialogue")
@export var dialogueItems: Array = []
@export var dialogueIndex: int = -1
@export var dialogueItemIdx: int = -1
@export var dialogueLine: int = -1

@export_category("NPCData - Shopkeeping")
@export var inventory: Inventory

func _init(
	i_saveName = "npc",
	i_animSet = null,
	i_spriteState = 'default',
	i_animation = 'stand',
	i_position = Vector2(),
	i_flipH = false,
	i_visible = true,
	i_selectedTarget = 0,
	i_loops = 0,
	i_disableMovement = false,
	i_previousDisableMove = false,
	i_afterMoveWaitAccum = 0,
	i_followerHomePosition = Vector2(),
	i_followingPlayer = false,
	i_followerHomeSet = false,
	i_combatMode = false,
	i_version = '',
	i_dialogueItems = [],
	i_dialogueIndex = -1,
	i_dialogueItemIdx = -1,
	i_dialogueLine = -1,
	i_inventory = Inventory.new(),
):
	saveName = i_saveName
	animSet = i_animSet
	spriteState = i_spriteState
	animation = i_animation
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
	afterMoveWaitAccum = i_afterMoveWaitAccum
	followerHomePosition = i_followerHomePosition
	followingPlayer = i_followingPlayer
	followerHomeSet = i_followerHomeSet
	combatMode = i_combatMode
	dialogueItems = i_dialogueItems
	dialogueIndex = i_dialogueIndex
	dialogueItemIdx = i_dialogueItemIdx
	dialogueLine = i_dialogueLine
	inventory = i_inventory

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + get_save_filename()):
		data = ResourceLoader.load(save_path + get_save_filename(), '', ResourceLoader.CACHE_MODE_IGNORE)
		if data != null:
			return data
	return data

func save_data(save_path, data) -> int:
	version = GameSettings.get_game_version()
	var err = ResourceSaver.save(data, save_path + get_save_filename())
	if err != 0:
		printerr("NPCData/" + saveName + " ResourceSaver error: " + String.num_int64(err))
	return err

func get_save_filename() -> String:
	return "npc_" + saveName + ".tres"
