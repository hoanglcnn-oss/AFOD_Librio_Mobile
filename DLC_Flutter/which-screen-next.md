# Sprint 2 — Mobile-first Experience

## Mục tiêu

Biến Librio thành ứng dụng điện thoại thực sự, tận dụng khả năng của thiết bị và hệ điều hành thay vì chỉ chuyển các chức năng quản lý thư viện lên màn hình nhỏ.

Ưu tiên phát triển phía Flutter, tái sử dụng backend/API hiện có. Không tự mở rộng backend nếu chưa được yêu cầu.

## Phạm vi chức năng

**P0 — Core Sprint**

1. **Enhanced ISBN Scanner:** Flash, chuyển camera, chống quét trùng, haptic feedback, xử lý camera permission và lifecycle.
2. **Mobile UX:** Pull-to-refresh, swipe actions, bottom sheet, skeleton loading. Chỉ áp dụng ở những màn hình thực sự phù hợp.
3. **Digital Library Card:** Thẻ thư viện điện tử, QR và thông tin độc giả. Cần xác minh QR có thể được backend/hệ thống thư viện sử dụng để xác thực hay chỉ để hiển thị.
4. **Local Notifications:** Nhắc hạn trả trước 3 ngày, 1 ngày và khi gần đến hạn. Đồng bộ lại lịch nhắc khi dữ liệu mượn/trả thay đổi.
5. **Offline Book Cache:** Lưu thông tin sách để xem offline ở chế độ read-only, có cơ chế nhận biết dữ liệu cũ.

**P1 — Bổ sung nếu phù hợp**

6. **Device Calendar Integration:** Cho phép thêm hạn trả vào lịch điện thoại.
7. **Recent Searches:** Lưu và sử dụng lại từ khóa tìm sách gần đây.

**P2 — Backlog**

8. **Batch ISBN Scanner:** Quét nhiều ISBN liên tục, không tự động tạo giao dịch mượn sách.
9. **Citation Generator:** Tạo trích dẫn học thuật từ metadata của sách.
10. **Voice Search:** Tìm sách bằng giọng nói tiếng Việt.

Rapid Checkout nằm ngoài phạm vi Sprint 2 cho đến khi xác minh được nghiệp vụ, mã định danh bản sao sách và API tương ứng.

## Quy tắc làm việc với codebase

- Ưu tiên đọc và hiểu code hiện tại trước khi đề xuất thay đổi.
- Phân biệt rõ chức năng đã có, đang có một phần và chưa có.
- Tận dụng architecture, BLoC, routing và dependencies hiện tại khi phù hợp.
- Không tự refactor lớn, thay đổi kiến trúc, thêm package hoặc sửa backend khi chưa được duyệt.
- Ưu tiên thay đổi nhỏ, có thể kiểm thử và hoàn tác.
- Không tự giả định business rules của thư viện.
- Với những tính năng sử dụng camera, notification, storage hoặc quyền hệ điều hành, phải xét cả permission, lifecycle, error handling và khả năng chạy trên thiết bị thật.

## Quy trình cho từng tính năng

**Bước 1 — Analysis**

1. Xác định luồng chức năng hiện tại.
2. Liệt kê file, class, BLoC, service và dependency liên quan.
3. Đối chiếu yêu cầu mới với code hiện có.
4. Xác định thay đổi tối thiểu cần thực hiện.
5. Chỉ ra rủi ro, edge cases và những điểm phụ thuộc backend.
6. Đề xuất implementation plan cùng tiêu chí nghiệm thu.

**Bước 2 — Implementation**

Chỉ triển khai khi phương án đã được duyệt. Giữ phạm vi đúng tính năng đang làm, tránh mở rộng sang các phần khác.

**Bước 3 — Verification**

Kiểm tra luồng hoạt động, error states, regression và những trường hợp cần test trên thiết bị thật.

## Tính năng bắt đầu

Enhanced ISBN Scanner (P0).

Trước tiên chỉ phân tích hiện trạng và đề xuất phương án triển khai. Chưa chỉnh sửa source code.

