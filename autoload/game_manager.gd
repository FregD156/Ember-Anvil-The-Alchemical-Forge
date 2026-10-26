extends Node

var gold: int = 100
var reputation: int = 1   # 1 to 5 stars

# Inventory storage: item_id (StringName) -> count (int)
var inventory: Dictionary = {}

# Active player buffs / debuffs for the day
var has_good_sleep_buff: bool = false
var has_faint_penalty: bool = false

# Daily tracker for Day Summary
var daily_gold_earned: int = 0
var daily_items_gathered: Dictionary = {}

func _ready() -> void:
	TimeManager.day_ended.connect(_on_day_ended)
	TimeManager.day_started.connect(_on_day_started)

func _on_day_ended(forced: bool) -> void:
	if forced:
		has_faint_penalty = true
		has_good_sleep_buff = false
		EventBus.player_fainted.emit()
	else:
		has_faint_penalty = false
		# Check if slept before 22:00
		if TimeManager.minutes < GameConstants.TIRED_WARNING_MINUTES:
			has_good_sleep_buff = true
		else:
			has_good_sleep_buff = false

func _on_day_started(_new_day: int, _wakeup_minute: int) -> void:
	daily_gold_earned = 0
	daily_items_gathered.clear()

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	if amount > 0:
		daily_gold_earned += amount
	EventBus.gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true

func add_item(item_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	var current: int = inventory.get(item_id, 0)
	inventory[item_id] = current + amount
	
	var day_current: int = daily_items_gathered.get(item_id, 0)
	daily_items_gathered[item_id] = day_current + amount
	
	EventBus.item_collected.emit(item_id, amount)
	EventBus.inventory_changed.emit()

func remove_item(item_id: StringName, amount: int) -> bool:
	var current: int = inventory.get(item_id, 0)
	if current < amount:
		return false
	var remaining: int = current - amount
	if remaining == 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = remaining
	EventBus.inventory_changed.emit()
	return true

func get_item_count(item_id: StringName) -> int:
	return inventory.get(item_id, 0)
