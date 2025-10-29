extends Node

@onready var http_request := HTTPRequest.new()

var player_id : String = str(randi())
var match_id : String = ""
var opponent_id : String = ""
var job : String = ""
var finding_match: bool = false
var opponent_block_list = []
var highest_point_of_opponent_tower: float = 0

var block_scenes := [
	preload("res://scenes/blocks/block.tscn"),
	preload("res://scenes/blocks/sphere.tscn"),
	#preload("res://scenes/blocks/stairs.tscn"),
	preload("res://scenes/blocks/pillars.tscn"),
	preload("res://scenes/blocks/pyramid.tscn"),
	preload("res://scenes/blocks/plank.tscn"),
]

func _ready():
	randomize()
	add_child(http_request)
	# Connect the HTTPRequest callback once
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))


# --- REQUEST TYPES ---
enum RequestType { NONE, FIND_MATCH, SEND_DATA, FETCH_DATA }
var current_request : int = RequestType.NONE
var pending_payload : Dictionary = {}  # For sending data
# --- FIND MATCH ---
func find_match() -> void:
	get_tree().change_scene_to_file("res://scenes/waiting.tscn")
	current_request = RequestType.FIND_MATCH
	var body = {"player_id": player_id}
	var json_body = JSON.stringify(body)
	http_request.request("http://127.0.0.1:8000/find_match/", [], HTTPClient.METHOD_POST, json_body)


# --- SEND MATCH DATA ---
func send_match_data(payload) -> void:
	if match_id == "":
		print("No match yet!")
		return
	get_tree().change_scene_to_file("res://scenes/waiting.tscn")
	current_request = RequestType.SEND_DATA
			
	var body = {
		"player_id": player_id,
		"match_id": match_id,
		"payload": payload,
	}
	var json_body = JSON.stringify(body)
	http_request.request("http://127.0.0.1:8000/send_match_data/", [], HTTPClient.METHOD_POST, json_body)
	print("sent data")


# --- FETCH OPPONENT DATA ---
func fetch_opponent_data() -> void:
	if match_id == "":
		return
	get_tree().change_scene_to_file("res://scenes/waiting.tscn")
	current_request = RequestType.FETCH_DATA
	var body = {
		"player_id": player_id,
		"match_id": match_id
	}
	var json_body = JSON.stringify(body)
	http_request.request("http://127.0.0.1:8000/fetch_opponent_data/", [], HTTPClient.METHOD_POST, json_body)
	print("fetched from fetch_opponent_data()")


# --- GENERAL HTTP RESPONSE HANDLER ---
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		print("Failed to parse response")
		return

	var response = json.data  # <-- use .data, not .result
	match current_request:
		RequestType.FIND_MATCH:
			handle_find_match_response(response)
		RequestType.SEND_DATA:
			print("fetcing from _on_request_completed1")
			fetch_opponent_data()
			# After sending data, immediately fetch opponent data
		RequestType.FETCH_DATA:
			print("fetched from _on_request_completed2")
			handle_fetch_data_response(response)

	#current_request = RequestType.NONE


# --- HANDLE FIND MATCH RESPONSE ---
func handle_find_match_response(response: Dictionary) -> void:
	if response["status"] == "matched":
		match_id = response["match_id"]
		opponent_id = response["opponent_id"]
		job = response["job"]
		print("Matched with", opponent_id, "as", job)
		get_tree().change_scene_to_file("res://scenes/rise_phase.tscn")
		# Start sending/receiving match data
	elif response["status"] == "waiting":
		print("Waiting for opponent...")
		await get_tree().create_timer(0.5).timeout
		find_match()
		
		
# --- HANDLE FETCH DATA RESPONSE ---
func handle_fetch_data_response(response: Dictionary) -> void:
	print("fetching")

	if response.has("opponent_data") and response["opponent_data"] != null:
		var raw_data = response["opponent_data"]
		if typeof(raw_data)==TYPE_ARRAY:
			if opponent_block_list: #changes made below must also be made here
				await get_tree().create_timer(0.5).timeout
				fetch_opponent_data()
				return
			var parsed = []
			for entry in raw_data:
				var index = int(entry[0])
				var transform_str = entry[1]
				var transform = parse_transform3d_from_string(transform_str)
				parsed.append([index, transform])
			
			opponent_block_list = parsed

			get_tree().change_scene_to_file("res://scenes/ruin_phase.tscn")
		else:
			finding_match = false
			player_id = str(randi())
			GameData._ready()
			var highest_point_of_self_tower = raw_data
			if highest_point_of_opponent_tower > highest_point_of_self_tower:
				get_tree().change_scene_to_file("res://scenes/you_lost.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/you_won.tscn")
				
	else: #changes made here must also be made above
		await get_tree().create_timer(0.5).timeout
		fetch_opponent_data()


func parse_transform3d_from_string(s: String) -> Transform3D:
	# Example: [X: (0.985, -0.00003, -0.170), Y: (...), Z: (...), O: (...)]
	var regex = RegEx.new()
	regex.compile(r"X:\s*\((.*?)\),\s*Y:\s*\((.*?)\),\s*Z:\s*\((.*?)\),\s*O:\s*\((.*?)\)")
	var result = regex.search(s)
	if result == null:
		push_error("Invalid transform string: %s" % s)
		return Transform3D()


	var x = parse_vec3(result.get_string(1))
	var y = parse_vec3(result.get_string(2))
	var z = parse_vec3(result.get_string(3))
	var o = parse_vec3(result.get_string(4))

	return Transform3D(Basis(x, y, z), o)

func parse_vec3(stri):
	var nums = stri.split(",")
	return Vector3(float(nums[0]), float(nums[1]), float(nums[2]))
