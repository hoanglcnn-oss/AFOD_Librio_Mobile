# Librio Mobile — Software Requirements Specification

**Version:** Draft v1.0  
**Status:** In progress  
**Product reference:** `product.md`  
**Platform:** Flutter — Android-first  
**Backend:** Librobe REST API  
**Scope:** Mobile client adaptation of the existing Librobe backend

---

## 1. Purpose & Scope

Tài liệu xác định các yêu cầu chức năng (Functional Requirements), quy tắc nghiệp vụ (Business Rules) và yêu cầu phi chức năng (Non-functional Requirements) cho Librio Mobile.

Librio Mobile sử dụng REST API của Librobe để cung cấp trải nghiệm quản lý thư viện trên thiết bị di động.

### Requirement priority

| Priority | Meaning |
|---|---|
| P0 | Bắt buộc trong MVP |
| P1 | Bổ sung sau khi P0 ổn định |
| P2 | Chức năng mở rộng |
| Conditional | Phụ thuộc xác nhận nghiệp vụ hoặc backend |

### Requirement status

- **Verified:** Đã triển khai và kiểm thử đạt.
- **Implemented:** Đã code, chưa hoàn tất kiểm thử.
- **Planned:** Chưa triển khai.
- **Blocked:** Đang chờ điều kiện hoặc quyết định bên ngoài.

---

## 2. Functional Requirements

### 2.1. Authentication

#### FR-AUTH-01 — Đăng ký tài khoản

**Priority:** P0  
**Status:** Verified  
**API:** `POST /api/auth/register`

Ứng dụng phải cho phép người dùng tạo tài khoản bằng họ tên, email, số điện thoại và mật khẩu.

**Acceptance Criteria:**

- AC01: Người dùng nhập được họ tên, email, số điện thoại, mật khẩu và xác nhận mật khẩu.
- AC02: Form kiểm tra trường bắt buộc, định dạng email, số điện thoại và xác nhận mật khẩu.
- AC03: Dữ liệu hợp lệ được gửi đến Register API.
- AC04: Backend trả thành công → hiển thị thông báo và quay về LoginScreen.
- AC05: Email hoặc số điện thoại trùng → hiển thị lỗi, không đóng màn hình.
- AC06: Khi đang gửi request, nút Submit bị vô hiệu hóa.
- AC07: Không hiển thị hoặc ghi log mật khẩu người dùng.

**Verified cases:** Đăng ký thành công và đăng ký email trùng đã PASS.

#### FR-AUTH-02 — Đăng nhập

**Priority:** P0  
**Status:** Verified  
**API:** `POST /api/auth/login`

Ứng dụng phải cho phép người dùng đăng nhập bằng tài khoản hợp lệ.

**Acceptance Criteria:**

- AC01: Người dùng nhập được thông tin tài khoản và mật khẩu.
- AC02: Form không gửi request khi dữ liệu bắt buộc bị thiếu.
- AC03: Dữ liệu được gửi đến Login API.
- AC04: Thông tin hợp lệ → nhận response thành công.
- AC05: Sai tài khoản hoặc mật khẩu → hiển thị lỗi phù hợp.
- AC06: Trong lúc xử lý, giao diện hiển thị loading và ngăn submit lặp.
- AC07: Không làm mất khả năng chuyển sang RegisterScreen.

**Verified cases:** Đăng nhập thành công và sai mật khẩu đã PASS.

**Ghi chú:** Hiện LoginScreen ưu tiên nhập email. Backend còn hỗ trợ số điện thoại, có thể bổ sung khi hoàn thiện Authentication.

#### FR-AUTH-03 — Quản lý phiên đăng nhập

**Priority:** P0  
**Status:** Planned  
**API:** `POST /api/auth/login`, `GET /api/auth/me`

Ứng dụng phải quản lý phiên dựa trên JWT do backend cung cấp.

**Acceptance Criteria:**

