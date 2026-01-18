extends Node2D
class_name ToolDialogueEditor

signal file_saved(filepath: String)
signal preview_entry_finished

const SFX_BUTTON_SCENE = preload("res://prefabs/ui/sfx_button.tscn")
const SFX_NINE_PATH_BUTTON_SCENE = preload("res://prefabs/ui/sfx_nine_patch_button.tscn")
const DIALOGUE_ITEM_EDITOR = preload("res://prefabs/tools/dialogue_editor/dialogue_item_editor/dialogue_item_editor.tscn")

enum ToolDialogueEditorMenuState {
	CREATE_OR_LOAD_ENTRY, ## initial decision point of loading or creating a Dialogue Entry
	LOAD_ENTRY, ## Choosing an existing DialogueEntry to load
	CHOOSE_MAP, ## Choosing the map this DialogueEntry belongs to
	CHOOSE_NPC, ## Choosing the NPC on this map this DialogueEntry belongs to
	EDIT_ENTRY, ## menu for options of editing a DialogueEntry
	SAVING_ENTRIES, ## menu for choosing where to save the dialogues (if necessary)
	PREVIEW_ENTRY, ## preview entry state (automatically transitions back to last state)
}

static func menu_state_to_string(state: ToolDialogueEditorMenuState) -> String:
	match state:
		ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY:
			return 'Create/Load DialogueEntry'
		ToolDialogueEditorMenuState.LOAD_ENTRY:
			return 'Load DialogueEntry'
		ToolDialogueEditorMenuState.CHOOSE_MAP:
			return 'Load Map'
		ToolDialogueEditorMenuState.CHOOSE_NPC:
			return 'Select NPC/Interactable Speaker'
		ToolDialogueEditorMenuState.EDIT_ENTRY:
			return 'Edit Entry'
		ToolDialogueEditorMenuState.SAVING_ENTRIES:
			return 'Save Dialogues'
		ToolDialogueEditorMenuState.PREVIEW_ENTRY:
			return 'Previewing Entry...'
	return 'UNKNOWN_STATE'

enum ToolDialogueEditorButtonAction {
	BACK_ACTION,
	LOAD_ENTRY_ACTION,
	CREATE_ENTRY_ACTION,
	ADD_ITEM_ACTION,
	SAVE_ACTION,
	CLEAR_CHOICE_LEADS_TO_ACTION,
	PREVIEW_ENTRY_ACTION
}

static func button_action_to_label(action: ToolDialogueEditorButtonAction) -> String:
	match action:
		ToolDialogueEditorButtonAction.BACK_ACTION:
			return 'Back'
		ToolDialogueEditorButtonAction.SAVE_ACTION:
			return 'Save All'
		ToolDialogueEditorButtonAction.LOAD_ENTRY_ACTION:
			return 'Load DialogueEntry'
		ToolDialogueEditorButtonAction.CREATE_ENTRY_ACTION:
			return 'Create DialogueEntry'
		ToolDialogueEditorButtonAction.ADD_ITEM_ACTION:
			return 'Add DialogueItem'
		ToolDialogueEditorButtonAction.CLEAR_CHOICE_LEADS_TO_ACTION:
			return 'Clear Choice Leads To'
		ToolDialogueEditorButtonAction.PREVIEW_ENTRY_ACTION:
			return 'Preview Entry'
	return 'UNKNOWN_ACTION'

@export var loadDialogueEntry: DialogueEntry
@export var loadInteractableDialogue: InteractableDialogue
@export var loadMap: PackedScene

@onready var testCamera: TestCamera = get_node('TestCamera')
@onready var textBox: TextBox = get_node('TestCamera/TextBoxRoot')
@onready var menuStateTitle: RichTextLabel = get_node('TestCamera/HudRoot/MenuStateTitle')
@onready var actionButtonsHFlow: HFlowContainer = get_node('TestCamera/HudRoot/ActionButtonsHFlow')
@onready var dialogueItemEditorsTabContainer: TabContainer = get_node('TestCamera/HudRoot/DialogueItemsTabContainer')
@onready var mapRoot: Node = get_node('MapRoot')
@onready var npcButtons: Node = get_node('MapRoot/NpcButtons')
@onready var audioHandler: AudioHandler = get_node('AudioHandler')

