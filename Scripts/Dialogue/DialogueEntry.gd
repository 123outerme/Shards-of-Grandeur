extends Resource
class_name DialogueEntry

@export var entryId: String = ''
@export var items: Array[DialogueItem] = []
@export var saysStartingAtAct: int = 0
@export var stopsSayingAtAct: int = 5
@export var prerequisiteQuests: Array[String] = []
@export var prerequisiteCutscenes: Array[String] = []
@export var prerequisiteDialogues: Array[String] = []
@export var stopSayingAfterDialogues: Array[String] = []
@export var startsQuest: Quest = null

func _init(
	i_id = '',
	i_items: Array[DialogueItem] = [],
	i_startAct = 0,
	i_stopAct = 5,
	i_prereqQuests: Array[String] = [],
	i_prereqCutscenes: Array[String] = [],
	i_prereqDialogues: Array[String] = [],
	i_stopAfterDialogues: Array[String] = [],
	i_startsQuest = null,
):
	entryId = i_id
	items = i_items
	saysStartingAtAct = i_startAct
	stopsSayingAtAct = i_stopAct
	prerequisiteQuests = i_prereqQuests
	prerequisiteCutscenes = i_prereqCutscenes
	prerequisiteDialogues = i_prereqDialogues
	stopSayingAfterDialogues = i_stopAfterDialogues
	startsQuest = i_startsQuest

func can_use_dialogue() -> bool:
	if PlayerResources.questInventory.currentAct < saysStartingAtAct or PlayerResources.questInventory.currentAct > stopsSayingAtAct:
		return false
	
	if not PlayerResources.questInventory.has_completed_prereqs(prerequisiteQuests):
		return false
		
	for cutscene in prerequisiteCutscenes:
		if not PlayerResources.playerInfo.has_seen_cutscene(cutscene):
			return false
	
	for dialogue in prerequisiteDialogues:
		var npcSaveName = dialogue.split('#')[0]
		var dialogueId = dialogue.split('#')[1]
		if not PlayerResources.playerInfo.has_seen_dialogue(npcSaveName, dialogueId):
			return false
	
	for dialogue in stopSayingAfterDialogues:
		var npcSaveName = dialogue.split('#')[0]
		var dialogueId = dialogue.split('#')[1]
		if PlayerResources.playerInfo.has_seen_dialogue(npcSaveName, dialogueId):
			return false
	
	if startsQuest != null and not PlayerResources.questInventory.can_start_quest(startsQuest):
		return false
	
	return true
