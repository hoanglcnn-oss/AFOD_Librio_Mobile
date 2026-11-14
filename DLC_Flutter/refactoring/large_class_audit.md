# Large Class Responsibility & Refactoring Audit

**Date:** 2026-11-13  
**Repository:** `hoanglcnn-oss/AFOD_Librio_Mobile`  
**Flutter Project:** `week34_project/`  
**Target Branch:** `refactor/folder-screen-anything`  
**Reviewed Commit:** `042fd7d` (Commit 6: Test suite rationalization)  
**Status:** Audit-Only Document (Read-Only Analysis)

---

## 1. Executive Summary

This audit evaluates large, coupled, or responsibility-heavy Dart classes across `week34_project/lib/` following the completion of the 5-part Borrowing Domain structural migration and the subsequent test-suite rationalization.

### Core Metrics
- **Total Dart Files Analyzed:** 101 production files in `lib/`.
- **Files Exceeding 400 LOC:** 3 files.
- **Files Exceeding 250 LOC:** 12 files.
- **Total Refactor Candidates Evaluated:** 10 primary candidates + 2 supporting files.
- **Total Tests Currently Protecting Codebase:** 236 tests across 34 files (100% passing).

### Key Architectural Findings
1. **The Primary Monolith (`BorrowingSlipDetailScreen` — 923 LOC):**
   The detail screen currently serves as an overloaded operational hub, combining 9 distinct responsibilities, including an inline stateful renewal dialog of nearly 300 LOC, cancellation dialogs, and navigation orchestration across four sibling borrowing submodules (`return_slip`, `pay_slip_fine`, `approve_slip`, and `renewal`).
2. **Widget Tree Bloat in Form Screens (`BorrowingSlipConfirmScreen` — 546 LOC):**
   The confirmation screen embeds massive private widget-building helper methods (`_buildForm`, `_buildDebtSummaryCard`, `_buildSuccess`) within a single state class, mixing debt resolution, input validation, and result presentation.
3. **High-Cohesion Classes That Must NOT Be Split (`ReservationsBloc` — 384 LOC):**
   `ReservationsBloc` manages complex concurrency guards (`_readRequestId`, `_writeEpoch`, `_isMutating`, `_cancelledReservationIds`) to prevent stale reads from clobbering active mutations during network lags or timeouts. Splitting this BLoC would dismantle its thread-safe concurrency model and introduce race conditions.
4. **Cohesive Repositories & Dialogs:**
   `ApiBorrowingSlipsRepository` (350 LOC) and `SlipDecisionDialog` (259 LOC) are well-scoped implementations of single responsibilities. Their LOC reflects comprehensive API mappings and Material Dialog layouts rather than architectural coupling.

---

## 2. Ranked Candidate Table

| Priority | File Path | LOC | Main Problem | Recommendation | Regression Risk |
|---|---|---:|---|---|---|
| **P0** | `lib/features/borrowing/slip_management/presentation/pages/borrowing_slip_detail_screen.dart` | 923 | 9 distinct responsibilities; inline 295 LOC renewal dialog; direct cancel mutations. | **EXTRACT WIDGETS & DIALOGS** | MEDIUM |
| **P1** | `lib/features/borrowing/create_slip/presentation/pages/borrowing_slip_confirm_screen.dart` | 546 | Form, debt summary card, and result views combined in private methods of one State. | **EXTRACT WIDGET** | LOW |
| **P1** | `lib/features/borrowing/reservations/presentation/pages/my_reservations_screen.dart` | 465 | Mixed pagination, filter bar, list state, and an 80 LOC inline cancellation dialog. | **EXTRACT DIALOG & WIDGET** | LOW |
| **P2** | `lib/features/members/presentation/pages/borrowing_limit_screen.dart` | 363 | Heavy presentation methods for debt overview and borrowing conditions in one screen. | **EXTRACT WIDGET** | LOW |
| **P2** | `lib/features/books/presentation/pages/books_detail_screen.dart` | 321 | Book presentation contains an embedded reservation dialog and direct BLoC dispatches. | **EXTRACT DIALOG** | LOW |
| **P2** | `lib/features/borrowing/reservations/presentation/widgets/reservation_card.dart` | 303 | Long build method with verbose date/status switch formatting. | **KEEP AS IS** | LOW |
| **P2** | `lib/features/borrowing/slip_management/presentation/pages/manage_borrowing_slips_screen.dart` | 283 | Librarian list contains filter chips, pagination, and decision routing. | **KEEP AS IS** | LOW |
| **P2** | `lib/features/borrowing/approve_slip/presentation/widgets/slip_decision_dialog.dart` | 259 | Large dialog combining approve confirmation and reject reason form. | **KEEP AS IS** | LOW |
| **P3** | `lib/features/borrowing/reservations/bloc/reservations_bloc.dart` | 384 | Tightly coupled concurrency counters (`_writeEpoch`, `_readRequestId`). | **KEEP AS IS (Do Not Split)** | HIGH |
| **P3** | `lib/features/borrowing/shared/repositories/api_borrowing_slips_repository.dart` | 350 | Monolithic repository interface covering all borrowing capabilities. | **DEFER (Future Epic)** | HIGH |

