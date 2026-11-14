# Screen UI Contract: BooksScreen

## 1. Overview & Context

- **Screen Name:** `BooksScreen`
- **Location in App:** Embedded in `MainScreen` (`IndexedStack`, tab index 0).
- **Primary Roles:** Library members (Students, Faculty) and Guests.
- **Core Responsibilities:**
  1. Display paginated library catalogue with cover, title, author, category, publication year, and real-time availability.
  2. Provide keyword search (title / author) with clear action.
  3. Provide barcode / QR code scanning to lookup books by barcode.
  4. Enable multi-book selection mode for streamlined borrowing slip creation.
  5. Route to `BookDetailScreen` on card tap (normal mode) or `BorrowingSlipConfirmScreen` (multi-select mode).

---

## 2. Screen Modes & Layout Hierarchy

### Mode A: Normal Catalogue Mode
1. **Header / AppBar:**
   - Title: `Danh sách sách` (Typography: 20px, bold / semi-bold, neutral dark `#0F172A`).
   - Action Button: Text button or outlined pill `Chọn nhiều` (Primary `#00316E`), toggles selection mode.
2. **Search & Scanner Bar:**
   - Search text input with leading search icon.
   - Text placeholder: `"Tìm kiếm theo tên sách hoặc tác giả..."`.
   - Trailing actions:
     - Clear button (`Icons.clear`): Clears search text and re-fetches default catalogue.
     - Barcode scanner button (`Icons.qr_code_scanner`): Triggers mobile barcode camera scanner.
3. **Book List (Vertical ListView):**
   - RefreshIndicator (Pull-to-refresh): dispatches `FetchBooksEvent(refresh: true)`.
   - ScrollController: detects scroll near bottom to dispatch `FetchBooksEvent(page: next)`.
   - Book Cards (see Item Contract below).
   - Bottom Loader: displays subtle circular progress indicator when fetching additional pages.

### Mode B: Multi-Book Selection Mode
1. **Header / AppBar:**
   - Title: `Đã chọn {count} đầu sách` (e.g., `"Đã chọn 2 đầu sách"`).
   - Action Button: `Hủy` (Cancel) button with close icon (`Icons.close`), exits multi-selection mode and resets selected list.
2. **Search & Scanner Bar:**
   - Fully functional search bar as in Mode A.
3. **Book List with Selection Controls:**
   - Book Cards show a trailing selection Checkbox instead of the navigation chevron.
   - **Eligible items (`book.canBorrow == true`):**
     - Tap toggles selection.
     - When selected: Active border (`2px solid #00316E`), subtle background tint (`#F0F4FA`), checkbox checked (`#00316E`).
     - When unselected: Neutral border (`1px solid #CDD8E5`), white background, checkbox unchecked.
   - **Ineligible items (`book.canBorrow == false`):**
     - Disabled checkbox (unclickable).
     - Card opacity reduced (`0.55` - `0.6`), visually signaling the book cannot be borrowed.
     - Tap shows informative toast/snackbar: `"Sách này hiện không khả dụng để mượn"`.
4. **Sticky Bottom Action Bar:**
   - Docked above `SafeArea`.
   - White surface background (`#FFFFFF`), subtle top divider (`#E2E8F0`), elevation shadow.
   - Primary Action Button:
     - Label: `"Tiếp tục ({count} sách)"` (e.g., `"Tiếp tục (2 sách)"`).
     - Trailing icon: `Icons.arrow_forward`.
     - State: Enabled when `{count} > 0`, disabled when `{count} == 0`.
     - Action: Navigates to `BorrowingSlipConfirmScreen` with selected `List<Book>`.

---

## 3. Book Card Component Specification

| Property | Visual Specification | Behavior / Logic |
| :--- | :--- | :--- |
| **Card Container** | Background `#FFFFFF`, 12px border radius, 1px border `#CDD8E5`, subtle elevation (`0 1px 3px rgba(0,0,0,0.05)`). | In selection mode, active items get 2px `#00316E` border and `#F0F4FA` fill. |
| **Cover Thumbnail** | Width 60px, Height 84px (aspect ~1:1.4), rounded 6px. | Network image with cached placeholder and fallback icon (`Icons.menu_book`) on error/empty. |
| **Title** | 15px, Font-weight 600, Color `#0F172A`, max 2 lines with ellipsis. | Display `book.title`. |
| **Author** | 13px, Color `#475569`, max 1 line with ellipsis. Leading author icon (`Icons.person_outline`). | Display `book.author ?? 'Chưa rõ tác giả'`. |
| **Category & Year** | 12px, Color `#64748B`. Subtle dot separator. | Display `book.category` • `book.publishedYear`. |
| **Availability Pill** | Pill badge: 6px vertical, 10px horizontal padding, rounded-full. | - Available: Green fill `#E0F4EA`, text `#196B3E`, icon `check_circle`, label `"Sẵn sàng mượn ({availableCopies})"`.<br>- Unavailable: Red fill `#FFDAD6`, text `#BA1A1A`, icon `error_outline`, label `"Hết sách ({availableCopies})"`. |
| **Trailing Action** | - Normal mode: Chevron right icon (`Icons.chevron_right`, `#94A3B8`).<br>- Multi-select mode: Checkbox (Primary `#00316E`). | - Normal mode: Opens `BookDetailScreen(bookId: book.id)`.<br>- Multi-select mode: Toggles selection in state. |

---

## 4. State Management & Lifecycle Contract (`BooksBloc`)

| BLoC State | UI Presentation | Actions Available |
| :--- | :--- | :--- |
| `BooksInitialState` | Initial scaffold or skeleton shimmer. | Automatic load trigger. |
| `BooksLoadingState` | Centered `CircularProgressIndicator` or skeleton list. | Search input disabled during initial fetch. |
| `BooksLoadedState` | Render list of `BookCard`s. Infinite scroll listener active. | Search, Clear, Scan, Card tap, Mode toggle. |
| `BooksLoadedState (Empty)` | Empty illustration/icon (`Icons.search_off`), message `"Không tìm thấy sách nào phù hợp"`, button `"Xem tất cả"`. | Reset search query. |
| `BooksErrorState` | Error illustration/icon (`Icons.error_outline`), message `"Không thể tải danh sách sách"`, button `"Thử lại"`. | Retries `FetchBooksEvent`. |

---

## 5. Navigation & External Integration

1. **Tap Book Card (Normal Mode):**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)),
   );
   ```
2. **Barcode Scanner Action:**
   - Launches mobile camera scanner (`BarcodeScannerScreen`).
   - On barcode detected: updates search controller text and dispatches `SearchBooksEvent(query: code)`.
3. **Continue to Borrowing Slip (Multi-Select Mode):**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (_) => BorrowingSlipConfirmScreen(books: selectedBooks),
     ),
   );
   ```
4. **Session / Auth Requirements:**
   - Browsing and searching books is public (Guests & Members).
   - Entering Multi-Select Mode or continuing to Borrowing Confirmation requires Member authentication (redirects to Login if unauthenticated).
