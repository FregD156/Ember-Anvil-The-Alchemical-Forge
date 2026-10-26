class_name ForgingOverlay extends Control

signal weapon_forged(recipe: WeaponRecipe, quality_score: int, tier: GameConstants.QualityTier)

enum State {
	IDLE,
	ANVIL_MINIGAME,
	GRINDER_MINIGAME,
	RESULT
}

var current_state: State = State.IDLE
var active_recipe: WeaponRecipe = null

var anvil_strikes_left: int = 3
var anvil_score: int = 0
var anvil_cursor_pos: float = 0.0 # 0.0 to 1.0
var anvil_cursor_dir: float = 1.0

var grinder_timer: float = 3.0
var grinder_score: float = 0.0
var grinder_is_pressing: bool = false
var grinder_pressure: float = 0.5 # 0.0 to 1.0

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var desc_label: Label = $Panel/Margin/VBox/DescLabel

# Anvil controls
@onready var anvil_container: VBoxContainer = $Panel/Margin/VBox/AnvilContainer
@onready var anvil_slider_track: Control = $Panel/Margin/VBox/AnvilContainer/SliderTrack
@onready var anvil_cursor: ColorRect = $Panel/Margin/VBox/AnvilContainer/SliderTrack/Cursor
@onready var anvil_strikes_label: Label = $Panel/Margin/VBox/AnvilContainer/StrikesLabel

# Grinder controls
@onready var grinder_container: VBoxContainer = $Panel/Margin/VBox/GrinderContainer
@onready var grinder_bar: ProgressBar = $Panel/Margin/VBox/GrinderContainer/GrinderBar
@onready var grinder_timer_label: Label = $Panel/Margin/VBox/GrinderContainer/TimerLabel

# Result controls
@onready var result_container: VBoxContainer = $Panel/Margin/VBox/ResultContainer
@onready var result_score_label: Label = $Panel/Margin/VBox/ResultContainer/ScoreLabel
@onready var result_rank_label: Label = $Panel/Margin/VBox/ResultContainer/RankLabel
@onready var result_stats_label: Label = $Panel/Margin/VBox/ResultContainer/StatsLabel

# Actions
@onready var start_button: Button = $Panel/Margin/VBox/Actions/StartButton
@onready var close_button: Button = $Panel/Margin/VBox/Actions/CloseButton

func _ready() -> void:
	visible = false
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if close_button:
		close_button.pressed.connect(close)

func open_for_crafting(recipe: WeaponRecipe) -> void:
	active_recipe = recipe
	current_state = State.IDLE
	visible = true
	# DETAIL.md 3.4: Anvil & Grinder do NOT pause time
	_update_ui_state()

func close() -> void:
	visible = false
	current_state = State.IDLE

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		close()
		return
		
	if current_state == State.ANVIL_MINIGAME:
		if event.is_action_pressed("action_tool") or event.is_action_pressed("ui_accept"):
			_on_anvil_hit()
	elif current_state == State.GRINDER_MINIGAME:
		if event.is_action_pressed("action_tool") or event.is_action_pressed("ui_accept"):
			grinder_is_pressing = true
		elif event.is_action_released("action_tool") or event.is_action_released("ui_accept"):
			grinder_is_pressing = false

func _process(delta: float) -> void:
	if not visible:
		return
		
	if current_state == State.ANVIL_MINIGAME:
		_process_anvil(delta)
	elif current_state == State.GRINDER_MINIGAME:
		_process_grinder(delta)

func _process_anvil(delta: float) -> void:
	# Cursor bounces back and forth across 120px track
	anvil_cursor_pos += anvil_cursor_dir * (delta * 1.8)
	if anvil_cursor_pos >= 1.0:
		anvil_cursor_pos = 1.0
		anvil_cursor_dir = -1.0
	elif anvil_cursor_pos <= 0.0:
		anvil_cursor_pos = 0.0
		anvil_cursor_dir = 1.0
		
	if anvil_cursor:
		var track_w: float = 120.0
		anvil_cursor.position.x = anvil_cursor_pos * (track_w - 6.0)

