extends Node2D
class_name CombatantNode

enum Role {
	ALLY = 0,
	ENEMY = 1
}

@export_category("CombatantNode - Details")
@export var combatant: Combatant = null
@export var role: Role = Role.ALLY
@export var leftSide: bool = false
@export var spriteFacesRight: bool = false

@onready var selectCombatantBtn: TextureButton = get_node("SelectCombatantBtn")
@onready var sprite: Sprite2D = get_node("CombatantSprite")
@onready var hpTag: Panel = get_node("HPTag")
@onready var lvText: RichTextLabel = get_node("HPTag/LvText")
@onready var hpText: RichTextLabel = get_node("HPTag/LvText/HPText")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_combatant_node():
	if not is_alive():
		visible = false
	else:
		visible = true
		sprite.texture = combatant.sprite
		sprite.flip_h = (leftSide and not spriteFacesRight) or (not leftSide and spriteFacesRight)
		selectCombatantBtn.size = combatant.sprite.get_size() + Vector2(4, 4) # set size of selecting button to sprite size + 4px
		selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button
		update_hp_tag()
	
	selectCombatantBtn.visible = false

func update_hp_tag():
	if not is_alive():
		return
	
	hpTag.visible = true
	lvText.text = 'Lv ' + String.num(combatant.stats.level)
	lvText.size.x = len(lvText.text) * 13 # about 13 pixels per character
	hpText.text = TextUtils.num_to_comma_string(combatant.currentHp) + ' / ' + TextUtils.num_to_comma_string(combatant.stats.maxHp)
	hpText.size.x = len(hpText.text) * 13 - 10 # magic number
	hpTag.size.x = (lvText.size.x + hpText.size.x) * lvText.scale.x + 8 # magic number
	if leftSide:
		hpTag.position = Vector2(-1 * hpTag.size.x - selectCombatantBtn.size.x * 0.5, -0.5 * hpTag.size.y)
	else:
		hpTag.position = Vector2(selectCombatantBtn.size.x * 0.5, -0.5 * hpTag.size.y)
		
func is_alive() -> bool:
	if combatant == null:
		return false
	return combatant.currentHp > 0
