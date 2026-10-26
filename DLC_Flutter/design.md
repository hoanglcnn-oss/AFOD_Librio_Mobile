# Librio Mobile — UX & Flow Design

**Version:** Draft v2.0  
**Status:** Partially implemented  
**Platform:** Flutter — Android-first  
**Backend:** Librobe REST API  
**References:** `product.md`, `requirements.md`, `domain.md`, `architecture.md`

---

## 1. Design Goals & Principles

### 1.1. Purpose

Tài liệu xác định cách người dùng tương tác với Librio Mobile, cấu trúc màn hình, điều hướng và thiết kế chi tiết các luồng cần triển khai.

Design không định nghĩa lại business rules của backend, không mô tả lại kiến trúc tầng dữ liệu và không thay thế API contracts.

### 1.2. Design Principles

1. **Backend-first:** Chỉ thể hiện những khả năng được backend hỗ trợ hoặc đã xác nhận.
2. **Mobile-first:** Ưu tiên thao tác một tay, bố cục gọn và dễ cuộn.
3. **Content-first:** Thông tin sách và hành động chính quan trọng hơn hiệu ứng trang trí.
4. **State-aware:** Mọi tương tác API đều có phản hồi loading, success hoặc error.
5. **Consistent navigation:** Người dùng hiểu được vị trí hiện tại và cách quay lại.
6. **Progressive complexity:** Hoàn thiện luồng cơ bản trước khi bổ sung hiệu ứng hoặc tính năng nâng cao.

### 1.3. Scope of Design

**Thiết kế trong MVP:**
- Authentication: Login, Register
- Session restoration
- Books Catalog và Search
- Book Detail
- Profile và Logout
- Navigation giữa các màn hình

**Thiết kế có điều kiện:**
- Borrowing List
- Borrowing Detail
- Create/Renew/Return Borrowing

**Không thiết kế:**
- Ebook reader
- Reading timer
- Personal reading library
- Shopping cart/checkout giả lập
- Admin Dashboard trước khi được xác nhận

---

## 2. Screen Inventory

### 2.1. MVP Screens

| ID | Screen | Purpose | Status |
|---|---|---|---|
| SCR-01 | LoginScreen | Đăng nhập | Implemented & tested |
| SCR-02 | RegisterScreen | Đăng ký | Implemented & tested |
| SCR-03 | App Entry / Session Gate | Kiểm tra phiên khi mở app | Planned |
| SCR-04 | MainScreen / Home | Điều hướng chức năng chính | Planned |
| SCR-05 | BooksScreen | Danh sách và tìm kiếm sách | Planned |
| SCR-06 | BookDetailScreen | Chi tiết sách | Planned |
| SCR-07 | ProfileScreen | Thông tin tài khoản và Logout | Planned |

`App Entry / Session Gate` là logic xác định màn khởi đầu, không bắt buộc phải có một màn SplashScreen riêng.

`MainScreen` có thể là một Scaffold chứa Books và Profile, không nhất thiết là một trang Home độc lập.

### 2.2. Conditional Screens

| ID | Screen | Purpose |
|---|---|---|
| SCR-08 | BorrowingsScreen | Danh sách phiếu mượn |
| SCR-09 | BorrowingDetailScreen | Chi tiết phiếu mượn |
| SCR-10 | BorrowConfirmation | Xác nhận giao dịch mượn |
| SCR-11 | ChangePasswordScreen | Đổi mật khẩu — P1 |

BorrowConfirmation có thể triển khai bằng dialog hoặc bottom sheet, không bắt buộc là một route riêng.

### 2.3. Proposed Main Navigation

**MVP đề xuất:**
- Sách
- Tài khoản

Khi Borrowings được xác nhận:
- Sách
- Phiếu mượn
- Tài khoản

Không cần tạo một tab Home riêng nếu Books đã là màn chính.

**Lưu ý:** Khả năng truy cập Books khi chưa đăng nhập được backend hỗ trợ, nhưng UX khởi động Login-first hay Catalog-first vẫn cần chốt.

