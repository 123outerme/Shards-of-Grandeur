extends Control
class_name ShardLearnPanel

signal learned_move(move: Move)
signal evolution_switched(evo: Evolution)
signal back_pressed

@export var shard: Shard = null

var combatant: Combatant = null
var evolution: Evolution = null
var inTutorial: bool = false
var evolutionListItemPanel = load('res://prefabs/ui/inventory/evolution_list_item_panel.tscn')

@onready var shardSprite: Sprite2D = get_node("Panel/ShardSpriteControl/ShardSprite")
@onready var learnPanelTitle: RichTextLabel = get_node("Panel/LearnPanelTitle")
@onready var movePoolPanel: MovePoolPanel = get_node("Panel/MovePoolPanel")
@onready var evolutionScrollContainer: ScrollContainer = get_node('Panel/EvolutionScrollContainer')
@onready var evoHboxContainer: HBoxContainer = get_node('Panel/EvolutionScrollContainer/EvolutionHboxContainer')
@onready var moveDetailsPanel: MoveDetailsPanel = get_node("MoveDetailsPanel")
@onready var backButton: Button = get_node("Panel/BackButton")

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline") and not backButton.disabled:
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
	if visible and evolutionScrollContainer.visible and (event.is_action_pressed('game_tab_left') or event.is_action_pressed('game_tab_right')):
		get_viewport().set_input_as_handled()
		var evolutionPanels: Array[Node] = evoHboxContainer.get_children()
		var selectedEvolutionPanelIdx: int = -1
		for panelIdx: int in range(len(evolutionPanels)):
			var panel: Node = evolutionPanels[panelIdx]
			if panel != null and panel is EvolutionListItemPanel:
				if panel.evolution == evolution:
					selectedEvolutionPanelIdx = panelIdx
					break
		
		if selectedEvolutionPanelIdx != -1:
			var direction: int = -1 if event.is_action_pressed('game_tab_left') else 1
			var newIdx: int = wrapi(selectedEvolutionPanelIdx + direction, 0, len(evolutionPanels))
			var newPanel: EvolutionListItemPanel = null
			while selectedEvolutionPanelIdx != newIdx:
				if evolutionPanels[newIdx] != null and evolutionPanels[newIdx] is EvolutionListItemPanel:
					newPanel = evolutionPanels[newIdx] as EvolutionListItemPanel
					_on_evolution_list_item_panel_selected(newPanel)
					break
				newIdx = wrapi(newIdx + direction, 0, len(evolutionPanels))
			if newPanel != null:
				newPanel.selectButton.grab_focus()

func initial_focus():
	if movePoolPanel.firstMovePanel != null:
		if movePoolPanel.firstMovePanel.learnButton.visible:
			movePoolPanel.firstMovePanel.learnButton.grab_focus()
		else:
			movePoolPanel.firstMovePanel.detailsButton.grab_focus()
	else:
		backButton.grab_focus()

