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
@export var saveSeed: int = -1
@export var version: String = ''

@export_category("PlayerInfo: Stats")
@export var combatant: Combatant = (load("res://gamedata/combatants/player/player.tres") as Combatant).copy()
@export var gold: int = 20
@export var playtimeSecs: float = 0

@export_category("PlayerInfo: Battle")
@export var encounteredName: String
@export var encounteredLevel: int = 1
@export var encounter: EnemyEncounter = null
@export var activeBattleModifierItems: Array[BattleModifierItem] = []
@export var completedSpecialBattles: Array[String] = []
@export var enemiesDefeated: Array[String] = []
@export var evolutionsFound: Array[String] = []

@export_category("PlayerInfo: Overworld State")
@export var pickedUpItems: Array[String] = []
@export var interactableDialogues: Array[InteractableDialogue] = []
@export var interactableDialogueIdx: int = 0
@export var interactableName: String = ''
@export var placesVisited: Array[String] = []
@export var mapLocationsVisited: Array[WorldLocation.MapLocation] = []
@export var cutscenesPlayed: Array[String] = []
@export var dialoguesSeen: Dictionary = {}
@export var puzzlesSolved: Array[String] = []
@export var puzzleStates: Dictionary = {}
@export var codexEntriesSeen: Array[String] = []
@export var cutscenesTempDisabled: Array[String] = []
@export var activeFollowers: Array[String] = []
@export var queuedRewards: Array[Reward] = []
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
	i_seed = -1,
	i_version = '',
	i_combatant = (load("res://gamedata/combatants/player/player.tres") as Combatant).copy(),
	i_gold = 20,
	i_playtimeSecs = 0,
	i_encounteredName = "",
	i_encounteredLevel = 1,
	i_encounter = null,
	i_activeBattleModifierItems: Array[BattleModifierItem] = [],
	i_completedSpecialBattles: Array[String] = [],
	i_enemiesDefeated: Array[String] = [],
	i_evolutionsFound: Array[String] = [],
	i_pickedUpItems: Array[String] = [],
	i_interactableDialogues: Array[InteractableDialogue] = [],
	i_interactableDialogueIdx = 0,
	i_interactableName = '',
	i_placesVisited: Array[String] = [],
	i_mapLocationsVisited: Array[WorldLocation.MapLocation] = [],
	i_cutscenesPlayed: Array[String] = [],
	i_dialoguesSeen: Dictionary = {},
	i_puzzlesSolved: Array[String] = [],
	i_puzzleStates: Dictionary = {},
	i_codexEntriesSeen: Array[String] = [],
	i_cutscenesTempDisabled: Array[String] = [],
	i_queuedRewards: Array[Reward] = [],
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
	saveSeed = i_seed
	if i_version != '':
		version = i_version
	else:
		version = GameSettings.get_game_version()
	combatant = i_combatant
	gold = i_gold
	playtimeSecs = i_playtimeSecs
	encounteredName = i_encounteredName
	encounteredLevel = i_encounteredLevel
	encounter = i_encounter
	activeBattleModifierItems = i_activeBattleModifierItems
	completedSpecialBattles = i_completedSpecialBattles
	enemiesDefeated = i_enemiesDefeated
	evolutionsFound = i_evolutionsFound
	pickedUpItems = i_pickedUpItems
	interactableDialogues = i_interactableDialogues
	interactableDialogueIdx = i_interactableDialogueIdx
	interactableName = i_interactableName
	placesVisited = i_placesVisited
	mapLocationsVisited = i_mapLocationsVisited
	cutscenesPlayed = i_cutscenesPlayed
	dialoguesSeen = i_dialoguesSeen
	puzzlesSolved = i_puzzlesSolved
	puzzleStates = i_puzzleStates
	codexEntriesSeen = i_codexEntriesSeen
	cutscenesTempDisabled = i_cutscenesTempDisabled
	queuedRewards = i_queuedRewards
	running = i_running

func get_battle_reward_item_count_modifier() -> float:
	var modifier: float = 1.0
	for item: BattleModifierItem in activeBattleModifierItems:
		modifier += (item.rewardItemCountModifier - 1.0)
	return modifier if modifier > 0 else 0

func get_battle_reward_exp_modifier() -> float:
	var modifier: float = 1.0
	for item: BattleModifierItem in activeBattleModifierItems:
		modifier += (item.rewardExpModifier - 1.0)
	return modifier if modifier > 0 else 0

func get_battle_reward_gold_modifier() -> float:
	var modifier: float = 1.0
	for item: BattleModifierItem in activeBattleModifierItems:
		modifier += (item.rewardGoldModifier - 1.0)
	return modifier if modifier > 0 else 0