@onready var entrySettings: Control = get_node('TestCamera/HudRoot/EntrySettings')
@onready var selectForChoiceCtrl: Control = get_node('TestCamera/HudRoot/EntrySettings/SelectForChoiceControl')
@onready var interactableSpeakerCtrl: Control = get_node("TestCamera/HudRoot/EntrySettings/InteractableSpeakerControl")
@onready var interactableSpeakerLineEdit: LineEdit = get_node("TestCamera/HudRoot/EntrySettings/InteractableSpeakerControl/InteractableSpeaker")
@onready var entryIdLineEdit: LineEdit = get_node('TestCamera/HudRoot/EntrySettings/EntryIdControl/EntryId')
@onready var closesDialogueButton: CheckButton = get_node('TestCamera/HudRoot/EntrySettings/ClosesDialogueControl/ClosesDialogue')
@onready var givesQuestButton: Button = get_node('TestCamera/HudRoot/EntrySettings/GivesQuestControl/GivesQuestButton')
@onready var fullyHealsButton: CheckButton = get_node('TestCamera/HudRoot/EntrySettings/FullyHealsControl/FullyHeals')
@onready var dialogueChoicesEditor: ToolDialogueChoicesEditor = get_node('TestCamera/HudRoot/DialogueChoicesEditor')
@onready var entryQuestPicker: ToolEntryQuestPicker = get_node('TestCamera/HudRoot/EntryQuestPicker')

var questsDict: Dictionary[String, Quest] = {}

var stateActionsDict: Dictionary[ToolDialogueEditorMenuState, Array] = {}

var menuState: ToolDialogueEditorMenuState = ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY
var menuStateStack: Array[ToolDialogueEditorMenuState] = []

var fileDialog: FileDialog = null

var dialogueSavePath: String = ''
var editingInteractableDialogue: InteractableDialogue = null
var editingEntry: DialogueEntry = null

# Stack-based storage of parents dialogues; if something is not set, it should be pushed as a NULL
var parentSavePaths: Array[String] = []
var parentInteractableDialogues: Array[InteractableDialogue] = []
var parentEntries: Array[DialogueEntry] = []
var parentChoices: Array[DialogueChoice] = []
var parentStackStartIdxs: Array[int] = []

var editingMap: MapScript = null
var mapNpcs: Array[Node] = []
var mapInteractables: Array[Node] = []
var editingNpc: NPCScript = null
var editingInteractable: Interactable = null

var previewingItems: Array[DialogueItem] = []
var previewingLineIdx: int = -1
var previewingOneLine: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and textBox.visible:
			if not textBox.is_textbox_complete():
				textBox.show_text_instant()
			elif len(previewingItems) > 0:
				advance_preview()
	elif event.is_action_pressed("game_interact") and textBox.visible:
		if not textBox.is_textbox_complete():
			textBox.show_text_instant()
		elif len(previewingItems) > 0:
			advance_preview()