func load_shard_learn_panel(initialFocus: bool = true, loadEvolutions: bool = true):
	if shard == null:
		visible = false
		return
	
	# initialize combatant
	combatant = PlayerResources.minions.get_minion(shard.combatantSaveName)
	if combatant == null:
		# backup strategy: initialize a new combatant for this task
		combatant = Combatant.load_combatant_resource(shard.combatantSaveName)
		combatant.stats.level = PlayerResources.playerInfo.combatant.stats.level
		combatant.validate_evolution_stats()
	if combatant == null:
		push_error('ShardLearnPanel ERROR: Combatant for shard ', shard.itemName, ' failed to be instantiated.')
		visible = false
		return
	shardSprite.texture = shard.itemSprite
	var combatantName: String = combatant.disp_name()
	if combatant.nickname == '':
		var evoStats: Stats = combatant.get_evolution_stats(evolution)
		combatantName = evoStats.displayName
	learnPanelTitle.text = '[center]Learn a Move From ' + combatantName + '[/center]'
	
	# initialize move pool panel
	movePoolPanel.moves = combatant.get_evolution_stats(evolution).moves
	movePoolPanel.movepool = combatant.get_evolution_stats(evolution).movepool.pool
	movePoolPanel.level = PlayerResources.playerInfo.combatant.stats.level
	movePoolPanel.load_move_pool_panel()
	movePoolPanel.show_learn_buttons(true)
	movePoolPanel.connect_bottom_panel_buttons_focus_bottom_to.call_deferred(backButton)
	
	# initialize known evolutions
	if combatant.evolutions != null:
		evolutionScrollContainer.visible = true
		if loadEvolutions:
			for panel: Node in evoHboxContainer.get_children():
				panel.queue_free()
			
			var evolutionsFound: Array[String] = []
			for foundEvo: String in PlayerResources.playerInfo.evolutionsFound:
				if foundEvo.begins_with(shard.combatantSaveName + '#'):
					evolutionsFound.append(foundEvo.split('#')[1])
			if len(evolutionsFound) > 0:
				var evoList: Array[Evolution] = [null]
				var lastPanel: EvolutionListItemPanel = null
				evoList.append_array(combatant.evolutions.evolutionList)
				for evo: Evolution in evoList:
					if evo == null or evo.evolutionSaveName in evolutionsFound:
						# initialize item panel
						var evoItemPanel: EvolutionListItemPanel = evolutionListItemPanel.instantiate()
						evoItemPanel.combatant = combatant
						evoItemPanel.evolution = evo
						evoItemPanel.evolution_selected.connect(_on_evolution_list_item_panel_selected)
						evolution_switched.connect(evoItemPanel._on_evolution_switched)
						evoHboxContainer.add_child(evoItemPanel)
						_deferred_evo_list_item_panel_connect.call_deferred(evoItemPanel, lastPanel)
						lastPanel = evoItemPanel
			else:
				# no evolutions known
				evolutionScrollContainer.visible = false
		else:
			# not reloading evolution panels; reconnect panels to new top move panel
			var lastPanel: EvolutionListItemPanel = null
			for panel: Node in evoHboxContainer.get_children():
				var evoItemPanel: EvolutionListItemPanel = panel as EvolutionListItemPanel
				_deferred_evo_list_item_panel_connect.call_deferred(evoItemPanel, lastPanel)
				lastPanel = evoItemPanel
	else:
		# evolutions is null; no evos known by default
		evolutionScrollContainer.visible = false
	
	backButton.disabled = inTutorial and movePoolPanel.get_learnable_move_count() > 0
	if initialFocus:
		initial_focus.call_deferred()
	visible = true

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

func _on_move_pool_panel_learn_button_clicked(move: Move):
	visible = false
	learned_move.emit(move)

func _on_move_pool_panel_details_button_clicked(move):
	moveDetailsPanel.move = move
	moveDetailsPanel.load_move_details_panel()

func _on_move_details_panel_back_pressed():
	var focusGrabbed: bool = movePoolPanel.focus_move_details(moveDetailsPanel.move)
	if not focusGrabbed:
		backButton.grab_focus()

func _deferred_evo_list_item_panel_connect(evoItemPanel: EvolutionListItemPanel, lastPanel: EvolutionListItemPanel) -> void:
	evoItemPanel.selectButton.button_pressed = evoItemPanel.evolution == evolution
	
	movePoolPanel.firstMovePanel.learnButton.focus_neighbor_top = movePoolPanel.firstMovePanel.learnButton.get_path_to(evoItemPanel.selectButton)
	evoItemPanel.selectButton.focus_neighbor_bottom = evoItemPanel.selectButton.get_path_to(movePoolPanel.firstMovePanel.learnButton)
	evoItemPanel.selectButton.focus_neighbor_right = '.'
	evoItemPanel.selectButton.focus_neighbor_top = evoItemPanel.selectButton.get_path_to(backButton)
	if evolution == evoItemPanel.evolution:
		movePoolPanel.firstMovePanel.detailsButton.focus_neighbor_top = movePoolPanel.firstMovePanel.detailsButton.get_path_to(evoItemPanel.selectButton)
		movePoolPanel.firstMovePanel.learnButton.focus_neighbor_top = movePoolPanel.firstMovePanel.learnButton.get_path_to(evoItemPanel.selectButton)
		backButton.focus_neighbor_top = backButton.get_path_to(evoItemPanel.selectButton)
	if lastPanel != null:
		evoItemPanel.selectButton.focus_neighbor_left = evoItemPanel.selectButton.get_path_to(lastPanel.selectButton)
		lastPanel.selectButton.focus_neighbor_right = lastPanel.selectButton.get_path_to(evoItemPanel.selectButton)
	else:
		evoItemPanel.selectButton.focus_neighbor_left = '.'

func _on_evolution_list_item_panel_selected(panel: EvolutionListItemPanel) -> void:
	evolution = panel.evolution
	load_shard_learn_panel(false, false)
	evolution_switched.emit(evolution)
