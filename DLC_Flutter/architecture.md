# Librio Mobile — Software Architecture

**Version:** Draft v2.0  
**Status:** Partially implemented  
**Platform:** Flutter / Dart — Android-first  
**Backend:** Librobe REST API  
**Architecture style:** Feature-first, BLoC, Repository Pattern  
**References:** `product.md`, `requirements.md`, `domain.md`

---

## 1. Architecture Overview

### 1.1. Mục tiêu

Librio Mobile là ứng dụng Flutter sử dụng REST API do Librobe backend cung cấp.

Ứng dụng chịu trách nhiệm hiển thị giao diện, quản lý trạng thái, điều hướng, duy trì phiên và giao tiếp với backend.

Không xây dựng lại business logic hoặc database của Librobe trên mobile.

Kiến trúc cần đáp ứng:

- Tái sử dụng code Flutter hiện có.
- Tách UI, state management và API access.
- Phù hợp mini-project với thời gian triển khai giới hạn.
- Dễ bổ sung Books và Borrowings.
- Hỗ trợ kiểm thử từng thành phần độc lập.
- Tránh các abstraction chưa cần thiết.

### 1.2. Architecture Style

Sử dụng **Feature-first + BLoC + Repository**.

```text
Flutter Application
│
├── Presentation
│   └── Screens / Widgets
│
├── State Management
│   └── BLoC / Events / States
│
├── Data Access
│   ├── Repositories
│   └── Response Models
│
└── Core Infrastructure
    ├── Dio HTTP Client
    ├── API Constants
    └── Token Storage
          │
          ▼
    Librobe REST API
          │
          ▼
    Backend Services / Database
```

**Dependency direction:**

`UI → BLoC → Repository → Dio → Backend`

Các dependency đi từ giao diện xuống tầng truy cập dữ liệu.

Widget không gọi HTTP request trực tiếp.

### 1.3. Source of Truth

| Data | Source of truth |
|---|---|
| User account | Backend |
| Member profile | Backend |
| Book catalog | Backend |
| Book inventory | Backend |
| Borrowing status | Backend |
| Authentication token validity | Backend |
| Locally stored token | Mobile storage |
| Navigation / UI state | Flutter |
| Search input / selected tab | Flutter |

Flutter có thể giữ bản dữ liệu đã tải trong memory, nhưng không được coi bản sao này là dữ liệu chính thức khi backend có thể thay đổi.

---

## 2. System Context & Boundaries

### 2.1. System Components

**Flutter Mobile Client**

Cung cấp màn hình đăng nhập, đăng ký, catalog, chi tiết sách, tài khoản và các nghiệp vụ bổ sung được chấp thuận.

**Librobe Backend**

Cung cấp API cho xác thực, truy xuất dữ liệu, kiểm tra điều kiện nghiệp vụ và lưu trữ.

**Backend Database**

Được quản lý bởi Librobe. Flutter không kết nối trực tiếp đến database.

### 2.2. Responsibility Boundaries

| Concern | Flutter | Backend |
|---|---|---|
| Form validation | Kiểm tra đầu vào để cải thiện UX | Validation cuối cùng |
| Authentication | Gửi credentials, lưu session | Xác thực và cấp JWT |
| Authorization | Điều chỉnh UI theo vai trò | Bắt buộc kiểm tra quyền truy cập |
| Book searching | Thu thập từ khóa, hiển thị kết quả | Tìm kiếm và phân trang |
| Book availability | Hiển thị trạng thái | Quản lý tồn kho |
| Borrowing | Gửi thao tác và hiển thị kết quả | Kiểm tra điều kiện, tạo/cập nhật phiếu |
| Error handling | Thông báo và recovery UI | Trả HTTP status và error response |

### 2.3. Security Boundary

Không coi việc ẩn nút hoặc kiểm tra vai trò trong Flutter là cơ chế bảo mật.

Các thao tác thay đổi dữ liệu phải được backend kiểm soát quyền.

**Backend dependency hiện tại:**

Auth `GET /auth/me` và `POST /auth/change-password` có sử dụng JWT guard.

Tuy nhiên, code controller Books/Borrowings hiện chưa thể hiện đầy đủ cơ chế guard và role authorization cho các nghiệp vụ tương ứng.

Vì vậy, Borrowings và các chức năng quản trị phải được xác minh về phân quyền trước khi trở thành tính năng chính thức dành cho người dùng.

---

## 3. Flutter Component Architecture

