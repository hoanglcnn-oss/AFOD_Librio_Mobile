# Librio Mobile — Domain Model

**Version:** Draft v1.0  
**Status:** In progress  
**References:** `product.md`, `requirements.md`  
**Backend source:** [Librobe](https://github.com/peggy2402/librobe)

---

## 1. Domain Overview

Librio Mobile là ứng dụng Flutter sử dụng các nghiệp vụ và dữ liệu từ Librobe Library Management System.

Ứng dụng không định nghĩa lại quy tắc quản lý thư viện, mà sử dụng domain model của backend để hiển thị dữ liệu và hỗ trợ tương tác trên thiết bị di động.

### Domain boundaries

**Backend-owned domain:**
- User và Member
- Books, Authors, Categories
- Borrowings và quy tắc mượn/trả
- Kiểm tra tồn kho, giới hạn mượn, gia hạn và tiền phạt

**Mobile-owned application state:**
- Phiên đăng nhập cục bộ
- Trạng thái điều hướng
- Loading, success, empty, error
- Từ khóa tìm kiếm và bộ lọc
- Dữ liệu màn hình đang hiển thị

Flutter không được tự tạo hoặc thay đổi trạng thái nghiệp vụ mà chưa được backend xác nhận.

---

## 2. Core Domain Concepts

### 2.1. User — Tài khoản hệ thống

`User` đại diện cho tài khoản dùng để xác thực và truy cập hệ thống.

**Core attributes:**

| Attribute | Type | Description |
|---|---|---|
| id | String | Định danh tài khoản |
| email | String | Email đăng nhập |
| phone | String | Số điện thoại |
| fullName | String | Họ tên |
| role | UserRole | Vai trò hệ thống |
| isActive | Boolean | Trạng thái tài khoản |
| memberId | String? | ID thẻ độc giả liên kết |

**UserRole:**
- `ADMIN`
- `LIBRARIAN`
- `MEMBER`

**Domain rules:**
- Email và số điện thoại đăng ký phải duy nhất.
- Tài khoản không hoạt động không được đăng nhập.
- Người đăng ký mặc định có vai trò MEMBER.
- Tài khoản MEMBER có thể được liên kết với hồ sơ Member.
- `User.id` không đồng nghĩa `Member.id`.

**Mobile usage:** Authentication, Profile và xác định vai trò người dùng.

### 2.2. Member — Độc giả thư viện

`Member` đại diện cho hồ sơ độc giả và thẻ thư viện dùng trong nghiệp vụ mượn sách.

**Core attributes:**

| Attribute | Type | Description |
|---|---|---|
| id | String | Định danh độc giả |
| cardNumber | String | Mã thẻ thư viện |
| fullName | String | Họ tên độc giả |
| membershipExpiry | DateTime | Hạn thẻ |
| status | MemberStatus | Trạng thái thẻ |
| maxBorrowLimit | int | Giới hạn số sách được mượn |
| currentBorrowedCount | int | Số sách hiện đang mượn |

**MemberStatus:**
- `ACTIVE`
- `SUSPENDED`
- `EXPIRED`

**Domain rules:**
- Thẻ hợp lệ là điều kiện cần để mượn sách.
- Độc giả không được vượt giới hạn mượn.
- Thẻ bị tạm khóa hoặc hết hạn không đủ điều kiện mượn.
- Tình trạng thẻ và giới hạn mượn do backend quản lý.

**Mobile usage:** Hiển thị trạng thái độc giả và xác định điều kiện tham gia Borrowing Flow.

**Open issue:** Cần xác minh cách mobile lấy `memberId` từ phiên đăng nhập. AuthResponse hiện công bố `UserProfile` không có trường này, dù User entity và JWT payload có `memberId`.

### 2.3. Book — Đầu sách trong thư viện

`Book` đại diện cho một đầu sách được thư viện quản lý, gồm metadata và số lượng bản in.

**Core attributes:**

| Attribute | Type | Description |
|---|---|---|
| id | String | Định danh sách |
| isbn | String | Mã ISBN |
| title | String | Tựa sách |
| authorId | String | ID tác giả |
| authorName | String | Tên tác giả |
| categoryId | String | ID thể loại |
| categoryName | String | Tên thể loại |
| copiesTotal | int | Tổng số bản |
| copiesAvailable | int | Số bản còn để mượn |
| status | BookStatus | Trạng thái sách |
| coverUrl | String? | Ảnh bìa |
| description | String | Mô tả sách |

Các thuộc tính bổ sung: publisher, publishYear, shelfLocation, createdAt, updatedAt.

**BookStatus:**
- `AVAILABLE`
- `LOW_STOCK`
- `OUT_OF_STOCK`
- `DISCONTINUED`

**Domain rules:**
- Một Book có thể xuất hiện trong nhiều Borrowing.
- Một Borrowing chỉ tham chiếu một Book.
- `copiesAvailable` không được âm hoặc lớn hơn `copiesTotal`.
- Sách `DISCONTINUED` không đủ điều kiện mượn.
- Sách không còn bản sẵn có không được tạo phiếu mượn mới.
- Số lượng tồn kho được cập nhật bởi backend sau giao dịch hợp lệ.

**Mobile usage:** Books Catalog, Search, Book Detail và hiển thị khả năng mượn.

### 2.4. Borrowing — Phiếu mượn sách

`Borrowing` đại diện cho một giao dịch mượn một đầu sách của một độc giả.

**Core attributes:**

| Attribute | Type | Description |
|---|---|---|
| id | String | Định danh phiếu mượn |
| transactionCode | String | Mã giao dịch |
| memberId | String | ID độc giả |
| bookId | String | ID sách |
| borrowDate | DateTime | Ngày mượn |
| dueDate | DateTime | Hạn trả |
| returnDate | DateTime? | Ngày trả thực tế |
| status | BorrowingStatus | Trạng thái phiếu |
| renewCount | int | Số lần gia hạn |
| fineAmount | num | Tiền phạt |
| finePaid | bool | Trạng thái thanh toán phạt |

**BorrowingStatus:**
- `BORROWED`
- `RETURNED`
- `OVERDUE`

**Domain rules:**
- Mỗi phiếu mượn liên kết đúng một Member và một Book.
- Một Member có thể có nhiều Borrowing.
- Một Book có thể xuất hiện trong nhiều Borrowing.
- Một phiếu mượn hoàn tất không được trả lần thứ hai.
- Gia hạn chỉ được thực hiện khi phiếu đủ điều kiện.
- Số lần gia hạn tối đa theo backend hiện tại là 2.
- Tiền phạt được backend xác định, không tự tính thành dữ liệu chính thức ở client.

**Mobile usage:** Danh sách phiếu mượn, chi tiết phiếu, trạng thái mượn/trả và hành động gia hạn nếu được phép.

### 2.5. AuthSession — Phiên đăng nhập phía client

`AuthSession` là mô hình trạng thái phiên trong Flutter, không phải thực thể được lưu thành bảng riêng trên backend.

**Core attributes:**

| Attribute | Type | Description |
|---|---|---|
| accessToken | String | Bearer JWT |
| tokenType | String | Loại token |
| expiresIn | int | Thời hạn tính bằng giây |
| user | UserProfile | Thông tin tài khoản |

**Session rules:**
- Token được backend cấp khi đăng nhập hoặc đăng ký thành công.
- Token có hiệu lực 24 giờ theo cấu hình backend hiện tại.
- Session lưu cục bộ không bảo đảm token vẫn được server chấp nhận.
- App cần xác minh phiên khi khôi phục.
- Logout xóa session cục bộ.
- Không ghi log token hoặc lưu dưới dạng hard-code.

---

## 3. Domain Relationships

### 3.1. User ↔ Member

Một tài khoản User có thể liên kết với một Member.

- User sử dụng để đăng nhập và xác thực.
- Member sử dụng để quản lý thẻ thư viện và mượn sách.
- Không phải mọi User đều có Member.
- Mobile không được thay `memberId` bằng `userId`.

### 3.2. Member ↔ Borrowing

Một Member có thể có nhiều Borrowing.

Mỗi Borrowing phải thuộc về một Member hợp lệ.

### 3.3. Book ↔ Borrowing

Một Book có thể được mượn nhiều lần trong những giao dịch khác nhau.

Mỗi Borrowing tham chiếu đúng một Book.

### 3.4. Author / Category ↔ Book

- Một Book tham chiếu một tác giả chính và một thể loại theo backend hiện tại.
- Một Author có thể liên kết nhiều Book.
- Một Category có thể liên kết nhiều Book.

Trong MVP, Flutter chỉ cần các trường `authorName`, `categoryName` có sẵn trên Book response.

Chưa cần xây dựng Author/Category model riêng nếu chưa triển khai chức năng lọc hoặc quản lý tương ứng.

---

## 4. Domain Lifecycles

### 4.1. Authentication Lifecycle

**Unauthenticated → Authenticating → Authenticated**

Các trường hợp:

- Login thành công: chuyển sang authenticated.
- Login thất bại: giữ trạng thái unauthenticated và hiển thị lỗi.
- Session restore hợp lệ: chuyển sang authenticated.
- Token hết hạn/không hợp lệ: trở về unauthenticated.
- Logout: xóa phiên và trở về unauthenticated.

Loading và failure là trạng thái xử lý của ứng dụng Flutter, không phải trạng thái tài khoản được lưu trong backend.

### 4.2. Book Availability Lifecycle

Các trạng thái do backend hỗ trợ:

- `AVAILABLE`
- `LOW_STOCK`
- `OUT_OF_STOCK`
- `DISCONTINUED`

**Các sự kiện có thể ảnh hưởng:**
- Nhập thêm sách.
- Tạo phiếu mượn.
- Trả sách.
- Điều chỉnh kho từ chức năng quản trị.
- Ngừng lưu hành.

Flutter chỉ cập nhật UI dựa trên response mới nhất từ backend.

Không tự suy diễn rằng mọi trạng thái đều có thể chuyển trực tiếp sang nhau.

### 4.3. Borrowing Lifecycle

**Luồng cơ bản:**

1. Người dùng chọn sách.
2. Gửi yêu cầu mượn theo quyền hợp lệ.
3. Backend kiểm tra điều kiện độc giả và tồn kho.
4. Nếu hợp lệ, backend tạo Borrowing với trạng thái `BORROWED`.
5. Phiếu có thể được gia hạn nếu đủ điều kiện.
6. Khi quá hạn, backend có thể cập nhật trạng thái `OVERDUE`.
7. Khi hoàn trả hợp lệ, backend cập nhật thành `RETURNED`.

**Các chuyển trạng thái chính:**

| Current | Event | Result |
|---|---|---|
| Chưa tồn tại | Borrow success | BORROWED |
| BORROWED | Renew success | BORROWED, dueDate thay đổi |
| BORROWED | Overdue detected | OVERDUE |
| BORROWED | Return success | RETURNED |
| OVERDUE | Return success | RETURNED |
| RETURNED | Return/Renew | Bị từ chối |

Lưu ý: Backend hiện xử lý phát hiện quá hạn khi thực hiện một số thao tác đọc Borrowings; Flutter không tự ghi thay đổi trạng thái quá hạn lên server.

### 4.4. Member Lifecycle

**Trạng thái thẻ:**
- ACTIVE
- SUSPENDED
- EXPIRED

Một Member không đủ điều kiện mượn nếu thẻ không ACTIVE hoặc đã quá hạn sử dụng.

Các thao tác thay đổi trạng thái thẻ thuộc nghiệp vụ backend/quản trị, không thuộc MVP member-facing.

---

## 5. Domain Invariants

Invariant là quy tắc phải luôn được bảo toàn bởi hệ thống.

| ID | Invariant | Owner |
|---|---|---|
| INV-01 | Email/số điện thoại tài khoản là duy nhất | Backend |
| INV-02 | User ID khác Member ID | Backend contract |
| INV-03 | Phiếu mượn luôn tham chiếu đúng Member và Book | Backend |
| INV-04 | `0 ≤ copiesAvailable ≤ copiesTotal` | Backend |
| INV-05 | Không tạo phiếu mượn nếu không đủ điều kiện | Backend |
| INV-06 | Không trả một phiếu đã trả | Backend |
| INV-07 | Không gia hạn vượt giới hạn backend | Backend |
| INV-08 | Flutter không tự xem giao dịch là thành công khi request thất bại | Mobile |
| INV-09 | Flutter không tự sửa tồn kho hoặc tiền phạt thành dữ liệu chính thức | Mobile |
| INV-10 | Token không được đưa vào source code hoặc logs | Mobile |
| INV-11 | Client-side UI restriction không thay thế backend authorization | Backend + Mobile |

---

## 6. Client-side Domain Representation

Flutter chỉ cần tạo model tương ứng với các response đang dùng.

**Trong Authentication MVP:**
- `AuthResponse`
- `UserProfile`

**Trong Books MVP:**
- `Book`
- `PaginatedBooks` hoặc một response wrapper đơn giản

**Nếu triển khai Borrowings:**
- `Borrowing`
- `BorrowingStatus`
- DTO tạo/gia hạn/trả sách theo API

Không cần tạo lại đầy đủ Prisma schema, aggregate repository theo DDD hoặc domain service chỉ để chuyển đổi JSON.

Các UI-only state như loading, empty, selected tab và search query không được coi là backend entities.

---

## 7. Open Domain Questions

| ID | Question | Why it matters |
|---|---|---|
| DQ-01 | Cách lấy `memberId` của User sau đăng nhập? | Cần cho Borrowing Flow |
| DQ-02 | MEMBER có được truy cập/tạo/trả/gia hạn phiếu hay chỉ thủ thư? | Quyết định luồng mobile |
| DQ-03 | Backend đã bảo vệ quyền sở hữu Borrowing chưa? | Tránh truy cập dữ liệu người khác |
| DQ-04 | Mobile có cần hỗ trợ vai trò LIBRARIAN/ADMIN không? | Quyết định scope và navigation |
| DQ-05 | Có cần hiển thị thông tin thẻ Member hay chỉ Profile? | Quyết định dữ liệu màn tài khoản |

Các câu hỏi này không ngăn việc triển khai Authentication hoặc Books Catalog.

---

## 8. Relation to Other Documents

- `product.md`: Xác định đối tượng sử dụng và phạm vi nghiệp vụ.
- `requirements.md`: Xác định hành vi và tiêu chí nghiệm thu.
- `domain.md`: Xác định dữ liệu nghiệp vụ, quan hệ, vòng đời và invariants.
- `architecture.md`: Xác định cách Flutter kết nối, tổ chức và xử lý domain data.
- `design/`: Mô tả chi tiết các flow cần thiết kế riêng.

Tài liệu domain chỉ thay đổi khi khái niệm hoặc quy tắc nghiệp vụ thay đổi, không cần chỉnh khi thay đổi màu sắc, bố cục hoặc chi tiết widget.
