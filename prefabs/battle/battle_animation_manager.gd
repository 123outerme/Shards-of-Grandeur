extends Node2D
class_name BattleAnimationManager

## the entire animation has just started
signal combatant_animation_start

## the entire animation is complete for this turn
signal combatant_animation_complete

## just one portion of the animation is complete for this turn
signal combatant_animation_unit_complete(type: AnimationType)

## just one rune's animation has completed
signal rune_animation_complete

## signals that all animation types we were waiting for are completed. Different than turn_animation_complete, as we may string multiple of these together before calling this turn done.
signal animation_waiting_complete

enum AnimationType {
	SPRITE_ANIM = 0,
	MOVE_SPRITE_ANIM = 1,
	BATTLEFIELD_SHADE = 2,
	TWEEN_TO_TARGET = 3,
	EVENT_TEXT = 4,
}

const originalCombatantZIndices: Dictionary = {
	'You': 3,
	'Ally': 2,
	'Center': 2,
	'Bottom': 3,
	'Top': 1,
}

@export var disableEventTexts: bool = false

@onready var playerCombatantNode: CombatantNode = get_node('PlayerCombatant')
@onready var minionCombatantNode: CombatantNode = get_node('MinionCombatant')
@onready var enemy1CombatantNode: CombatantNode = get_node('EnemyCombatant1')
@onready var enemy2CombatantNode: CombatantNode = get_node('EnemyCombatant2')
@onready var enemy3CombatantNode: CombatantNode = get_node('EnemyCombatant3')

@onready var battlefieldShade: BattlefieldShade = get_node('BattlefieldShade')

@onready var globalMarker: Marker2D = get_node('GlobalMarker')

var waitingForSignals: Array[AnimationType] = []
var totalWaitingForSignals: Array[AnimationType] = []
var cancellingAnimation: bool = false

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
		var statusDmgdNodes: Array[CombatantNode] = []
		for cNode: CombatantNode in get_all_combatant_nodes():
			for target: Combatant in command.targets:
				if target == cNode.combatant:
					targetNodes.append(cNode)
			for dmgd: Combatant in statusDamagedCombatants:
				if dmgd == cNode.combatant:
					statusDmgdNodes.append(cNode)
		await use_move_animation(user, command, targetNodes, [], statusDmgdNodes)
	elif command.type == BattleCommand.Type.ESCAPE:
		await escape_animation(user)
	reset_all_combatants_shade_z_indices()
	combatant_animation_complete.emit()

