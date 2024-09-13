extends Node2D
class_name BattleAnimationManager

## the entire animation has just started
signal combatant_animation_start

## the entire animation is complete for this turn
signal combatant_animation_complete

## just one portion of the animation is complete for this turn
signal combatant_animation_unit_complete(type: AnimationType)

## signals that all animation types we were waiting for are completed. Different than turn_animation_complete, as we may string multiple of these together before calling this turn done.
signal animation_waiting_complete

enum AnimationType {
	SPRITE_ANIM = 0,
	MOVE_SPRITE_ANIM = 1,
	BATTLEFIELD_SHADE = 2,
	TWEEN_TO_TARGET = 3,
}

@onready var playerCombatantNode: CombatantNode = get_node('PlayerCombatant')
@onready var minionCombatantNode: CombatantNode = get_node('MinionCombatant')
@onready var enemy1CombatantNode: CombatantNode = get_node('EnemyCombatant1')
@onready var enemy2CombatantNode: CombatantNode = get_node('EnemyCombatant2')
@onready var enemy3CombatantNode: CombatantNode = get_node('EnemyCombatant3')

@onready var battlefieldShade: BattlefieldShade = get_node('BattlefieldShade')

@onready var globalMarker: Marker2D = get_node('GlobalMarker')

var waitingForSignals: Array[AnimationType] = []
var totalWaitingForSignals: Array[AnimationType] = []

func get_all_combatant_nodes() -> Array[CombatantNode]:
	return [playerCombatantNode, minionCombatantNode, enemy1CombatantNode, enemy2CombatantNode, enemy3CombatantNode]

func play_turn_animation(user: CombatantNode, command: BattleCommand, statusDamagedCombatants: Array[Combatant]):
	reset_all_combatants_shade_z_indices()
	combatant_animation_start.emit()
	if command.type == BattleCommand.Type.MOVE:
		var targetNodes: Array[CombatantNode] = []
		var interceptingNodes: Array[CombatantNode] = []
		var statusDmgdNodes: Array[CombatantNode] = []
		for cNode: CombatantNode in get_all_combatant_nodes():
			for target: Combatant in command.targets:
				if target == cNode.combatant:
					targetNodes.append(cNode)
			for interceptor: Combatant in command.interceptingTargets:
				if interceptor == cNode.combatant and cNode not in targetNodes:
					interceptingNodes.append(cNode)
			for dmgd: Combatant in statusDamagedCombatants:
				if dmgd == cNode.combatant:
					statusDmgdNodes.append(cNode)
			
		await use_move_animation(user, command, targetNodes, interceptingNodes, statusDmgdNodes)
	elif command.type == BattleCommand.Type.USE_ITEM:
		var targetNodes: Array[CombatantNode] = []
		for cNode: CombatantNode in get_all_combatant_nodes():
			for target: Combatant in command.targets:
				if target == cNode.combatant:
					targetNodes.append(cNode)
		await use_item_animation(user, command.slot, targetNodes)
	elif command.type == BattleCommand.Type.ESCAPE:
		await escape_animation(user)
	reset_all_combatants_shade_z_indices()
	combatant_animation_complete.emit()