### 3.1. Presentation Layer

Bao gồm:

- Screens
- Reusable widgets
- Forms
- Navigation
- Hiển thị loading, success, error và empty states

**Responsibilities:**

- Thu thập input.
- Validate các điều kiện cơ bản.
- Gửi event tới BLoC.
- Render giao diện theo state.
- Thực hiện navigation và UI feedback.

Không thực hiện HTTP request trực tiếp trong Widget.

### 3.2. State Management Layer

Sử dụng `flutter_bloc`.

BLoC quản lý các thao tác bất đồng bộ và chuyển đổi trạng thái giao diện.

**AuthBloc:**
- LoginRequested
- RegisterRequested
- RestoreSessionRequested (planned)
- LogoutRequested (planned)

**BooksBloc (planned):**
- LoadBooks
- SearchBooks
- LoadNextPage

Các event/state cụ thể được xác định khi triển khai từng feature.

Không cần tạo một BLoC cho mọi widget. State đơn giản như hiện/ẩn mật khẩu hoặc điều khiển text field vẫn có thể dùng `StatefulWidget`.

### 3.3. Repository Layer

Repository đóng vai trò giao tiếp với nguồn dữ liệu.

**AuthRepository:**
- Login
- Register
- Get current user
- Session-related operations

**BooksRepository:**
- Get books
- Search books
- Get book detail

**BorrowingsRepository (conditional):**
- Get borrowings
- Get borrowing detail
- Create borrowing
- Return / Renew

Repository nhận request, gọi API và chuyển response thành model được ứng dụng sử dụng.

Không tạo repository generic hoặc hệ thống abstraction phức tạp khi chưa có nhu cầu.

### 3.4. Data Models

Các model phản ánh API response, không sao chép toàn bộ backend entity.

**P0:**
- AuthResponse
- UserProfile
- Book
- PaginatedResponse / BooksPage

**Conditional:**
- Borrowing
- BorrowingStatus
- Borrow request DTO

Chỉ tạo model cho dữ liệu thực sự sử dụng trong ứng dụng.

---

## 4. Project Structure

### 4.1. Current Structure

Cấu trúc hiện tại:

```text
week34_project/lib/
├── main.dart
├── app/
│   └── app.dart
├── core/
│   ├── constants/
│   │   └── api_constants.dart
│   └── network/
│       └── dio_client.dart
├── features/
│   └── auth/
│       ├── bloc/
│       │   ├── auth_bloc.dart
│       │   ├── auth_event.dart
│       │   └── auth_state.dart
│       ├── data/
│       │   ├── auth_repository.dart
│       │   ├── api_auth_repository.dart
│       │   └── fake_auth_repository.dart
│       └── presentation/
│           ├── login_screen.dart
│           └── register_screen.dart
└── shared/
    └── widgets/
```

Đây là cấu trúc đã được thiết lập và sử dụng trong Authentication.

### 4.2. Target MVP Structure

```text
week34_project/lib/
├── main.dart
│
├── app/
│   └── app.dart
│
├── core/
│   ├── constants/
│   │   └── api_constants.dart
│   ├── network/
│   │   └── dio_client.dart
│   └── storage/
│       └── token_storage.dart         [planned]
│
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── auth_response.dart [planned]
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── profile_screen.dart    [planned]
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart       [planned]
│   │
│   └── books/
│       ├── bloc/                      [planned]
│       ├── data/                      [planned]
│       └── presentation/              [planned]
│
└── shared/
    └── widgets/
```

Nếu Borrowings được chấp thuận, bổ sung:

```text
features/
└── borrowings/
    ├── bloc/
    ├── data/
    └── presentation/
```

Không cần tạo sẵn thư mục hoặc file chưa sử dụng.

---

## 5. Integration Architecture

### 5.1. HTTP Client

Sử dụng `dio`.

Base URL:

`https://api.leorank.site/api`

DioClient hiện có:

- Base URL dùng chung.
- Connect timeout 10 giây.
- Receive timeout 10 giây.
- JSON headers.

**Target additions:**

- Gắn Bearer JWT vào request cần xác thực.
- Chuẩn hóa xử lý lỗi Dio tại repository hoặc helper nhỏ dùng chung nếu thực sự cần.
- Không ghi log token/password.

Không cần xây API client framework riêng.

### 5.2. API Response Handling

Backend sử dụng nhiều response shapes.

**Authentication:**

Response thành công có các trường:

- `accessToken`
- `tokenType`
- `expiresIn`
- `user`

