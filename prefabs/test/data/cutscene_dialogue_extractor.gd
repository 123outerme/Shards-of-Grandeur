extends Node

@export var cutscene: Cutscene

func _ready() -> void:
	extract_dialogue(cutscene)

func extract_dialogue(cs: Cutscene) -> void:
	for frame: CutsceneFrame in cs.cutsceneFrames:
		for dialogue: CutsceneDialogue in frame.dialogues:
			if dialogue is StoryReqsCutsceneDialogue:
				var altNum: int = 1
				for alt in dialogue.storyReqsAlternatives:
					print('Alternate dialogue ', altNum, ' - ', alt.speaker)
					for text: String in dialogue.texts:
						print(text)
					print('Alt dialogue ', altNum, ' end.')
					altNum += 1
			print('Standard dialogue - ', dialogue.speaker)
			for text: String in dialogue.texts:
				print(text)
