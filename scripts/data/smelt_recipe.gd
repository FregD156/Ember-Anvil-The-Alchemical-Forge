class_name SmeltRecipe extends Resource

@export var id: StringName
@export var display_name: String
@export var input_ore_id: StringName = &"copper_ore"
@export var input_ore_count: int = 3         # DETAIL.md: 1 Ingot = 3 Ores
@export var melting_point: float = 300.0     # °C
@export var cook_duration: float = 6.0       # Seconds required in sweet spot
@export var output_item_id: StringName = &"copper_ingot"
@export var output_item_count: int = 1
