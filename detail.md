# DETAIL.MD - MASTER GAME DESIGN DOCUMENT (GDD)

**Dự án:** Ember & Anvil: The Alchemical Forge
**Thể loại:** 2D Top-Down Gathering, Crafting & Guild Simulator
**Engine:** Godot 4.x (GDScript 2.0), pixel art 16x16, ánh sáng động `PointLight2D`
**Phiên bản tài liệu:** v0.3 (đã gộp GDD gốc + Module 1 + Module 2)
**File liên quan:** `ART_PROMPTS.md` (Art Bible + hệ prompt cho agent)

---

## 0. TRẠNG THÁI TÀI LIỆU

### 0.1. Đã chốt

| Hạng mục | Giá trị |
|---|---|
| Độ phân giải thế giới | 640x360, scale nguyên x2 / x3 / x4 |
| Stamina gốc | 120 (trần cứng 200) |
| Tỉ lệ luyện kim | **1 Phôi = 3 Quặng** |
| Ngày game | 06:00 - 24:00 = 13.5 phút thực |

### 0.2. Giả định đang chờ bạn xác nhận

| Giả định | Nơi dùng |
|---|---|
| Live Viewport là **side-view 192x108** (mở rộng 320x180) | Mục 8 |
| "Khách hàng" = Mạo hiểm giả và NPC đến đặt đơn | `ART_PROMPTS.md` |

### 0.3. Thay đổi so với GDD gốc

| Mục | GDD gốc | Bản này | Lý do |
|---|---|---|---|
| Stamina | 100 | 120, hồi dần | 100 chỉ đủ khoảng 33 nhát, quá chặt |
| Chi phí mỗi nhát | 3 cố định | 2 / 1 theo Power so với Hardness | Nâng cấp công cụ phải tiết kiệm Stamina |
| HP node T1-T2 | 40-120 | 60-150 | Số nhát mỗi cấp đều 5-6, nâng cấp vẫn có cảm giác |
| Live Viewport | 320x180 | 192x108 mặc định | 320px là nửa màn hình 640 |
| Tier 3 | Chỉ nhắc tên | Đã có công cụ, node, drop | Zone 4 cần dữ liệu |

---

## 1. VÒNG LẶP CỐT LÕI (CORE GAMEPLAY LOOP)

1. **KHAI THÁC (Gather):** Quản lý Thời gian và Stamina để ra vùng hoang dã chặt gỗ, đào quặng, khai thác đá mài, hái thảo dược. Không có quái cản đường ở khu khai thác, để tập trung vào nhịp độ thu thập.
2. **NHIỆT LƯỢNG VÀ SƠ CHẾ (Heat & Smelt):** Đốt củi/than trong Lò Nung, giữ nhiệt trong vùng lý tưởng (Sweet Spot) để đúc Phôi và chiết xuất Tinh Dầu Giả Kim.
3. **RÈN VÀ GIẢ KIM (Forge & Infuse):** Mini-game căn nhịp tại Đe Rèn (định hình) và Đá Mài (mài sắc) để quyết định Phẩm chất vũ khí, sau đó khảm Tinh Dầu Nguyên Tố và pha thuốc.
4. **ỦY THÁC VÀ QUAN SÁT (Dispatch & Watch):** Trang bị Vũ khí và Thuốc cho Mạo Hiểm Giả. Theo dõi hành trình vượt ải và đánh Boss tự động qua **Live Expedition Viewport** để thu Vàng, Danh tiếng và Nguyên liệu Boss.

---

## 2. HIỂN THỊ, HUD VÀ LUỒNG MÀN HÌNH

### 2.1. Hiển thị

- Độ phân giải thế giới **640x360**, scale nguyên. Project Settings: `stretch/mode = canvas_items`, `scale_mode = integer`, bật `snap_2d_transforms_to_pixel`.
- Lớp UI nằm trong `CanvasLayer` riêng, font pixel không bị méo khi scale.
- Live Viewport: `SubViewport` hiển thị trong `SubViewportContainer` góc trên phải (xem mục 8).

### 2.2. Bố cục HUD

