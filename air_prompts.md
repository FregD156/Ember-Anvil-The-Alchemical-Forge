# ART_PROMPTS.MD - ART BIBLE VÀ HỆ PROMPT CHO AGENT

**Dự án:** Ember & Anvil: The Alchemical Forge
**Phiên bản:** v0.3
**Công cụ gen ảnh:** Google Antigravity (Nano Banana)
**File liên quan:** `DETAIL.md` (GDD)

> Lưu ý: tên thư mục Rules/Skills của Antigravity (`.agent/...`) chưa được xác nhận với bản hiện tại. Kiểm tra trong Settings của IDE trước khi đặt file.

---

# PHẦN A. ART BIBLE

## A1. Định hướng

**Từ khóa:** ấm, thủ công, lấp lánh lửa. Cảm giác "xưởng rèn ấm áp giữa vùng hoang dã se lạnh".

| Trụ cột | Ý nghĩa khi vẽ |
|---|---|
| **Lửa là nhân vật chính** | Mọi thứ khác dịu, ít bão hòa. Lửa, kim loại nóng, phép thuật là điểm sáng bão hòa cao để mắt luôn bị kéo về lò rèn |
| **Đọc được trong 0.2 giây** | Node đào được hay chưa, vũ khí nào, phẩm chất nào đều nhận ra bằng hình khối và màu, không cần đọc chữ |
| **Một nguồn sáng ấm, bóng lạnh** | Ánh sáng ngả cam, bóng ngả tím xanh. Không dùng đen thuần |
| **Ít asset, nhiều biến thể** | Palette swap bằng shader cho vật liệu và phẩm chất |

## A2. Thông số kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Độ phân giải thế giới | **640x360** (scale nguyên x2, x3, x4) |
| Tile | **16x16** |
| Góc nhìn thế giới | Top-down 3/4 (kiểu Stardew), vật cao vẽ chồng lên tile phía trên |
| Hướng nhân vật | 3 hướng vẽ (Xuống, Lên, Ngang), hướng trái lật từ phải |
| Canvas frame nhân vật | **32x32** (thân khoảng 16x24, chừa chỗ cho công cụ) |
| Viền | Selective outline: tông tối hơn của chính màu vật thể, không viền đen |
| Y-sort | Bật cho mọi vật thể, origin nằm ở **chân** sprite |
| Bóng | Sprite elip mờ dưới chân (không dùng shadow động của Light2D cho vật nhỏ) |
| Công cụ | Aseprite, export spritesheet + JSON, import bằng *Aseprite Wizard* |

**Cài đặt Godot bắt buộc:**
```
rendering/textures/canvas_textures/default_texture_filter = Nearest
display/window/stretch/mode = canvas_items
display/window/stretch/scale_mode = integer
rendering/2d/snap/snap_2d_transforms_to_pixel = true
rendering/2d/snap/snap_2d_vertices_to_pixel = true
```
Camera dùng `position_smoothing` kèm làm tròn vị trí về số nguyên pixel để tránh rung pixel.

## A3. Bảng màu chính (40 màu khác nhau)

| Ramp | Màu (tối → sáng) |
|---|---|
| Mực / Đá | `#14121C` `#2A2438` `#463C5A` `#6B5F7E` `#9A8FA3` `#CFC6C4` `#F2EBDD` |
| Gỗ / Đất | `#2B1B17` `#4A2E24` `#6E4A32` `#946A44` `#C08F5A` `#E2B97F` |
| Rừng / Cỏ | `#1C2B2A` `#264A3A` `#3B6E43` `#5E9150` `#94B85A` `#CBD87F` |
| Nước / Đầm / Băng | `#1F3A4D` `#2F5F6B` `#4C8C8A` `#86BFAE` `#A9D8E8` |
| Lửa / Dung nham | `#5A1E24` `#9B2D2B` `#D4542B` `#F28C33` `#FFC84A` `#FFF1A8` |
| Kim loại | Đồng đỏ `#B4633A`, Đồng thau `#C99A3C`, Thiếc `#9FA9B5`, Sắt `#5F6B7A`, Thép `#8CA3B8`, Mythril `#5FE0C8`, Obsidian `#2A1E3A` |
| Nguyên tố | Hỏa `#F28C33` (trùng ramp lửa), Băng `#A9D8E8` (trùng ramp nước), Lôi `#FFE45E`, Độc `#8AD04A` |

