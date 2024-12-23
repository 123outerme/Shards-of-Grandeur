extends Resource
class_name QuestTracker

enum Status {
	NOT_STARTED = 0,
	IN_PROGRESS = 1,
	READY_TO_TURN_IN_STEP = 2,
	COMPLETED = 3,
	FAILED = 4,
	INCOMPLETE = -1, # negative numbers: for use as filters, not as quest statuses
	ALL = -2,
	MAIN_QUEST = -3,
}

static func StatusToString(s: Status) -> String:
	match s:
		Status.NOT_STARTED:
			return 'Not Started'
		Status.IN_PROGRESS:
			return 'In Progress'
		Status.READY_TO_TURN_IN_STEP:
			return 'Ready To Turn In'
		Status.COMPLETED:
			return 'Completed'
		Status.INCOMPLETE:
			return 'Incomplete'
		Status.FAILED:
			return 'Failed'
		Status.ALL:
			return 'All'
	return 'Unknown'

@export var quest: Quest = null
@export var stepProgressCounts: Array[int] = [0]
@export var currentStep: int = 0
@export var pinned: bool = false

func _init(i_quest = null, i_progress: Array[int] = [0], i_curStep = 0, i_pinned = false):
	quest = i_quest
	stepProgressCounts = i_progress
	currentStep = i_curStep
	pinned = i_pinned

func get_current_status() -> Status:
	if currentStep >= len(quest.steps):
		return Status.COMPLETED
	
	var curStep = get_current_step()
	if curStep != null:
		return get_step_status(curStep)
	
	return Status.NOT_STARTED

func get_current_step() -> QuestStep:
	if currentStep >= 0:
		return quest.steps[min(currentStep, len(quest.steps) - 1)] # cap at last array element
	return null
	
func get_prev_step() -> QuestStep:
	if currentStep >= 1:
		return quest.steps[min(currentStep, len(quest.steps) - 1) - 1] # cap at second-to-last array element
	return quest.steps[0] # if on first step, consider it to also be prev step
	
func get_step_by_name(name: String) -> QuestStep:
	for step in quest.steps:
		if step.name == name:
			return step
	return null
	
func get_step_index(step: QuestStep) -> int:
	for idx in range(len(quest.steps)):
		if step == quest.steps[idx]:
			return idx
	return -1

func get_step_progress(step: QuestStep) -> int:
	var idx = get_step_index(step)
	if idx >= 0:
		if idx < len(stepProgressCounts):
			return stepProgressCounts[idx]
		else:
			return 0
	return -1

func get_step_status(step: QuestStep) -> Status:
	if step == null:
		return Status.NOT_STARTED # not sure what else to return here
	var idx = get_step_index(step)
	if idx == currentStep and quest.storyRequirements != null and not quest.storyRequirements.is_valid():
		return Status.FAILED
	
	if idx >= 0 and idx < len(stepProgressCounts):
		var progress = get_step_progress(step)
		if progress >= step.count:
			if progress == -1 or currentStep > idx:
				return Status.COMPLETED
			return Status.READY_TO_TURN_IN_STEP
		return Status.IN_PROGRESS
	return Status.NOT_STARTED

func get_step_status_str(step: QuestStep, getProgress: bool = false) -> String:
	var status: Status = get_step_status(step)
	if status == Status.IN_PROGRESS or getProgress:
		var st: String = ''
		if step.type == QuestStep.Type.TALK:
			st += 'Talk to'
		if step.type == QuestStep.Type.COLLECT_ITEM:
			st += 'Collect'
		if step.type == QuestStep.Type.ACQUIRE_ITEM:
			st += 'Acquire'
		if step.type == QuestStep.Type.DEFEAT:
			st += 'Defeat'
		if step.type == QuestStep.Type.STATIC_ENCOUNTER:
			st += 'Beat'
		st += ' ' + step.displayObjName + ' (' + TextUtils.num_to_comma_string(get_step_progress(step)) + ' / ' + TextUtils.num_to_comma_string(step.count) + ')!'
		if step.type == QuestStep.Type.CUTSCENE or step.type == QuestStep.Type.SOLVE_PUZZLE:
			st = '???'
		if step.customStatusStr != '':
			st = step.customStatusStr
		return st
	if status == Status.COMPLETED:
		if step.displayTurnInName != '':
			return 'Turned in to ' + step.displayTurnInName + '.'
		return 'Completed.'
	if status == Status.READY_TO_TURN_IN_STEP:
		if step.displayTurnInName != '':
			return 'Turn in to ' + step.displayTurnInName + '!'
		return 'Ready to Turn In!'
	if status == Status.FAILED:
		return 'Failed.'
	return '???'
	
func get_known_steps() -> Array[QuestStep]:
	var knownSteps: Array[QuestStep] = []
	for i in range(min(currentStep, len(quest.steps) - 1), -1, -1): # for each step from current step down to the first (or all steps if current step >= # of steps)
		knownSteps.append(quest.steps[i]) # add the known quest step
	return knownSteps

func turn_in_step() -> bool:
	if get_current_status() == Status.READY_TO_TURN_IN_STEP:
		currentStep += 1
		stepProgressCounts.append(0)
		PlayerResources.questInventory.auto_update_quests()
	return currentStep >= len(quest.steps)

func set_current_step_progress(count: int = 0):
	var idx = get_step_index(get_current_step())
	if idx == -1:
		return
	stepProgressCounts[idx] = min(count, quest.steps[idx].count)

func add_current_step_progress(count: int = 1):
	var idx = get_step_index(get_current_step())
	if idx == -1:
		return
	stepProgressCounts[idx] = min(stepProgressCounts[idx] + count, quest.steps[idx].count)
