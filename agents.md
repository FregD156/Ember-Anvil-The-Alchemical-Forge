# AGENTS.md - Ember & Anvil: The Alchemical Forge

Hướng dẫn cho mọi AI agent (Antigravity, Claude Code, Codex...) làm việc trong repo này. Đọc hết file này trước khi sửa bất kỳ thứ gì.

> Lưu ý: tên file/thư mục cấu hình agent (`AGENTS.md`, `.agent/`) có thể khác nhau giữa các công cụ. Nếu công cụ của bạn dùng tên khác (ví dụ `GEMINI.md`), hãy sao chép nội dung này sang đó.

---

## 1. Tổng quan dự án

- **Game:** 2D top-down Gathering, Crafting & Guild Simulator, pixel art 16x16.
- **Engine:** Godot 4.x, GDScript 2.0.
- **Vòng lặp cốt lõi:** Khai thác → Nung/Sơ chế → Rèn/Giả kim → Ủy thác mạo hiểm giả và xem qua Live Expedition Viewport.
- **Độ phân giải thế giới:** 640x360, scale nguyên.

### Nguồn sự thật (Source of Truth)

| File | Nội dung | Quyền ưu tiên |
|---|---|---|
| `DETAIL.md` | GDD: số liệu, công thức, bảng cân bằng, kiến trúc | **Cao nhất** cho gameplay |
| `ART_PROMPTS.md` | Art Bible, palette, hệ prompt gen ảnh | **Cao nhất** cho đồ họa |
| `AGENTS.md` (file này) | Quy tắc làm việc cho agent | Cho cách làm việc |

**Khi có mâu thuẫn:** `DETAIL.md` / `ART_PROMPTS.md` thắng. Nếu thấy chúng tự mâu thuẫn hoặc thiếu số liệu, **dừng lại và hỏi**, không tự bịa.

---

## 2. Trạng thái thiết kế hiện tại

| Hạng mục | Trạng thái |
|---|---|
| Thời gian, Stamina, Thu hoạch (node, drop, respawn) | Đã chốt (`DETAIL.md` mục 3-6) |
| Bố cục HUD, luồng màn hình, Forge Hub | Đã chốt |
| Art Bible + hệ prompt | Đã chốt |
| **Lò nung, Rèn, Giả kim** (công thức nhiệt, hợp kim, thuốc) | **Chưa chốt (Module 3)**, không tự triển khai bản cuối |
| **Mạo hiểm giả, Viewport, ECP, độ bền, kinh tế** | **Chưa chốt (Module 4)** |
| Boss, quái, bảng khắc chế | Chưa chốt (Module 5) |
| Tier 3 (nhiên liệu Lõi Dung Nham, Mythril, Obsidian) | Chưa chốt |
| Live Viewport side-view 192x108 | Giả định, chờ chủ dự án xác nhận |

**Quy tắc:** với mục "Chưa chốt", chỉ được làm **khung (stub/interface)** và ghi `# TODO(module-N)`, không hard-code số liệu cuối.

---

## 3. Cấu trúc dự án (Godot)

```
res://
├── autoload/              # TimeManager, GameManager, SaveManager, EventBus
├── scenes/
│   ├── world/             # forge_hub.tscn, zone_1..4.tscn
│   ├── player/
│   ├── stations/          # furnace, anvil, grinder, alchemy, board
│   ├── nodes/             # resource_node.tscn (dùng chung)
│   ├── viewport/          # live_expedition.tscn (SubViewport)
│   └── ui/                # hud, bag, smelter, map, compendium
├── scripts/
│   ├── components/        # StaminaComponent, HealthComponent...
│   ├── systems/           # crafting, dispatch, economy
│   └── ui/
├── data/                  # *.tres (Resource): node, item, recipe, weapon, boss
├── art/                   # xem ART_PROMPTS.md mục A11
├── audio/
└── tests/
```

(Tạo thư mục khi cần, không tạo hàng loạt thư mục rỗng.)

---

## 4. Quy ước code (GDScript)

### 4.1. Phong cách

- **Static typing bắt buộc:** khai báo kiểu cho biến, tham số, giá trị trả về (`var hp: int`, `func hit(dmg: int) -> void`).
- Tên: `snake_case` cho biến/hàm/file, `PascalCase` cho `class_name`, `UPPER_SNAKE` cho hằng số.
- Tên node và signal rõ nghĩa. Signal đặt tên theo quá khứ hoặc sự kiện: `minute_changed`, `day_ended`.
- Dùng `StringName` (`&"pickaxe"`) cho ID, không dùng chuỗi tự do.
- Mỗi script một trách nhiệm. Ưu tiên **component** (node con) hơn kế thừa sâu.
- Tránh `get_node("../../..")`. Dùng `@export`, signal, hoặc autoload.

