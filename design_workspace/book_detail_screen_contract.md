# BookDetailScreen — UI & Behavior Contract

**Platform:** Flutter Mobile (Android-first)  
**Target Viewport:** 390×844 logical pixels  
**Source Source of Truth:** `lib/features/books/presentation/pages/books_detail_screen.dart`  
**Dialog Component:** `lib/features/books/presentation/widgets/book_reserve_dialog.dart`  
**Test Suite Reference:** `test/book_detail_reservation_test.dart`  
**Design System Reference:** Academic Clarity (`#0F172A` Navy / `#0D9488` Teal / `#F8FAFC` Slate)  

---

## 1. Screen Overview & Architecture

`BookDetailScreen` presents the bibliographic details, real-time availability/quota status, and circulation actions for a single book.

### State & Dependency Flow
- **Data Source:** `BooksRepository.getBookById(bookId)` returns a `Future<Book>`.
- **Session/Auth:** `AuthBloc` (checks `AuthAuthenticated`, `user.role == 'MEMBER'`).
- **Member Resolution:** `MemberResolver.resolve(memberId, email, role)` obtains the reader's unique `memberId`.
- **Reservation Lifecycle:** `ReservationsBloc` manages `CreateReservationRequested` and emits `ReservationCreating`, `ReservationCreateSuccess`, or `ReservationCreateFailure`.
- **Navigation Input:** `bookId` (`String`).

---

## 2. Displayed Fields & Data Bindings

| UI Element | Source Field | Type / Binding | Null / Fallback Handling |
|---|---|---|---|
| **Top AppBar Title** | Static string | `'Chi tiết sách'` | Always present |
| **Book Cover Image** | `book.coverUrl` | `String?` (Network Image, `BoxFit.contain`, height 220) | If null, empty, or fails to load, display `Icon(Icons.menu_book, size: 80)` |
| **Book Title** | `book.title` | `String` (`headlineSmall`) | Render as-is (multi-line supported) |
| **Author** | `book.authorName` | `'Tác giả: ${book.authorName}'` | Render as-is |
| **Category** | `book.categoryName` | `'Thể loại: ${book.categoryName}'` | Render as-is |
| **ISBN** | `book.isbn` | `'ISBN: ${book.isbn}'` | Render as-is |
| **Availability Status** | `book.canBorrow`, `book.copiesAvailable`, `book.copiesTotal` | Dynamic: If `canBorrow`: `'Còn ${book.copiesAvailable} / ${book.copiesTotal} cuốn'` (Color: Green shade 700). If not: `'Hiện không thể mượn (đã hết bản khả dụng)'` (Color: `errorScheme`) | `canBorrow` is computed as `copiesAvailable > 0 && (status == 'AVAILABLE' || status == 'LOW_STOCK')` |
| **Description Section Header** | Static string | `'Mô tả'` (`titleLarge`) | Always present |
| **Description Body** | `book.description` | `String` | If empty: `'Chưa có mô tả'`, else full text |

---

## 3. Interactive Buttons & Actions

The screen features **exactly two primary action buttons** positioned side-by-side in a bottom row:

### A. "Đặt trước" (Reserve Book)
- **Widget:** `OutlinedButton.icon`
- **Key:** `ValueKey('reserve_book_button')`
- **Default State:** Label `'Đặt trước'`, Icon `Icons.bookmark_add_outlined`, enabled.
- **In-Flight State (`isReserving`):** Label `'Đang xử lý...'`, Icon replaced with 16×16 `CircularProgressIndicator(strokeWidth: 2)`, disabled (`onPressed: null`).
- **Availability Decoupling:** Even when `book.canBorrow == false` (all copies borrowed), **"Đặt trước" remains ENABLED** so members can place reservations on checked-out books.

### B. "Mượn sách" (Borrow Book)
- **Widget:** `FilledButton`
- **Key:** `ValueKey('borrow_book_button')`
- **Default State:** Label `'Mượn sách'`.
- **Enabled Condition:** `book.canBorrow == true`.
- **Disabled Condition:** `!book.canBorrow` (`onPressed: null`).

---

## 4. Business Validation & Workflow Rules

### 4.1 Reservation Trigger Flow (`_onReserveBook`)
1. **Authentication Check:**
   - If `authState is! AuthAuthenticated`: Show warning toast:  
     `'Vui lòng đăng nhập để đặt trước sách'` (Does NOT open dialog).