```
┌────────────────────────────────────────────────────────────┐
│ [Ngày 12 · Sáng]  [06:00━━●━━24:00]      ┌───────────────┐ │
│ [Vàng: 1,240] [Danh tiếng: ★★☆]          │ LIVE VIEWPORT │ │
│                                          │   192 x 108   │ │
│                                          │ (Stage 2/3)   │ │
│                                          └───────────────┘ │
│                                                            │
│                  VÙNG CHƠI (WORLD VIEW)                    │
│                                                            │
│ [Stamina]                                                  │
│ ████████░░ 80/120     [1][2][3] Công cụ     [Nhiệm vụ ▾]   │
└────────────────────────────────────────────────────────────┘
```

| Vị trí | Nội dung |
|---|---|
| Trái trên | Ngày/giờ, Vàng, Danh tiếng |
| Phải trên | Live Viewport (chỉ hiện khi có chuyến đi) |
| Trái dưới | Thanh Stamina: vàng 30-50%, cam dưới 30%, đỏ nhấp nháy sau 22:00 |
| Giữa dưới | 3 slot công cụ (Cuốc / Rìu / Liềm), phím 1-2-3 |
| Phải dưới | Nhiệm vụ đang theo dõi (thu gọn được) |

### 2.3. Game State Machine

```
Splash → Main Menu → [New Game / Continue / Settings]
                          ↓
                    Game World (Forge Hub)
        ┌───────────┬─────┴─────┬──────────────┐
   Wilderness   Smelter UI   Anvil/Grinder   Dispatch Board
   (4 zones)    (overlay)    (mini-game)     (overlay)
        └───────────┴─────┬─────┴──────────────┘
                    Sleep → Day Summary → Ngày mới (06:00)
```

**Day Summary** (sau khi ngủ): vàng kiếm được, kết quả chuyến đi, nguyên liệu, thay đổi danh tiếng, đơn hàng mới.

---

## 3. HỆ THỐNG THỜI GIAN

### 3.1. Hằng số

| Hằng số | Giá trị |
|---|---|
| 1 phút game | 0.75 giây thực |
| 1 giờ game | 45 giây thực |
| 1 ngày (06:00 → 24:00) | 810 giây = 13.5 phút thực |
| Tick logic | mỗi phút game (signal `minute_changed`) |

### 3.2. Mốc trong ngày

| Giờ game | Phút thực | Sự kiện |
|---|---|---|
| 06:00 | 0:00 | Ngày mới: respawn tài nguyên, sinh Đơn hàng ngày, mạo hiểm giả đến Bảng Ủy Thác |
| 12:00 | 4:30 | Giữa trưa: Bụi cây khô và Đá cuội T0 respawn đợt 2 |
| 18:00 | 9:00 | Chiều tà: đèn lồng tự bật, Live Viewport chiếu cao trào Boss. **Có thể ngủ từ giờ này** |
| 22:00 | 12:00 | Cảnh báo mệt mỏi, vignette tối dần |
| 24:00 | 13:30 | Ngất nếu chưa ngủ |

### 3.3. Ánh sáng (`CanvasModulate`, nội suy giữa keyframe)

| Giờ | Màu | Ghi chú |
|---|---|---|
| 06:00 | `#FFD9A8` | Bình minh ấm |
| 09:00 - 15:00 | `#FFFFFF` | Ban ngày |
| 18:00 | `#FFB070` | Hoàng hôn |
| 20:00 | `#6A6FB0` | Chạng vạng |
| 22:00 | `#3A4278` | Đêm |
| 24:00 | `#252B55` | Đêm sâu |

`PointLight2D` của lò rèn, đèn lồng, người chơi bật dần từ 17:30 đến 19:00 bằng tween energy.

### 3.4. Quy tắc tạm dừng thời gian

| UI | Thời gian | Lý do |
|---|---|---|
| Bag, Map, Compendium | **Dừng** | Tra cứu, không gây áp lực |
| Smelter, Anvil, Grinder, Alchemy | **Chạy** | Nhiệt lò chạy thật, mini-game cần căng thẳng |
| Dispatch Board | **Dừng** | Chọn đội hình cần suy nghĩ |
| Pause Menu, Settings | **Dừng** | Hiển nhiên |

### 3.5. Ngủ và Ngất

| Tình huống | Kết quả |
|---|---|
| Ngủ (từ 18:00) | Dậy **06:00**, Stamina hồi 100% |
| Ngủ trước 22:00 | Buff `Ngủ Ngon`: +10 Max Stamina trong ngày |
| Quá 24:00 chưa ngủ | Ngất tại chỗ, dậy **08:00**, `-30% Max Stamina` cả ngày. Mất 2 giờ đầu ngày, vật phẩm giữ nguyên |
| 22:00 trở đi | Hồi Stamina giảm một nửa |
| 23:00 trở đi | Chi phí hành động +25% |

