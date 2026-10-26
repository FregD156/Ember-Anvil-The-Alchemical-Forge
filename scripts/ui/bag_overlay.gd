class_name BagOverlay extends Control

@onready var grid_container: GridContainer = $Panel/Margin/VBox/GridContainer
@onready var item_detail_label: Label = $Panel/Margin/VBox/ItemDetailLabel
@onready var sort_button: Button = $Panel/Margin/VBox/Buttons/SortButton
@onready var close_button: Button = $Panel/Margin/VBox/Buttons/CloseButton

const TOTAL_SLOTS: int = 20
var slot_buttons: Array[Button] = []
var selected_item_id: StringName = &""

func _ready() -> void:
	visible = false
	EventBus.inventory_changed.connect(_refresh_inventory)
	
	if sort_button:
		sort_button.pressed.connect(_on_sort_pressed)
	if close_button:
		close_button.pressed.connect(close)
		
	_create_slots()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle"):
		toggle()
	elif event.is_action_pressed("ui_cancel") and visible:
		close()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	visible = true
	# DETAIL.md 3.4: Bag pauses time
	TimeManager.set_pause(&"bag", true)
	_refresh_inventory()

func close() -> void:
	visible = false
	TimeManager.set_pause(&"bag", false)
	selected_item_id = &""
	if item_detail_label:
		item_detail_label.text = "Chọn vật phẩm để xem chi tiết"

func _create_slots() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	slot_buttons.clear()
	
	for i in range(TOTAL_SLOTS):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		btn.pressed.connect(_on_slot_pressed.bind(i))
		grid_container.add_child(btn)
		slot_buttons.append(btn)

func _refresh_inventory() -> void:
	if not visible:
		return
		
	var items: Array = GameManager.inventory.keys()
	
	for i in range(TOTAL_SLOTS):
		var btn: Button = slot_buttons[i]
		if i < items.size():
			var item_id: StringName = items[i]
			var count: int = GameManager.inventory[item_id]
			btn.text = "%s\nx%d" % [item_id.left(6), count]
			btn.tooltip_text = "%s (Số lượng: %d)" % [item_id, count]
			btn.set_meta("item_id", item_id)
		else:
			btn.text = "—"
			btn.tooltip_text = "Ô trống"
			btn.remove_meta("item_id")
			
	if selected_item_id != &"":
		_update_item_detail(selected_item_id)
	elif item_detail_label:
		item_detail_label.text = "Chọn một ô để xem chi tiết vật phẩm."

func _on_slot_pressed(index: int) -> void:
	var btn: Button = slot_buttons[index]
	if btn.has_meta("item_id"):
		selected_item_id = btn.get_meta("item_id")
		_update_item_detail(selected_item_id)
	else:
		selected_item_id = &""
		if item_detail_label:
			item_detail_label.text = "Ô trống."

func _update_item_detail(item_id: StringName) -> void:
	if not item_detail_label:
		return
	var count: int = GameManager.get_item_count(item_id)
	var detail_text: String = "Vật phẩm: %s\nSố lượng trong túi: %d" % [item_id, count]
	item_detail_label.text = detail_text

func _on_sort_pressed() -> void:
	# Sort items alphabetically in GameManager inventory
	var sorted_keys: Array = GameManager.inventory.keys()
	sorted_keys.sort()
	var new_inv: Dictionary = {}
	for k in sorted_keys:
		new_inv[k] = GameManager.inventory[k]
	GameManager.inventory = new_inv
	_refresh_inventory()
	EventBus.ui_notification.emit("Đã sắp xếp túi đồ", Color("FFC84A"))
