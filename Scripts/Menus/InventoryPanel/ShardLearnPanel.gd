extends Control
class_name ShardLearnPanel

signal learned_move(move: Move)
signal back_pressed

@export var shard: Shard = null

var combatant: Combatant = null

@onready var shardSprite: Sprite2D = get_node("Panel/ShardSpriteControl/ShardSprite")
@onready var learnPanelTitle: RichTextLabel = get_node("Panel/LearnPanelTitle")
@onready var movePoolPanel: MovePoolPanel = get_node("Panel/MovePoolPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_shard_learn_panel():
	if shard == null:
		visible = false
		return
	
	combatant = Combatant.load_combatant_resource(shard.combatantSaveName)
	combatant.stats.level = PlayerResources.playerInfo.stats.level
	shardSprite.texture = combatant.sprite
	learnPanelTitle.text = '[center]Learn a Move From ' + combatant.disp_name() + '[/center]'
	movePoolPanel.moves = combatant.stats.moves
	movePoolPanel.movepool = combatant.stats.movepool
	movePoolPanel.level = PlayerResources.playerInfo.stats.level
	movePoolPanel.load_move_pool_panel()
	movePoolPanel.show_learn_buttons(true)
	visible = true

func _on_back_button_pressed():
	visible = false
	PlayerResources.inventory.add_item(shard as Item) # add the shard back to the inventory after using it up
	back_pressed.emit()

func _on_move_pool_panel_learn_button_clicked(move: Move):
	PlayerResources.playerInfo.stats.movepool.append(move)
	visible = false
	learned_move.emit(move)
