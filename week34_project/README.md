# week34_project

Librio Mobile Application (AFOD).

## 1. Getting Started

This project is a Flutter application for library borrowing, book discovery, reservations, and member management.

A few resources to get you started:
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

---

## 2. Environment & API Configuration

The API base URL is configured at compile time via Flutter's `--dart-define` mechanism in `ApiConstants.baseUrl`.

### Default API URL

If `--dart-define=API_BASE_URL=...` is not passed, the app defaults to the production endpoint:
```text
https://api.leorank.site/api
```

### Overriding the Base URL

Pass the `API_BASE_URL` environment variable during `flutter run` or `flutter build`:

#### 1. Standard run (default production URL)
```bash
flutter run
```

#### 2. Android Emulator (local backend)
Android emulator maps the host machine's `localhost` to `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

#### 3. iOS Simulator / Web / Desktop (local backend)
iOS simulator and desktop share the host network stack:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

#### 4. Physical Mobile Device (local backend via LAN)
When debugging on a physical device over Wi-Fi, use your workstation's LAN IP address:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
```

#### 5. Release / Staging Build
```bash
flutter build apk --dart-define=API_BASE_URL=https://staging.example.com/api
flutter build appbundle --dart-define=API_BASE_URL=https://api.leorank.site/api
```

> [!NOTE]
> `String.fromEnvironment` values are resolved at **compile time**. Changing `--dart-define` parameters requires a full application restart / rebuild, not a hot reload or hot restart.

---

## 3. Project Structure

```text
lib/
├── app/
│   └── router/
├── core/
│   ├── constants/
│   ├── network/
│   ├── storage/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── books/
│   ├── borrowing/
│   │   ├── borrow_return/
│   │   ├── librarian_desk/
│   │   ├── renewal/
│   │   ├── shared/
│   │   └── slip_management/
│   ├── home/
│   ├── members/
│   └── reservations/
│
└── main.dart
```

---

## 4. Folder Responsibilities

### 4.1. `app/`

Chứa cấu hình, điểm vào và điều hướng cấp ứng dụng:
- Cấu hình `MaterialApp.router`, theme và font chữ toàn cục.
- Khởi tạo các BLoC cấp ứng dụng (như `AuthBloc`).
- **`router/`**: Quản lý điều hướng tập trung (`GoRouter`) và định danh route (`route_names.dart`), tự động kiểm tra trạng thái xác thực và phân quyền màn hình theo vai trò người dùng (Member / Librarian / Admin). Các luồng chi tiết bên trong feature vẫn sử dụng `Navigator.push()` linh hoạt.

### 4.2. `core/` (Application-level Shared)

Chứa các thành phần hạ tầng và tài nguyên dùng chung trên toàn ứng dụng (không mang logic nghiệp vụ riêng của bất kỳ feature nào).

| Folder | Responsibility |
| :--- | :--- |
| `constants/` | API endpoints và các hằng số cấu hình toàn cục (`ApiConstants`) |
| `network/` | HTTP client (`DioClient`), interceptors và cấu hình kết nối API |
| `storage/` | Lưu trữ token và dữ liệu cục bộ an toàn (`TokenStorage`, `FlutterSecureStorage`) |
| `widgets/` | Widget UI hạ tầng dùng chung toàn ứng dụng (nút bấm, dialog base, toast `AppToast`, loader) |

> [!IMPORTANT]
> **Quy ước Shared cấp ứng dụng (`core/`):**
> - Chỉ đặt các thành phần Generic & Domain-agnostic (dùng chung cho mọi feature mà không phụ thuộc vào bất kỳ entity nghiệp vụ nào).
> - Không đặt logic nghiệp vụ, models hoặc state của một feature cụ thể vào `core/`.

### 4.3. `features/`

Chứa các nhóm chức năng nghiệp vụ độc lập của hệ thống.

- **`auth/` – Authentication**  
  Quản lý đăng nhập, đăng ký, khôi phục mật khẩu, phiên đăng nhập và thông tin tài khoản/hồ sơ người dùng.

- **`books/` – Book Management**  
  Quản lý danh mục sách, tìm kiếm, lọc theo thể loại, xem chi tiết sách và quét mã vạch (ISBN).

- **`borrowing/` – Borrowing Management**  
  Quản lý nghiệp vụ mượn, trả, gia hạn và xử lý phiếu mượn sách.

  | Subfolder | Responsibility |
  | :--- | :--- |
  | `borrow_return/` | Luồng cốt lõi Mượn $\rightarrow$ Trả sách (`create/`: tạo phiếu mượn; `return/`: trả sách & thanh toán phạt) |
  | `librarian_desk/` | Bàn trực thủ thư: thao tác quầy (quét barcode, tra cứu bạn đọc, tạo phiếu) và duyệt/từ chối phiếu chờ duyệt |
  | `renewal/` | Xử lý gia hạn thời hạn mượn cho phiếu mượn đủ điều kiện |
  | `slip_management/` | Quản lý danh sách, bộ lọc trạng thái và màn hình chi tiết phiếu mượn (Ticket Pass) |
  | `shared/` | Data source, repository, model, error mapper và UI helper dùng chung trong domain Borrowing |

  > [!TIP]
  > **Quy ước Shared cấp Feature (`borrowing/shared/`):**
  > - Dành riêng cho domain lớn có nhiều sub-features con chia sẻ chung thực thể (như `BorrowingSlip`, `BorrowingSlipsRepository`, `BorrowingSlipUiHelper`).
  > - Các submodules trong `borrowing/` có thể dùng chung `borrowing/shared/`, nhưng các feature độc lập bên ngoài (`auth`, `books`, `reservations`) không được phụ thuộc trực tiếp vào đây.

- **`home/` – Home & Navigation**  
  Chứa màn hình chính (Dashboard), thanh điều hướng (BottomNavigationBar) theo vai trò người dùng (Member / Librarian / Admin).

- **`members/` – Member Management**  
  Quản lý thông tin độc giả, tìm kiếm độc giả, giải quyết định danh (`resolveMemberId`) và thông tin hạn mức mượn.

- **`reservations/` – Reservation Management**  
  Quản lý độc lập toàn bộ vòng đời yêu cầu đặt trước sách khi sách tạm hết bản sao khả dụng (đặt trước, theo dõi hàng đợi, hủy đặt trước, và chuyển thành phiếu mượn khi sách sẵn sàng).

---

## 5. Internal Structure of a Feature

Các feature được tổ chức theo kiến trúc Clean Architecture / BLoC pattern và có thể sử dụng những tầng sau tùy theo nhu cầu:

```text
feature_name/
├── bloc/
│   ├── feature_bloc.dart
│   ├── feature_event.dart
│   └── feature_state.dart
│
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── errors/                          # (Tùy chọn) Ánh xạ lỗi kỹ thuật sang ngôn ngữ người dùng
│   └── feature_error_mapper.dart
│
└── presentation/
    ├── pages/
    └── widgets/
