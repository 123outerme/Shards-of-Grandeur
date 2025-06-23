extends Node2D
class_name StatsMenu

signal attempt_equip_weapon_to(stats: Stats)
signal attempt_equip_armor_to(stats: Stats)
signal back_pressed

enum TabbedViewTab {
	STATS = 0,
	NEW_MOVES = 1,
	EQUIPMENT = 2,
	MOVES = 3,
	MINIONS = 4,
	BATTLE_BOOSTS = 5,
	TAB_COUNT,
}

@export_category("StatsPanel - Data")

## the stats to view in this panel
@export var stats: Stats = null

## the current HP from the combatant being viewed
@export var curHp: int = -1

## if true, show the level up text and newly learned move icons
@export var levelUp: bool = false

## if levelling up, how many new levels gained by the level up event
@export var newLvs: int = 0

## if true, cannot change stats, equipment, moves, etc.
@export var readOnly: bool = false

## if true, viewing the player's stats (not a minion)
@export var isPlayer: bool = false

## if true, this stats panel is in the Battle scene
@export var inBattle: bool = false

@export_category("StatsPanel - Audio")

## when leveling up, plays this music
@export var levelUpMusic: AudioStream = null

@export var levelUpLoopMusic: AudioStream = null

## sfx to play when the tabs in the Tab View change
@export var tabChangeSfx: AudioStream = null

@export_category("StatsPanel - Tab Icons")
@export var unspentStatPtsIndicator: Texture2D = null
@export var newMoveIndicator: Texture2D = null
@export var minionChangedIndicator: Texture2D = null

var levelUpAnimPlayed: bool = false
var levelUpAnimPlaying: bool = false

var isMinionStats: bool = false
var minion: Combatant = null
var savedStats: Stats = null
var savedCurHp: int = -1
var savedIsPlayer: bool = false
var changingCombatant: bool = false

var previousControl: Control = null
var previousMoveListSlot: int = -1

@onready var statsTitle: RichTextLabel = get_node("StatsPanel/Panel/StatsTitle")
@onready var levelUpLabel: RichTextLabel = get_node("StatsPanel/Panel/LevelUpLabel")

# --- Tabbed View ---
@onready var tabbedViewPanel: Panel = get_node('StatsPanel/Panel/TabbedView')
@onready var tabbedViewContainer: TabContainer = get_node('StatsPanel/Panel/TabbedView/TabContainer')
@onready var tabbedViewCombatantSprite: AnimatedSprite2D = get_node('StatsPanel/Panel/TabbedView/AnimatedCombatantSprite')

@onready var statlinePanel: StatLinePanel = get_node('StatsPanel/Panel/TabbedView/TabContainer/Stats/StatLinePanel')
@onready var moveListPanel: MoveListPanel = get_node('StatsPanel/Panel/TabbedView/TabContainer/Moves/MoveListPanel')
@onready var equipmentPanel: EquipmentPanel = get_node('StatsPanel/Panel/TabbedView/TabContainer/Equipment/EquipmentPanel')

@onready var minionsControl: Control = get_node('StatsPanel/Panel/TabbedView/TabContainer/Minions')
@onready var minionsPanel: MinionsPanel = get_node('StatsPanel/Panel/TabbedView/TabContainer/Minions/MinionsPanel')

@onready var battleBoostsPanel: BattleBoostsPanel = get_node('StatsPanel/Panel/TabbedView/TabContainer/Battle Boons/BattleBoostsPanel')

@onready var newMovesPanel: NewMovesPanel = get_node('StatsPanel/Panel/TabbedView/TabContainer/New Moves/NewMovesPanel')

@onready var backButton: Button = get_node("StatsPanel/Panel/TabbedView/BackButton")


@onready var levelUpPanel: Panel = get_node('StatsPanel/Panel/LevelUpPanel')
@onready var newLevelLabel: RichTextLabel = get_node('StatsPanel/Panel/LevelUpPanel/NewLevelLabel')
@onready var levelUpAnimPlayer: AnimationPlayer = get_node('StatsPanel/Panel/LevelUpPanel/AnimationPlayer')

