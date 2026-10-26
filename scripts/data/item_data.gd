class_name ItemData extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var category: StringName     # &"wood", &"ore", &"herb", &"fuel", &"ingot", etc.
@export var tier: int = 0
@export var icon: Texture2D
@export var base_sell_price: int = 1