---

## 3. Navigation Design

### 3.1. Navigation Matrix

| From | Action / Condition | To | Navigation |
|---|---|---|---|
| Login | Nhấn Đăng ký | Register | Push |
| Register | Nhấn Đăng nhập / Back | Login | Pop |
| Register | Đăng ký thành công | Login | Pop + feedback |
| Login | Đăng nhập thành công | MainScreen | Replace stack |
| App Entry | Session hợp lệ | MainScreen | Set initial destination |
| App Entry | Không có phiên hợp lệ | Login | Set initial destination |
| MainScreen | Chọn sách | BookDetail | Push |
| BookDetail | Back | BooksScreen | Pop |
| MainScreen | Chọn Tài khoản | Profile | Switch tab |
| Profile | Logout | Login | Clear authenticated navigation |
| BookDetail | Yêu cầu mượn, chưa đăng nhập | Login | Conditional |
| BookDetail | Yêu cầu mượn, đủ quyền | BorrowConfirmation | Conditional |

### 3.2. Navigation Rules

- Login và Register dùng chung AuthBloc hiện tại.
- AuthBloc được cung cấp phía trên MaterialApp.
- Đăng ký thành công hiện quay về Login.
- Sau Login thành công, không giữ Login trong back stack.
- Logout phải xóa session và loại bỏ các route yêu cầu đăng nhập.
- Book Detail chỉ cần nhận Book ID để tải dữ liệu.
- Navigation theo tab không được tự động gửi lại request không cần thiết.
- Không tạo nested Navigator hoặc thêm routing package nếu chưa cần.

### 3.3. Entry Flow

**Target flow:**

App Launch  
→ Check Stored Session  
→ Validate Session  
→ Authenticated: MainScreen  
→ Unauthenticated: LoginScreen

Trong lúc kiểm tra session:
- Hiển thị loading trung tính.
- Không chuyển nhanh Login → Home → Login gây nhấp nháy.
- Lỗi mạng cần xử lý rõ ràng; không mặc định mọi lỗi mạng đều có nghĩa token hết hạn.

**Pending decision:** Có cho phép vào Books Catalog khi chưa đăng nhập hay không.

---

## 4. Authentication Flow LLD

### 4.1. Login Interaction

**Screen:** SCR-01  
**Requirements:** FR-AUTH-02, FR-AUTH-03

**Input:**
- Email
- Password

Backend có hỗ trợ định danh bằng email hoặc số điện thoại. UI hiện chỉ hỗ trợ email; việc mở rộng input cần quyết định riêng.

**Interaction sequence:**

1. Người dùng nhập thông tin.
2. Nhấn Login.
3. Form thực hiện validation.
4. UI gửi `LoginRequested` đến AuthBloc.
5. AuthBloc chuyển sang Loading.
6. Repository gọi `POST /api/auth/login`.
7. Backend trả AuthResponse hoặc lỗi.
8. Thành công: nhận UserProfile/JWT và cập nhật session.
9. Điều hướng tới MainScreen.
10. Thất bại: hiển thị lỗi, giữ người dùng tại LoginScreen.

**UI states:**

| State | Behavior |
|---|---|
| Initial | Form sẵn sàng nhập |
| Invalid | Hiển thị lỗi tại trường tương ứng |
| Loading | Khóa Submit, hiển thị progress |
| Success | Lưu session và điều hướng |
| Authentication Error | Hiển thị sai tài khoản/mật khẩu |
| Network Error | Hiển thị lỗi kết nối và cho thử lại |

**Implementation note:**

AuthBloc hiện chỉ có `AuthSuccess(message)`. Khi bổ sung Session, cần phân biệt đăng ký thành công với phiên đã đăng nhập.

Không nên để RegisterScreen nhận một AuthSuccess do Login tạo ra rồi tự đóng route.

### 4.2. Register Interaction

**Screen:** SCR-02  
**Requirements:** FR-AUTH-01

**Input:**
- Full name
- Phone
- Email
- Password
- Confirm password