@onready var editMovesPanel: EditMovesPanel = get_node("StatsPanel/Panel/EditMovesPanel")

func _ready() -> void:
	SettingsHandler.settings_changed.connect(_settings_changed)
	tabbedViewContainer.tab_selected.connect(_tab_selected)

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline') and not levelUpAnimPlaying:
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
		
	if visible and (event.is_action_pressed('game_tab_left') or event.is_action_pressed('game_tab_right')):
		get_viewport().set_input_as_handled()
		var selectedTab: Control = tabbedViewContainer.get_current_tab_control()
		var selectedIdx: int = tabbedViewContainer.get_tab_idx_from_control(selectedTab)
		var direction: int = -1 if event.is_action_pressed('game_tab_left') else 1
		# if going to a tab that's hidden; jump one more instead
		if (selectedIdx + direction == TabbedViewTab.NEW_MOVES and not newMovesPanel.visible) \
				or (selectedIdx + direction == TabbedViewTab.BATTLE_BOOSTS and not battleBoostsPanel.visible):
			direction *= 2
		# get next filter button to the left (negative)/right (positive) that's not disabled (wrapping around)
		var newTabIdx: int = wrapi(selectedIdx + direction, 0, tabbedViewContainer.get_tab_count())
		var newTab: Control = tabbedViewContainer.get_tab_control(newTabIdx)
		if newTab != null:
			selectedTab.visible = false
			newTab.visible = true
			initial_focus()

func toggle():
	visible = not visible
	if visible:
		load_stats_panel(true)
		initial_focus()
	else:
		close_panel()

func close_panel():
	close_minion_stats_auto_alloc()
	visible = false
	levelUpAnimPlayed = false
	equipmentPanel.itemDetailsPanel.visible = false
	moveListPanel.moveDetailsPanel.visible = false
	editMovesPanel.reset_menu_state(false)
	editMovesPanel.visible = false
	minionsPanel.end_edit_name(false)
	minionsPanel.reset_reorder_state()
	backButton.disabled = false
	tabbedViewContainer.current_tab = TabbedViewTab.STATS
	savedStats = null
	minion = null
	previousControl = null
	# if the level up music is currently playing and this is in the overworld, fade the overworld theme back in after fading out the level up music
	if SceneLoader.audioHandler.is_music_already_playing(levelUpLoopMusic) and PlayerFinder.player != null and SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapEntry != null:
		SceneLoader.audioHandler.fade_out_music()
		# fade_in_new_music will wait for the fadeout to complete before fading back in
		SceneLoader.audioHandler.fade_in_new_music(SceneLoader.mapLoader.mapEntry.overworldTheme, -1, 0.5)
	back_pressed.emit()

func initial_focus():
	tabbedViewContainer.get_tab_bar().grab_focus()

func restore_previous_focus():
	if previousControl == null:
		if previousMoveListSlot == -1:
			initial_focus()
		else:
			moveListPanel.get_move_list_item(previousMoveListSlot).detailsButton.grab_focus()
			previousMoveListSlot = -1
	else:
		previousControl.grab_focus()

