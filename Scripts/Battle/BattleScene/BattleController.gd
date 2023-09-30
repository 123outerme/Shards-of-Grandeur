extends Node2D

@export var state: BattleState = BattleState.new()

@onready var combatantNodes: Array[Node] = get_tree().get_nodes_in_group("CombatantNode")
@onready var playerCombatant: CombatantNode = get_node("TileMap/PlayerCombatant")
@onready var minionCombatant: CombatantNode = get_node("TileMap/MinionCombatant")
@onready var enemyCombatant1: CombatantNode = get_node("TileMap/EnemyCombatant1")
@onready var enemyCombatant2: CombatantNode = get_node("TileMap/EnemyCombatant2")
@onready var enemyCombatant3: CombatantNode = get_node("TileMap/EnemyCombatant3")

# Called when the node enters the scene tree for the first time.
func _ready():
	if not PlayerResources.loaded:
		SaveHandler.load_data()
	
	playerCombatant.combatant = PlayerResources.playerInfo.combatant
	playerCombatant.leftSide = true
	playerCombatant.spriteFacesRight = true
	playerCombatant.role = CombatantNode.Role.ALLY
	
	minionCombatant.combatant = null
	minionCombatant.leftSide = true
	minionCombatant.role = CombatantNode.Role.ALLY
	
	enemyCombatant1.combatant = Combatant.load_combatant_resource(PlayerResources.playerInfo.encounteredName)
	enemyCombatant1.role = CombatantNode.Role.ENEMY
	
	var eCombatant2Idx: int = WeightedThing.pick_item(enemyCombatant1.combatant.teamTable)
	if enemyCombatant1.combatant.teamTable[eCombatant2Idx].string != '':
		enemyCombatant2.combatant = Combatant.load_combatant_resource(enemyCombatant1.combatant.teamTable[eCombatant2Idx].string)
	else:
		enemyCombatant2.combatant = null
	enemyCombatant2.role = CombatantNode.Role.ENEMY
	
	var eCombatant3Idx: int = WeightedThing.pick_item(enemyCombatant1.combatant.teamTable)
	if enemyCombatant1.combatant.teamTable[eCombatant3Idx].string != '':
		enemyCombatant3.combatant = Combatant.load_combatant_resource(enemyCombatant1.combatant.teamTable[eCombatant3Idx].string)
	else:
		enemyCombatant3.combatant = null
	enemyCombatant3.leftSide = false
	enemyCombatant3.role = CombatantNode.Role.ENEMY
		
	for node in combatantNodes:
		node.load_combatant_node()
