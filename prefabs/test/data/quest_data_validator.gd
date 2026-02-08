extends Control

const QUESTS_ROOT_PATH: String = 'res://gamedata/quests/'

var resultStrings: Array[String] = []

func _ready() -> void:
	#execute_for_each_quest(test_in_progress_prev_step_logic_relied_on)
	#print("===========")
	print('Quests/Steps missing Display Objective AND Custom Status:')
	execute_for_each_quest(test_steps_missing_display_objective_and_custom_status)
	print("===========")
	print('Quests/Steps missing Display Turn In Names:')
	execute_for_each_quest(test_steps_missing_display_turn_in_names)
	print("===========")
	print('Quests/Steps missing Objective:')
	execute_for_each_quest(test_steps_missing_objective)
	print("===========")
	print('Quests/Steps missing Objective Location:')
	execute_for_each_quest(test_steps_missing_objective_locations)
	print("===========")
	print('Quests/Steps missing Turn-In Location:')
	execute_for_each_quest(test_steps_missing_turn_in_locations)
	print("===========")
	print('Quests/Steps with both a Display Objective Name and Custom Status String:')
	execute_for_each_quest(test_steps_with_both_display_objective_name_and_custom_status_string)
	print("===========")
	print('Quests/Steps with a Name of "TBD":')
	execute_for_each_quest(test_steps_with_name_tbd)
	get_tree().quit()

func test_callable(quest: Quest) -> void:
	print(quest.questName)

## Tests that changing the pre-v0.4.2 quest step turn in logic did not alter the ability to turn in any of the quests that would have leveraged the logic as it was coded in v0.4.1 and before
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
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
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
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_missing_display_turn_in_names(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if len(curStep.turnInNames) > 0 and curStep.displayTurnInName == '':
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_missing_objective(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if curStep.objectiveName == '':
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_missing_display_objective_and_custom_status(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if curStep.customStatusStr == '' and curStep.displayObjName == '':
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_missing_objective_locations(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if len(curStep.locations) == 0:
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_missing_turn_in_locations(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if len(curStep.turnInNames) > 0 and len(curStep.turnInLocations) == 0:
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_with_both_display_objective_name_and_custom_status_string(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if curStep.displayObjName != '' and curStep.customStatusStr != '':
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

func test_steps_with_name_tbd(quest: Quest) -> void:
	var foundAny: bool = false
	for idx: int in range(len(quest.steps)):
		var curStep: QuestStep = quest.steps[idx]
		if curStep.name.to_lower().contains('tbd'):
			if not foundAny:
					resultStrings.append("Quest " + quest.questName + ' (' + quest.resource_path + ')' + ":")
			resultStrings.append("> Step " + curStep.name + " (idx " + String.num_int64(idx) + ")")
			foundAny = true
	if foundAny:
		resultStrings.append("")

# execute helper methods
func execute_for_each_quest(callable: Callable) -> void:
	resultStrings = []
	_execute_for_each_quest_helper(QUESTS_ROOT_PATH, callable)
	for strng: String in resultStrings:
		print(strng)
	
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
