class_name SmelterOverlay extends Control

@export var default_recipe: SmeltRecipe

@onready var temp_label: Label = $Panel/Margin/VBox/StatusContainer/TempLabel
@onready var status_label: Label = $Panel/Margin/VBox/StatusContainer/StatusLabel
@onready var fuel_label: Label = $Panel/Margin/VBox/FuelContainer/FuelLabel
@onready var progress_bar: ProgressBar = $Panel/Margin/VBox/ProgressContainer/ProgressBar
@onready var progress_label: Label = $Panel/Margin/VBox/ProgressContainer/ProgressLabel
@onready var temp_bar: ProgressBar = $Panel/Margin/VBox/TempBar

@onready var add_fuel_button: Button = $Panel/Margin/VBox/Actions/AddFuelButton
@onready var bellows_button: Button = $Panel/Margin/VBox/Actions/BellowsButton
@onready var smelt_button: Button = $Panel/Margin/VBox/Actions/SmeltButton
@onready var close_button: Button = $Panel/Margin/VBox/Actions/CloseButton

var current_furnace: StationFurnace = null

func _ready() -> void:
	visible = false
	if default_recipe == null and ResourceLoader.exists("res://data/recipes/recipe_copper_ingot.tres"):
		default_recipe = load("res://data/recipes/recipe_copper_ingot.tres")
		
	if add_fuel_button:
		add_fuel_button.pressed.connect(_on_add_fuel_pressed)
	if bellows_button:
		bellows_button.pressed.connect(_on_bellows_pressed)
	if smelt_button:
		smelt_button.pressed.connect(_on_smelt_button_pressed)
	if close_button:
		close_button.pressed.connect(close)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close()

func open_for_furnace(furnace: StationFurnace) -> void:
	current_furnace = furnace
	if default_recipe:
		current_furnace.set_recipe(default_recipe)
	visible = true
	# DETAIL.md 3.4: Smelter does NOT pause game time
	_update_ui()

func close() -> void:
	visible = false
	current_furnace = null

func _process(_delta: float) -> void:
	if not visible or not current_furnace:
		return
	_update_ui()

func _update_ui() -> void:
	if not current_furnace:
		return
		
	var temp: float = current_furnace.current_temperature
	temp_label.text = "Nhiệt độ lò: %d°C" % int(temp)
	temp_bar.value = temp
	
	if current_furnace.fuel_time_remaining > 0:
		fuel_label.text = "Nhiên liệu: Còn %.1fs" % current_furnace.fuel_time_remaining
	else:
		fuel_label.text = "Nhiên liệu: Hết (Lò đang nguội)"
		
	var recipe: SmeltRecipe = current_furnace.active_recipe
	if recipe:
		var sweet_min: float = recipe.melting_point
		var sweet_max: float = recipe.melting_point + 100.0
		var overheat: float = recipe.melting_point + 200.0
		
		if temp < sweet_min:
			status_label.text = "Trạng thái: Chưa đạt ngưỡng nóng chảy (%d°C)" % int(sweet_min)
			status_label.modulate = Color("9A8FA3")
		elif temp <= sweet_max:
			status_label.text = "★ SWEET SPOT (%d - %d°C) ★ Đang đúc phôi!" % [int(sweet_min), int(sweet_max)]
			status_label.modulate = Color("FFC84A")
		elif temp > overheat:
			status_label.text = "⚠ OVERHEAT (>%d°C)! Phôi bị Giòn!" % int(overheat)
			status_label.modulate = Color("D4542B")
		else:
			status_label.text = "Trạng thái: Nhiệt độ cao (%d - %d°C)" % [int(sweet_max), int(overheat)]
			status_label.modulate = Color("E2B97F")
			
		var cook_ratio: float = current_furnace.cook_progress / recipe.cook_duration if recipe.cook_duration > 0 else 0.0
		progress_bar.value = clamp(cook_ratio * 100.0, 0.0, 100.0)
		progress_label.text = "Tiến độ luyện kim: %d%%" % int(progress_bar.value)
	else:
		status_label.text = "Chưa chọn công thức nung"

func _on_add_fuel_pressed() -> void:
	if not current_furnace:
		return
	# Try using dry_branch (T0) or pine_wood (T1)
	if GameManager.get_item_count(&"dry_branch") > 0:
		GameManager.remove_item(&"dry_branch", 1)
		current_furnace.add_fuel(350.0, 15.0) # 350°C, 15s (DETAIL.md 5)
		EventBus.floating_text_requested.emit("+Cành khô (15s)", current_furnace.global_position + Vector2(0, -20), Color("FFC84A"))
	elif GameManager.get_item_count(&"pine_wood") > 0:
		GameManager.remove_item(&"pine_wood", 1)
		current_furnace.add_fuel(550.0, 30.0) # 550°C, 30s
		EventBus.floating_text_requested.emit("+Gỗ thông (30s)", current_furnace.global_position + Vector2(0, -20), Color("FFC84A"))
	else:
		EventBus.ui_notification.emit("Không có cành khô hoặc gỗ trong túi!", Color("D4542B"))

func _on_bellows_pressed() -> void:
	if not current_furnace:
		return
	# DETAIL.md 4.4: Bellows pump costs 2 stamina
	var player: Player = get_tree().get_first_node_in_group("player")
	if player and player.stamina_component:
		if player.stamina_component.spend(2.0):
			current_furnace.pump_bellows(80.0)
			EventBus.floating_text_requested.emit("Bơm ống thổi (+80°C)", current_furnace.global_position + Vector2(0, -20), Color("F28C33"))
		else:
			EventBus.ui_notification.emit("Không đủ thể lực để bơm ống thổi!", Color("D4542B"))

func _on_smelt_button_pressed() -> void:
	if not current_furnace or not default_recipe:
		return
	if current_furnace.is_cooking:
		EventBus.ui_notification.emit("Lò đang trong quá trình nung!", Color("FFC84A"))
		return
	# Check if player has 3 copper ores
	var needed: int = default_recipe.input_ore_count
	var ore_id: StringName = default_recipe.input_ore_id
	if GameManager.get_item_count(ore_id) >= needed:
		GameManager.remove_item(ore_id, needed)
		current_furnace.start_smelting(default_recipe)
		EventBus.ui_notification.emit("Đã cho 3 Quặng vào lò! Giữ nhiệt ở Sweet Spot để đúc phôi.", Color("5E9150"))
	else:
		EventBus.ui_notification.emit("Cần ít nhất %d %s (1 Phôi = 3 Quặng)!" % [needed, ore_id], Color("D4542B"))
