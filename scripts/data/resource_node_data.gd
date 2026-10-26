class_name ResourceNodeData extends Resource

@export var id: StringName
@export var display_name: String
@export var tool_type: StringName              # &"pickaxe", &"axe", &"sickle"
@export var max_hp: int = 15
@export var hardness: int = 1
@export var drops: Array[DropEntry] = []
@export var respawn_rule: StringName = &"daily" # &"daily", &"twice", &"rare", &"two_days"
@export var texture_full: Texture2D
@export var texture_depleted: Texture2D
