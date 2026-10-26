# TIẾN ĐỘ DỰ ÁN (TODO.MD) - EMBER & ANVIL: THE ALCHEMICAL FORGE

**Cập nhật lần cuối:** 2026-10-26 (Bản v0.2 - Hoàn thiện Module 3 & Module 4 & Hệ thống Túi đồ)  
**Engine:** Godot 4.x (GDScript 2.0) | **Độ phân giải:** 640x360 (Pixel-perfect snap)  
**Tài liệu tham chiếu:** `DETAIL.md` (GDD), `ART_PROMPTS.md` (Art Bible), `AGENTS.md` (Quy tắc agent), `docx/ideal.md` (Cảm hứng & Gameplay tham chiếu).

---

## 1. TỔNG QUAN HẠNG MỤC & TRẠNG THÁI

| Hạng mục | Trạng thái | Ghi chú |
|---|---|---|
| **Khởi tạo Project Godot 4.x** | Hoàn thành | Thiết lập display 640x360, Nearest filter, snap pixel, input actions |
| **Autoloads & Hằng số (`TimeManager`, `GameConstants`, `EventBus`, `GameManager`)** | Hoàn thành | Đúng 100% công thức từ `DETAIL.md` |
| **Hệ thống Stamina (`StaminaComponent`)** | Hoàn thành | Base 120/200, chi phí theo Power/Hardness, hồi x2 tại Safe Zone, phạt kiệt sức & thức khuya |
| **Dữ liệu Data-driven (`Resource`)** | Hoàn thành | `DropEntry`, `ItemData`, `ToolData`, `ResourceNodeData`, `SmeltRecipe`, `WeaponRecipe` |
| **Bộ 5 Shaders bắt buộc** | Hoàn thành | `palette_swap`, `hit_flash`, `outline_select`, `heat_shimmer`, `masterwork_glow` |
| **Khai thác tài nguyên (`ResourceNode`)** | Hoàn thành | Kiểm tra Power >= Hardness, tính số nhát `ceil(HP/DMG)`, rơi đồ, respawn theo giờ (06:00, 12:00) |
| **Điều khiển Người chơi (`Player`)** | Hoàn thành | Top-down 80px/s (-20% khi stamina=0), 3 slot công cụ (1, 2, 3), vung công cụ, tương tác node |
| **Giao diện Túi đồ (`BagOverlay` - Phím B)** | Hoàn thành | Lưới 20 ô (5x4), nút Sắp xếp (`Sort`), xem chi tiết, **dừng thời gian** theo quy tắc GDD |
| **Module 3: Lò nung & Nhiệt lượng (`StationFurnace` & `SmelterOverlay`)** | Hoàn thành | Mô hình nhiệt tiến dần, Sweet Spot, Overheat (phôi Giòn), bơm ống thổi (-2 stamina), 1 Phôi = 3 Quặng, **không dừng thời gian** |
| **Module 3: Mini-game Đe Rèn & Đá Mài (`ForgingOverlay` & `StationAnvil`, `StationGrinder`)** | Hoàn thành | Đe rèn căn nhịp thanh trượt (max 45đ), Đá mài ép lực 3s (max 55đ), tính phẩm chất Q (Thô, Thường, Tinh Xảo, Tuyệt Tác) |
| **Module 4: Live Expedition Viewport (`LiveExpedition`)** | Hoàn thành | Side-view 192x108 (phóng to 320x180), 3 ải (Vượt quái, Đấu Boss, Rương thưởng), tiêu hao độ bền, tự uống thuốc khi HP < 40% |
| **Module 4: Bảng Ủy Thác (`StationDispatchBoard`)** | Hoàn thành | Đặt tại góc Tây Bắc Forge Hub, phái mạo hiểm giả kích hoạt Live Viewport |
| **Xưởng Rèn Forge Hub & Safe Zone** | Hoàn thành | Hoàn chỉnh dây chuyền: `Bảng Ủy Thác` → `Kho đồ` → `LÒ NUNG` → `ĐE RÈN` → `ĐÁ MÀI` → `GIƯỜNG NGỦ` |
| **Zone 1: Bìa Rừng Thông (Thử nghiệm)** | Hoàn thành | Bố trí Bụi cây khô, Đá cuội, Mỏ đồng nông, Cây thông |
| **Công cụ hậu xử lý ảnh (`postprocess.py`)** | Hoàn thành | Khóa 40 màu palette, binary alpha, kiểm tra Y-sort đáy sprite |
| **Bộ kiểm thử tự động (Unit Tests)** | Hoàn thành | **10/10 tests pass 100%** không lỗi |
| **Khởi tạo GitHub Repository** | Hoàn thành | Đã tạo và push lên `FregD156/Ember-Anvil-The-Alchemical-Forge` (Public) |

