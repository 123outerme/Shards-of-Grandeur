extends Control
class_name ItemCountChoosePanel

enum CountChooseReason {
	BUY = 0,
	SELL = 1,
	TRASH = 2,
}

signal panel_closed(count: int, backPressed: bool)

## the item to pick the count for
@export var item: Item = null

## the reason for having to pick a count (buy, sell, or trash)
@export var chooseReason: CountChooseReason = CountChooseReason.BUY

## initial value to load the panel with
@export var initialValue: int = 1

## min selectable value
@export var minValue: int = 1

## the count for corresponding slot of player inventory if `chooseReason` is BUY or TRASH, shop inventory if SELL 
@export var inventoryCount: int = 1

## the count for corresponding slot of shop inventory if `chooseReason` is BUY, player inventory if SELL
@export var otherInventoryCount: int = 1

## max selectable value; combines the `inventoryCount` and `otherInventoryCount` (if not TRASH `chooseReason`) to calculate
var maxValue: int = 1

@onready var itemSprite: Sprite2D = get_node('Panel/ItemSpriteControl/ItemSprite')
@onready var titleLabel: RichTextLabel = get_node('Panel/ItemCountChooseTitle')
@onready var descLabel: RichTextLabel = get_node('Panel/ItemCountChooseDesc')

@onready var inventoryCountLabel: RichTextLabel = get_node('Panel/InventoryCountsHboxContainer/InventoryCountLabel')
@onready var otherInventoryCountLabel: RichTextLabel = get_node('Panel/InventoryCountsHboxContainer/OtherInventoryCountLabel')

@onready var goldVerbLabel: RichTextLabel = get_node('Panel/GoldCountControl/GoldVerbLabel')
@onready var goldCountLabel: RichTextLabel = get_node('Panel/GoldCountControl/GoldCountLabel')

@onready var countChooseControl: CountChooseControl = get_node('Panel/CountChooseControl')
@onready var okButton: Button = get_node('Panel/OkButton')
@onready var backButton: Button = get_node('Panel/BackButton')
@onready var virtualKeyboard: VirtualKeyboard = get_node('VirtualKeyboard')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SettingsHandler.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()
	countChooseControl.set_lineedit_bottom_focus_neighbor(backButton)
	countChooseControl.set_lineedit_bottom_focus_neighbor(okButton)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_decline") and visible:
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func load_item_count_choose_panel() -> void:
	if item == null:
		visible = false
		return
	itemSprite.texture = item.itemSprite
	var title: String = ''
	var description: String = ''
	var invCountString: String = ''
	var otherInvCountString: String = ''
	match chooseReason:
		CountChooseReason.BUY:
			title = 'Buy Item'
			description = 'How many will you buy?'
			if inventoryCount > 0:
				invCountString = '[right]Shop has ' + TextUtils.num_to_comma_string(inventoryCount) + 'x ' + item.itemName + '.[/right]'
				inventoryCountLabel.visible = true
				maxValue = min(inventoryCount, item.maxCount - otherInventoryCount, floori(PlayerResources.playerInfo.gold / item.cost))
			else:
				inventoryCountLabel.visible = false
				otherInvCountString = '[center]'
				maxValue = min(item.maxCount - otherInventoryCount, floori(PlayerResources.playerInfo.gold / item.cost))
			otherInvCountString += 'You have ' + TextUtils.num_to_comma_string(otherInventoryCount) + 'x ' + item.itemName
			if item.maxCount > 0:
				otherInvCountString += ' (max ' + TextUtils.num_to_comma_string(item.maxCount) + ')'
			otherInvCountString += '.'
			if inventoryCount <= 0:
				otherInvCountString += '[/center]'
		CountChooseReason.SELL:
			title = 'Sell Item'
			description = 'How many will you sell?'
			inventoryCountLabel.visible = true
			var invCountTag: String = 'right'
			if otherInventoryCount > 0:
				otherInvCountString = 'Shop has ' + TextUtils.num_to_comma_string(otherInventoryCount) + 'x ' + item.itemName
				if item.maxCount > 0:
					otherInvCountString += ' (max ' + TextUtils.num_to_comma_string(item.maxCount) + ')'
				otherInvCountString += '.'
				otherInventoryCountLabel.visible = true
				maxValue = min(inventoryCount, item.maxCount - otherInventoryCount)
			else:
				otherInventoryCountLabel.visible = false
				invCountTag = 'center'
				maxValue = inventoryCount
			invCountString = '[' + invCountTag + ']You have ' + TextUtils.num_to_comma_string(inventoryCount) + 'x ' + item.itemName + '.[/' + invCountTag + ']'
			
		CountChooseReason.TRASH:
			title = 'Trash Item'
			description = "How many will you trash?\nYou will get half the item's value in gold for each one trashed."
			invCountString = '[center]You have ' + TextUtils.num_to_comma_string(inventoryCount) + 'x ' + item.itemName + '.[/center]'
			inventoryCountLabel.visible = true
			otherInventoryCountLabel.visible = false
			maxValue = inventoryCount
	
	titleLabel.text = '[center]' + title + ' - ' + item.itemName + '[/center]'
	descLabel.text = '[center]' + description + '[/center]'
	inventoryCountLabel.text = invCountString
	otherInventoryCountLabel.text = otherInvCountString
	update_gold_count_label()
	countChooseControl.value = initialValue
	countChooseControl.minValue = minValue
	countChooseControl.useMin = true
	
	countChooseControl.maxValue = maxValue
	countChooseControl.useMax = maxValue > 0
	countChooseControl.load_count_choose_control()
	countChooseControl.initial_focus()
	visible = true

