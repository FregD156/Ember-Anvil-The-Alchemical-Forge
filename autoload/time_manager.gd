extends Node

signal minute_changed(total_minutes: int)
signal hour_changed(hour: int)
signal day_started(day: int, wakeup_minute: int)
signal day_ended(forced: bool)
signal noon_reached()
signal evening_reached()
signal tired_warning_reached()

var day: int = 1
var minutes: int = GameConstants.DAY_START_MINUTES
var paused_by: Dictionary = {}   # source (StringName) -> bool
var _accum: float = 0.0

var _noon_triggered_today: bool = false
var _evening_triggered_today: bool = false
var _tired_triggered_today: bool = false

func _ready() -> void:
	# Initial emit
	minute_changed.emit(minutes)
	hour_changed.emit(int(minutes / 60))

func _process(delta: float) -> void:
	if not paused_by.is_empty():
		return
	
	_accum += delta
	while _accum >= GameConstants.REAL_SEC_PER_GAME_MIN:
		_accum -= GameConstants.REAL_SEC_PER_GAME_MIN
		_advance_minute()

func _advance_minute() -> void:
	minutes += 1
	minute_changed.emit(minutes)
	
	if minutes % 60 == 0:
		@warning_ignore("integer_division")
		hour_changed.emit(int(minutes / 60))
	
	if not _noon_triggered_today and minutes >= GameConstants.NOON_MINUTES:
		_noon_triggered_today = true
		noon_reached.emit()
		
	if not _evening_triggered_today and minutes >= GameConstants.EVENING_MINUTES:
		_evening_triggered_today = true
		evening_reached.emit()
		
	if not _tired_triggered_today and minutes >= GameConstants.TIRED_WARNING_MINUTES:
		_tired_triggered_today = true
		tired_warning_reached.emit()
	
	if minutes >= GameConstants.DAY_END_MINUTES:
		end_day(true)

func end_day(forced: bool) -> void:
	day_ended.emit(forced)
	day += 1
	
	_noon_triggered_today = false
	_evening_triggered_today = false
	_tired_triggered_today = false
	
	var wakeup: int = GameConstants.FAINT_WAKEUP_MINUTES if forced else GameConstants.DAY_START_MINUTES
	minutes = wakeup
	_accum = 0.0
	
	day_started.emit(day, wakeup)
	minute_changed.emit(minutes)
	@warning_ignore("integer_division")
	hour_changed.emit(int(minutes / 60))

func can_sleep() -> bool:
	return minutes >= GameConstants.EVENING_MINUTES

func sleep() -> bool:
	if not can_sleep():
		return false
	end_day(false)
	return true

func set_pause(source: StringName, on: bool) -> void:
	if on:
		paused_by[source] = true
	else:
		paused_by.erase(source)

func is_paused() -> bool:
	return not paused_by.is_empty()

func get_formatted_time() -> String:
	var h: int = int(minutes / 60)
	var m: int = minutes % 60
	return "%02d:%02d" % [h, m]

func get_day_period_name() -> String:
	if minutes < 12 * 60:
		return "Sáng"
	elif minutes < 18 * 60:
		return "Trưa"
	elif minutes < 22 * 60:
		return "Chiều tối"
	else:
		return "Đêm"
