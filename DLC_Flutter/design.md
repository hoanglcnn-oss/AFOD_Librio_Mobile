# Librio Mobile — Design Direction

**Trạng thái:** Draft v1.0  
**Định hướng:** Modern Minimal + Soft Skeuomorphic Accents — không copy giao diện thương hiệu khác.

## 1. UX trước hiệu ứng

- Catalog ít chữ: ảnh bìa (nếu có), tên (tối đa hai dòng), tác giả; nhấn cả hàng để xem chi tiết.
- Chỉ nút/thao tác cần thiết trên mỗi hàng; không nhồi nhãn, icon và badge.
- Metadata chi tiết để tại màn Chi tiết; reader ưu tiên vùng văn bản thoáng.
- Ba tab chính: **Thư viện / Khám phá / Tài khoản**. Các trang cấp 2 ẩn thanh tab.
- Nút giỏ/danh sách chọn nằm trong header Khám phá; đây **không phải** giỏ thanh toán.
- Trạng thái thiếu nội dung: cho lưu sách vào Thư viện nhưng không hiển thị nút đọc giả.

## 2. Color tokens (từ palette HTML Stitch hiện tại)

| Token | HEX | Vai trò |
|---|---|---|
| `background` | `#F7F9FB` | Nền chính |
| `surface` | `#FFFFFF` | Nền trường nhập/panel khi cần |
| `text` | `#191C1E` | Chữ chính |
| `secondary` | `#006A61` | Hành động chính/accent |
| `outline` | `#76777D` | Viền/chữ phụ khi phù hợp |
| `surfaceContainerHigh` | `#E6E8EA` | Nền phụ |
| `outlineVariant` | `#C6C6CD` | Đường phân cách |

Các mã trên tham khảo palette Stitch; mức tương phản thực tế cần kiểm tra trên thiết bị.

## 3. Elevation và soft bevel (giá trị đề xuất, chưa phải tokens Stitch gốc)

- **Flat:** danh sách và mặt phẳng nội dung; có thể dùng separator rất nhẹ, không tạo card nổi hàng loạt.
- **Subtle:** bóng ngoài `0 2px 8px rgba(25,28,30,0.08)` cho surface thật sự cần tách nền.
- **Primary action soft bevel:** gradient sáng nhẹ ở mép trên, highlight tinh tế và bóng mềm vừa đủ. **Tránh đường line tối đậm dưới đáy nút**; không tạo hiệu ứng nhựa bóng kiểu Aqua nặng.
- **Raised:** chỉ modal hoặc phần tử nổi cần phân cấp, không phủ lên mọi sách.
- Gradient, highlight và inset/outer shadow cần mapping riêng khi implement Flutter; `BoxShadow` đơn lẻ không tái hiện toàn bộ bevel.

## 4. Typography và spacing (đề xuất)

- Dùng font dễ đọc và phân cấp bằng size/weight, không tăng số nhãn.
- Hệ khoảng cách bội số 4 px; radius phổ biến 8–12 px.
- Catalog: title 15–16 px, author 12–14 px; reader cho phép ít nhất một cỡ chữ dễ đọc, không cần tùy chỉnh font-size ở MVP.
- Nút bấm có vùng chạm phù hợp điện thoại; tránh badge chữ quá nhỏ.

## 5. Reader

- Nền dịu, tương phản rõ; một trang nội dung demo (có thể cuộn nếu dài).
- Hiển thị tên chương/cuốn gọn, điều hướng trang trước/sau, vị trí đọc hiện tại.
- Mục tiêu và thời gian đọc không chiếm phần lớn vùng đọc; hiển thị ở Thư viện hoặc bảng nhỏ khi cần.
- Không làm animation lật trang 3D, texture giấy cầu kỳ hay trang trí làm giảm khả năng đọc.