**Paginated data:**

Danh sách sách và phiếu mượn sử dụng cấu trúc:

- `data`: danh sách items
- `meta`: page, limit, totalItems, totalPages, hasNextPage, hasPreviousPage

**Error response:**

Backend exception filter trả:

- `statusCode`
- `error`
- `message`
- `timestamp`
- `path`
- `method`

`message` có thể là chuỗi hoặc danh sách thông báo validation.

Không giả định mọi response đều nằm trong một wrapper giống nhau.

### 5.3. Error Handling Strategy

Các trường hợp cần hỗ trợ:

| Error | Client behavior |
|---|---|
| 400 | Hiển thị lỗi dữ liệu/nghiệp vụ |
| 401 | Xử lý lỗi xác thực; nếu phiên bị từ chối thì yêu cầu đăng nhập lại |
| 403 | Thông báo không có quyền truy cập |
| 404 | Hiển thị Not Found |
| 409 | Hiển thị Conflict |
| 500+ | Hiển thị lỗi server |
| Timeout / connection error | Thông báo kết nối và hỗ trợ Retry phù hợp |

Không gửi lại tự động các request tạo hoặc thay đổi dữ liệu khi chưa có cơ chế chống thực hiện trùng.

---

## 6. Authentication & Session Architecture

### 6.1. Current Implementation

Đã triển khai:

- Login/Register UI
- AuthBloc
- ApiAuthRepository
- DioClient
- Auth loading/success/failure

Đã kiểm thử thành công bốn trường hợp Authentication cơ bản.

**Giới hạn hiện tại:** AuthRepository vẫn dùng `Future<void>`, chưa giữ lại token và thông tin user.

### 6.2. Target Authentication Flow

```text
LoginScreen
   │
   ▼
LoginRequested
   │
   ▼
AuthBloc
   │
   ▼
AuthRepository
   │
   ▼
POST /api/auth/login
   │
   ▼
AuthResponse
   │
   ├── Parse UserProfile
   └── Save JWT
          │
          ▼
Authenticated State
          │
          ▼
HomeScreen
```

LoginScreen không tự parse JWT.

Repository hoặc thành phần phụ trách session tiếp nhận response và lưu thông tin cần thiết.

### 6.3. Session Persistence

**Proposed storage:** `flutter_secure_storage` cho Android.

Session flow:

1. Login thành công.
2. Parse AuthResponse.
3. Lưu token an toàn.
4. Khi khởi động app, kiểm tra token đã lưu.
5. Nếu có token, gọi `/auth/me` để xác minh.
6. Nếu hợp lệ, sử dụng thông tin người dùng từ backend.
7. Nếu không hợp lệ, xóa phiên và hiển thị trạng thái chưa đăng nhập.

Không cần refresh token vì backend hiện chưa cung cấp endpoint tương ứng.

Lưu ý: nếu triển khai Flutter Web, cần đánh giá riêng cơ chế lưu trữ và bảo mật session, không mặc định giống Android.

### 6.4. Logout

Logout trên Flutter:

1. Xóa token cục bộ.
2. Xóa dữ liệu tài khoản/session đang giữ trong memory.
3. Chuyển trạng thái sang unauthenticated.
4. Điều hướng về LoginScreen theo requirements hiện tại.
5. Không cho quay lại màn đã đăng nhập bằng Back.

Đây là local logout, không phải thu hồi JWT phía server.

### 6.5. Authentication State Design

AuthBloc hiện có các state:

- AuthInitial
- AuthLoading
- AuthSuccess
- AuthFailure

Khi bổ sung session, cần phân biệt rõ:

- Đăng ký thành công.
- Đăng nhập thành công.
- Phiên đã được xác thực.
- Không có phiên hợp lệ.
- Lỗi xác thực.

**Proposed adjustment:** Bổ sung state hoặc thông tin kết quả đủ để phân biệt loại thao tác, thay vì mọi trường hợp đều dùng `AuthSuccess(message)`.

Giữ một AuthBloc cho authentication ở giai đoạn hiện tại; chưa cần xây hệ thống quản lý session độc lập nhiều tầng.

---

## 7. Navigation Architecture

### 7.1. Navigation Approach

Tiếp tục sử dụng Flutter Navigator.

Không cần thêm GoRouter tại MVP hiện tại.

**Main destinations:**
- Login
- Register
- Home / Books
- Book Detail
- Profile
- Borrowings (conditional)

### 7.2. Authentication Scope