func _on_anvil_hit() -> void:
	# Calculate score for this strike (max 15 per strike, 3 strikes = 45 max)
	# Center is at 0.50
	var dist: float = abs(anvil_cursor_pos - 0.50)
	var pts: int = 0
	if dist <= 0.08:
		pts = 15 # Perfect gold sweet spot
		EventBus.floating_text_requested.emit("HOÀN HẢO! +15", global_position + Vector2(0, -20), Color("FFC84A"))
	elif dist <= 0.20:
		pts = 10 # Good green zone
		EventBus.floating_text_requested.emit("TỐT! +10", global_position + Vector2(0, -20), Color("5E9150"))
	else:
		pts = 5 # Edge hit
		EventBus.floating_text_requested.emit("MÉP! +5", global_position + Vector2(0, -20), Color("9A8FA3"))
		
	anvil_score += pts
	anvil_strikes_left -= 1
	if anvil_strikes_label:
		anvil_strikes_label.text = "Số nhát búa còn lại: %d (Điểm: %d/45)" % [anvil_strikes_left, anvil_score]
		
	if anvil_strikes_left <= 0:
		_start_grinder_phase()

func _start_grinder_phase() -> void:
	# Check stamina for grinder phase (DETAIL.md 4.4: 5 stamina)
	var player: Player = get_tree().get_first_node_in_group("player")
	if player and player.stamina_component:
		player.stamina_component.spend(5.0)
		
	current_state = State.GRINDER_MINIGAME
	grinder_timer = 3.0
	grinder_score = 0.0
	grinder_pressure = 0.5
	_update_ui_state()

func _process_grinder(delta: float) -> void:
	# Holding key increases pressure, releasing decreases pressure
	if grinder_is_pressing:
		grinder_pressure = min(1.0, grinder_pressure + (0.9 * delta))
	else:
		grinder_pressure = max(0.0, grinder_pressure - (0.7 * delta))
		
	if grinder_bar:
		grinder_bar.value = grinder_pressure * 100.0
		
	# Ideal pressure zone: 0.40 to 0.70
	if grinder_pressure >= 0.40 and grinder_pressure <= 0.70:
		grinder_score += (55.0 / 3.0) * delta # accumulates to 55 max over 3s
		
	grinder_timer -= delta
	if grinder_timer_label:
		grinder_timer_label.text = "Thời gian mài: %.1fs (Giữ [Space]/Chuột để ép lực)" % max(0.0, grinder_timer)
		
	if grinder_timer <= 0.0:
		_finish_crafting()

func _finish_crafting() -> void:
	current_state = State.RESULT
	var total_q: int = clamp(anvil_score + int(round(grinder_score)), 0, 100)
	var tier: GameConstants.QualityTier = GameConstants.get_quality_tier(total_q)
	var rank_name: String = GameConstants.get_quality_name(tier)
	
	# Stat multipliers according to DETAIL.md 7.4
	var atk_mult: float = 1.0
	var dur_mult: float = 1.0
	var price_mult: float = 1.0
	
	match tier:
		GameConstants.QualityTier.CRUDE:
			atk_mult = 0.8; dur_mult = 0.7; price_mult = 0.8
		GameConstants.QualityTier.COMMON:
			atk_mult = 1.0; dur_mult = 1.0; price_mult = 1.0
		GameConstants.QualityTier.FINE:
			atk_mult = 1.25; dur_mult = 1.3; price_mult = 1.5
		GameConstants.QualityTier.MASTERWORK:
			atk_mult = 1.5; dur_mult = 1.6; price_mult = 2.5
			
	var final_atk: int = int(round(active_recipe.base_atk * atk_mult))
	var final_dur: int = int(round(active_recipe.base_durability * dur_mult))
	var final_price: int = int(round(active_recipe.base_price * price_mult))
	
	# Add crafted weapon item
	GameManager.add_item(active_recipe.id, 1)
	
	if result_score_label:
		result_score_label.text = "Tổng điểm Phẩm chất (Q): %d / 100\n(Đe: %d/45 | Đá Mài: %d/55)" % [total_q, anvil_score, int(round(grinder_score))]
	if result_rank_label:
		result_rank_label.text = "Xếp hạng: %s" % rank_name
		result_rank_label.modulate = Color("FFC84A") if tier == GameConstants.QualityTier.MASTERWORK else Color("FFFFFF")
	if result_stats_label:
		result_stats_label.text = "ATK: %d | Độ bền: %d | Giá bán: %d Vàng" % [final_atk, final_dur, final_price]
		
	weapon_forged.emit(active_recipe, total_q, tier)
	EventBus.item_crafted.emit(active_recipe.id, total_q)
	EventBus.ui_notification.emit("Rèn xong %s [%s]!" % [active_recipe.display_name, rank_name], Color("FFC84A"))
	_update_ui_state()

