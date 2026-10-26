class_name WeaponRecipe extends Resource

@export var id: StringName
@export var display_name: String
@export var branch: StringName = &"balanced"  # &"speed", &"balanced", &"heavy"
@export var required_ingot_id: StringName = &"copper_ingot"
@export var required_ingot_count: int = 2     # DETAIL.md 7.3
@export var base_atk: int = 15
@export var base_durability: int = 50
@export var base_price: int = 30
