extends Control
class_name CodexMenu

signal back_pressed

@export var notSeenSprite: Texture2D = null

@onready var entryTitle: RichTextLabel = get_node('Panel/EntryTitle')
@onready var backButton: Button = get_node('Panel/ClipScrollContainerControl/ScrollContainer/VBoxContainer/BackButton')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ClipScrollContainerControl/ScrollContainer/VBoxContainer')
@onready var codexEntryPanel: CodexEntryPanel = get_node('Panel/CodexEntryPanel')

var selectedEntryStack: Array[CodexEntry] = []

var codexEntriesDir: String = 'res://gamedata/codex_entries/'
var buttonPrefab = preload('res://prefabs/ui/sfx_button.tscn')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func toggle_codex_menu(showing: bool):
	if showing:
		load_codex_menu()
		visible = true
	else:
		_on_back_button_pressed()

func load_codex_menu():
	initial_focus()
	
	for button in get_tree().get_nodes_in_group('CodexEntryButton'):
		button.queue_free()
	
	var lastEntry: CodexEntry = get_last_entry_with_children()
	if lastEntry == null:
		entryTitle.text = ''
		var files = DirAccess.get_files_at(codexEntriesDir)
		for filepath in files: # for all entry files inside the directory
			var entry: CodexEntry = load(codexEntriesDir + filepath) as CodexEntry
			if entry != null and (entry.storyRequirements == null or entry.storyRequirements.is_valid()):
				instantiate_button_for_entry(entry)
			else:
				printerr('Codex entry at ', filepath, ' was not loaded!')
	else:
		entryTitle.text = '[center]' + lastEntry.title + '[/center]'
		for entry in lastEntry.childrenEntries:
			if entry.storyRequirements == null or entry.storyRequirements.is_valid():
				instantiate_button_for_entry(entry)
	
	var entryButtons: Array[Node] = vboxContainer.get_children()
	var bottomEntryButton: Button = null
	if len(entryButtons) > 0:
		bottomEntryButton = entryButtons[len(entryButtons) - 1] as Button
	if bottomEntryButton != null:
		backButton.focus_neighbor_top = backButton.get_path_to(bottomEntryButton)
		bottomEntryButton.focus_neighbor_bottom = bottomEntryButton.get_path_to(backButton)
	else:
		backButton.focus_neighbor_bottom = backButton.get_path_to(backButton)

func initial_focus():
	backButton.grab_focus()

func instantiate_button_for_entry(entry: CodexEntry):
	if entry == null:
		return
	var button: SFXButton = buttonPrefab.instantiate()
	button.text = entry.title
	button.pressed.connect(_on_codex_button_pressed.bind(entry))
	button.add_to_group('CodexEntryButton')
	if not PlayerResources.playerInfo.has_seen_codex_entry(entry.id):
		button.icon = notSeenSprite
		button.expand_icon = true
	vboxContainer.add_child(button)

func focus_button_for_entry(entry: CodexEntry):
	for button in get_tree().get_nodes_in_group('CodexEntryButton'):
		if button.text == entry.title:
			button.grab_focus()
			return

func get_last_entry_with_children() -> CodexEntry:
	for idx in range(len(selectedEntryStack) - 1, -1, -1):
		if len(selectedEntryStack[idx].childrenEntries) > 0:
			return selectedEntryStack[idx]
	return null

func _on_codex_button_pressed(entry: CodexEntry):
	codexEntryPanel.codexEntry = entry
	codexEntryPanel.load_codex_entry_panel()
	if len(entry.childrenEntries) > 0:
		selectedEntryStack.append(entry)
		load_codex_menu()
	PlayerResources.playerInfo.set_codex_entry_seen(entry.id)

func _on_back_button_pressed():
	if len(selectedEntryStack) > 0:
		var entry = selectedEntryStack.pop_back()
		load_codex_menu()
		focus_button_for_entry(entry)
	else:
		back_pressed.emit()
		visible = false
