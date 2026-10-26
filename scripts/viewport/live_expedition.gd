class_name LiveExpedition extends Node2D

signal stage_changed(stage: int)
signal expedition_completed(success: bool, rank: StringName, rewards: Dictionary)

enum Stage {
	INACTIVE,
	STAGE_1_MOBS,    # Vượt quái nhỏ (tiêu hao độ bền vũ khí)
	STAGE_2_BOSS,    # Quyết đấu Boss (kiểm tra ECP & nguyên tố)
	STAGE_3_LOOT     # Mở rương tổng kết
}

var current_stage: Stage = Stage.INACTIVE
var stage_timer: float = 0.0

# Expedition stats
var adventurer_name: String = "Kiếm Sĩ Tập Sự"
var adventurer_hp: float = 100.0
var adventurer_max_hp: float = 100.0
var weapon_durability: int = 50
var potions_count: int = 2

var boss_hp: float = 120.0
var boss_max_hp: float = 120.0

@onready var stage_label: Label = $HUD/StageLabel
@onready var adv_hp_bar: ProgressBar = $HUD/AdventurerHpBar
@onready var boss_container: Control = $HUD/BossContainer
@onready var boss_hp_bar: ProgressBar = $HUD/BossContainer/BossHpBar
@onready var adventurer_sprite: Sprite2D = $World/AdventurerSprite
@onready var monster_sprite: Sprite2D = $World/MonsterSprite

func _ready() -> void:
	if boss_container:
		boss_container.visible = false
	_update_hud()

func start_expedition(adv_archetype: String = "Kiếm Sĩ", starting_durability: int = 50) -> void:
	adventurer_name = adv_archetype
	weapon_durability = starting_durability
	adventurer_hp = 100.0
	adventurer_max_hp = 100.0
	potions_count = 2
	boss_hp = 120.0
	boss_max_hp = 120.0
	
	current_stage = Stage.STAGE_1_MOBS
	stage_timer = 12.0 # 12 seconds in Stage 1
	if boss_container:
		boss_container.visible = false
	_update_hud()
	stage_changed.emit(1)
	EventBus.expedition_started.emit(&"expedition_zone_1")
	EventBus.floating_text_requested.emit("Chuyến thám hiểm bắt đầu!", Vector2(320, 40), Color("86BFAE"))

func _process(delta: float) -> void:
	if current_stage == Stage.INACTIVE:
		return
		
	stage_timer -= delta
	
	# Simulate combat loop
	match current_stage:
		Stage.STAGE_1_MOBS:
			_process_stage_1(delta)
		Stage.STAGE_2_BOSS:
			_process_stage_2(delta)
		Stage.STAGE_3_LOOT:
			_process_stage_3(delta)
			
	_update_hud()

func _process_stage_1(delta: float) -> void:
	# Subtle bobbing animation
	if adventurer_sprite:
		adventurer_sprite.position.y = 70.0 + sin(Time.get_ticks_msec() / 150.0) * 2.0
	if monster_sprite:
		monster_sprite.position.y = 70.0 + cos(Time.get_ticks_msec() / 180.0) * 2.0
		
	# Consume weapon durability periodically (DETAIL.md 8)
	if fmod(stage_timer, 3.0) < delta and weapon_durability > 0:
		weapon_durability -= 1
		
	if stage_timer <= 0.0:
		# Transition to Stage 2: Boss Duel
		current_stage = Stage.STAGE_2_BOSS
		stage_timer = 16.0
		if boss_container:
			boss_container.visible = true
		stage_changed.emit(2)
		EventBus.expedition_progress_updated.emit(2, 3)

func _process_stage_2(delta: float) -> void:
	# Duel boss
	boss_hp = max(0.0, boss_hp - (10.0 * delta))
	adventurer_hp = max(0.0, adventurer_hp - (4.0 * delta))
	
	# Auto drink potion when HP < 40% (DETAIL.md 8: "tự uống máu khi HP dưới 40%")
	if adventurer_hp < 40.0 and potions_count > 0:
		potions_count -= 1
		adventurer_hp = min(adventurer_max_hp, adventurer_hp + 45.0)
		EventBus.floating_text_requested.emit("Mạo hiểm giả uống thuốc hồi sinh lực!", Vector2(320, 60), Color("FFC84A"))
		
	if boss_hp <= 0.0 or stage_timer <= 0.0:
		# Transition to Stage 3: Loot summary
		current_stage = Stage.STAGE_3_LOOT
		stage_timer = 6.0
		if boss_container:
			boss_container.visible = false
		stage_changed.emit(3)
		EventBus.expedition_progress_updated.emit(3, 3)

func _process_stage_3(_delta: float) -> void:
	if stage_timer <= 0.0:
		_complete_expedition()

func _complete_expedition() -> void:
	current_stage = Stage.INACTIVE
	var success: bool = adventurer_hp > 0.0
	var rank: StringName = &"S-Rank" if (success and weapon_durability >= 35) else &"A-Rank"
	
	var rewards: Dictionary = {
		"gold": 150 if success else 30,
		"reputation": 1 if success else 0,
		"rare_material": "Mảnh Lõi Rừng" if rank == &"S-Rank" else "Quặng Đồng x5"
	}
	
	if success:
		GameManager.add_gold(rewards["gold"])
		EventBus.floating_text_requested.emit("+%d Vàng từ Thám hiểm (%s)!" % [rewards["gold"], rank], Vector2(320, 40), Color("FFC84A"))
	
	expedition_completed.emit(success, rank, rewards)
	EventBus.expedition_finished.emit(&"expedition_zone_1", success, rank)
	EventBus.ui_notification.emit("Chuyến thám hiểm hoàn tất! Xếp hạng: %s" % rank, Color("FFC84A"))

func _update_hud() -> void:
	if adv_hp_bar:
		adv_hp_bar.value = adventurer_hp
	if boss_hp_bar:
		boss_hp_bar.value = boss_hp
	if stage_label:
		match current_stage:
			Stage.INACTIVE:
				stage_label.text = "Không có chuyến đi"
			Stage.STAGE_1_MOBS:
				stage_label.text = "ẢI 1/3: VƯỢT QUÁI"
			Stage.STAGE_2_BOSS:
				stage_label.text = "ẢI 2/3: ĐẤU BOSS"
			Stage.STAGE_3_LOOT:
				stage_label.text = "ẢI 3/3: RƯƠNG THƯỞNG"
