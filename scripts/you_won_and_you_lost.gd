extends Node2D



func _on_home_screen_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/home_screen.tscn")