func _ready() -> void:
	SceneLoader.ignoreStoryRequirements = true
	var focusPrevInput: InputEventKey = InputEventKey.new()
	focusPrevInput.keycode = KEY_TAB
	focusPrevInput.shift_pressed = true
	var focusNextInput: InputEventKey = InputEventKey.new()
	focusNextInput.keycode = KEY_TAB
	InputMap.action_add_event('ui_focus_prev', focusPrevInput)
	InputMap.action_add_event('ui_focus_next', focusNextInput)
	
	SceneLoader.audioHandler = audioHandler
	stateActionsDict[ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY] = [
		ToolDialogueEditorButtonAction.LOAD_ENTRY_ACTION,
		ToolDialogueEditorButtonAction.CREATE_ENTRY_ACTION
	]
	
	stateActionsDict[ToolDialogueEditorMenuState.EDIT_ENTRY] = [
		ToolDialogueEditorButtonAction.ADD_ITEM_ACTION,
		ToolDialogueEditorButtonAction.PREVIEW_ENTRY_ACTION
	]
	
	load_quests()
	if (loadDialogueEntry != null or loadInteractableDialogue != null):
		textBox.hide_textbox()
		if loadInteractableDialogue != null:
			editingInteractableDialogue = loadInteractableDialogue
			editingEntry = loadInteractableDialogue.dialogueEntry
			dialogueSavePath = loadInteractableDialogue.resource_path
		else:
			editingEntry = loadDialogueEntry
			dialogueSavePath = loadDialogueEntry.resource_path
		menuStateStack = [ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY, ToolDialogueEditorMenuState.LOAD_ENTRY]
		menuState = ToolDialogueEditorMenuState.CHOOSE_MAP
		if loadMap != null:
			_on_file_dialog_file_selected(loadMap.resource_path)
			return
	
	load_menu_state()

func load_quests() -> void:
	questsDict = {}
	var filepathQueue: Array[String] = ['res://gamedata/quests']
	while not filepathQueue.is_empty():
		var filepath: String = filepathQueue.pop_front()
		var dirs: PackedStringArray = DirAccess.get_directories_at(filepath)
		for dir: String in dirs:
			filepathQueue.append(filepath + '/' + dir)
		var files: PackedStringArray = DirAccess.get_files_at(filepath)
		for fileName: String in files:
			var questResource: Resource = ResourceLoader.load(filepath + '/' + fileName, '', ResourceLoader.CACHE_MODE_REPLACE_DEEP)
			if questResource is Quest:
				var quest: Quest = questResource as Quest
				questsDict.set(quest.questName, quest)
	entryQuestPicker.questsDict = questsDict

func load_menu_state() -> void:
	menuStateTitle.text = '[center]' + menu_state_to_string(menuState) + '[/center]'
	testCamera.disableInputHandling = true
	interactableSpeakerCtrl.visible = editingInteractableDialogue != null
	if editingEntry == null:
		textBox.hide_textbox()
	match menuState:
		ToolDialogueEditorMenuState.LOAD_ENTRY, ToolDialogueEditorMenuState.CHOOSE_MAP:
			init_file_dialog()
			fileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			if menuState == ToolDialogueEditorMenuState.LOAD_ENTRY:
				fileDialog.title = 'Load DialogueEntry'
				fileDialog.filters = ["*.tres,*.res"]
				fileDialog.root_subfolder = "gamedata/dialogue"
			elif menuState == ToolDialogueEditorMenuState.CHOOSE_MAP:
				fileDialog.title = 'Load Map For Entry'
				fileDialog.filters = ["*.tscn,*.scn"]
				fileDialog.root_subfolder = "prefabs/maps"
		ToolDialogueEditorMenuState.CHOOSE_NPC:
			load_npc_buttons()
			testCamera.disableInputHandling = false
		ToolDialogueEditorMenuState.EDIT_ENTRY:
			var lastState: ToolDialogueEditorMenuState = menuStateStack.back()
			if lastState == ToolDialogueEditorMenuState.CHOOSE_NPC or lastState == ToolDialogueEditorMenuState.LOAD_ENTRY or lastState == ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY:
				load_dialogue_item_editors()
			load_entry_settings()
		ToolDialogueEditorMenuState.PREVIEW_ENTRY:
			preview_entry()
	load_action_buttons()

func init_file_dialog() -> FileDialog:
	fileDialog = FileDialog.new()
	add_child(fileDialog)
	fileDialog.position = get_viewport_rect().size / 2.0 - fileDialog.size / 2.0
	fileDialog.display_mode = FileDialog.DISPLAY_LIST
	fileDialog.show_hidden_files = true
	fileDialog.file_selected.connect(_on_file_dialog_file_selected)
	fileDialog.mode_overrides_title = false
	fileDialog.visible = true
	return fileDialog