func use_move_animation(user: CombatantNode, command: BattleCommand, targets: Array[CombatantNode], interceptors: Array[CombatantNode], statusDamagedCombatants: Array[CombatantNode]):
	var moveAnimation: MoveAnimation = command.move.moveAnimation if command.type == BattleCommand.Type.MOVE else BattleCommand.useItemAnimation
	
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
	
	if command.type != BattleCommand.Type.MOVE or command.moveEffectType == Move.MoveEffectType.CHARGE:
		shade = moveAnimation.chargeBattlefieldShade
	elif command.moveEffectType == Move.MoveEffectType.SURGE:
		shade = moveAnimation.surgeBattlefieldShade
		var surgeParticles: ParticlePreset = preload("res://gamedata/moves/particles_surge.tres")
		user.play_particles(surgeParticles)
		user.update_orb_display()
	
	# play animation sprite if not none or battle idle
	if moveAnimation.combatantAnimation != '' and moveAnimation.combatantAnimation != 'battle_idle' and SettingsHandler.gameSettings.battleAnims:
		user.play_animation(moveAnimation.combatantAnimation)
		if moveAnimation.combatantAnimation != 'hide' and moveAnimation.combatantAnimation != 'stand':
			animCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.SPRITE_ANIM)
			user.sprite_animation_finished.connect(animCallbackFunc)
			totalWaitingForSignals.append(AnimationType.SPRITE_ANIM)
	
	# play user particles
	user.play_particles(moveAnimation.userParticlePreset)
	
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
		defender.play_particles(moveAnimation.targetsParticlePreset)
	
	# move sprites (playing immediately, ignoring timing of tweens)
	if len(immediateSprites) > 0 and SettingsHandler.gameSettings.battleAnims:
		user.moveSpriteTargets = targets
		if command.type == BattleCommand.Type.USE_ITEM and command.slot != null and command.slot.item != null:
			user.useItemSprite = command.slot.item.itemSprite
		for sprite: MoveAnimSprite in immediateSprites:
			user.play_move_sprite(sprite)
		spriteCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
		user.move_sprites_finished.connect(spriteCallbackFunc)
		totalWaitingForSignals.append(AnimationType.MOVE_SPRITE_ANIM)
		user.useItemSprite = null
	
	# tween-to (combatant movement)
	if moveAnimation.makesContact and SettingsHandler.gameSettings.battleAnims:
		var moveToPos: Vector2 = user.global_position # fallback: self (no movement)
		var moveToCombatantNode: CombatantNode = user
		var multiIsAllies: bool = false
		var multiIsEnemies: bool = false
		if len(targets) == 1:
			moveToCombatantNode = targets[0]
			if moveToCombatantNode != user:
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
	if shade != null and SettingsHandler.gameSettings.battleAnims:
		battlefieldShade.do_battlefield_shade_anim(shade)
		shadeCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.BATTLEFIELD_SHADE)
		battlefieldShade.shade_faded_up.connect(shadeCallbackFunc)
	
	# do the tween movement to the target first (if it should be done)
	if len(waitingForSignals) > 0:
		# await for when the final animation has completed
		await animation_waiting_complete
		if cancellingAnimation:
			cancellingAnimation = false
			return
		
		if tweenToCallbackFunc != Callable():
			user.tween_to_target_finished.disconnect(tweenToCallbackFunc)
	
	# play sprites that should only play after a tween, if one happened
	if len(afterTweenSprites) > 0 and SettingsHandler.gameSettings.battleAnims:
		user.moveSpriteTargets = targets
		if command.type == BattleCommand.Type.USE_ITEM and command.slot != null and command.slot.item != null:
			user.useItemSprite = command.slot.item.itemSprite
		for sprite: MoveAnimSprite in afterTweenSprites:
			user.play_move_sprite(sprite)
		if spriteCallbackFunc == Callable():
			spriteCallbackFunc = _on_combatant_animation_unit_complete.bind(AnimationType.MOVE_SPRITE_ANIM)
			user.move_sprites_finished.connect(spriteCallbackFunc)
		if AnimationType.MOVE_SPRITE_ANIM not in totalWaitingForSignals:
			totalWaitingForSignals.append(AnimationType.MOVE_SPRITE_ANIM)
		user.useItemSprite = null
	
	if len(totalWaitingForSignals) > 0:
		await animation_waiting_complete
		if cancellingAnimation:
			cancellingAnimation = false
			return
	
	# if a tween was started, return the combatant now (and un-hide while we're at it)
	if tweenBackCallbackFunc != Callable():
		user.tween_back_to_return_pos()
		totalWaitingForSignals.append(AnimationType.TWEEN_TO_TARGET)
	
	if user.animatedSprite.animation == 'hide' or moveAnimation.combatantAnimation == 'stand':
		user._on_animated_sprite_animation_finished()
	
	var longestTextDelay: float = 0
	var playedEventTexts: bool = false
	# hit particles spawning, updating HP tags, playing event texts for damage, status, and stat boosts
	for defender: CombatantNode in defenders:
		defender.update_hp_tag()
		var playHitParticles: bool = false
		var dealtDmg: int = 0
		var dmgWasSuperEffective: bool = false
		var eventTexts: Array[String] = []
		var targetIdx: int = command.targets.find(defender.combatant)
		var moveEffect: MoveEffect = null
		if command.type == BattleCommand.Type.MOVE:
			moveEffect = command.move.surgeEffect.apply_surge_changes(absi(command.orbChange)) if command.moveEffectType == Move.MoveEffectType.SURGE else command.move.chargeEffect
		
		if targetIdx >= 0 and targetIdx < len(command.commandResult.damagesDealt):
			dealtDmg += command.commandResult.damagesDealt[targetIdx]
			if command.type == BattleCommand.Type.MOVE:
				if moveEffect.power > 0 and defender.combatant.get_element_effectiveness_multiplier(command.move.element) == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective:
					dmgWasSuperEffective = true
			if command.commandResult.damagesDealt[targetIdx] > 0:
				playHitParticles = true
		var interceptorIdx: int = command.interceptingTargets.find(defender.combatant)
		if interceptorIdx >= 0 and interceptorIdx < len(command.commandResult.damageOnInterceptingTargets):
			dealtDmg += command.commandResult.damageOnInterceptingTargets[interceptorIdx]
			if command.type == BattleCommand.Type.MOVE:
				if moveEffect.power > 0 and defender.combatant.get_element_effectiveness_multiplier(command.move.element) == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective:
					dmgWasSuperEffective = true
			if command.commandResult.damageOnInterceptingTargets[interceptorIdx] > 0:
				playHitParticles = true
		if defender in statusDamagedCombatants:
			playHitParticles = true
		if playHitParticles:
			defender.play_particles(BattleCommand.get_hit_particles(), 0)
		# event texts start here: damage
		if dealtDmg != 0:
			eventTexts.append(CombatantEventText.build_damage_text(dealtDmg, dmgWasSuperEffective))
		if defender == user and command.commandResult.lifestealHeal > 0:
			eventTexts.append(CombatantEventText.build_damage_text(-1 * command.commandResult.lifestealHeal))
		# status effect text here
		if targetIdx > -1 and command.commandResult.afflictedStatuses[targetIdx]:
			var statusEffect: StatusEffect = defender.combatant.statusEffect
			if statusEffect == null and command.type == BattleCommand.Type.USE_ITEM:
				var healing: Healing = command.slot.item as Healing
				if healing.statusStrengthHeal != StatusEffect.Potency.NONE:
					statusEffect = StatusEffect.new(StatusEffect.Type.NONE, healing.statusStrengthHeal, true)
			eventTexts.append(CombatantEventText.build_status_get_text(statusEffect))
		# stat changes text here
		if targetIdx > -1 and (command.commandResult.wasBoosted[targetIdx] or len(command.commandResult.equipmentProcd[targetIdx]) > 0):
			var statChanges: StatChanges = null
			if command.type == BattleCommand.Type.MOVE:
				if command.commandResult.wasBoosted[targetIdx]:
					# if the command type is a move: calculate the stat changes of the move
					statChanges = moveEffect.targetStatChanges
					# if the defender is also the user and there are self-boosts
					if defender == user and moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
						if statChanges != null:
							statChanges = statChanges.copy()
							statChanges.stack(moveEffect.selfStatChanges)
						else:
							statChanges = moveEffect.selfStatChanges
				if len(command.commandResult.equipmentProcd[targetIdx]) > 0:
					if statChanges == null:
						statChanges = StatChanges.new()
					var equipmentArr: Array[Item] = command.commandResult.equipmentProcd[targetIdx]
					for equipment: Item in equipmentArr:
						if equipment.itemType == Item.Type.WEAPON:
							statChanges.stack((equipment as Weapon).statChanges)
							# TODO: play weapon proc animation
						else:
							statChanges.stack((equipment as Armor).statChanges)
							# TODO: play armor proc animation
			elif command.type == BattleCommand.Type.USE_ITEM:
				# if the command type is an item (healing item): get the stat changes of the item
				if command.slot.item.itemType == Item.Type.HEALING:
					var healing: Healing = command.slot.item as Healing
					statChanges = healing.statChanges
			if statChanges != null and statChanges.has_stat_changes():
				eventTexts.append_array(CombatantEventText.build_stat_changes_texts(statChanges))
		# END event texts
		var textDelayAccum: float = 0
		if not disableEventTexts and SettingsHandler.gameSettings.battleAnims:
			for textIdx: int in range(len(eventTexts)):
				if textIdx > 0:
					textDelayAccum += CombatantEventText.SECS_UNTIL_FADE_OUT
				defender.play_event_text(eventTexts[textIdx], textDelayAccum)
			playedEventTexts = playedEventTexts or len(eventTexts) > 0
		if textDelayAccum > longestTextDelay:
			longestTextDelay = textDelayAccum
		defender.isBeingStatusAfflicted = false
	
	# if the user wasn't a defender, we still need to update (HP tag, hit particles, event texts)
	if not user in defenders:
		user.update_hp_tag()
		var eventTexts: Array[String] = []
		# start event texts: damage
		if user in statusDamagedCombatants or command.commandResult.selfRecoilDmg > 0:
			user.play_particles(BattleCommand.get_hit_particles(), 0)
			eventTexts.append(CombatantEventText.build_damage_text(command.commandResult.selfRecoilDmg))
		if command.commandResult.lifestealHeal > 0:
			eventTexts.append(CombatantEventText.build_damage_text(-1 * command.commandResult.lifestealHeal))
		# status effect text + stat changes text
		if command.type == BattleCommand.Type.MOVE:
			var moveEffect: MoveEffect = command.move.chargeEffect
			if command.moveEffectType == Move.MoveEffectType.SURGE:
				moveEffect = command.move.surgeEffect.apply_surge_changes(absi(command.orbChange))
			if moveEffect.selfGetsStatus and command.commandResult.selfAfflictedStatus:
				eventTexts.append(CombatantEventText.build_status_get_text(user.combatant.statusEffect))
			# if the command type is a move: calculate the stat changes of the move, use that for texts
			if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
				eventTexts.append_array(CombatantEventText.build_stat_changes_texts(moveEffect.selfStatChanges))
		# END event texts
		var textDelayAccum: float = 0
		if not disableEventTexts and SettingsHandler.gameSettings.battleAnims:
			for textIdx: int in range(len(eventTexts)):
				if textIdx > 0:
					textDelayAccum += CombatantEventText.SECS_UNTIL_FADE_OUT
				user.play_event_text(eventTexts[textIdx], textDelayAccum)
			playedEventTexts = playedEventTexts or len(eventTexts) > 0
		if textDelayAccum > longestTextDelay:
			longestTextDelay = textDelayAccum
		user.isBeingStatusAfflicted = false
	
	# lift the battlefield shade now that the animation is over soon
	if shade != null and SettingsHandler.gameSettings.battleAnims:
		battlefieldShade.lift_battlefield_shade()
		totalWaitingForSignals.append(AnimationType.BATTLEFIELD_SHADE)
	
	if playedEventTexts:
		get_tree().create_timer(longestTextDelay + CombatantEventText.FADE_IN_SECS + CombatantEventText.SECS_UNTIL_FADE_OUT) \
			.timeout.connect(_on_combatant_animation_unit_complete.bind(AnimationType.EVENT_TEXT))
		totalWaitingForSignals.append(AnimationType.EVENT_TEXT)
	
	if len(totalWaitingForSignals) > 0:
		await animation_waiting_complete
		if cancellingAnimation:
			cancellingAnimation = false
			return
	
	if tweenBackCallbackFunc != Callable():
		user.tween_back_finished.disconnect(tweenBackCallbackFunc)
	if animCallbackFunc != Callable():
		user.sprite_animation_finished.disconnect(animCallbackFunc)
	if spriteCallbackFunc != Callable():
		user.move_sprites_finished.disconnect(spriteCallbackFunc)
	user.moveSpriteTargets = []
	if shadeCallbackFunc != Callable():
		battlefieldShade.shade_faded_up.disconnect(shadeCallbackFunc)

	await play_triggered_rune_animations()
	
	# post-move animations?
	
	#if command.type == BattleCommand.Type.USE_ITEM and slot.item.itemType == Item.ItemType.HEALING:
	#	user.play_particles()