func load_stats_panel(fromToggle: bool = false):
	if stats == null:
		return
	
	var playingLvUpAnim: bool = false
	if fromToggle:
		tabbedViewContainer.current_tab = TabbedViewTab.STATS # auto-select Stats when opening menu
	
	if fromToggle and levelUp and not levelUpAnimPlayed:
		levelUpAnimPlayer.play('level_up')
		levelUpAnimPlayed = true
		newLevelLabel.text = '[center]Level ' + String.num_int64(stats.level) + '![/center]'
		playingLvUpAnim = true
		levelUpAnimPlaying = true
	else:
		levelUpPanel.visible = false
	
	tabbedViewPanel.visible = not playingLvUpAnim
	
	var dispName: String = stats.displayName
	if minion != null:
		dispName = minion.disp_name()
	
	var combatantSprite: CombatantSprite = PlayerResources.playerInfo.combatant.get_sprite_obj()
	var spriteFrames: SpriteFrames = PlayerResources.playerInfo.combatant.get_sprite_frames()
	if minion != null:
		combatantSprite = minion.get_sprite_obj()
		spriteFrames = minion.get_sprite_frames()
	
	# scale sprite 3x if max size in max dimension is [16, 32); [32, 48] scale 2x; (48, infinity) scale 1x
	var spriteScale: float = 3.0
	if combatantSprite != null:
		var maxSizeDim: float = max(combatantSprite.maxSize.x, combatantSprite.maxSize.y)
		if maxSizeDim >= 32.0:
			spriteScale = 2.0
		if maxSizeDim > 48.0:
			spriteScale = 1.0
	
	tabbedViewCombatantSprite.sprite_frames = spriteFrames
	tabbedViewCombatantSprite.scale = Vector2.ONE * spriteScale
	tabbedViewCombatantSprite.play('walk')
	
	statsTitle.text = '[center]' + dispName + ' - Stats[/center]'
	levelUpLabel.visible = levelUp
	statlinePanel.stats = stats
	statlinePanel.curHp = curHp
	statlinePanel.readOnly = readOnly
	statlinePanel.levelUp = levelUp
	statlinePanel.newLvs = newLvs
	statlinePanel.load_statline_panel(changingCombatant or fromToggle)
	update_stats_tab_icon()
	moveListPanel.moves = stats.moves
	moveListPanel.movepool = stats.movepool.pool
	moveListPanel.readOnly = readOnly
	moveListPanel.level = stats.level
	moveListPanel.levelUp = levelUp
	moveListPanel.showNewMoveIndicator = levelUp and minion.stats.movepool.has_moves_at_level(minion.stats.level) \
			if minion != null else false
	moveListPanel.load_move_list_panel()
	#print('stats ', stats, ' / ', minion.stats)
	if moveListPanel.firstMovePanel != null:
		var tabBar: TabBar = tabbedViewContainer.get_tab_bar()
		moveListPanel.firstMovePanel.set_buttons_top_neighbor(moveListPanel.firstMovePanel.detailsButton.get_path_to(tabBar))
		if not moveListPanel.editMovesButton.visible:
			moveListPanel.lastMovePanel.set_buttons_bottom_neighbor(moveListPanel.lastMovePanel.detailsButton.get_path_to(backButton))
	equipmentPanel.weapon = stats.equippedWeapon
	equipmentPanel.armor = stats.equippedArmor
	equipmentPanel.statsPanel = self
	equipmentPanel.load_equipment_panel()
	minionsPanel.minion = minion
	minionsPanel.readOnly = readOnly
	minionsPanel.levelUp = levelUp
	minionsPanel.load_minions_panel()
	
	battleBoostsPanel.inBattle = inBattle
	battleBoostsPanel.levelUp = levelUp
	battleBoostsPanel.load_battle_boosts_panel()
	tabbedViewContainer.set_tab_hidden(TabbedViewTab.BATTLE_BOOSTS, not battleBoostsPanel.visible)
	
	newMovesPanel.levelUp = levelUp
	if minion == null:
		newMovesPanel.load_new_moves_panel()
	else:
		newMovesPanel.visible = false
	tabbedViewContainer.set_tab_hidden(TabbedViewTab.NEW_MOVES, not newMovesPanel.visible)
	
	update_move_list_tab_icon()
	var minionsCtrl: Control = tabbedViewContainer.get_tab_control(TabbedViewTab.MINIONS)
	if minion != null:
		minionsCtrl.name = minion.disp_name()
	else:
		minionsCtrl.name = 'Minions'
	update_minions_tab()
	#minionsPanel.call_deferred('connect_to_bottom_control', tabbedViewBackButton)
	changingCombatant = false

func restore_previous_stats_panel():
	close_minion_stats_auto_alloc()
	stats = savedStats
	minion = null
	curHp = savedCurHp
	isPlayer = savedIsPlayer
	isMinionStats = false
	changingCombatant = true
	load_stats_panel()
	tabbedViewContainer.current_tab = TabbedViewTab.MINIONS
	restore_previous_focus()