### 4.2. Data-driven (quan trọng)

- **Mọi số liệu cân bằng nằm trong `res://data/*.tres`** (Resource), không hard-code trong script. Ví dụ: HP node, drop, giá, hệ số phẩm chất.
- Hằng số hệ thống lấy từ `DETAIL.md` (ví dụ `REAL_SEC_PER_GAME_MIN = 0.75`, trần Stamina 200) và đặt ở một nơi duy nhất (autoload hoặc `GameConstants`).
- Khi đổi số liệu, **cập nhật `DETAIL.md` cùng lúc**.

### 4.3. Thời gian và trạng thái

- Mọi thứ phụ thuộc giờ game đi qua `TimeManager` (signal `minute_changed`, `hour_changed`, `day_started`, `day_ended`). **Không** dùng `Time` hoặc timer riêng để tính giờ game.
- Tạm dừng thời gian qua `TimeManager.set_pause(source, on)` theo nguồn, không set `get_tree().paused` cho việc này.
- Quy tắc dừng: Bag/Map/Compendium/Dispatch Board/Pause **dừng**; Smelter/Anvil/Grinder/Alchemy **không dừng**.

### 4.4. Giao tiếp giữa hệ thống

- Dùng signal / `EventBus` (autoload) cho sự kiện liên hệ thống (ví dụ `item_crafted`, `expedition_finished`).
- Không để UI sửa trực tiếp dữ liệu logic. UI phát tín hiệu, hệ thống xử lý, UI cập nhật theo signal.

### 4.5. Rendering 2D

- Texture filter `Nearest`, stretch `canvas_items`, scale mode `integer`, bật snap pixel (xem `ART_PROMPTS.md` A2).
- Y-sort cho mọi vật thể, **origin ở chân sprite**.
- Camera làm tròn vị trí về pixel nguyên.
- Đúng **5 shader**: `palette_swap`, `hit_flash`, `outline_select`, `heat_shimmer`, `masterwork_glow`. Cần thêm shader mới thì hỏi trước.

---

## 5. Quy tắc gameplay không được phá

Các giá trị này đã chốt. Chỉ đổi khi chủ dự án đồng ý.

| Quy tắc | Giá trị |
|---|---|
| Ngày game | 06:00 - 24:00 = 13.5 phút thực (1 giờ game = 45 giây thực) |
| Stamina gốc / trần | 120 / 200 |
| Chi phí mỗi nhát | 2 nếu `Power == Hardness`, 1 nếu `Power > Hardness` |
| Điều kiện khai thác | `Power >= Hardness`, nếu không thì không gây sát thương |
| Số nhát | `ceil(HP / DMG)` |
| Ngất | Quá 24:00 → dậy 08:00, `-30% Max Stamina` |
| Luyện kim | 1 Phôi = 3 Quặng |
| Phẩm chất | Q 0-39 Thô, 40-69 Thường, 70-89 Tinh Xảo, 90-100 Tuyệt Tác |
| Mini-game rèn | Đe tối đa 45 điểm, Đá Mài tối đa 55 điểm |
| Respawn | 06:00 (thường 100%, hiếm 60%), thêm 12:00 cho Bụi cây khô và Đá cuội |

---

## 6. Quy trình đồ họa (cho agent gen ảnh)

Mọi asset đồ họa phải đi theo `ART_PROMPTS.md` phần B.

1. **Không viết prompt tự do.** Dùng STYLE LOCK + template theo loại asset.
2. Dùng **ảnh tham chiếu** trong `art_refs/` cho thợ rèn và 3 nguyên mẫu mạo hiểm giả.
3. Gen 1024px, nền magenta `#FF00FF`, rồi chạy `postprocess.py` (xóa nền, downscale, ép palette 40 màu).
4. **Không bao giờ nhờ AI vẽ chữ, số, logo.** Chữ do Godot render.
5. Gen ảnh thất bại (lỗi/quá tải) thì **dừng và báo lỗi**, không tự thay bằng cách khác (không vẽ bằng code, không làm trang web thay thế).
6. Mỗi lần chỉ 1 asset hoặc 1 sprite sheet. Đặt tên `loại_chủ đề_biến thể_trạng thái`, chữ thường, gạch dưới.
7. Output vào `art/` theo cấu trúc ở `ART_PROMPTS.md` A11.

