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

var codexEntriesMap: Dictionary = {}
var entriesLoaded: bool = false

var buttonPrefab = preload('res://prefabs/ui/sfx_button.tscn')

var lastFocusedButton: Button = null

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_gui_focus_changed)

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func toggle_codex_menu(showing: bool):
	if showing:
		selectedEntryStack = [initialEntry]
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
	
	if not entriesLoaded:
		load_codex()
	
	var lastEntry: CodexEntry = get_last_entry()
	if lastEntry != null and lastEntry != initialEntry:
		entryTitle.text = '[center]' + lastEntry.title + '[/center]'
	else:
		entryTitle.text = ''
		
	var childrenEntries: Array[CodexEntry] = []
	var selectedPath: String = get_codex_path_for_stack(selectedEntryStack)
	if codexEntriesMap.has(selectedPath):
		childrenEntries = codexEntriesMap[selectedPath]
	for entry in childrenEntries:
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

func load_codex() -> void:
	load_codex_branch([initialEntry])
	entriesLoaded = true

func load_codex_branch(stack: Array[CodexEntry]) -> void:
	if len(stack) == 0:
		return
	
	var childrenEntries: Array[CodexEntry] = load_children_entries_for_entry(stack)
	childrenEntries.sort_custom(CodexEntry._sort_entries)
	codexEntriesMap[get_codex_path_for_stack(stack)] = childrenEntries
	for entry: CodexEntry in childrenEntries:
		var childStack: Array[CodexEntry] = []
		childStack.append_array(stack)
		childStack.append(entry)
		# Depth-first load codex branch here
		load_codex_branch(childStack)

## returns -1 if entryStack is empty: otherwise returns ResourceLoader/DirAccess error codes
func load_children_entries_for_entry(entryStack: Array[CodexEntry]) -> Array[CodexEntry]:
	if len(entryStack) == 0:
		return []
	
	var path: String = entryStack[0].resource_path.get_base_dir() + '/'
	for entry: CodexEntry in entryStack:
		path += entry.id + '/'
	
	var codexEntries: Array[CodexEntry] = []
	if DirAccess.dir_exists_absolute(path):
		var files: PackedStringArray = DirAccess.get_files_at(path)
		if len(files) > 0:
			for file in files:
				var codexEntry: CodexEntry = ResourceLoader.load(path + file) as CodexEntry
				if codexEntry != null:
					codexEntries.append(codexEntry)
				else:
					printerr('Codex entry at ', path, file, ' loaded as null.')
	
	return codexEntries

func get_codex_path_for_stack(codexEntryStack: Array[CodexEntry]) -> String:
	var path: String = '/'
	for entry: CodexEntry in codexEntryStack:
		path += entry.id + '/'
	return path

func initial_focus():
	backButton.grab_focus()

func instantiate_button_for_entry(entry: CodexEntry):
	if entry == null:
		return
	var button: SFXButton = buttonPrefab.instantiate()
	button.text = entry.title
	button.pressed.connect(_on_codex_button_pressed.bind(entry, button))
	button.add_to_group('CodexEntryButton')
	var hasNotSeen = has_not_seen_indicator(entry, selectedEntryStack)
	if hasNotSeen:
		button.icon = notSeenSprite
		button.expand_icon = true
	vboxContainer.add_child(button)
	button.custom_minimum_size.y = 40 # 40px height minimum
	button.focus_neighbor_left = '.'
	button.focus_neighbor_right = button.get_path_to(codexEntryPanel.entryDescription)

func focus_button_for_entry(entry: CodexEntry):
	for button in get_tree().get_nodes_in_group('CodexEntryButton'):
		if button.text == entry.title:
			button.grab_focus()
			return

func get_last_entry() -> CodexEntry:
	if len(selectedEntryStack) >= 1:
		return selectedEntryStack[len(selectedEntryStack) - 1]
	return null

func has_not_seen_indicator(entry: CodexEntry, codexEntryStack: Array[CodexEntry]) -> bool:
	if not PlayerResources.playerInfo.has_seen_codex_entry(entry.id):
		return true
	
	var childStack: Array[CodexEntry] = []
	childStack.append_array(codexEntryStack)
	childStack.append(entry)
	var path: String = get_codex_path_for_stack(childStack)
	if codexEntriesMap.has(path):
		var children: Array[CodexEntry] = codexEntriesMap[path]
		if children != null:
			for child in children:
				if not child.is_valid():
					continue
				if has_not_seen_indicator(child, childStack):
					return true
	
	return false

func _on_codex_button_pressed(entry: CodexEntry, button: Button):
	codexEntryPanel.codexEntry = entry
	codexEntryPanel.load_codex_entry_panel()
	var stack: Array[CodexEntry] = []
	stack.append_array(selectedEntryStack)
	stack.append(entry)
	var path: String = get_codex_path_for_stack(stack)
	if codexEntriesMap.has(path):
		var children: Array[CodexEntry] = codexEntriesMap[path]
		if children != null:
			var hasValidChildren = false
			for child in children:
				if child.is_valid():
					hasValidChildren = true
					break
			if hasValidChildren:
				selectedEntryStack.append(entry)
				load_codex_menu()
	PlayerResources.playerInfo.set_codex_entry_seen(entry.id)
	if not has_not_seen_indicator(entry, selectedEntryStack):
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

func _gui_focus_changed(control: Control) -> void:
	if is_visible_in_tree():
		if control is Button and control.is_in_group('CodexEntryButton'):
			lastFocusedButton = control as Button

func _on_codex_entry_panel_entry_desc_focused() -> void:
	codexEntryPanel.entryDescription.focus_neighbor_left = codexEntryPanel.entryDescription.get_path_to(lastFocusedButton)