AuthBloc được cung cấp phía trên `MaterialApp`.

Cách này cho phép các màn Login/Register và các route sau này dùng chung trạng thái Authentication.

BooksBloc chỉ cần được tạo trong phạm vi Books khi bắt đầu triển khai catalog.

Không tạo tất cả feature BLoC ở app root.

### 7.3. Navigation Rules

- Login ↔ Register hoạt động như hiện tại.
- Sau Login thành công, chuyển Home và không giữ Login trong back stack.
- Phiên hợp lệ khi khởi động có thể vào Home.
- Sau Logout, trở về Login theo requirements.
- Book Detail nhận Book ID và tải dữ liệu chi tiết theo ID.
- Catalog là tài nguyên công khai; có thể bổ sung hành động xem sách không cần đăng nhập từ Login.
- Các thao tác yêu cầu xác thực phải kiểm tra trạng thái phiên.

Việc cho khách truy cập Books Catalog không đồng nghĩa được thực hiện Borrowings.

---

## 8. Books Architecture

### 8.1. Data Flow

```text
BooksScreen
    │
    ▼
BooksBloc
    │
    ▼
BooksRepository
    │
    ▼
DioClient
    │
    ▼
GET /api/books
    │
    ▼
Paginated Books Response
    │
    ▼
BooksState
    │
    ▼
BooksScreen
```

### 8.2. Search & Pagination

Search sử dụng query parameter `search`.

Pagination sử dụng `page`, `limit` và metadata backend.

**Client behavior:**
- Reset page khi từ khóa thay đổi.
- Không cho request kết quả cũ ghi đè kết quả mới.
- Không tải trang tiếp nếu `hasNextPage = false`.
- Hiển thị trạng thái loading/empty/error.

Không cần infinite scroll ở phiên bản đầu. Có thể dùng nút "Xem thêm".

### 8.3. Book Detail

BookDetailScreen nhận `bookId`.

Repository gọi `GET /api/books/:id`.

Các thông tin cần thiết được chuyển thành Book model.

Không cần tạo một BookDetailBloc riêng nếu thao tác chỉ là tải dữ liệu một lần và chưa có state phức tạp. Có thể dùng FutureBuilder gọi qua Repository hoặc tái sử dụng BLoC phù hợp.

---

## 9. Borrowings Architecture — Deferred

Backend cung cấp các thao tác:

- Danh sách phiếu mượn
- Chi tiết phiếu
- Tạo phiếu
- Trả sách
- Gia hạn
- Thanh toán phạt

Tuy nhiên, mobile chưa được phép mặc định triển khai mọi thao tác.

### Dependencies

Cần xác nhận:

1. Lấy `memberId` từ tài khoản đã đăng nhập bằng cách nào.
2. API giới hạn dữ liệu theo user/member ra sao.
3. Vai trò MEMBER được thực hiện những hành động nào.
4. Các thao tác thay đổi phiếu đã được kiểm soát quyền trên backend chưa.

**Architectural decision:**

Không triển khai BorrowingsRepository, BorrowingsBloc và màn hình nghiệp vụ trước khi xác minh các điều kiện trên.

Khi được chấp thuận, sử dụng lại cùng kiến trúc Presentation → BLoC → Repository → Dio.

Không tạo một subsystem riêng.

---

## 10. Dependency Management

### Current Packages

| Package | Purpose |
|---|---|
| flutter_bloc | State management |
| dio | HTTP client |
| equatable | State/event equality |
| google_fonts | Typography |

### Planned Package

| Package | Purpose |
|---|---|
| flutter_secure_storage | JWT persistence trên nền tảng hỗ trợ |

### Dependency Injection

Tạm thời sử dụng constructor injection và BlocProvider/RepositoryProvider khi cần.

Ví dụ:

- Dio được cấp cho ApiAuthRepository.
- ApiAuthRepository được cấp cho AuthBloc.
- AuthBloc được cấp cho widget subtree qua BlocProvider.

Không yêu cầu `get_it`, `injectable` hay service locator ở MVP.

GetX không được đưa vào kiến trúc hiện tại vì BLoC đã đáp ứng nhu cầu state management.

---

## 11. Testing Architecture

### 11.1. Unit Tests

Ưu tiên:

- Parse AuthResponse
- Parse Book/Book pagination
- AuthBloc state transitions
- BooksBloc loading/success/error
- Session restore/logout

Repository nên cho phép truyền Dio hoặc fake dependency để kiểm thử độc lập.