---

## 3. Mandatory Deep Dive — `BorrowingSlipDetailScreen` (923 LOC)

### Current Responsibilities Breakdown
`BorrowingSlipDetailScreen` in `lib/features/borrowing/slip_management/presentation/pages/borrowing_slip_detail_screen.dart` is the largest class in the application.

```text
BorrowingSlipDetailScreen (923 LOC)
├── 1. Member & Role Resolution (lines 82–125)
├── 2. Slip Fetching & Lifecycle Management (lines 56–80, 126–139)
├── 3. Submodule Navigation Orchestration (lines 140–193)
│   ├── Return Slip (_openReturn -> BorrowingSlipReturnScreen)
│   ├── Fine Payment (_openPayFine -> PaySlipFineScreen)
│   └── Slip Decision (_processSlip -> SlipDecisionDialog)
├── 4. Slip Cancellation Flow (lines 194–322, 128 LOC)
│   ├── _confirmCancelSlip (Confirmation dialog)
│   └── _cancelSlip (Direct repository call, error handling, toast dispatch)
├── 5. Inline Renewal Dialog Flow (lines 323–618, 295 LOC)
│   ├── Dropdown selection (7, 14, custom days)
│   ├── Custom days input field & validation (1–14 days)
│   ├── Dynamic action enablement & setDialogState
│   ├── RenewSlipBloc dispatch (RenewSlipRequested)
│   └── Nested BlocListener & RenewalErrorMapper error presentation
├── 6. Renewal Section Presentation (lines 843–922, 80 LOC)
│   ├── Status badge, reason text, and eligibility button
│   └── Integration with RenewSlipBloc state
└── 7. Slip Detail UI Composition (lines 619–842, 223 LOC)
    ├── App bar with refresh indicator
    ├── Status header, borrower metadata, timestamps
    ├── Books list using BorrowingSlipItemCard
    └── Bottom action bar based on AppRole (MEMBER vs LIBRARIAN)
```

### Architectural Deficiencies
1. **Severe Violation of Single Responsibility Principle:**
   The screen handles UI rendering, navigation routing, asynchronous domain mutations (`cancelBorrowingSlip`), and complex modal form workflows (`_openRenewDialog`).
2. **Inline State Management Inflation:**
   `_openRenewDialog` spans 295 LOC solely to manage a modal dialog with `StatefulBuilder`, controllers, and internal BLoC listeners.
3. **Feature Boundary Leakage:**
   `BorrowingSlipDetailScreen` directly instantiates or listens to `RenewSlipBloc` from the `renewal` submodule, coupled with `RenewalErrorMapper`.
4. **State Ownership Issues:**
   The state class maintains multiple independent state streams: `_future` for the slip, `_renewBloc` for renewals, `_currentMemberId` for role resolution, `_isCancelling` for cancellation loading, and `_cachedSlip` for optimistic UI updates.

### Proposed Decomposed Architecture
Decomposing `BorrowingSlipDetailScreen` will reduce its size from 923 LOC to approximately 250 LOC:

```text
lib/features/borrowing/
├── slip_management/presentation/
│   ├── pages/
│   │   └── borrowing_slip_detail_screen.dart        # (~250 LOC) Core scaffold, lifecycle, routing
│   └── widgets/
│       ├── slip_detail_header.dart                  # (~120 LOC) Slip status, dates, borrower info
│       ├── slip_detail_items_list.dart              # (~70 LOC) List of BorrowingSlipItemCards
│       ├── slip_detail_action_bar.dart              # (~90 LOC) Member & Librarian action buttons
│       └── cancel_slip_dialog.dart                  # (~85 LOC) Isolated cancel confirmation dialog
│
└── renewal/presentation/widgets/
    ├── slip_renewal_dialog.dart                     # (~260 LOC) Extracted modal dialog with days selector
    └── slip_renewal_section.dart                    # (~80 LOC) Inline eligibility banner and renew CTA
```

