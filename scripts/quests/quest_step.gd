extends Resource
class_name QuestStep

enum Type {
	TALK = 0,
	COLLECT_ITEM = 1,
	DEFEAT = 2,
	CUTSCENE = 3,
	ALL = -1,
}

static func TypeToString(t: Type) -> String:
	match t:
		Type.TALK:
			return 'Talk'
		Type.COLLECT_ITEM:
			return 'Collect'
		Type.DEFEAT:
			return 'Defeat'
		Type.CUTSCENE:
			return ''
		Type.ALL:
			return 'All'
	return 'Unknown'

@export_category("Quest Step - Details")
@export var name: String
@export_multiline var description: String
@export var reward: Reward

@export_category("Quest Step - Completion")
@export var type: Type = Type.TALK
@export var count: int = 1
@export var objectiveName: String
@export var turnInNames: Array[String]
@export var displayObjName: String
@export var displayTurnInName: String
@export var customStatusStr: String

@export_category("Quest Step - Dialogue")
@export var turnInDialogue: Array[DialogueEntry]
@export var inProgressDialogue: Array[DialogueEntry]

func _init(
	i_name = '',
	i_description = '',
	i_type = Type.TALK,
	i_count = 1,
	i_objectiveName = '',
	i_turnInNames: Array[String] = [],
	i_dispObjName = '',
	i_dispTurnInName = '',
	i_customStatus = '',
	i_reward = null,
	i_turnInDlg: Array[DialogueEntry] = [],
	i_inProgressDlg: Array[DialogueEntry] = [],
):
	name = i_name
	description = i_description
	type = i_type
	count = i_count
	objectiveName = i_objectiveName
	turnInNames = i_turnInNames
	displayObjName = i_dispObjName
	displayTurnInName = i_dispTurnInName
	customStatusStr = i_customStatus
	reward = i_reward
	turnInDialogue = i_turnInDlg
	inProgressDialogue = i_inProgressDlg