2. **Role Check:**
   - If `user.role != 'MEMBER'`: Show warning toast:  
     `'Chỉ độc giả mới có thể đặt trước sách'` (Librarians/Admins cannot reserve via reader UI).
3. **Member Profile Resolution:**
   - Invokes `MemberResolver.resolve(...)`. If null or empty: Show error toast:  
     `'Không tìm thấy hồ sơ độc giả'`.
4. **Confirmation Dialog (`BookReserveDialog`):**
   - Modal title: `'Đặt trước sách'`.
   - Message: `'Bạn có muốn đặt trước cuốn sách "${book.title}"?'`.
   - Text input: `labelText: 'Ghi chú (tùy chọn)'`, `hintText: 'Nhập ghi chú cho thư viện...'`.
   - Action buttons: `'Hủy'` (dismisses with null), `'Xác nhận đặt trước'` (trims notes and returns `BookReserveDialogResult`).
5. **BLoC Event Dispatch:**
   - Dispatches `CreateReservationRequested(memberId: memberId, bookId: book.id, notes: result.notes)`.
6. **Result Handling:**
   - On `ReservationCreateSuccess`: Show success toast `state.message`, triggers `_retry()` to refresh copies/status.
   - On `ReservationCreateFailure`: Show error toast `state.message`.

### 4.2 Borrow Flow
1. User taps `'Mượn sách'`.
2. Pushes `MaterialPageRoute` to `BorrowConfirmScreen(book: book)`.
3. If `BorrowConfirmScreen` pops with `true` (borrow slip successfully created), `BookDetailScreen` pops with `true`.
4. If cancelled or pops with `false`, `BookDetailScreen` triggers `_retry()` to ensure displayed availability is synchronized.

---

## 5. Screen Lifecycle States

| State | UI Representation | Interaction |
|---|---|---|
| **Loading** | `Center(child: CircularProgressIndicator())` | Blocks content until `_bookFuture` resolves |
| **Error (404 Not Found)** | `Text('Không tìm thấy sách')` + `ElevatedButton('Thử lại')` | Triggers `_retry()` |
| **Error (Network / Server)** | `Text('Không thể tải chi tiết sách')` + `ElevatedButton('Thử lại')` | Triggers `_retry()` |
| **Success / Loaded** | Full `ListView` with cover, title, metadata, availability, description, and action buttons | Scrollable body with active controls |

---

## 6. UI Keys & Automated Test Assertions

Existing automated widget tests in `test/book_detail_reservation_test.dart` assert the following:
- `find.byKey(const ValueKey('reserve_book_button'))`: Exactly 1 instance.
- `find.byKey(const ValueKey('borrow_book_button'))`: Exactly 1 instance.
- Text assertions: `'Chi tiết sách'`, `'Mượn sách'`, `'Đặt trước'`, `'Tác giả: ...'`, `'Thể loại: ...'`, `'ISBN: ...'`, `'Mô tả'`.
- Disabled state check on `borrow_book_button` when `canBorrow == false`.
- Toast warnings for unauthenticated and non-member roles.

---

## 7. Required Functional Behavior vs. Visual Styling

| Feature | Required Functional Contract (Must Preserve) | Flexible Visual Styling (Stitch Redesign Scope) |
|---|---|---|
| **Header** | Title `'Chi tiết sách'`, back button navigation | Typography (Newsreader / Manrope), elevation, blur, padding |
| **Book Cover** | Proportionate aspect ratio, placeholder fallback on null/error | Shadow depth, border stroke, background tint |
| **Metadata** | Display title, author, category, ISBN | Layout arrangement, icon tags, chip styling |
| **Availability** | Dynamic text `'Còn X / Y cuốn'` vs. `'Hiện không thể mượn...'` | Badge shape, background pill tint, typography hierarchy |
| **Description** | Section `'Mô tả'`, full description or `'Chưa có mô tả'` | Leading spacing, line height, typography size |
| **Actions** | Exactly 2 buttons: `'Đặt trước'` (reservation dialog) & `'Mượn sách'` (borrow flow) | Button height (48dp min), gradient/solid color, border radius |
| **Unsupported** | **No** shopping cart, **no** multi-slip queue counter, **no** shelf locator map modal | Any decorative academic elements that do not imply fake transactional APIs |