### 11.2. Widget Tests

Kiểm tra:

- Form validation
- Loading và disable button
- Lỗi API hiển thị trên UI
- Books empty/error states
- Navigation giữa các màn quan trọng

### 11.3. Integration / Manual Tests

Kiểm tra với backend thật:

- Register/Login
- JWT restore
- Logout
- Books List/Search/Detail
- Borrowings nếu được triển khai

Không sử dụng dữ liệu cá nhân thật hoặc tài khoản người khác khi test.

### 11.4. Quality Checks

Chạy:

- `flutter analyze`
- `flutter test`
- Manual responsive test

Các màn quan trọng cần được kiểm tra ở kích thước điện thoại nhỏ và màn hình rộng.

---

## 12. Runtime & Deployment

### 12.1. Flutter Runtime

**Target:** Android-first.

Flutter Web/Desktop có thể sử dụng để debug trong quá trình phát triển, nhưng không mặc định là nền tảng nghiệm thu chính.

### 12.2. Backend Integration

Backend được deploy độc lập tại:

`https://api.leorank.site`

Swagger:

`https://api.leorank.site/api/docs`

Flutter giao tiếp qua HTTPS.

Không cần chạy NestJS và database bên trong dự án Flutter.

### 12.3. Configuration

MVP sử dụng `ApiConstants` cho base URL và endpoints.

Khi cần chuyển đổi giữa local/staging/production, có thể sử dụng `--dart-define` thay vì hard-code nhiều môi trường.

Không đưa thông tin bí mật vào source code hoặc tài liệu.

### 12.4. Build & Delivery

Development:
- Flutter SDK
- Dart SDK
- Android SDK / Emulator hoặc thiết bị thực
- Backend API có thể truy cập

Delivery:
- Source code GitHub
- README hướng dẫn chạy
- Danh sách chức năng đã hoàn thành
- Test results
- Android debug build/APK nếu mentor yêu cầu

Chưa cần CI/CD pipeline hoặc tự động triển khai lên Google Play.

---

## 13. Architecture Decisions

| Decision | Rationale | Consequence |
|---|---|---|
| Feature-first | Tách tính năng dễ quản lý | Thêm module khi cần |
| BLoC | Đã triển khai và phù hợp đào tạo | Duy trì một state management chính |
| Repository Pattern | Tách API khỏi UI | Có thể test độc lập |
| Shared DioClient | Tái sử dụng cấu hình HTTP | Không tạo client trùng lặp |
| Navigator | Đủ cho số màn MVP | Có thể đổi router về sau |
| Secure token storage | Hỗ trợ khôi phục phiên Android | Thêm dependency và test lifecycle |
| Backend as source of truth | Tránh lệch dữ liệu nghiệp vụ | Client phải xử lý loading và error |
| No separate mobile DB | Backend đã quản lý dữ liệu | Không có offline-first ở MVP |
| Borrowings deferred | Chưa xác minh quyền và member mapping | Không cam kết flow chưa an toàn |

---

## 14. Architecture Evolution

### Stage A — Completed

- Flutter project setup
- Login/Register UI
- DioClient
- AuthRepository
- ApiAuthRepository
- AuthBloc
- Basic API integration

### Stage B — Next

- AuthResponse model
- JWT storage
- Restore session
- Logout
- Home/Profile

### Stage C — Planned

- Book model
- BooksRepository
- BooksBloc
- BooksScreen
- Search/Pagination
- Book Detail

### Stage D — Conditional

- Member identity mapping
- BorrowingsRepository
- Borrowings UI
- Borrow/Return/Renew flows

### Stage E — Finalization

- Integration testing
- UI/UX responsive review
- Bug fixes
- README and demo preparation

---

## 15. Explicitly Out of Scope

Không triển khai trong MVP:

- Clean Architecture đầy đủ với domain use cases cho từng action.
- Microservices trong Flutter.
- Flutter-side database riêng.
- Offline-first synchronization.
- Service locator hoặc DI code generation.
- Kết hợp nhiều state management framework không cần thiết.
- Custom HTTP abstraction thay Dio.
- Refresh token flow khi backend chưa cung cấp.
- Admin module khi chưa được yêu cầu và chưa xác minh authorization.
- CI/CD production phức tạp.

**Architecture principle:** Chỉ mở rộng kiến trúc khi chức năng thực tế cần đến nó, không tạo sẵn cấu trúc chỉ để dự đoán tương lai.
