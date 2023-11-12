extends Resource
class_name Quest

@export_category("Quest - Details")
@export var questName: String
@export_multiline var description: String
@export var steps: Array[QuestStep]
@export var prerequisiteQuestNames: Array[String]
@export var availableAtAct: int = 0
@export var unavailableAfterAct: int = 5

func _init(
	i_name = '',
	i_description = '',
	i_steps: Array[QuestStep] = [],
	i_prereqs: Array[String] = [],
):
	questName = i_name
	description = i_description
	steps = i_steps
	prerequisiteQuestNames = i_prereqs
