class_name Player extends CharacterBody2D

const BASE_SPEED: float = 80.0
const TIRED_SPEED_MULT: float = 0.8

@export var tool_slots: Array[ToolData] = [null, null, null]
@export var active_slot_index: int = 0

@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var facing_direction: Vector2 = Vector2.DOWN
var is_swinging: bool = false
var is_exhausted: bool = false

func _ready() -> void:
	EventBus.player_exhausted.connect(_on_player_exhausted)
	
	# Load starting tools if not set
	if tool_slots[0] == null and ResourceLoader.exists("res://data/tools/tool_pickaxe_t0.tres"):
		tool_slots[0] = load("res://data/tools/tool_pickaxe_t0.tres")
	if tool_slots[1] == null and ResourceLoader.exists("res://data/tools/tool_axe_t0.tres"):
		tool_slots[1] = load("res://data/tools/tool_axe_t0.tres")
	if tool_slots[2] == null and ResourceLoader.exists("res://data/tools/tool_sickle_t0.tres"):
		tool_slots[2] = load("res://data/tools/tool_sickle_t0.tres")
	
	_select_slot(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_slot_1"):
		_select_slot(0)
	elif event.is_action_pressed("tool_slot_2"):
		_select_slot(1)
	elif event.is_action_pressed("tool_slot_3"):
		_select_slot(2)
	elif event.is_action_pressed("action_tool"):
		_try_swing_tool()

func _physics_process(_delta: float) -> void:
	if is_swinging:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector != Vector2.ZERO:
		# Discrete 4-way facing direction
		if abs(input_vector.x) > abs(input_vector.y):
			facing_direction = Vector2.RIGHT if input_vector.x > 0 else Vector2.LEFT
		else:
			facing_direction = Vector2.DOWN if input_vector.y > 0 else Vector2.UP
		
		interaction_ray.target_position = facing_direction * 18.0
		
		# Flip sprite when facing left
		if facing_direction == Vector2.LEFT:
			sprite.flip_h = true
		elif facing_direction == Vector2.RIGHT:
			sprite.flip_h = false

	var current_speed: float = BASE_SPEED * (TIRED_SPEED_MULT if is_exhausted else 1.0)
	velocity = input_vector.normalized() * current_speed
	move_and_slide()

func _select_slot(index: int) -> void:
	if index < 0 or index >= tool_slots.size():
		return
	active_slot_index = index
	var active_tool: ToolData = tool_slots[index]
	EventBus.tool_selected.emit(index, active_tool)

func get_active_tool() -> ToolData:
	return tool_slots[active_slot_index]

func _try_swing_tool() -> void:
	if is_swinging:
		return
		
	# DETAIL.md 4.2: Stamina = 0 cannot swing
	if stamina_component.value <= 0:
		EventBus.floating_text_requested.emit("Kiệt sức!", global_position + Vector2(0, -16), Color("D4542B"))
		return
		
	var active_tool: ToolData = get_active_tool()
	if not active_tool:
		EventBus.floating_text_requested.emit("Chưa trang bị công cụ!", global_position + Vector2(0, -16), Color("CBD87F"))
		return
	
	is_swinging = true
	
	# Swing animation speed is -15% if stamina < 30% (DETAIL.md 4.2)
	var swing_speed: float = 0.85 if (stamina_component.value / stamina_component.max_stamina()) < 0.3 else 1.0
	
	if anim_player and anim_player.has_animation("swing"):
		anim_player.play("swing", -1, swing_speed)
	else:
		# Fallback programmatic swing duration (frame 3 hits at ~0.15s)
		get_tree().create_timer(0.12 / swing_speed).timeout.connect(_on_swing_impact)
		get_tree().create_timer(0.24 / swing_speed).timeout.connect(_on_swing_finished)

func _on_swing_impact() -> void:
	var active_tool: ToolData = get_active_tool()
	if not active_tool:
		return
		
	if interaction_ray.is_colliding():
		var collider: Object = interaction_ray.get_collider()
		if collider is ResourceNode:
			var hit_res: Dictionary = collider.hit(active_tool.power, active_tool.dmg, active_tool.tool_type)
			if hit_res.get("success", false):
				var cost: float = hit_res.get("stamina_cost", 1.0)
				stamina_component.spend(cost)
			elif hit_res.get("reason", "") != "":
				var reason: String = hit_res.get("reason")
				EventBus.floating_text_requested.emit(reason, global_position + Vector2(0, -16), Color("CBD87F"))

func _on_swing_finished() -> void:
	is_swinging = false

func _on_player_exhausted(exhausted: bool) -> void:
	is_exhausted = exhausted