func escape_animation(user: CombatantNode):
	if SettingsHandler.gameSettings.battleAnims:
		user.play_animation('walk')
		await user.sprite_animation_finished

func play_intermediate_round_animations(state: BattleState):
	totalWaitingForSignals = []
	waitingForSignals = []
	
	if state.calcdStateIndex < len(state.calcdStateStrings):
		var eventTexts: Array[String] = []
		var subjectNode: CombatantNode = null
		for cNode: CombatantNode in get_all_combatant_nodes():
			if cNode.combatant == state.calcdStateCombatants[state.calcdStateIndex]:
				subjectNode = cNode
				break
		if subjectNode != null:
			if subjectNode.combatant in state.statusEffDamagedCombatants:
				subjectNode.play_particles(BattleCommand.get_hit_particles())
				eventTexts.append(CombatantEventText.build_damage_text(state.calcdStateDamage[state.calcdStateIndex]))
				subjectNode.update_hp_tag()
			var procdEquipment: Array[Item] = state.calcdStateEquipmentProcd[state.calcdStateIndex]
			if procdEquipment != null:
				for equipment: Item in procdEquipment:
					var statChanges: StatChanges = null
					if equipment.itemType == Item.Type.WEAPON:
						statChanges = (equipment as Weapon).statChanges
					elif equipment.itemType == Item.Type.ARMOR:
						statChanges = (equipment as Armor).statChanges
					if statChanges != null and statChanges.has_stat_changes():
						eventTexts.append_array(CombatantEventText.build_stat_changes_texts(statChanges))
					# TODO: play equipment proc'd animation for this equipment
			var textDelayAccum: float = 0
			var playedEventTexts: bool = false
			if not disableEventTexts and SettingsHandler.gameSettings.battleAnims:
				for textIdx: int in range(len(eventTexts)):
					if textIdx > 0:
						textDelayAccum += CombatantEventText.SECS_UNTIL_FADE_OUT
					subjectNode.play_event_text(eventTexts[textIdx], textDelayAccum)
					playedEventTexts = true
			
			if playedEventTexts:
				get_tree().create_timer(textDelayAccum + CombatantEventText.FADE_IN_SECS + CombatantEventText.SECS_UNTIL_FADE_OUT) \
					.timeout.connect(_on_combatant_animation_unit_complete.bind(AnimationType.EVENT_TEXT))
				totalWaitingForSignals.append(AnimationType.EVENT_TEXT)
			
			combatant_animation_start.emit()
			if len(totalWaitingForSignals) > 0:
				# start/complete events are only emitted if the subject is found and animations are playing
				await animation_waiting_complete

			await play_triggered_rune_animations()
			combatant_animation_complete.emit()

