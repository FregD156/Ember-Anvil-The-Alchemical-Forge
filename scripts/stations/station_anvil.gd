class_name StationAnvil extends StaticBody2D

@export var default_recipe: WeaponRecipe

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if default_recipe == null and ResourceLoader.exists("res://data/recipes/weapon_sword.tres"):
		default_recipe = load("res://data/recipes/weapon_sword.tres")

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		_interact()

func _interact() -> void:
	var forging_ui: ForgingOverlay = get_tree().root.find_child("ForgingOverlay", true, false)
	if forging_ui and default_recipe:
		forging_ui.open_for_crafting(default_recipe)
	else:
		EventBus.ui_notification.emit("Chưa tải được giao diện Đe Rèn!", Color("D4542B"))

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		if prompt_label:
			prompt_label.text = "[E] Đe Rèn"
			prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label:
			prompt_label.visible = false
