class_name NewMoveListItemPanel
extends Panel

signal details_pressed(panel: NewMoveListItemPanel)
signal learn_pressed(panel: NewMoveListItemPanel)
signal learn_hidden

@export var move: Move = null
@export var combatant: Combatant = null
@export var evolution: Evolution = null

var aboveListItemPanel: NewMoveListItemPanel = null
var combatantShardSlot: InventorySlot = null

@onready var moveNameLabel: RichTextLabel = get_node('CenterMoveName/MoveName')
@onready var damageTypeLabel: RichTextLabel = get_node('CenterDetails/DamageType')

@onready var itemSprite: Sprite2D = get_node('ItemSprite')
@onready var itemNameLabel: RichTextLabel = get_node('CenterItemName/ItemName')
@onready var itemCountLabel: RichTextLabel = get_node('CenterItemCount/ItemCount')

@onready var animatedCombatantSprite: AnimatedSprite2D = get_node('CenterCombatantSprite/CombatantSpriteControl/CombatantSprite')
@onready var minionNameLabel: RichTextLabel = get_node('CenterMinionName/MinionName')

@onready var detailsButton: Button = get_node('Buttons/DetailsButton')
@onready var learnButton: Button = get_node('Buttons/LearnButton')

func load_new_move_list_item_panel() -> void:
	if move == null or combatant == null:
		queue_free()
		return
	
	moveNameLabel.text = move.moveName
	damageTypeLabel.text = ''
	if move.element != Move.Element.NONE:
		damageTypeLabel.text += Move.element_to_string(move.element) + '\n'
	damageTypeLabel.text += Move.dmg_category_to_string(move.category)
	
	combatantShardSlot = PlayerResources.inventory.get_shard_slot_for_combatant(combatant.save_name())
	if combatantShardSlot != null and not (move in PlayerResources.playerInfo.combatant.stats.movepool.pool):
		itemSprite.texture = combatantShardSlot.item.itemSprite
		itemNameLabel.text = combatantShardSlot.item.itemName
		itemCountLabel.text = 'x' + TextUtils.num_to_comma_string(combatantShardSlot.count)
		itemSprite.visible = true
		itemNameLabel.visible = true
		itemCountLabel.visible = true
		
		animatedCombatantSprite.visible = false
		minionNameLabel.visible = false
		learnButton.visible = true
	else:
		itemSprite.visible = false
		itemNameLabel.visible = false
		itemCountLabel.visible = false
		
		var combatantSprite: CombatantSprite = combatant.get_sprite_obj() if evolution == null else evolution.combatantSprite
		animatedCombatantSprite.sprite_frames = combatantSprite.spriteFrames
		animatedCombatantSprite.offset = (combatantSprite.maxSize / 2) - combatantSprite.idleCanvasCenterPosition
		animatedCombatantSprite.flip_h = combatantSprite.spriteFacesRight
		if combatantSprite.spriteFacesRight: # if flipping, invert the X offset
			animatedCombatantSprite.offset.x *= -1
			
		if combatantSprite.idleSize.x > 32 or combatantSprite.idleSize.y > 32:
			animatedCombatantSprite.scale = 2 * Vector2.ONE
		else:
			animatedCombatantSprite.scale = 3 * Vector2.ONE
		
		animatedCombatantSprite.play('battle_idle')
		minionNameLabel.text = combatant.disp_name() if combatant.nickname != '' or evolution == null else evolution.stats.displayName
		
		animatedCombatantSprite.visible = true
		minionNameLabel.visible = true
		learnButton.visible = false
	
	if learnButton.visible:
		detailsButton.focus_neighbor_right = detailsButton.get_path_to(learnButton)
	else:
		detailsButton.focus_neighbor_right = '.'

func connect_panel_focus_neighbors(abovePanel: NewMoveListItemPanel) -> void:
	aboveListItemPanel = abovePanel
	if abovePanel == null:
		detailsButton.focus_neighbor_top = ''
		learnButton.focus_neighbor_top = ''
		return
	
	abovePanel.learn_hidden.connect(_above_panel_learn_hidden)
	
	detailsButton.focus_neighbor_top = detailsButton.get_path_to(abovePanel.detailsButton)
	abovePanel.detailsButton.focus_neighbor_bottom = abovePanel.detailsButton.get_path_to(detailsButton)
	
	if abovePanel.learnButton.visible:
		learnButton.focus_neighbor_top = learnButton.get_path_to(abovePanel.learnButton)
	else:
		learnButton.focus_neighbor_top = learnButton.get_path_to(abovePanel.detailsButton)
	
	if learnButton.visible:
		abovePanel.learnButton.focus_neighbor_bottom = abovePanel.learnButton.get_path_to(learnButton)
	elif abovePanel.learnButton.visible:
		abovePanel.learnButton.focus_neighbor_bottom = abovePanel.learnButton.get_path_to(detailsButton)

func hide_learn_button() -> void:
	learnButton.visible = false
	if aboveListItemPanel != null:
		aboveListItemPanel.learnButton.focus_neighbor_bottom = aboveListItemPanel.learnButton.get_path_to(detailsButton)
	learn_hidden.emit()

func _above_panel_learn_hidden() -> void:
	learnButton.focus_neighbor_top = learnButton.get_path_to(aboveListItemPanel.detailsButton)

func _on_details_button_pressed() -> void:
	details_pressed.emit(self)

func _on_learn_button_pressed() -> void:
	learn_pressed.emit(self)
