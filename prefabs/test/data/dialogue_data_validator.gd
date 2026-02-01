extends Control

const DIALOGUE_ROOT_PATH: String = 'res://gamedata/dialogue/'

func _ready() -> void:
	execute_for_each_dialogue(test_callable)

func test_callable(entry: DialogueEntry) -> void:
	pass

func execute_for_each_dialogue(callable: Callable) -> void:
	_execute_for_each_dialogue_helper(DIALOGUE_ROOT_PATH, callable)
	
func _execute_for_each_dialogue_helper(path: String, callable: Callable) -> void:
	var files: PackedStringArray = DirAccess.get_files_at(path)
	for file: String in files:
			# just in case there's a ".remap" in the path that's not at the end (although this should never be the case):
			# get everything except the LAST file extension present
			var resourceFilename: String = file.get_basename()
				# if it doesn't have ".tres" at the end (only if being played in the editor): add it
			if not resourceFilename.ends_with('.tres'):
				resourceFilename += '.tres'
			var dialogueEntry = ResourceLoader.load(path + resourceFilename)
			if dialogueEntry != null:
				if dialogueEntry is DialogueEntry:
					callable.call(dialogueEntry)
				elif dialogueEntry is InteractableDialogue:
					callable.call(dialogueEntry.dialogueEntry)
	var directories: PackedStringArray = DirAccess.get_directories_at(path)
	for dir: String in directories:
		_execute_for_each_dialogue_helper(path + '/' + dir + '/', callable)