---

## 2. CHI TIẾT CÁC FILE ĐÃ TRIỂN KHAI

### 2.1. Cấu hình & Autoloads
- `project.godot`: Cấu hình độ phân giải 640x360, stretch `canvas_items` integer, texture filter Nearest, snap pixel 2D, đầy đủ Input Map phím di chuyển, vung công cụ (Space/LMB), đổi công cụ (1-3), tương tác (E), menu (B, M, J).
- `autoload/game_constants.gd`: Lưu trữ tập trung các hằng số theo GDD (`0.75s`/phút game, ngày 06:00 - 24:00, tỉ lệ nung 1 Phôi = 3 Quặng, các mốc phẩm chất Thô/Thường/Tinh Xảo/Tuyệt Tác, bảng màu ánh sáng môi trường).
- `autoload/time_manager.gd`: Điều phối nhịp thời gian, phát tín hiệu phút/giờ/ngày, mốc 12:00 (respawn T0), 18:00 (ngủ), 22:00 (cảnh báo mệt), 24:00 (ngất); tạm dừng theo từng nguồn (`paused_by`).
- `autoload/event_bus.gd`: Trục truyền tín hiệu liên hệ thống (thể lực, khai thác, vật phẩm, kinh tế, thám hiểm, thông báo UI).
- `autoload/game_manager.gd`: Quản lý kho đồ người chơi, vàng, danh tiếng, buff ngày (`Ngủ Ngon` +10 Max Stamina, phạt ngất `-30%` Max Stamina).

### 2.2. Dữ liệu Data-driven (`scripts/data/` & `data/`)
- `scripts/data/drop_entry.gd`: Resource quy định item rớt, số lượng min-max và tỉ lệ %.
- `scripts/data/item_data.gd`: Resource vật phẩm (Cành khô, Đá cuội, Quặng đồng, Phôi đồng, Gỗ thông...).
- `scripts/data/tool_data.gd`: Resource công cụ với cấp độ (Tier), độ cứng (Power), sát thương (DMG).
- `scripts/data/resource_node_data.gd`: Resource node khai thác (HP, Hardness, loại công cụ, quy tắc respawn).
- `scripts/data/smelt_recipe.gd`: Resource công thức nung (Quặng cần, Nhiệt độ chảy, thời gian nung, thành phẩm).
- `scripts/data/weapon_recipe.gd`: Resource công thức rèn (Nhánh vũ khí, số phôi cần, ATK gốc, Độ bền gốc, Giá bán gốc).
- `data/tools/`: `tool_pickaxe_t0.tres`, `tool_axe_t0.tres`, `tool_sickle_t0.tres`.
- `data/nodes/`: `node_dry_shrub.tres`, `node_pebble.tres`, `node_shallow_copper.tres`, `node_pine_tree.tres`.
- `data/items/`: `item_copper_ore.tres`, `item_dry_branch.tres`, `item_pebble.tres`, `item_copper_ingot.tres`...
- `data/recipes/`: `recipe_copper_ingot.tres`, `weapon_dagger.tres`, `weapon_sword.tres`, `weapon_warhammer.tres`.

