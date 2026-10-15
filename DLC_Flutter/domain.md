# Librio Mobile — Domain Model tối giản

**Trạng thái:** Draft v1.0  
**Giới hạn:** Personal Reading Library, **không** kế thừa domain lưu thông sách giấy từ Librio Web.

## 1. Khái niệm

| Khái niệm | Ý nghĩa | Trường gợi ý |
|---|---|---|
| `Book` | Metadata của một đầu sách, từ provider hoặc fixture | `id`, `source`, `title`, `authors`, `description?`, `coverUrl?` |
| `SelectionList` | Những sách tạm chọn trước thao tác lưu nhiều sách | `bookKeys: Set<BookKey>` |
| `UserLibraryEntry` | Quan hệ giữa user và sách đã lưu | `userId`, `bookKey`, `status`, `addedAt` |
| `ReadingStatus` | Trạng thái do người dùng tự quản lý | `WANT_TO_READ`, `READING`, `FINISHED` |
| `ReadableContent` | Nội dung demo được phép sử dụng cho một sách cụ thể | `contentId`, `bookKey`, `title`, `pages/chapters`, `rightsNote` |
| `ReadingPosition` | Vị trí đọc đã lưu của nội dung demo | `userId`, `contentId`, `pageIndex`, `updatedAt` |
| `ReadingSession` | Một khoảng thời gian người dùng đọc trong reader | `sessionId`, `userId`, `contentId`, `startedAt`, `durationSeconds`, `localDate` |
| `DailyReadingGoal` | Mục tiêu đọc theo ngày của người dùng | `userId`, `targetMinutes` |

`BookKey = (source, id)` để tránh đụng ID giữa các nguồn khác nhau. Thư viện cá nhân dùng khóa duy nhất `(userId, bookKey)`.

## 2. Quan hệ và bất biến

```text
Book (metadata) 1 ── 0..1 ReadableContent (demo)
User 1 ── N UserLibraryEntry ── 1 Book
User 1 ── N ReadingSession ── 1 ReadableContent
User 1 ── N ReadingPosition ── 1 ReadableContent
User 1 ── 1 DailyReadingGoal
SelectionList ── N BookKey (tạm thời, không phải đơn hàng)
```

- Một sách lưu trong Thư viện chỉ có **một** `UserLibraryEntry` trên một user.
- `Book` chỉ có metadata không được giả định có `ReadableContent`.
- `ReadingPosition.pageIndex` nằm trong phạm vi trang của fixture tương ứng; không coi là số trang chuẩn của bản in.
- Phiên đọc chỉ cộng thời gian **active**; một `sessionId` không được tổng hợp hai lần.
- `ReadingStatus.FINISHED` do người dùng chọn; không ép hoàn thành chỉ vì đến trang cuối.
- Mỗi nội dung mẫu cần ghi được nguồn/quyền sử dụng. Không giả danh nội dung của cuốn sách thương mại khác.

## 3. Use cases cốt lõi

`SearchBooks` → `ViewBookDetail` → `AddToSelection` → `ReviewSelection` → `SaveBooksToLibrary` → `UpdateReadingStatus`.

Với nội dung sẵn có: `OpenReadableContent` → `ResumeAtSavedPosition` → `TurnPage` → `SavePosition` và `RecordActiveReadingSession` → `GetDailyReadingProgress`.

## 4. Những gì không có trong domain này

Không có `PhysicalItem`, `BorrowRequest`, `Borrowing`, `Reservation`, `Order`, `Payment`, `Entitlement` hoặc cơ chế phân phối ebook. Những khái niệm này thuộc phạm vi sản phẩm khác.