func load_action_buttons() -> void:
	for child: Node in actionButtonsHFlow.get_children():
		actionButtonsHFlow.remove_child(child)
		child.queue_free.call_deferred()
	
	# save
	if editingEntry != null or len(parentEntries) > 0:
		var saveButton: Button = SFX_BUTTON_SCENE.instantiate()
		saveButton.text = button_action_to_label(ToolDialogueEditorButtonAction.SAVE_ACTION)
		saveButton.pressed.connect(_action_button_pressed.bind(ToolDialogueEditorButtonAction.SAVE_ACTION))
		actionButtonsHFlow.add_child(saveButton)
	
	# clear choice leadsTo
	if len(parentChoices) > 0:
		var clearButton: Button = SFX_BUTTON_SCENE.instantiate()
		clearButton.text = button_action_to_label(ToolDialogueEditorButtonAction.CLEAR_CHOICE_LEADS_TO_ACTION)
		clearButton.pressed.connect(_action_button_pressed.bind(ToolDialogueEditorButtonAction.CLEAR_CHOICE_LEADS_TO_ACTION))
		actionButtonsHFlow.add_child(clearButton)
	
	if stateActionsDict.has(menuState):
		var actions: Array = stateActionsDict[menuState]
		for action: ToolDialogueEditorButtonAction in actions:
			var button: Button = SFX_BUTTON_SCENE.instantiate()
			button.text = button_action_to_label(action)
			button.pressed.connect(_action_button_pressed.bind(action))
			actionButtonsHFlow.add_child(button)
	
	# back
	if len(menuStateStack) > 0:
		var backButton: Button = SFX_BUTTON_SCENE.instantiate()
		backButton.text = button_action_to_label(ToolDialogueEditorButtonAction.BACK_ACTION)
		backButton.pressed.connect(_action_button_pressed.bind(ToolDialogueEditorButtonAction.BACK_ACTION))
		actionButtonsHFlow.add_child(backButton)

func load_npc_buttons() -> void:
	for npc: NPCScript in mapNpcs:
		npc.visible = true
		var button: SFXNinePatchButton = SFX_NINE_PATH_BUTTON_SCENE.instantiate()
		button.pressed.connect(_npc_button_pressed.bind(npc, null))
		npcButtons.add_child(button)
		button.size = npc.get_max_sprite_size() + Vector2i(8, 8)
		button.position = npc.position - 0.5 * button.size
	
	for interactable: Interactable in mapInteractables:
		interactable.visible = true
		var button: SFXNinePatchButton = SFX_NINE_PATH_BUTTON_SCENE.instantiate()
		button.pressed.connect(_npc_button_pressed.bind(null, interactable))
		npcButtons.add_child(button)
		button.size = interactable.get_max_sprite_size() + Vector2i(8, 8)
		button.position = interactable.position - 0.5 * button.size

func load_dialogue_item_editors() -> void:
	for child: Node in dialogueItemEditorsTabContainer.get_children():
		child.name += ' Old' # prevent name clashes before the old one is finally freed
		child.visible = false
		child.queue_free()
	
	for itemIdx: int in range(len(editingEntry.items)):
		var itemEditor: ToolDialogueItemEditor = DIALOGUE_ITEM_EDITOR.instantiate()
		itemEditor.dialogueItem = editingEntry.items[itemIdx]
		itemEditor.name = 'Item ' + String.num_int64(itemIdx + 1)
		itemEditor.preview_line_toggled.connect(preview_line)
		itemEditor.delete_item_pressed.connect(_on_dialogue_item_editor_delete_item)
		itemEditor.edit_choices_toggled.connect(_on_dialogue_item_editor_edit_choices_toggled)
		dialogueItemEditorsTabContainer.add_child(itemEditor)
	dialogueItemEditorsTabContainer.visible = true