- AC01: Parse được `accessToken`, `tokenType`, `expiresIn` và `user` từ Auth API.
- AC02: Token được lưu bằng cơ chế phù hợp với nền tảng.
- AC03: Request yêu cầu xác thực gửi Bearer token.
- AC04: Khi khởi động lại, ứng dụng kiểm tra phiên đã lưu.
- AC05: Phiên hợp lệ → người dùng được đưa đến màn hình phù hợp.
- AC06: Token không hợp lệ/hết hạn → yêu cầu đăng nhập lại.
- AC07: Không đưa token vào logs hoặc repository Git.

#### FR-AUTH-04 — Đăng xuất

**Priority:** P0  
**Status:** Planned

Ứng dụng phải cho phép người dùng kết thúc phiên đăng nhập trên thiết bị.

**Acceptance Criteria:**

- AC01: Có thao tác Logout từ giao diện tài khoản.
- AC02: Logout xóa token đã lưu.
- AC03: Người dùng được chuyển về LoginScreen.
- AC04: Không thể quay lại màn yêu cầu đăng nhập bằng nút Back.
- AC05: Mở lại ứng dụng sau Logout không tự khôi phục phiên cũ.

**Lưu ý:** Backend hiện không cung cấp endpoint Logout riêng; thao tác Logout của MVP diễn ra trên client.

#### FR-AUTH-05 — Thông tin tài khoản

**Priority:** P0  
**Status:** Planned  
**API:** `GET /api/auth/me`

**Acceptance Criteria:**

- AC01: Profile hiển thị tên và email người dùng.
- AC02: Thông tin được lấy từ phiên/backend, không hard-code.
- AC03: Request không hợp lệ được xử lý phù hợp.
- AC04: Không hiển thị các thông tin nhạy cảm như password hoặc JWT.

#### FR-AUTH-06 — Đổi mật khẩu

**Priority:** P1  
**Status:** Planned  
**API:** `POST /api/auth/change-password`

**Acceptance Criteria:**

- AC01: Người dùng nhập mật khẩu hiện tại và mật khẩu mới.
- AC02: Form validate dữ liệu trước khi gửi.
- AC03: Thành công có phản hồi rõ ràng.
- AC04: Mật khẩu hiện tại sai hoặc mật khẩu mới không hợp lệ được thông báo.
- AC05: Không ghi log mật khẩu.

---

### 2.2. Books Catalog

#### FR-BOOK-01 — Danh sách sách

**Priority:** P0  
**Status:** Planned  
**API:** `GET /api/books`

Ứng dụng phải hiển thị danh sách sách từ backend.

**Acceptance Criteria:**

- AC01: Khi mở BooksScreen, ứng dụng tải danh sách sách.
- AC02: Mỗi mục hiển thị ít nhất tên sách và thông tin phân biệt phù hợp từ API.
- AC03: Danh sách dùng dữ liệu backend, không dùng dữ liệu hard-code để giả lập chức năng.
- AC04: Có giao diện loading, empty và error.
- AC05: Danh sách có thể cuộn trên màn hình nhỏ.
- AC06: Có thể thử tải lại khi request thất bại.

#### FR-BOOK-02 — Tìm kiếm sách

**Priority:** P0  
**Status:** Planned  
**API:** `GET /api/books?search=...`

**Acceptance Criteria:**

- AC01: Người dùng nhập được từ khóa tìm kiếm.
- AC02: Request gửi đúng tham số `search`.
- AC03: Kết quả hiển thị theo response backend.
- AC04: Từ khóa không có kết quả → hiển thị trạng thái rỗng.
- AC05: Xóa từ khóa → danh sách được tải lại.
- AC06: Không để kết quả của request cũ ghi đè kết quả tìm kiếm mới hơn.

#### FR-BOOK-03 — Chi tiết sách

**Priority:** P0  
**Status:** Planned  
**API:** `GET /api/books/:id`

**Acceptance Criteria:**

