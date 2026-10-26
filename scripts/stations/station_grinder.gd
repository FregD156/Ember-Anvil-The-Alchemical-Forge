class_name StationGrinder extends StaticBody2D

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		_interact()

func _interact() -> void:
	EventBus.ui_notification.emit("Đá Mài: Tự động kết nối trong quy trình rèn sau khi đập búa trên Đe!", Color("FFC84A"))

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		if prompt_label:
			prompt_label.text = "[E] Đá Mài"
			prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label:
			prompt_label.visible = false
