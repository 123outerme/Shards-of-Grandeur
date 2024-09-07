extends Panel
class_name MinionsPanel

signal stats_clicked(combatant: Combatant)
signal minion_auto_alloc_changed(combatant: Combatant)
signal changed_minion_hovered(combatant: Combatant)
signal panel_loaded
signal minion_renamed

@export var readOnly: bool = false
@export var minion: Combatant = null
@export var levelUp: bool = false

var loaded: bool = false
var editingName: bool = false
var firstMinionPanel: MinionSlotPanel = null
var reordering: bool = false
var reorderingMinion: Combatant = null

@onready var playerView: Control = get_node("PlayerView")
@onready var reorderButton: Button = get_node('PlayerView/ReorderButton')
@onready var vboxContainer: VBoxContainer = get_node("PlayerView/ScrollContainer/VBoxContainer")

@onready var minionView: Control = get_node("MinionView")
@onready var minionName: RichTextLabel = get_node("MinionView/MinionName")
@onready var nameInput: LineEdit = get_node("MinionView/NameInput")
@onready var editName: Button = get_node("MinionView/NameFormControls/EditButton")
@onready var confirmName: Button = get_node("MinionView/NameFormControls/ConfirmButton")
@onready var cancelName: Button = get_node("MinionView/NameFormControls/CancelButton")
@onready var friendshipBar: ProgressBar = get_node("MinionView/FriendshipBar")
@onready var autoAllocCheckButton: CheckButton = get_node('MinionView/AutoAllocateCheckButton')
@onready var virtualKeyboard: VirtualKeyboard = get_node('MinionView/VirtualKeyboard')

# Called when the node enters the scene tree for the first time.
func _ready():
	SettingsHandler.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()

func _exit_tree():
	firstMinionPanel = null

func _unhandled_input(event):
	if event.is_action_pressed("game_decline") and nameInput.has_focus():
		get_viewport().set_input_as_handled()
		var focusCancel: bool = true
		
		# if Shift key is pressed:
		# this is involved in text input without being a character that the LineEdit consumes, so we need to handle it here
		if event is InputEventKey:
			if event.keycode == KEY_SHIFT:
				focusCancel = false
			
		if focusCancel:
			cancelName.grab_focus()

func load_minions_panel():
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if "stats_clicked" in panel and panel.stats_clicked.is_connected(_on_stats_clicked):
			panel.stats_clicked.disconnect(_on_stats_clicked)
		panel.queue_free()
	
	firstMinionPanel = null
	if minion != null:
		nameInput.placeholder_text = minion.stats.displayName
		minionName.text = '[center]'
		if minion.nickname != '':
			minionName.text += minion.nickname + '\n(' + minion.stats.displayName + ')'
			nameInput.text = minion.disp_name()
		else:
			nameInput.text = ''
			minionName.text += minion.stats.displayName
		minionName.text += ':[/center]'
		confirmName.disabled = true
		editName.disabled = readOnly
		cancelName.disabled = false
		friendshipBar.max_value = minion.maxFriendship
		friendshipBar.value = minion.friendship
		autoAllocCheckButton.button_pressed = minion.should_auto_alloc_stat_pts()
		reordering = false
		reorderingMinion = null
	else:
		if reordering:
			reorderButton.text = 'Cancel'
		else:
			reorderButton.text = 'Reorder'
		var minionSlotPanel = load("res://prefabs/ui/stats/minion_slot_panel.tscn")
		for listed_minion in PlayerResources.minions.get_minion_list():
			var instantiatedPanel: MinionSlotPanel = minionSlotPanel.instantiate()
			if firstMinionPanel == null:
				firstMinionPanel = instantiatedPanel
				firstMinionPanel.panel_ready.connect(set_loaded)
			instantiatedPanel.readOnly = readOnly
			instantiatedPanel.combatant = listed_minion
			instantiatedPanel.levelUp = levelUp
			instantiatedPanel.showReorderButton = reordering
			instantiatedPanel.reorderButtonIsTarget = reorderingMinion != null and reorderingMinion != listed_minion
			instantiatedPanel.reorderButtonIsCancel = reorderingMinion != null and reorderingMinion == listed_minion
			instantiatedPanel.stats_clicked.connect(_on_stats_clicked)
			instantiatedPanel.reorder_clicked.connect(_on_reorder_clicked)
			instantiatedPanel.changed_minion_hovered.connect(_changed_minion_hovered)
			
			vboxContainer.add_child(instantiatedPanel)
	
	minionView.visible = minion != null
	playerView.visible = minion == null

func set_loaded():
	loaded = true
	panel_loaded.emit()

func connect_to_top_control(control: Control):
	if not loaded:
		await panel_loaded
	if minion == null:
		reorderButton.focus_neighbor_top = reorderButton.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(reorderButton)
	else:
		editName.focus_neighbor_top = editName.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(editName)

