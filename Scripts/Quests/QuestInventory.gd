extends Resource
class_name QuestInventory

@export var quests: Array[QuestTracker] = []

var save_name: String = "quests.tres"

func _init(i_quests: Array[QuestTracker] = []):
	quests = i_quests

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
		if curStep.turnInName == targetName:
			trackers.append(questTracker)
	return trackers

func has_completed_prereqs(prereqNames: Array[String]) -> bool:
	var hasCompleted: bool = true
	for name in prereqNames:
		var completedPrereq: bool = false
		var tracker: QuestTracker = get_quest_tracker_by_name(name)
		if tracker != null and tracker.get_current_status() == QuestTracker.Status.COMPLETED:
			completedPrereq = true
		hasCompleted = hasCompleted and completedPrereq
	return hasCompleted

func accept_quest(q: Quest):
	if get_quest_tracker_by_quest(q) != null:
		return
	var tracker: QuestTracker = QuestTracker.new(q)
	quests.append(tracker)
	
func progress_quest(target: String, type: QuestStep.Type, progress: int = 1):
	for tracker in get_cur_trackers_for_target(target):
			if tracker.get_current_step().type == type:
				tracker.add_current_step_progress(progress)

func turn_in_cur_step(tracker: QuestTracker):
	var allDone: bool = tracker.turn_in_step()
	if allDone:
		quests.erase(tracker)
	# TODO yield rewards

func load_data(save_path):
	if ResourceLoader.exists(save_path + save_name):
		return load(save_path + save_name)
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_name)
	if err != 0:
		printerr("QuestInventory ResourceSaver error: " + err)
