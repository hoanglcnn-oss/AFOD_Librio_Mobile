# Librio Mobile — Yêu cầu MVP

**Trạng thái:** Draft v2.0  
**Nguồn phạm vi:** `product.md` v3.0  
**Quy ước:** P0 = bắt buộc khi demo; P1 = bổ sung nếu còn thời gian. Mọi yêu cầu ở dưới mặc định P0 trừ khi có nhãn P1.

## 1. Yêu cầu chức năng

| ID | Yêu cầu | Điều kiện nghiệm thu tối thiểu |
|---|---|---|
| FR-01 | Đăng nhập / đăng ký demo | Validate đầu vào, phản hồi sai thông tin, duy trì phiên hợp lệ và đăng xuất |
| FR-02 | Tìm catalog qua API | Nhập từ khóa, gọi API, hiển thị kết quả; có loading/empty/error |
| FR-03 | Xem chi tiết sách | Hiển thị title, authors, cover, description khi có; graceful fallback khi thiếu |
| FR-04 | Danh sách chọn tạm | Thêm nhiều `Book` theo khóa duy nhất, bỏ từng sách, không có duplicate |
| FR-05 | Lưu nhiều sách vào Thư viện | Xem lại lựa chọn, xác nhận một lần, không lưu trùng, chỉ xóa lựa chọn khi lưu thành công |
| FR-06 | Thư viện cá nhân | Xem/lọc Muốn đọc–Đang đọc–Đã đọc, đổi trạng thái, khởi động lại vẫn có dữ liệu |
| FR-07 | Reader nội dung demo | Chỉ sách được gắn `ReadableContent` hợp lệ mới có nút Đọc; có trước/sau và định vị trang |
| FR-08 | Resume reading | Đóng reader, mở lại đúng trang/vị trí đã lưu theo sách |
| FR-09 | Reading session timer | Đếm khi reader foreground/active, dừng khi rời reader/background, tránh đếm trùng |
| FR-10 | Mục tiêu đọc theo ngày | Đặt số phút mục tiêu dương, hiển thị tổng thời gian ngày hiện tại và mức hoàn thành |
| FR-11 | Lưu trạng thái cục bộ | Lưu thư viện, trang đọc, mục tiêu và session đã hoàn tất; xử lý mở lại app |
| FR-12 | Phản hồi các trạng thái | API lỗi, không có nội dung demo, lỗi lưu hoặc danh sách rỗng đều có thông báo phù hợp |

## 2. Quy tắc nghiệp vụ

| ID | Quy tắc |
|---|---|
| BR-01 | Metadata sách (`Book`) và nội dung đọc (`ReadableContent`) là hai nguồn dữ liệu tách biệt. |
| BR-02 | Kết quả Google Books API không mặc định có nội dung toàn văn để đọc. |
| BR-03 | Mỗi sách có tối đa một mục trong danh sách chọn và một mục trong Thư viện của người dùng. |
| BR-04 | Xác nhận lưu vào thư viện **không phải mua, mượn hoặc tải ebook**. |
| BR-05 | Khi chuyển từ Muốn đọc sang Đang đọc không yêu cầu sách có nội dung trong app; người dùng có thể đang đọc sách giấy. |
| BR-06 | Vị trí đọc chỉ áp dụng cho sách có `ReadableContent`; không dựa trên số trang ước lượng từ metadata. |
| BR-07 | Bộ đếm chỉ ghi nhận thời gian reader đang active; background, khóa màn hình hoặc rời reader phải tạm dừng. |
| BR-08 | Khi không thể xác định thời điểm bắt đầu/kết thúc phiên, không tự cộng thời gian mất kiểm soát. |
| BR-09 | Thời gian ngày được tính theo ngày địa phương của thiết bị; không ghi nhận âm, không tăng cùng một phiên hai lần. |
| BR-10 | Nội dung demo phải có quyền sử dụng phù hợp và thể hiện đúng tên tác phẩm/nguồn. |

## 3. Trường hợp kiểm thử tối thiểu

- Tìm thành công, tìm rỗng, API timeout/error, metadata thiếu bìa/tác giả.
- Thêm sách A hai lần; chọn A+B, bỏ B rồi xác nhận; mở lại app thấy A trong thư viện.
- Thử đọc sách chỉ có metadata → không hiện nút đọc hoặc giải thích chưa có nội dung.
- Mở sách demo, chuyển trang, thoát, mở lại đúng trang.
- Reader đang chạy → app background → trở lại foreground; thời gian không tăng khi app nền.
- Đọc hai phiên trong một ngày → tổng cộng đúng; mở lại ứng dụng không cộng lặp.
- Danh sách chọn rỗng → không cho xác nhận; lưu lỗi → không mất các sách đang chọn.

## 4. Yêu cầu phi chức năng

- **NFR-01:** Android-first, màn hình nhỏ vẫn đọc và bấm được; chữ dễ đọc, không nhồi metadata.
- **NFR-02:** Tách UI, business logic và data access ở mức đủ bảo trì; không over-engineer.
- **NFR-03:** Không hard-code hoặc commit secrets/token thật; phiên demo không được quảng cáo là bảo mật production.
- **NFR-04:** Có Git commit/PR, mô tả cách chạy và demo dữ liệu mẫu.
- **NFR-05:** Sử dụng dữ liệu và nội dung đúng giấy phép/điều kiện của provider.

## 5. Ngoài phạm vi và điểm còn mở

Không yêu cầu EPUB/PDF parser, import file, DRM, ebook store, mượn sách đại học, đồng bộ cloud hoặc UI quản trị.

**Cần mentor chấp thuận:** Flow lưu nhiều sách thay cho cart/checkout mẫu; yêu cầu quantity trong đề mẫu chưa được bảo đảm bởi danh sách không trùng. Chi tiết chọn Mock API/local storage và format fixture reader cần chốt trong `architecture.md`.