### Protection & Test Coverage
- **Existing Test Coverage:**
  - `test/borrowing_slip_detail_screen_test.dart` (12 tests) covers role-based visibility, cancellation dialogs, and navigation triggers.
  - `test/borrowing_slip_renewal_screen_test.dart` (13 tests) covers eligibility presentation, days validation, and renewal BLoC integration.
- **Regression Risk:** **MEDIUM**. State ownership of `_renewBloc` and `_future` refresh callbacks must remain intact.

---

## 4. Mandatory Deep Dive — `BorrowingSlipConfirmScreen` (546 LOC)

### Current Responsibilities Breakdown
`BorrowingSlipConfirmScreen` in `lib/features/borrowing/create_slip/presentation/pages/borrowing_slip_confirm_screen.dart` is responsible for confirming and creating multi-book borrowing requests.

```text
BorrowingSlipConfirmScreen (546 LOC)
├── 1. Member & Debt Summary Loading (lines 83–99)
│   ├── _resolveMember (fetches current user card/ID)
│   └── _loadDebtSummary (fetches MemberDebtSummary via MembersRepository)
├── 2. Submission & Bloc Coordination (lines 100–144)
│   └── _submit (validates, constructs CreateBorrowingSlipRequest, calls BorrowingSlipBloc)
├── 3. Main Scaffold & BlocConsumer (lines 145–194)
├── 4. Large Form Builder `_buildForm` (lines 195–390, 195 LOC)
│   ├── Expected return days radio/dropdown (1–30 days)
│   ├── Purpose / Notes text field
│   └── Selected books list with items count and validation
├── 5. Debt Summary Widget `_buildDebtSummaryCard` (lines 391–513, 122 LOC)
│   ├── Active borrowing count vs allowed limit
│   ├── Overdue book warnings and outstanding fine badges
│   └── canBorrow boolean check to enable/disable submission
└── 6. Success State Widget `_buildSuccess` (lines 514–546, 32 LOC)
    └── Confirmation icon, generated slip ID, and back navigation button
```

### Architectural Deficiencies
1. **Monolithic State Class with Giant Methods:**
   The `_SlipConfirmContentState` class contains 475 LOC. `_buildForm` and `_buildDebtSummaryCard` are long procedural widget-building methods rather than composable widgets.
2. **Rebuild Performance:**
   Any change in local input state (e.g., entering notes or toggling days) triggers an evaluation of `_buildDebtSummaryCard` even though debt summary is completely static after initial load.

### Proposed Decomposed Architecture
```text
lib/features/borrowing/create_slip/presentation/
├── pages/
│   └── borrowing_slip_confirm_screen.dart          # (~180 LOC) Screen coordinator, BlocConsumer
└── widgets/
    ├── borrow_debt_summary_card.dart               # (~130 LOC) Standalone debt & eligibility card
    ├── borrow_slip_form_card.dart                  # (~170 LOC) Duration selector, notes, items list
    └── borrow_slip_success_view.dart               # (~40 LOC) Success feedback card
```

### Protection & Test Coverage
- **Existing Test Coverage:**
  - `test/borrowing_slip_confirm_screen_test.dart` (7 tests) covers limit loading, limit exceeded button lock, and submission navigation.
  - `test/borrowing_slip_bloc_test.dart` (4 tests) covers submission state transitions and double-submit protection.
- **Regression Risk:** **LOW**. Extracted widgets will be stateless or receive simple callbacks without altering `BorrowingSlipBloc` contracts.

---

## 5. `ReservationsBloc` Concurrency & Safety Review (384 LOC)

### Audit Target
`ReservationsBloc` in `lib/features/borrowing/reservations/bloc/reservations_bloc.dart`.

