extends Node3D

var opponent_block_list: Array = []  # This is filled from server
func _ready():
	opponent_block_list = GameState.opponent_block_list
	place_opponent_blocks()
	GameData.costs = GameData.costs_for_ruin
	get_node("bg/InventoryBar")._setup_initial_slots()
	await get_tree().create_timer(10).timeout
	var highest: float = -1
	for block in get_children():
		if block is RigidBody3D:
			if block.position.y > highest:
				highest = block.position.y
	GameState.highest_point_of_opponent_tower = highest
	GameState.send_match_data(highest)

func place_opponent_blocks():
	print("placing blocks")
	if opponent_block_list.is_empty():
		print("No opponent blocks to place.")
		return

	for entry in opponent_block_list:
		var index = entry[0]
		var transform_of_entry = entry[1]
		# Validate index
		if index < 0 or index >= GameState.block_scenes.size():
			push_error("Invalid block index: %s" % index)
			continue

		# Instantiate and place
		var block_scene = GameState.block_scenes[index]
		var instance = block_scene.instantiate()
		instance.global_transform = Transform3D(transform_of_entry.basis, transform_of_entry.origin)

		add_child(instance)