**Quy tắc màu:**
- Mỗi bước sáng dịch hue về vàng/cam, mỗi bước tối dịch về tím/xanh.
- Bão hòa cao chỉ dành cho: lửa, kim loại nóng, tinh thể, nút tương tác, vật phẩm hiếm.
- Màu theo Zone: Zone 1 xanh lục ấm, Zone 2 lục lam đục, Zone 3 xám tím lạnh, Zone 4 đỏ cam đen.

## A4. Live Expedition Viewport

| Thông số | Giá trị |
|---|---|
| Kích thước mặc định | **192x108**, tỉ lệ 1:1, góc trên phải *(giả định chờ xác nhận)* |
| Mở rộng | **320x180**, đổi kích thước SubViewport, không scale texture |
| Góc nhìn | Side-view, nhân vật quay mặt phải |

Lý do chọn side-view: dễ đọc ở độ phân giải nhỏ, phân biệt rõ với thế giới khai thác, Boss cao lớn trông hoành tráng. Cái giá là phải vẽ thêm bộ sprite mạo hiểm giả riêng.

## A5. Nhân vật

### Thợ Rèn (người chơi), canvas 32x32

Công cụ là **layer sprite riêng**, đồng bộ bằng `AnimationPlayer`.

| Animation | Frame | FPS | Ghi chú |
|---|---|---|---|
| Idle | 4 | 6 | Thở nhẹ |
| Walk | 6 | 10 | Bụi nhỏ dưới chân |
| Swing | 6 | 14 | Gồng (2), **chạm (frame 3, gây sát thương)**, thu về (3) |
| Sickle | 5 | 14 | |
| Bellows | 4 | 8 | |
| Hammer | 6 | 12 | |
| Grind | 4 | 10 | Lặp |
| Drink | 5 | 10 | |
| Sleep | 2 | 2 | |
| Faint | 4 | 8 | Một hướng |
| Tired walk | 6 | 7 | Khi Stamina bằng 0 |

Idle, Walk, Swing, Sickle cần 3 hướng; còn lại 1 hướng. Tổng khoảng 190 frame thân nhân vật.

### Mạo hiểm giả (= khách hàng), side-view 32x32

| Nguyên mẫu | Nhánh | Dáng | Màu chủ đạo |
|---|---|---|---|
| Du Kích | Tốc độ | Gầy, áo choàng ngắn có mũ | Xanh rêu, nâu |
| Kiếm Sĩ | Cân bằng | Vừa, giáp da | Đỏ rượu, xám |
| Chiến Binh | Phá giáp | Vạm vỡ, giáp nặng | Xanh thép, đen |

| Animation | Frame | FPS |
|---|---|---|
| Idle | 4 | 6 |
| Run | 6 | 12 |
| Attack | 4 (Du Kích) / 5 (Kiếm Sĩ) / 6 (Chiến Binh) | 14 / 12 / 10 |
| Hurt | 2 | 12 |
| Uống thuốc | 4 | 10 |
| Thắng | 4 | 8 |
| Thua | 3 | 6 |

Vũ khí là layer riêng, mỗi hình khối vẽ 5 tư thế (nghỉ, gồng, chém giữa, chém cuối, thu về). Tóc và áo đổi bằng palette swap.

### Vũ khí và Phẩm chất (shader)