### Concurrency Mechanisms Analyzed
The BLoC implements robust custom concurrency control:
1. `int _readRequestId = 0`: Monotonically increasing counter for asynchronous fetch/pagination operations. Any stale read arriving after a newer request or mutation has been initiated is discarded.
2. `int _writeEpoch = 0`: Monotonically increasing epoch counter incremented on every mutation (create or cancel). Prevents out-of-order responses from overwriting the UI state.
3. `bool _isMutating = false`: Concurrency gate that blocks secondary mutations while one is in-flight (double-submit prevention).
4. `final Set<String> _cancelledReservationIds = {}`: Local tombstone set tracking IDs cancelled during the active session. If an outdated paginated query returns a reservation that was just cancelled locally, the BLoC filters it out.

### Keep/Split Recommendation: **KEEP AS IS (Do NOT Split)**
- **Reasoning:**
  - The ~384 LOC is not caused by disparate responsibilities, but by comprehensive concurrency and reconciliation logic for a single domain entity (`Reservation`).
  - Splitting into `ReservationQueryBloc` and `ReservationCommandBloc` would require external synchronization of `_writeEpoch` and `_cancelledReservationIds` across separate BLoCs, creating a distributed state problem in memory.
  - The BLoC is 100% verified by 16 targeted tests in `test/reservations_bloc_test.dart`.
- **Verdict:** Splitting would increase architectural complexity and introduce severe concurrency regression risks.

---

## 6. Per-Class Responsibility Audit of Remaining Candidates

### 1. `my_reservations_screen.dart` (465 LOC)
- **Module:** `borrowing/reservations/presentation/pages/`
- **Responsibilities:**
  1. Member resolution and BLoC initialization (`_initMember`).
  2. Pull-to-refresh and pagination navigation (`_changePage`, `_onRefresh`).
  3. Status filtering tabs (`TẤT CẢ`, `CHỜ XỬ LÝ`, `SẴN SÀNG NHẬN`, `ĐÃ HỦY`).
  4. Inline cancellation dialog (`_showCancelDialog`, 80 LOC).
  5. Reservation item listing using `ReservationCard`.
  6. Ready reservation fulfillment navigation (`_handleCreateSlip`).
- **Recommendation:** **EXTRACT DIALOG & WIDGET**
  - Extract `cancel_reservation_dialog.dart` (~85 LOC).
  - Extract `reservation_status_filter_bar.dart` (~65 LOC).
  - Screen size drops from 465 LOC to ~310 LOC.
- **Regression Risk:** **LOW**. Protected by `test/my_reservations_screen_test.dart` (11 tests).

### 2. `borrowing_limit_screen.dart` (363 LOC)
- **Module:** `members/presentation/pages/`
- **Responsibilities:**
  1. Member card resolution via `MemberResolver`.
  2. Loading `MemberDebtSummary` via `MembersRepository`.
  3. Rendering 4 distinct summary cards: Limit Status Card, Outstanding Fines Card, Eligibility Conditions Card, Policy Guide Card.
- **Recommendation:** **EXTRACT WIDGET**
  - Extract `member_debt_status_card.dart` into `features/members/presentation/widgets/`.
- **Regression Risk:** **LOW**. Protected by `test/borrowing_limit_screen_test.dart` (3 tests).

### 3. `api_borrowing_slips_repository.dart` (350 LOC)
- **Module:** `borrowing/shared/repositories/`
- **Responsibilities:**
  - Implements 11 API methods covering slip creation, listing, detail, approve, reject, return, renew, pay fine, cancel, and HTTP 409 limit error translation.
- **Recommendation:** **KEEP AS IS (DEFER Interface Segregation)**
  - Cohesive data layer implementation. While the interface spans multiple borrowing submodules, segregating it into `BorrowRepository`, `ReturnRepository`, etc., should be addressed in a future cross-cutting repository refactor.
- **Regression Risk:** **HIGH** if split now. Protected by `test/borrowing_slips_repository_test.dart` (17 tests).

### 4. `books_detail_screen.dart` (321 LOC)
- **Module:** `books/presentation/pages/`
- **Responsibilities:**
  1. Book metadata, availability, and cover presentation.
  2. Single book borrow routing (`BorrowConfirmScreen`).
  3. Inline reservation modal dialog (`_onReserveBook`, 75 LOC) and BLoC dispatch.
- **Recommendation:** **EXTRACT DIALOG**
  - Extract `book_reserve_dialog.dart` into `features/books/presentation/widgets/`.
- **Regression Risk:** **LOW**. Protected by `test/book_detail_reservation_test.dart` (7 tests).

