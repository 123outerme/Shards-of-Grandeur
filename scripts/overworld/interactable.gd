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

func has_dialogue() -> bool:
	return dialogue != null and dialogue.can_use_dialogue()

func enter_player_range():
	var idx: int = PlayerFinder.player.interactables.find(self)
	if idx == -1:
		PlayerFinder.player.interactables.append(self)
	PlayerFinder.player.update_interact_touch_ui()

func exit_player_range():
	if PlayerFinder.player == null:
		return
	var idx: int = PlayerFinder.player.interactables.find(self)
	if idx != -1:
		PlayerFinder.player.interactables.remove_at(idx)
	if PlayerFinder.player.interactable == self:
		PlayerFinder.player.interactable = null
	PlayerFinder.player.update_interact_touch_ui()

func play_animation(animName: String):
	print('Warning: Interactable ', name, ' was told to play animation ', animName, ' but play_animation() was not overrided.')

func select_choice(choice: DialogueChoice):
	if PlayerFinder.player.interactableDialogueIndex > 0:
		# find the dialogue entry being read by the player currently
		var dialogueEntry: DialogueEntry = PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIndex].dialogueEntry
		if dialogueEntry != null and saveName != '' and dialogueEntry.entryId != '':
			# if the entry is found, the saveName of this interactable is defined, and so is the dialogue entry ID: set this dialogue seen
			print(dialogueEntry.entryId, ': dialogue seen being set for ', saveName, '')
			PlayerResources.playerInfo.set_dialogue_seen(saveName, dialogueEntry.entryId)
			PlayerResources.questInventory.progress_quest(saveName + '#' + dialogueEntry.entryId, QuestStep.Type.TALK)
		elif dialogueEntry == null:
			print('dialogue entry not found for ', saveName, ' choice ', choice.choiceBtp)
		# TODO: test this
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
			# remove the parent dialogue and make it the "leadsTo" dialogue for use below (so it gets pushed to the list of dialogues after finishing this one up)
			var parentDialogueEntry: DialogueEntry = PlayerFinder.player.interactableDialogues[parentIdx].dialogueEntry
			var prevLen: int = len(PlayerFinder.player.interactableDialogues)
			PlayerFinder.player.interactableDialogues.erase(parentDialogueEntry)
			# if the dialogue entry was erased and it was before our current index, update the index of the current dialogue!
			if prevLen != len(PlayerFinder.player.interactableDialogues) and parentIdx <= PlayerFinder.player.interactableDialogueIndex:
				PlayerFinder.player.interactableDialogueIndex -= 1
			leadsTo = parentDialogueEntry
	
	if leadsTo == null and choice.randomDialogues != null and len(choice.randomDialogues) > 0:
		var randomDialogues: Array[WeightedDialogueEntry] = []
		var sumWeights: float = 0
		for randDialogue in choice.randomDialogues:
			if randDialogue.dialogueEntry.can_use_dialogue():
				randomDialogues.append(randDialogue)
				sumWeights += randDialogue.weight
		
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
				PlayerFinder.player.interactableDialogueIndex = index
				PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIndex].savedItemIdx = 0
				PlayerFinder.player.interactableDialogues[PlayerFinder.player.interactableDialogueIndex].savedTextIdx = 0
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
