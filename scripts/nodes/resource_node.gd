class_name ResourceNode extends StaticBody2D

signal harvested(node: ResourceNode, items: Dictionary)

@export var data: ResourceNodeData

var current_hp: int = 0
var is_depleted: bool = false
var days_depleted: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_player: AnimationPlayer = $AnimationPlayer

var _original_sprite_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if sprite:
		_original_sprite_pos = sprite.position
	
	if data:
		current_hp = data.max_hp
		if data.texture_full and sprite:
			sprite.texture = data.texture_full
	
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.noon_reached.connect(_on_noon_reached)

func hit(tool_power: int, tool_dmg: int, tool_type: StringName) -> Dictionary:
	# Result dictionary: { "success": bool, "damage": int, "stamina_cost": float, "reason": String }
	var result: Dictionary = {
		"success": false,
		"damage": 0,
		"stamina_cost": 0.0,
		"reason": ""
	}
	
	if is_depleted:
		result["reason"] = "Node đã cạn kiệt"
		return result
	
	if not data:
		result["reason"] = "Không có dữ liệu node"
		return result
		
	if tool_type != data.tool_type:
		result["reason"] = "Sai loại công cụ"
		return result
	
	# Rule from DETAIL.md 4.4: Tool_Power >= Node_Hardness required
	if tool_power < data.hardness:
		result["reason"] = "Công cụ quá yếu"
		EventBus.floating_text_requested.emit("Công cụ quá yếu!", global_position + Vector2(0, -16), Color("CBD87F"))
		return result
	
	# Calculate stamina cost according to DETAIL.md 4.4
	var cost: float = StaminaComponent.swing_cost(tool_power, data.hardness)
	result["stamina_cost"] = cost
	result["success"] = true
	result["damage"] = tool_dmg
	
	current_hp -= tool_dmg
	_play_hit_feedback()
	
	EventBus.node_hit.emit(self, tool_dmg, max(0, current_hp))
	
	if current_hp <= 0:
		_deplete(tool_power)
	
	return result

func _deplete(tool_power: int) -> void:
	is_depleted = true
	days_depleted = 0
	
	if sprite and data.texture_depleted:
		sprite.texture = data.texture_depleted
	elif sprite:
		# Visual dimming if depleted texture not assigned
		sprite.modulate = Color(0.6, 0.6, 0.6, 0.7)
		
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	var drops_harvested: Dictionary = {}
	var over_tier_bonus: float = 0.10 if tool_power >= (data.hardness + 1) else 0.0
	
	for drop: DropEntry in data.drops:
		var chance: float = min(1.0, drop.chance + over_tier_bonus)
		if randf() <= chance:
			var amount: int = randi_range(drop.min_count, drop.max_count)
			if amount > 0:
				GameManager.add_item(drop.item_id, amount)
				drops_harvested[drop.item_id] = amount
				EventBus.floating_text_requested.emit("+%d %s" % [amount, drop.item_id], global_position + Vector2(0, -20), Color("FFC84A"))
	
	harvested.emit(self, drops_harvested)
	EventBus.node_depleted.emit(self, data.id)

func _play_hit_feedback() -> void:
	# Flash effect and slight shake
	if hit_player and hit_player.has_animation("hit"):
		hit_player.play("hit")
	else:
		_manual_hit_shake()

func _manual_hit_shake() -> void:
	if not sprite:
		return
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "position", _original_sprite_pos + Vector2(1, 0), 0.03)
	tween.tween_property(sprite, "position", _original_sprite_pos + Vector2(-1, 0), 0.03)
	tween.tween_property(sprite, "position", _original_sprite_pos, 0.03)

func _on_day_started(_day: int, _wakeup: int) -> void:
	if not is_depleted or not data:
		return
		
	days_depleted += 1
	
	match data.respawn_rule:
		&"daily", &"twice":
			respawn()
		&"rare":
			if randf() <= 0.60:
				respawn()
		&"two_days":
			if days_depleted >= 2:
				respawn()

func _on_noon_reached() -> void:
	if not is_depleted or not data:
		return
	# T0 nodes (Dry Shrub, Pebbles) respawn again at 12:00
	if data.respawn_rule == &"twice":
		respawn()

func respawn() -> void:
	if not is_depleted:
		return
	is_depleted = false
	days_depleted = 0
	if data:
		current_hp = data.max_hp
		if sprite and data.texture_full:
			sprite.texture = data.texture_full
		elif sprite:
			sprite.modulate = Color.WHITE
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