func skip_intermediate_animations(state: BattleState, menuState: BattleState.Menu):
	# if the current state is pre-battle:
	if menuState == BattleState.Menu.PRE_BATTLE:
		# cancel all active animations for the turn combatant
		var subjectNode: CombatantNode = null
		for cNode: CombatantNode in get_all_combatant_nodes():
			if cNode.combatant == state.calcdStateCombatants[state.calcdStateIndex]:
				subjectNode = cNode
				break
		if subjectNode != null:
			subjectNode.stop_animation(false, false, true, true)
			if len(totalWaitingForSignals) > 0:
				totalWaitingForSignals = []
				animation_waiting_complete.emit()
	# otherwise, if not pre-battle then don't cancel the active animations, continue as normal

func play_triggered_rune_animations() -> void:
	for combatantNode: CombatantNode in get_all_combatant_nodes():
		var removingRuneSprites: Array[MoveSprite] = []
		for runeSprite: MoveSprite in combatantNode.playingRuneSprites:
			var rune: Rune = runeSprite.linkedResource as Rune
			var runeIdx: int = combatantNode.combatant.triggeredRunes.find(rune)
			if not (rune in combatantNode.combatant.runes) and runeIdx != -1:
				removingRuneSprites.append(runeSprite)
				if SettingsHandler.gameSettings.battleAnims:
					runeSprite.looping = false
					runeSprite.anim = rune.triggerAnim
					runeSprite.move_sprite_complete.connect(_on_rune_trigger_animation_complete)
					runeSprite.play_sprite_animation()
					await rune_animation_complete
					var eventTexts: Array[String] = []
					var eventTargets: Array[CombatantNode] = []
					if combatantNode.combatant.triggeredRunesDmg[runeIdx] != 0:
						var runeDmg: int = combatantNode.combatant.triggeredRunesDmg[runeIdx]
						var superEffective: bool = combatantNode.combatant.get_element_effectiveness_multiplier(rune.element) == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective
						eventTexts.append(CombatantEventText.build_damage_text(runeDmg, superEffective))
						eventTargets.append(combatantNode)
						combatantNode.play_particles(BattleCommand.get_hit_particles(), 0)
						if rune.lifesteal > 0:
							var lifestealDmg: float = max(1, runeDmg * max(0, rune.lifesteal)) * -1
							var casterNode: CombatantNode = null
							for cNode: CombatantNode in get_all_combatant_nodes():
								if cNode.combatant == rune.caster:
									casterNode = cNode
									break
							if casterNode != null:
								eventTexts.append(CombatantEventText.build_damage_text(lifestealDmg, false))
								eventTargets.append(casterNode)
					if rune.statChanges != null and rune.statChanges.has_stat_changes():
						eventTexts.append(CombatantEventText.build_stat_changes_texts(rune.statChanges))
						eventTargets.append(combatantNode)
					if combatantNode.combatant.triggeredRunesStatus[runeIdx]:
						eventTexts.append(CombatantEventText.build_status_get_text(rune.statusEffect))
						eventTargets.append(combatantNode)
					
					var textDelayAccum: float = 0
					var playedEventTextsCount: int = 0
					if not disableEventTexts:
						for textIdx: int in range(len(eventTexts)):
							var cNode: CombatantNode = eventTargets[textIdx]
							if cNode != null:
								if playedEventTextsCount > 0:
									textDelayAccum += CombatantEventText.SECS_UNTIL_FADE_OUT
								cNode.play_event_text(eventTexts[textIdx], textDelayAccum)
								playedEventTextsCount += 1
					
					if playedEventTextsCount > 0 and SettingsHandler.gameSettings.battleAnims:
						get_tree().create_timer(textDelayAccum + CombatantEventText.FADE_IN_SECS + CombatantEventText.SECS_UNTIL_FADE_OUT) \
							.timeout.connect(_on_rune_trigger_animation_complete)
						await rune_animation_complete
		if not SettingsHandler.gameSettings.battleAnims:
			for runeSprite: MoveSprite in removingRuneSprites:
				runeSprite.looping = false
				var runeSpriteIdx: int = combatantNode.playingRuneSprites.find(runeSprite)
				if runeSpriteIdx != -1 and runeSpriteIdx != combatantNode.playingRuneSpriteIdx:
					runeSprite.destroy()

