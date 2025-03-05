extends Panel
class_name MoveEffectDetailsPanel

signal tooltip_panel_opened

@export var moveEffect: MoveEffect = null
@export var isSurgeEffect: bool = false
@export var tooltipPanel: TooltipPanel
@export var bailoutFocusControl: Control
@export var scrollerBottomFocusNeighbor: Control

@onready var detailsTitleLabel: RichTextLabel = get_node('ScrollContainer/VBoxContainer/Panel/DetailsTitle')

@onready var moveEffPanel: Panel = get_node('ScrollContainer/VBoxContainer/Panel')

@onready var moveTargets: RichTextLabel = get_node("ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/MoveTargets")
@onready var movePower: RichTextLabel = get_node("ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/MovePower")
@onready var moveRole: RichTextLabel = get_node("ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/MoveRole")
@onready var keywordsLabel: RichTextLabel = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/Keywords')

@onready var userBoostsRow: HBoxContainer = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/UserBoostsRow')
@onready var userStatChanges: RichTextLabel = get_node("ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/UserBoostsRow/UserStatChanges")

@onready var targetBoostsRow: HBoxContainer = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/TargetBoostsRow')
@onready var targetStatChanges: RichTextLabel = get_node("ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/TargetBoostsRow/TargetStatChanges")

@onready var statusEffectRow: HBoxContainer = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/StatusEffectRow')
@onready var statusLabel: RichTextLabel = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/StatusEffectRow/StatusLabel')
@onready var moveStatusEffect: RichTextLabel = get_node("ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/StatusEffectRow/MoveStatusEffect")
@onready var moveStatusIcon: Sprite2D = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/StatusEffectRow/StatusEffectIconGroup/StatusEffectIconControl/StatusEffectIcon')
@onready var statusHelpButton: Button = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/StatusEffectRow/StatusHelpSection/StatusHelpButton')
# the statusHelpButton is fetched to to connect focus to the back button in the parent panel

@onready var runeRow: HBoxContainer = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/RuneRow')
@onready var runeDetailsLabel: RichTextLabel = get_node('ScrollContainer/VBoxContainer/Panel/BaseEffectPanel/VBoxContainer/RuneRow/RuneDetails')

@onready var surgePanel: Panel = get_node('ScrollContainer/VBoxContainer/Panel/SurgePanel')
@onready var surgeVBox: VBoxContainer = get_node('ScrollContainer/VBoxContainer/Panel/SurgePanel/VBoxContainer')

@onready var runeEffectDetailsPanel: RuneEffectDetailsPanel = get_node('ScrollContainer/VBoxContainer/RuneEffectDetailsPanel')

@onready var boxContainerScroller: BoxContainerScroller = get_node('BoxContainerScroller')

const SCROLLING_WIDTH: int = 588
const NO_SCROLLING_WIDTH: int = 540

const CHARGE_HEIGHT: int = 317
const SURGE_HEIGHT: int = 566

var surgeChangesRowScene: PackedScene = preload('res://prefabs/ui/stats/surge_changes_row.tscn')

var helpButtonPressed: Button = null

