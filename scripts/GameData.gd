# File: GameData.gd

extends Node

# Signal to notify the HUD when money changes, carrying the new amount.
signal money_changed(new_amount: int)
signal display_message(text: String)
# --- Game Constants ---
const STARTING_MONEY: int = 1000

const costs:= [150, 300, 200, 150, 250]
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
		# Subtract the cost. The setter will automatically emit the signal.
		money -= cost
		return true  # Block placed successfully
	else:
		# Inside GameData.gd - place_block function (on failure)
		display_message.emit("INSUFFICIENT FUNDS! Cost: %d" % cost)
		return false
		
func break_block(block_index: int):
	var cost = costs[block_index]
	money += cost
	#return true;