func connect_to_bottom_control(control: Control):
	if not loaded:
		await panel_loaded
	if minion == null:
		var panels: Array[MinionSlotPanel] = get_tree().get_nodes_in_group('MinionSlotPanel') as Array[MinionSlotPanel]
		var minionPanelControl: Control = null
		if len(panels) > 0:
			var bottomPanel: MinionSlotPanel = panels[len(panels) - 1]
			minionPanelControl = bottomPanel.statsButton
		else:
			minionPanelControl = reorderButton
		minionPanelControl.focus_neighbor_bottom = minionPanelControl.get_path_to(control)
		control.focus_neighbor_top = control.get_path_to(minionPanelControl)
	else:
		autoAllocCheckButton.focus_neighbor_bottom = autoAllocCheckButton.get_path_to(control)
		control.focus_neighbor_top = control.get_path_to(autoAllocCheckButton)

func get_stats_button_for(combatant: Combatant) -> Button:
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if panel.combatant == combatant:
			return panel.statsButton
	return null

func get_panel_for(combatant: Combatant) -> MinionSlotPanel:
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if panel.combatant == combatant:
			return panel
	return null

func update_panels_reorder_buttons():
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		var minionSlotPanel: MinionSlotPanel = panel as MinionSlotPanel
		minionSlotPanel.showReorderButton = reordering
		minionSlotPanel.reorderButtonIsTarget = reorderingMinion != null and reorderingMinion != minionSlotPanel.combatant
		minionSlotPanel.reorderButtonIsCancel = reorderingMinion != null and reorderingMinion == minionSlotPanel.combatant
		minionSlotPanel.load_minion_slot_panel()

func reset_reorder_state(reload: bool = false):
	if reordering:
		reordering = false
		reorderingMinion = null
		if reload:
			load_minions_panel()

func _on_stats_clicked(combatant: Combatant):
	stats_clicked.emit(combatant)

func _on_reorder_clicked(combatant: Combatant):
	if reorderingMinion == null:
		reorderingMinion = combatant
	else:
		if reorderingMinion != combatant:
			var idx = PlayerResources.minions.reorder_minion(reorderingMinion, combatant)
			if idx != -1:
				var panel = get_panel_for(reorderingMinion)
				vboxContainer.move_child(panel, idx)
		reorderingMinion = null
	update_panels_reorder_buttons()

func _on_name_input_text_changed(new_text: String):
	confirmName.disabled = false

func _on_name_input_text_submitted(new_text: String):
	confirmName.grab_focus()

func _on_confirm_button_pressed():
	minion.nickname = nameInput.text
	end_edit_name()
	minion_renamed.emit()
	if virtualKeyboard.visible:
		# like calling hide_keyboard(), but without emitting an event that causes the keyboard to cancel the edit again
		virtualKeyboard.visible = false
		virtualKeyboard.reset_keyboard_state()

func _on_cancel_button_pressed():
	nameInput.text = minion.nickname
	if virtualKeyboard.visible:
		# like calling hide_keyboard(), but without emitting an event that causes the keyboard to cancel the edit again
		virtualKeyboard.visible = false
		virtualKeyboard.reset_keyboard_state()
	end_edit_name()

func end_edit_name(refocus: bool = true):
	confirmName.visible = false
	confirmName.disabled = true
	cancelName.visible = false
	editName.disabled = false
	nameInput.clear_button_enabled = false
	nameInput.focus_mode = Control.FOCUS_NONE
	if refocus:
		editName.grab_focus()

func _on_edit_button_pressed():
	editingName = true
	confirmName.visible = true
	confirmName.disabled = true
	cancelName.visible = true
	editName.disabled = true
	nameInput.clear_button_enabled = true
	nameInput.focus_mode = Control.FOCUS_ALL
	nameInput.grab_focus()

func _on_name_input_gui_input(event):
	# if ui cancel (Escape) has been pressed to unfocus the input
	if event.is_action_pressed('ui_cancel') and editingName:
		_on_cancel_button_pressed()

func _on_auto_allocate_check_button_toggled(toggled_on: bool) -> void:
	if minion != null:
		minion.minionStatAllocMode = Combatant.MinionStatAllocationMode.AUTOMATIC if toggled_on else Combatant.MinionStatAllocationMode.MANUAL
		minion_auto_alloc_changed.emit(minion)

func _on_virtual_keyboard_backspace_pressed():
	if virtualKeyboard.visible:
		nameInput.text = nameInput.text.substr(0, len(nameInput.text) - 1)
		_on_name_input_text_changed(nameInput.text)

func _on_virtual_keyboard_enter_pressed():
	if virtualKeyboard.visible:
		confirmName.grab_focus()

func _on_virtual_keyboard_key_pressed(character):
	if virtualKeyboard.visible:
		nameInput.text += character
		_on_name_input_text_changed(nameInput.text)

func _on_virtual_keyboard_keyboard_hidden():
	_on_cancel_button_pressed()

func _on_reorder_button_pressed():
	reordering = !reordering
	reorderingMinion = null
	load_minions_panel()

func _on_settings_changed():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	nameInput.virtual_keyboard_enabled = not SettingsHandler.gameSettings.useVirtualKeyboard
	if not virtualKeyboard.enabled:
		virtualKeyboard.hide_keyboard()

func _changed_minion_hovered(combatant: Combatant):
	changed_minion_hovered.emit(combatant)
