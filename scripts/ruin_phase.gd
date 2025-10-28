extends Node3D

@onready var block_scenes := [
	preload("res://scenes/blocks/block.tscn"),
	preload("res://scenes/blocks/sphere.tscn"),
	preload("res://scenes/blocks/stairs.tscn"),
]

var opponent_block_list: Array = []  # This is filled from server
func _ready():
	opponent_block_list = GameState.opponent_block_list
	place_opponent_blocks()

func place_opponent_blocks():
	print(opponent_block_list)
	if opponent_block_list.is_empty():
		print("No opponent blocks to place.")
		return

	for entry in opponent_block_list:
		var index = entry[0]
		var transform = entry[1]
		# Validate index
		if index < 0 or index >= block_scenes.size():
			push_error("Invalid block index: %s" % index)
			continue

		# Instantiate and place
		var block_scene = block_scenes[index]
		var instance = block_scene.instantiate()
		instance.global_transform = transform
		print("transform: ", Transform3D(transform.basis, transform.origin))
		instance.global_transform = Transform3D(transform.basis, transform.origin)

		add_child(instance)
	
	print("Placed %d opponent blocks." % opponent_block_list.size())
