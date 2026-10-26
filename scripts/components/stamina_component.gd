class_name StaminaComponent extends Node

signal changed(value: float, max_value: float)

@export var base_max: float = 120.0
var bonus_max: float = 0.0
var penalty_mult: float = 1.0        # 0.7 khi bị phạt ngất
var value: float = 120.0
var in_safe_zone: bool = false
var _idle_timer: float = 0.0
var _regen_accum: float = 0.0

func _ready() -> void:
	TimeManager.day_started.connect(_on_day_started)
	_sync_buffs_and_reset()

func _on_day_started(_day: int, _wakeup: int) -> void:
	_sync_buffs_and_reset()

func _sync_buffs_and_reset() -> void:
	if GameManager.has_faint_penalty:
		penalty_mult = GameConstants.FAINT_STAMINA_PENALTY_MULT
	else:
		penalty_mult = 1.0
	
	if GameManager.has_good_sleep_buff:
		bonus_max = GameConstants.GOOD_SLEEP_BONUS_MAX
	else:
		bonus_max = 0.0
	
	value = max_stamina()
	_idle_timer = 0.0
	_regen_accum = 0.0
	changed.emit(value, max_stamina())
	EventBus.stamina_changed.emit(value, max_stamina())

func max_stamina() -> float:
	return min((base_max + bonus_max) * penalty_mult, GameConstants.HARD_CAP_STAMINA)

static func swing_cost(power: int, hardness: int) -> float:
	# Power == Hardness: 2, Power > Hardness: 1
	return 2.0 if power == hardness else 1.0

func spend(amount: float) -> bool:
	var late_mult: float = 1.25 if TimeManager.minutes >= GameConstants.LATE_PENALTY_MINUTES else 1.0
	var cost: float = amount * late_mult
	if value < cost:
		return false
	value -= cost
	_idle_timer = 0.0
	changed.emit(value, max_stamina())
	EventBus.stamina_changed.emit(value, max_stamina())
	if value <= 0.0:
		EventBus.player_exhausted.emit(true)
	return true

func restore(amount: float) -> void:
	value = min(value + amount, max_stamina())
	changed.emit(value, max_stamina())
	EventBus.stamina_changed.emit(value, max_stamina())
	if value > 0.0:
		EventBus.player_exhausted.emit(false)

func _process(delta: float) -> void:
	_idle_timer += delta
	if _idle_timer < GameConstants.IDLE_BEFORE_REGEN:
		return
	
	var rate: float = 1.0 / GameConstants.NATURAL_REGEN_INTERVAL
	if TimeManager.minutes >= GameConstants.TIRED_WARNING_MINUTES:
		rate *= 0.5
	if in_safe_zone:
		rate *= GameConstants.HUB_REGEN_MULTIPLIER
	
	_regen_accum += rate * delta
	if _regen_accum >= 1.0:
		var add_val: float = floor(_regen_accum)
		value = min(value + add_val, max_stamina())
		_regen_accum = fmod(_regen_accum, 1.0)
		changed.emit(value, max_stamina())
		EventBus.stamina_changed.emit(value, max_stamina())
		if value > 0.0:
			EventBus.player_exhausted.emit(false)