Chỉ vẽ **6 hình khối**: Dao Găm, Song Kiếm, Kiếm Đơn, Kiếm Bản Rộng, Búa Chiến, Đại Đao. Mỗi hình dùng **4 tông xám chỉ mục**, shader đổi sang màu vật liệu qua LUT 4x1.

| Vật liệu | Tông tối → sáng |
|---|---|
| Đồng đỏ | `#6E3A24` `#B4633A` `#D98A56` `#F2B98A` |
| Đồng thau | `#6E5420` `#C99A3C` `#E4C066` `#F7E0A0` |
| Sắt | `#2A3038` `#5F6B7A` `#8493A3` `#B8C4D0` |
| Thép | `#3C4A5C` `#8CA3B8` `#B8CCDC` `#E8F0F6` |

| Phẩm chất | Hiệu ứng |
|---|---|
| Thô | Giảm bão hòa 25%, overlay vết mẻ |
| Thường | Nguyên bản |
| Tinh Xảo | Viền sáng 1px ở sống lưỡi |
| Tuyệt Tác | Shader phát sáng nhịp thở (xung 1.2 giây) + hạt lấp lánh |

## A6. Môi trường

### Tileset theo vùng (Godot Terrain, bộ 3x3 minimal)

| Vùng | Địa hình chính | Bổ sung |
|---|---|---|
| Forge Hub | Sàn gỗ, sân đá, tường gạch, mái ngói | Cửa, cửa sổ phát sáng đêm |
| Zone 1 | Cỏ, đất, lối mòn, thông | Suối nhỏ, gốc cây, đá rêu |
| Zone 2 | Bùn, nước nông, lau sậy | Cầu gỗ (hỏng / đã sửa), sương |
| Zone 3 | Đá hầm, đường ray, cột chống | Xe goòng, đèn treo, vách tối |
| Zone 4 | Đá đen, dung nham, tinh thể | Hơi nóng, đá nứt phát sáng |

Mỗi vùng 60-80 tile (tổng khoảng 350). Dung nham và nước dùng animated tile (4 frame, 4 FPS).

### Sprite tài nguyên

| Node | Kích thước | Trạng thái | Dấu nhận dạng |
|---|---|---|---|
| Bụi cây khô, Đá cuội | 16x16 | Nguyên, cạn | Nhánh nâu khô |
| Mỏ Đồng | 16x16 | Nguyên, cạn | Chấm cam |
| Mỏ Thiếc | 16x16 | Nguyên, cạn | Chấm bạc |
| Mỏ Sắt | 16x16 | Nguyên, cạn | Chấm xanh xám |
| Mỏ Than | 16x16 | Nguyên, cạn | Đen kèm vệt tím |
| Cây Thông | 32x48 | Nguyên, gốc | Thông xanh đậm, thân đỏ nâu |
| Cây Sồi | 48x64 | Nguyên, gốc | Tán rộng, quả sồi |
| Cụm Tinh Thể | 16x24 | Nguyên (4 nguyên tố), cạn | Màu nguyên tố |
| Obsidian, Mythril, Lõi Dung Nham | 24x24 | Nguyên, cạn | Tím đen / ngọc lam / cam sáng |
| Thảo dược | 16x16 | Nụ, nở, đã hái | |

**Phản hồi:** hit flash (shader trắng 0.06 giây) + rung ngang 1px + 3-5 mảnh vỡ hạt. Vết nứt overlay ở 50% HP. Respawn: hiệu ứng "mọc" 0.4 giây lúc 06:00 và 12:00.

## A7. Các trạm trong Forge Hub

| Trạm | Kích thước | Trạng thái hình ảnh |
|---|---|---|
| Lò Nung | 48x48 | Nguội, Ấm, **Sweet Spot**, **Overheat** |
| Đe Rèn | 32x24 | Trống, có phôi nóng, có vũ khí |
| Đá Mài | 32x32 | Đứng yên, quay (4 frame), có tia lửa |
| Bàn Giả Kim | 32x32 | Rảnh, sôi, xong |
| Bảng Ủy Thác | 32x32 | Trống, có đơn mới (dấu `!`) |
| Kho đồ (rương) | 16x16 | Đóng, mở |
| Giường | 32x32 | Lv1, Lv2, Lv3 |
| Quầy giao dịch | 48x32 | |

