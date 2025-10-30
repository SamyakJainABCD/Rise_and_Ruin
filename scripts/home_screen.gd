extends Node

func _on_make_match_pressed() -> void:
	if not GameState.finding_match:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.finding_match = true
		GameData.costs = []
		GameState.find_match()
