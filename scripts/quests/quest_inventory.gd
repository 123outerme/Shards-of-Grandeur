extends Resource
class_name QuestInventory

@export var quests: Array[QuestTracker] = []
@export var currentAct: int = 0

const actNames: Array[String] = [
	'Prologue', # act 0
	'The Radiant War', # act 1
	'act2placeholder', # act 2
	'act3placeholder', # act 3
	'act4placeholder', # act 4
]
var save_name: String = "quests.tres"

func _init(i_quests: Array[QuestTracker] = [], i_act = 0):
	quests = i_quests
	currentAct = i_act

func get_quest_tracker_by_quest(q: Quest) -> QuestTracker:
	for questTracker in quests:
		if q == questTracker.quest:
			return questTracker
	return null

func get_quest_tracker_by_name(name: String) -> QuestTracker:
	for questTracker in quests:
		if questTracker.quest.questName == name:
			return questTracker
	return null
	
func get_quest_tracker_for_step(step: QuestStep) -> QuestTracker:
	for questTracker in quests:
		if questTracker.get_step_index(step) >= 0:
			return questTracker
	return null
	
func get_cur_trackers_for_target(targetName: String) -> Array[QuestTracker]:
	var trackers: Array[QuestTracker] = []
	for questTracker in quests:
		var curStep = questTracker.get_current_step()
		if curStep.objectiveName == targetName:
			trackers.append(questTracker)
	return trackers

func can_start_quest(q: Quest) -> bool:
	if q == null:
		return false
	return not (q.storyRequirements != null and not q.storyRequirements.is_valid()) and get_quest_tracker_by_quest(q) == null

func has_completed_prereqs(prereqNames: Array[String]) -> bool:
	var hasCompleted: bool = true
	for name in prereqNames:
		var completedPrereq: bool = false
		if not '#' in name:
			var tracker: QuestTracker = get_quest_tracker_by_name(name)
			if tracker != null and tracker.get_current_status() == QuestTracker.Status.COMPLETED:
				completedPrereq = true
		else:
			var questName: String = name.split('#')[0]
			var stepName: String = name.split('#')[1]
			var tracker: QuestTracker = get_quest_tracker_by_name(questName)
			if tracker != null:
				var step: QuestStep = tracker.get_step_by_name(stepName)
				if tracker.get_step_status(step) == QuestTracker.Status.COMPLETED:
					completedPrereq = true
		hasCompleted = hasCompleted and completedPrereq
	return hasCompleted

func has_reached_status_for_one_quest_of(questNames: Array[String], status: QuestTracker.Status) -> bool:
	for name in questNames:
		if not '#' in name:
			var tracker: QuestTracker = get_quest_tracker_by_name(name)
			if tracker != null and tracker.get_current_status() == status:
				return true
		else:
			var questName: String = name.split('#')[0]
			var stepName: String = name.split('#')[1]
			var tracker: QuestTracker = get_quest_tracker_by_name(questName)
			if tracker != null:
				var step: QuestStep = tracker.get_step_by_name(stepName)
				if step != null:
					if tracker.get_step_status(step) == status:
						return true
	return false

func accept_quest(q: Quest):
	if q == null or get_quest_tracker_by_quest(q) != null or not can_start_quest(q):
		return
	var tracker: QuestTracker = QuestTracker.new(q)
	quests.append(tracker)
	auto_update_quests()

func auto_update_quests():
	for tracker in quests:
		var step: QuestStep = tracker.get_current_step()
		if tracker.get_step_status(step) == QuestTracker.Status.COMPLETED or tracker.get_step_status(step) == QuestTracker.Status.FAILED:
			continue # skip this quest if already completed or failed
		if step.type == QuestStep.Type.COLLECT_ITEM:
			var count: int = 0
			for slot in PlayerResources.inventory.inventorySlots:
				if slot.item.itemName == tracker.get_current_step().objectiveName:
					count += slot.count
			tracker.set_current_step_progress(count)
	for specialBattle in PlayerResources.playerInfo.completedSpecialBattles:
		if PlayerResources.playerInfo.has_completed_special_battle(specialBattle):
			progress_quest(specialBattle, QuestStep.Type.STATIC_ENCOUNTER)
	for cutscene in PlayerResources.playerInfo.cutscenesPlayed:
		progress_quest(cutscene, QuestStep.Type.CUTSCENE)
		auto_turn_in_cutscene_steps(cutscene)

func set_quest_progress(target: String, type: QuestStep.Type, progress: int = 0):
	for tracker in get_cur_trackers_for_target(target):
		if tracker.get_current_step().type == type and (tracker.quest.storyRequirements == null or tracker.quest.storyRequirements.is_valid()):
			tracker.set_current_step_progress(progress)
	
func progress_quest(target: String, type: QuestStep.Type, progress: int = 1):
	for tracker in get_cur_trackers_for_target(target):
			if tracker.get_current_step().type == type and (tracker.quest.storyRequirements == null or tracker.quest.storyRequirements.is_valid()):
				tracker.add_current_step_progress(progress)

func auto_turn_in_cutscene_steps(target: String):
	for tracker in get_cur_trackers_for_target(target):
		if tracker.get_current_status() == QuestTracker.Status.READY_TO_TURN_IN_STEP \
				and tracker.get_current_step().type == QuestStep.Type.CUTSCENE:
			turn_in_cur_step(tracker)

func turn_in_cur_step(tracker: QuestTracker) -> int:
	var curStep: QuestStep = tracker.get_current_step()
	var newLvs: int = PlayerResources.accept_rewards([curStep.reward])
	var allDone: bool = tracker.turn_in_step()
	if curStep.type == QuestStep.Type.COLLECT_ITEM:
		PlayerResources.inventory.trash_items_by_name(curStep.objectiveName, curStep.count)
	
	auto_update_quests()
	
	if allDone and tracker.quest.advanceActActerComplete:
		currentAct += 1 # advance act after quest completion
	
	PlayerResources.story_requirements_updated.emit()
	return newLvs

func get_sorted_trackers() -> Array[QuestTracker]:
	var trackers: Array[QuestTracker] = []
	trackers.append_array(quests)
	trackers.sort_custom(sort_by_pinned)
	return trackers

func sort_by_pinned(a: QuestTracker, b: QuestTracker) -> bool:
	if a.pinned and not b.pinned:
		return true # a goes before b
	if b.pinned and not a.pinned:
		return false # b goes before a
	return a.quest.questName.naturalnocasecmp_to(b.quest.questName) < 0 # compare names (including natural number comparisons)

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_name):
		data = load(save_path + save_name)
		if data != null:
			return data #.duplicate(true)
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_name)
	if err != 0:
		printerr("QuestInventory ResourceSaver error: ", err)
