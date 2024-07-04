extends Area2D
class_name Interactable

## unique ID for preserving dialogue in progress when save + quitting
@export var saveName: String = ''
## higher == better
@export var interactPriority: int = 0
## dialogue to show when the player interacts with this Interactable
@export var dialogue: InteractableDialogue = null
## sfx to play when the player interacts with this Interactable
@export var interactSfx: AudioStream = null

func interact(_args: Array = []):
	var interactableDialogue: InteractableDialogue = null
	if len(_args) > 0:
		if _args[0] is InteractableDialogue:
			interactableDialogue = _args[0]
	
	PlayerFinder.player.interact_interactable(self, interactableDialogue)
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

func play_animation(animName: String):
	pass

func select_choice(choice: DialogueChoice):
	if choice.repeatsItem:
		PlayerFinder.player.put_interactable_text(false, false)
		return
	
	var leadsTo: DialogueEntry = null
	if choice.returnsToParentId != '':
		var parentIdx: int = -1
		for dialogueIdx: int in range(len(PlayerFinder.player.interactableDialogues)):
			var interDialogue: InteractableDialogue = PlayerFinder.player.interactableDialogues[dialogueIdx]
			if interDialogue.dialogueEntry.entryId == choice.returnsToParentId:
				parentIdx = dialogueIdx
				break
		if parentIdx > -1:
			# remove all dialogues that came after this one and make it the "leadsTo" dialogue for use below
			PlayerFinder.player.interactableDialogues = PlayerFinder.player.interactableDialogues.slice(0, parentIdx + 1)
			leadsTo = PlayerFinder.player.interactableDialogues[parentIdx].dialogueEntry
	
	if leadsTo == null and choice.randomDialogues != null and len(choice.randomDialogues) > 0:
		var randomDialogues: Array[WeightedDialogueEntry] = []
		var sumWeights: float = 0
		for dialogue in choice.randomDialogues:
			if dialogue.dialogueEntry.can_use_dialogue():
				randomDialogues.append(dialogue)
				sumWeights += dialogue.weight
		
		var randomIdx: int = WeightedThing.pick_item(randomDialogues, sumWeights)
		if randomIdx > -1:
			leadsTo = randomDialogues[randomIdx].dialogueEntry
	
	if leadsTo == null:
		leadsTo = choice.leadsTo
	
	if leadsTo != null:
		if leadsTo.can_use_dialogue():
			var index: int = -1
			for dialogueIdx: int in range(len(PlayerFinder.player.interactableDialogues)):
				var interDialogue: InteractableDialogue = PlayerFinder.player.interactableDialogues[dialogueIdx]
				if interDialogue.dialogueEntry == leadsTo:
					index = dialogueIdx
					break
					
			if index != -1: # reuse entry if it exists to support going back in the dialogue tree
				PlayerFinder.player.interactableDialogueIdx = index
				PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIdx].savedItemIdx = 0
				PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIdx].savedTextIdx = 0
				PlayerFinder.player.put_interactable_text(false, true)
			else:
				index = mini(PlayerFinder.player.interactableDialogueIndex + 1, len(PlayerFinder.player.interactableDialogues))
				var newInterDialogue: InteractableDialogue = InteractableDialogue.new()
				newInterDialogue.dialogueEntry = leadsTo
				newInterDialogue.speaker = dialogue.speaker
				PlayerFinder.player.interactableDialogues.insert(index, newInterDialogue)
				PlayerFinder.player.put_interactable_text(true)

func finished_dialogue():
	pass
