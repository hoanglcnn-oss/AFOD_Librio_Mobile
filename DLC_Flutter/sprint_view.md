Đúng rồi. Hồi trước ta đã chốt roadmap mở rộng Librio Mobile thành 3 Sprint, với định hướng:

- Sprint 1: Hoàn thiện vòng đời mượn–trả sách (workflow khép kín).
- Sprint 2: Mobile-first Experience — tận dụng các tính năng đặc trưng của điện thoại.
- Sprint 3: Smart Library — các chức năng thông minh, có thể cần mở rộng backend.

## Tổng quan roadmap

Sprint 1 — Borrowing Lifecycle

Đang thực hiện

Hoàn thiện nghiệp vụ cốt lõi bằng các API backend đã có.

1. My Borrowings: Xem sách đang mượn và lịch sử mượn.
2. Return Book: Trả sách, cập nhật số lượng tồn kho.
3. Renew Borrowing: Gia hạn thời gian mượn sách.
4. Overdue: Xem sách quá hạn, trạng thái, tiền phạt và kiểm thử toàn bộ workflow.

Luồng khép kín:

`Books → Borrow → My Borrowings → Return / Renew → History`

Tiến độ: Đã hoàn thành Data Layer GET /borrowings và push lên feat/Sprint1_expansion. Tiếp theo là BLoC + UI.

Sprint 2 — Mobile-first Experience

Biến Librio thành ứng dụng điện thoại thực sự, thay vì phiên bản thu nhỏ của trang web quản lý thư viện.

1. Enhanced ISBN Scanner: Flash, đổi camera, chống quét trùng, rung phản hồi và xử lý quyền camera.
2. Mobile UX: Pull-to-refresh, swipe, bottom sheet, skeleton loading.
3. Digital Library Card: Thẻ thư viện điện tử, mã QR và thông tin độc giả.
4. Local Notifications: Nhắc lịch trả sách trước 3 ngày, 1 ngày hoặc khi gần quá hạn.
5. Offline Book Cache: Lưu thông tin sách đã tải để xem khi mất mạng.

Phần lớn có thể làm phía Flutter mà chưa cần backend mới. Riêng QR xác thực tại quầy cần thống nhất quy trình với backend.

Sprint 3 — Smart Library

Mở rộng trải nghiệm cá nhân hóa và tương tác với hệ thống thư viện.

1. Favorites / Wishlist: Lưu sách yêu thích, đồng bộ giữa các thiết bị.
2. Book Reservation: Đặt trước sách đang hết hàng và quản lý hàng chờ.
3. Personalized Recommendations: Gợi ý sách theo thể loại, lịch sử mượn hoặc sở thích.
4. Push Notifications: Thông báo từ thư viện về sách đặt trước, thay đổi phiếu mượn và các sự kiện liên quan.

Các mục này có khả năng cần mentor bổ sung API, database hoặc cơ chế thông báo từ server.


## Thứ tự ưu tiên giữ nguyên

| Giai đoạn | Mục tiêu hoàn thành                                                   |
| --------- | --------------------------------------------------------------------- |
| Sprint 1  | Một độc giả có thể mượn → xem phiếu → gia hạn hoặc trả → xem lịch sử  |
| Sprint 2  | Ứng dụng có trải nghiệm mobile nổi bật: camera, QR, nhắc hạn, offline |
| Sprint 3  | Có khả năng cá nhân hóa và tương tác nâng cao với backend             |