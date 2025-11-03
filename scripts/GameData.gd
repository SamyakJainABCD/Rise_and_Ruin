extends Node

# Signal to notify the HUD when money changes, carrying the new amount.
signal money_changed(new_amount: int)
signal display_message(text: String)
signal block_selected(new_index: int)
# --- Game Constants ---
const block_scenes := [
	preload("res://scenes/blocks/block.tscn"),
	preload("res://scenes/blocks/pillars.tscn"),
	preload("res://scenes/blocks/4pillars.tscn"),
	preload("res://scenes/blocks/floor.tscn"),
]
const block_icons: Array[Texture2D] = [
	preload("res://assets/blocks/block.png"),  
	preload("res://assets/blocks/pillar.png"),
	preload("res://assets/blocks/plank.png"),
	preload("res://assets/blocks/floor.png"),
]
const missile_icons: Array[Texture2D] = [
	preload("res://assets/blocks/fireball.png"),
]	
var BLOCK_ICONS: Array[Texture2D] = []
var costs_for_rise = [150, 300, 1200, 750]
var costs_for_ruin = [750]
var costs
var hud
const STARTING_MONEY: int = 10000
# --- Money Variable with Setter ---
# The setter ensures the 'money_changed' signal is emitted automatically 
# whenever the 'money' variable is updated.
var money: int = 0: 
	set(value):
		money = max(0, value) # Ensure money never goes below zero
		money_changed.emit(money)
		
		


# --- Core Logic ---

func new_match():
	costs = []
	

func _ready():
	# 1. Give the user starting money when the game starts
	money = STARTING_MONEY 
	
func place_block(block_index: int, coords: Vector3 = Vector3(0,0,0)) -> bool:
	var cost = costs[block_index]
	if coords.distance_to(Vector3(0,coords.y,0)) > 10:
		display_message.emit("Out of bounds")
		return false
	if money >= cost:
		money -= cost
	else:
		# Inside GameData.gd - place_block function (on failure)
		display_message.emit("INSUFFICIENT FUNDS! Cost: $%d" % cost)
		return false
	return true
func break_block(block_index: int):
	var cost = costs[block_index]
	money += cost

func start_timer(time):
	hud.start_timer(time)
