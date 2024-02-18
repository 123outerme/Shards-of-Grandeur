extends Panel
class_name MinionsPanel

signal stats_clicked(combatant: Combatant)
signal panel_loaded

@export var readOnly: bool = false
@export var minion: Combatant = null

var loaded: bool = false
var editingName: bool = false
var firstMinionPanel: MinionSlotPanel = null

@onready var playerView: Control = get_node("PlayerView")
@onready var vboxContainer: VBoxContainer = get_node("PlayerView/ScrollContainer/VBoxContainer")

@onready var minionView: Control = get_node("MinionView")
@onready var minionName: RichTextLabel = get_node("MinionView/MinionName")
@onready var nameInput: LineEdit = get_node("MinionView/NameInput")
@onready var editName: Button = get_node("MinionView/NameFormControls/EditButton")
@onready var confirmName: Button = get_node("MinionView/NameFormControls/ConfirmButton")
@onready var cancelName: Button = get_node("MinionView/NameFormControls/CancelButton")
@onready var friendshipBar: ProgressBar = get_node("MinionView/FriendshipBar")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _exit_tree():
	firstMinionPanel = null

func _unhandled_input(event):
	if event.is_action_pressed("game_pause") and nameInput.has_focus():
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
	else:
		var minionSlotPanel = load("res://prefabs/ui/stats/minion_slot_panel.tscn")
		for listed_minion in PlayerResources.minions.get_minion_list():
			var instantiatedPanel: MinionSlotPanel = minionSlotPanel.instantiate()
			if firstMinionPanel == null:
				firstMinionPanel = instantiatedPanel
				firstMinionPanel.panel_ready.connect(set_loaded)
			instantiatedPanel.readOnly = readOnly
			instantiatedPanel.combatant = listed_minion
			instantiatedPanel.stats_clicked.connect(_on_stats_clicked)
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
		firstMinionPanel.statsButton.focus_neighbor_top = firstMinionPanel.statsButton.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(firstMinionPanel.statsButton)
	else:
		editName.focus_neighbor_top = editName.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(editName)

func get_stats_button_for(combatant: Combatant) -> Button:
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if panel.combatant == combatant:
			return panel.statsButton
	return null

func _on_stats_clicked(combatant: Combatant):
	stats_clicked.emit(combatant)

func _on_name_input_text_changed(new_text: String):
	confirmName.disabled = false

func _on_name_input_text_submitted(new_text: String):
	confirmName.grab_focus()

func _on_confirm_button_pressed():
	minion.nickname = nameInput.text
	end_edit_name()

func _on_cancel_button_pressed():
	nameInput.text = minion.nickname
	end_edit_name()

func end_edit_name():
	confirmName.visible = false
	confirmName.disabled = true
	cancelName.visible = false
	editName.visible = true
	nameInput.clear_button_enabled = false
	nameInput.focus_mode = Control.FOCUS_NONE
	editName.grab_focus()

func _on_edit_button_pressed():
	editingName = true
	confirmName.visible = true
	confirmName.disabled = true
	cancelName.visible = true
	editName.visible = false
	nameInput.clear_button_enabled = true
	nameInput.focus_mode = Control.FOCUS_ALL
	nameInput.grab_focus()

func _on_name_input_gui_input(event):
	# if ui cancel (Escape) has been pressed to unfocus the input
	if event.is_action_pressed('ui_cancel') and editingName:
		_on_cancel_button_pressed()
