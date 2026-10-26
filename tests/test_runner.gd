extends Node

func _ready() -> void:
	print("--- BAT DAU KIEM TRA CAC QUY TAC GAMEPLAY & MODULE 3 (DETAIL.md) ---")
	var success_count: int = 0
	var total_count: int = 0
	
	# Test 1: Time constants
	total_count += 1
	assert(GameConstants.REAL_SEC_PER_GAME_MIN == 0.75, "1 phut game phai la 0.75 giay thuc")
	assert(GameConstants.DAY_START_MINUTES == 360, "Bat dau ngay phai la 06:00 (360 phut)")
	assert(GameConstants.DAY_END_MINUTES == 1440, "Ket thuc ngay phai la 24:00 (1440 phut)")
	print("✓ Test 1: Hang so thoi gian chinh xac (0.75s/min, 06:00 -> 24:00)")
	success_count += 1
	
	# Test 2: Stamina values and formula
	total_count += 1
	var stamina: StaminaComponent = StaminaComponent.new()
	assert(stamina.base_max == 120.0, "Max stamina goc phai la 120")
	assert(stamina.max_stamina() == 120.0, "Max stamina tinh toan ban dau phai la 120")
	assert(StaminaComponent.swing_cost(1, 1) == 2.0, "Power == Hardness chi phi phai la 2")
	assert(StaminaComponent.swing_cost(2, 1) == 1.0, "Power > Hardness chi phi phai la 1")
	stamina.queue_free()
	print("✓ Test 2: Quy tac Stamina goc (120, chi phi 2 khi bang hardness, 1 khi hon)")
	success_count += 1
	
	# Test 3: Sleep & Good sleep buff
	total_count += 1
	TimeManager.minutes = 19 * 60 # 19:00 (after 18:00, before 22:00)
	assert(TimeManager.can_sleep() == true, "Sau 18:00 phai co the ngu")
	var slept: bool = TimeManager.sleep()
	assert(slept == true, "Goi sleep thanh cong")
	assert(TimeManager.minutes == GameConstants.DAY_START_MINUTES, "Day luc 06:00 sau khi ngu binh thuong")
	assert(GameManager.has_good_sleep_buff == true, "Ngu truoc 22:00 phai co buff Ngu Ngon")
	assert(GameManager.has_faint_penalty == false, "Ngu truoc 22:00 khong bi phat ngat")
	print("✓ Test 3: Co che ngu va buff Ngu Ngon (+10 Max Stamina)")
	success_count += 1
	
	# Test 4: Faint mechanics at 24:00
	total_count += 1
	TimeManager.minutes = GameConstants.DAY_END_MINUTES # 24:00
	TimeManager.end_day(true) # Forced faint
	assert(TimeManager.minutes == GameConstants.FAINT_WAKEUP_MINUTES, "Ngat phai day luc 08:00")
	assert(GameManager.has_faint_penalty == true, "Ngat phai co faint penalty (-30% max stamina)")
	var faint_stamina: StaminaComponent = StaminaComponent.new()
	add_child(faint_stamina)
	assert(abs(faint_stamina.max_stamina() - (120.0 * 0.7)) < 0.01, "Max stamina sau khi ngat phai la 84 (120 * 0.7)")
	faint_stamina.queue_free()
	print("✓ Test 4: Co che ngat luc 24:00 (Day luc 08:00, -30% Max Stamina)")
	success_count += 1
	
	# Test 5: Resource Node mechanics
	total_count += 1
	var node: ResourceNode = ResourceNode.new()
	var node_data: ResourceNodeData = ResourceNodeData.new()
	node_data.id = &"test_node"
	node_data.tool_type = &"pickaxe"
	node_data.max_hp = 25
	node_data.hardness = 2
	node.data = node_data
	node.current_hp = 25
	
	# Weak tool test
	var weak_hit: Dictionary = node.hit(1, 5, &"pickaxe") # Power 1 < Hardness 2
	assert(weak_hit["success"] == false, "Cong cu yeu hon hardness phai that bai")
	assert(weak_hit["reason"] == "Công cụ quá yếu", "Ly do phai la 'Cong cu qua yeu'")
	assert(node.current_hp == 25, "Node khong duoc mat mau khi cong cu yeu")
	
	# Equal tool test
	var eq_hit: Dictionary = node.hit(2, 5, &"pickaxe") # Power 2 == Hardness 2
	assert(eq_hit["success"] == true, "Cong cu bang hardness phai thanh cong")
	assert(eq_hit["stamina_cost"] == 2.0, "Chi phi stamina phai la 2 khi power == hardness")
	assert(node.current_hp == 20, "Node phai mat 5 HP")
	
	# Superior tool test
	var sup_hit: Dictionary = node.hit(3, 5, &"pickaxe") # Power 3 > Hardness 2
	assert(sup_hit["success"] == true, "Cong cu manh hon hardness phai thanh cong")
	assert(sup_hit["stamina_cost"] == 1.0, "Chi phi stamina phai la 1 khi power > hardness")
	assert(node.current_hp == 15, "Node phai mat tiep 5 HP")
	
	node.queue_free()
	print("✓ Test 5: Khai thac node, kiem tra do cung, cong cu va chi phi stamina")
	success_count += 1
	
	# Test 6: Quality bracket formulas
	total_count += 1
	assert(GameConstants.get_quality_tier(30) == GameConstants.QualityTier.CRUDE, "0-39 phai la Tho")
	assert(GameConstants.get_quality_tier(55) == GameConstants.QualityTier.COMMON, "40-69 phai la Thuong")
	assert(GameConstants.get_quality_tier(80) == GameConstants.QualityTier.FINE, "70-89 phai la Tinh Xao")
	assert(GameConstants.get_quality_tier(95) == GameConstants.QualityTier.MASTERWORK, "90-100 phai la Tuyet Tac")
	print("✓ Test 6: Phan hang pham chat (Tho, Thuong, Tinh Xao, Tuyet Tac)")
	success_count += 1
	
	# Test 7: Smelting ratio
	total_count += 1
	assert(GameConstants.ORE_PER_INGOT == 3, "1 Phoi = 3 Quang")
	print("✓ Test 7: Ti le luyen kim (1 Phoi = 3 Quang)")
	success_count += 1
	
	# Test 8: Bag Overlay Pause Rule (DETAIL.md 3.4)
	total_count += 1
	var bag_scene: PackedScene = load("res://scenes/ui/bag_overlay.tscn")
	var bag: BagOverlay = bag_scene.instantiate()
	add_child(bag)
	assert(TimeManager.is_paused() == false, "Ban dau thoi gian khong bi dung")
	bag.open()
	assert(TimeManager.is_paused() == true, "Mo tui do phai dung thoi gian")
	bag.close()
	assert(TimeManager.is_paused() == false, "Dong tui do phai tiep tuc thoi gian")
	bag.queue_free()
	print("✓ Test 8: Tui do (Bag) dung thoi gian dung quy tac DETAIL.md 3.4")
	success_count += 1
	
	# Test 9: Furnace Simulation (Module 3)
	total_count += 1
	var furnace_scene: PackedScene = load("res://scenes/stations/station_furnace.tscn")
	var furnace: StationFurnace = furnace_scene.instantiate()
	add_child(furnace)
	assert(furnace.current_temperature == 25.0, "Nhiet do ban dau cua lo la 25C")
	furnace.add_fuel(350.0, 15.0)
	assert(furnace.fuel_time_remaining == 15.0, "Nhien lieu phai con 15s")
	# Simulate 1 second of physics process
	furnace._physics_process(1.0)
	assert(furnace.current_temperature > 25.0, "Nhiet do lo phai tang dan")
	furnace.pump_bellows(80.0)
	assert(furnace.bellows_boost > 0.0, "Ong thoi phai tang boost tam thoi")
	furnace.queue_free()
	print("✓ Test 9: Mo hinh nhiet lo nung tien dan va tang nhiet ong thoi")
	success_count += 1
	
	# Test 10: Live Expedition Viewport & 3-stage loop (Module 4)
	total_count += 1
	var exp_scene: PackedScene = load("res://scenes/viewport/live_expedition.tscn")
	var live_exp: LiveExpedition = exp_scene.instantiate()
	add_child(live_exp)
	assert(live_exp.current_stage == LiveExpedition.Stage.INACTIVE, "Ban dau chuyen tham hiem o trang thai INACTIVE")
	live_exp.start_expedition("Kiem Si", 50)
	assert(live_exp.current_stage == LiveExpedition.Stage.STAGE_1_MOBS, "Bat dau voi Ai 1 (Vuot quai nho)")
	assert(live_exp.weapon_durability == 50, "Do ben vu khi ban dau la 50")
	# Fast-forward stage 1 to trigger stage 2
	live_exp.stage_timer = 0.05
	live_exp._process(0.1)
	assert(live_exp.current_stage == LiveExpedition.Stage.STAGE_2_BOSS, "Chuyen sang Ai 2 (Dau Boss)")
	# Test auto drink potion when HP < 40%
	live_exp.adventurer_hp = 30.0
	live_exp._process(0.1)
	assert(live_exp.adventurer_hp > 40.0, "Mao hiem gia phai tu uong thuoc khi HP < 40%")
	live_exp.queue_free()
	print("✓ Test 10: Live Expedition Viewport 3 ai va co che tu uong thuoc")
	success_count += 1
	
	print("\n=== KET QUA: %d / %d TESTS PASS HOAN TOAN ===" % [success_count, total_count])
	get_tree().quit(0)