func close_panel() -> void:
	visible = false
	if virtualKeyboard.visible:
		virtualKeyboard.hide_keyboard()

func update_gold_count_label() -> void:
	goldCountLabel.text = ''
	var cost: int = item.cost * countChooseControl.value
	match chooseReason:
		CountChooseReason.BUY:
			goldCountLabel.text += TextUtils.num_to_comma_string(cost)
			goldVerbLabel.text = '[right]Spend[/right]'
		CountChooseReason.SELL:
			goldCountLabel.text += TextUtils.num_to_comma_string(cost)
			goldVerbLabel.text = '[right]Gain[/right]'
		CountChooseReason.TRASH:
			goldCountLabel.text += TextUtils.num_to_comma_string(roundi(cost * 0.5))
			goldVerbLabel.text = '[right]Recoup[/right]'
	goldCountLabel.text += '?'

func _on_count_choose_control_value_changed(newVal: int) -> void:
	update_gold_count_label()

func _on_virtual_keyboard_backspace_pressed() -> void:
	if countChooseControl.allCountTextSelected:
		countChooseControl.lineEdit.text = ''
		countChooseControl.value = 0
		countChooseControl.allCountTextSelected = false
	else:
		var newVal: int = floori(countChooseControl.value / 10)
		if newVal == 0:
			countChooseControl.lineEdit.text = ''
			countChooseControl.value = 0
		else:
			countChooseControl.set_count_value(newVal)

func _on_virtual_keyboard_enter_pressed() -> void:
	countChooseControl._on_line_edit_text_submitted(countChooseControl.lineEdit.text)

func _on_virtual_keyboard_key_pressed(character: String) -> void:
	if len(character) == 1 and character.is_valid_int():
		if countChooseControl.allCountTextSelected:
			countChooseControl.set_count_value(character.to_int())
			countChooseControl.allCountTextSelected = false
		else:
			var newVal: int = countChooseControl.value * 10
			newVal += character.to_int()
			countChooseControl.set_count_value(newVal)

func _on_virtual_keyboard_keyboard_hidden() -> void:
	countChooseControl.initial_focus()

func _on_count_choose_control_line_edit_submitted(text: String) -> void:
	if SettingsHandler.gameSettings.useVirtualKeyboard:
		okButton.grab_focus()
	else:
		countChooseControl.initial_focus()

func _on_ok_button_pressed() -> void:
	# make sure text is validated before emitting this value
	countChooseControl._on_line_edit_text_submitted(countChooseControl.lineEdit.text)
	close_panel()
	panel_closed.emit(countChooseControl.value, false)

func _on_back_button_pressed() -> void:
	close_panel()
	panel_closed.emit(countChooseControl.value, true)

func _on_settings_changed():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	if not virtualKeyboard.enabled and virtualKeyboard.visible:
		virtualKeyboard.hide_keyboard()

func _on_count_choose_control_intercepted_input_in_line_edit() -> void:
	_on_back_button_pressed()
