extends Area2D
class_name Interactable

@export var saveName: String = ''
@export var interactPriority: int = 0
@export var dialogue: InteractableDialogue = null
@export var interactSfx: AudioStream = null

func interact(args: Array = []):
	PlayerFinder.player.interact_interactable(self)
	if interactSfx != null:
		SceneLoader.audioHandler.play_sfx(interactSfx)

func enter_player_range():
	var idx: int = PlayerFinder.player.interactables.find(self)
	if idx == -1:
		PlayerFinder.player.interactables.append(self)

func exit_player_range():
	var idx: int = PlayerFinder.player.interactables.find(self)
	if idx != -1:
		PlayerFinder.player.interactables.remove_at(idx)
	if PlayerFinder.player.interactable == self:
		PlayerFinder.player.interactable = null

func select_choice(choice: DialogueChoice):
	if choice.repeatsItem:
		PlayerFinder.player.put_interactable_dialogue()
		return
	
	if choice.leadsTo != null:
		if choice.leadsTo.can_use_dialogue():
			var index: int = PlayerFinder.player.interactableDialogues.find(choice.leadsTo, 0)
			if index != -1: # reuse entry if it exists to support going back in the dialogue tree
				PlayerFinder.player.interactableDialogueIdx = index
				PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIdx].savedItemIdx = 0
				PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIdx].savedTextIdx = 0
				PlayerFinder.player.put_interactable_dialogue()
			else:
				index = mini(PlayerFinder.player.interactableDialogueIdx + 1, len(PlayerFinder.player.interactableDialogues))
				PlayerFinder.player.interactableDialogues.insert(index, choice.leadsTo)
				PlayerFinder.player.put_interactable_dialogue(true)

func finished_dialogue():
	pass
