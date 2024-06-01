extends KeyItem
class_name TeleportStone

const DISABLE_IF_VALID_REQUIREMENTS: Array[StoryRequirements] = [
	preload('res://gamedata/story_requirements/main_story/act1/etreus_fight1_done.tres')
]

@export var targetMap: String = ''
@export var targetPos: Vector2 = Vector2()

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.KEY_ITEM,
	i_itemDescription = "",
	i_cost = 50,
	i_maxCount = 2,
	i_usable = true,
	i_battleUsable = false,
	i_consumable = true,
	i_equippable = false,
	i_targets = BattleCommand.Targets.SELF,
	i_keyItemType = KeyItem.KeyItemType.TELEPORT_STONE,
	i_useMsg = '',
	i_effectText = '',
	i_targetMap = '',
	i_targetPos = Vector2(),
):
	super(
		i_sprite,
		i_name,
		i_type,
		i_itemDescription,
		i_cost,
		i_maxCount,
		i_usable,
		i_battleUsable,
		i_consumable,
		i_equippable,
		i_targets,
		i_keyItemType,
		i_useMsg,
		i_effectText)
	targetMap = i_targetMap
	targetPos = i_targetPos

func use(_target: Combatant):
	PlayerFinder.player.useTeleportStone = self

func can_be_used_now() -> bool:
	for requirement: StoryRequirements in DISABLE_IF_VALID_REQUIREMENTS:
		if requirement.is_valid():
			return false
	
	return PlayerResources.playerInfo.map != targetMap