### 5. `reservation_card.dart` (303 LOC)
- **Module:** `borrowing/reservations/presentation/widgets/`
- **Responsibilities:**
  - Renders a single reservation card with dates, codes, status badges, and action buttons.
- **Recommendation:** **KEEP AS IS**
  - Highly cohesive presentation widget. Its size is due to verbose layout padding and styling.

### 6. `manage_borrowing_slips_screen.dart` (283 LOC)
- **Module:** `borrowing/slip_management/presentation/pages/`
- **Responsibilities:**
  - Filter chips, paginated list of slips for librarians, detail navigation, and fast approval triggering.
- **Recommendation:** **KEEP AS IS**
  - Well-structured and concise for a complete administration screen.

### 7. `slip_decision_dialog.dart` (259 LOC)
- **Module:** `borrowing/approve_slip/presentation/widgets/`
- **Responsibilities:**
  - Approval confirmation, rejection note validation, BLoC dispatch, and 409 limit failure alert.
- **Recommendation:** **KEEP AS IS**
  - Self-contained modal dialog with dedicated BLoC listener.

---

## 7. Extraction Mapping

| Current File | Method / Component | Proposed Destination | Extraction Type | Dependencies |
|---|---|---|---|---|
| `borrowing_slip_detail_screen.dart` | `_openRenewDialog` (lines 323–618) | `lib/features/borrowing/renewal/presentation/widgets/slip_renewal_dialog.dart` | **EXTRACT DIALOG** | `RenewSlipBloc`, `RenewalErrorMapper`, `BorrowingSlip` |
| `borrowing_slip_detail_screen.dart` | `_buildRenewalSection` (lines 843–922) | `lib/features/borrowing/renewal/presentation/widgets/slip_renewal_section.dart` | **EXTRACT WIDGET** | `BorrowingSlip`, `RenewSlipState`, `onRenewPressed` |
| `borrowing_slip_detail_screen.dart` | `_confirmCancelSlip` (lines 194–244) | `lib/features/borrowing/slip_management/presentation/widgets/cancel_slip_dialog.dart` | **EXTRACT DIALOG** | Slip ID, `onConfirm` callback |
| `borrowing_slip_detail_screen.dart` | Header cards (lines 752–806) | `lib/features/borrowing/slip_management/presentation/widgets/slip_detail_header.dart` | **EXTRACT WIDGET** | `BorrowingSlip`, `BorrowingSlipUiHelper` |
| `borrowing_slip_detail_screen.dart` | Role action bar (lines 808–841) | `lib/features/borrowing/slip_management/presentation/widgets/slip_detail_actions.dart` | **EXTRACT WIDGET** | `BorrowingSlip`, `AppRole`, Action Callbacks |
| `borrowing_slip_confirm_screen.dart` | `_buildDebtSummaryCard` (lines 391–513) | `lib/features/borrowing/create_slip/presentation/widgets/borrow_debt_summary_card.dart` | **EXTRACT WIDGET** | `MemberDebtSummary`, `canBorrow` |
| `borrowing_slip_confirm_screen.dart` | `_buildForm` (lines 195–390) | `lib/features/borrowing/create_slip/presentation/widgets/borrow_slip_form_card.dart` | **EXTRACT WIDGET** | Selected books, Form controllers, Callbacks |
| `my_reservations_screen.dart` | `_showCancelDialog` (lines 145–225) | `lib/features/borrowing/reservations/presentation/widgets/cancel_reservation_dialog.dart` | **EXTRACT DIALOG** | Reservation ID, `onCancelConfirmed` callback |
| `books_detail_screen.dart` | `_onReserveBook` (lines 200–275) | `lib/features/books/presentation/widgets/book_reserve_dialog.dart` | **EXTRACT DIALOG** | `Book`, `MemberResolver`, `ReservationsBloc` |
| `borrowing_limit_screen.dart` | Status card (lines 100–185) | `lib/features/members/presentation/widgets/member_debt_status_card.dart` | **EXTRACT WIDGET** | `MemberDebtSummary` |

---

## 8. Dependency & Refactor Impact Analysis

### Impact on Imports and Module Boundaries
1. **Renewal Section & Dialog Extraction:**
   - Moving the renewal dialog to `lib/features/borrowing/renewal/presentation/widgets/slip_renewal_dialog.dart` places renewal form logic squarely within the `renewal/` capability.
   - `BorrowingSlipDetailScreen` will import `SlipRenewalDialog` and `SlipRenewalSection` rather than directly importing `RenewalErrorMapper` and managing day validation regexes.