func get_battle_attunement_modifier() -> float:
	var modifier: float = 1.0
	for item: BattleModifierItem in activeBattleModifierItems:
		modifier += (item.rewardExpModifier - 1.0)
	return modifier if modifier > 0 else 0

func get_spawns_three_face_combatant() -> bool:
	for item: BattleModifierItem in activeBattleModifierItems:
		if item.spawnsThreeOfFace:
			return true
	return false

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

func has_visited_place(placeName: String) -> bool:
	return placeName in placesVisited

func set_place_visited(placeName: String):
	if not has_visited_place(placeName):
		placesVisited.append(placeName)
		PlayerResources.story_requirements_updated.emit()

func has_visited_map_location(location: WorldLocation.MapLocation) -> bool:
	return location in mapLocationsVisited

func set_map_location_visited(location: WorldLocation.MapLocation) -> void:
	if not has_visited_map_location(location):
		mapLocationsVisited.append(location)
		PlayerResources.story_requirements_updated.emit()

func has_defeated_enemy(saveName: String) -> bool:
	return saveName in enemiesDefeated

func set_enemy_defeated(saveName: String):
	if not has_defeated_enemy(saveName):
		enemiesDefeated.append(saveName)
		PlayerResources.story_requirements_updated.emit()

func has_completed_special_battle(battleId: String) -> bool:
	return battleId in completedSpecialBattles

func set_special_battle_completed(battleId: String):
	if not has_completed_special_battle(battleId):
		completedSpecialBattles.append(battleId)
		PlayerResources.story_requirements_updated.emit()

func has_solved_puzzle(puzzleId: String) -> bool:
	return puzzleId in puzzlesSolved

func set_puzzle_solved(puzzleId: String):
	if not has_solved_puzzle(puzzleId):
		puzzlesSolved.append(puzzleId)
		#PlayerResources.story_requirements_updated.emit() # TEST this can be enabled. I think it can't based on simple_puzzle_decoration.gd logic

func has_puzzle_states(puzzleId: String) -> bool:
	return puzzleStates.has(puzzleId)

func set_puzzle_states(puzzleId: String, states: Array[String]):
	var shouldSet: bool = false
	if not has_puzzle_states(puzzleId) or (len(states) != len(puzzleStates[puzzleId])):
		shouldSet = true
	if not shouldSet:
		for i in range(len(states)):
			if states[i] != puzzleStates[puzzleId][i]:
				shouldSet = true
				break
	if shouldSet:
		puzzleStates[puzzleId] = states.duplicate(false)
		PlayerResources.story_requirements_updated.emit()

func set_puzzle_state_at_index(puzzleId: String, index: int, state: String, defaultStates: Array[String] = [], defaultState: String = 'default'):
	if index < 0:
		return
	# if the puzzle ID is not present in the states array, first setup the default states
	if not has_puzzle_states(puzzleId):
		puzzleStates[puzzleId] = defaultStates.duplicate(false)
	var states: Array[String] = puzzleStates[puzzleId]
	if index < len(states):
		if states[index] != state:
			states[index] = state
			PlayerResources.story_requirements_updated.emit()
	else:
		# if the index is out of bounds of the array, add new elements until the index is in bounds
		var prevLen: int = len(states)
		for i in range(prevLen, index):
			# for this new index, if there is a defaultStates value for this index: use it
			if i < len(defaultStates):
				states.append(defaultStates[i])
			else:
				# otherwise, append the "default" state
				states.append(defaultState)
		states.append(state)
		PlayerResources.story_requirements_updated.emit()

func get_puzzle_states(puzzleId: String) -> Array[String]:
	if puzzleStates.has(puzzleId):
		return puzzleStates[puzzleId].duplicate(false)
	return []

## fullEvoSaveName intented to be: <combatant save name>#<evolution save name>
func has_found_evolution(fullEvoSaveName: String) -> bool:
	return fullEvoSaveName in evolutionsFound

func mark_evolution_found(fullEvoSaveName: String) -> void:
	if not has_found_evolution(fullEvoSaveName):
		evolutionsFound.append(fullEvoSaveName)
		PlayerResources.story_requirements_updated.emit()

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

func has_active_follower(followerId: String) -> bool:
	return followerId in activeFollowers

func set_follower_active(followerId: String) -> bool:
	if not has_active_follower(followerId):
		activeFollowers.append(followerId)
		return true
	return false

func remove_follower(followerId: String) -> bool:
	if has_active_follower(followerId):
		activeFollowers.erase(followerId)
		return true
	return false

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
