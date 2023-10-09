extends Panel

signal details_pressed(move: Move)

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node("CenterMoveName/MoveName")
@onready var roleText: RichTextLabel = get_node("CenterRole/RoleText")
@onready var damageType: RichTextLabel = get_node("CenterType/DamageType")
@onready var detailsButton: Button = get_node("DetailsButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_item_panel():
	if move != null:
		moveName.text = move.moveName
		roleText.text = Move.role_to_string(move.role)
		damageType.text = Move.dmg_category_to_string(move.category)
		detailsButton.visible = true
	else:
		moveName.text = '-----'
		roleText.text = ''
		damageType.text = ''
		detailsButton.visible = false

func _on_details_button_pressed():
	details_pressed.emit(move)