**Interaction sequence:**

1. Người dùng nhập thông tin.
2. Nhấn Register.
3. Form kiểm tra dữ liệu.
4. Gửi `RegisterRequested`.
5. AuthBloc phát Loading.
6. Repository gọi `POST /api/auth/register`.
7. Thành công: hiển thị thông báo và quay về Login.
8. Thất bại: hiển thị lỗi, giữ dữ liệu form phù hợp.

**UI rules:**
- Không gửi Confirm Password lên backend.
- Password và Confirm Password được che mặc định.
- Email và Phone được chuẩn hóa trước khi gửi.
- Nếu backend trả lỗi trùng email/số điện thoại, giữ màn Register.
- Trong lúc gửi request, không cho submit liên tục.

**Design decision hiện tại:**

Đăng ký thành công → quay về Login.

Backend trả JWT ngay khi đăng ký, nhưng app hiện chưa sử dụng token đó để đăng nhập tự động. Có thể giữ flow này để không thay đổi UI đang hoạt động, trừ khi mentor yêu cầu auto-login.

### 4.3. Shared AuthBloc & Route Listener

Vì LoginScreen và RegisterScreen dùng chung AuthBloc:

- Listener phải phân biệt thao tác thành công.
- Không để màn nằm dưới route đang mở hiển thị Snackbar không mong muốn.
- Nếu kiểm tra `ModalRoute.isCurrent`, điều kiện phải được thực hiện trước các side effects.
- Navigation chỉ chạy một lần cho một kết quả thành công.
- Nếu widget đã unmounted sau thao tác async, không dùng BuildContext để điều hướng.

Đây là phần cần kiểm tra khi refactor Authentication State.

### 4.4. Session Restore & Logout

**Restore:**

1. App đọc token cục bộ.
2. Không có token → unauthenticated.
3. Có token → gọi `GET /api/auth/me`.
4. Response hợp lệ → authenticated.
5. HTTP 401 → xóa token và chuyển unauthenticated.
6. Lỗi mạng → hiển thị trạng thái lỗi phù hợp; không tự kết luận token bị thu hồi.

**Logout:**

1. Người dùng chọn Logout.
2. Xóa token cục bộ và thông tin session trong memory.
3. Chuyển AuthBloc sang unauthenticated.
4. Điều hướng về Login hoặc entry screen đã chốt.
5. Không thể Back về màn cần đăng nhập.

Logout trên client không thu hồi JWT còn hiệu lực phía backend.

---

## 5. Books Catalog Flow LLD

### 5.1. BooksScreen

**Screen:** SCR-05  
**Requirements:** FR-BOOK-01, FR-BOOK-02, FR-BOOK-04

**Main components:**
- AppBar với tiêu đề
- Search field
- Books list
- Book item/card
- Loading/empty/error area
- Pagination hoặc nút Xem thêm

**Book item information:**
- Cover image nếu có
- Title
- Author
- Availability indicator

Không cần hiển thị toàn bộ metadata trong danh sách.

### 5.2. Initial Loading

1. Người dùng mở BooksScreen.
2. BooksBloc nhận LoadBooks.
3. Repository gọi `GET /api/books`.
4. Parse `data` và `meta`.
5. UI hiển thị danh sách hoặc trạng thái tương ứng.

**States:**

| State | UI Behavior |
|---|---|
| Initial | Bắt đầu tải danh sách |
| Loading | Hiển thị progress |
| Loaded | Hiển thị danh sách |
| Empty | Thông báo không có sách |
| Error | Thông báo và nút Thử lại |
| Loading More | Giữ danh sách, hiển thị loading cuối trang |

### 5.3. Search Interaction

**Proposed MVP behavior:** Gửi tìm kiếm khi người dùng nhấn Search hoặc submit bàn phím.

Chưa cần tìm kiếm tự động từng ký tự.

**Interaction sequence:**

1. Người dùng nhập từ khóa.
2. Submit Search.
3. Chuẩn hóa từ khóa.
4. Reset page về 1.
5. Gửi request với query `search`.
6. Cập nhật danh sách theo kết quả mới.

