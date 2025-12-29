extends Node2D
class_name ToolDialogueEditor

signal file_saved(filepath: String)

const SFX_BUTTON_SCENE = preload("res://prefabs/ui/sfx_button.tscn")
const SFX_NINE_PATH_BUTTON_SCENE = preload("res://prefabs/ui/sfx_nine_patch_button.tscn")
const DIALOGUE_ITEM_EDITOR = preload("res://prefabs/tools/dialogue_editor/dialogue_item_editor/dialogue_item_editor.tscn")

enum ToolDialogueEditorMenuState {
	CREATE_OR_LOAD_ENTRY, ## initial decision point of loading or creating a Dialogue Entry
	LOAD_ENTRY, ## Choosing an existing DialogueEntry to load
	CHOOSE_MAP, ## Choosing the map this DialogueEntry belongs to
	CHOOSE_NPC, ## Choosing the NPC on this map this DialogueEntry belongs to
	EDIT_ENTRY, ## menu for options of editing a DialogueEntry
	CONFIGURE_ENTRY_SETTINGS, ## menu for configuring Entry settings
	EDIT_CHOICES, ## menu for editing DialogueChoices on the DialogueItem
	CONFIGURE_ITEM_SETTINGS, ## menu for configuring DialogueItem settings
	CONFIGURE_CHOICE_SETTINGS, ## menu for configuring the settings of a DialogueChoice
	SAVING_ENTRIES, ## menu for choosing where to save the dialogues (if necessary)
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
		ToolDialogueEditorMenuState.CONFIGURE_ENTRY_SETTINGS:
			return 'Configure Entry'
		ToolDialogueEditorMenuState.EDIT_CHOICES:
			return 'Edit Choices'
		ToolDialogueEditorMenuState.CONFIGURE_ITEM_SETTINGS:
			return 'Configure DialogueItem'
		ToolDialogueEditorMenuState.CONFIGURE_CHOICE_SETTINGS:
			return 'Configure Choice'
		ToolDialogueEditorMenuState.SAVING_ENTRIES:
			return 'Save Dialogues'
	return 'UNKNOWN_STATE'

enum ToolDialogueEditorButtonAction {
	BACK_ACTION,
	LOAD_ENTRY_ACTION,
	CREATE_ENTRY_ACTION,
	CONFIGURE_ENTRY_ACTION,
	EDIT_ITEM_ACTION,
	SAVE_ACTION,
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
		ToolDialogueEditorButtonAction.CONFIGURE_ENTRY_ACTION:
			return 'Configure Entry'
		ToolDialogueEditorButtonAction.EDIT_ITEM_ACTION:
			return 'Edit DialogueItems'
	return 'UNKNOWN_ACTION'

@onready var testCamera: TestCamera = get_node('TestCamera')
@onready var textBox: TextBox = get_node('TestCamera/TextBoxRoot')
@onready var menuStateTitle: RichTextLabel = get_node('TestCamera/HudRoot/MenuStateTitle')
@onready var actionButtonsHFlow: HFlowContainer = get_node('TestCamera/HudRoot/ActionButtonsHFlow')
@onready var dialogueItemEditorsTabContainer: TabContainer = get_node('TestCamera/HudRoot/DialogueItemsTabContainer')
@onready var mapRoot: Node = get_node('MapRoot')
@onready var npcButtons: Node = get_node('MapRoot/NpcButtons')
@onready var audioHandler: AudioHandler = get_node('AudioHandler')

@onready var interactableSpeakerCtrl: Control = get_node("TestCamera/HudRoot/EntrySettings/InteractableSpeakerControl")
@onready var interactableSpeakerLineEdit: LineEdit = get_node("TestCamera/HudRoot/EntrySettings/InteractableSpeakerControl/InteractableSpeaker")

var stateActionsDict: Dictionary[ToolDialogueEditorMenuState, Array] = {}

var menuState: ToolDialogueEditorMenuState = ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY
var menuStateStack: Array[ToolDialogueEditorMenuState] = []

var fileDialog: FileDialog = null

var dialogueSavePath: String = ''
var editingInteractableDialogue: InteractableDialogue = null
var editingEntry: DialogueEntry = null
var editingChoice: DialogueChoice = null

# Stack-based storage of parents dialogues; if something is not set, it should be pushed as a NULL
var parentSavePaths: Array[String] = []
var parentInteractableDialogues: Array[InteractableDialogue] = []
var parentEntries: Array[DialogueEntry] = []
var parentChoices: Array[DialogueChoice] = []

var editingMap: MapScript = null
var mapNpcs: Array[Node] = []
var mapInteractables: Array[Node] = []
var editingNpc: NPCScript = null
var editingInteractable: Interactable = null

func _ready() -> void:
	SceneLoader.audioHandler = audioHandler
	stateActionsDict[ToolDialogueEditorMenuState.CREATE_OR_LOAD_ENTRY] = [
		ToolDialogueEditorButtonAction.LOAD_ENTRY_ACTION,
		ToolDialogueEditorButtonAction.CREATE_ENTRY_ACTION
	]
	
	stateActionsDict[ToolDialogueEditorMenuState.EDIT_ENTRY] = [
		ToolDialogueEditorButtonAction.CONFIGURE_ENTRY_ACTION,
		ToolDialogueEditorButtonAction.EDIT_ITEM_ACTION
	]
	
	load_menu_state()

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
			load_dialogue_item_editors()
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
		actionButtonsHFlow.remove_child.call_deferred(child)
		child.queue_free.call_deferred()
	