func load_move_effect_details_panel():
	if moveEffect == null:
		visible = false
		return
	
	boxContainerScroller.bailoutFocusControl = bailoutFocusControl
	boxContainerScroller.connect_scroll_down_bottom_neighbor(scrollerBottomFocusNeighbor)
	
	for node in get_tree().get_nodes_in_group('SurgeChangesRow'):
		node.queue_free()
	
	if Combatant.are_surge_moves_allowed():
		var titleText: String = '[center]' + ('Surge Effect' if isSurgeEffect else 'Charge Effect') + ' ('
		if moveEffect.orbChange > 0:
			titleText += '+'
		titleText += String.num_int64(moveEffect.orbChange) + ' $orb'
		if moveEffect.orbChange < 0:
			titleText += ' Min.'
		titleText += ')[/center]'
		detailsTitleLabel.text = TextUtils.rich_text_substitute(titleText, Vector2i(32, 32))
		visible = true
	else:
		if isSurgeEffect:
			visible = false
			return
		else:
			detailsTitleLabel.text = '[center]Move Effect[/center]'
	
	if moveEffect.power >= 0:
		movePower.text = String.num_int64(moveEffect.power) + ' Power'
	else:
		movePower.text = String.num_int64(moveEffect.power * -1) + ' Heal Power'
	
	if moveEffect.lifesteal > 0 and moveEffect.power != 0:
		movePower.text += ' (' + String.num_int64(roundi(max(0, moveEffect.lifesteal) * 100)) + '% Lifesteal)'
	
	moveTargets.text = '[center]Targets ' + BattleCommand.targets_to_string(moveEffect.targets) + '[/center]'
	moveRole.text = '[right]' + MoveEffect.role_to_string(moveEffect.role) + '[/right]'
	
	if len(moveEffect.keywords) > 0:
		keywordsLabel.visible = true
		var keywordNoun: String = 'Keyword'
		if len(moveEffect.keywords) != 1:
			keywordNoun += 's'
		keywordsLabel.text = '[center]' + keywordNoun + ': ' + TextUtils.string_arr_to_string(moveEffect.keywords, ', ', ', ', ', ') + '[/center]'
	else:
		keywordsLabel.visible = false

	if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
		var multipliers = moveEffect.selfStatChanges.get_multipliers_text()
		userStatChanges.text = '[center]' + StatMultiplierText.multiplier_text_list_to_string(multipliers) + '\n [/center]'
		userBoostsRow.visible = true
	else:
		userBoostsRow.visible = false
		
	if moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes():
		var multipliers = moveEffect.targetStatChanges.get_multipliers_text()
		targetStatChanges.text = '[center]' + StatMultiplierText.multiplier_text_list_to_string(multipliers) + '\n [/center]'
		targetBoostsRow.visible = true
	else:
		targetBoostsRow.visible = false
		
	if moveEffect.statusEffect != null:
		if moveEffect.selfGetsStatus:
			statusLabel.text = 'Status (Self):'
		else:
			statusLabel.text = 'Status (Target):'
		moveStatusEffect.text = '[center]'
		if moveEffect.statusEffect.type != StatusEffect.Type.NONE:
			moveStatusEffect.text += StatusEffect.potency_to_string(moveEffect.statusEffect.potency) \
					+ ' ' + moveEffect.statusEffect.get_status_type_string()
		else:
			moveStatusEffect.text += 'Cures ' + StatusEffect.potency_to_string(moveEffect.statusEffect.potency) + ' Statuses'
		var accuracyString: String = String.num_int64(roundi(moveEffect.statusChance * 100)) + ' Chance'
		if moveEffect.statusChance >= 1:
			accuracyString = 'Guaranteed'
		moveStatusEffect.text += ' (' + accuracyString
		if moveEffect.statusEffect.overwritesOtherStatuses:
			moveStatusEffect.text += ', Replaces'
		moveStatusEffect.text += ')[/center]'
		moveStatusIcon.texture = moveEffect.statusEffect.get_icon()
		statusEffectRow.visible = true
		if moveEffect.rune != null and Combatant.are_runes_allowed():
			# a move eff details panel with rune details only needs to scroll if it's surge effect
			if isSurgeEffect:
				boxContainerScroller.connect_scroll_down_top_neighbor(statusHelpButton)
				boxContainerScroller.connect_scroll_up_bottom_neighbor(statusHelpButton)
			# the else logic that should go here is already handled below after the rune details panel is loaded...
		else:
			statusHelpButton.focus_neighbor_bottom = '.'
			statusHelpButton.focus_neighbor_top = '.'
	else:
		statusEffectRow.visible = false
		statusHelpButton.focus_neighbor_bottom = '.'
		statusHelpButton.focus_neighbor_top = '.'
		boxContainerScroller.connect_scroll_down_top_neighbor(boxContainerScroller.scrollUpBtn)
		boxContainerScroller.connect_scroll_up_bottom_neighbor(boxContainerScroller.scrollDownBtn)
	
	if isSurgeEffect and moveEffect.surgeChanges != null:
		var changes: Array[SurgeChanges.SurgeChangeDescRow] = moveEffect.surgeChanges.get_description()
		for change: SurgeChanges.SurgeChangeDescRow in changes:
			var row: SurgeChangesRow = surgeChangesRowScene.instantiate()
			row.changeHeader = change.title
			row.changeDetails = change.description
			surgeVBox.add_child(row)
		surgePanel.visible = true
		moveEffPanel.custom_minimum_size.y = SURGE_HEIGHT
		moveEffPanel.size.y = SURGE_HEIGHT
	else:
		surgePanel.visible = false
		moveEffPanel.custom_minimum_size.y = CHARGE_HEIGHT
		moveEffPanel.size.y = CHARGE_HEIGHT
	
	if moveEffect.rune != null and Combatant.are_runes_allowed():
		runeRow.visible = true
		runeDetailsLabel.text = '[center]' + moveEffect.rune.get_rune_type() + ' (Details Below)[/center]'
		runeEffectDetailsPanel.rune = moveEffect.rune
	else:
		runeRow.visible = false
		runeEffectDetailsPanel.rune = null
	
	runeEffectDetailsPanel.isSurgeEffect = isSurgeEffect
	runeEffectDetailsPanel.tooltipPanel = tooltipPanel
	runeEffectDetailsPanel.casterPosition = ''
	runeEffectDetailsPanel.load_rune_effect_details()
	
	if runeRow.visible and runeEffectDetailsPanel.statusEffectRow.visible:
		if statusEffectRow.visible:
			statusHelpButton.focus_neighbor_bottom = statusHelpButton.get_path_to(runeEffectDetailsPanel.statusHelpButton)
			runeEffectDetailsPanel.statusHelpButton.focus_neighbor_top = runeEffectDetailsPanel.statusHelpButton.get_path_to(statusHelpButton)
		runeEffectDetailsPanel.statusHelpButton.focus_neighbor_bottom = runeEffectDetailsPanel.statusHelpButton.get_path_to(scrollerBottomFocusNeighbor)