func use_move_animation(user: CombatantNode, command: BattleCommand, targets: Array[CombatantNode], interceptors: Array[CombatantNode], statusDamagedCombatants: Array[CombatantNode]):
	var immediateSprites: Array[MoveAnimSprite] = []
	var afterTweenSprites: Array[MoveAnimSprite] = []
	for sprite: MoveAnimSprite in command.get_command_sprites():
		if sprite.delayedUntilReposition:
			afterTweenSprites.append(sprite)
		else:
			immediateSprites.append(sprite)
	
	var shade: BattlefieldShadeAnim = null
	
	for target: CombatantNode in targets:
		var resultIdx: int = command.targets.find(target.combatant)
		if command.commandResult != null and resultIdx > -1 and resultIdx < len(command.commandResult.afflictedStatuses):
			target.isBeingStatusAfflicted = true
	
	var animCallbackFunc: Callable = Callable()
	var spriteCallbackFunc: Callable = Callable()
	var tweenToCallbackFunc: Callable = Callable()
	var tweenBackCallbackFunc: Callable = Callable()
	var shadeCallbackFunc: Callable = Callable()
	waitingForSignals = []
	totalWaitingForSignals = []
	
	if command.moveEffectType == Move.MoveEffectType.CHARGE:
		shade = command.move.moveAnimation.chargeBattlefieldShade
	elif command.moveEffectType == Move.MoveEffectType.SURGE:
		shade = command.move.moveAnimation.surgeBattlefieldShade
		var surgeParticles: ParticlePreset = preload("res://gamedata/moves/particles_surge.tres")
		user.play_particles(surgeParticles)
	
	# play animation sprite if not none or battle idle
	if command.move.moveAnimation.combatantAnimation != '' and command.move.moveAnimation.combatantAnimation != 'battle_idle':
		user.play_animation(command.move.moveAnimation.combatantAnimation)
		if command.move.moveAnimation.combatantAnimation != 'hide':
			animCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.SPRITE_ANIM)
			user.sprite_animation_finished.connect(animCallbackFunc)
			totalWaitingForSignals.append(AnimationType.SPRITE_ANIM)
	
	# play user particles
	user.play_particles(command.move.moveAnimation.userParticlePreset)
	
	set_combatant_above_shade(user)
	# build list of defenders
	var defenders: Array[CombatantNode] = []
	defenders.append_array(targets)
	for interceptor: CombatantNode in interceptors:
		if interceptor not in defenders:
			defenders.append(interceptor)
	
	# play target (defender) particles
	for defender: CombatantNode in defenders:
		set_combatant_above_shade(defender)
		defender.play_particles(command.move.moveAnimation.targetsParticlePreset)
	
	# move sprites
	if len(immediateSprites) > 0:
		user.moveSpriteTargets = targets
		for sprite: MoveAnimSprite in immediateSprites:
			user.play_move_sprite(sprite)
		spriteCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
		user.move_sprites_finished.connect(spriteCallbackFunc)
		totalWaitingForSignals.append(AnimationType.MOVE_SPRITE_ANIM)
	
	# tween-to (combatant movement)
	if command.move.moveAnimation.makesContact:
		var moveToPos: Vector2 = user.global_position # fallback: self (no movement)
		var moveToCombatantNode: CombatantNode = user
		var multiIsAllies: bool = false
		var multiIsEnemies: bool = false
		if len(targets) == 1:
			moveToCombatantNode = targets[0]
			if moveToCombatantNode.leftSide != user.leftSide:
				moveToPos = moveToCombatantNode.onAttackMarker.global_position
			else:
				moveToPos = moveToCombatantNode.onAssistMarker.global_position
		else:
			for targetNode: CombatantNode in targets:
				if targetNode.leftSide != user.leftSide:
					multiIsEnemies = true
				else:
					multiIsAllies = true
			if multiIsAllies or multiIsEnemies:
				moveToCombatantNode = null
				# if targeting both allies and enemies
				if multiIsAllies and multiIsEnemies:
					moveToPos = globalMarker.global_position # use global move pos
				elif multiIsAllies:
					moveToPos = user.allyTeamMarker.global_position # use ally team pos
				else: # multiIsEnemies
					moveToPos = user.enemyTeamMarker.global_position # use enemy team pos
		if moveToPos != user.global_position:
			tweenToCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.TWEEN_TO_TARGET, false)
			user.tween_to_target_finished.connect(tweenToCallbackFunc)
			tweenBackCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.TWEEN_TO_TARGET)
			user.tween_back_finished.connect(tweenBackCallbackFunc)
			user.tween_to(moveToPos, moveToCombatantNode)
			waitingForSignals.append(AnimationType.TWEEN_TO_TARGET)
	
	# battlefield shade
	if shade != null:
		battlefieldShade.do_battlefield_shade_anim(shade)
		shadeCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.BATTLEFIELD_SHADE)
		battlefieldShade.shade_faded_up.connect(shadeCallbackFunc)
	
	# do the tween movement to the target first (if it should be done)
	if len(waitingForSignals) > 0:
		# await for when the final animation has completed
		await animation_waiting_complete
		if tweenToCallbackFunc != Callable():
			user.tween_to_target_finished.disconnect(tweenToCallbackFunc)
	
	# play sprites that should only play after a tween, if one happened
	if len(afterTweenSprites) > 0:
		user.moveSpriteTargets = targets 
		for sprite: MoveAnimSprite in afterTweenSprites:
			user.play_move_sprite(sprite)
		if spriteCallbackFunc == Callable():
			spriteCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
			user.move_sprites_finished.connect(spriteCallbackFunc)
		if AnimationType.MOVE_SPRITE_ANIM not in totalWaitingForSignals:
			totalWaitingForSignals.append(AnimationType.MOVE_SPRITE_ANIM)
	
	if len(totalWaitingForSignals) > 0:
		await animation_waiting_complete
	
	# if a tween was started, return the combatant now (and un-hide while we're at it)
	if tweenBackCallbackFunc != Callable():
		user.tween_back_to_return_pos()
		if user.animatedSprite.animation == 'hide':
			user._on_animated_sprite_animation_finished()
		totalWaitingForSignals.append(AnimationType.TWEEN_TO_TARGET)
	
	# hit particles spawning, updating HP tags
	for defender: CombatantNode in defenders:
		defender.update_hp_tag()
		defender.isBeingStatusAfflicted = false
		var playHitParticles: bool = false
		var dealtDmg: int = 0
		var targetIdx: int = command.targets.find(defender.combatant)
		if targetIdx >= 0 and targetIdx < len(command.commandResult.damagesDealt):
			dealtDmg += command.commandResult.damagesDealt[targetIdx]
			if command.commandResult.damagesDealt[targetIdx] > 0:
				playHitParticles = true
		var interceptorIdx: int = command.interceptingTargets.find(defender.combatant)
		if interceptorIdx >= 0 and interceptorIdx < len(command.commandResult.damageOnInterceptingTargets):
			dealtDmg += command.commandResult.damageOnInterceptingTargets[interceptorIdx]
			if command.commandResult.damageOnInterceptingTargets[interceptorIdx] > 0:
				playHitParticles = true
		if defender in statusDamagedCombatants:
			playHitParticles = true
		if playHitParticles:
			defender.play_particles(BattleCommand.get_hit_particles(), 0.2)
		if dealtDmg != 0:
			pass # TODO: add floating damage numbers here
	
	# lift the battlefield shade now that the animation is over soon
	if shade != null:
		battlefieldShade.lift_battlefield_shade()
		totalWaitingForSignals.append(AnimationType.BATTLEFIELD_SHADE)
	
	if len(totalWaitingForSignals) > 0:
		await animation_waiting_complete
	
	if tweenBackCallbackFunc != Callable():
		user.tween_back_finished.disconnect(tweenBackCallbackFunc)
	if animCallbackFunc != Callable():
		user.sprite_animation_finished.disconnect(animCallbackFunc)
	if spriteCallbackFunc != Callable():
		user.move_sprites_finished.disconnect(spriteCallbackFunc)
		user.moveSpriteTargets = []
	if shadeCallbackFunc != Callable():
		battlefieldShade.shade_faded_up.disconnect(shadeCallbackFunc)

	# post-move animations?

