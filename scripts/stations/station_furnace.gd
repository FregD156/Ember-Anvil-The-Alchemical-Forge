class_name StationFurnace extends StaticBody2D

signal temperature_updated(current_temp: float, target_temp: float)
signal smelting_completed(output_item: StringName, amount: int, is_brittle: bool)

@export var ambient_temperature: float = 25.0
@export var heat_rate: float = 1.2

var current_temperature: float = 25.0
var fuel_target_temperature: float = 25.0
var fuel_time_remaining: float = 0.0
var bellows_boost: float = 0.0

var active_recipe: SmeltRecipe = null
var is_cooking: bool = false
var cook_progress: float = 0.0
var has_overheated_during_cook: bool = false

@onready var light: PointLight2D = $PointLight2D
@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	current_temperature = ambient_temperature

func _physics_process(delta: float) -> void:
	# Fuel burn down
	if fuel_time_remaining > 0.0:
		fuel_time_remaining -= delta
		if fuel_time_remaining <= 0.0:
			fuel_time_remaining = 0.0
			fuel_target_temperature = ambient_temperature
			
	# Bellows boost decay
	if bellows_boost > 0.0:
		bellows_boost = max(0.0, bellows_boost - (35.0 * delta))
		
	# Gradual temperature formula from DETAIL.md 7.2:
	# T += (T_target - T) * heat_rate * delta
	var target_t: float = (fuel_target_temperature if fuel_time_remaining > 0.0 else ambient_temperature) + bellows_boost
	current_temperature += (target_t - current_temperature) * heat_rate * delta
	current_temperature = max(ambient_temperature, current_temperature)
	
	# Smelting progress
	if is_cooking and active_recipe:
		var sweet_min: float = active_recipe.melting_point
		var sweet_max: float = active_recipe.melting_point + 100.0
		var overheat_limit: float = active_recipe.melting_point + 200.0
		
		if current_temperature > overheat_limit:
			has_overheated_during_cook = true
			
		if current_temperature >= sweet_min and current_temperature <= sweet_max:
			cook_progress += delta
			if cook_progress >= active_recipe.cook_duration:
				_finish_smelt()
				
	_update_visuals()
	temperature_updated.emit(current_temperature, target_t)

func _finish_smelt() -> void:
	is_cooking = false
	cook_progress = 0.0
	
	var out_id: StringName = active_recipe.output_item_id
	var count: int = active_recipe.output_item_count
	GameManager.add_item(out_id, count)
	
	if has_overheated_during_cook:
		EventBus.floating_text_requested.emit("Đúc xong %s (Bị Giòn do Overheat)!" % out_id, global_position + Vector2(0, -24), Color("D4542B"))
		EventBus.ui_notification.emit("Phôi %s bị Giòn (-20%% độ bền) do lò quá nhiệt!" % out_id, Color("D4542B"))
	else:
		EventBus.floating_text_requested.emit("+%d %s (Hoàn hảo)!" % [count, out_id], global_position + Vector2(0, -24), Color("FFC84A"))
		EventBus.ui_notification.emit("Đúc thành công %d %s!" % [count, out_id], Color("5E9150"))
		
	smelting_completed.emit(out_id, count, has_overheated_during_cook)
	EventBus.item_crafted.emit(out_id, 1)

func add_fuel(target_heat: float, duration: float) -> void:
	fuel_target_temperature = max(fuel_target_temperature, target_heat)
	fuel_time_remaining += duration

func pump_bellows(boost: float = 80.0) -> void:
	bellows_boost = min(bellows_boost + boost, 180.0)

func set_recipe(recipe: SmeltRecipe) -> void:
	active_recipe = recipe

func start_smelting(recipe: SmeltRecipe) -> void:
	active_recipe = recipe
	is_cooking = true
	cook_progress = 0.0
	has_overheated_during_cook = false

func _update_visuals() -> void:
	if not light:
		return
	
	# Light color & intensity according to ART_PROMPTS.md A7
	if current_temperature < 150.0:
		light.color = Color("9B2D2B")
		light.energy = 0.3
	elif current_temperature < 300.0:
		light.color = Color("F28C33")
		light.energy = 0.7
	elif current_temperature <= 450.0:
		light.color = Color("FFC84A")
		light.energy = 1.2
	else:
		# Overheat: flickering white-yellow
		var flicker: float = 1.4 + 0.3 * sin(Time.get_ticks_msec() / 60.0)
		light.color = Color("FFF1A8")
		light.energy = flicker

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		_interact()

func _interact() -> void:
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_node("SmelterOverlay"):
		var smelter_ui: SmelterOverlay = hud.get_node("SmelterOverlay")
		smelter_ui.open_for_furnace(self)
	else:
		# Fallback direct lookup in UI CanvasLayer
		var smelter_ui: SmelterOverlay = get_tree().root.find_child("SmelterOverlay", true, false)
		if smelter_ui:
			smelter_ui.open_for_furnace(self)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		if prompt_label:
			prompt_label.text = "[E] Lò Nung"
			prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label:
			prompt_label.visible = false
