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

@export_category("CombatantNode - Command")
@export var command: BattleCommand = BattleCommand.new()

@onready var selectCombatantBtn: TextureButton = get_node("SelectCombatantBtn")
@onready var sprite: Sprite2D = get_node("CombatantSprite")
@onready var hpTag: Panel = get_node("HPTag")
@onready var lvText: RichTextLabel = get_node("HPTag/LvText")
@onready var hpText: RichTextLabel = get_node("HPTag/HPText")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_combatant_node():
	if combatant == null:
		visible = false
	else:
		visible = true
		sprite.texture = combatant.sprite
		sprite.flip_h = (leftSide and not spriteFacesRight) or (not leftSide and spriteFacesRight)
		selectCombatantBtn.size = combatant.sprite.get_size() + Vector2(4, 4) # set size of selecting button to sprite size + 4px
		selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button
		if leftSide:
			hpTag.position = Vector2(-1 * hpTag.size.x - selectCombatantBtn.size.x * 0.5, -0.5 * hpTag.size.y)
		else:
			hpTag.position = Vector2(selectCombatantBtn.size.x * 0.5, -0.5 * hpTag.size.y)
		
		
		lvText.text = 'Lv ' + String.num(combatant.stats.level)
		hpText.text = TextUtils.num_to_comma_string(combatant.currentHp) + ' / ' + TextUtils.num_to_comma_string(combatant.stats.maxHp)
		
	selectCombatantBtn.visible = false
