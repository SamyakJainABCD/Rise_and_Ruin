# File: GameData.gd

extends Node

# Signal to notify the HUD when money changes, carrying the new amount.
signal money_changed(new_amount: int)
signal display_message(text: String)
signal inventory_updated()
signal block_selected(new_index: int)
# --- Game Constants ---
const block_scenes := [
	preload("res://scenes/blocks/block.tscn"),
	preload("res://scenes/blocks/sphere.tscn"),
	preload("res://scenes/blocks/pillars.tscn"),
	preload("res://scenes/blocks/pyramid.tscn"),
	preload("res://scenes/blocks/plank.tscn"),
	preload("res://scenes/blocks/block.tscn"),
	preload("res://scenes/blocks/sphere.tscn"),
	preload("res://scenes/blocks/pillars.tscn"),
	preload("res://scenes/blocks/pyramid.tscn"),
	preload("res://scenes/blocks/plank.tscn"),
]
const BLOCK_ICONS: Array[Texture2D] = [
	preload("res://assets/blocks/block.png"),  
	preload("res://assets/blocks/sphere.png"),
	preload("res://assets/blocks/pillar.png"),
	preload("res://assets/blocks/pyramid.png"),
	preload("res://assets/blocks/plank.png"),
	preload("res://assets/blocks/block.png"),  
	preload("res://assets/blocks/sphere.png"),
	preload("res://assets/blocks/pillar.png"),
	preload("res://assets/blocks/pyramid.png"),
	preload("res://assets/blocks/plank.png"),
]	
var inventory: Dictionary = {
	0: 10,  
	1: 10, 
	2: 10,  
	3: 10, 
	4: 10, 
	5: 10,
	6: 10,
	7: 10,
	8: 10,
	9: 10, 
}
const costs:= [150, 300, 200, 150, 250, 150, 300, 200, 150, 250]
const STARTING_MONEY: int = 5000
# --- Money Variable with Setter ---
# The setter ensures the 'money_changed' signal is emitted automatically 
# whenever the 'money' variable is updated.
var money: int = 0: 
	set(value):
		money = max(0, value) # Ensure money never goes below zero
		money_changed.emit(money)

# --- Core Logic ---

func _ready():
	# 1. Give the user starting money when the game starts
	money = STARTING_MONEY 
func place_block(block_index: int) -> bool:
	var cost = costs[block_index]
	if money >= cost:
		if inventory.get(block_index, 0) > 0:
			inventory[block_index] -= 1
			inventory_updated.emit()
			money -= cost
			return true;
		else :
			display_message.emit("OUT OF STOCK")
			return false;
	else:
		# Inside GameData.gd - place_block function (on failure)
		display_message.emit("INSUFFICIENT FUNDS! Cost: $%d" % cost)
		return false
func add_item(block_index: int, amount: int = 1):
	inventory[block_index] = inventory.get(block_index, 0) + amount
	inventory_updated.emit()

func break_block(block_index: int):
	var cost = costs[block_index]
	money += cost
	inventory[block_index] += 1
	inventory_updated.emit()
	#return true;