### Lửa lò nung là nhiệt kế thứ hai

| Trạng thái | Nhiệt | Hình ảnh lửa | `PointLight2D` |
|---|---|---|---|
| Nguội | Dưới ngưỡng chảy | Than đỏ mờ | Đỏ sẫm, energy 0.3 |
| Đang nóng lên | Dưới Melt | Lửa cam nhỏ | Cam, 0.7 |
| **Sweet Spot** | `[Melt, Melt+100]` | Lửa vàng ổn định | Vàng ấm, 1.2, **ổn định** |
| **Overheat** | Trên +200 | Lửa trắng vàng, giật, tia lửa, gợn nhiệt | Trắng, 1.6, **nhấp nháy** |

Màu light nội suy bằng `Gradient` theo nhiệt độ. Phôi nóng đổi màu theo cùng gradient (đỏ sẫm → cam → vàng → trắng).

## A8. Đồ họa Mini-game Rèn

- **Đe Rèn:** thanh trượt ngang 120x10 px. Vùng Xanh `#5E9150` và Vàng `#FFC84A`, con trỏ là tia lửa nhỏ. Bấm trúng thì rung 1px (0.08 giây) và bắn tia lửa.
- **Đá Mài:** thanh tiến độ tròn quanh lưỡi, tia lửa `#FFC84A` nhiều hơn khi ép đúng lực (tối đa 24 hạt).
- **Kết quả:** khung vũ khí theo hạng: Thô xám, Thường trắng, Tinh Xảo xanh lam, Tuyệt Tác vàng phát sáng.

## A9. Ánh sáng và VFX

| Hiệu ứng | Cách làm |
|---|---|
| Ngày đêm | `CanvasModulate` theo bảng ở `DETAIL.md` mục 3.3 |
| Đèn lồng, lò | `PointLight2D`, texture gradient 128px, bật dần 17:30-19:00 |
| Ánh sáng quanh người chơi | Light nhỏ sau 20:00 |
| Hạt | `GPUParticles2D` hoặc `CPUParticles2D` |
| Vignette | Shader viền tối, mạnh dần từ 22:00 |
| Rung màn hình | Tối đa 2px, chỉ sự kiện quan trọng |
| Hitstop | 0.05 giây khi đánh trúng Boss |

**Đúng 5 shader:** `palette_swap`, `hit_flash`, `outline_select`, `heat_shimmer`, `masterwork_glow`.

## A10. UI Art

- Phong cách: khung sắt rèn viền cam (ánh lò) trên nền da thuộc tối.
- Panel 9-slice **24x24**, 3 biến thể: da tối, giấy da sáng (Map, Compendium), kim loại (Smelter).
- Icon vật phẩm **16x16**, nền slot 20x20.
- Font phải hỗ trợ **tiếng Việt đủ dấu** (`U+1EA0-1EF9`). Ứng viên: *Pixelify Sans* (OFL). Test chuỗi đủ dấu trước khi chốt.
- Thanh Stamina 100x8 px, đổi màu theo ngưỡng ở `DETAIL.md` mục 4.2.

## A11. Quy ước file

```
res://art/
├── characters/player/       spr_player_swing_side.png
├── characters/adventurers/
├── weapons/                 spr_wpn_dagger_pose1.png
├── environment/tilesets/    ts_zone1_forest.png
├── nodes/                   spr_node_oak_full.png
├── stations/
├── ui/                      ui_panel_leather_9s.png
├── vfx/
└── shaders/
```
Tên: `loại_chủ đề_biến thể_trạng thái`, chữ thường, gạch dưới. Tag Aseprite trùng tên animation trong Godot.

