# Librio Mobile — Product Overview

**Status:** Draft v1.0  
**Product type:** Flutter mobile client for Librobe Library Management System  
**Platform:** Android-first  
**Backend:** [Librobe API](https://api.leorank.site/api/docs)  
**Backend source:** [peggy2402/librobe](https://github.com/peggy2402/librobe)  
**Mobile source:** [AFOD_Librio_Mobile](https://github.com/hoanglcnn-oss/AFOD_Librio_Mobile)

---

## 1. Why — Bối cảnh và mục tiêu

Librobe đã cung cấp hệ thống backend quản lý thư viện với các phân hệ xác thực, sách, độc giả, mượn/trả và thống kê.

Librio Mobile được phát triển nhằm xây dựng một ứng dụng Flutter sử dụng lại các API này, chuyển các nghiệp vụ phù hợp thành trải nghiệm trên thiết bị di động.

Dự án không xây dựng lại backend và không nhằm sao chép toàn bộ giao diện quản trị của hệ thống gốc.

**Mục tiêu sản phẩm:**

- Cung cấp giao diện mobile để khám phá thông tin sách trong thư viện.
- Cho phép người dùng đăng ký, đăng nhập và quản lý phiên.
- Hỗ trợ các thao tác liên quan đến mượn sách trong phạm vi backend cho phép.
- Hiển thị dữ liệu thật từ Librobe API và phản hồi đúng các trạng thái nghiệp vụ.
- Tạo một mini-project Flutter có luồng sử dụng hoàn chỉnh, dễ trình bày và kiểm thử.

**Mục tiêu học việc:** Vận dụng Flutter/Dart, quản lý trạng thái, REST API integration, navigation, responsive UI và kiểm thử trong một dự án có backend thực tế.

## 2. Users — Đối tượng sử dụng

### 2.1. Primary User — Độc giả (MEMBER)

Người dùng chính của MVP là độc giả thư viện.

**Nhu cầu:**

- Đăng ký và đăng nhập tài khoản.
- Tìm kiếm sách theo tên hoặc thông tin liên quan.
- Xem thông tin sách, tác giả, thể loại và số lượng còn.
- Theo dõi thông tin mượn sách, hạn trả và trạng thái.
- Thực hiện những thao tác mượn/gia hạn được backend cho phép.
- Xem thông tin tài khoản và đăng xuất.

### 2.2. Secondary User — Thủ thư / Quản trị viên

Backend còn hỗ trợ quản lý sách, độc giả, mượn/trả, tiền phạt và báo cáo.

Các chức năng này là **khả năng mở rộng**, không mặc định thuộc MVP Flutter.

Việc triển khai giao diện cho thủ thư/quản trị viên phụ thuộc vào yêu cầu mentor và cơ chế phân quyền được xác nhận.

## 3. Direction — Định hướng sản phẩm

### 3.1. Backend-first adaptation

Librio Mobile là client tiêu thụ Librobe REST API.

**Nguyên tắc phát triển:**

1. Ưu tiên nghiệp vụ và dữ liệu mà backend đã hỗ trợ.
2. Không tự tạo API hoặc thay đổi business rules phía client.
3. Không giả lập tính năng chưa có backend rồi trình bày như chức năng thật.
4. Chỉ triển khai subset chức năng phù hợp với thời gian và đối tượng sử dụng.
5. Tách việc hiển thị giao diện khỏi xử lý state và truy cập API.
6. Ưu tiên hoàn thiện luồng end-to-end trước khi mở rộng chức năng.

### 3.2. Mobile experience

Ứng dụng tập trung vào thao tác nhanh và đơn giản trên điện thoại.

Hành trình người dùng dự kiến:

**Khám phá sách → Xem chi tiết → Đăng nhập khi cần → Thực hiện nghiệp vụ mượn sách → Theo dõi phiếu mượn.**

Người dùng có thể xem catalog mà không cần đăng nhập, do API Books hỗ trợ truy cập công khai. Những thao tác cần nhận diện người dùng sẽ yêu cầu đăng nhập.

### 3.3. Product boundaries

**Backend chịu trách nhiệm:**
- Xác thực tài khoản và cấp JWT.
- Truy xuất, tìm kiếm và phân trang sách.
- Kiểm tra điều kiện mượn/trả.
- Quản lý tồn kho và trạng thái phiếu mượn.
- Thực thi nghiệp vụ và lưu trữ dữ liệu.

**Flutter Mobile chịu trách nhiệm:**
- Cung cấp giao diện và điều hướng.
- Thu thập, kiểm tra dữ liệu đầu vào.
- Gửi request, nhận và hiển thị response.
- Quản lý trạng thái giao diện và phiên ứng dụng.
- Thông báo lỗi và kết quả thao tác.
- Thích ứng bố cục với kích thước màn hình.

Các quy tắc nghiệp vụ ở Flutter chỉ phục vụ trải nghiệm, không thay thế kiểm tra từ backend.

## 4. Scope — Phạm vi sản phẩm

### 4.1. MVP — Chức năng ưu tiên

**P0 — Authentication & Session**

- Đăng ký tài khoản độc giả.
- Đăng nhập bằng thông tin tài khoản hợp lệ.
- Xử lý lỗi xác thực.
- Lưu và khôi phục phiên hợp lệ.
- Xem thông tin tài khoản.
- Đăng xuất.

**P0 — Books Catalog**

- Xem danh sách sách từ backend.
- Tìm kiếm theo từ khóa.
- Xem chi tiết sách.
- Hiển thị thông tin tác giả, thể loại và tình trạng tồn kho khi dữ liệu có sẵn.
- Xử lý phân trang và các trạng thái loading, empty, error.

**P0 — Core Mobile Navigation**

- Luồng điều hướng giữa Authentication, Books, Book Detail và Profile.
- Giao diện dùng được trên điện thoại.
- Phản hồi rõ ràng khi thao tác thành công hoặc thất bại.

### 4.2. Conditional MVP — Borrowing

Đây là nghiệp vụ có giá trị trực tiếp với sản phẩm, nhưng cần hoàn tất kiểm tra về quyền và phạm vi dữ liệu trước khi cam kết triển khai.

**Các khả năng dự kiến:**

- Xem danh sách phiếu mượn liên quan đến người dùng.
- Xem chi tiết phiếu mượn.
- Tạo yêu cầu mượn sách theo luồng backend hỗ trợ.
- Xem hạn trả, trạng thái và số lần gia hạn.
- Gia hạn hoặc trả sách nếu được phép.

**Điều kiện đưa vào MVP:**

- Xác định được memberId tương ứng với tài khoản đang đăng nhập.
- Backend bảo đảm người dùng chỉ có thể truy cập và thao tác lên dữ liệu được phép.
- Flow mượn/trả trên mobile được mentor chấp thuận.

Nếu chưa đáp ứng, Borrowings chuyển thành phần mở rộng và không được thay bằng xử lý giả lập trên client.

### 4.3. P1 — Chức năng mở rộng

- Lọc sách theo tác giả, thể loại, trạng thái.
- Tra cứu ISBN.
- Đổi mật khẩu.
- Lịch sử mượn và thông tin quá hạn.
- Các thao tác gia hạn/trả sách bổ sung khi có phân quyền phù hợp.

### 4.4. P2 — Admin/Staff Extension

- Quản lý đầu sách: thêm, sửa, xóa.
- Quản lý tác giả và thể loại.
- Quản lý độc giả.
- Quản lý phiếu mượn và ghi nhận thanh toán phạt.
- Xem dashboard thống kê.

Các chức năng P2 không bắt buộc trong MVP.

### 4.5. Out of Scope

- Xây dựng hoặc triển khai lại Librobe backend.
- Thiết kế database riêng cho mobile.
- Google Books API.
- EPUB/PDF reader hoặc cung cấp nội dung ebook.
- Reading timer, reading goals, thư viện đọc cá nhân độc lập.
- Thanh toán trực tuyến.
- Notification, chat, AI recommendations.
- Phát hành ứng dụng lên Google Play.
- Các chức năng không có API/backend tương ứng nếu chưa được duyệt mở rộng.

## 5. Capability Map — Ánh xạ chức năng và backend

| Capability | User-facing behavior | Backend support | Priority |
|---|---|---|---|
| Account Registration | Tạo tài khoản | POST `/auth/register` | P0 |
| Account Login | Đăng nhập | POST `/auth/login` | P0 |
| Session & Profile | Duy trì phiên, xem hồ sơ | GET `/auth/me` + JWT | P0 |
| Logout | Kết thúc phiên trên thiết bị | Client-side token removal | P0 |
| Book Discovery | Xem danh sách và tìm kiếm | GET `/books` | P0 |
| Book Detail | Xem thông tin sách | GET `/books/:id` | P0 |
| Book Filtering | Lọc theo tiêu chí | GET `/books` + query | P1 |
| Borrowing History | Xem phiếu mượn | GET `/borrowings` | Conditional |
| Borrowing Detail | Xem chi tiết phiếu | GET `/borrowings/:id` | Conditional |
| Borrow Book | Tạo phiếu mượn | POST `/borrowings` | Conditional |
| Return Book | Trả sách | POST `/borrowings/:id/return` | Conditional |
| Renew Loan | Gia hạn | POST `/borrowings/:id/renew` | Conditional |
| Change Password | Đổi mật khẩu | POST `/auth/change-password` | P1 |
| Book Management | Quản trị sách | POST/PATCH/DELETE `/books` | P2 |
| Member Management | Quản trị độc giả | `/members` | P2 |
| Statistics | Dashboard | GET `/stats` | P2 |

*Các endpoint trong bảng dùng tiền tố chung `/api`.*

**Chú thích:**
- P0: Phạm vi ưu tiên phải hoàn thiện trước.
- P1: Bổ sung khi P0 ổn định.
- P2: Mở rộng dành cho vai trò quản trị.
- Conditional: Backend có endpoint nhưng còn phụ thuộc xác nhận luồng nghiệp vụ và phân quyền.

## 6. Success Criteria — Tiêu chí thành công

MVP được coi là đạt yêu cầu sản phẩm khi:

1. Người dùng đăng ký và đăng nhập được với backend thật.
2. Phiên đăng nhập hợp lệ có thể được khôi phục; logout hoạt động.
3. Người dùng xem, tìm kiếm và mở chi tiết sách từ dữ liệu API.
4. Các trạng thái loading, empty, error được xử lý rõ ràng.
5. Điều hướng nhất quán, không phát sinh lỗi nghiêm trọng trên thiết bị thử nghiệm.
6. Có ít nhất một luồng sử dụng hoàn chỉnh được kiểm thử và trình bày trong demo.
7. Các chức năng công bố trong demo tương ứng với khả năng triển khai thực tế.

Nếu Borrowings được xác nhận thuộc MVP, bổ sung tiêu chí nghiệm thu riêng cho vòng đời phiếu mượn.

## 7. Open Questions

Cần xác nhận trước khi mở rộng Borrowings:

- Mobile được phát triển chủ yếu cho MEMBER hay cho STAFF/ADMIN?
- Người dùng MEMBER có được tự tạo phiếu mượn và gia hạn/trả sách không?
- Backend đã giới hạn quyền truy cập phiếu mượn theo tài khoản chưa?
- Có cần màn quản trị trên mobile hay chỉ cần trải nghiệm độc giả?
- Mentor yêu cầu demo bắt buộc nghiệp vụ nào ngoài Authentication và Books?

Các vấn đề này không cản trở việc tiếp tục triển khai Authentication và Books Catalog.

---

## 8. Current Product Progress

**Completed & verified:**
- Login/Register UI.
- Validation và responsive cơ bản.
- Authentication API integration.
- Kết nối backend thành công.
- Bốn test case Authentication cơ bản đã PASS.

**Next:**
- JWT response và session management.
- Home/Profile navigation.
- Books Catalog integration.

**Not started:**
- Books UI với API thật.
- Borrowings mobile flow.
- Các chức năng mở rộng P1/P2.