### 2.3. Trạm Xưởng & Giao Diện (Module 3 & Module 4)
- `scripts/stations/station_furnace.gd` & `scenes/stations/station_furnace.tscn`: Lò nung nhiệt tiến dần `T += (T_target - T) * heat_rate * delta`, Sweet Spot, Overheat (phôi Giòn), ánh sáng lò động (`PointLight2D`).
- `scripts/ui/smelter_overlay.gd` & `scenes/ui/smelter_overlay.tscn`: Giao diện lò nung, nhiệt kế dọc, vạch Sweet Spot, nút nạp nhiên liệu, nút bơm ống thổi (-2 stamina), không dừng thời gian.
- `scripts/ui/forging_overlay.gd` & `scenes/ui/forging_overlay.tscn`: Giao diện rèn kết hợp Đe Rèn (bấm nhịp 3 lần thanh trượt, max 45đ) và Đá Mài (giữ lực 3s, max 55đ), tính hệ số phẩm chất Q.
- `scripts/stations/station_anvil.gd` & `scenes/stations/station_anvil.tscn`: Đe rèn mở ForgingOverlay.
- `scripts/stations/station_grinder.gd` & `scenes/stations/station_grinder.tscn`: Đá mài trên dây chuyền rèn.
- `scripts/stations/station_bed.gd` & `scenes/stations/station_bed.tscn`: Giường ngủ (cho phép ngủ từ 18:00, hồi phục thể lực, tính buff Ngủ Ngon).
- `scripts/stations/station_dispatch_board.gd` & `scenes/stations/station_dispatch_board.tscn`: Bảng Ủy Thác phái mạo hiểm giả.
- `scripts/viewport/live_expedition.gd` & `scenes/viewport/live_expedition.tscn`: Màn hình SubViewport side-view 192x108 (3 ải, tiêu hao độ bền, tự uống máu <40%, tổng kết phần thưởng).
- `scripts/ui/bag_overlay.gd` & `scenes/ui/bag_overlay.tscn`: Túi đồ phím B, 20 ô, dừng thời gian khi mở.

### 2.4. Kiểm thử tự động (10/10 Tests Pass)
- `tests/test_runner.gd`: Kiểm tra toàn diện hệ thống:
  1. Hằng số thời gian (0.75s/min, 06:00 -> 24:00)
  2. Quy tắc Stamina gốc (120, chi phí theo Power/Hardness)
  3. Cơ chế ngủ & buff Ngủ Ngon (+10 Max Stamina)
  4. Cơ chế ngất lúc 24:00 (Dậy lúc 08:00, -30% Max Stamina)
  5. Khai thác node, kiểm tra độ cứng, công cụ và chi phí thể lực
  6. Phân hạng phẩm chất (Thô, Thường, Tinh Xảo, Tuyệt Tác)
  7. Tỉ lệ luyện kim (1 Phôi = 3 Quặng)
  8. Túi đồ (Bag) dừng thời gian đúng quy tắc
  9. Mô hình nhiệt lò nung tiến dần và tăng nhiệt ống thổi
  10. Live Expedition Viewport 3 ải và cơ chế tự uống thuốc

---

## 3. BƯỚC TIẾP THEO

- [ ] **Tạo Asset Pixel Art Chính Thức (Vertical Slice):**
  - Chạy `image-generator` theo mẫu prompt trong `ART_PROMPTS.md` và chạy `postprocess.py` ép về bảng màu 40 màu:
    1. Thợ Rèn (Player spritesheet idle, walk, swing)
    2. 3 Sprite Node Zone 1 (Bụi cây khô, Đá cuội, Mỏ đồng nông)
    3. Sprite Lò Nung (4 trạng thái: Nguội, Ấm, Sweet Spot, Overheat)
    4. Sprite Đe Rèn, Đá Mài
- [ ] **Bàn Giả Kim (Alchemy Station):** Chiết xuất Tinh dầu nguyên tố (Hỏa, Băng, Lôi, Độc) và pha thuốc thể lực (Module 3 phần cuối).
- [ ] **Mở rộng Module 5 & 6:** Boss đầu tiên và World Map giấy da (Phím M).
