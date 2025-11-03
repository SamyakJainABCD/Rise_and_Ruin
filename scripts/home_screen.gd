extends Node

@onready var usernameNode = $TextureRect/VBoxContainer/LineEdit

func _on_make_match_pressed() -> void:
	if not GameState.finding_match:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.finding_match = true
		GameData.costs = []
		GameState.new_match()
		GameData.new_match()
		GameState.username = usernameNode.text
		GameState.player_id = GameState.username + "$" + GameState.player_id
		GameState.find_match()