```

> [!NOTE]
> Không bắt buộc mọi feature phải có đầy đủ tất cả các folder trên. Cấu trúc thực tế được điều chỉnh linh hoạt theo độ phức tạp và trách nhiệm của từng feature.

### 5.1. Bloc (State Management)
- Tiếp nhận **Event** từ giao diện (Presentation).
- Gọi **Repository** để thực hiện nghiệp vụ và truy xuất dữ liệu.
- Phát (**Emit**) các **State** tương ứng với chu trình xử lý: `Initial`, `Loading`, `Success`, `Failure`.

### 5.2. Data
- **`datasources/`**: Giao tiếp trực tiếp với Backend API (thông qua `HttpClient`) hoặc các nguồn dữ liệu ngoại vi.
- **`models/`**: Định nghĩa cấu trúc dữ liệu, chuyển đổi JSON (`fromJson`, `toJson`) và serialize dữ liệu.
- **`repositories/`**: Khai báo abstract interface và triển khai cụ thể các thao tác truy cập dữ liệu, ánh xạ exception sang domain failure.

*Lưu ý:* Một số feature có thể đặt repository trực tiếp trong `data/` hoặc sử dụng cấu trúc dùng chung như `borrowing/shared/repositories/`. Khi thêm file mới, cần tuân theo cấu trúc hiện có của feature đó.

### 5.3. Errors (Error Mapping Layer)
- **Ánh xạ lỗi kỹ thuật sang thông báo người dùng:** Chuyển đổi các ngoại lệ thô (`DioException`, mã HTTP `400/404/409/500`, timeout mạng) và các mã lý do từ chối của Backend (`ACTIVE_RESERVATION`, `MAX_RENEWALS_REACHED`, `OVERDUE`...) thành câu thông báo tiếng Việt rõ ràng, dễ hiểu.
- **Tách biệt và dễ bảo trì:** Giúp BLoC và tầng giao diện không phụ thuộc vào cấu trúc JSON lỗi chi tiết của Backend; khi API thay đổi mã lỗi hoặc định dạng phản hồi, chỉ cần cập nhật tại file mapper tương ứng.
- **Phạm vi tổ chức:**
  - Cấp Feature nghiệp vụ con (ví dụ: `borrowing/renewal/errors/`, `reservations/errors/`): Xử lý các quy tắc từ chối đặc thù của riêng nghiệp vụ đó.
  - Cấp Shared (ví dụ: `borrowing/shared/errors/`): Xử lý các lỗi tạo phiếu, hết bản in khả dụng, lỗi chung trên toàn domain mượn trả.

### 5.4. Presentation

Chịu trách nhiệm hoàn toàn về giao diện và tương tác người dùng, chia thành 2 thư mục con theo quy ước chuẩn:

#### 1. `pages/` (Màn hình cấp trang)
- **Định dạng & Đặt tên:** Các file cấp trang thường có hậu tố `*_screen.dart` hoặc `*_page.dart` (ví dụ: `books_screen.dart`, `borrowing_slip_detail_screen.dart`).
- **Trách nhiệm:**
  - Sử dụng `Scaffold` làm khung giao diện chuẩn cho màn hình.
  - Cung cấp và lắng nghe BLoC (`BlocProvider`, `BlocListener`, `BlocConsumer`).
  - Quản lý vòng đời trang (`initState`, `dispose`), điều hướng màn hình (`Navigator`), và hiển thị thông báo (`AppToast`, SnackBar).
  - Đóng vai trò là "nhạc trưởng" lắp ráp các widget con từ `widgets/` vào bố cục tổng thể. Không viết toàn bộ mã giao diện chi tiết trong một file page.

#### 2. `widgets/` (Thành phần giao diện con)
- **Định dạng & Đặt tên:** Chứa các widget chuyên biệt, danh sách thẻ (`*_card.dart`), hộp thoại (`*_dialog.dart`), thanh thao tác (`*_action_bar.dart`) thuộc phạm vi nghiệp vụ của feature.
- **Trách nhiệm & Quy ước:**
  - Nhận dữ liệu đầu vào qua constructor arguments hoặc đọc trực tiếp trạng thái từ BLoC.
  - **Không gọi trực tiếp Repository hay API:** Mọi tương tác người dùng phải thông qua callback (`onPressed`, `onChanged`) hoặc dispatch BLoC Event (`context.read<FeatureBloc>().add(...)`).
  - **Tiêu chí tách widget:**
    1. Widget được tái sử dụng ở 2 page trở lên trong cùng một feature.
    2. Thành phần có logic hiển thị, hiệu ứng animation hoặc state giao diện độc lập.
    3. Hàm `build()` của page quá lớn cần chia nhỏ để mã nguồn sáng sủa, dễ đọc và tối ưu hóa việc re-render (rebuild subtree).