Tài nguyên và đơn hàng vẫn sinh đúng 06:00 kể cả khi người chơi ngất.

---

## 4. HỆ THỐNG STAMINA

### 4.1. Thông số

| Thông số | Giá trị |
|---|---|
| Max Stamina gốc | **120** |
| Giường Lv1 / Lv2 / Lv3 | +15 / +15 / +20 (tối đa 170) |
| Tinh Chất Sinh Lực (rớt từ Boss) | +5 vĩnh viễn, tối đa 8 lần (+40) |
| **Trần cứng** | **200** |
| Hồi tự nhiên | +1 mỗi 3 giây, sau 2 giây không hành động |
| Hồi trong Forge Hub / bên lửa trại | x2 tốc độ |

### 4.2. Trạng thái mệt mỏi

| Stamina | Hiệu ứng |
|---|---|
| > 50% | Bình thường |
| 30% - 50% | Thanh đổi vàng |
| < 30% | Thanh đổi cam, tốc độ vung công cụ -15% |
| 0 | Không vung được công cụ, tốc độ đi -20%, vẫn đi và dùng UI được |

### 4.3. Thuốc Stamina (công thức chi tiết ở Module 3)

| Loại | Hồi | Mở ở |
|---|---|---|
| Nhỏ | +40 | Tier 1 |
| Vừa | +70 | Tier 2 |
| Lớn | +100 | Tier 3 |

Từ viên thứ 4 trong cùng một ngày, hiệu quả giảm 50%.

### 4.4. Chi phí hành động

**Điều kiện khai thác:** `Tool_Power >= Node_Hardness`. Nếu không, node báo "Công cụ quá yếu" và không nhận sát thương.

| Quan hệ Power / Hardness | Stamina mỗi nhát |
|---|---|
| `Power == Hardness` | **2** |
| `Power > Hardness` | **1** |

| Hành động khác | Chi phí |
|---|---|
| Kéo ống thổi | 2 / lần |
| Rèn trên Đe | 5 / công đoạn |
| Mài trên Đá | 5 / công đoạn |

### 4.5. Kiểm tra ngân sách ngày đầu (Tier 0)

| Hoạt động | Stamina | Kết quả |
|---|---|---|
| Đào 6 Mỏ Đồng (5 nhát x 2) | 60 | 12-18 Quặng Đồng |
| Cắt 2 Bụi cây (2 nhát x 2) | 8 | 4-6 Cành khô |
| Kéo ống thổi ~5 lần | 10 | Giữ lò ở Sweet Spot |
| Rèn 1 vũ khí (Đe + Mài) | 10 | 1 vũ khí |
| Dự phòng + hồi tự nhiên | ~32 | Đệm cho sai sót |

12-18 Quặng chia 3 ra 4-6 Phôi mỗi ngày, đủ cho 1 vũ khí Cân Bằng (2-3 Phôi) + 1 Dao Găm (1-2 Phôi).

---

## 5. PHÂN NHÁNH CẤP ĐỘ (TIER PROGRESSION)

| Tier | Công cụ | Nhiên liệu và ngưỡng nhiệt lò | Sản phẩm và tự động hóa |
|---|---|---|---|
| **T0: Đá Thô** (khởi đầu) | Cuốc/Rìu Đá Cuội, Power 1, DMG 5 | **Cành khô:** Max Heat 350°C, cháy 15s/cành | Phôi Đồng Đỏ (chảy 300°C), Đá Mài Thô. Thủ công 100% |
| **T1: Đồng Thau** (mở rộng) | Cuốc/Rìu Đồng Đỏ, Power 2, DMG 12 | **Gỗ Thông Bổ Nhỏ:** Max Heat 550°C, cháy 30s/khúc | Phôi Đồng Thau (chảy 500°C), Đá Mài Tiêu Chuẩn, Thuốc Hồi Lực. Tự động: khung giữ nhiệt lò cơ bản |
| **T2: Sắt Thép** (chuyên sâu) | Cuốc/Rìu Đồng Thau, Power 3, DMG 25 | **Than Củi / Than Đá:** Max Heat 900°C, cháy 60s/viên | Phôi Sắt (750°C), Phôi Thép (850°C), Tinh Dầu Nguyên Tố (Hỏa/Băng/Lôi/Độc). Tự động: Đá mài xoay, Búa máy |
| **T3: Dung Nham** (cuối game) | Cuốc/Rìu Thép, Power 4, DMG 45 | **Lõi Dung Nham:** *chưa chốt (Module 3)* | Mythril, Obsidian. *Chốt ở Module 3* |

