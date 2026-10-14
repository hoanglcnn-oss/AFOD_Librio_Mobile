# Librio Mobile — Tổng quan sản phẩm

**Trạng thái:** Draft v1.0 — Chờ xác nhận phạm vi nghiệm thu
**Dự án:** Librio — Academic Library Resource Discovery & Availability Platform
**Hình thức phát triển:** Flutter Mobile Extension
**Bối cảnh:** Mini-project học việc Flutter tại DOFA Tech (4 tuần)

## 1. Tầm nhìn sản phẩm

Librio Mobile mở rộng nền tảng Librio hiện có sang thiết bị di động, giúp độc giả khám phá tài nguyên thư viện, kiểm tra khả dụng và gửi yêu cầu mượn sách thuận tiện hơn.

Phiên bản đầu tập trung vào trải nghiệm độc giả trên điện thoại Android, không thay thế hệ thống web.

## 2. Người dùng và nhu cầu

**Người dùng chính:** Độc giả (Reader).

Nhu cầu:

- Tìm kiếm và xem thông tin sách.
- Kiểm tra tình trạng khả dụng.
- Chọn nhiều sách dự định mượn.
- Gửi yêu cầu mượn.
- Duy trì phiên đăng nhập và danh sách chọn tạm khi mở lại ứng dụng.

## 3. Phạm vi MVP

### 3.1 Xác thực

- Đăng nhập và đăng ký tài khoản ở mức demo.
- Kiểm tra dữ liệu form và hiển thị lỗi phù hợp.
- Duy trì phiên đăng nhập.

### 3.2 Khám phá tài nguyên

- Hiển thị danh sách sách từ Mock API.
- Xem thông tin chi tiết và tình trạng khả dụng.
- Làm mới danh sách (pull-to-refresh).

### 3.3 Danh sách mượn tạm

- Thêm nhiều Resource vào danh sách.
- Mỗi Resource chỉ xuất hiện một lần.
- Xóa Resource khỏi danh sách.
- Hiển thị tổng số đầu sách đã chọn.
- Giữ danh sách khi đóng và mở lại ứng dụng.

Danh sách mượn tạm chỉ tồn tại phía client, không đồng nghĩa sách đã được đặt trước hoặc giữ chỗ.

### 3.4 Gửi yêu cầu mượn

- Xác nhận danh sách sách đã chọn.
- Gửi dữ liệu lên Mock API.
- Hiển thị trạng thái Loading, Success và Error.
- Chỉ xóa các mục đã gửi thành công theo quy ước xử lý của API.

## 4. Ngoài phạm vi MVP

- Giao diện quản trị cho thủ thư.
- Tablet/kiosk/POS chuyên dụng.
- Thanh toán, tiền phạt và thông báo đẩy.
- Phát triển backend/database mới.
- Tích hợp backend Librio thật.
- Phát hành lên Google Play hoặc App Store.

## 5. Ràng buộc kỹ thuật

- Flutter/Dart, ưu tiên Android.
- Giao diện responsive trên các kích thước điện thoại.
- Mock API phục vụ bài đánh giá.
- Quản lý state phù hợp mức độ phức tạp.
- Lưu trữ cục bộ cho dữ liệu không nhạy cảm; thông tin xác thực nhạy cảm phải được lưu an toàn.
- Git, commit và Pull Request.
- Code dễ đọc, có khả năng bảo trì và giải thích được khi review.

## 6. Khả năng mở rộng

Sau khi hoàn thành mini-project, Flutter client có thể được tích hợp với backend Librio hiện có.

Việc mở rộng sang tablet, kiosk hoặc các nhóm người dùng khác chỉ được xem xét khi có nhu cầu và yêu cầu cụ thể.

## 7. Các quyết định còn mở

- DOFA có chấp nhận thay chức năng tăng/giảm số lượng trong giỏ hàng bằng thêm/xóa Resource và quản lý tổng số đầu sách hay không.
- Quy ước Mock API khi gửi nhiều yêu cầu: thành công toàn bộ hay cho phép thành công một phần.
- State management và cấu trúc thư mục cụ thể sẽ được chọn ở giai đoạn thiết kế kỹ thuật.
