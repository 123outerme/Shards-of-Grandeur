class_name CombatantAiLayerBase
extends Resource

## the amount of weight this layer has on the final decision of the AI
@export var weight: float = 1.0

func _init(i_weight: float = 1.0):
	weight = i_weight

func copy(copyStorage: bool = false) -> CombatantAiLayerBase:
	return CombatantAiLayerBase.new(weight)
