class_name NewMovesPanel
extends Control

@export var levelUp: bool = false
@export var tabControl: Control = null
@export var backButton: Button = null

var newMoveListItemPanel: PackedScene = preload('res://prefabs/ui/stats/new_move_list_item_panel.tscn')
var lastFocusedPanel: NewMoveListItemPanel = null
var panelsByMove: Dictionary[Move, Array] = {}

@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollBetterFollow/VBoxContainer')

@onready var moveDetailsPanel: MoveDetailsPanel = get_node('MoveDetailsPanel')
@onready var itemUsePanel: ItemUsePanel = get_node('ItemUsePanel')

func load_new_moves_panel() -> void:
	if not levelUp:
		visible = false
		return
	visible = true
	
	for child: Node in vboxContainer.get_children():
		child.visible = false
		child.queue_free()
	
	
	var panels: Array[NewMoveListItemPanel] = []
	for minion: Combatant in PlayerResources.minions.get_minion_list():
		var minionMoves: Array[Move] = get_new_moves(minion.stats.movepool)
		var moveEvolutions: Array[Evolution] = []
		for move: Move in minionMoves:
			moveEvolutions.append(null)
		
		for evolution: Evolution in minion.evolutions.evolutionList:
			# if the player hasn't discovered this evolution yet: don't give them a hint
			if not PlayerResources.playerInfo.has_found_evolution(minion.save_name() + '#' + evolution.evolutionSaveName):
				continue
			
			var evoMoves: Array[Move] = get_new_moves(evolution.stats.movepool)
			for move: Move in evoMoves:
				if not (move in minionMoves):
					minionMoves.append(move)
					moveEvolutions.append(evolution)
		
		for moveIdx: int in range(len(minionMoves)):
			var move: Move = minionMoves[moveIdx]
			var panel: NewMoveListItemPanel = newMoveListItemPanel.instantiate()
			panel.combatant = minion
			panel.evolution = moveEvolutions[moveIdx]
			panel.move = move
			if not panelsByMove.has(move):
				panelsByMove[move] = []
			panelsByMove[move].append(panel)
			panel.details_pressed.connect(_panel_details_pressed)
			panel.learn_pressed.connect(_panel_learn_pressed)
			panels.append(panel)
	
	if len(panels) == 0:
		visible = false
		return
	
	var lastPanel: NewMoveListItemPanel = null
	panels.sort_custom(_sort_panels_by_move_alphabetically)
	for panel: NewMoveListItemPanel in panels:
		vboxContainer.add_child(panel)
		panel.call_deferred('load_new_move_list_item_panel')
		panel.call_deferred('connect_panel_focus_neighbors', lastPanel)
		lastPanel = panel
	
	if lastPanel != null:
		lastPanel.detailsButton.focus_neighbor_bottom = lastPanel.detailsButton.get_path_to(backButton)
		lastPanel.learnButton.focus_neighbor_bottom = lastPanel.learnButton.get_path_to(backButton)

func get_new_moves(movepool: MovePool) -> Array[Move]:
	var newMoves: Array[Move] = []
	for move: Move in movepool.pool:
		if move.requiredLv == PlayerResources.playerInfo.combatant.stats.level:
			newMoves.append(move)
	return newMoves

func _panel_details_pressed(panel: NewMoveListItemPanel) -> void:
	lastFocusedPanel = panel
	moveDetailsPanel.move = panel.move
	moveDetailsPanel.load_move_details_panel()

func _panel_learn_pressed(panel: NewMoveListItemPanel) -> void:
	lastFocusedPanel = panel
	# load the item use panel
	itemUsePanel.item = lastFocusedPanel.combatantShardSlot.item
	itemUsePanel.learnedMove = lastFocusedPanel.move
	itemUsePanel.learnedFromEvolution = lastFocusedPanel.evolution
	itemUsePanel.load_item_use_panel()
	# after loading: process learning the move, etc.
	var playerCombatant: Combatant = PlayerResources.playerInfo.combatant
	playerCombatant.stats.add_move_to_pool(itemUsePanel.learnedMove)
	# if the player is in an evolution right now, also add this move to the base form stats for keeping track of learned moves
	if playerCombatant.get_evolution() != null:
		playerCombatant.get_evolution_stats(null).stats.add_move_to_pool(itemUsePanel.learnedMove)
	
	var shard: Shard = lastFocusedPanel.combatantShardSlot.item as Shard
	# add Attunement for minion whose shard you used
	PlayerResources.minions.add_friendship(shard.combatantSaveName)
	PlayerResources.inventory.trash_item(lastFocusedPanel.combatantShardSlot)
	
	# for each panel that can teach this same move: reload it
	for movePanel: NewMoveListItemPanel in panelsByMove[panel.move]:
		movePanel.hide_learn_button() # hide the learn button because we've already learned this move
		movePanel.load_new_move_list_item_panel() # reload the panel display

func _on_move_details_panel_back_pressed() -> void:
	lastFocusedPanel.detailsButton.grab_focus()
	lastFocusedPanel = null

func _on_shard_learn_panel_back_pressed() -> void:
	lastFocusedPanel.learnButton.grab_focus()
	lastFocusedPanel = null

func _on_item_use_panel_ok_pressed() -> void:
	if lastFocusedPanel != null:
		lastFocusedPanel.detailsButton.grab_focus()
	else:
		tabControl.grab_focus()
	lastFocusedPanel = null

func _sort_panels_by_move_alphabetically(a: NewMoveListItemPanel, b: NewMoveListItemPanel) -> bool:
	return a.move.moveName.naturalnocasecmp_to(b.move.moveName) <= 0
