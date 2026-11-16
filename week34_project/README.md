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
│   │   ├── create_slip/
│   │   ├── pay_slip_fine/
│   │   ├── pending_slips/
│   │   ├── renewal/
│   │   ├── return_slip/
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

Chứa cấu hình và khởi tạo ứng dụng:
- Cấu hình `MaterialApp`, theme và font chữ.
- Khởi tạo các Bloc cấp ứng dụng (như `AuthBloc`).
- Kiểm tra trạng thái xác thực và điều hướng đến màn hình phù hợp.

### 4.2. `core/`

Chứa các thành phần hạ tầng dùng chung trên toàn ứng dụng.

| Folder | Responsibility |
| :--- | :--- |
| `constants/` | API endpoints và các hằng số cấu hình toàn cục |
| `network/` | HTTP client, interceptors và cấu hình kết nối API |
| `storage/` | Lưu trữ token và dữ liệu cục bộ (SecureStorage, SharedPreferences) |
| `widgets/` | Widget hạ tầng dùng chung toàn ứng dụng (nút bấm, dialog base, toast, loader) |

> [!IMPORTANT]
> Không đặt logic nghiệp vụ riêng của một feature vào `core/`.

### 4.3. `features/`

Chứa các nhóm chức năng nghiệp vụ độc lập của hệ thống.

- **`auth/` – Authentication**  
  Quản lý đăng nhập, đăng ký, khôi phục mật khẩu, phiên đăng nhập và thông tin tài khoản/hồ sơ người dùng.

- **`books/` – Book Management**  
  Quản lý danh mục sách, tìm kiếm, lọc theo thể loại, xem chi tiết sách và quét mã vạch (ISBN).

- **`borrowing/` – Borrowing Management**  
  Quản lý toàn bộ nghiệp vụ liên quan đến mượn trả sách, phiếu mượn và đặt trước sách.

  | Subfolder | Responsibility |
  | :--- | :--- |
  | `create_slip/` | Tạo yêu cầu hoặc phiếu mượn sách mới (bao gồm kiểm tra hạn mức & nợ phạt) |
  | `pay_slip_fine/` | Xử lý thanh toán tiền phạt trễ hạn hoặc làm hư hỏng/mất sách |
  | `pending_slips/` | Hiển thị và xử lý duyệt / từ chối phiếu mượn chờ xử lý (dành cho thủ thư) |
  | `renewal/` | Xử lý gia hạn thời hạn mượn cho phiếu mượn đủ điều kiện |
  | `return_slip/` | Xử lý nghiệp vụ trả sách, ghi nhận hư hỏng/mất và tính tiền phạt |
  | `slip_management/` | Quản lý danh sách, bộ lọc trạng thái và màn hình chi tiết phiếu mượn (Ticket Pass) |
  | `shared/` | Data source, repository, model, error mapper và UI helper dùng chung trong domain Borrowing |

  > [!TIP]
  > **Quy ước:** Các nghiệp vụ con được tổ chức độc lập khi có luồng xử lý riêng. Những thành phần thực sự được nhiều nghiệp vụ Borrowing sử dụng chung mới đặt trong `borrowing/shared/`.

- **`home/` – Home & Navigation**  
  Chứa màn hình chính (Dashboard), thanh điều hướng (BottomNavigationBar) theo vai trò người dùng (Member / Librarian / Admin).

- **`members/` – Member Management**  
  Quản lý thông tin độc giả, tìm kiếm độc giả và các dữ liệu liên quan đến tài khoản độc giả.

- **`reservations/` – Reservation Management**  
  Quản lý toàn bộ yêu cầu đặt trước sách khi sách tạm hết bản sao khả dụng (đặt trước, theo dõi hàng đợi, hủy đặt trước, và chuyển thành phiếu mượn khi sách sẵn sàng).

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
- **`pages/`**: Các màn hình cấp trang (Scaffold screens), quản lý vòng đời và cung cấp BLoC qua `BlocProvider`.
- **`widgets/`**: Các thành phần giao diện nhỏ, tái sử dụng nội bộ thuộc phạm vi của feature đó.