## A12. Khối lượng asset MVP (Tier 0-1, Zone 1, 1 Boss)

| Nhóm | Ước lượng |
|---|---|
| Thợ rèn (thân + công cụ T0-T1) | ~230 frame |
| Mạo hiểm giả (3 nguyên mẫu) | ~110 frame |
| Vũ khí (6 hình x 5 tư thế) | 30 sprite |
| Tileset (Hub + Zone 1 + Zone 2) | ~150 tile |
| Node tài nguyên | ~25 sprite |
| Trạm rèn | ~35 sprite |
| Icon vật phẩm | ~80 icon |
| UI | ~40 mảnh |
| Boss đầu tiên | ~30 frame |
| **Tổng** | **~700 sprite/frame** |

Nên làm **vertical slice** trước: 1 màn Hub + 1 góc Zone 1 + thợ rèn chặt cây + 1 lò nung.

---

# PHẦN B. HỆ PROMPT CHO AGENT

## B1. Thực tế về AI tạo ảnh pixel art

Nano Banana **không vẽ được lưới pixel thật**: ảnh chỉ "trông giống" pixel art, hay lệch lưới và lẫn màu ngoài palette. Prompt chỉ đạt khoảng 70%, phần còn lại là hậu xử lý bắt buộc.

| Bước | Việc |
|---|---|
| 1 | Gen ảnh 1024px, nền magenta đơn sắc |
| 2 | Xóa nền thành trong suốt |
| 3 | Downscale về kích thước đích (BOX) |
| 4 | **Ép về đúng palette 40 màu** |
| 5 | Kiểm tra checklist (B8) |

Hoạt ảnh: model khó giữ nhân vật nhất quán qua nhiều frame. Dùng **ảnh tham chiếu** cho mọi frame. Frame quan trọng (Swing chạm đòn) nên chỉnh tay trong Aseprite.

## B2. Khác biệt khi dùng Nano Banana

| Cách làm cũ | Cách làm đúng |
|---|---|
| Khối `NEGATIVE` | Không có negative prompt đúng nghĩa. Viết thành câu khẳng định ("viền tông tối hơn cùng màu", thay vì "không viền đen") |
| Danh sách hex dài | Model chỉ gần đúng màu. Giữ vài hex chủ đạo, ép palette bằng script |
| Seed cố định | Thường không có seed. Giữ nhất quán bằng **ảnh tham chiếu** |
| Từ khóa rời | Viết **câu văn mô tả đầy đủ** |
| Gen đúng 16x16 | Gen 1024px rồi downscale |

## B3. Cấu trúc thư mục dự án

```
ember-anvil/
├── .agent/                     # kiểm tra tên thực tế trong Antigravity
│   ├── rules/art-style.md      # luôn áp dụng (B4)
│   └── skills/pixel-asset/
│       ├── SKILL.md            # quy trình gen (B5)
│       ├── postprocess.py      # hậu xử lý (B6)
│       └── manifest.json       # danh sách asset (B7)
├── art_refs/                   # ảnh tham chiếu khóa nhân vật
│   ├── ref_player.png
│   ├── ref_skirmisher.png
│   ├── ref_swordsman.png
│   └── ref_warrior.png
└── art/                        # đầu ra (khớp res:// của Godot)
```

## B4. Rule luôn bật: `.agent/rules/art-style.md` (STYLE LOCK)