- AC01: Chọn một sách mở đúng BookDetailScreen.
- AC02: Thông tin chi tiết lấy theo ID của sách.
- AC03: Hiển thị thông tin cơ bản, tác giả, thể loại và số lượng có sẵn khi backend cung cấp.
- AC04: Trường dữ liệu thiếu được xử lý bằng fallback phù hợp.
- AC05: Sách không tồn tại → hiển thị lỗi Not Found.
- AC06: Người dùng có thể quay lại danh sách.

#### FR-BOOK-04 — Phân trang

**Priority:** P0  
**Status:** Planned  
**API:** `GET /api/books?page=...&limit=...`

**Acceptance Criteria:**

- AC01: Ứng dụng đọc được thông tin phân trang từ backend.
- AC02: Người dùng có thể xem các trang tiếp theo.
- AC03: Chuyển trang không hiển thị trùng dữ liệu do client.
- AC04: Khi tìm kiếm hoặc thay đổi bộ lọc, phân trang được reset phù hợp.
- AC05: Không tiếp tục tải trang khi đã hết dữ liệu.

**Implementation note:** Có thể dùng nút "Xem thêm" trước, chưa bắt buộc infinite scroll.

#### FR-BOOK-05 — Bộ lọc sách

**Priority:** P1  
**Status:** Planned

**Acceptance Criteria:**

- AC01: Có thể lọc theo tiêu chí được backend hỗ trợ.
- AC02: Query parameters tương ứng được gửi đúng.
- AC03: Kết quả lọc phản ánh dữ liệu backend.
- AC04: Có thể xóa bộ lọc và quay về danh sách mặc định.

#### FR-BOOK-06 — Tra cứu ISBN

**Priority:** P1  
**Status:** Planned  
**API:** `GET /api/books/isbn/:isbn`

**Acceptance Criteria:**

- AC01: Cho phép nhập ISBN để tra cứu.
- AC02: ISBN hợp lệ được gửi tới endpoint.
- AC03: Tìm thấy → hiển thị đúng sách.
- AC04: Không tìm thấy → hiển thị thông báo.

---

### 2.3. Navigation & User Experience

#### FR-NAV-01 — Điều hướng Authentication

**Priority:** P0  
**Status:** Verified

**Acceptance Criteria:**

- AC01: LoginScreen chuyển được tới RegisterScreen.
- AC02: RegisterScreen quay được về LoginScreen.
- AC03: Không xảy ra ProviderNotFoundException khi điều hướng.
- AC04: Không tạo các màn Login/Register trùng lặp không cần thiết.

#### FR-NAV-02 — Điều hướng theo phiên

**Priority:** P0  
**Status:** Planned

**Acceptance Criteria:**

- AC01: Phiên hợp lệ → truy cập được màn chính.
- AC02: Phiên không hợp lệ → có thể đăng nhập.
- AC03: Người dùng chưa đăng nhập vẫn xem được catalog công khai nếu flow sản phẩm cho phép.
- AC04: Những thao tác yêu cầu đăng nhập phải có xử lý phù hợp.
- AC05: Logout đưa ứng dụng về trạng thái chưa xác thực.

#### FR-NAV-03 — Trạng thái giao diện

**Priority:** P0  
**Status:** Implemented (Authentication), Planned (Books)

**Acceptance Criteria:**

- AC01: Request đang xử lý → hiển thị loading.
- AC02: Thành công → hiển thị dữ liệu hoặc phản hồi kết quả.
- AC03: Thất bại → có thông báo phù hợp.
- AC04: Không có dữ liệu → có empty state.
- AC05: Không crash khi gặp lỗi API thông thường.

---

### 2.4. Borrowings — Conditional Requirements

Các yêu cầu trong phần này chỉ trở thành bắt buộc sau khi xác nhận đối tượng sử dụng và quyền truy cập dữ liệu.

#### FR-BRW-01 — Xem danh sách phiếu mượn

**Priority:** Conditional  
**Status:** Blocked — Business/authorization confirmation  
**API:** `GET /api/borrowings`

**Acceptance Criteria:**

