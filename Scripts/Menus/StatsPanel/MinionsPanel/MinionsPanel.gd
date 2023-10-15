extends Panel
class_name MinionsPanel

signal stats_clicked(combatant: Combatant)

@export var readOnly: bool = false

@onready var vboxContainer: VBoxContainer = get_node("ScrollContainer/VBoxContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_minions_panel():
	for panel in get_tree().get_nodes_in_group('MinionSlotPanel'):
		if "stats_clicked" in panel and panel.stats_clicked.is_connected(_on_stats_clicked):
			panel.stats_clicked.disconnect(_on_stats_clicked)
		panel.queue_free()
	
	var minionSlotPanel = load("res://Prefabs/UI/Stats/MinionSlotPanel.tscn")
	for minion in PlayerResources.minions.get_minion_list():
		var instantiatedPanel: MinionSlotPanel = minionSlotPanel.instantiate()
		instantiatedPanel.readOnly = readOnly
		instantiatedPanel.combatant = minion
		instantiatedPanel.stats_clicked.connect(_on_stats_clicked)
		vboxContainer.add_child(instantiatedPanel)

func _on_stats_clicked(combatant: Combatant):
	stats_clicked.emit(combatant)