func close_minion_stats_auto_alloc() -> void:
	# if the player changed the minion to auto-allocate its stat points and then backed out before saving stat allocs:
	if minion != null and minion.should_auto_alloc_stat_pts() and minion.stats.statPts > 0:
		var statAllocStrategy: StatAllocationStrategy = minion.get_stat_allocation_strategy()
		# if there is a stat allocation strategy (safety test): auto-allocate stat points
		if statAllocStrategy != null:
			statAllocStrategy.allocate_stats(minion.stats)

func update_stats_tab_icon():
	var statsIcon: Texture2D = unspentStatPtsIndicator
	if stats.statPts == 0:
		statsIcon = null
	tabbedViewContainer.set_tab_icon(TabbedViewTab.STATS, statsIcon)

func update_move_list_tab_icon():
	var moveListIcon: Texture2D = null
	if moveListPanel.showNewMoveIndicator:
		moveListIcon = newMoveIndicator
	tabbedViewContainer.set_tab_icon(TabbedViewTab.MOVES, moveListIcon)

func update_minions_tab():
	var minionsTabIcon: Texture2D = null
	var minionChanged: bool = false
	var minionHasNewMoves: bool = false
	var minionHasUnspentStatPts: bool = false
	if minion == null:
		minionsControl.name = 'Minions'
		for m: Combatant in PlayerResources.minions.get_minion_list():
			if PlayerResources.minions.is_minion_marked_changed(m.save_name()):
				minionChanged = true
				break
			if m.stats.movepool.has_moves_at_level(m.stats.level) and levelUp:
				minionHasNewMoves = true
			elif m.stats.statPts > 0:
				minionHasUnspentStatPts = true
	else:
		minionsControl.name = minion.disp_name()
		# currently not showing any icons over the Minions tab
		#if PlayerResources.minions.is_minion_marked_changed(minion.save_name()):
		#	minionChanged = true
		#elif minion.stats.movepool.has_moves_at_level(minion.stats.level) and levelUp:
		#	minionHasNewMoves = true
		#elif minion.stats.statPts > 0:
		#	minionHasUnspentStatPts = true
		# unspent stat points are apparent on the Stats tab
	
	if minionChanged:
		minionsTabIcon = minionChangedIndicator
	elif minionHasNewMoves:
		minionsTabIcon = newMoveIndicator
	elif minionHasUnspentStatPts:
		minionsTabIcon = unspentStatPtsIndicator
	tabbedViewContainer.set_tab_icon(TabbedViewTab.MINIONS, minionsTabIcon)

func reset_panel_to_player():
	if isMinionStats:
		restore_previous_stats_panel()

func _on_back_button_pressed():
	if not isMinionStats or savedStats == null:
		toggle()
		if SceneLoader.audioHandler.is_music_already_playing(levelUpMusic):
			if SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapEntry != null:
				SceneLoader.audioHandler.cross_fade(SceneLoader.mapLoader.mapEntry.overworldTheme, -1)
			else:
				SceneLoader.audioHandler.cross_fade(null) # fade out the track
	else:
		restore_previous_stats_panel()

func _on_stat_line_panel_stats_saved() -> void:
	update_stats_tab_icon()

func _on_move_list_panel_move_details_visiblity_changed(newVisible: bool, move: Move):
	backButton.disabled = newVisible
	if newVisible:
		previousMoveListSlot = moveListPanel.get_index_of_move(move)
		previousControl = null
	else:
		restore_previous_focus()

func _on_minions_panel_stats_clicked(combatant: Combatant):
	previousControl = minionsPanel.get_stats_button_for(combatant)
	savedStats = stats
	savedCurHp = curHp
	savedIsPlayer = isPlayer
	if combatant != null and combatant.stats != null:
		minion = combatant
		stats = combatant.stats
		curHp = -1
		isPlayer = false
		isMinionStats = true
		changingCombatant = true
		load_stats_panel()
		tabbedViewContainer.current_tab = TabbedViewTab.STATS
		initial_focus()