func load_entry_settings() -> void:
	entrySettings.visible = true
	selectForChoiceCtrl.visible = len(parentChoices) > 0
	if editingInteractableDialogue != null:
		interactableSpeakerCtrl.visible = true
		interactableSpeakerLineEdit.text = editingInteractableDialogue.speaker
	else:
		interactableSpeakerCtrl.visible = false
	entryIdLineEdit.text = editingEntry.entryId
	closesDialogueButton.button_pressed = editingEntry.closesDialogue
	fullyHealsButton.button_pressed = editingEntry.fullHealsPlayer
	if editingEntry.startsQuest != null:
		givesQuestButton.text = editingEntry.startsQuest.questName
	else:
		givesQuestButton.text = '(No Quest)'

func load_text_box(dialogueItem: DialogueItem) -> void:
	textBox.dialogueItem = dialogueItem
	textBox.speakerAnim = dialogueItem.animation
	if dialogueItem.speakerOverride != '@':
		if editingNpc != null:
			textBox.speakerSpriteFrames = editingNpc.get_sprite_frames()
			textBox.speakerSpriteOffset = editingNpc.speakerSpriteOffset
		elif editingInteractable != null:
			textBox.speakerSpriteFrames = editingInteractable.get_sprite_frames()
			textBox.speakerSpriteOffset = editingInteractable.speakerSpriteOffset
	#textBox.update_speaker_sprite() # not necessary, textBox.set_textbox_text will handle this

func preview_line(dialogueItem: DialogueItem, lineIdx: int, text: String, previewingSingleLine = true) -> void:
	if previewingSingleLine:
		previewingItems = [dialogueItem]
	previewingLineIdx = lineIdx
	previewingOneLine = previewingSingleLine
	load_text_box(dialogueItem)
	
	var speakerName: String = 'ERROR'
	if editingNpc != null:
		speakerName = editingNpc.displayName
	elif editingInteractable != null:
		speakerName = editingInteractableDialogue.speaker
	textBox.set_textbox_text(TextUtils.rich_text_substitute(text, Vector2i(32, 32)), dialogueItem.speakerOverride if dialogueItem.speakerOverride != '' else speakerName, len(dialogueItem.lines) - 1 == lineIdx)

func advance_preview() -> void:
	var dialogueItem: DialogueItem = previewingItems[0]
	previewingLineIdx += 1
	if previewingLineIdx >= len(dialogueItem.lines) or previewingOneLine:
		previewingItems.pop_front()
		if len(previewingItems) == 0 or previewingOneLine:
			stop_previewing()
			return
		dialogueItem = previewingItems[0]
		previewingLineIdx = 0
	preview_line(dialogueItem, previewingLineIdx, dialogueItem.lines[previewingLineIdx], previewingOneLine)

func preview_entry() -> void:
	if editingEntry == null or len(editingEntry.items) == 0:
		return
	previewingItems = editingEntry.items.duplicate()
	previewingLineIdx = 0
	preview_line(previewingItems[0], previewingLineIdx, previewingItems[0].lines[previewingLineIdx], false)
	await preview_entry_finished
	menuState = menuStateStack.pop_back()
	load_menu_state()

func stop_previewing() -> void:
	textBox.visible = false
	previewingItems = []
	previewingLineIdx = -1
	preview_entry_finished.emit()

