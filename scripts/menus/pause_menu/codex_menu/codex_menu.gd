extends Control
class_name CodexMenu

signal back_pressed

@export var notSeenSprite: Texture2D = null
@export var initialEntry: CodexEntry = null

@onready var entryTitle: RichTextLabel = get_node('Panel/EntryTitle')
@onready var backButton: Button = get_node('Panel/ClipScrollContainerControl/ScrollContainer/VBoxContainer/BackButton')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ClipScrollContainerControl/ScrollContainer/VBoxContainer')
@onready var codexEntryPanel: CodexEntryPanel = get_node('Panel/CodexEntryPanel')

var selectedEntryStack: Array[CodexEntry] = []

var buttonPrefab = preload('res://prefabs/ui/sfx_button.tscn')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func toggle_codex_menu(showing: bool):
	if showing:
		selectedEntryStack.append(initialEntry)
		codexEntryPanel.codexEntry = initialEntry
		codexEntryPanel.load_codex_entry_panel()
		load_codex_menu()
		visible = true
	else:
		_on_back_button_pressed()

func load_codex_menu():
	initial_focus()
	
	for button in get_tree().get_nodes_in_group('CodexEntryButton'):
		button.queue_free()
	
	var lastEntry: CodexEntry = get_last_entry_with_children()
	if lastEntry != initialEntry:
		entryTitle.text = '[center]' + lastEntry.title + '[/center]'
	else:
		entryTitle.text = ''
	for entry in lastEntry.childrenEntries:
		if entry.is_valid():
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
	button.pressed.connect(_on_codex_button_pressed.bind(entry, button))
	button.add_to_group('CodexEntryButton')
	var hasNotSeen = has_not_seen_indicator(entry)
	if hasNotSeen:
		button.icon = notSeenSprite
		button.expand_icon = true
	vboxContainer.add_child(button)
	button.focus_neighbor_right = '.'

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

func has_not_seen_indicator(entry: CodexEntry) -> bool:
	if not PlayerResources.playerInfo.has_seen_codex_entry(entry.id):
		return true
	
	for child in entry.childrenEntries:
		if not child.is_valid():
			continue
		if has_not_seen_indicator(child):
			return true
	
	return false

func _on_codex_button_pressed(entry: CodexEntry, button: Button):
	codexEntryPanel.codexEntry = entry
	codexEntryPanel.load_codex_entry_panel()
	if len(entry.childrenEntries) > 0:
		var hasValidChildren = false
		for child in entry.childrenEntries:
			if child.is_valid():
				hasValidChildren = true
				break
		if hasValidChildren:
			selectedEntryStack.append(entry)
			load_codex_menu()
	PlayerResources.playerInfo.set_codex_entry_seen(entry.id)
	if not has_not_seen_indicator(entry):
		button.icon = null

func _on_back_button_pressed():
	var entry: CodexEntry = null
	if len(selectedEntryStack) > 0:
		entry = selectedEntryStack.pop_back()
	if len(selectedEntryStack) == 0:
		back_pressed.emit()
		visible = false
	else:
		load_codex_menu()
		focus_button_for_entry(entry)