**Palette:** chỉ dùng 40 màu trong `ART_PROMPTS.md` A3. Không dùng đen thuần `#000000` hay trắng thuần.

---

## 7. Cách làm việc của agent

### 7.1. Trước khi làm

1. Đọc phần liên quan trong `DETAIL.md` / `ART_PROMPTS.md`.
2. Kiểm tra mục 2 của file này: tính năng đã chốt chưa?
3. Nếu yêu cầu mơ hồ hoặc thiếu số liệu, **hỏi một câu ngắn** thay vì đoán.

### 7.2. Khi làm

- Thay đổi nhỏ, tập trung, một việc mỗi lần. Không refactor ngoài phạm vi yêu cầu.
- Tạo scene bằng text (`.tscn`) cẩn thận, không phá UID/tham chiếu hiện có.
- Không xóa hoặc đổi tên file trong `art/` và `data/` nếu chưa kiểm tra mọi tham chiếu.
- Không thêm thư viện/plugin ngoài khi chưa được đồng ý (đã dự kiến *Aseprite Wizard* cho import sprite).
- Không commit file nhị phân lớn không cần thiết.

### 7.3. Sau khi làm

1. Chạy kiểm tra cú pháp/dự án (mục 8) và sửa lỗi.
2. Cập nhật `DETAIL.md` nếu đổi số liệu hoặc cơ chế.
3. Tóm tắt ngắn: đã làm gì, file nào, còn TODO gì.

### 7.4. Điều **không** làm

- Không tự chốt các mục "Chưa chốt" (mục 2).
- Không hard-code số cân bằng trong script.
- Không đổi độ phân giải, tile size, palette, hoặc số lượng shader.
- Không dùng nội dung có bản quyền (nhân vật, logo, lời bài hát) trong asset hoặc prompt.
- Không dùng `localStorage`-kiểu lưu trữ ngoài hệ thống Save/Load của dự án.

---

## 8. Lệnh thường dùng

Điều chỉnh đường dẫn Godot cho máy của bạn.

```bash
# Mở project (editor)
godot --path . --editor

# Chạy game
godot --path .

# Kiểm tra project load được (không giao diện)
godot --headless --path . --quit

# Kiểm tra cú pháp một script
godot --headless --path . --check-only --script res://scripts/components/stamina_component.gd

# Hậu xử lý ảnh gen
python .agent/skills/pixel-asset/postprocess.py <ảnh_gốc> --canvas 32x32 --frames 1 --out art/nodes/<tên>.png
```

Kiểm thử đơn vị (khuyến nghị, chưa cài): dùng **GUT** hoặc **gdUnit4** cho logic thuần (công thức Stamina, số nhát, phân hạng phẩm chất). Hỏi chủ dự án trước khi thêm.

---

## 9. Thứ tự ưu tiên triển khai (gợi ý)

1. `TimeManager` + `StaminaComponent` + HUD cơ bản (đã có code mẫu trong `DETAIL.md` mục 12).
2. `ResourceNodeData` + node khai thác + drop/respawn cho Zone 1.
3. Người chơi: di chuyển, vung công cụ, tiêu hao Stamina.
4. Forge Hub tối thiểu + Kho đồ/Bag.
5. *Chờ Module 3:* Lò nung, Đe, Đá Mài, Giả kim.
6. *Chờ Module 4:* Bảng Ủy Thác, Live Viewport.

**Vertical slice trước:** 1 màn Hub + 1 góc Zone 1 + thợ rèn chặt cây + 1 lò nung, trước khi làm khối lượng lớn (xem `ART_PROMPTS.md` A12).

---

## 10. Câu hỏi đang mở (hỏi chủ dự án khi liên quan)

1. Live Viewport dùng **side-view 192x108** đúng không?
2. Mô hình nhiệt lò: `T += (T_target - T) * heat_rate * delta` với ống thổi là rủi ro/phần thưởng, có đồng ý không?
3. Định nghĩa `ECP`, `S-Rank`, độ bền vũ khí, thời lượng chuyến đi, và có chạy khi người chơi ở vùng hoang dã không?
4. Nhiên liệu và hợp kim Tier 3 (Mythril, Obsidian, Lõi Dung Nham).