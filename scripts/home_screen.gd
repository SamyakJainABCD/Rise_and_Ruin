extends Node

func _on_make_match_pressed() -> void:
	if not GameState.finding_match:
		GameState.finding_match = true
		GameState.find_match()
