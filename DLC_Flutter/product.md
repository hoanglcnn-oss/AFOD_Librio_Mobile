# Librio Mobile — Tổng quan sản phẩm

**Trạng thái:** Draft v3.0 — Chờ mentor xác nhận phạm vi nghiệm thu  
**Định hướng:** Personal Reading Library (mini-project Flutter độc lập)  
**Nền tảng:** Flutter, Android-first  
**Bối cảnh:** Học việc Flutter tại DOFA Tech; khoảng 2 tuần dành cho triển khai mini-project.

## 1. Tầm nhìn

Librio Mobile giúp người dùng **khám phá sách, xây dựng thư viện đọc cá nhân và duy trì thói quen đọc** trong một trải nghiệm đơn giản.

**Vòng lặp cốt lõi:** Khám phá → Chọn/lưu sách → Mở nội dung có sẵn → Đọc → Tự lưu vị trí → Ghi nhận thời gian → Đọc tiếp.

Ứng dụng **không phải dịch vụ phân phối ebook** và không thay thế hệ thống thư viện đại học Librio Web.

## 2. Người dùng và nhu cầu

Người dùng chính là cá nhân muốn tìm sách, quản lý danh sách đọc và theo dõi thời gian đọc mỗi ngày. Họ cần:

- Tìm sách, xem bìa, tác giả và thông tin cơ bản.
- Gom nhiều cuốn muốn đọc trước khi thêm vào thư viện cá nhân.
- Phân loại **Muốn đọc / Đang đọc / Đã đọc**.
- Mở **nội dung đọc demo được cung cấp hợp pháp trong app**, chuyển trang và tiếp tục từ vị trí cũ.
- Đặt mục tiêu đọc theo phút/ngày; thời gian đọc trong app được ghi nhận tự động.

## 3. Phạm vi MVP

### 3.1. Khám phá sách
- Tìm kiếm metadata sách từ **Google Books API**; hiển thị kết quả, chi tiết, ảnh bìa nếu có.
- Xử lý loading, empty, error và trường dữ liệu/ảnh bị thiếu.
- **Metadata không đồng nghĩa có nội dung toàn văn.** Không hiển thị nút Đọc nếu sách chưa có nội dung demo liên kết.

### 3.2. Danh sách chọn và thư viện cá nhân
- Thêm nhiều sách vào danh sách chọn tạm; tránh trùng; xóa từng cuốn trước khi xác nhận.
- Một lần xác nhận lưu các sách đã chọn vào **Thư viện của tôi**, mặc định trạng thái *Muốn đọc*.
- Thư viện cho xem/lọc và cập nhật trạng thái đọc; dữ liệu cần thiết tồn tại qua lần khởi động lại app.
- Có thể lưu metadata của sách chưa có nội dung đọc; **không hứa rằng cuốn nào lưu cũng đọc được**.

### 3.3. Trình đọc demo
- Cung cấp một **tập sách/chương mẫu được phép sử dụng**; nội dung được chuẩn bị theo các trang/chương xác định trước để demo.
- Chỉ các sách mẫu có nội dung mới có hành động **Đọc / Đọc tiếp**.
- Có chuyển trang trước/sau, hiển thị tiến độ và tự lưu vị trí đọc theo sách.
- Mở lại sách đi đến vị trí đã lưu.
- Phân trang **cố định theo dữ liệu demo**, không tuyên bố tự động dàn trang mọi EPUB/PDF hoặc mọi kích cỡ màn hình.

### 3.4. Mục tiêu và thời gian đọc
- Người dùng đặt mục tiêu phút/ngày.
- Bắt đầu đếm khi màn đọc đang hoạt động; dừng khi rời reader hoặc app chuyển nền; không cộng thời gian lúc app bị ẩn.
- Cộng dồn các phiên đọc trong ngày, lưu kết quả và hiển thị tiến độ mục tiêu.
- Đây là **reading session timer**, không phải bộ Pomodoro có lịch nghỉ và thông báo.

### 3.5. Tài khoản demo
- Đăng nhập/đăng ký với validation cơ bản; quản lý phiên demo và đăng xuất.
- Không tuyên bố có xác thực production hay đồng bộ cloud đa thiết bị.

## 4. Điều hướng

Ba tab cấp 1: **Thư viện / Khám phá / Tài khoản**.

- **Khám phá:** tìm kiếm, danh sách sách, nút mở **Danh sách chọn** ở góc trên; lựa chọn sách từ catalog.
- **Thư viện:** sách đã lưu, trạng thái đọc, mục tiêu hôm nay, vào **Đọc tiếp** nếu có nội dung.
- **Tài khoản:** đăng nhập/đăng ký demo, thông tin cơ bản.
- Cấp 2 (ẩn bottom navigation): Chi tiết sách, Danh sách chọn, Xác nhận lưu, Reader và các màn xác thực khi cần.

**Phong cách UI:** Content-first, ít chữ và nút; chỉ thành phần hành động chính dùng *soft bevel* nhẹ. Chi tiết quy định tại `design.md`.

## 5. Nguồn dữ liệu và giới hạn

- **Google Books API:** chỉ metadata/catalog; không cung cấp mặc định bản ebook toàn văn để đọc trong Librio.
- **Demo reading content:** văn bản do nhóm tự viết hoặc tác phẩm có quyền sử dụng phù hợp; đóng gói trong app/fixture. Không gắn văn bản không liên quan vào một sách thương mại rồi gọi đó là nội dung của sách ấy.
- **Mock API:** minh họa networking và các luồng yêu cầu theo tiêu chí học việc; dữ liệu cá nhân thiết yếu được lưu cục bộ. Hợp đồng và ranh giới lưu trữ sẽ xác định ở `architecture.md`.

## 6. Ngoài phạm vi MVP

- Import, parse và render EPUB/PDF bất kỳ; trình đọc ebook production.
- Tải ebook có bản quyền từ nguồn khác; DRM, thanh toán, thuê sách.
- Highlight, annotation, TTS, tìm kiếm toàn văn, đồng bộ đa thiết bị.
- Thủ thư, đặt mượn sách giấy, quản lý kho, lưu thông vật lý.
- Pomodoro đầy đủ, notification, gamification và hệ thống gợi ý AI.
- Phát hành lên kho ứng dụng.

## 7. Tiêu chí hoàn thành

1. Tìm và xem metadata sách từ API, kể cả loading/error/empty.
2. Chọn nhiều sách, loại bỏ sách không muốn và lưu một lần vào thư viện; không tạo bản ghi trùng.
3. Đổi trạng thái đọc, duy trì thư viện sau khi mở lại app.
4. Với **sách demo có nội dung**, đọc/chuyển trang/đọc tiếp đúng vị trí đã lưu.
5. Đặt mục tiêu phút/ngày; phiên đọc được cộng dồn và không tính khi app nền.
6. Đăng nhập/đăng ký demo, Git/PR, xử lý lỗi và trình bày demo theo yêu cầu mentor.

## 8. Cần xác nhận với mentor

- Việc **chọn và lưu nhiều sách** có đáp ứng tiêu chí thay thế giỏ hàng/checkout (đặc biệt phần tăng/giảm số lượng) của đề tài mẫu DOFA không.
- Mức độ yêu cầu đối với Mock API và lưu dữ liệu cá nhân.

## 9. Quan hệ với dự án Librio gốc

Librio Web vẫn là hệ thống thư viện đại học với domain mượn tài nguyên; giữ nguyên các tài liệu gốc. **Librio Mobile là mini-project độc lập lấy cảm hứng từ tên và trải nghiệm khám phá sách**, không khẳng định sử dụng hay tương thích backend Librio Web.
