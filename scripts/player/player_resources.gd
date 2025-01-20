extends Node
signal story_requirements_updated
signal act_changed

@export var playerInfo: PlayerInfo = PlayerInfo.new()
@export var inventory: Inventory = Inventory.new()
@export var questInventory: QuestInventory = QuestInventory.new()
@export var minions: PlayerMinions = PlayerMinions.new()
@export var loaded: bool = false

var player = null
# the save folder this game came from
var saveFolder: String = 'save'
# the save folder we are loading battle from
# '' if starting a battle while the game is already loaded, a save folder if loading from main menu
var battleSaveFolder: String = ''
var timeSinceLastLoad: float = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func accept_rewards(rewards: Array[Reward]) -> int:
	var gainedLevels: int = 0
	for reward in rewards:
		if reward == null:
			continue # skip this reward if it's null
		playerInfo.gold += reward.gold
		gainedLevels += playerInfo.combatant.stats.add_exp(reward.experience)
		if reward.item != null:
			var tempSlot: InventorySlot = InventorySlot.new(reward.item, reward.itemCount)
			inventory.add_slot(tempSlot)
		if reward.fullyAttuneCombatantSaveName != '':
			minions.fully_attune(reward.fullyAttuneCombatantSaveName)
	if gainedLevels > 0:
		playerInfo.combatant.currentHp = playerInfo.combatant.stats.maxHp
		minions.level_up_minions(playerInfo.combatant.stats.level) # level up all stored minions
	playerInfo.combatant.stats = playerInfo.combatant.stats.copy() # copy stats into combatant's copy
	return gainedLevels

func copy_combatant_to_info(combatant: Combatant):
	playerInfo.combatant.save_from_object(combatant)
	playerInfo.combatant.stats.save_from_object(combatant.stats)

func get_cur_act_save_str() -> String:
	return 'act' + String.num_int64(questInventory.currentAct)

func set_cutscene_seen(saveName: String):
	playerInfo.set_cutscene_seen(saveName)
	questInventory.progress_quest(saveName, QuestStep.Type.CUTSCENE)
	questInventory.auto_turn_in_cutscene_steps(saveName)

func set_follower_active(followerId: String) -> void:
	if playerInfo.set_follower_active(followerId):
		story_requirements_updated.emit()
	
func remove_follower(followerId: String) -> void:
	if playerInfo.remove_follower(followerId):
		story_requirements_updated.emit()

func load_data(save_path):
	if playerInfo == null:
		playerInfo = PlayerInfo.new()
	var newPlayerInfo = playerInfo.load_data(save_path)
	if newPlayerInfo != null:
		playerInfo = newPlayerInfo
		# if this save was created before the seed was introduced: generate it now
		if playerInfo.saveSeed == -1:
			playerInfo.saveSeed = randi()
		playerInfo.combatant.validate_all_evolutions_stat_totals()
		playerInfo.combatant.stats = playerInfo.combatant.stats.copy() # copy stats to Combatant obj
		playerInfo.combatant.validate_evolution_stats() # validate evolution stats data structure
		playerInfo.combatant.stats.movepool = playerInfo.combatant.stats.movepool.duplicate(false)
		if playerInfo.combatant.currentHp == -1: # if -1, set to maxHp
			playerInfo.combatant.currentHp = playerInfo.combatant.stats.maxHp
		if playerInfo.combatant.evolutions == null:
			# compatibility fix: load player evolutions if not present
			playerInfo.combatant.evolutions = load('res://gamedata/combatants/player/player_evolutions.tres') as Evolutions	
		if playerInfo.combatant.sprite == null:
			# combatibility fix: load player sprite if not present
			playerInfo.combatant.sprite = load('res://gamedata/combatants/player/player_sprite.tres') as CombatantSprite
		if playerInfo.combatant.moveEffectiveness == null:
			# combatibility fix: load player effectiveness if not present
			playerInfo.combatant.moveEffectiveness = load('res://gamedata/combatants/player/player_effectiveness.tres')
		player = PlayerFinder.player
	if player != null:
		player.position = playerInfo.position
		if playerInfo.combatant.get_sprite_frames() != null:
			player.set_sprite_frames(playerInfo.combatant.get_sprite_frames())
		player.facingLeft = playerInfo.flipH
		player.sprite.flip_h = playerInfo.flipH
		player.interactableDialogueIndex = playerInfo.interactableDialogueIdx
		player.restore_interactable_dialogue.call_deferred(playerInfo.interactableDialogues)
		player.running = playerInfo.running
	inventory = Inventory.new(true)
	var newInv = inventory.load_data(save_path)
	if newInv != null:
		inventory = newInv
	questInventory = QuestInventory.new()
	var newQuestInv = questInventory.load_data(save_path)
	if newQuestInv != null:
		questInventory = newQuestInv
	minions = PlayerMinions.new()
	var newMinions = minions.load_data(save_path)
	if newMinions != null:
		minions = newMinions
	minions.level_up_minions(playerInfo.combatant.stats.level)
	loaded = true
	timeSinceLastLoad = Time.get_unix_time_from_system()
	#print('loaded at ', timeSinceLastLoad)

func save_data(save_path) -> int:
	var err = 0
	if playerInfo != null:
		if player != null:
			playerInfo.position = player.position
			playerInfo.flipH = player.sprite.flip_h
			playerInfo.interactableDialogues = player.interactableDialogues
			playerInfo.interactableDialogueIdx = player.interactableDialogueIndex
			if player.interactable:
				playerInfo.interactableName = player.interactable.saveName
			else:
				playerInfo.interactableName = ''
			playerInfo.running = player.running
		playerInfo.combatant.stats = playerInfo.combatant.stats.copy()
		playerInfo.combatant.version = GameSettings.get_game_version()
		if playerInfo.combatant.currentHp == -1:
			playerInfo.combatant.currentHp = playerInfo.combatant.stats.maxHp
		if timeSinceLastLoad > -1:
			var curTime: float = Time.get_unix_time_from_system()
			playerInfo.playtimeSecs += (curTime - timeSinceLastLoad)
			#print('new playtime: ', playerInfo.playtimeSecs, ', + ', (Time.get_unix_time_from_system() - timeSinceLastLoad))
			timeSinceLastLoad = curTime
		err = playerInfo.save_data(save_path, playerInfo)
		if err != 0:
			return err
	if inventory != null:
		err = inventory.save_data(save_path, inventory)
		if err != 0:
			return err
	if questInventory != null:
		err = questInventory.save_data(save_path, questInventory)
		if err != 0:
			return err
	if minions != null:
		err = minions.save_data(save_path, minions)
		if err != 0:
			return err
	return 0
	
func new_game(save_path):
	playerInfo = PlayerInfo.new()
	playerInfo.saveSeed = randi() # generate a random seed on new game in the range [0, (2^32) - 1]
	inventory = Inventory.new(true)
	inventory.save_data(save_path, inventory)
	questInventory = QuestInventory.new()
	questInventory.save_data(save_path, questInventory)
	minions = PlayerMinions.new()
	minions.save_data(save_path, minions)
	loaded = true
	timeSinceLastLoad = Time.get_unix_time_from_system()
	#print('loaded at ', timeSinceLastLoad)

func name_player(save_path, characterName: String):
	playerInfo.combatant.stats.displayName = characterName
	playerInfo.combatant.nickname = characterName
	playerInfo.save_data(save_path, playerInfo)