**Rules:**
- Xóa từ khóa và submit → tải danh sách mặc định.
- Request cũ không được ghi đè kết quả tìm kiếm mới.
- Không có kết quả → empty state, không phải API error.
- Lỗi request → giữ từ khóa để người dùng thử lại.

### 5.4. Pagination

**Proposed implementation:** Nút Xem thêm.

- Trang đầu tải mặc định.
- Mỗi lần Xem thêm tải trang tiếp theo.
- Khi `hasNextPage = false`, ẩn/vô hiệu hóa Xem thêm.
- Không gửi request tải trang tiếp khi đang loading.
- Kết quả trang mới được thêm vào danh sách hiện tại.
- Thay đổi từ khóa/bộ lọc sẽ reset pagination.

Infinite scroll là enhancement, không bắt buộc trong MVP.

### 5.5. Book Detail

**Screen:** SCR-06  
**Requirement:** FR-BOOK-03

**Navigation input:** `bookId`

**Interaction sequence:**

1. Người dùng nhấn BookCard.
2. Mở BookDetailScreen với `bookId`.
3. Repository gọi `GET /api/books/:id`.
4. Hiển thị dữ liệu sách.
5. Nếu không tìm thấy → Not Found.
6. Back về catalog.

**Information hierarchy:**

1. Cover, Title
2. Author, Category
3. Availability và số lượng còn
4. Description
5. Publisher, Published Year, Shelf Location
6. Borrow Action (chỉ khi được xác nhận)

**UI rules:**
- Không có ảnh → placeholder.
- Description dài → nội dung cuộn được.
- Không giả định Book có nội dung ebook.
- Availability lấy từ backend.
- Không tự tạo thao tác mượn khi chưa được xác nhận nghiệp vụ.

---

## 6. Borrowing Flow LLD — Conditional

Phần này là thiết kế dự kiến, chưa phải chức năng đã được phê duyệt.

### 6.1. Preconditions

Trước khi triển khai phải xác định:

- User đang đăng nhập thuộc Member nào.
- Người dùng có được thực hiện thao tác mượn/trả không.
- Backend có giới hạn quyền truy cập phiếu mượn không.
- Flow đại diện cho tự mượn sách hay nghiệp vụ xác nhận bởi thủ thư.

### 6.2. Borrow Book Flow

**Potential flow:**

BookDetail  
→ Chọn Mượn sách  
→ Kiểm tra authenticated session  
→ Xác định Member hợp lệ  
→ Hiển thị xác nhận  
→ `POST /api/borrowings`  
→ Thành công: Borrowing Detail / Confirmation  
→ Thất bại: Hiển thị lỗi nghiệp vụ

**Important rules:**
- Không dùng `user.id` thay `memberId`.
- Không cho chọn memberId tùy ý ở giao diện độc giả.
- Không coi việc nhấn nút là bằng chứng giao dịch thành công.
- Không cho gửi lặp khi đang xử lý.
- Không giả lập Borrowing thành công nếu backend từ chối.

### 6.3. Borrowing Detail

**Displayed information:**
- Transaction code
- Book title
- Borrow date
- Due date
- Status
- Renew count
- Fine amount khi có

**Conditional actions:**
- Renew
- Return

Chỉ hiển thị action phù hợp với nghiệp vụ đã được xác nhận.

### 6.4. Renew / Return

**Renew:**

1. Người dùng chọn Gia hạn.
2. Xác nhận thao tác nếu cần.
3. Gửi API Renew.
4. Thành công → cập nhật hạn trả/số lần gia hạn.
5. Thất bại → giữ dữ liệu cũ và thông báo lỗi.

**Return:**

1. Người dùng chọn Trả sách.
2. Xác nhận thao tác.
3. Gửi API Return.
4. Thành công → cập nhật phiếu mượn.
5. Thất bại → giữ trạng thái trước đó.