- AC01: Hiển thị danh sách phiếu mượn trong phạm vi người dùng được phép.
- AC02: Mỗi phiếu có tên sách, trạng thái, ngày mượn và hạn trả.
- AC03: Có thể lọc theo trạng thái.
- AC04: Xử lý loading, empty và error.
- AC05: Không truy cập trái phép phiếu mượn của người dùng khác.

#### FR-BRW-02 — Chi tiết phiếu mượn

**Priority:** Conditional  
**Status:** Blocked  
**API:** `GET /api/borrowings/:id`

**Acceptance Criteria:**

- AC01: Hiển thị thông tin phiếu mượn theo ID.
- AC02: Hiển thị ngày mượn, hạn trả, trạng thái và số lần gia hạn.
- AC03: Phiếu không tồn tại → hiển thị Not Found.
- AC04: Chỉ truy cập dữ liệu trong phạm vi được phép.

#### FR-BRW-03 — Mượn sách

**Priority:** Conditional  
**Status:** Blocked  
**API:** `POST /api/borrowings`

**Acceptance Criteria:**

- AC01: Người dùng chọn sách từ catalog.
- AC02: Hệ thống xác định đúng độc giả liên kết với tài khoản.
- AC03: Request gửi đúng dữ liệu theo API contract.
- AC04: Backend chấp nhận → hiển thị kết quả tạo phiếu.
- AC05: Backend từ chối do hết sách, thẻ hết hạn hoặc vượt hạn mức → hiển thị lý do phù hợp.
- AC06: Không gửi trùng giao dịch khi loading.
- AC07: Dữ liệu sách và phiếu mượn được cập nhật sau thành công.

#### FR-BRW-04 — Trả sách

**Priority:** Conditional  
**Status:** Blocked  
**API:** `POST /api/borrowings/:id/return`

**Acceptance Criteria:**

- AC01: Chỉ hiển thị thao tác khi nghiệp vụ cho phép.
- AC02: Thực hiện request đúng ID phiếu.
- AC03: Thành công → cập nhật trạng thái và thông tin trả.
- AC04: Phiếu đã trả → không cho thực hiện lặp.
- AC05: Có xác nhận trước thao tác thay đổi dữ liệu.

#### FR-BRW-05 — Gia hạn

**Priority:** Conditional  
**Status:** Blocked  
**API:** `POST /api/borrowings/:id/renew`

**Acceptance Criteria:**

- AC01: Hiển thị hạn trả hiện tại và số lần gia hạn.
- AC02: Gửi yêu cầu gia hạn đúng API contract.
- AC03: Thành công → cập nhật hạn trả mới.
- AC04: Phiếu quá hạn hoặc hết lượt gia hạn → hiển thị lỗi backend.
- AC05: Không cho submit liên tục.

---

## 3. Business Rules

Business rules được lấy từ backend Librobe. Flutter phải phản ánh các quy tắc này trong UI, nhưng backend là nơi quyết định cuối cùng.

### BR-AUTH

| ID | Rule |
|---|---|
| BR-AUTH-01 | Email và số điện thoại đăng ký phải duy nhất. |
| BR-AUTH-02 | Số điện thoại đăng ký phải có định dạng hợp lệ theo backend. |
| BR-AUTH-03 | Mật khẩu phải đáp ứng giới hạn độ dài theo API contract. |
| BR-AUTH-04 | Đăng ký mặc định tạo tài khoản vai trò MEMBER nếu không chỉ định role. |
| BR-AUTH-05 | JWT do backend cấp có thời hạn hiệu lực. |
| BR-AUTH-06 | Flutter không được xem việc lưu token là bằng chứng phiên còn hợp lệ; phải xử lý token hết hạn hoặc bị từ chối. |
| BR-AUTH-07 | Đăng xuất trên client xóa token cục bộ; không đồng nghĩa thu hồi JWT phía server. |

### BR-BOOK