```markdown
# Art Style Lock - Ember & Anvil

Mọi ảnh sinh ra cho dự án này tuân theo phong cách sau. Không tự đổi.

Phong cách: 2D pixel art cho game "Ember & Anvil", cảm giác xưởng rèn ấm
áp giữa vùng hoang dã se lạnh. Góc nhìn top-down 3/4 kiểu Stardew Valley
(riêng Live Viewport là side-view nhìn ngang, hướng phải).

Quy tắc hình ảnh:
- Pixel sắc nét, đặt tay, mỗi "pixel" là một khối vuông đều nhau.
- Viền 1 pixel, là tông tối hơn của chính màu vật thể (không viền đen).
- Tô khối phẳng (cel shading) 3-4 tông mỗi vật liệu, không chuyển màu mượt.
- Nguồn sáng từ trên-trái, ánh cam ấm; bóng ngả tím xanh lạnh.
- Sáng hơn thì ngả vàng/cam, tối hơn thì ngả tím/xanh.
- Môi trường ít bão hòa; chỉ lửa, kim loại nóng, tinh thể, vật phẩm hiếm
  và điểm tương tác mới bão hòa cao.
- Tuyệt đối không chữ, số, logo, watermark trong ảnh.
- Mỗi lần chỉ một asset hoặc một sprite sheet.
- Chỉ một vật thể chính trong khung, thấy trọn vẹn, không bị cắt.

Màu chủ đạo: đá #2A2438 #6B5F7E #CFC6C4, gỗ #4A2E24 #946A44 #E2B97F,
rừng #264A3A #5E9150 #CBD87F, nước #2F5F6B #86BFAE, lửa #9B2D2B #D4542B
#FFC84A. Kim loại: đồng #B4633A, thau #C99A3C, thiếc #9FA9B5, sắt #5F6B7A,
thép #8CA3B8, mythril #5FE0C8, obsidian #2A1E3A.

Nhận diện Zone:
- Hub: xưởng gỗ ấm, sân đá, tường gạch, mái ngói, cửa sổ phát sáng
- Z1: bìa rừng thông, cỏ xanh ấm, lối đất, đá phủ rêu, suối nhỏ
- Z2: đầm lầy thảo dược, nước lục lam đục, bùn, lau sậy, cầu gỗ, sương
- Z3: hầm mỏ sắt, đá xám tím lạnh, đường ray, cột chống gỗ, đèn treo
- Z4: hang dung nham, đá bazan đen, vết nứt cam phát sáng, hơi nóng

Mọi ảnh phải đi qua postprocess.py trước khi lưu vào art/.
```

## B5. Skill: `.agent/skills/pixel-asset/SKILL.md`

