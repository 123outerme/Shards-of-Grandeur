@tool
extends Resource
class_name StoryRequirements

@export_category("Acts")

## 0 == Prologue
@export var minAct: int = 0

## 0 == Prologue. -1 == no max
@export var maxAct: int = -1

@export_category("Prerequisites")

## specified by "<Quest Name>" for completion of the whole quest, or "<Quest Name>#<Step Name>" for a specific step
@export var prereqQuests: Array[String] = []

## specified by a cutscene ID
@export var prereqCutscenes: Array[String] = []

## specified by "<NPC ID>#<dialogue ID>"
@export var prereqDialogues: Array[String] = []

## specified by "<map name>"
@export var prereqPlacesVisited: Array[String] = []

## specified by "<static encounter ID>"
@export var prereqSpecialBattles: Array[String] = []

## specified by "<enemy save name>"
@export var prereqDefeatedEnemies: Array[String] = []

## specified by "<puzzle ID>"
@export var prereqPuzzles: Array[String] = []

## specified by "<base combatant save name>#<evolution save name>"
@export var prereqDiscoveredEvolutions: Array[String] = []

@export_category("Invalidations")

## specified by "<Quest Name>" for completion of the whole quest, or "<Quest Name>#<Step Name>" for a specific step
@export var invalidAfterCompletingQuests: Array[String] = []

## specified by "<Quest Name>" for completion of the whole quest, or "<Quest Name>#<Step Name>" for a specific step
@export var invalidAfterFailingQuests: Array[String] = []

## specified by a cutscene ID
@export var invalidAfterCutscenes: Array[String] = []

## specified by "<NPC ID>#<dialogue ID>"
@export var invalidAfterDialogues: Array[String] = []

## specified by "<map name>"
@export var invalidAfterVistingPlaces: Array[String] = []

## specified by "<static encounter ID>"
@export var invalidAfterSpecialBattles: Array[String] = []

## specified by "<puzzle ID>"
@export var invalidAfterSolvingPuzzles: Array[String] = []

func _init(
	i_minAct = 0,
	i_maxAct = -1,
	i_prereqQuests: Array[String] = [],
	i_prereqCutscenes: Array[String] = [],
	i_prereqDialogues: Array[String] = [],
	i_prereqPlaces: Array[String] = [],
	i_prereqBattles: Array[String] = [],
	i_prereqDefeatedEnemies: Array[String] = [],
	i_prereqPuzzles: Array[String] = [],
	i_prereqEvos: Array[String] = [],
	i_invalidCompletedQuests: Array[String] = [],
	i_invalidFailedQuests: Array[String] = [],
	i_invalidCutscenes: Array[String] = [],
	i_invalidDialogues: Array[String] = [],
	i_invalidPlacesVisited: Array[String] = [],
	i_invalidBattles: Array[String] = [],
	i_invalidPuzzles: Array[String] = [],
):
	minAct = i_minAct
	maxAct = i_maxAct
	prereqQuests = i_prereqQuests
	prereqCutscenes = i_prereqCutscenes
	prereqDialogues = i_prereqDialogues
	prereqPlacesVisited = i_prereqPlaces
	prereqSpecialBattles = i_prereqBattles
	prereqDefeatedEnemies = i_prereqDefeatedEnemies
	prereqPuzzles = i_prereqPuzzles
	prereqDiscoveredEvolutions = i_prereqEvos
	invalidAfterCompletingQuests = i_invalidCompletedQuests
	invalidAfterFailingQuests = i_invalidFailedQuests
	invalidAfterCutscenes = i_invalidCutscenes
	invalidAfterDialogues = i_invalidDialogues
	invalidAfterVistingPlaces = i_invalidPlacesVisited
	invalidAfterSpecialBattles = i_invalidBattles
	invalidAfterSolvingPuzzles = i_invalidPuzzles

func is_valid() -> bool:
	if Engine.is_editor_hint():
		return true
	
	if PlayerResources.questInventory.currentAct < minAct or (maxAct >= 0 and PlayerResources.questInventory.currentAct > maxAct):
		return false
		
	if not PlayerResources.questInventory.has_completed_prereqs(prereqQuests):
		return false
	
	for cutscene in prereqCutscenes:
		if not PlayerResources.playerInfo.has_seen_cutscene(cutscene):
			return false
	
	for dialogue in prereqDialogues:
		var npcSaveName = dialogue.split('#')[0]
		var dialogueId = dialogue.split('#')[1]
		if not PlayerResources.playerInfo.has_seen_dialogue(npcSaveName, dialogueId):
			return false
	
	for place in prereqPlacesVisited:
		if not PlayerResources.playerInfo.has_visited_place(place):
			return false
	
	for battle in prereqSpecialBattles:
		if not PlayerResources.playerInfo.has_completed_special_battle(battle):
			return false
			
	for enemy in prereqDefeatedEnemies:
		if not PlayerResources.playerInfo.has_defeated_enemy(enemy):
			return false
	
	for puzzle in prereqPuzzles:
		if not PlayerResources.playerInfo.has_solved_puzzle(puzzle):
			return false
	
	for fullEvoSaveName: String in prereqDiscoveredEvolutions:
		if not PlayerResources.playerInfo.has_found_evolution(fullEvoSaveName):
			return false
	
	if PlayerResources.questInventory.has_reached_status_for_one_quest_of(invalidAfterCompletingQuests, QuestTracker.Status.COMPLETED):
		return false
		
	if PlayerResources.questInventory.has_reached_status_for_one_quest_of(invalidAfterFailingQuests, QuestTracker.Status.FAILED):
		return false
	
	for cutscene in invalidAfterCutscenes:
		if PlayerResources.playerInfo.has_seen_cutscene(cutscene):
			return false
	
	for dialogue in invalidAfterDialogues:
		var npcSaveName = dialogue.split('#')[0]
		var dialogueId = dialogue.split('#')[1]
		if PlayerResources.playerInfo.has_seen_dialogue(npcSaveName, dialogueId):
			return false
	
	for place in invalidAfterVistingPlaces:
		if PlayerResources.playerInfo.has_visited_place(place):
			return false
	
	for battle in invalidAfterSpecialBattles:
		if PlayerResources.playerInfo.has_completed_special_battle(battle):
			return false
			
	for puzzle in invalidAfterSolvingPuzzles:
		if PlayerResources.playerInfo.has_solved_puzzle(puzzle):
			return false
	
	return true
