extends Resource
class_name PlayerInfo

@export_category("PlayerInfo: Location")
@export var position: Vector2 = Vector2(-50, 0)
@export var flipH: bool = false
@export var map: String = "intro_map"
@export var recoverMap: String = "intro_map"
@export var inUnderworld: bool
@export var underworldMap: String
@export var underworldDepth: int
@export var savedPosition: Vector2
@export var scene: String = "Overworld"
@export var version: String = ''

@export_category("PlayerInfo: Stats")
@export var combatant: Combatant = (load("res://gamedata/combatants/player/player.tres") as Combatant).copy()
@export var gold: int = 20
@export var playtimeSecs: float = 0

@export_category("PlayerInfo: Battle")
@export var encounteredName: String
@export var encounteredLevel: int = 1
@export var staticEncounter: StaticEncounter = null
@export var completedSpecialBattles: Array[String] = []
@export var enemiesDefeated: Array[String] = []

@export_category("PlayerInfo: Overworld State")
@export var pickedUpItems: Array[String] = []
@export var pickedUpItem: PickedUpItem = null
@export var cutscenesPlayed: Array[String] = []
@export var dialoguesSeen: Dictionary = {}
@export var codexEntriesSeen: Array[String] = []
@export var cutscenesTempDisabled: Array[String] = []
@export var running: bool = false

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
	i_version = '',
	i_combatant = (load("res://gamedata/combatants/player/player.tres") as Combatant).copy(),
	i_gold = 20,
	i_playtimeSecs = 0,
	i_encounteredName = "",
	i_encounteredLevel = 1,
	i_staticEncounter = null,
	i_completedSpecialBattles: Array[String] = [],
	i_enemiesDefeated: Array[String] = [],
	i_pickedUpItems: Array[String] = [],
	i_pickedUpItem = null,
	i_cutscenesPlayed: Array[String] = [],
	i_dialoguesSeen: Dictionary = {},
	i_codexEntriesSeen: Array[String] = [],
	i_cutscenesTempDisabled: Array[String] = [],
	i_running = false,
):
	map = i_map
	inUnderworld = i_inUnderworld
	underworldMap = i_underworldMap
	underworldDepth = i_underworldDepth
	position = i_position
	savedPosition = i_savedPosition
	flipH = i_flipH
	scene = i_scene
	if i_version != '':
		version = i_version
	else:
		version = GameSettings.get_game_version()
	combatant = i_combatant
	gold = i_gold
	playtimeSecs = i_playtimeSecs
	encounteredName = i_encounteredName
	encounteredLevel = i_encounteredLevel
	staticEncounter = i_staticEncounter
	completedSpecialBattles = i_completedSpecialBattles
	enemiesDefeated = i_enemiesDefeated
	pickedUpItems = i_pickedUpItems
	pickedUpItem = i_pickedUpItem
	cutscenesPlayed = i_cutscenesPlayed
	dialoguesSeen = i_dialoguesSeen
	codexEntriesSeen = i_codexEntriesSeen
	cutscenesTempDisabled = i_cutscenesTempDisabled
	running = i_running

func has_picked_up(uniqueId: String) -> bool:
	return pickedUpItems.has(uniqueId)

func has_seen_cutscene(saveName: String) -> bool:
	return cutscenesPlayed.has(saveName)

func set_cutscene_seen(saveName: String):
	if not has_seen_cutscene(saveName):
		cutscenesPlayed.append(saveName)
		PlayerResources.story_requirements_updated.emit()

func has_seen_dialogue(npcSaveName: String, dialogueId: String) -> bool:
	if dialoguesSeen.has(npcSaveName):
		return dialogueId in dialoguesSeen[npcSaveName]
	
	return false

func set_dialogue_seen(npcSaveName: String, dialogueId: String):
	if dialoguesSeen.has(npcSaveName):
		if not (dialogueId in dialoguesSeen[npcSaveName]):
			dialoguesSeen[npcSaveName].append(dialogueId)
			PlayerResources.story_requirements_updated.emit()
	else:
		dialoguesSeen[npcSaveName] = [dialogueId]
		PlayerResources.story_requirements_updated.emit()

func has_defeated_enemy(saveName: String) -> bool:
	return saveName in enemiesDefeated

func set_enemy_defeated(saveName: String):
	if not has_defeated_enemy(saveName):
		enemiesDefeated.append(saveName)

func has_completed_special_battle(battleId: String) -> bool:
	return battleId in completedSpecialBattles

func set_special_battle_completed(battleId: String):
	if not has_completed_special_battle(battleId):
		completedSpecialBattles.append(battleId)

func has_seen_codex_entry(entryName: String) -> bool:
	return entryName in codexEntriesSeen

func set_codex_entry_seen(entryName: String):
	if not has_seen_codex_entry(entryName):
		codexEntriesSeen.append(entryName)

func is_cutscene_temp_disabled(saveName: String) -> bool:
	return saveName in cutscenesTempDisabled

func set_cutscene_temp_disabled(saveName: String):
	if not is_cutscene_temp_disabled(saveName):
		cutscenesTempDisabled.append(saveName)

func clear_cutscenes_temp_disabled():
	cutscenesTempDisabled = []

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = ResourceLoader.load(save_path + save_file, '', ResourceLoader.CACHE_MODE_IGNORE)
		if data != null:
			return data
	return data

func save_data(save_path, data) -> int:
	data.version = GameSettings.get_game_version()
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("PlayerInfo ResourceSaver error: ", err)
	return err
