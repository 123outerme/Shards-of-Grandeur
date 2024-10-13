extends Control
class_name SummonMinionPanel

signal minion_summoned(minion, shardSlot)
signal show_stats_for_minion(minion: Combatant)
signal back_pressed

var summonMinionListPanel = preload('res://prefabs/battle/summon_minion_list_panel.tscn')
var statsShowMinion: Combatant = null

@onready var vboxContainer: VBoxContainer = get_node("Panel/Panel/ScrollContainer/VBoxContainer")
@onready var scrollContainer: ScrollBetterFollow = get_node('Panel/Panel/ScrollContainer')
@onready var backButton: Button = get_node("Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func load_summon_minion_panel(initialLoad: bool = true):
	statsShowMinion = null
	var focused: bool = false
	
	for panel in get_tree().get_nodes_in_group('SummonMinionListPanel'):
		panel.queue_free()
	
	for minion in PlayerResources.minions.get_minion_list():
		var shardSlot: InventorySlot = PlayerResources.inventory.get_shard_slot_for_minion(minion.save_name())
		if minion.friendship >= minion.maxFriendship or shardSlot != null:
			var panelInstance = summonMinionListPanel.instantiate()
			panelInstance.minion = minion
			panelInstance.shardItemSlot = shardSlot
			panelInstance.parentPanel = self
			vboxContainer.add_child(panelInstance)
			if not focused:
				panelInstance.call_deferred('focus_summon_button')
				focused = true

	if not focused:
		initial_focus()
	
	if initialLoad:
		
		scrollContainer.set_deferred('scroll_vertical', 0)
	
	visible = true

func summon_minion(minion: Combatant, shardSlot: InventorySlot):
	minion_summoned.emit(minion, shardSlot)
	visible = false
	statsShowMinion = null

func initial_focus():
	if statsShowMinion != null:
		for panel: SummonMinionListPanel in get_tree().get_nodes_in_group('SummonMinionListPanel'):
			if panel.minion == statsShowMinion:
				panel.focus_stats_button()
				statsShowMinion = null
				return
	else:
		backButton.grab_focus()

func show_minion_stats(minion: Combatant):
	statsShowMinion = minion
	show_stats_for_minion.emit(minion)

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()
	statsShowMinion = null