func use_item_animation(user: CombatantNode, slot: InventorySlot, targets: Array[CombatantNode]):
	user.useItemSprite = slot.item.itemSprite
	user.moveSpriteTargets = targets
	
	var spritesCallbackFunc: Callable = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
	var shadeCallbackFunc: Callable = _on_combatant_animation_unit_complete.bind(AnimationType.BATTLEFIELD_SHADE)
	var tweenToCallbackFunc: Callable = Callable()
	var tweenBackCallbackFunc: Callable = Callable()
	
	for target: CombatantNode in targets:
		target.update_hp_tag()
	
	set_combatant_above_shade(user)
	for sprite: MoveAnimSprite in BattleCommand.useItemAnimation.chargeMoveSprites:
		user.play_move_sprite(sprite)
	user.move_sprites_finished.connect(spritesCallbackFunc)
	user.play_particles(BattleCommand.useItemAnimation.userParticlePreset)
	
	battlefieldShade.do_battlefield_shade_anim(BattleCommand.useItemAnimation.chargeBattlefieldShade)
	battlefieldShade.shade_faded_up.connect(shadeCallbackFunc)
	
	waitingForSignals = []
	totalWaitingForSignals = [AnimationType.MOVE_SPRITE_ANIM]
	
	# tween-to (combatant movement)
	if BattleCommand.useItemAnimation.makesContact:
		var moveToPos: Vector2 = user.global_position # fallback: self (no movement)
		var moveToCombatantNode: CombatantNode = user
		var multiIsAllies: bool = false
		var multiIsEnemies: bool = false
		if len(targets) == 1:
			moveToCombatantNode = targets[0]
			if moveToCombatantNode.leftSide != user.leftSide:
				moveToPos = moveToCombatantNode.onAttackMarker.global_position
			else:
				moveToPos = moveToCombatantNode.onAssistMarker.global_position
		else:
			for targetNode: CombatantNode in targets:
				if targetNode.leftSide != user.leftSide:
					multiIsEnemies = true
				else:
					multiIsAllies = true
			if multiIsAllies or multiIsEnemies:
				moveToCombatantNode = null
				# if targeting both allies and enemies
				if multiIsAllies and multiIsEnemies:
					moveToPos = globalMarker.global_position # use global move pos
				elif multiIsAllies:
					moveToPos = user.allyTeamMarker.global_position # use ally team pos
				else: # multiIsEnemies
					moveToPos = user.enemyTeamMarker.global_position # use enemy team pos
		if moveToPos != user.global_position:
			tweenToCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.TWEEN_TO_TARGET)
			tweenBackCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.TWEEN_TO_TARGET)
			user.tween_to_target_finished.connect(tweenToCallbackFunc)
			user.tween_back_finished.connect(tweenBackCallbackFunc)
			user.tween_to(moveToPos, moveToCombatantNode)
			totalWaitingForSignals.append(AnimationType.TWEEN_TO_TARGET)
	
	await animation_waiting_complete
	
	totalWaitingForSignals = [AnimationType.BATTLEFIELD_SHADE]
	battlefieldShade.lift_battlefield_shade()
	
	if tweenBackCallbackFunc != Callable():
		totalWaitingForSignals.append(AnimationType.TWEEN_TO_TARGET)
		user.tween_back_to_return_pos()
	
	await animation_waiting_complete
	
	user.move_sprites_finished.disconnect(spritesCallbackFunc)
	battlefieldShade.shade_faded_up.disconnect(shadeCallbackFunc)
	if tweenToCallbackFunc != Callable():
		user.tween_to_target_finished.disconnect(tweenToCallbackFunc)
	if tweenBackCallbackFunc != Callable():
		user.tween_back_finished.disconnect(tweenBackCallbackFunc)
	user.useItemSprite = null
	
	#if slot.item.itemType == Item.ItemType.HEALING:
	#	user.play_particles()

func escape_animation(user: CombatantNode):
	user.play_animation('walk')
	await user.sprite_animation_finished

## combatant will always be above shade
func set_combatant_above_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = 2

## Combatant will always be below shade
func set_combatant_below_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = 0

## Default combatant z-index. Sets combatant above the shade if the shade is at its "normal" height, if shade is raised then the combatant will be below
func set_combatant_between_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = 1

func reset_all_combatants_shade_z_indices() -> void:
	for combatantNode: CombatantNode in get_all_combatant_nodes():
		set_combatant_between_shade(combatantNode)

func _on_combatant_animation_unit_complete(type: BattleAnimationManager.AnimationType, includeTotal: bool = true) -> void:
	if type in waitingForSignals:
		waitingForSignals.erase(type)
	if type in totalWaitingForSignals and includeTotal:
		totalWaitingForSignals.erase(type)
	if len(waitingForSignals) == 0 and (not includeTotal or len(totalWaitingForSignals) == 0):
		animation_waiting_complete.emit()
