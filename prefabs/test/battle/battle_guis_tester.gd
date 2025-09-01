extends Node2D

@export var encounter: EnemyEncounter = null
@export var battleState: BattleState = null
@export var playerCombatant: Combatant = null
@export var mapEntry: MapEntry = null
@export var map: String = ''

@export var playerOrbs: int = 0
@export var minionOrbs: int = 0
@export var enemyCombatant1Orbs: int = 0
@export var enemyCombatant2Orbs: int = 0
@export var enemyCombatant3Orbs: int = 0

@onready var battle: BattleController = get_node('Battle')
@onready var audioHandler: AudioHandler = get_node('AudioHandler')

func _ready():
	SceneLoader.audioHandler = audioHandler
	playerCombatant.orbs = playerOrbs
	PlayerResources.playerInfo.combatant = playerCombatant
	PlayerResources.playerInfo.encounter = encounter
	PlayerResources.playerInfo.map = map
	SceneLoader.curMapEntry = mapEntry
	battleState.minionCombatant.orbs = minionOrbs
	battleState.enemyCombatant1.orbs = enemyCombatant1Orbs
	battleState.enemyCombatant2.orbs = enemyCombatant2Orbs
	battleState.enemyCombatant3.orbs = enemyCombatant3Orbs
	battle.state = battleState
	battle.load_into_battle(false)