func save_dialogues(justCurrent = false) -> void:
	if dialogueSavePath != '':
		if editingInteractableDialogue != null:
			ResourceSaver.save(editingInteractableDialogue, dialogueSavePath)
			if editingInteractableDialogue.dialogueEntry.resource_path.begins_with('res://'):
				ResourceSaver.save(editingInteractableDialogue.dialogueEntry, editingInteractableDialogue.dialogueEntry.resource_path)
		elif editingEntry != null:
			ResourceSaver.save(editingEntry, dialogueSavePath)
	else:
		init_file_dialog()
		fileDialog.root_subfolder = "gamedata/dialogue"
		fileDialog.title = 'Save Current Dialogue'
		fileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		fileDialog.filters = ["*.tres,*.res"]
		
		dialogueSavePath = await file_saved
		if editingInteractableDialogue != null:
			ResourceSaver.save(editingInteractableDialogue, dialogueSavePath)
		elif editingEntry != null:
			ResourceSaver.save(editingEntry, dialogueSavePath)
		var resource: Resource = ResourceLoader.load(dialogueSavePath, '', ResourceLoader.CACHE_MODE_REPLACE_DEEP)
		if resource is InteractableDialogue:
			editingInteractableDialogue = resource as InteractableDialogue
			editingEntry = editingInteractableDialogue.dialogueEntry
		elif resource is DialogueEntry:
			editingInteractableDialogue = null
			editingEntry = resource as DialogueEntry
	
	if justCurrent:
		return
	
	for idx: int in range(len(parentSavePaths)):
		var parentSavePath: String = parentSavePaths[idx]
		var parentInteractableDialogue: InteractableDialogue = parentInteractableDialogues[idx]
		var parentEntry: DialogueEntry = parentEntries[idx]
		if parentSavePath != '':
			if parentInteractableDialogue != null:
				ResourceSaver.save(parentInteractableDialogue, parentSavePath)
				if parentInteractableDialogue.dialogueEntry.resource_path.begins_with('res://'):
					ResourceSaver.save(parentInteractableDialogue.dialogueEntry, parentInteractableDialogue.dialogueEntry.resource_path)
			elif parentEntry != null:
				ResourceSaver.save(parentEntry, parentSavePath)
		else:
			init_file_dialog()
			fileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			fileDialog.root_subfolder = "gamedata/dialogue"
			fileDialog.title = 'Save Parent ' + String.num_int64(idx + 1) + ' Dialogue'
			fileDialog.filters = ["*.tres,*.res"]
		
			parentSavePath = await file_saved
			if parentInteractableDialogue != null:
				ResourceSaver.save(parentInteractableDialogue, parentSavePath)
			elif parentEntry != null:
				ResourceSaver.save(parentEntry, parentSavePath)
			parentSavePaths[idx] = parentSavePath
			var resource: Resource = ResourceLoader.load(parentSavePath, '', ResourceLoader.CACHE_MODE_REPLACE_DEEP)
			if resource is InteractableDialogue:
				parentInteractableDialogues[idx] = resource as InteractableDialogue
				parentEntries[idx] = editingInteractableDialogue.dialogueEntry
			elif resource is DialogueEntry:
				parentInteractableDialogues[idx] = null
				parentEntries[idx] = resource as DialogueEntry
	menuState = menuStateStack.pop_back()
	load_menu_state()

func pop_entry_stack() -> void:
	var stackIdx: int = parentStackStartIdxs.pop_back()
	editingInteractableDialogue = parentInteractableDialogues.pop_back()
	editingEntry = parentEntries.pop_back()
	parentChoices.pop_back()
	dialogueSavePath = parentSavePaths.pop_back()
	for idx: int in range(stackIdx, len(menuStateStack)):
		menuStateStack.pop_back()
	menuState = menuStateStack.pop_back()
	load_menu_state()

