class_name StationBed extends StaticBody2D

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		_try_sleep()

func _try_sleep() -> void:
	if not TimeManager.can_sleep():
		EventBus.floating_text_requested.emit("Chỉ có thể ngủ từ 18:00!", global_position + Vector2(0, -20), Color("FFC84A"))
		return
	
	var is_good_sleep: bool = TimeManager.minutes < GameConstants.TIRED_WARNING_MINUTES
	TimeManager.sleep()
	
	if is_good_sleep:
		EventBus.floating_text_requested.emit("Ngủ ngon (+10 Max Thể Lực)!", global_position + Vector2(0, -20), Color("8AD04A"))
	else:
		EventBus.floating_text_requested.emit("Đã ngủ đến 06:00 sáng!", global_position + Vector2(0, -20), Color("FFFFFF"))

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		if prompt_label:
			prompt_label.text = "[E] Đi ngủ (Từ 18:00)"
			prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label:
			prompt_label.visible = false