2. **Zero Modification to BLoCs:**
   - None of the recommended extractions alter BLoC interfaces, event payloads, or state models.
   - `RenewSlipBloc`, `BorrowingSlipBloc`, `ApproveSlipBloc`, and `ReservationsBloc` remain 100% untouched.
3. **Widget Callback Interface:**
   - Extracted presentation widgets (`SlipDetailHeader`, `BorrowDebtSummaryCard`) will receive immutable data models and emit standard `VoidCallback` or `ValueChanged<T>` events, preserving clean unidirectional data flow.

---

## 9. Refactor Roadmap (Future Phased Implementation)

Should the team choose to execute these decompositions, they should be performed as small, atomic commits:

### Phase 1: Decompose `BorrowingSlipDetailScreen` (P0)
- **Commit 1A:** Extract `SlipRenewalDialog` and `SlipRenewalSection` to `features/borrowing/renewal/`.
  - *Files Affected:* `borrowing_slip_detail_screen.dart`, new `slip_renewal_dialog.dart`, new `slip_renewal_section.dart`.
  - *Verification:* `test/borrowing_slip_renewal_screen_test.dart` (13 tests) must pass with 0 regressions.
- **Commit 1B:** Extract `SlipDetailHeader`, `SlipDetailActions`, and `CancelSlipDialog`.
  - *Files Affected:* `borrowing_slip_detail_screen.dart`, new header/action/dialog widgets in `slip_management/presentation/widgets/`.
  - *Verification:* `test/borrowing_slip_detail_screen_test.dart` (12 tests) must pass with 0 regressions.

### Phase 2: Decompose `BorrowingSlipConfirmScreen` (P1)
- **Commit 2:** Extract `BorrowDebtSummaryCard` and `BorrowSlipFormCard` to `features/borrowing/create_slip/presentation/widgets/`.
  - *Files Affected:* `borrowing_slip_confirm_screen.dart`, new widgets under `create_slip/presentation/widgets/`.
  - *Verification:* `test/borrowing_slip_confirm_screen_test.dart` (7 tests) must pass with 0 regressions.

### Phase 3: Decompose `MyReservationsScreen` & `BookDetailScreen` (P1/P2)
- **Commit 3A:** Extract `CancelReservationDialog` to `features/borrowing/reservations/presentation/widgets/`.
  - *Verification:* `test/my_reservations_screen_test.dart` (11 tests) must pass.
- **Commit 3B:** Extract `BookReserveDialog` to `features/books/presentation/widgets/`.
  - *Verification:* `test/book_detail_reservation_test.dart` (7 tests) must pass.

---

## 10. Keep-As-Is Decisions

| Class Name | LOC | Justification for Keeping Intact |
|---|---:|---|
| **`ReservationsBloc`** | 384 | Concurrency mechanisms (`_readRequestId`, `_writeEpoch`, `_isMutating`, `_cancelledReservationIds`) require unified in-memory coordination. Splitting creates race conditions. |
| **`ApiBorrowingSlipsRepository`** | 350 | Highly cohesive, low-complexity implementation. Splitting interface should only be done in a major domain API epic. |
| **`ReservationCard`** | 303 | Pure presentation widget; length is caused by standard Material Card styling. |
| **`ManageBorrowingSlipsScreen`** | 283 | Already well-organized for a multi-status filterable librarian screen. |
| **`SlipDecisionDialog`** | 259 | Self-contained, modal dialog with focused BLoC integration. |

---

## 11. Risks and Open Questions

1. **`RenewSlipBloc` Scoping and Lifecycle:**
   Currently, `BorrowingSlipDetailScreen` can accept an optional external `RenewSlipBloc` for testing, but instantiates its own if null. When extracting `SlipRenewalSection`, the BLoC provider boundary must remain at or above the detail screen so both the section and the modal dialog share the same bloc instance.
2. **Context Passing in Modal Dialogs:**
   Extracting `SlipRenewalDialog` and `CancelSlipDialog` into separate files requires careful context management so that parent `ScaffoldMessenger` and `BlocProvider` references remain valid after dialog pop.
3. **Interface Segregation for `BorrowingSlipsRepository`:**
   While `BorrowingSlipsRepository` is large, postponing its segregation preserves atomic stability across all 34 test files.