## 💡 Features "Bay Bổng" — Vượt ra ngoài Sprint 2 cơ bản

Sprint 2 hiện tại nghiêng về **infrastructure mobile** (scanner, notification, offline). Dưới đây là những ý tưởng mang tính **trải nghiệm người dùng** và **giá trị thư viện thực sự**:

### 🏆 Tier 1 — Thực tế & Có thể làm ngay với backend hiện tại

**1. 📊 Reading Stats Dashboard**
- Thống kê cá nhân: số sách đã đọc theo tháng/năm, thể loại yêu thích, tốc độ đọc trung bình
- Streak đọc sách (giống Duolingo) — "Bạn đã mượn sách 4 tuần liên tiếp!"
- Toàn bộ tính từ data `borrowing-slips` đã có, **không cần API mới**
- Visualize bằng `fl_chart` — chart dạng heatmap hoặc bar chart theo tháng

**2. 🔍 Smart Book Discovery (Related Books)**
- Khi xem chi tiết 1 cuốn sách → gợi ý "Sách cùng tác giả", "Cùng thể loại", "Người mượn sách này cũng mượn..."
- Phần "cùng tác giả/thể loại" → query từ API books hiện có (filter by `author`, `category`)
- Phần "collaborative filtering" → tính từ borrowing history, chạy client-side

**3. 📱 Book Sharing / Social**
- Nút "Chia sẻ sách" → tạo deep link / share card đẹp (book cover + title + "Mượn tại thư viện X")
- Dùng `share_plus` package — chia sẻ qua Zalo, Messenger, etc.
- Không cần backend, chỉ cần metadata sách đã có

### 🎨 Tier 2 — Sáng tạo & Tạo khác biệt

**4. 🎯 Reading Challenges / Mục tiêu đọc sách**
- User đặt mục tiêu: "Đọc 20 cuốn trong năm 2027"
- Progress ring animation, celebration khi đạt milestone (confetti 🎉)
- Lưu local (`shared_preferences` hoặc `hive`), không cần API
- Gamification nhẹ: badges cho "Đọc 5 cuốn văn học", "Mượn 3 tuần liên tiếp không quá hạn"

**5. 📸 Book Shelf / Tủ sách cá nhân**
- Visual grid hiển thị tất cả sách đã từng mượn, dạng book spine hoặc cover gallery
- Swipe qua từng cuốn với animation 3D flip
- Thêm ghi chú cá nhân, đánh giá ⭐ (lưu local)
- Aesthetic kiểu Goodreads nhưng tối giản hơn

**6. 🗺️ Library Map / Bản đồ thư viện**
- Khi xem sách → hiện vị trí trên sơ đồ thư viện (kệ nào, tầng nào)
- Dùng `CustomPainter` vẽ floor plan đơn giản
- Data vị trí có thể hardcode hoặc map từ `callNumber` / `category`

### 🌟 Tier 3 — Thực sự "Bay bổng"

**7. 🤖 AI Book Companion (Gemini API)**
- Chat về cuốn sách đang mượn: "Tóm tắt chương 3 cho mình", "Sách này nói về gì?"
- Dùng Gemini API (free tier) + metadata sách
- Không phải toàn bộ nội dung sách, mà là **trợ lý học tập** từ thông tin công khai

**8. 📖 AR Book Preview**
- Quét bìa sách bằng camera → hiện overlay thông tin: rating, tình trạng còn/hết, nút mượn nhanh
- Dùng `google_ml_kit` (text recognition trên bìa) → match với database
- Như "Shazam cho sách" — đưa camera vào kệ sách là biết ngay thông tin

**9. 🌙 Reading Mode / Dark Library**
- Không chỉ dark theme — mà là **ambiance mode** khi đang đọc sách
- Warm tones, giảm blue light, timer đọc sách, nhạc nền lo-fi tùy chọn
- Widget "Đang đọc" trên Home Screen (Android widget / iOS Live Activity)

---
