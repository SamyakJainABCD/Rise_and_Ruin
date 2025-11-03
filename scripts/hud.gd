# File: HUD.gd

extends Control

# This property name MUST match the unique name (%) you set on your Label node.
@onready var money_label = $"%MoneyLabel" 
@onready var message_label = $"%MessageLabel"
@onready var settings_icon = $"CanvasLayer/SettingsIcon"
@onready var controls_display = $"%ControlsDisplay"
@onready var timer = $"%Timer"
const CONTROLS_TEXT = """
[b]CONTROLS:[/b]
-------------------
[color=yellow]Toggle Menu:[/color] [b]F1[/b]
[color=yellow]Place Block:[/color] Right Click
[b]Break Block:[/b] Left Click
[b]Movement:[/b] WASD
"""
func _ready():
	GameData.money_changed.connect(_on_money_changed)
	GameData.display_message.connect(show_message)
	_on_money_changed(GameData.money)
	if is_instance_valid(settings_icon):
		print("Settings Icon Global Position: ", settings_icon.global_position)
	GameData.hud = self
	
func _unhandled_input(event):
	# 🚩 NEW FUNCTION: Check for the custom keyboard action
	if event.is_action_pressed("toggle_settings"):
		toggle_settings_panel()
		print("presesed")

func toggle_settings_panel():
	if is_instance_valid(controls_display):
		print("aaaa")
		var is_now_visible = not controls_display.visible
		controls_display.visible = is_now_visible
		# Change Mouse Mode
		if is_now_visible:
			print("a4")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
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


func start_timer(time):
	if time<0:
		return
	timer.text=str(time)
	if get_tree():
		await get_tree().create_timer(1).timeout
	start_timer(time-1)
