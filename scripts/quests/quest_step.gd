extends Resource
class_name QuestStep

enum Type {
	TALK = 0, ## talk to an NPC and get to a specific dialogue entry
	COLLECT_ITEM = 1, ## collect `X` number of items and give them to the turn-in NPC
	DEFEAT = 2, ## defeat `X` number of enemies
	CUTSCENE = 3, ## see the specified cutscene
	STATIC_ENCOUNTER = 4, ## achieve victory in the specified static encounter
	SOLVE_PUZZLE = 5, ##  solve the specified puzzle
	ACQUIRE_ITEM = 6, ## acquire `X` number of items, NOT giving them to the turn-in NPC
	ALL = -1, ## use only for filtering
}

static func type_to_string(t: Type) -> String:
	match t:
		Type.TALK:
			return 'Talk'
		Type.COLLECT_ITEM:
			return 'Collect'
		Type.ACQUIRE_ITEM:
			return 'Acquire'
		Type.DEFEAT:
			return 'Defeat'
		Type.STATIC_ENCOUNTER:
			return 'Beat'
		Type.CUTSCENE:
			return ''
		Type.SOLVE_PUZZLE:
			return ''
		Type.ALL:
			return 'All'
	return 'Unknown'

@export_category("Quest Step - Details")

@export var name: String

@export_multiline var description: String

## reward to grant the player on completion. Auto-turned in steps will not announce rewards to the player, so generally avoid defining rewards for those steps
@export var reward: Reward

## the location for use displaying in the Map screen when NOT complete or turn-in ready
@export var locations: Array[WorldLocation.MapLocation] = []

## the location for use displaying in the Map screen when turn-in ready ONLY
@export var turnInLocations: Array[WorldLocation.MapLocation] = []

@export_category("Quest Step - Completion")

@export var type: Type = Type.TALK

## amount of objectives to fulfill. Talk, Defeat, Static Encounter, Cutscene, and Puzzle steps should only ever be 1
@export var count: int = 1

## the objective name (save name if there is a distinction)
@export var objectiveName: String

## The list of saveNames this step can be turned in to. If empty and a Solve Puzzle type, will auto-turn in
@export var turnInNames: Array[String]

## the objective name to display to the player
@export var displayObjName: String

## the name to tell the player to turn this step into
@export var displayTurnInName: String

## if specified, the quest status will be displayed as this until completed. If defined, no `displayObjName` or `displayTurnInName` need be defined.
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
