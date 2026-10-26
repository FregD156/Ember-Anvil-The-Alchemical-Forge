class_name SafeZoneArea extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.stamina_component:
		body.stamina_component.in_safe_zone = true
		EventBus.floating_text_requested.emit("Khu vực an toàn (Hồi phục x2)", body.global_position + Vector2(0, -18), Color("86BFAE"))

func _on_body_exited(body: Node2D) -> void:
	if body is Player and body.stamina_component:
		body.stamina_component.in_safe_zone = false