	# save
	if editingEntry != null or len(parentEntries) > 0:
		var saveButton: Button = SFX_BUTTON_SCENE.instantiate()
		saveButton.text = button_action_to_label(ToolDialogueEditorButtonAction.SAVE_ACTION)
		saveButton.pressed.connect(_action_button_pressed.bind(ToolDialogueEditorButtonAction.SAVE_ACTION))
		actionButtonsHFlow.add_child(saveButton)
	
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
		var button: SFXNinePatchButton = SFX_NINE_PATH_BUTTON_SCENE.instantiate()
		button.pressed.connect(_npc_button_pressed.bind(npc, null))
		npcButtons.add_child(button)
		button.size = npc.get_max_sprite_size() + Vector2i(8, 8)
		button.position = npc.position - 0.5 * button.size
	
	for interactable: Interactable in mapInteractables:
		var button: SFXNinePatchButton = SFX_NINE_PATH_BUTTON_SCENE.instantiate()
		button.pressed.connect(_npc_button_pressed.bind(null, interactable))
		npcButtons.add_child(button)
		button.size = interactable.get_max_sprite_size() + Vector2i(8, 8)
		button.position = interactable.position - 0.5 * button.size

func load_dialogue_item_editors() -> void:
	for child: Node in dialogueItemEditorsTabContainer.get_children():
		child.visible = false
		child.queue_free()
	
	for itemIdx: int in range(len(editingEntry.items)):
		var itemEditor: ToolDialogueItemEditor = DIALOGUE_ITEM_EDITOR.instantiate()
		itemEditor.dialogueItem = editingEntry.items[itemIdx]
		itemEditor.name = 'Item ' + String.num_int64(itemIdx + 1)
		itemEditor.preview_line_toggled.connect(_on_dialogue_item_editor_preview_line_toggled)
		dialogueItemEditorsTabContainer.add_child(itemEditor)
	dialogueItemEditorsTabContainer.visible = true

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
	textBox.update_speaker_sprite()

func save_dialogues() -> void:
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
		
		var filepath: String = await file_saved
		if editingInteractableDialogue != null:
			ResourceSaver.save(editingInteractableDialogue, filepath)
		elif editingEntry != null:
			ResourceSaver.save(editingEntry, dialogueSavePath)
		dialogueSavePath = filepath
	
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

func _action_button_pressed(action: ToolDialogueEditorButtonAction) -> void:
	if action != ToolDialogueEditorButtonAction.BACK_ACTION:
		menuStateStack.append(menuState)
	match action:
		ToolDialogueEditorButtonAction.BACK_ACTION:
			menuState = menuStateStack.pop_back()
		ToolDialogueEditorButtonAction.CREATE_ENTRY_ACTION:
			editingEntry = DialogueEntry.new()
			menuState = ToolDialogueEditorMenuState.CHOOSE_MAP
		ToolDialogueEditorButtonAction.LOAD_ENTRY_ACTION:
			menuState = ToolDialogueEditorMenuState.LOAD_ENTRY
		ToolDialogueEditorButtonAction.SAVE_ACTION:
			menuState = ToolDialogueEditorMenuState.SAVING_ENTRIES
			save_dialogues()
	load_menu_state()

func _npc_button_pressed(npc: NPCScript, interactable: Interactable) -> void:
	editingNpc = npc
	editingInteractable = interactable
	
	if interactable != null and dialogueSavePath == '':
		editingInteractableDialogue = InteractableDialogue.new()
		editingInteractableDialogue.dialogueEntry = editingEntry
	
	menuStateStack.append(menuState)
	menuState = ToolDialogueEditorMenuState.EDIT_ENTRY
	for child: Node in npcButtons.get_children():
		child.visible = false
		child.queue_free()
	load_menu_state()

func _on_file_dialog_file_selected(path: String) -> void:
	menuStateStack.append(menuState)
	match menuState:
		ToolDialogueEditorMenuState.LOAD_ENTRY:
			dialogueSavePath = path
			var resource: Resource = load(path)
			if resource is InteractableDialogue:
				editingInteractableDialogue = resource as InteractableDialogue
				editingEntry = editingInteractableDialogue.dialogueEntry
			elif resource is DialogueEntry:
				editingInteractableDialogue = null
				editingEntry = resource as DialogueEntry
			else:
				printerr("ERROR: Resource not recognized as a dialogue entry/interactable entry")
			menuState = ToolDialogueEditorMenuState.CHOOSE_MAP
		ToolDialogueEditorMenuState.CHOOSE_MAP:
			var mapInstance = load(path)
			editingMap = mapInstance.instantiate()
			mapRoot.add_child(editingMap)
			mapNpcs = get_tree().get_nodes_in_group('NPC')
			mapInteractables = get_tree().get_nodes_in_group('Interactable')
			menuState = ToolDialogueEditorMenuState.CHOOSE_NPC
		ToolDialogueEditorMenuState.SAVING_ENTRIES:
			file_saved.emit(path)
	fileDialog.visible = false
	fileDialog.queue_free()
	if menuState != ToolDialogueEditorMenuState.SAVING_ENTRIES:
		load_menu_state.call_deferred()
	else:
		menuStateStack.pop_back() # undo push at the beginning here

func _on_dialogue_item_editor_preview_line_toggled(dialogueItem: DialogueItem, lineIdx: int, text: String) -> void:
	load_text_box(dialogueItem)
	
	var speakerName: String = 'ERROR'
	if editingNpc != null:
		speakerName = editingNpc.displayName
	elif editingInteractable != null:
		speakerName = editingInteractableDialogue.speaker
	textBox.set_textbox_text(TextUtils.rich_text_substitute(text, Vector2i(32, 32)), dialogueItem.speakerOverride if dialogueItem.speakerOverride != '' else speakerName, len(dialogueItem.lines) - 1 == lineIdx)

func _on_interactable_speaker_text_changed(new_text: String) -> void:
	if editingInteractableDialogue != null:
		editingInteractableDialogue.speaker = new_text