### 5.1. Chế tạo công cụ

| Tier | Công cụ | Chi phí |
|---|---|---|
| T0 | Cuốc/Rìu Đá Cuội | Khởi đầu |
| T1 | Cuốc/Rìu Đồng Đỏ | 3 Phôi Đồng Đỏ + 2 Cành khô |
| T2 | Cuốc/Rìu Đồng Thau | 4 Phôi Đồng Thau + 2 Gỗ Thông |
| T3 | Cuốc/Rìu Thép | 5 Phôi Thép + 2 Gỗ Sồi |

**Liềm:** DMG cố định 10. Nâng cấp chỉ tăng sản lượng (+1 thảo dược ở T2 và T3).

---

## 6. TÀI NGUYÊN: NODE, DROP, RESPAWN

### 6.1. Bảng Node

Công thức: `Số nhát = ceil(HP / DMG)`.

| Tier | Node | Công cụ | HP | Hard | Số nhát |
|---|---|---|---|---|---|
| T0 | Bụi cây khô | Rìu | 10 | 1 | 2 |
| T0 | Đá cuội | Cuốc | 15 | 1 | 3 |
| T0 | Mỏ Đồng Nông | Cuốc | 25 | 1 | 5 |
| T1 | Cây Thông | Rìu | 60 | 2 | 5 |
| T1 | Mỏ Thiếc | Cuốc | 66 | 2 | 6 |
| T1 | Đá Nhám | Cuốc | 72 | 2 | 6 |
| T1 | Thảo dược Đỏ/Xanh | Liềm | 20 | 1 | 2 |
| T2 | Cây Sồi | Rìu | 125 | 3 | 5 |
| T2 | Mỏ Sắt Sâu | Cuốc | 150 | 3 | 6 |
| T2 | Mỏ Than Đá | Cuốc | 125 | 3 | 5 |
| T2 | Cụm Tinh Thể | Cuốc | 100 | 3 | 4 |
| T3 | Đá Obsidian | Cuốc | 270 | 4 | 6 |
| T3 | Mỏ Mythril | Cuốc | 315 | 4 | 7 |
| T3 | Lõi Dung Nham | Cuốc | 225 | 4 | 5 |

### 6.2. Bảng rơi đồ

| Node | Rơi chắc chắn | Rơi hiếm |
|---|---|---|
| Bụi cây khô | Cành khô x2-3 | 10% Sợi cỏ |
| Đá cuội | Đá cuội x2-3 | 10% Đá lửa |
| Mỏ Đồng Nông | Quặng Đồng x2-3 | 15% Đá cuội x1 |
| Cây Thông | Gỗ Thông x2-3 | 20% Nhựa Thông (giả kim) |
| Mỏ Thiếc | Quặng Thiếc x2-3 | 10% Quặng Đồng x1 |
| Đá Nhám | Đá Nhám x2-3 | 12% Hạt Mài |
| Thảo dược Đỏ/Xanh | Thảo dược x1-2 | 8% Hạt giống |
| Cây Sồi | Gỗ Sồi x3-4 | 15% Quả Sồi |
| Mỏ Sắt Sâu | Quặng Sắt x2-4 | 10% Bụi Sắt |
| Mỏ Than Đá | Than Đá x3-4 | 10% Than Nén (cháy lâu hơn) |
| Cụm Tinh Thể | Tinh Thể x1-2 | Nguyên tố theo bảng 6.3 |
| Obsidian / Mythril / Lõi Dung Nham | x2-3 | 8% Mảnh Hiếm |

**Công cụ vượt cấp:** nếu `Power >= Hardness + 1` thì +10% cơ hội rơi hiếm.

### 6.3. Nguyên tố của Tinh Thể

| Nguyên tố | Điều kiện |
|---|---|
| Hỏa | Gần Hang Dung Nham, hoặc 12:00 - 18:00 |
| Băng | Hầm Mỏ, hoặc 18:00 - 24:00 |
| Lôi | Hầm Mỏ, giờ chẵn |
| Độc | Đầm Lầy, mọi giờ |

### 6.4. Respawn

