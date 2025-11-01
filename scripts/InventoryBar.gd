extends Control

# Must preload the slot template scene
const SLOT_SCENE = preload("res://scenes/ui/InventorySlot.tscn")
@onready var slots_container = $CanvasLayer/SlotsContainer
var slots: Array = [] # To store references to all instantiated slot nodes
var current_highlighted_slot: Control = null
const ICON_PATH = "PanelContainer/MarginContainer/VBoxContainer/Icon"

func _ready():
	# Connect to the global signals
	GameData.block_selected.connect(highlight_slot)
	
	# Initial setup
	_setup_initial_slots()
	highlight_slot(0) # Highlight the first slot on game start

func _setup_initial_slots():
	# Clear any old slots and the array
	for child in slots_container.get_children():
		child.queue_free()
	slots.clear() 
	if GameData.costs == GameData.costs_for_ruin or not GameData.costs:
		return

	# We need 6 slots (matching the 6 blocks in GameData)
	while not GameData.costs:
		await get_tree().process_frame
	for block_index in range(GameData.costs.size()):
		var price: int = GameData.costs[block_index]
		var slot = SLOT_SCENE.instantiate()
		var icon_rect = slot.get_node("PanelContainer/MarginContainer/VBoxContainer/Icon")
		var price_label = slot.get_node("PanelContainer/MarginContainer/VBoxContainer/PriceLabel")
		if block_index < GameData.BLOCK_ICONS.size():
			icon_rect.texture = GameData.BLOCK_ICONS[block_index]
			# Add a placeholder Label for the slot index (e.g., "1", "2", "3"...)
		if is_instance_valid(price_label):
			price_label.text += "%d" % price
		var index_label = Label.new()
		
		index_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		index_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		index_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		index_label.position = Vector2(5, 5)
		
		index_label.add_theme_font_size_override("font_size", 16)
		slot.add_child(index_label) # Add directly to the root Slot control
		
		slots.append(slot)
		slots_container.add_child(slot)





# File: InventoryBar.gd

# ... (omitted @onready vars and other functions) ...
func highlight_slot(index: int):
	for slot in slots:
		var icon_rect = slot.get_node(ICON_PATH)
		var highlight_rect = slot.get_node("HighlightRect")

		if is_instance_valid(icon_rect):
			# A: Forcefully reset scale using the zero-duration tween trick
			icon_rect.create_tween().tween_property(icon_rect, "scale", Vector2(1.0, 1.0), 0.001).set_ease(Tween.EASE_OUT)
			
			# B: Reset background highlight
			if is_instance_valid(highlight_rect):
				highlight_rect.visible = false
					   
	# Reset the tracker (optional, but clean)
	current_highlighted_slot = null

	# 2. Get the NEWLY selected slot
	if index >= 0 and index < slots.size():
		var slot = slots[index]
		var highlight_rect = slot.get_node("HighlightRect")
		var icon_rect = slot.get_node(ICON_PATH)
		if not is_instance_valid(icon_rect):
			push_error("InventoryBar.gd: Failed to find TextureRect (Icon) node in slot.")
			return # Stop if the node isn't found
		# 3. Apply NEW visual state (Highlight background)
		highlight_rect.color = Color(1, 1, 0, 0.4) 
		highlight_rect.visible = true
		icon_rect.pivot_offset = icon_rect.size 
		# 4. Apply Scaling Tween to the Icon
		var scale_factor = 1.2 
		var scale_duration = 0.25
		# Create a new tween directly on the icon_rect node for easy management
		var current_tween = icon_rect.create_tween() 
		current_tween.tween_property(icon_rect, "scale", Vector2(scale_factor, scale_factor), scale_duration)
		# 5. Track the newly highlighted slot
		current_highlighted_slot = slot