Không tự điều chỉnh số lượng sách hoặc tiền phạt trên client trước khi nhận kết quả backend.

---

## 7. UI/UX Design Rules

### 7.1. Visual Direction

Giữ hướng tối giản, ưu tiên nội dung.

Cấu hình ThemeData hiện tại trong `app.dart` là nền tảng được ưu tiên tái sử dụng.

Không cần thiết kế lại toàn bộ Authentication UI đang hoạt động.

**Existing elements:**
- Material 3
- Manrope typography
- InputDecorationTheme
- Primary button style
- Màu nền và màu hành động đã được thiết lập

Chỉ bổ sung hoặc chuẩn hóa style khi có vấn đề thực tế về nhất quán.

### 7.2. Responsive Layout

**Phone (dưới 600 dp):**
- Form bố trí theo chiều dọc.
- Nội dung ưu tiên phía trên.
- Có thể cuộn khi keyboard mở.

**Tablet / wider layout (từ 600 dp):**
- Form giới hạn chiều rộng.
- Nội dung có thể căn giữa.
- Không kéo giãn trường nhập hết màn hình.

**Testing sizes:**
- 360×800 dp
- 390×844 dp
- 800+ dp
- Keyboard open
- Text scaling 150%

**Layout rules:**
- Tránh Row gây overflow bởi text dài.
- Ưu tiên Wrap/Flexible khi cần.
- Nội dung dài phải được cuộn hoặc xử lý hợp lý.
- Form không bị che hoàn toàn khi bàn phím mở.

### 7.3. Feedback & Error Presentation

**Form validation:**
- Lỗi nhập liệu hiển thị gần TextFormField.
- Giữ nguyên dữ liệu đã nhập khi submit thất bại.

**Network/API errors:**
- Snackbar cho thông báo thao tác ngắn.
- Empty/Error state trong nội dung cho màn hình tải dữ liệu.
- Có Retry khi phù hợp.

**Loading:**
- Khóa hành động thay đổi dữ liệu trong lúc gửi request.
- Đối với danh sách, loading không được làm mất dữ liệu hiện tại một cách không cần thiết.

**Success:**
- Chỉ hiển thị sau response backend thành công.
- Không điều hướng trước khi hoàn tất request.

### 7.4. Accessibility & Usability

- Text đủ tương phản.
- Nút có vùng chạm phù hợp.
- Icon không rõ nghĩa cần tooltip/label.
- Không phụ thuộc duy nhất vào màu để truyền đạt trạng thái.
- Có phản hồi khi thao tác bị vô hiệu hóa.
- Hỗ trợ keyboard và text scaling ở mức MVP.

---

## 8. Design Validation Checklist

### Authentication

- [x] Login/Register chuyển qua lại.
- [x] Register/Login tích hợp API thật.
- [x] 4 test case cơ bản PASS.
- [x] ProviderNotFoundException đã được xử lý.
- [ ] Phân biệt LoginSuccess và RegisterSuccess khi bổ sung session.
- [ ] Khôi phục session sau restart.
- [ ] Logout điều hướng đúng.

### Books

- [ ] Danh sách hiển thị dữ liệu backend.
- [ ] Search đúng từ khóa.
- [ ] Empty/Error/Loading đầy đủ.
- [ ] Phân trang hoạt động.
- [ ] Mở đúng BookDetail.
- [ ] Trường thiếu ảnh/mô tả không làm crash.

### Borrowings

- [ ] Xác nhận người dùng và quyền thao tác.
- [ ] Xác định cách lấy memberId hợp lệ.
- [ ] Chốt Borrow/Return/Renew Flow.
- [ ] Bổ sung test case trước khi triển khai.

### Responsive

- [ ] Kiểm tra thiết bị nhỏ.
- [ ] Kiểm tra tablet.
- [ ] Kiểm tra bàn phím mở.
- [ ] Kiểm tra text scaling.
- [ ] Không có overflow hoặc điều hướng sai trong luồng demo.

---

## 9. Design Decisions & Limitations

