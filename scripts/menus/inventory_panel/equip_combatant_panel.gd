extends Panel
class_name EquipCombatantPanel

@export var combatant: Combatant = null
@export var item: Item = null
@export var noCurrentEquipmentSprite: Texture = null

var parentPanel: EquipPanel = null
var currentEquipment: Item = null

@onready var animatedCombatantSprite: AnimatedSprite2D = get_node('SpriteControl/CombatantSprite')
@onready var combatantName: RichTextLabel = get_node('CenterCombatantName/CombatantName')
@onready var equipSpriteButton: TextureButton = get_node('EquipmentSpriteButton')
@onready var otherEquipDetailsButton: TextureButton = get_node('OtherEquipmentDetailsButton')
@onready var statsButton: Button = get_node('CenterButtons/HBoxContainer/StatsButton')
@onready var equipButton: Button = get_node('CenterButtons/HBoxContainer/EquipButton')
@onready var unequipButton: Button = get_node('CenterButtons/HBoxContainer/UnequipButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_equip_combatant_panel()

func initial_focus():
	get_equip_button().grab_focus()

func focus_stats_button():
	statsButton.grab_focus()

func focus_details_button():
	if equipSpriteButton.visible:
		equipSpriteButton.grab_focus()
	else:
		otherEquipDetailsButton.grab_focus()

func get_equip_button() -> Button:
	if equipButton.visible:
		return equipButton
	return unequipButton

func load_equip_combatant_panel():
	if combatant == null or parentPanel == null:
		return
	
	equipButton.visible = not combatant.stats.is_item_equipped(item)
	unequipButton.visible = not equipButton.visible
	
	if unequipButton.visible:
		currentEquipment = item
	
	combatantName.text = combatant.disp_name()
	
	animatedCombatantSprite.sprite_frames = combatant.spriteFrames
	if combatant.maxSize.x <= 16 and combatant.maxSize.y <= 16:
		animatedCombatantSprite.scale = Vector2(3, 3)
	elif combatant.maxSize.x < 48 and combatant.maxSize.y < 48:
		animatedCombatantSprite.scale = Vector2(2.5, 2.5)
	else:
		animatedCombatantSprite.scale = Vector2(2, 2)
	animatedCombatantSprite.play('walk')
	
	equipSpriteButton.texture_normal = item.itemSprite
	equipSpriteButton.visible = unequipButton.visible
	
	var curEquipmentSprite = noCurrentEquipmentSprite
	if item is Weapon:
		if combatant.stats.equippedWeapon != null:
			currentEquipment = combatant.stats.equippedWeapon
			curEquipmentSprite = combatant.stats.equippedWeapon.itemSprite
	elif item is Armor:
		if combatant.stats.equippedArmor != null:
			currentEquipment = combatant.stats.equippedArmor
			curEquipmentSprite = combatant.stats.equippedArmor.itemSprite
	if curEquipmentSprite == noCurrentEquipmentSprite:
		otherEquipDetailsButton.disabled = true
	
	otherEquipDetailsButton.texture_normal = curEquipmentSprite
	otherEquipDetailsButton.texture_disabled = noCurrentEquipmentSprite
	otherEquipDetailsButton.visible = equipButton.visible
	
	var leftOfStatsBtn: BaseButton = equipSpriteButton
	if otherEquipDetailsButton.visible:
		leftOfStatsBtn = otherEquipDetailsButton
	
	statsButton.focus_neighbor_left = statsButton.get_path_to(leftOfStatsBtn)
	leftOfStatsBtn.focus_neighbor_right = leftOfStatsBtn.get_path_to(statsButton)

func connect_to_equip_button(control: Control, isBottomPanel: bool = true):
	if isBottomPanel:
		control.focus_neighbor_top = control.get_path_to(get_equip_button())
	else:
		control.focus_neighbor_bottom = control.get_path_to(get_equip_button())
		get_equip_button().focus_neighbor_top = get_equip_button().get_path_to(control)

func _on_stats_button_pressed():
	parentPanel.stats_pressed(combatant)

func _on_equip_button_pressed():
	parentPanel.equip_pressed(combatant)

func _on_unequip_button_pressed():
	parentPanel.unequip_pressed(combatant)

func _on_item_details_pressed():
	if currentEquipment != null:
		parentPanel.show_item_details(combatant, currentEquipment)
