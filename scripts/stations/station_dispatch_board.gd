class_name StationDispatchBoard extends StaticBody2D

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		_interact()

func _interact() -> void:
	# Dispatch an adventurer to Zone 1
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	var live_exp: LiveExpedition = null
	if hud:
		live_exp = hud.find_child("LiveExpedition", true, false)
	else:
		live_exp = get_tree().root.find_child("LiveExpedition", true, false)
		
	if live_exp:
		live_exp.start_expedition("Kiếm Sĩ Đồng", 50)
		EventBus.ui_notification.emit("Đã phái Kiếm Sĩ đi thám hiểm Bìa Rừng!", Color("FFC84A"))
	else:
		EventBus.ui_notification.emit("Bảng Ủy Thác: Chưa kết nối Live Viewport", Color("D4542B"))

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		if prompt_label:
			prompt_label.text = "[E] Bảng Ủy Thác"
			prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label:
			prompt_label.visible = false
