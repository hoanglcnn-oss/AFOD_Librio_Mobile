# Stitch Design Review: BooksScreen Redesign

## 1. Executive Summary

This document reviews the visual redesign of `BooksScreen` generated in Google Stitch (Project: `Librio Academic Library App`, Project ID: `15818255613485056082`) following the **Academic Clarity** design system established in the approved `BookDetailScreen ver final`.

Two mobile screen variations were generated and downloaded:
1. **Screen A (Normal Catalogue Mode):** Screen ID `ea7c9d3cee024318b21e6c67a13c2442` (`design_workspace/books_screen/screens/catalogue_draft.png`)
2. **Screen B (Multi-Select Mode):** Screen ID `af271ec760734546b886d4d39a16db7b` (`design_workspace/books_screen/screens/multi_select_draft.png`)

---

## 2. Functional Comparison Matrix

| Feature / UI Element | Existing Flutter Implementation | Stitch Draft Screen A (Normal) | Stitch Draft Screen B (Multi-Select) | Backend / API Support | Recommendation for Flutter (Task 15B) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Top App Bar Title** | Text `"Sách"` or `"Danh mục sách"` | `"Danh sách sách"` | `"Đã chọn 2 đầu sách"` | Client-side state | Adopt Stitch clear counters and dynamic titles. |
| **Selection Mode Toggle** | Icon or button in AppBar | Action button `"Chọn nhiều"` | Action button `"Hủy"` (with close icon) | Client-side state | Adopt Stitch explicit text/icon toggle in header. |
| **Search Input** | `BookSearchBar` with text editing | Clean pill search input with search icon | Clean pill search input with search icon | Supported (`/books?search=...`) | Retain existing debounce and search submit behavior. |
| **Clear Search Action** | Clear button in text field | Explicit `close` icon button | Explicit `close` icon button | Client-side | Keep clear button to quickly reset search results. |
| **Barcode Scanner Button** | Trailing barcode icon in search bar | `qr_code_scanner` icon button | `qr_code_scanner` icon button | Supported (`mobile_scanner` flow) | Keep barcode camera scan button directly in search bar. |
| **Book Cover Thumbnail** | Small image widget | Aspect 1:1.4 cover with rounded corners | Aspect 1:1.4 cover with rounded corners | Supported (`book.imageUrl`) | Use cached network image with academic placeholder fallback. |
| **Book Metadata Display** | Title, author, category | Title (bold), author, category, published year | Title (bold), author, category, published year | Supported (`Book` model fields) | Layout metadata with high legibility and clear typography hierarchy. |
| **Availability Pill** | Simple text badge | Green `#E0F4EA` / Red `#FFDAD6` pill badge | Green `#E0F4EA` / Red `#FFDAD6` pill badge | Supported (`availableCopies`, `canBorrow`) | Adopt Stitch Academic Clarity badges (`Sẵn sàng mượn`, `Hết sách`). |
| **Selection Checkbox** | None in normal mode | Hidden (normal browsing) | Visible trailing checkbox (Primary `#00316E` when checked) | Client-side selection list | Implement trailing checkbox only during multi-select mode. |
| **Card Highlight on Select** | N/A | White card with `#CDD8E5` border | Active `2px solid #00316E` border and `#F0F4FA` fill | Client-side | Implement responsive card border & background highlight. |
| **Ineligible Book Handling** | Greyed out or alert | Normal card display | Reduced opacity (0.6), disabled checkbox, unclickable | Supported (`book.canBorrow`) | Apply `0.6` opacity and disable checkbox for non-borrowable items. |
| **Sticky Bottom Action Bar** | Bottom container with button | None (normal browsing) | Sticky bar with `"Tiếp tục (N sách)"` CTA | Supported (`BorrowingSlipConfirmScreen`) | Dock sticky bar above `SafeArea` only in multi-select mode. |
| **Infinite Scroll & Refresh** | ScrollController + RefreshIndicator | Page list representation | Page list representation | Supported (`PaginatedBooks` / BLoC) | Retain existing Flutter pagination & pull-to-refresh. |

---

## 3. Analysis of Absent / Questionable UI Elements

1. **Floating Cart / E-Commerce Cart Icon:**
   - *Observation:* Some generic catalogue designs place a shopping cart icon in the top header.
   - *Assessment:* **Unnecessary and unsupported.** Librio operates on direct library borrowing workflows (single book reserve or multi-book borrowing slip confirmation). The inline multi-selection mode with bottom sticky CTA `"Tiếp tục (N sách)"` accurately represents Librio's domain model without e-commerce cart overhead.
2. **Auto-Suggest / Search History Dropdown:**
   - *Observation:* Stitch search bars can imply live instant autocomplete dropdowns.
   - *Assessment:* The backend API `GetBooks` performs server-side filtering on submit. Instant dropdown auto-suggest is not implemented in the backend. Librio will continue using text submit and debounce queries directly updating the catalogue list.
3. **Category Filter Tabs / Chips:**
   - *Observation:* Category chips may appear above book lists in some web designs.
   - *Assessment:* In the current Librio backend contract, category filtering is part of search or full query parameters. The mobile priority for Task 15 is search + barcode scan. Category chips can be added as a progressive enhancement without breaking the current BLoC contract.

---

## 4. Academic Clarity Visual Token Compliance

| Design Token | Specification in Stitch Drafts | Alignment with Approved `BookDetailScreen` |
| :--- | :--- | :--- |
| **Primary Color** | `#00316E` | 100% matched with `BookDetailScreen ver final` |
| **Surface Background** | `#F7FAFD` | 100% matched |
| **Card Container** | `#FFFFFF`, 12px rounded corners, `#CDD8E5` 1px border | 100% matched |
| **Selected Card Accent** | `#00316E` border (2px), `#F0F4FA` fill | Consistent with Academic Clarity selection patterns |
| **Available Pill** | Background `#E0F4EA`, Text `#196B3E`, Icon `check_circle` | 100% matched |
| **Unavailable Pill** | Background `#FFDAD6`, Text `#BA1A1A`, Icon `error_outline` | 100% matched |
| **Typography** | Sans-serif (Be Vietnam Pro / Inter), high contrast | 100% matched |
| **Action Button Height** | 48dp minimum touch target | Compliant with Material 3 mobile standards |

---

## 5. Implementation Roadmap for Task 15B

1. **Keep Flutter Production Logic Untouched in Task 15A:** Verified that `week34_project/lib/` has not been modified.
2. **Task 15B Execution Scope:**
   - Refactor `lib/features/books/presentation/pages/books_screen.dart` to support Academic Clarity top bar, mode switching, and sticky action bar.
   - Redesign `lib/features/books/presentation/widgets/book_card.dart` to match the 12px rounded card, metadata hierarchy, availability pill, and selection checkbox.
   - Enhance `lib/features/books/presentation/widgets/book_search_bar.dart` with refined styling, clear button, and barcode scan action.
   - Preserve existing BLoC lifecycle, pagination controller, and navigation routes.
