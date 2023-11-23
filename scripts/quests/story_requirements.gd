extends Resource
class_name StoryRequirements

@export_category("Acts")
@export var minAct: int = 0
@export var maxAct: int = 5

@export_category("Prerequisites")
@export var prereqQuests: Array[String] = []
@export var prereqCutscenes: Array[String] = []
@export var prereqDialogues: Array[String] = []
@export var prereqSpecialBattles: Array[String] = []

@export_category("Invalidations")
@export var invalidAfterCompletingQuests: Array[String] = []
@export var invalidAfterFailingQuests: Array[String] = []
@export var invalidAfterCutscenes: Array[String] = []
@export var invalidAfterDialogues: Array[String] = []
@export var invalidAfterSpecialBattles: Array[String] = []

func _init(
	i_minAct = 0,
	i_maxAct = 5,
	i_prereqQuests: Array[String] = [],
	i_prereqCutscenes: Array[String] = [],
	i_prereqDialogues: Array[String] = [],
	i_prereqBattles: Array[String] = [],
	i_invalidCompletedQuests: Array[String] = [],
	i_invalidFailedQuests: Array[String] = [],
	i_invalidCutscenes: Array[String] = [],
	i_invalidDialogues: Array[String] = [],
	i_invalidBattles: Array[String] = [],
):
	minAct = i_minAct
	maxAct = i_maxAct
	prereqQuests = i_prereqQuests
	prereqCutscenes = i_prereqCutscenes
	prereqDialogues = i_prereqDialogues
	i_prereqBattles = i_prereqBattles
	invalidAfterCompletingQuests = i_invalidCompletedQuests
	invalidAfterFailingQuests = i_invalidFailedQuests
	invalidAfterCutscenes = i_invalidCutscenes
	invalidAfterDialogues = i_invalidDialogues
	invalidAfterSpecialBattles = i_invalidBattles

func is_valid() -> bool:
	if PlayerResources.questInventory.currentAct < minAct or PlayerResources.questInventory.currentAct > maxAct:
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
			
	for battle in prereqSpecialBattles:
		if not PlayerResources.playerInfo.has_completed_special_battle(battle):
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
	
	for battle in invalidAfterSpecialBattles:
		if PlayerResources.playerInfo.has_completed_special_battle(battle):
			return false
	
	return true