| Loại | Quy tắc |
|---|---|
| Node thường | 100% slot trống được lấp lúc **06:00** |
| Node hiếm (Tinh Thể, Mythril, Mảnh Hiếm) | 60% xác suất mỗi slot trống lúc 06:00 |
| Bụi cây khô, Đá cuội (T0) | Thêm đợt lúc **12:00** |
| Thảo dược | Mọc lại sau 2 ngày |

### 6.5. Slot cố định theo Zone

| Zone | Slot thường | Slot hiếm |
|---|---|---|
| 1. Bìa Rừng Thông | 14 | 0 |
| 2. Đầm Lầy Thảo Dược | 12 | 2 |
| 3. Hầm Mỏ Sắt Sâu | 16 | 3 |
| 4. Hang Dung Nham | 12 | 4 |

Số slot cố định giúp World Map hiển thị trữ lượng thật theo thời gian thực.

### 6.6. Thời gian di chuyển (tốc độ đi 80 px/giây)

| Tuyến | Thời gian thực |
|---|---|
| Hub → Zone 1 | ~20 giây |
| Hub → Zone 2 | ~35 giây |
| Hub → Zone 3 | ~45 giây, hoặc ~8 giây bằng xe goòng sau khi sửa |
| Hub → Zone 4 | ~60 giây |

---

## 7. RÈN, LÒ NUNG, GIẢ KIM

> Phần này là GDD gốc. Module 3 sẽ chốt lại công thức nhiệt, bảng hợp kim và công thức giả kim.

### 7.1. Lò Nung (bản gốc)

- Công thức gốc: `T_current = T_ambient + Fuel_Heat - (Cooling_Rate * delta)`
- **Sweet Spot:** `[Melting_Point, Melting_Point + 100°C]`.
- Vượt **+200°C (Overheat)**: phôi bị `Giòn (Brittle)`, giảm 20% Độ bền.

### 7.2. Vấn đề đã phát hiện (chờ Module 3)

| # | Vấn đề | Đề xuất |
|---|---|---|
| 1 | Overheat gần như không xảy ra: Đồng Thau chảy 500, nhiên liệu max 550, ngưỡng giòn là 700 | Overheat chỉ xảy ra khi dùng nhiên liệu cao cấp cho quặng thấp cấp, hoặc khi ống thổi cho +X°C tạm thời |
| 2 | Công thức nhiệt không có trạng thái, nhiệt sẽ nhảy ngay | Dùng mô hình tiến dần: `T += (T_target - T) * heat_rate * delta`, với `T_target = ambient + fuel_heat + bellows_bonus` |
| 3 | Chưa định nghĩa Độ bền vũ khí | Chốt ở Module 4 |

### 7.3. Ba nhánh vũ khí

| Nhánh | Vũ khí | Phôi | Đặc tính |
|---|---|---|---|
| Tốc Độ | Dao Găm → Song Kiếm | 1-2 | Đánh nhanh, khắc chế Boss nhanh nhẹn / ít giáp |
| Cân Bằng | Kiếm Đơn → Kiếm Bản Rộng | 2-3 | ATK và Độ bền đồng đều |
| Phá Giáp | Búa Chiến → Đại Đao / Rìu Lớn | 4-5 | Đánh chậm, sát thương đơn mục tiêu lớn, phá giáp Golem / Giáp Cứng |

### 7.4. Mini-game và Phẩm chất (Q: 0 → 100)

| Bước | Cách chơi | Tối đa |
|---|---|---|
| 1. Đe Rèn | Bấm `Space` 3 lần khi con trỏ qua vùng Xanh/Vàng trên thanh trượt | 45 điểm |
| 2. Đá Mài | Giữ chuột trái ép lưỡi kiếm vào đá mài trong 3 giây | 55 điểm |

| Tổng Q | Phẩm chất | ATK | Độ bền | Giá bán |
|---|---|---|---|---|
| 0 - 39 | **Thô (Crude)** | x0.8 | x0.7 | x0.8 |
| 40 - 69 | **Thường (Common)** | x1.0 | x1.0 | x1.0 |
| 70 - 89 | **Tinh Xảo (Fine)** | x1.25 | x1.3 | x1.5 |
| 90 - 100 | **Tuyệt Tác (Masterwork)** | x1.5 (phát sáng) | x1.6 | x2.5 |

---

## 8. LIVE EXPEDITION VIEWPORT

> Chi tiết công thức ECP, độ bền vũ khí, thời gian chuyến đi sẽ chốt ở Module 4.

