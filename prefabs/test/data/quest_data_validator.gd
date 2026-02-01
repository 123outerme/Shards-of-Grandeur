extends Control

const QUESTS_ROOT_PATH: String = 'res://gamedata/quests/'

var resultStrings: Array[String] = []

func _ready() -> void:
	#execute_for_each_quest(test_in_progress_prev_step_logic_relied_on)
	#print("===========")
	execute_for_each_quest(test_steps_without_turn_in_names)

func test_callable(quest: Quest) -> void:
	print(quest.questName)

func test_in_progress_prev_step_logic_relied_on(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		var prevStep: QuestStep = null
		if idx >= 1:
			prevStep = quest.steps[idx - 1]
		if prevStep != null:
			if len(curStep.turnInNames) == 0 and len(prevStep.turnInNames) > 0 and len(curStep.inProgressDialogue) > 0:
				if not foundAny:
					resultStrings.append("Quest " + quest.questName + ":")
				resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ") uses previous step turn in NPCs for \"In Progress Dialogue\"")
				foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_without_turn_in_names(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if len(curStep.turnInNames) == 0:
			if not foundAny:
				resultStrings.append("Quest " + quest.questName + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ") has no turn-in NPCs (type " + QuestStep.type_to_debug_string(curStep.type) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func execute_for_each_quest(callable: Callable) -> void:
	resultStrings = []
	_execute_for_each_quest_helper(QUESTS_ROOT_PATH, callable)
	for str: String in resultStrings:
		print(str)
	
func _execute_for_each_quest_helper(path: String, callable: Callable) -> void:
	var files: PackedStringArray = DirAccess.get_files_at(path)
	for file: String in files:
			# just in case there's a ".remap" in the path that's not at the end (although this should never be the case):
			# get everything except the LAST file extension present
			var resourceFilename: String = file.get_basename()
				# if it doesn't have ".tres" at the end (only if being played in the editor): add it
			if not resourceFilename.ends_with('.tres'):
				resourceFilename += '.tres'
			var quest = ResourceLoader.load(path + resourceFilename)
			if quest != null and quest is Quest:
				callable.call(quest)
	var directories: PackedStringArray = DirAccess.get_directories_at(path)
	for dir: String in directories:
		_execute_for_each_quest_helper(path + '/' + dir + '/', callable)
