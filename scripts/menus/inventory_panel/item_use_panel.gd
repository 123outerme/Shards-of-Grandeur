extends Control
class_name ItemUsePanel

signal ok_pressed

@export var item: Item = null
@export var target: Combatant = null
@export var learnedMove: Move = null
@export var learnedFromEvolution: Evolution = null

@onready var itemSprite: Sprite2D = get_node("Panel/ItemSpriteControl/ItemSprite")
@onready var itemUsedTitle: RichTextLabel = get_node("Panel/ItemUsedTitle")
@onready var itemUsedEffects: RichTextLabel = get_node("Panel/ItemUsedEffects")

@onready var moveLearnAnimController: MoveLearnAnimationController = get_node('Panel/MoveLearnAnimControl')

@onready var hpDisplay: Control = get_node('Panel/HpDisplay')
@onready var hpLabel: RichTextLabel = get_node('Panel/HpDisplay/HpProgressBar/Hp')
@onready var hpNameLabel: RichTextLabel = get_node('Panel/HpDisplay/HpNameLabel')
@onready var hpBar: TextureProgressBar = get_node('Panel/HpDisplay/HpProgressBar')

@onready var okButton: Button = get_node('Panel/OkButton')

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_ok_button_pressed()

func load_item_use_panel():
	var itemUseText: String = ''
	if target == null:
		target = PlayerResources.playerInfo.combatant
	
	moveLearnAnimController.visible = false
	hpDisplay.visible = false
	if item != null:
		itemSprite.texture = item.itemSprite
		if target.would_item_have_effect(item):
			itemUsedTitle.text = '[center]Item Used - ' + item.itemName + '[/center]'
			if learnedMove == null:
				itemUseText = item.get_as_subclass().get_use_message(target)
				if item is Healing:
					hpBar.max_value = target.stats.maxHp
					hpBar.value = target.currentHp
					hpNameLabel.text = '[center]' + target.disp_name() + "'s HP:[/center]"
					hpBar.tint_progress = Combatant.get_hp_bar_color(target.currentHp, target.stats.maxHp)
					update_hp_numbers_label(target.currentHp, target.stats.maxHp)
					hpDisplay.visible = true
					
					var healedHp: int = min(target.stats.maxHp, target.currentHp + item.healBy)
					var hpDrainTween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
					# wait for 0.5 second before starting the tween (animate a property doing nothing)
					hpDrainTween.tween_property(hpBar, 'rotation_degrees', 0, 0.5)
					# then: animate the HP going up
					hpDrainTween.tween_callback(update_hp_numbers_label.bind(healedHp, target.stats.maxHp))
					hpDrainTween.parallel().tween_property(hpBar, 'value', healedHp, 1)
					hpDrainTween.parallel().tween_property(hpBar, 'tint_progress', Combatant.get_hp_bar_color(healedHp, target.stats.maxHp), 1)
			else:
				var shard: Shard = item as Shard
				var combatant: Combatant = Combatant.load_combatant_resource(shard.combatantSaveName)
				combatant.switch_evolution(learnedFromEvolution, null)
				itemUseText = 'You learned ' + learnedMove.moveName + ' from ' + combatant.disp_name() + ', absorbing its Shard in the process. ' + learnedMove.moveLearnedText
				moveLearnAnimController.move = learnedMove
				moveLearnAnimController.shard = shard
				moveLearnAnimController.playAnimAfterLoad = true
				moveLearnAnimController.visible = true
				moveLearnAnimController.load_move_learn_animation()
		else:
			itemUsedTitle.text = '[center]Has No Effect - ' + item.itemName + '[/center]'
			itemUseText = 'You attempted to use the ' + item.itemName + ', but it has no effect'
			if item is Healing:
				itemUseText += ', because you are at full health already'
			if item is KeyItem:
				if item.get_as_subclass() is StatResetItem:
					itemUseText += ', because ' + target.disp_name() + ' has not allocated any Stat Points'
			itemUseText += '.'
		visible = true
		okButton.grab_focus()
	
	if itemUseText == '':
		visible = false
		_on_ok_button_pressed()
	else:
		itemUsedEffects.text = itemUseText

func _on_ok_button_pressed():
	ok_pressed.emit()
	learnedMove = null
	moveLearnAnimController.visible = false
	moveLearnAnimController.playAnimAfterLoad = false
	moveLearnAnimController.clean_up_animation()
	visible = false

func update_hp_numbers_label(hp: int, maxHp: int) -> void:
	hpLabel.text = '[center]' + TextUtils.num_to_comma_string(hp) \
		+ ' / ' + TextUtils.num_to_comma_string(maxHp) + '[/center]'