| Thông số | Giá trị |
|---|---|
| Kích thước mặc định | **192x108**, hiển thị tỉ lệ 1:1, góc trên phải *(giả định chờ xác nhận)* |
| Chế độ mở rộng | **320x180**, đổi kích thước `SubViewport` chứ không scale texture |
| Góc nhìn | Side-view, nhân vật quay mặt phải |

**3 Micro-stages:**
1. **Stage 1:** Vượt quái nhỏ (tiêu hao độ bền vũ khí).
2. **Stage 2:** Quyết đấu Boss (kiểm tra sát thương thực chiến ECP và khắc chế nguyên tố). Mạo hiểm giả tự uống máu khi HP dưới 40%.
3. **Stage 3:** Tổng kết rương báu, rớt nguyên liệu Boss hiếm khi đạt S-Rank.

**Câu hỏi còn mở:** `ECP`, `S-Rank`, độ bền, thời lượng chuyến đi so với ngày game, có chạy khi người chơi ở vùng hoang dã không.

---

## 9. THIẾT KẾ KHÔNG GIAN

### 9.1. Forge Hub

Khoảng 40x30 tile (16px), cuộn nhẹ.

```
  ┌─────────────── BẮC: Cổng ra 4 Zone ───────────────┐
  │  [Bảng Ủy Thác]          [Giường ngủ]             │
  │  [Kho đồ] → [LÒ NUNG] → [ĐE RÈN] → [ĐÁ MÀI]       │  ← dây chuyền
  │  [Bàn Giả Kim]                    [Quầy giao dịch]│
  └───────────────── NAM: Sân trước ──────────────────┘
```

Nguyên tắc: mọi trạm trên dây chuyền cách nhau tối đa khoảng 3 giây đi bộ.

### 9.2. Bốn Zone

| Zone | Tier | Điều kiện |
|---|---|---|
| 1. Bìa Rừng Thông | 0-1 | Mở sẵn |
| 2. Đầm Lầy Thảo Dược | 1 | Cần sửa cầu gỗ |
| 3. Hầm Mỏ Sắt Sâu | 2 | Cần Đèn lồng, có xe goòng Fast Travel |
| 4. Hang Dung Nham | 3 | Môi trường nóng, cần Thuốc kháng nhiệt |

---

## 10. GIAO DIỆN UI/UX

| UI | Phím | Mô tả |
|---|---|---|
| Bag | B | 3 ô công cụ + lưới 20 ô, có `Sort` và `Quick Stack` |
| World Map | M | Bản đồ giấy da 4 vùng, trữ lượng tài nguyên theo thời gian thực |
| Smelter | (tương tác) | Nhiệt kế dọc, vạch Sweet Spot, nút bơm ống thổi |
| Alchemy | (tương tác) | 2 tab: Pha thuốc, Khảm tinh dầu nguyên tố |
| Compendium | J | Nhiệm vụ, công thức hợp kim, điểm yếu Boss |

Chi tiết từng màn hình, phím tắt và gamepad: Module 6.

---

## 11. HỆ THỐNG NHIỆM VỤ

- **Main Milestones:** Tier 0 (Đốm lửa đầu tiên) → Tier 1 (Lò hầm than và Đơn hàng đầu tiên) → Tier 2-3 (Thời đại sắt thép và Săn Boss vực sâu).
- **Daily Orders:** đơn hàng ngẫu nhiên sinh lúc 06:00 mỗi ngày để kiếm Vàng và Nguyên liệu.

---

## 12. KIẾN TRÚC GODOT

### 12.1. Scene tree

```
Main (Node)
├── GameManager (autoload: state)
├── TimeManager (autoload)
├── World (Node2D)
│   ├── ForgeHub (scene)
│   └── Zones (load động từng zone)
├── UI (CanvasLayer)
│   ├── HUD
│   ├── LiveViewportPanel (SubViewportContainer)
│   └── Overlays (Bag, Smelter, Map, ...)
└── Audio (Node)
```

### 12.2. `TimeManager` (autoload)

