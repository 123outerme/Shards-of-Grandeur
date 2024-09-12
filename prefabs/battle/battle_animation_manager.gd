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
		await use_item_animation(user, command.slot)
	elif command.type == BattleCommand.Type.ESCAPE:
		await escape_animation(user)
	reset_all_combatants_shade_z_indices()
	combatant_animation_complete.emit()

func use_move_animation(user: CombatantNode, command: BattleCommand, targets: Array[CombatantNode], interceptors: Array[CombatantNode], statusDamagedCombatants: Array[CombatantNode]):
	var sprites: Array[MoveAnimSprite] = command.get_command_sprites()
	var shade: BattlefieldShadeAnim = null
	
	for target: CombatantNode in targets:
		var resultIdx: int = command.targets.find(target.combatant)
		if command.commandResult != null and resultIdx > -1 and resultIdx < len(command.commandResult.afflictedStatuses):
			target.isBeingStatusAfflicted = true
	
	var animCallbackFunc: Callable = Callable()
	var spriteCallbackFunc: Callable = Callable()
	var tweenCallbackFunc: Callable = Callable()
	var shadeCallbackFunc: Callable = Callable()
	waitingForSignals = []
	
	if command.moveEffectType == Move.MoveEffectType.CHARGE:
		shade = command.move.moveAnimation.chargeBattlefieldShade
	elif command.moveEffectType == Move.MoveEffectType.SURGE:
		shade = command.move.moveAnimation.surgeBattlefieldShade
		var surgeParticles: ParticlePreset = preload("res://gamedata/moves/particles_surge.tres")
		user.play_particles(surgeParticles)
	
	# play animation sprite if not none or battle idle
	if command.move.moveAnimation.combatantAnimation != '' and command.move.moveAnimation.combatantAnimation != 'battle_idle':
		user.play_animation(command.move.moveAnimation.combatantAnimation)
		animCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.SPRITE_ANIM)
		user.sprite_animation_finished.connect(animCallbackFunc)
		waitingForSignals.append(AnimationType.SPRITE_ANIM)
	
	# user particles
	user.play_particles(command.move.moveAnimation.userParticlePreset)
	
	set_combatant_above_shade(user)
	# build list of defenders
	var defenders: Array[CombatantNode] = []
	defenders.append_array(targets)
	for interceptor: CombatantNode in interceptors:
		if interceptor not in defenders:
			defenders.append(interceptor)
	
	# TODO?: rework statusDamagedCombatants logic
	for defender: CombatantNode in defenders:
		set_combatant_above_shade(defender)
		defender.play_particles(command.move.moveAnimation.targetsParticlePreset)
		var particlePresets: Array[ParticlePreset] = command.get_particles(defender, user, defender not in interceptors)
		# play recoil dmg effect
		if defender in statusDamagedCombatants:
			# link the damaged combatant to the attacking combatant
			#combatantNode.hittingCombatant = userNode
			defender.play_particles(BattleCommand.get_hit_particles(), true, 0.5)
		for preset in particlePresets:
			# skip null presets
			if preset == null:
				continue
			# if this is a "hit" particle effect and the particles will be delayed:
			#if preset.emitter == 'hit' and combatantNode != userNode:
				# link the damaged combatant to the attacking combatant
			#	combatantNode.hittingCombatant = userNode
			defender.play_particles(preset, defender != user)
	
	# move sprites
	if len(sprites) > 0:
		user.moveSpriteTargets = targets 
		user.play_move_sprites(sprites)
		spriteCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
		user.move_sprites_finished.connect(spriteCallbackFunc)
		waitingForSignals.append(AnimationType.MOVE_SPRITE_ANIM)
	
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
			tweenCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.TWEEN_TO_TARGET)
			user.tween_back_finished.connect(tweenCallbackFunc)
			user.tween_to(moveToPos, moveToCombatantNode)
			waitingForSignals.append(AnimationType.TWEEN_TO_TARGET)
	
	# battlefield shade
	if shade != null:
		battlefieldShade.do_battlefield_shade_anim(shade)
		shadeCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.BATTLEFIELD_SHADE)
		if AnimationType.TWEEN_TO_TARGET in waitingForSignals:
			user.tween_returning_to_rest.connect(_lift_battlefield_shade)
		
		battlefieldShade.shade_faded_up.connect(shadeCallbackFunc)
		waitingForSignals.append(AnimationType.BATTLEFIELD_SHADE)
	
	if len(waitingForSignals) > 0:
		# await for when the final animation has completed
		await animation_waiting_complete
		if animCallbackFunc != Callable():
			user.sprite_animation_finished.disconnect(animCallbackFunc)
		if spriteCallbackFunc != Callable():
			user.move_sprites_finished.disconnect(spriteCallbackFunc)
		if tweenCallbackFunc != Callable():
			user.tween_back_finished.disconnect(tweenCallbackFunc)
		if shadeCallbackFunc != Callable():
			battlefieldShade.shade_faded_up.disconnect(shadeCallbackFunc)
			if tweenCallbackFunc != Callable():
				user.tween_returning_to_rest.disconnect(_lift_battlefield_shade)
	
	# TODO: place hit particle spawning here... plus other post-move animations

func use_item_animation(user: CombatantNode, slot: InventorySlot):
	user.useItemSprite = slot.item.itemSprite
	
	var spritesCallbackFunc: Callable = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
	var shadeCallbackFunc: Callable = _on_combatant_animation_unit_complete.bind(AnimationType.BATTLEFIELD_SHADE)
	
	user.update_hp_tag()
	
	set_combatant_above_shade(user)
	user.play_move_sprites(BattleCommand.useItemAnimation.chargeMoveSprites)
	user.move_sprites_finished.connect(spritesCallbackFunc)
	user.play_particles(BattleCommand.useItemAnimation.userParticlePreset)
	
	battlefieldShade.do_battlefield_shade_anim(BattleCommand.useItemAnimation.chargeBattlefieldShade)
	battlefieldShade.shade_faded_up.connect(shadeCallbackFunc)
	
	waitingForSignals = [AnimationType.MOVE_SPRITE_ANIM, AnimationType.BATTLEFIELD_SHADE]
	await animation_waiting_complete
	user.move_sprites_finished.disconnect(spritesCallbackFunc)
	battlefieldShade.shade_faded_up.disconnect(shadeCallbackFunc)
	
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

func _lift_battlefield_shade() -> void:
	battlefieldShade.lift_battlefield_shade()

func _on_combatant_animation_unit_complete(type: BattleAnimationManager.AnimationType) -> void:
	if type in waitingForSignals:
		waitingForSignals.erase(type)
	if len(waitingForSignals) == 0:
		animation_waiting_complete.emit()
