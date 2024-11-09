extends Control
class_name BattleRunesPanel

signal back_pressed

@export var combatantNode: CombatantNode
@export var allCombatantNodes: Array[CombatantNode]

@onready var panelTitle: RichTextLabel = get_node('Panel/PanelTitle')

@onready var hboxContainer: HBoxContainer = get_node('Panel/ScrollContainer/HBoxContainer')

@onready var boxContainerScroller: BoxContainerScroller = get_node('Panel/BoxContainerScroller')
@onready var backButton: Button = get_node('Panel/BackButton')

@onready var tooltipPanel: TooltipPanel = get_node('TooltipPanel')

const runeEffectDetailsPanelScene = preload("res://prefabs/ui/stats/rune_effect_details_panel.tscn")

var helpButtonPressed: Control = null

func load_battle_runes_panel() -> void:
	if combatantNode == null or combatantNode.combatant == null or len(allCombatantNodes) == 0:
		_on_back_button_pressed()
		return
	
	visible = true
	
	panelTitle.text = '[center]Runes Enchanted On ' + combatantNode.combatant.disp_name() + '[/center]'
	
	backButton.focus_neighbor_top = '.'
	
	for child: Node in hboxContainer.get_children():
		child.queue_free()
	
	for rune: Rune in combatantNode.combatant.runes:
		var instantiatedRuneDetailsPanel: RuneEffectDetailsPanel = runeEffectDetailsPanelScene.instantiate()
		instantiatedRuneDetailsPanel.rune = rune
		instantiatedRuneDetailsPanel.isSurgeEffect = false
		instantiatedRuneDetailsPanel.tooltipPanel = tooltipPanel
		
		var casterPosition: String = ''
		for cNode: CombatantNode in allCombatantNodes:
			if cNode.combatant == rune.caster:
				casterPosition = cNode.battlePosition
		instantiatedRuneDetailsPanel.casterPosition = casterPosition
		instantiatedRuneDetailsPanel.tooltip_panel_opened.connect(_rune_effect_tooltip_opened.bind(instantiatedRuneDetailsPanel))
		hboxContainer.add_child(instantiatedRuneDetailsPanel)
		instantiatedRuneDetailsPanel.load_rune_effect_details.call_deferred()
		instantiatedRuneDetailsPanel.loaded_panel.connect(update_rune_details_panel_focus.bind(instantiatedRuneDetailsPanel))
	_on_box_container_scroller_visibility_changed.call_deferred()

func update_rune_details_panel_focus(panel: RuneEffectDetailsPanel) -> void:
	
	var children: Array[Node] = hboxContainer.get_children()
	var childIdx: int = children.find(panel)
	var lastPanel: RuneEffectDetailsPanel = null
	if childIdx > 0:
		lastPanel = children[childIdx - 1] as RuneEffectDetailsPanel
		panel.runeHelpButton.focus_neighbor_left = panel.runeHelpButton.get_path_to(lastPanel.runeHelpButton)
		lastPanel.runeHelpButton.focus_neighbor_right = lastPanel.runeHelpButton.get_path_to(panel.runeHelpButton)
	
	var lastPanelWithStatusHelpBtn: RuneEffectDetailsPanel = null
	for idx: int in range(childIdx):
		var tempPanel: RuneEffectDetailsPanel = children[childIdx - 1] as RuneEffectDetailsPanel
		if tempPanel.statusEffectRow.visible:
			lastPanelWithStatusHelpBtn = tempPanel
		
	if lastPanelWithStatusHelpBtn != null and panel.statusEffectRow.visible:
		panel.statusHelpButton.focus_neighbor_left = panel.statusHelpButton.get_path_to(lastPanelWithStatusHelpBtn.statusHelpButton)
		lastPanelWithStatusHelpBtn.statusHelpButton.focus_neighbor_right = lastPanelWithStatusHelpBtn.statusHelpButton.get_path_to(panel.statusHelpButton)
	
	var bottomMostBtn: Button = panel.get_bottom_most_button()
	bottomMostBtn.focus_neighbor_bottom = bottomMostBtn.get_path_to(backButton)
	# the back button leads to the second panel (or first if none other will be present)
	if childIdx == 1 or len(children) == 1:
		backButton.focus_neighbor_top = backButton.get_path_to(bottomMostBtn)

func initial_focus() -> void:
	backButton.grab_focus()

func _rune_effect_tooltip_opened(panel: RuneEffectDetailsPanel) -> void:
	helpButtonPressed = panel.helpButtonPressed

func _on_box_container_scroller_visibility_changed() -> void:
	var children: Array[Node] = hboxContainer.get_children()
	var firstPanel: RuneEffectDetailsPanel = null if len(children) == 0 else children[0] as RuneEffectDetailsPanel
	var lastPanel: RuneEffectDetailsPanel = null if len(children) == 0 else children[len(children) - 1] as RuneEffectDetailsPanel
	
	if boxContainerScroller.visible:
		boxContainerScroller.connect_scroll_left_right_neighbor(backButton)
		boxContainerScroller.connect_scroll_right_left_neighbor(backButton)
		if firstPanel != null:
			boxContainerScroller.connect_scroll_left_top_neighbor(firstPanel.get_bottom_most_button())
		if lastPanel != null:
			boxContainerScroller.connect_scroll_right_top_neighbor(lastPanel.get_bottom_most_button())
	else:
		backButton.focus_neighbor_left = '.'
		backButton.focus_neighbor_right = '.'
		if firstPanel != null:
			var bottomMostBtn: Button = firstPanel.get_bottom_most_button()
			bottomMostBtn.focus_neighbor_bottom = bottomMostBtn.get_path_to(backButton)
		if lastPanel != null:
			var bottomMostBtn: Button = lastPanel.get_bottom_most_button()
			bottomMostBtn.focus_neighbor_bottom = bottomMostBtn.get_path_to(backButton)

func _on_back_button_pressed() -> void:
	visible = false
	back_pressed.emit()

func _on_tooltip_panel_ok_pressed() -> void:
	if helpButtonPressed != null:
		helpButtonPressed.grab_focus()
	else:
		initial_focus()
