# Librio Mobile — Kiến trúc triển khai MVP

**Trạng thái:** Draft v1.0  
**Mục đích:** Gợi ý ranh giới kỹ thuật đủ triển khai trong mini-project, chưa khóa framework/state package.

## 1. Data flow

```text
Flutter UI (3 tabs + detail/selection/reader)
  ↓
Features / application logic
  ├── CatalogRepository ── HTTP (Dio hoặc tương đương) ── Google Books API
  ├── LibraryRepository ── local storage (và Mock API nếu cần cho tiêu chí DOFA)
  ├── DemoContentRepository ── bundled JSON/text fixtures có quyền sử dụng
  └── ReadingRepository ── persisted position, sessions, daily goal
```

## 2. Ranh giới quan trọng

- Catalog data từ Google Books chỉ chứa **metadata**. `imageLinks` có thể trống; không có nghĩa có văn bản ebook.
- **Demo content** đóng gói local; chỉ gắn với bookKey được định nghĩa trong fixture rõ ràng. Nội dung được tự viết hoặc có quyền sử dụng, không tạo nội dung giả cho sách thật.
- **User library** và **reading progress** là dữ liệu của ứng dụng. MVP lưu cục bộ làm nguồn trạng thái cần duy trì. Nếu mentor yêu cầu Mock API cho create/update, định nghĩa adapter minh họa riêng, tránh nói đã đồng bộ server nếu chưa có.
- Mọi cập nhật một batch sách cần deduplicate và báo lỗi mà không xóa danh sách chọn khi thất bại.

## 3. Reader đơn giản

Fixture có `contentId`, `bookKey`, các trang `pages[]` được biên tập trước; có thể nhóm theo chương. UI hiển thị một trang mỗi lần và điều hướng trước/sau; lưu `pageIndex` theo `contentId` + user.

**Hạn chế chấp nhận:** `pageIndex` là chỉ số của nội dung demo, không tự dàn trang EPUB/PDF theo kích thước màn hình. Nếu nội dung dài trên thiết bị nhỏ, trang có thể cuộn nội bộ. Không triển khai parser ở MVP.

## 4. Reading timer và lifecycle

- Bắt đầu/tái tiếp tục tính giờ khi reader hiển thị và app đang foreground (`resumed`).
- Dừng/flush thời lượng khi rời reader hoặc app `inactive`/`paused`/`hidden`; không chạy timer cộng tích lũy chỉ dựa vào callback giao diện.
- Ghi nhận bằng **thời gian trôi qua monotonic** khi phiên active (ví dụ Stopwatch); UI có thể refresh số giây hiển thị định kỳ. Persist tổng thời gian an toàn khi kết thúc/tạm dừng phiên.
- Phân bổ thời gian theo **ngày địa phương**; với phiên qua nửa đêm, tách đúng ngày hoặc kết thúc và mở phiên mới tại ranh giới ngày. Không double-count session khi resume/retry.
- Khi app bị hệ điều hành kill mà không có callback, có thể mất phần thời gian chưa flush; ưu tiên checkpoint định kỳ nếu cần. Tuyệt đối không suy ra thời gian đã đọc từ khoảng thời gian app bị đóng.

## 5. Điều hướng và tổ chức code

- Cấp 1: `LibraryTab`, `DiscoverTab`, `AccountTab` (giữ bottom nav).
- Cấp 2: `BookDetail`, `Selection`, `ConfirmSave`, `Reader`, `Auth` (ẩn bottom nav).
- Gợi ý chia theo feature: `catalog`, `library`, `reader`, `reading_goal`, `auth`, `shared`.
- Trạng thái mạng/data riêng với trạng thái UI; mỗi feature hiển thị loading, empty, success và error hợp lý.

## 6. Chưa khóa

Gói state management (GetX/BLoC/Riverpod), local database/preferences cụ thể, shape Mock API, kiến trúc final và test tooling sẽ quyết định sau khi học Flutter Core và thống nhất mentor.