func _update_ui_state() -> void:
	anvil_container.visible = (current_state == State.ANVIL_MINIGAME)
	grinder_container.visible = (current_state == State.GRINDER_MINIGAME)
	result_container.visible = (current_state == State.RESULT)
	start_button.visible = (current_state == State.IDLE)
	
	if current_state == State.IDLE:
		title_label.text = "ĐE RÈN & ĐÁ MÀI"
		if active_recipe:
			desc_label.text = "Chế tạo: %s\nYêu cầu: %d %s (Hiện có: %d)" % [
				active_recipe.display_name,
				active_recipe.required_ingot_count,
				active_recipe.required_ingot_id,
				GameManager.get_item_count(active_recipe.required_ingot_id)
			]
	elif current_state == State.ANVIL_MINIGAME:
		title_label.text = "BƯỚC 1: ĐE RÈN (ĐỊNH HÌNH)"
		desc_label.text = "Bấm [Space] hoặc Chuột khi con trỏ vào vùng Xanh / Vàng!"
	elif current_state == State.GRINDER_MINIGAME:
		title_label.text = "BƯỚC 2: ĐÁ MÀI (MÀI SẮC)"
		desc_label.text = "Giữ phím để ép lưỡi kiếm vào đá trong vùng lý tưởng!"
	elif current_state == State.RESULT:
		title_label.text = "KẾT QUẢ RÈN KIM"
		desc_label.text = "Vũ khí đã hoàn thiện và cất vào kho đồ."

func _on_start_pressed() -> void:
	if not active_recipe:
		return
		
	var needed_ingots: int = active_recipe.required_ingot_count
	var ingot_id: StringName = active_recipe.required_ingot_id
	if GameManager.get_item_count(ingot_id) < needed_ingots:
		EventBus.ui_notification.emit("Không đủ phôi kim loại để rèn (cần %d %s)!" % [needed_ingots, ingot_id], Color("D4542B"))
		return
		
	var player: Player = get_tree().get_first_node_in_group("player")
	if player and player.stamina_component:
		# DETAIL.md 4.4: 5 stamina for anvil phase
		if not player.stamina_component.spend(5.0):
			EventBus.ui_notification.emit("Không đủ thể lực để bắt đầu rèn (cần 5 thể lực)!", Color("D4542B"))
			return
			
	GameManager.remove_item(ingot_id, needed_ingots)
	current_state = State.ANVIL_MINIGAME
	anvil_strikes_left = 3
	anvil_score = 0
	anvil_cursor_pos = 0.0
	anvil_cursor_dir = 1.0
	if anvil_strikes_label:
		anvil_strikes_label.text = "Số nhát búa còn lại: 3 (Điểm: 0/45)"
	_update_ui_state()