```gdscript
extends Node

signal minute_changed(total_minutes: int)
signal hour_changed(hour: int)
signal day_started(day: int)
signal day_ended(forced: bool)

const REAL_SEC_PER_GAME_MIN := 0.75
const DAY_START := 6 * 60
const DAY_END := 24 * 60

var day: int = 1
var minutes: int = DAY_START
var paused_by: Dictionary = {}   # nguồn pause -> true
var _accum := 0.0

func _process(delta: float) -> void:
    if not paused_by.is_empty():
        return
    _accum += delta
    while _accum >= REAL_SEC_PER_GAME_MIN:
        _accum -= REAL_SEC_PER_GAME_MIN
        _advance_minute()

func _advance_minute() -> void:
    minutes += 1
    minute_changed.emit(minutes)
    if minutes % 60 == 0:
        @warning_ignore("integer_division")
        hour_changed.emit(minutes / 60)
    if minutes >= DAY_END:
        end_day(true)

func end_day(forced: bool) -> void:
    day_ended.emit(forced)
    day += 1
    minutes = DAY_START + (120 if forced else 0)
    day_started.emit(day)

func set_pause(source: StringName, on: bool) -> void:
    if on: paused_by[source] = true
    else: paused_by.erase(source)
```

`paused_by` theo nguồn để Bag và Map mở chồng nhau không mở thời gian sớm.

### 12.3. `StaminaComponent`

```gdscript
class_name StaminaComponent extends Node

signal changed(value: float, max_value: float)

@export var base_max := 120.0
var bonus_max := 0.0
var penalty_mult := 1.0        # 0.7 khi bị phạt ngất
var value := 120.0
var in_safe_zone := false
var _idle_timer := 0.0
var _regen_accum := 0.0

func max_stamina() -> float:
    return min((base_max + bonus_max) * penalty_mult, 200.0)

static func swing_cost(power: int, hardness: int) -> float:
    return 2.0 if power == hardness else 1.0

func spend(amount: float) -> bool:
    var late_mult := 1.25 if TimeManager.minutes >= 23 * 60 else 1.0
    var cost := amount * late_mult
    if value < cost:
        return false
    value -= cost
    _idle_timer = 0.0
    changed.emit(value, max_stamina())
    return true

func _process(delta: float) -> void:
    _idle_timer += delta
    if _idle_timer < 2.0:
        return
    var rate := 1.0 / 3.0
    if TimeManager.minutes >= 22 * 60:
        rate *= 0.5
    if in_safe_zone:
        rate *= 2.0
    _regen_accum += rate * delta
    if _regen_accum >= 1.0:
        value = min(value + floor(_regen_accum), max_stamina())
        _regen_accum = fmod(_regen_accum, 1.0)
        changed.emit(value, max_stamina())
```

### 12.4. `ResourceNodeData` (data-driven)

```gdscript
class_name ResourceNodeData extends Resource

@export var id: StringName
@export var display_name: String
@export var tool_type: StringName      # &"pickaxe" / &"axe" / &"sickle"
@export var max_hp: int
@export var hardness: int
@export var drops: Array[DropEntry]    # item, min, max, chance
@export var respawn_rule: StringName   # &"daily" / &"rare" / &"twice" / &"two_days"
```

Mỗi node là một file `.tres`, chỉnh cân bằng không cần sửa code.

---

## 13. LỘ TRÌNH MODULE

| # | Module | Trạng thái |
|---|---|---|
| 1 | Bố cục và luồng màn hình | Xong (mục 2, 9, 10) |
| 2 | Thời gian, Stamina, Thu hoạch | Xong (mục 3-6, 12) |
| Art | Art Bible + hệ prompt cho agent | Xong (`ART_PROMPTS.md`) |
| 3 | Lò nung, Rèn, Giả kim (công thức nhiệt, hợp kim, thuốc, Tier 3) | **Tiếp theo** |
| 4 | Mạo hiểm giả, Viewport, ECP, độ bền, kinh tế | Chưa |
| 5 | Boss, quái, bảng khắc chế nguyên tố (4-5 Boss) | Chưa |
| 6 | UI/UX chi tiết từng màn hình, phím tắt, gamepad | Chưa |
| 7 | Quest, Tutorial, Tiến trình | Chưa |
| 8 | Kiến trúc Godot mở rộng (save/load, data-driven) | Một phần (mục 12) |
| 9 | Lộ trình sản xuất: MVP, milestone, asset list | Chưa |

### Câu hỏi cần bạn chốt

1. Live Viewport dùng **side-view 192x108**, đúng không?
2. Module 3 làm tiếp theo hướng đề xuất ở mục 7.2 (nhiệt tiến dần + ống thổi là rủi ro/phần thưởng), đồng ý chứ?