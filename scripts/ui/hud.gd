class_name HUD extends CanvasLayer

@onready var day_label: Label = $TopLeft/VBox/DayLabel
@onready var time_label: Label = $TopLeft/VBox/TimeLabel
@onready var gold_label: Label = $TopLeft/VBox/EconomyContainer/GoldLabel
@onready var rep_label: Label = $TopLeft/VBox/EconomyContainer/RepLabel

@onready var stamina_bar: ProgressBar = $BottomLeft/VBox/StaminaBar
@onready var stamina_label: Label = $BottomLeft/VBox/StaminaText

@onready var slot_1: PanelContainer = $BottomCenter/VBox/ToolSlots/Slot1
@onready var slot_2: PanelContainer = $BottomCenter/VBox/ToolSlots/Slot2
@onready var slot_3: PanelContainer = $BottomCenter/VBox/ToolSlots/Slot3
@onready var tool_name_label: Label = $BottomCenter/VBox/ActiveToolName

@onready var floating_text_layer: Control = $FloatingTextLayer
@onready var tired_vignette: ColorRect = $TiredVignette
@onready var canvas_modulate: CanvasModulate = $DayNightModulate

@onready var live_viewport_container: SubViewportContainer = $TopRight/LiveViewportContainer
@onready var sub_viewport: SubViewport = $TopRight/LiveViewportContainer/SubViewport

var _active_slot: int = 0
var _is_viewport_expanded: bool = false

func _ready() -> void:
	# Connect to Autoload signals
	TimeManager.minute_changed.connect(_on_minute_changed)
	TimeManager.day_started.connect(_on_day_started)
	
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.reputation_changed.connect(_on_rep_changed)
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.floating_text_requested.connect(_on_floating_text_requested)
	
	EventBus.expedition_started.connect(_on_expedition_started)
	EventBus.expedition_finished.connect(_on_expedition_finished)
	
	# Initial UI updates
	_update_time_display(TimeManager.minutes)
	_update_day_display(TimeManager.day)
	_on_gold_changed(GameManager.gold)
	_on_rep_changed(GameManager.reputation)
	_update_stamina_bar(GameConstants.BASE_MAX_STAMINA, GameConstants.BASE_MAX_STAMINA)

func _process(_delta: float) -> void:
	# Smoothly update ambient lighting according to game time
	if canvas_modulate:
		canvas_modulate.color = GameConstants.sample_ambient_color(TimeManager.minutes)

func _on_minute_changed(minutes: int) -> void:
	_update_time_display(minutes)
	_check_tired_vignette(minutes)

func _on_day_started(day: int, _wakeup: int) -> void:
	_update_day_display(day)

func _update_time_display(minutes: int) -> void:
	if time_label:
		var time_str: String = TimeManager.get_formatted_time()
		var period_str: String = TimeManager.get_day_period_name()
		time_str += " · " + period_str
		time_label.text = time_str

func _update_day_display(day: int) -> void:
	if day_label:
		day_label.text = "Ngày %d" % day

func _on_gold_changed(gold: int) -> void:
	if gold_label:
		gold_label.text = "Vàng: %d" % gold

func _on_rep_changed(rep: int) -> void:
	if rep_label:
		var stars: String = ""
		for i in range(5):
			stars += "★" if i < rep else "☆"
		rep_label.text = "Danh tiếng: %s" % stars

func _on_stamina_changed(current: float, max_val: float) -> void:
	_update_stamina_bar(current, max_val)

func _update_stamina_bar(current: float, max_val: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = current
	if stamina_label:
		stamina_label.text = "%d / %d" % [int(ceil(current)), int(max_val)]
	
	# Detail.md 4.2 color thresholds
	var ratio: float = current / max_val if max_val > 0 else 0.0
	var bar_color: Color
	if TimeManager.minutes >= GameConstants.TIRED_WARNING_MINUTES and fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.0:
		bar_color = Color("9B2D2B") # Flashing red late at night
	elif ratio > 0.5:
		bar_color = Color("5E9150") # Green
	elif ratio >= 0.3:
		bar_color = Color("FFC84A") # Yellow (30% - 50%)
	else:
		bar_color = Color("D4542B") # Orange (< 30%)
	
	if stamina_bar:
		stamina_bar.modulate = bar_color

func _on_tool_selected(slot_index: int, tool_data: Resource) -> void:
	_active_slot = slot_index
	_highlight_slot(slot_1, slot_index == 0)
	_highlight_slot(slot_2, slot_index == 1)
	_highlight_slot(slot_3, slot_index == 2)
	
	if tool_name_label:
		if tool_data and "display_name" in tool_data:
			tool_name_label.text = "[%d] %s" % [slot_index + 1, tool_data.display_name]
		else:
			tool_name_label.text = "[%d] Trống" % [slot_index + 1]

func _highlight_slot(slot_node: PanelContainer, is_active: bool) -> void:
	if slot_node:
		slot_node.modulate = Color("FFC84A") if is_active else Color(0.7, 0.7, 0.7, 0.9)

func _check_tired_vignette(minutes: int) -> void:
	if not tired_vignette:
		return
	if minutes >= GameConstants.TIRED_WARNING_MINUTES:
		var factor: float = float(minutes - GameConstants.TIRED_WARNING_MINUTES) / 120.0
		tired_vignette.modulate.a = clamp(factor * 0.45, 0.0, 0.45)
		tired_vignette.visible = true
	else:
		tired_vignette.visible = false

func _on_floating_text_requested(text: String, world_pos: Vector2, color: Color) -> void:
	if not floating_text_layer:
		return
	
	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.top_level = true
	label.global_position = world_pos
	floating_text_layer.add_child(label)
	
	var tween: Tween = create_tween()
	tween.tween_property(label, "global_position", world_pos + Vector2(0, -18), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_expedition_started(_expedition_id: StringName) -> void:
	if live_viewport_container:
		live_viewport_container.visible = true

func _on_expedition_finished(_id: StringName, _success: bool, _rank: StringName) -> void:
	# Hide after a short delay so player can see the loot phase
	get_tree().create_timer(3.5).timeout.connect(func():
		if live_viewport_container:
			live_viewport_container.visible = false
	)

func toggle_viewport_expand() -> void:
	if not sub_viewport or not live_viewport_container:
		return
	_is_viewport_expanded = !_is_viewport_expanded
	if _is_viewport_expanded:
		# Expand to 320x180 (DETAIL.md 8)
		sub_viewport.size = Vector2i(320, 180)
		live_viewport_container.custom_minimum_size = Vector2(320, 180)
	else:
		# Default 192x108
		sub_viewport.size = Vector2i(192, 108)
		live_viewport_container.custom_minimum_size = Vector2(192, 108)
