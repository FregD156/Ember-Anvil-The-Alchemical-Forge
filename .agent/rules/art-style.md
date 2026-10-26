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
