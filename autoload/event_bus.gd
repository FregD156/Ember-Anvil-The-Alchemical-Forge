extends Node

# --- Stamina & Player ---
signal stamina_changed(current: float, max_val: float)
signal player_exhausted(is_exhausted: bool)
signal player_fainted()
signal tool_selected(slot_index: int, tool_data: Resource)

# --- Gathering / Mining ---
signal node_hit(node_ref: Node, damage: int, remaining_hp: int)
signal node_depleted(node_ref: Node, resource_id: StringName)
signal item_collected(item_id: StringName, amount: int)
signal floating_text_requested(text: String, world_pos: Vector2, color: Color)

# --- Inventory & Economy ---
signal inventory_changed()
signal gold_changed(new_gold: int)
signal reputation_changed(new_rep: int)

# --- Stations / Crafting (Module 3 stubs) ---
signal furnace_temperature_changed(current_temp: float, target_temp: float)
signal item_crafted(item_id: StringName, quality: int)

# --- Dispatch / Expeditions (Module 4 stubs) ---
signal expedition_started(expedition_id: StringName)
signal expedition_progress_updated(stage: int, max_stages: int)
signal expedition_finished(expedition_id: StringName, success: bool, rank: StringName)

# --- General UI ---
signal ui_notification(message: String, color: Color)