| ID | Rule |
|---|---|
| BR-BOOK-01 | Book ID là khóa nhận diện sách khi truy cập chi tiết. |
| BR-BOOK-02 | ISBN dùng cho tra cứu sách theo chuẩn backend. |
| BR-BOOK-03 | Tình trạng tồn kho và số lượng bản còn lấy từ backend. |
| BR-BOOK-04 | Flutter không tự điều chỉnh tồn kho khi chưa có kết quả giao dịch hợp lệ. |
| BR-BOOK-05 | Kết quả tìm kiếm và phân trang tuân theo dữ liệu backend. |

### BR-BRW

| ID | Rule |
|---|---|
| BR-BRW-01 | Độc giả phải có thẻ hợp lệ để mượn sách. |
| BR-BRW-02 | Không được mượn sách khi vượt hạn mức hoặc còn sách quá hạn theo quy tắc backend. |
| BR-BRW-03 | Sách phải có bản còn sẵn và chưa ngừng lưu hành. |
| BR-BRW-04 | Một giao dịch mượn thành công tạo phiếu mượn và giảm tồn kho. |
| BR-BRW-05 | Trả sách hợp lệ cập nhật phiếu và hoàn tồn kho. |
| BR-BRW-06 | Gia hạn phụ thuộc trạng thái phiếu và giới hạn số lần. |
| BR-BRW-07 | Các thao tác mượn/trả/gia hạn phải được kiểm soát quyền phía backend, không chỉ ẩn nút trên Flutter. |

---

## 4. Non-functional Requirements

### NFR-01 — Responsive & Usability

- Android-first.
- Nội dung không overflow ở chiều rộng thiết bị nhỏ.
- Form có thể cuộn khi bàn phím mở.
- Các thao tác chính dễ nhận biết.
- Ưu tiên bố cục đơn giản, nhất quán giữa các màn.

**Verification:** Kiểm tra ít nhất các kích thước 360×800 dp, 390×844 dp và một màn hình rộng từ 800 dp trở lên.

### NFR-02 — Reliability

- Request thất bại không khiến ứng dụng crash.
- Có xử lý lỗi kết nối và timeout.
- Các thao tác thay đổi dữ liệu không bị submit liên tục.
- Có cơ chế thử lại cho những request đọc dữ liệu phù hợp.
- UI không hiển thị trạng thái thành công trước khi API xác nhận.

### NFR-03 — Security

- Không hard-code tài khoản hoặc token thật.
- Không commit credentials lên GitHub.
- Không ghi log mật khẩu hoặc JWT.
- Token được lưu theo cơ chế phù hợp với nền tảng.
- Không coi validation trên Flutter là thay thế cho validation của backend.
- Không sử dụng dữ liệu hoặc quyền của tài khoản khác trái phép.

### NFR-04 — Maintainability

- Phân tách presentation, state management và data access.
- Tái sử dụng DioClient và các thành phần chung.
- Không gọi API trực tiếp từ widget khi đã có Repository.
- Không tạo architecture abstraction không cần thiết.
- Code dễ đọc và dễ kiểm thử.

### NFR-05 — Performance

- Không block giao diện khi gọi API.
- Danh sách lớn được giới hạn bằng phân trang.
- Không tự gửi request tìm kiếm cho mỗi ký tự theo cách gây quá tải không cần thiết.
- Chỉ tải dữ liệu cần thiết cho màn hình hiện tại.

### NFR-06 — Testability

- `flutter analyze` không phát sinh lỗi mới từ phần code triển khai.
- Mỗi chức năng P0 có test case thành công và thất bại.
- Có kiểm tra API error, empty state và điều hướng.
- Những kết quả PASS phải dựa trên thử nghiệm thực tế, không chỉ dựa trên code đã viết.

### NFR-07 — Documentation & Delivery

- README mô tả cách chạy app.
- Nêu rõ backend URL và cấu hình cần thiết.
- Các thay đổi quan trọng được commit.
- Tài liệu phản ánh đúng trạng thái chức năng.
- Demo sử dụng dữ liệu hợp lệ và có thể lặp lại.

