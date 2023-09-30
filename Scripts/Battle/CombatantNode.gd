extends Node2D
class_name CombatantNode

enum Role {
	ALLY = 0,
	ENEMY = 1
}

@export var combatant: Combatant = null
@export var role: Role = Role.ALLY

@onready var selectCombatantBtn: TextureButton = get_node("SelectCombatantBtn")
@onready var sprite: Sprite2D = get_node("CombatantSprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_combatant_node():
	if combatant == null:
		return
	
	sprite.texture = combatant.sprite
	selectCombatantBtn.visible = false
	selectCombatantBtn.size = combatant.sprite.get_size() + Vector2(4, 4) # set size of selecting button to sprite size + 4px
	selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button
