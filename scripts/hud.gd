# File: HUD.gd

extends Control

# This property name MUST match the unique name (%) you set on your Label node.
@onready var money_label = $"%MoneyLabel" 
@onready var message_label = $"%MessageLabel"


func _ready():
	GameData.money_changed.connect(_on_money_changed)
	GameData.display_message.connect(show_message)
	
	_on_money_changed(GameData.money)

func _on_money_changed(new_amount: int):
	money_label.text = "%d" % new_amount 
	
# Inside HUD.gd - in _ready():

# The function that manages the on-screen display:
func show_message(text: String, duration: float = 2.0):
	message_label.text = text 
	message_label.visible = true
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	message_label.visible = false
