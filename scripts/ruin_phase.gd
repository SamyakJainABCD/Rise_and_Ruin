extends Node3D

const TOTAL_TIME = 20
var opponent_block_list: Array = []  # This is filled from server
func _ready():
	opponent_block_list = GameState.opponent_block_list
	place_opponent_blocks()
	GameData.costs = GameData.costs_for_ruin
	get_node("bg/InventoryBar")._setup_initial_slots()
	GameData.start_timer(TOTAL_TIME)
	await get_tree().create_timer(TOTAL_TIME).timeout
	var highest: float = -1
	for block in get_children():
		if block is RigidBody3D:
			if block.scene_file_path == "res://scenes/fireball/fireball.tscn":
				continue
			var block_highest = block.position.y
			
			# Find the collision shape to get the actual highest point
			for child in block.get_children():
				if child is CollisionShape3D:
					var shape = child.shape
					var aabb: AABB
					
					if shape is BoxShape3D:
						aabb = AABB(-shape.size / 2.0, shape.size)
					elif shape is SphereShape3D:
						var rad = shape.radius
						aabb = AABB(Vector3(-rad, -rad, -rad), Vector3(rad * 2, rad * 2, rad * 2))
					elif shape is CapsuleShape3D:
						var rad = shape.radius
						var half_height = shape.height / 2.0
						aabb = AABB(Vector3(-rad, -half_height - rad, -rad), 
								   Vector3(rad * 2, shape.height + rad * 2, rad * 2))
					elif shape is CylinderShape3D:
						var rad = shape.radius
						var half_height = shape.height / 2.0
						aabb = AABB(Vector3(-rad, -half_height, -rad), 
								   Vector3(rad * 2, shape.height, rad * 2))
					# Add other shape types as needed
					
					# Transform AABB by the block's global transform
					var global_transform_ = block.global_transform * child.transform
					var corners = [
						global_transform_ * Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
						global_transform_ * Vector3(aabb.end.x, aabb.position.y, aabb.position.z),
						global_transform_ * Vector3(aabb.position.x, aabb.end.y, aabb.position.z),
						global_transform_ * Vector3(aabb.end.x, aabb.end.y, aabb.position.z),
						global_transform_ * Vector3(aabb.position.x, aabb.position.y, aabb.end.z),
						global_transform_ * Vector3(aabb.end.x, aabb.position.y, aabb.end.z),
						global_transform_ * Vector3(aabb.position.x, aabb.end.y, aabb.end.z),
						global_transform_ * Vector3(aabb.end.x, aabb.end.y, aabb.end.z)
					]
					
					for corner in corners:
						if corner.y > block_highest:
							block_highest = corner.y
					break
		
			if block_highest > highest:
				highest = block_highest
	print(highest)
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
		if index < 0 or index >= GameData.block_scenes.size():
			push_error("Invalid block index: %s" % index)
			continue

		# Instantiate and place
		var block_scene = GameData.block_scenes[index]
		var instance = block_scene.instantiate()
		instance.global_transform = Transform3D(transform_of_entry.basis, transform_of_entry.origin)

		add_child(instance)