func _action_button_pressed(action: ToolDialogueEditorButtonAction) -> void:
	if action != ToolDialogueEditorButtonAction.BACK_ACTION and \
		action != ToolDialogueEditorButtonAction.ADD_ITEM_ACTION:
		menuStateStack.append(menuState)
	match action:
		ToolDialogueEditorButtonAction.BACK_ACTION:
			if len(parentStackStartIdxs) > 0 and parentStackStartIdxs.back() == len(menuStateStack):
				pop_entry_stack()
				return
			elif menuState == ToolDialogueEditorMenuState.PREVIEW_ENTRY:
				stop_previewing()
				return
			else:
				if menuState == ToolDialogueEditorMenuState.CHOOSE_MAP:
					editingMap.queue_free()
					editingMap = null
				if menuState == ToolDialogueEditorMenuState.CHOOSE_NPC:
					editingNpc = null
					editingInteractable = null
					for child: Node in npcButtons.get_children():
						child.visible = false
						child.queue_free()
				menuState = menuStateStack.pop_back()
		ToolDialogueEditorButtonAction.CREATE_ENTRY_ACTION:
			editingEntry = DialogueEntry.new()
			dialogueSavePath = ''
			if editingMap == null:
				menuState = ToolDialogueEditorMenuState.CHOOSE_MAP
			else:
				if editingInteractable != null:
					editingInteractableDialogue = InteractableDialogue.new()
				menuState = ToolDialogueEditorMenuState.EDIT_ENTRY
				load_entry_settings()
		ToolDialogueEditorButtonAction.LOAD_ENTRY_ACTION:
			menuState = ToolDialogueEditorMenuState.LOAD_ENTRY
		ToolDialogueEditorButtonAction.ADD_ITEM_ACTION:
			if editingEntry != null:
				editingEntry.items.append(DialogueItem.new())
				load_dialogue_item_editors()
		ToolDialogueEditorButtonAction.SAVE_ACTION:
			menuState = ToolDialogueEditorMenuState.SAVING_ENTRIES
			save_dialogues()
		ToolDialogueEditorButtonAction.CLEAR_CHOICE_LEADS_TO_ACTION:
			var parentChoice: DialogueChoice = parentChoices.back()
			parentChoice.leadsTo = null
			pop_entry_stack()
		ToolDialogueEditorButtonAction.PREVIEW_ENTRY_ACTION:
			menuState = ToolDialogueEditorMenuState.PREVIEW_ENTRY
	load_menu_state()

func _npc_button_pressed(npc: NPCScript, interactable: Interactable) -> void:
	editingNpc = npc
	editingInteractable = interactable
	
	if interactable != null and dialogueSavePath == '':
		editingInteractableDialogue = InteractableDialogue.new()
		editingInteractableDialogue.dialogueEntry = editingEntry
	
	menuStateStack.append(menuState)
	menuState = ToolDialogueEditorMenuState.EDIT_ENTRY
	load_entry_settings()
	
	for child: Node in npcButtons.get_children():
		child.visible = false
		child.queue_free()
	load_menu_state()

func _on_file_dialog_file_selected(path: String) -> void:
	if menuState != ToolDialogueEditorMenuState.SAVING_ENTRIES:
		menuStateStack.append(menuState)
	match menuState:
		ToolDialogueEditorMenuState.LOAD_ENTRY:
			dialogueSavePath = path
			var resource: Resource = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_REPLACE_DEEP)
			if resource is InteractableDialogue:
				editingInteractableDialogue = resource as InteractableDialogue
				editingEntry = editingInteractableDialogue.dialogueEntry
			elif resource is DialogueEntry:
				editingInteractableDialogue = null
				editingEntry = resource as DialogueEntry
			else:
				printerr("ERROR: Resource not recognized as a dialogue entry/interactable entry")
			if editingMap == null:
				menuState = ToolDialogueEditorMenuState.CHOOSE_MAP
			else:
				menuState = ToolDialogueEditorMenuState.EDIT_ENTRY
				load_entry_settings()
		ToolDialogueEditorMenuState.CHOOSE_MAP:
			if editingMap != null:
				editingMap.visible = false
				editingMap.queue_free()
			mapNpcs = []
			mapInteractables = []
			editingNpc = null
			editingInteractable = null
			var mapInstance = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_REPLACE_DEEP)
			editingMap = mapInstance.instantiate()
			mapRoot.add_child(editingMap)
			mapNpcs = get_tree().get_nodes_in_group('NPC')
			mapInteractables = get_tree().get_nodes_in_group('Interactable')
			mapInteractables = mapInteractables.filter(_filter_map_interactables)
			menuState = ToolDialogueEditorMenuState.CHOOSE_NPC
		ToolDialogueEditorMenuState.SAVING_ENTRIES:
			file_saved.emit(path)
	if fileDialog != null:
		fileDialog.visible = false
		fileDialog.queue_free()
		fileDialog = null
	if menuState != ToolDialogueEditorMenuState.SAVING_ENTRIES:
		load_menu_state.call_deferred()
	else:
		menuStateStack.pop_back() # undo push at the beginning here