---

## 5. Requirement Traceability

| Capability | Requirements | API / Component | Status |
|---|---|---|---|
| Registration | FR-AUTH-01 | Register API + AuthBloc | Verified |
| Login | FR-AUTH-02 | Login API + AuthBloc | Verified |
| Session | FR-AUTH-03 | JWT + `/auth/me` | Planned |
| Logout | FR-AUTH-04 | Local session | Planned |
| Profile | FR-AUTH-05 | `/auth/me` | Planned |
| Books List | FR-BOOK-01 | `/books` | Planned |
| Book Search | FR-BOOK-02 | `/books?search=` | Planned |
| Book Detail | FR-BOOK-03 | `/books/:id` | Planned |
| Pagination | FR-BOOK-04 | `/books?page=` | Planned |
| Mobile Navigation | FR-NAV-01/02 | Flutter Navigator | Partial |
| Borrowing Flow | FR-BRW-01–05 | `/borrowings` | Blocked |

---

## 6. MVP Acceptance Gate

MVP chỉ được đánh dấu hoàn thành khi tất cả yêu cầu P0 đạt nghiệm thu.

### Gate A — Authentication

- [x] Register thành công.
- [x] Login thành công.
- [x] Login sai mật khẩu.
- [x] Register email trùng.
- [ ] Parse JWT và thông tin user.
- [ ] Khôi phục phiên.
- [ ] Logout thành công.
- [ ] Profile hiển thị đúng dữ liệu.

### Gate B — Books

- [ ] Lấy danh sách thật từ backend.
- [ ] Hiển thị đầy đủ loading/empty/error.
- [ ] Tìm kiếm sách.
- [ ] Phân trang.
- [ ] Xem chi tiết.
- [ ] Xử lý lỗi Not Found.

### Gate C — Navigation & Quality

- [ ] Điều hướng Home/Books/Profile đúng.
- [ ] Không overflow tại các kích thước kiểm thử.
- [ ] Không có exception nghiêm trọng trong luồng demo.
- [ ] README và hướng dẫn chạy được cập nhật.
- [ ] Có commit/PR cho các phần hoàn thành.

### Gate D — Borrowings (Conditional)

Chỉ kích hoạt khi được xác nhận là phạm vi MVP.

- [ ] Xác định đúng member gắn với tài khoản.
- [ ] Backend kiểm soát quyền truy cập phiếu mượn.
- [ ] Xem danh sách và chi tiết phiếu.
- [ ] Mượn sách thành công và thất bại theo quy tắc.
- [ ] Trả/gia hạn theo phạm vi được duyệt.

---

## 7. Open Issues & Dependencies

| ID | Issue | Impact |
|---|---|---|
| OI-01 | Cần xác nhận mobile chủ yếu phục vụ MEMBER hay STAFF | Quyết định scope Borrowings và Admin |
| OI-02 | Xác định quan hệ giữa Auth User và Member ID được Flutter sử dụng | Ảnh hưởng tạo/lọc phiếu mượn |
| OI-03 | Xác minh cơ chế authorization cho Borrowings trên backend | Ảnh hưởng bảo mật và khả năng triển khai |
| OI-04 | Xác định yêu cầu demo bắt buộc từ mentor | Quyết định P0/P1 và deadline |

Các vấn đề đang mở không ngăn cản triển khai Session hoặc Books Catalog.

---

## 8. Change Control

Khi yêu cầu thay đổi:

1. Cập nhật `product.md` nếu thay đổi phạm vi sản phẩm.
2. Cập nhật FR/BR/NFR và tiêu chí nghiệm thu trong file này.
3. Cập nhật `domain.md` nếu có thay đổi mô hình nghiệp vụ.
4. Cập nhật `architecture.md` khi thay đổi giải pháp kỹ thuật.
5. Cập nhật tài liệu `design/` khi thay đổi flow hoặc tương tác màn hình.

Không đánh dấu Verified trước khi thực hiện kiểm thử tương ứng.