```markdown
---
name: pixel-asset
description: Sinh và hậu xử lý asset pixel art cho Ember & Anvil (nhân vật,
node, trạm, tileset, icon, UI, hoạt ảnh) đúng art bible và palette.
---

# Quy trình cho mỗi asset

1. Đọc manifest.json để lấy asset_id, category, canvas, zone, frames, ref, out.
2. Ghép prompt: [template theo category bên dưới] + câu: "Solid flat magenta
   #FF00FF background, nothing else in the frame."
3. Nếu có `ref`, đính kèm ảnh trong art_refs/ và thêm: "Keep the exact same
   character design, proportions and palette as the reference image."
4. Gen ảnh 1024x1024 (hoặc tỉ lệ ngang cho sprite sheet).
5. Chạy: python postprocess.py <ảnh> --canvas WxH --frames N --out <out>
6. Nếu script báo FAIL (palette, viền đen, ảnh rỗng), gen lại, tối đa 3 lần.
7. Nếu gen ảnh thất bại (lỗi server, quá tải): DỪNG và báo lỗi, không tự thay
   bằng cách khác (không vẽ bằng code, không làm trang web thay thế).

# Template theo loại (điền biến trong {})

node: "A single {NODE} resource sprite for a top-down 3/4 pixel art game,
state {full|depleted}, the base touches the bottom edge, bold silhouette
readable at a glance, one small signature highlight color, soft oval ground
shadow. Centered, whole object visible."

character: "A pixel art sprite sheet of a young blacksmith with leather apron,
rolled sleeves, soot-stained face, brown hair and orange headband, animation
'{ANIM}', {N} frames in one horizontal row, equal spacing, identical
proportions and origin in every frame, no tool in hands."

adventurer: "Side-view pixel art sprite sheet facing right of a {archetype},
animation '{ANIM}', {N} frames in one row, no weapon in hands."
  archetype: skirmisher = lean, short mossy-green cloak, brown leather, hood;
  swordsman = medium build, wine-red tabard, gray leather armor;
  warrior = broad heavy steel-blue plate armor with dark trim.

station: "A pixel art {STATION} for a blacksmith workshop, top-down 3/4 view,
state {STATE}, base touches the bottom edge."
  furnace bắt buộc có state: cold = dim red embers; warming = small orange
  flame; sweet spot = steady golden flame; overheat = flickering white-yellow
  flame with sparks and heat haze.

weapon: "A {WEAPON} sprite in side view, diagonal pose {rest|windup|slash_mid|
slash_end|recover}, drawn in exactly four grayscale tones (#2A2438 #6B5F7E
#9A8FA3 #F2EBDD), no hand, no arm." Weapon: dagger, twin swords, short sword,
broadsword, war hammer, great axe.

icon: "A 16x16-style inventory icon of {ITEM}, centered, readable when tiny,
few colors, 1px darker outline."

tag: "A small {rank} badge, forged-iron border with warm orange edge light,
flat dark leather fill, blank center." rank: crude = gray, common = white,
fine = blue, masterwork = gold glow. Tag giá: "hanging wooden price tag,
string hole at the left, blank face".

panel: "A 9-slice UI panel, style {leather dark|parchment|metal smelter},
forged-iron frame with orange ember edge, 6px corners, tileable center,
no text, no icons."

tileset: "A seamless 16x16 pixel art tileset sheet on a strict grid for
{ZONE}: 4 ground variants, edge and corner transitions, path, water or lava
as 4 animation frames in a row, cliff wall, small decorations."

animation: "Pixel art sprite sheet of {SUBJECT}, animation '{ANIM}', {N} frames
in ONE horizontal row, equal spacing, same character, proportions, palette and
origin in every frame. Frame notes: {NOTES}."
  Swing (6 frame): 1-2 wind up, 3 impact (tool fully extended, damage frame),
  4-6 recover.

vfx: "A pixel art VFX sprite sheet of {hit sparks|rock debris|forge sparks|
heat shimmer|respawn glow|masterwork sparkle}, {N} frames, bright colors from
the fire or element ramp, transparent-friendly."

boss: "Side-view pixel art boss sprite sheet facing left, {BOSS_DESC},
animations idle(4) attack(6) hurt(2) death(6), a glowing core in the color of
its elemental weakness."

# Quy tắc
- Chữ, số, giá do Godot render, không nhờ AI vẽ.
- Luôn đính kèm ảnh tham chiếu cho thợ rèn và 3 nguyên mẫu mạo hiểm giả.
- Mỗi lần gen chỉ 1 asset hoặc 1 sprite sheet.
```

## B6. Hậu xử lý: `.agent/skills/pixel-asset/postprocess.py`