func _on_dialogue_item_editor_delete_item(dialogueItem: DialogueItem) -> void:
	if editingEntry == null:
		return
	var removeIdx: int = editingEntry.items.find(dialogueItem)
	if removeIdx < 0:
		return
	for idx: int in range(removeIdx, len(editingEntry.items) - 1):
		editingEntry.items[idx] = editingEntry.items[idx + 1]
	editingEntry.items.pop_back()
	load_dialogue_item_editors()

func _on_dialogue_item_editor_edit_choices_toggled(dialogueItem: DialogueItem) -> void:
	dialogueChoicesEditor.dialogueItem = dialogueItem
	dialogueChoicesEditor.questsDict = questsDict
	dialogueChoicesEditor.load_choices_editor()

func _filter_map_interactables(interactable: Node) -> bool:
	return interactable is Interactable and not (interactable is GroundItem)

func _on_interactable_speaker_text_changed(new_text: String) -> void:
	if editingInteractableDialogue != null:
		editingInteractableDialogue.speaker = new_text

func _on_gives_quest_button_pressed() -> void:
	entryQuestPicker.load_entry_quest_picker()

func _on_entry_quest_picker_set_entry_quest(quest: Quest) -> void:
	editingEntry.startsQuest = quest
	if editingEntry.startsQuest != null:
		givesQuestButton.text = editingEntry.startsQuest.questName
	else:
		givesQuestButton.text = '(No Quest)'

func _on_select_for_choice_button_pressed() -> void:
	if len(parentChoices) > 0:
		await save_dialogues(true)
		var parentChoice: DialogueChoice = parentChoices.back()
		parentChoice.leadsTo = editingEntry
		pop_entry_stack()

func _on_entry_id_text_changed(new_text: String) -> void:
	editingEntry.entryId = new_text

func _on_closes_dialogue_toggled(toggled_on: bool) -> void:
	editingEntry.closesDialogue = toggled_on

func _on_fully_heals_toggled(toggled_on: bool) -> void:
	editingEntry.fullHealsPlayer = toggled_on

func _on_dialogue_choices_editor_choice_leads_to_clicked(choiceIdx: int, dialogueItem: DialogueItem) -> void:
	menuStateStack.append(menuState)
	parentEntries.append(editingEntry)
	parentInteractableDialogues.append(editingInteractableDialogue)
	parentSavePaths.append(dialogueSavePath)
	parentStackStartIdxs.append(len(menuStateStack))
	parentChoices.append(dialogueItem.choices[choiceIdx])
	menuState = ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY
	dialogueChoicesEditor.visible = false
	load_menu_state()

func _on_dialogue_choices_editor_choices_editor_closed(dialogueItem: DialogueItem) -> void:
	for child: Node in dialogueItemEditorsTabContainer.get_children():
		if child is ToolDialogueItemEditor and child.dialogueItem == dialogueItem:
			child.load_item_editor()
			break

func _on_text_box_root_choice_selected(choice: DialogueChoice) -> void:
	if menuState != ToolDialogueEditorMenuState.PREVIEW_ENTRY or \
			choice.leadsTo != null or len(choice.randomDialogues) > 0 or \
			choice.returnsToParentId != '':
		 # close dialogue if it would lead somewhere else, or if this is not previewing a full entry
		stop_previewing()
		return
	if choice.repeatsItem:
		previewingLineIdx = -1
		advance_preview() # will increment previewing lineIdx by 1, restarting at 0
		return
	if choice is NPCDialogueChoice:
		if choice.opensShop:
			return # do nothing; as if player entered and exited shop
	
	# this is a no-op button
	advance_preview()