func _on_minions_panel_minion_renamed() -> void:
	var minionsCtrl: Control = tabbedViewContainer.get_tab_control(TabbedViewTab.MINIONS)
	minionsCtrl.name = minion.disp_name()

func _on_minions_panel_changed_minion_hovered(combatant: Combatant) -> void:
	if PlayerResources.minions.is_minion_marked_changed(combatant.save_name()):
		PlayerResources.minions.clear_minion_changed(combatant.save_name())
		update_minions_tab()

func _on_minions_panel_minion_auto_alloc_changed(combatant: Combatant) -> void:
	# the minion changed should never not be the minion being inspected, but just in case, do nothing
	# same is true with the stats copy being empty
	if minion != combatant or statlinePanel.statsCopy == null:
		return
	if statlinePanel.statsCopy.statPts > 0 and combatant.should_auto_alloc_stat_pts():
		var statAllocStrategy: StatAllocationStrategy = combatant.get_stat_allocation_strategy()
		if statAllocStrategy != null:
			# allocate to the statlinePanel's stats copy
			statAllocStrategy.allocate_stats(statlinePanel.statsCopy)
			# reload the statline panel with it appearing as modified (not auto-confirming it just in case the player doesn't want it)
			statlinePanel.modified = true
			statlinePanel.load_statline_panel()
		else:
			printerr('Minion ', combatant.save_name(), ' has no defined stat allocation strategy and is being auto-allocated after setting was switched')

func _on_minions_panel_minions_reordered() -> void:
	pass

func _on_move_list_panel_edit_moves():
	previousControl = moveListPanel.editMovesButton
	editMovesPanel.moves = stats.moves
	editMovesPanel.movepool = stats.movepool.pool
	editMovesPanel.level = stats.level
	editMovesPanel.levelUp = levelUp
	editMovesPanel.load_edit_moves_panel()
	backButton.disabled = true

func _on_edit_moves_panel_back_pressed():
	backButton.disabled = false
	restore_previous_focus()
	previousControl = null

func _on_edit_moves_panel_replace_move(slot: int, newMove: Move):
	if slot >= len(stats.moves):
		for i in range(4):
			if slot == i:
				stats.moves.append(newMove)
			elif i >= len(stats.moves):
				stats.moves.append(null)
	else:
		stats.moves[slot] = newMove
	editMovesPanel.movePoolPanel.moves = stats.moves
	editMovesPanel.load_edit_moves_panel(true, false)
	load_stats_panel()

func _on_equipment_panel_attempt_equip_weapon():
	if not readOnly:
		pass #attempt_equip_weapon_to.emit(stats)

func _on_equipment_panel_attempt_equip_armor():
	if not readOnly:
		pass #attempt_equip_armor_to.emit(stats)

func _on_inventory_panel_node_open_stats(combatant: Combatant):
	stats = combatant.stats
	if combatant == PlayerResources.playerInfo.combatant:
		isPlayer = true
		isMinionStats = false
	else:
		isPlayer = false
		isMinionStats = true
		minion = combatant
	curHp = combatant.currentHp
	toggle()

func _tab_selected(idx: int) -> void:
	if idx >= 0 and idx < TabbedViewTab.TAB_COUNT and visible:
		SceneLoader.audioHandler.play_sfx(tabChangeSfx)

func _settings_changed() -> void:
	pass

func _level_up_anim_start():
	SceneLoader.audioHandler.play_music(levelUpMusic)
	SceneLoader.audioHandler.music_playback_complete.connect(_level_up_loop_music)
	levelUpPanel.visible = true

func _level_up_anim_panel_fade_in():
	var view: Panel = tabbedViewPanel
	var levelUpTween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	view.visible = true
	view.modulate = Color(1, 1, 1, 0)
	levelUpTween.tween_property(view, 'modulate', Color(1, 1, 1, 1), 2.1)
	levelUpTween.tween_callback(initial_focus)

func _level_up_loop_music():
	SceneLoader.audioHandler.play_music(levelUpLoopMusic, -1)
	SceneLoader.audioHandler.music_playback_complete.disconnect(_level_up_loop_music)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'level_up':
		levelUpAnimPlaying = false