| Decision | Selected direction |
|---|---|
| Design style | Minimal, content-first |
| Navigation | Flutter Navigator hiện có |
| Forms | Giữ UI đã triển khai |
| Session entry | Kiểm tra phiên trước khi chọn màn |
| Main navigation | Books + Profile, thêm Borrowings khi được duyệt |
| Search | Explicit submit |
| Pagination | Xem thêm |
| Book Detail | Tải theo Book ID |
| Borrowing flow | Chưa triển khai khi chưa rõ quyền |
| Wireframe | Chỉ bổ sung khi cần thay đổi layout đáng kể |
| Animation | Không ưu tiên trong MVP |

Các lựa chọn trên là phương án thiết kế đề xuất. Những quyết định còn phụ thuộc mentor được ghi tập trung trong Decision Register bên dưới.

---

## 10. Centralized Decision Register

Bảng dưới đây tổng hợp các câu hỏi còn tồn đọng từ cả năm tài liệu.

| ID | Question | Source | Priority |
|---|---|---|---|
| DEC-01 | Mobile dành cho MEMBER, LIBRARIAN hay cả hai? | Product, Domain | Critical |
| DEC-02 | Mini-project bắt buộc có những nghiệp vụ nào khi demo? | Product, Requirements | Critical |
| DEC-03 | Các tiêu chí cart/quantity/checkout của đề mẫu có bắt buộc không? | Product, Requirements | High |
| DEC-04 | Backend kiểm soát authorization cho Books/Borrowings ra sao? | Requirements, Architecture | Critical |
| DEC-05 | Mobile lấy memberId từ tài khoản đăng nhập bằng cách nào? | Domain, Architecture | Critical nếu làm Borrowings |
| DEC-06 | Borrow/Return/Renew là thao tác của độc giả hay thủ thư? | Domain, Design | Critical nếu làm Borrowings |
| DEC-07 | App bắt đầu bằng Login hay Books Catalog? | Product, Design | Medium |
| DEC-08 | Register thành công tự đăng nhập hay quay về Login? | Architecture, Design | Low |
| DEC-09 | Login UI có cần hỗ trợ số điện thoại không? | Requirements, Design | Low |
| DEC-10 | Có bắt buộc dùng Mock API ngoài backend thật không? | Product cũ, Requirements | High |
| DEC-11 | Android là nền tảng nghiệm thu duy nhất hay cần Web/Desktop? | Product, Architecture | Medium |
| DEC-12 | Có cần chức năng Admin/Staff trong MVP không? | Product, Requirements | High |
| DEC-13 | UI hiện tại có cần áp dụng lại toàn bộ style từ Stitch không? | Design | Low |
| DEC-14 | Deadline và tiêu chí đánh giá cuối cùng của mentor là gì? | Product, Requirements | Critical |

### Decision status

Tất cả câu hỏi chưa được mentor xác nhận vẫn có trạng thái **Open**.

Không sử dụng giả định trong thiết kế để tuyên bố rằng backend đã hỗ trợ đầy đủ phân quyền, member mapping hoặc những nghiệp vụ ngoài phạm vi xác minh.

---

## 11. Design Maintenance

Khi phạm vi thay đổi:

1. Cập nhật Product nếu thay đổi người dùng hoặc chức năng.
2. Cập nhật Requirements nếu thay đổi tiêu chí nghiệm thu.
3. Cập nhật Domain nếu thay đổi nghiệp vụ.
4. Cập nhật Architecture nếu thay đổi cấu trúc kỹ thuật.
5. Cập nhật Design nếu thay đổi màn hình, điều hướng hoặc tương tác.

Không bắt buộc tạo wireframe cho mọi màn hình.

Chỉ tạo tài liệu LLD riêng trong `design/` khi flow đủ phức tạp để cần đặc tả sâu hơn, ví dụ:
- Session restoration
- Borrowing authorization
- Multi-step transaction

**Design completion criterion:** Các luồng P0 được mô tả đủ rõ để triển khai và kiểm thử mà không phải tự suy đoán nghiệp vụ.
