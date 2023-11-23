extends Resource
class_name PlayerInfo

@export_category("PlayerInfo: Location")
@export var position: Vector2 = Vector2(-50, 0)
@export var flipH: bool = false
@export var map: String = "intro_map"
@export var inUnderworld: bool
@export var underworldMap: String
@export var underworldDepth: int
@export var savedPosition: Vector2
@export var scene: String = "Overworld"

@export_category("PlayerInfo: Stats")
@export var stats: Stats = (load("res://gamedata/combatants/player.tres") as Combatant).stats.copy()
@export var combatant: Combatant = (load("res://gamedata/combatants/player.tres") as Combatant).copy()
@export var gold: int = 10

@export_category("PlayerInfo: Battle")
@export var inBattle: bool
@export var exitingBattle: bool
@export var encounteredName: String
@export var encounteredLevel: int = 1
@export var encounteredReward: Reward = null
@export var encounteredBoss: bool = false
@export var specialBattleId: String
@export var completedSpecialBattles: Array[String] = []

@export_category("PlayerInfo: Overworld State")
@export var pickedUpItems: Array[String] = []
@export var pickedUpItem: PickedUpItem = null
@export var cutscenesPlayed: Array[String] = []
@export var dialoguesSeen: Dictionary = {}

var save_file = "playerinfo.tres"

func _init(
	i_map = "intro_map",
	i_inUnderworld = false,
	i_underworldMap = "",
	i_underworldDepth = 0,
	i_position = Vector2(-50, 0),
	i_savedPosition = Vector2(-50,0),
	i_flipH = false,
	i_scene = "Overworld",
	i_stats = (load("res://gamedata/combatants/player.tres") as Combatant).stats.copy(),
	i_combatant = (load("res://gamedata/combatants/player.tres") as Combatant).copy(),
	i_gold = 10,
	i_inBattle = false,
	i_exitingBattle = false,
	i_encounteredName = "",
	i_encounteredLevel = 1,
	i_encounteredReward = null,
	i_encounteredBoss = false,
	i_specialBattleId = '',
	i_completedSpecialBattles: Array[String] = [],
	i_pickedUpItems: Array[String] = [],
	i_pickedUpItem = null,
	i_cutscenesPlayed: Array[String] = [],
	i_dialoguesSeen: Dictionary = {},
):
	map = i_map
	inUnderworld = i_inUnderworld
	underworldMap = i_underworldMap
	underworldDepth = i_underworldDepth
	position = i_position
	savedPosition = i_savedPosition
	flipH = i_flipH
	scene = i_scene
	stats = i_stats
	combatant = i_combatant
	gold = i_gold
	inBattle = i_inBattle
	exitingBattle = i_exitingBattle
	encounteredName = i_encounteredName
	encounteredLevel = i_encounteredLevel
	encounteredReward = i_encounteredReward
	encounteredBoss = i_encounteredBoss
	specialBattleId = i_specialBattleId
	completedSpecialBattles = i_completedSpecialBattles
	pickedUpItems = i_pickedUpItems
	pickedUpItem = i_pickedUpItem
	cutscenesPlayed = i_cutscenesPlayed
	dialoguesSeen = i_dialoguesSeen

func has_picked_up(uniqueId: String) -> bool:
	return pickedUpItems.has(uniqueId)

func has_seen_cutscene(saveName: String) -> bool:
	return cutscenesPlayed.has(saveName)

func set_cutscene_seen(saveName: String):
	if not has_seen_cutscene(saveName):
		cutscenesPlayed.append(saveName)

func has_seen_dialogue(npcSaveName: String, dialogueId: String) -> bool:
	if dialoguesSeen.has(npcSaveName):
		return dialogueId in dialoguesSeen[npcSaveName]
	
	return false

func set_dialogue_seen(npcSaveName: String, dialogueId: String):
	if dialoguesSeen.has(npcSaveName) and not (dialogueId in dialoguesSeen[npcSaveName]):
		dialoguesSeen[npcSaveName].append(dialogueId)
	else:
		dialoguesSeen[npcSaveName] = [dialogueId]
	
func has_completed_special_battle(battleId: String) -> bool:
	return battleId in completedSpecialBattles

func set_special_battle_completed(battleId: String):
	if not has_completed_special_battle(battleId):
		completedSpecialBattles.append(battleId)

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = load(save_path + save_file)
		if data != null:
			return data
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("PlayerInfo ResourceSaver error: ", err)