func play_combatant_event_text(combatantNode: CombatantNode, text: String, delay: float = 0, center: bool = true) -> void:
	if not disableEventTexts and SettingsHandler.gameSettings.battleAnims:
		combatantNode.play_event_text(text, delay, center)

## combatant will always be above shade
func set_combatant_above_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = originalCombatantZIndices[combatantNode.battlePosition] + 4

## Combatant will always be below shade
func set_combatant_below_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = originalCombatantZIndices[combatantNode.battlePosition]

## Default combatant z-index. Sets combatant above the shade if the shade is at its "normal" height, if shade is raised then the combatant will be below
func set_combatant_between_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = originalCombatantZIndices[combatantNode.battlePosition]

func reset_all_combatants_shade_z_indices() -> void:
	for combatantNode: CombatantNode in get_all_combatant_nodes():
		set_combatant_between_shade(combatantNode)

func cancel_animation():
	cancellingAnimation = true
	waitingForSignals = []
	totalWaitingForSignals = []
	animation_waiting_complete.emit()
	playerCombatantNode.stop_animation(true, true, true, true)
	minionCombatantNode.stop_animation(true, true, true, true)
	enemy1CombatantNode.stop_animation(true, true, true, true)
	enemy2CombatantNode.stop_animation(true, true, true, true)
	battlefieldShade.lift_battlefield_shade()
	reset_all_combatants_shade_z_indices()

func _on_combatant_animation_unit_complete(type: BattleAnimationManager.AnimationType, includeTotal: bool = true) -> void:
	if type in waitingForSignals:
		waitingForSignals.erase(type)
	if type in totalWaitingForSignals and includeTotal:
		totalWaitingForSignals.erase(type)
	if len(waitingForSignals) == 0 and (not includeTotal or len(totalWaitingForSignals) == 0):
		animation_waiting_complete.emit()

func _on_rune_trigger_animation_complete(arg: Variant = null) -> void:
	rune_animation_complete.emit()
