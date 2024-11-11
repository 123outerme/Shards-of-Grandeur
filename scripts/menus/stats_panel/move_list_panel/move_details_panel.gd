extends Control
class_name MoveDetailsPanel

signal back_pressed

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node('Panel/MoveName')
@onready var damageCategory: RichTextLabel = get_node("Panel/DamageCategory")
@onready var requiredLv: RichTextLabel = get_node("Panel/RequiredLv")
@onready var moveDescription: RichTextLabel = get_node("Panel/MoveDescription")
@onready var backButton: Button = get_node("Panel/BackButton")

@onready var chargeEffectDetails: MoveEffectDetailsPanel = get_node('Panel/HBoxContainer/ChargeEffectDetailsPanel')
@onready var surgeEffectDetails: MoveEffectDetailsPanel = get_node('Panel/HBoxContainer/SurgeEffectDetailsPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func initial_focus():
	backButton.grab_focus()

func load_move_details_panel():
	if move == null:
		visible = false
		return

	visible = true
	moveName.text = '[center]' + move.moveName + '[/center]'
	if move.element == Move.Element.NONE:
		damageCategory.text = ''
	else:
		damageCategory.text = Move.element_to_string(move.element) + '/'
	
	damageCategory.text += Move.dmg_category_to_string(move.category)

	requiredLv.text = '[right]Required Level: ' + str(move.requiredLv) + '[/right]'
	moveDescription.text = move.description
	initial_focus()
	
	chargeEffectDetails.moveEffect = move.chargeEffect
	chargeEffectDetails.load_move_effect_details_panel()
	surgeEffectDetails.moveEffect = move.surgeEffect
	surgeEffectDetails.load_move_effect_details_panel()
	
	connect_help_buttons()
	connect_scrollers.call_deferred()

func connect_help_buttons():
	backButton.focus_neighbor_top = '.'
	backButton.focus_neighbor_left = '.'
	backButton.focus_neighbor_right = '.'
	
	if move.surgeEffect.rune != null:
		if surgeEffectDetails.runeEffectDetailsPanel.statusEffectRow.visible:
			backButton.focus_neighbor_top = backButton.get_path_to(surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton)
			surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton.focus_neighbor_bottom = surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton.get_path_to(backButton)
		else:
			backButton.focus_neighbor_top = backButton.get_path_to(surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton)
			surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton.focus_neighbor_bottom = surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton.get_path_to(backButton)
	elif surgeEffectDetails.visible and move.surgeEffect.statusEffect != null:
		backButton.focus_neighbor_top = backButton.get_path_to(surgeEffectDetails.statusHelpButton)
		surgeEffectDetails.statusHelpButton.focus_neighbor_bottom = surgeEffectDetails.statusHelpButton.get_path_to(backButton)
		backButton.focus_neighbor_right = backButton.get_path_to(surgeEffectDetails.statusHelpButton)
		surgeEffectDetails.statusHelpButton.focus_neighbor_left = surgeEffectDetails.statusHelpButton.get_path_to(backButton)
	
	if move.chargeEffect.rune != null:
		if chargeEffectDetails.runeEffectDetailsPanel.statusEffectRow.visible:
			backButton.focus_neighbor_top = backButton.get_path_to(chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton)
			chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton.focus_neighbor_bottom = chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton.get_path_to(backButton)
		else:
			backButton.focus_neighbor_top = backButton.get_path_to(chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton)
			chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton.focus_neighbor_bottom = chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton.get_path_to(backButton)
	elif move.chargeEffect.statusEffect != null:
		backButton.focus_neighbor_top = backButton.get_path_to(chargeEffectDetails.statusHelpButton)
		chargeEffectDetails.statusHelpButton.focus_neighbor_bottom = chargeEffectDetails.statusHelpButton.get_path_to(backButton)
		if surgeEffectDetails.visible:
			backButton.focus_neighbor_left = backButton.get_path_to(chargeEffectDetails.statusHelpButton)
			if move.surgeEffect.statusEffect != null:
				chargeEffectDetails.statusHelpButton.focus_neighbor_right = chargeEffectDetails.statusHelpButton.get_path_to(surgeEffectDetails.statusHelpButton)
				surgeEffectDetails.statusHelpButton.focus_neighbor_left = surgeEffectDetails.statusHelpButton.get_path_to(chargeEffectDetails.statusHelpButton)
			else:
				chargeEffectDetails.statusHelpButton.focus_neighbor_right = chargeEffectDetails.statusHelpButton.get_path_to(backButton)

func connect_scrollers():
	#if chargeEffectDetails.visible and chargeEffectDetails.moveEffect.rune != null and not Combatant.are_runes_allowed() and chargeEffectDetails.boxContainerScroller.visible:
	#	chargeEffectDetails.boxContainerScroller.connect_scroll_down_bottom_neighbor(backButton)
	if surgeEffectDetails.visible and surgeEffectDetails.moveEffect.rune != null and Combatant.are_runes_allowed() and surgeEffectDetails.boxContainerScroller.visible:
		surgeEffectDetails.boxContainerScroller.connect_scroll_down_left_neighbor(backButton)
		# if both have runes, the scroll bars will show up
		if chargeEffectDetails.moveEffect.rune != null:
			chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton.focus_neighbor_right = chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton.get_path_to(surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton)
			surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton.focus_neighbor_left = surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton.get_path_to(chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton)
			if chargeEffectDetails.runeEffectDetailsPanel.statusEffectRow.visible:
				if surgeEffectDetails.runeEffectDetailsPanel.statusEffectRow.visible:
					# both status help buttons are visible
					chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton.focus_neighbor_right = chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton.get_path_to(surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton)
					surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton.focus_neighbor_left = surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton.get_path_to(chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton)
				else:
					# only charge status help button is visible
					chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton.focus_neighbor_right = chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton.get_path_to(surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton)
					surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton.focus_neighbor_left = surgeEffectDetails.runeEffectDetailsPanel.runeHelpButton.get_path_to(chargeEffectDetails.runeEffectDetailsPanel.statusHelpButton)
			elif surgeEffectDetails.runeEffectDetailsPanel.statusEffectRow.visible:
				# only surge status help button is visible
				chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton.focus_neighbor_right = chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton.get_path_to(surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton)
				surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton.focus_neighbor_left = surgeEffectDetails.runeEffectDetailsPanel.statusHelpButton.get_path_to(chargeEffectDetails.runeEffectDetailsPanel.runeHelpButton)
				
			#if chargeEffectDetails.boxContainerScroller.visible:
			#	chargeEffectDetails.boxContainerScroller.connect_scroll_down_right_neighbor(surgeEffectDetails.boxContainerScroller.scrollDownBtn)
			#	chargeEffectDetails.boxContainerScroller.connect_scroll_up_right_neighbor(surgeEffectDetails.boxContainerScroller.scrollUpBtn)
		#else:
		if move.surgeEffect.statusEffect != null: # tab everything else up 1 if using the "both have runes" logic -- for now, charge effect panel cannot scroll at all!
			surgeEffectDetails.boxContainerScroller.connect_scroll_up_left_neighbor(surgeEffectDetails.statusHelpButton)
		else:
			surgeEffectDetails.boxContainerScroller.connect_scroll_up_left_neighbor(surgeEffectDetails.boxContainerScroller.scrollUpBtn)
		# if the charge effect has no help buttons for the focus to need to navigate to: make the back button's top neighbor the scroll down button
		if move.chargeEffect.rune == null and move.chargeEffect.statusEffect == null:
			surgeEffectDetails.boxContainerScroller.connect_scroll_down_bottom_neighbor(backButton)

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

func _on_tooltip_panel_ok_pressed() -> void:
	if chargeEffectDetails.helpButtonPressed != null:
		chargeEffectDetails.helpButtonPressed.grab_focus()
	elif surgeEffectDetails.helpButtonPressed:
		surgeEffectDetails.helpButtonPressed.grab_focus()
	else:
		backButton.grab_focus()
	chargeEffectDetails.helpButtonPressed = null
	surgeEffectDetails.helpButtonPressed = null
