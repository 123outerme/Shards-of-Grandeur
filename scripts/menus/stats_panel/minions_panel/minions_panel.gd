extends Panel
class_name MinionsPanel

signal stats_clicked(combatant: Combatant)

@export var readOnly: bool = false
@export var minion: Combatant = null

@onready var playerView: Control = get_node("PlayerView")
@onready var vboxContainer: VBoxContainer = get_node("PlayerView/ScrollContainer/VBoxContainer")

@onready var minionView: Control = get_node("MinionView")
@onready var minionName: RichTextLabel = get_node("MinionView/MinionName")
@onready var nameInput: LineEdit = get_node("MinionView/NameInput")
@onready var confirmName: Button = get_node("MinionView/NameFormControls/ConfirmButton")
@onready var cancelName: Button = get_node("MinionView/NameFormControls/CancelButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_minions_panel():
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if "stats_clicked" in panel and panel.stats_clicked.is_connected(_on_stats_clicked):
			panel.stats_clicked.disconnect(_on_stats_clicked)
		panel.queue_free()
	
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
		cancelName.disabled = true
	else:
		var minionSlotPanel = load("res://prefabs/ui/stats/minion_slot_panel.tscn")
		for listed_minion in PlayerResources.minions.get_minion_list():
			var instantiatedPanel: MinionSlotPanel = minionSlotPanel.instantiate()
			instantiatedPanel.readOnly = readOnly
			instantiatedPanel.combatant = listed_minion
			instantiatedPanel.stats_clicked.connect(_on_stats_clicked)
			vboxContainer.add_child(instantiatedPanel)
	
	minionView.visible = minion != null
	playerView.visible = minion == null

func get_stats_button_for(combatant: Combatant) -> Button:
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if panel.combatant == combatant:
			return panel.statsButton
	return null

func _on_stats_clicked(combatant: Combatant):
	stats_clicked.emit(combatant)

func _on_name_input_text_changed(new_text: String):
	confirmName.disabled = false
	cancelName.disabled = false

func _on_name_input_text_submitted(new_text: String):
	minion.nickname = new_text
	nameInput.release_focus()
	confirmName.disabled = true
	cancelName.disabled = true

func _on_confirm_button_pressed():
	minion.nickname = nameInput.text
	confirmName.disabled = true
	cancelName.disabled = true

func _on_cancel_button_pressed():
	nameInput.text = minion.nickname
	confirmName.disabled = true
	cancelName.disabled = true