func _on_status_help_button_pressed():
	if moveEffect.statusEffect == null:
		return
	helpButtonPressed = statusHelpButton
	tooltipPanel.title = moveEffect.statusEffect.get_status_type_string()
	tooltipPanel.details = moveEffect.statusEffect.get_status_effect_tooltip()
	tooltipPanel.load_tooltip_panel()
	tooltip_panel_opened.emit()

func _on_rune_effect_details_panel_tooltip_panel_opened() -> void:
	if runeEffectDetailsPanel.rune == null:
		return
	
	if runeEffectDetailsPanel.helpButtonPressed == runeEffectDetailsPanel.statusHelpButton:
		if runeEffectDetailsPanel.rune.statusEffect == null:
			return
	
	helpButtonPressed = runeEffectDetailsPanel.helpButtonPressed
	tooltip_panel_opened.emit()

func _on_rune_effect_details_panel_status_button_onscreen_update(isOnscreen: bool) -> void:
	if not isSurgeEffect:
		return # charge effects cannot scroll currently; not bailing out will mess up the focus logic farther up the scene tree by overwriting what's already being set in the parent...
	
	if isOnscreen:
		boxContainerScroller.connect_scroll_down_top_neighbor(runeEffectDetailsPanel.statusHelpButton)
		boxContainerScroller.connect_scroll_up_bottom_neighbor(runeEffectDetailsPanel.statusHelpButton)
	else:
		if runeEffectDetailsPanel.runeHelpButtonOnscreen:
			boxContainerScroller.connect_scroll_down_top_neighbor(runeEffectDetailsPanel.runeHelpButton)
			boxContainerScroller.connect_scroll_up_bottom_neighbor(runeEffectDetailsPanel.runeHelpButton)
		elif statusEffectRow.visible:
			boxContainerScroller.connect_scroll_down_top_neighbor(statusHelpButton)
			boxContainerScroller.connect_scroll_up_bottom_neighbor(statusHelpButton)
		else:
			boxContainerScroller.connect_scroll_down_top_neighbor(boxContainerScroller.scrollUpBtn)
			boxContainerScroller.connect_scroll_up_bottom_neighbor(boxContainerScroller.scrollDownBtn)

func _on_box_container_scroller_visibility_changed() -> void:
	if boxContainerScroller == null:
		print('MoveEffectDetailsPanel Warning: BoxContainerScroller is null')
		return
	custom_minimum_size.x = SCROLLING_WIDTH if boxContainerScroller.visible else NO_SCROLLING_WIDTH
	size.x = custom_minimum_size.x

func _on_rune_effect_details_panel_rune_help_button_onscreen_update(isOnscreen: bool) -> void:
	if not isSurgeEffect:
		return # charge effects cannot scroll currently; not bailing out will mess up the focus logic farther up the scene tree by overwriting what's already being set in the parent...
	
	if isOnscreen:
		boxContainerScroller.connect_scroll_down_top_neighbor(runeEffectDetailsPanel.runeHelpButton)
		boxContainerScroller.connect_scroll_up_bottom_neighbor(runeEffectDetailsPanel.runeHelpButton)
	else:
		if runeEffectDetailsPanel.statusHelpButtonOnscreen:
			boxContainerScroller.connect_scroll_down_top_neighbor(runeEffectDetailsPanel.statusHelpButton)
			boxContainerScroller.connect_scroll_up_bottom_neighbor(runeEffectDetailsPanel.statusHelpButton)
		elif statusEffectRow.visible:
			boxContainerScroller.connect_scroll_down_top_neighbor(statusHelpButton)
			boxContainerScroller.connect_scroll_up_bottom_neighbor(statusHelpButton)
		else:
			boxContainerScroller.connect_scroll_down_top_neighbor(boxContainerScroller.scrollUpBtn)
			boxContainerScroller.connect_scroll_up_bottom_neighbor(boxContainerScroller.scrollDownBtn)