```python
import argparse, sys
from PIL import Image
import numpy as np

PALETTE = """14121C 2A2438 463C5A 6B5F7E 9A8FA3 CFC6C4 F2EBDD
2B1B17 4A2E24 6E4A32 946A44 C08F5A E2B97F
1C2B2A 264A3A 3B6E43 5E9150 94B85A CBD87F
1F3A4D 2F5F6B 4C8C8A 86BFAE A9D8E8
5A1E24 9B2D2B D4542B F28C33 FFC84A FFF1A8
B4633A C99A3C 9FA9B5 5F6B7A 8CA3B8 5FE0C8 2A1E3A
FFE45E 8AD04A""".split()
PAL = np.array([[int(h[i:i+2], 16) for i in (0, 2, 4)] for h in PALETTE])

def remove_bg(img, key=(255, 0, 255), tol=90):
    a = np.array(img.convert("RGBA"))
    d = np.abs(a[..., :3].astype(int) - key).sum(axis=2)
    a[d < tol, 3] = 0
    return a

def snap(a):
    rgb = a[..., :3].reshape(-1, 3).astype(int)
    idx = ((rgb[:, None, :] - PAL[None]) ** 2).sum(axis=2).argmin(axis=1)
    a[..., :3] = PAL[idx].reshape(a.shape[:2] + (3,))
    a[..., 3] = np.where(a[..., 3] > 127, 255, 0)   # alpha nhị phân
    return a

def main():
    p = argparse.ArgumentParser()
    p.add_argument("src")
    p.add_argument("--canvas", required=True)        # kích thước MỘT frame, vd 32x32
    p.add_argument("--out", required=True)
    p.add_argument("--frames", type=int, default=1)
    args = p.parse_args()
    w, h = map(int, args.canvas.lower().split("x"))
    W, H = w * args.frames, h
    img = Image.fromarray(remove_bg(Image.open(args.src)))
    img = img.resize((W, H), Image.BOX)              # BOX mượt trước khi ép palette
    out = snap(np.array(img))
    ok = True
    vis = out[..., 3] > 0
    if not vis.any():
        print("FAIL: ảnh rỗng"); ok = False
    elif (out[..., :3][vis] == 0).all(axis=1).any():
        print("FAIL: có pixel đen thuần"); ok = False
    elif args.frames == 1 and not vis[-2:].any():
        print("WARN: gốc sprite không chạm đáy canvas")
    Image.fromarray(out).save(args.out)
    print("OK" if ok else "FAIL", args.out, f"{W}x{H}")
    sys.exit(0 if ok else 1)

main()
```

Script dùng `BOX` (trung bình) rồi ép palette vì ảnh AI thường hơi mờ; `NEAREST` trực tiếp sẽ ra nhiễu. Script chưa tự dò lưới pixel gốc, nên asset quan trọng vẫn cần chỉnh tay trong Aseprite.

## B7. Manifest mẫu: `manifest.json`

```json
[
  {"asset_id":"spr_node_pine_full","category":"node","canvas":"32x48","zone":"Z1","frames":1,"out":"art/nodes/spr_node_pine_full.png"},
  {"asset_id":"spr_player_swing_side","category":"character","canvas":"32x32","zone":"Hub","frames":6,"ref":"art_refs/ref_player.png","out":"art/characters/player/spr_player_swing_side.png"},
  {"asset_id":"spr_station_furnace_sweet","category":"station","canvas":"48x48","zone":"Hub","frames":1,"out":"art/stations/spr_station_furnace_sweet.png"}
]
```

## B8. Checklist kiểm tra tự động

- Kích thước đúng `canvas x frames`.
- Mọi pixel nằm trong palette 40 màu.
- Không có pixel đen thuần `#000000`.
- Nền trong suốt sạch, không viền magenta.
- Gốc sprite chạm đáy canvas (Y-sort).
- Sprite sheet: frame cách đều, cùng kích thước.

## B9. Cách chạy trong Antigravity

1. Đặt các file B4-B7 vào đúng thư mục.
2. **Khóa nhân vật:** gen 1 ảnh Thợ Rèn đẹp nhất, duyệt tay, lưu `art_refs/ref_player.png`. Làm tương tự cho 3 nguyên mẫu mạo hiểm giả.
3. Ra lệnh cho agent: *"Dùng skill pixel-asset, gen các asset nhóm node và station trong manifest.json, báo cáo cái nào FAIL."*
4. Dùng Agent Manager để chia việc cho nhiều agent chạy song song (node, tileset, icon...).

## B10. Việc còn mở

1. Xác nhận Live Viewport side-view 192x108.
2. Viết manifest đầy đủ cho MVP (~150 asset đầu tiên theo A12).
3. Thử gen vertical slice để kiểm tra độ nhất quán trước khi gen hàng loạt.