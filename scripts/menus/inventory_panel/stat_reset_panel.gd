extends Control
class_name StatResetPanel

signal stats_button_pressed(combatant: Combatant)
signal close_stat_reset_panel(combatant: Combatant)

var lastCombatant: Combatant = null
var playerPanel: StatResetCombatantPanel = null
var bottomCombatantPanel: StatResetCombatantPanel = null

var statResetCombatantPanelScene: PackedScene = load('res://prefabs/ui/inventory/stat_reset_combatant_panel.tscn')

@onready var scrollContainer: ScrollBetterFollow = get_node('Panel/ScrollContainer')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollContainer/VBoxContainer')
@onready var backButton: Button = get_node('Panel/BackButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func load_stat_reset_panel(initial: bool = true):
	visible = true
	
	if initial:
		for panel in get_tree().get_nodes_in_group('StatResetCombatantPanel'):
			panel.combatant = null
			panel.queue_free()
		
		playerPanel = statResetCombatantPanelScene.instantiate()
		playerPanel.combatant = PlayerResources.playerInfo.combatant
		playerPanel.parentPanel = self
		vboxContainer.add_child(playerPanel)
		playerPanel.call_deferred('initial_focus')
		bottomCombatantPanel = playerPanel
	
		for minion in PlayerResources.minions.get_minion_list():
			var panel: StatResetCombatantPanel = statResetCombatantPanelScene.instantiate()
			panel.combatant = minion
			panel.parentPanel = self
			vboxContainer.add_child(panel)
			bottomCombatantPanel = panel
		
		bottomCombatantPanel.call_deferred('connect_to_reset_button', backButton, true)
		scrollContainer.set_deferred('scroll_vertical', 0)
	else:
		for panel: StatResetCombatantPanel in get_tree().get_nodes_in_group('StatResetCombatantPanel'):
			panel.load_stat_reset_combatant_panel()
	
	playerPanel.call_deferred('connect_to_reset_button', backButton, false)

func restore_focus(button: String = ''):
	if lastCombatant == null:
		playerPanel.call_deferred('initial_focus')
	else:
		for panel: StatResetCombatantPanel in get_tree().get_nodes_in_group('StatResetCombatantPanel'):
			if panel.combatant == lastCombatant:
				if button == 'stats':
					panel.call_deferred('focus_stats_button')
				else:
					panel.call_deferred('initial_focus')
				break

func stats_pressed(combatant: Combatant):
	lastCombatant = combatant
	stats_button_pressed.emit(combatant)
	
func reset_pressed(combatant: Combatant):
	_on_back_button_pressed(combatant)

func _on_back_button_pressed(combatant: Combatant = null):
	close_stat_reset_panel.emit(combatant)
