extends Node

# --- System & Time Constants (DETAIL.md Section 3) ---
const REAL_SEC_PER_GAME_MIN: float = 0.75
const REAL_SEC_PER_GAME_HOUR: float = 45.0
const DAY_START_MINUTES: int = 6 * 60      # 06:00 (360)
const NOON_MINUTES: int = 12 * 60          # 12:00 (720)
const EVENING_MINUTES: int = 18 * 60       # 18:00 (1080) - Sleep available
const TIRED_WARNING_MINUTES: int = 22 * 60 # 22:00 (1320) - Vignette, half regen
const LATE_PENALTY_MINUTES: int = 23 * 60  # 23:00 (1380) - +25% action cost
const DAY_END_MINUTES: int = 24 * 60       # 24:00 (1440) - Faint if not asleep
const FAINT_WAKEUP_MINUTES: int = 8 * 60   # 08:00 (480)

# --- Stamina Constants (DETAIL.md Section 4) ---
const BASE_MAX_STAMINA: float = 120.0
const HARD_CAP_STAMINA: float = 200.0
const FAINT_STAMINA_PENALTY_MULT: float = 0.7 # -30% Max Stamina on faint day
const GOOD_SLEEP_BONUS_MAX: float = 10.0      # Sleep before 22:00
const NATURAL_REGEN_INTERVAL: float = 3.0    # 1 stamina per 3 sec
const IDLE_BEFORE_REGEN: float = 2.0         # 2 sec after last action
const HUB_REGEN_MULTIPLIER: float = 2.0      # 2x in Hub or near campfire

# --- Smelting / Crafting Rules (DETAIL.md Section 0, 5, 7) ---
const ORE_PER_INGOT: int = 3                 # 1 Ingot = 3 Ores

# --- Tool Types ---
const TOOL_PICKAXE: StringName = &"pickaxe"
const TOOL_AXE: StringName = &"axe"
const TOOL_SICKLE: StringName = &"sickle"

# --- Quality Brackets (DETAIL.md Section 7.4) ---
enum QualityTier {
	CRUDE,       # 0 - 39
	COMMON,      # 40 - 69
	FINE,        # 70 - 89
	MASTERWORK   # 90 - 100
}

static func get_quality_tier(score: int) -> QualityTier:
	if score < 40:
		return QualityTier.CRUDE
	elif score < 70:
		return QualityTier.COMMON
	elif score < 90:
		return QualityTier.FINE
	else:
		return QualityTier.MASTERWORK

static func get_quality_name(tier: QualityTier) -> String:
	match tier:
		QualityTier.CRUDE: return "Thô"
		QualityTier.COMMON: return "Thường"
		QualityTier.FINE: return "Tinh Xảo"
		QualityTier.MASTERWORK: return "Tuyệt Tác"
		_: return "Không rõ"

# --- Day/Night Ambient Light Color Keyframes (DETAIL.md Section 3.3) ---
const LIGHT_KEYFRAMES: Array[Dictionary] = [
	{"minute": 6 * 60, "color": Color("FFD9A8")},   # 06:00 Bình minh ấm
	{"minute": 9 * 60, "color": Color("FFFFFF")},   # 09:00 Ban ngày
	{"minute": 15 * 60, "color": Color("FFFFFF")},  # 15:00 Ban ngày
	{"minute": 18 * 60, "color": Color("FFB070")},  # 18:00 Hoàng hôn
	{"minute": 20 * 60, "color": Color("6A6FB0")},  # 20:00 Chạng vạng
	{"minute": 22 * 60, "color": Color("3A4278")},  # 22:00 Đêm
	{"minute": 24 * 60, "color": Color("252B55")}   # 24:00 Đêm sâu
]

static func sample_ambient_color(minute: int) -> Color:
	var count: int = LIGHT_KEYFRAMES.size()
	if minute <= LIGHT_KEYFRAMES[0]["minute"]:
		return LIGHT_KEYFRAMES[0]["color"]
	if minute >= LIGHT_KEYFRAMES[count - 1]["minute"]:
		return LIGHT_KEYFRAMES[count - 1]["color"]
	
	for i in range(count - 1):
		var k1: Dictionary = LIGHT_KEYFRAMES[i]
		var k2: Dictionary = LIGHT_KEYFRAMES[i + 1]
		var m1: int = k1["minute"]
		var m2: int = k2["minute"]
		if minute >= m1 and minute <= m2:
			var t: float = float(minute - m1) / float(m2 - m1)
			var c1: Color = k1["color"]
			var c2: Color = k2["color"]
			return c1.lerp(c2, t)
	return Color.WHITE
