# Post-Refactor Regression & Integration Audit

**Date:** 2026-11-14  
**Repository:** `hoanglcnn-oss/AFOD_Librio_Mobile`  
**Flutter Project:** `week34_project/`  
**Target Branch:** `refactor/folder-screen-anything`  
**Base Commit:** `5d2dce56f9112fc8853fe4b25f6f683257f83db8` (Commit 11: Extract book reservation dialog)  
**Status:** Audit & Verification Report (Documentation-Only)

---

## 1. Executive Summary

This audit evaluates the regression status, architectural integrity, and business integration flows of the AFOD Librio Mobile application following the multi-phase refactoring series:
1. **Borrowing Domain Structural Migration (Commits 1–5):** Reorganized legacy flat folders into feature-capability modules (`shared`, `reservations`, `renewal`, `create_slip`, `approve_slip`, `return_slip`, `pay_slip_fine`, `slip_management`).
2. **Evidence-Based Test Suite Rationalization (Commit 6):** Streamlined redundant and low-value tests while protecting all critical P0/P1 invariants (236 baseline tests).
3. **Large Class Responsibility Audit (Task 7):** Diagnosed structural monoliths and mapped decomposition opportunities without altering business rules.
4. **Decomposition Implementations (Tasks 8A–11):**
   - **Commit 8A:** Extracted `SlipRenewalDialog` and `SlipRenewalSection` from `BorrowingSlipDetailScreen` (923 LOC → 655 LOC).
   - **Commit 8B:** Extracted `SlipDetailHeader`, `SlipDetailActions`, and `CancelSlipDialog` from `BorrowingSlipDetailScreen` (655 LOC → 492 LOC).
   - **Commit 9:** Extracted `BorrowSlipFormCard` and `BorrowDebtSummaryCard` from `BorrowingSlipConfirmScreen` (546 LOC → 295 LOC).
   - **Commit 10A:** Extracted `CancelReservationDialog` from `MyReservationsScreen` (465 LOC → 430 LOC).
   - **Commit 11:** Extracted `BookReserveDialog` from `BookDetailScreen` (321 LOC → 289 LOC).

### Key Audit Highlights
- **Static Analysis:** `flutter analyze` reports **0 errors, 0 warnings, 0 lints**.
- **Automated Test Suite:** **244 passing tests out of 244** across 35 test files (100% pass rate, 0 failures, 0 skipped, ~7.5s execution time).
- **Behavioral Invariants:** All existing role permissions (`MEMBER` vs `LIBRARIAN`), concurrency guards, duplicate-request throttles, timeout reconciliation flows, and dialog contracts are verified intact.
- **Confirmed Regressions:** **0**. No behavioral bugs were introduced by the presentation decompositions.

---

## 2. Test and Analyzer Verification

### 2.1 Static Analysis
Command: `flutter analyze`
```text
Analyzing week34_project...
No issues found! (ran in 1.3s)
```
- No unused imports.
- No deprecated API usage.
- Strict type conformance maintained across all refactored classes.

### 2.2 Test Suite Execution
Command: `flutter test`
```text
00:07 +244: All tests passed!
```
- Total test files: **35**
- Total test cases: **244** (increased from baseline of 236 due to focused contract tests for extracted dialogs)
- Execution time: **~7.5 seconds**
- Coverage file: Generated successfully at `coverage/lcov.info`.

### 2.3 Targeted Test Results by Capability Area
| Capability / Module | Primary Test Files | Test Count | Result |
|---|---|---:|:---:|
| **Slip Management & Detail** | `borrowing_slip_detail_screen_test.dart`<br>`manage_borrowing_slips_screen_test.dart` | 24 | PASS |
| **Renewal Flow** | `borrowing_slip_renewal_screen_test.dart`<br>`renew_slip_bloc_test.dart`<br>`renewal_error_mapper_test.dart` | 33 | PASS |
| **Create Slip (Multi & Single)** | `borrowing_slip_confirm_screen_test.dart`<br>`borrow_confirm_screen_test.dart`<br>`borrowing_slip_bloc_test.dart` | 18 | PASS |
| **Reservations & Dialogs** | `my_reservations_screen_test.dart`<br>`book_detail_reservation_test.dart`<br>`reservations_bloc_test.dart`<br>`reservations_repository_test.dart` | 51 | PASS |
| **Slip Approval & Decisions** | `approve_slip_bloc_test.dart`<br>`pending_borrowing_slips_screen_test.dart` | 16 | PASS |
| **Return & Fine Payment** | `return_slip_bloc_test.dart`<br>`pay_slip_fine_bloc_test.dart` | 6 | PASS |
| **Auth & Members** | `auth_bloc_test.dart`<br>`member_resolver_test.dart`<br>`members_debt_summary_repository_test.dart` | 27 | PASS |

---

## 3. End-to-End Business Flow Audit Matrix

| Flow | Key Steps | State Ownership & Safety Controls | Verification Status |
|---|---|---|:---:|
| **A. Authentication** | App launch → Session restore → Login / Register → Authenticated routing → Logout | `AuthBloc` manages tokens in `TokenStorage`. Emits `AuthAuthenticated` with `UserProfile` or `AuthUnauthenticated`. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **B. Single-Book Borrowing** | `BooksScreen` → `BookDetailScreen` → `BorrowConfirmScreen` → Request → Result | `BorrowConfirmScreen` loads member ID via `MemberResolver`, validates `book.canBorrow`, coordinates `BorrowingSlipBloc`. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **C. Multi-Book Borrowing** | Book selection → `BorrowingSlipConfirmScreen` → `BorrowSlipFormCard` + `BorrowDebtSummaryCard` → Create Request → Success | Pre-submit debt check, `_daysController` lifecycle, 1–30 day bounds, quota limits, double-submit button guard. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **D. Reservation Creation** | `BookDetailScreen` → `BookReserveDialog` → `CreateReservationRequested` → Result | Enforces `MEMBER` role, resolves member ID, handles optional notes, dialog returns `BookReserveDialogResult`, double-submit disabled. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **E. Reservation Cancellation** | `MyReservationsScreen` → `CancelReservationDialog` → `CancelReservationRequested` → Refresh | Verifies authenticated member owns reservation, dialog returns `CancelReservationDialogResult`, `ReservationsBloc` write-epoch guards. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **F. Slip Detail Management** | Slip list → `BorrowingSlipDetailScreen` → `SlipDetailHeader` + `SlipDetailActions` | Role check (`AppRole.canManageBorrowingSlips`), owner checks, approve/reject routing, copy member ID toast. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **G. Renewal** | Detail screen → `SlipRenewalSection` → `SlipRenewalDialog` → `RenewSlipBloc` → Refresh | Duration validation (1–14 days), preset chips (3, 7, 14), projected due date calculation, offline background sync fallback. | **VERIFIED**<br>*(Widget & Bloc tests)* |
| **H. Return & Fines** | Detail screen → Return / Fine screens → API mutation → Refresh | Return quantity validation, unpaid fine calculation, librarian-only fine payment recording. | **VERIFIED**<br>*(Widget & Bloc tests)* |

> [!NOTE]
> All flows marked **VERIFIED** above were executed using hermetic Flutter widget and BLoC integration tests with realistic test doubles. Real backend execution is documented in Section 7.

---

## 4. BLoC Lifecycle and Ownership Review

A major risk during presentation decomposition is premature BLoC closure or memory leaks. The audit reviewed every screen and dialog:

### 4.1 Injected vs. Locally Created BLoCs
1. **`BookDetailScreen` (`_reservationsBloc`):**
   - Supports optional injection: `widget.reservationsBloc`.
   - Uses `_ownsBloc` boolean flag set in `initState()`.
   - `dispose()` only closes `_reservationsBloc` if `_ownsBloc == true`.
   - **Verdict:** Safe. Externally supplied test BLoCs are never closed prematurely.
2. **`BorrowingSlipDetailScreen` (`_renewBloc`):**
   - Supports optional injection: `widget.renewSlipBloc`.
   - Uses `_isCustomBloc` flag.
   - `dispose()` only closes `_renewBloc` if `!_isCustomBloc`.
   - **Verdict:** Safe.
3. **`MyReservationsScreen` & `BorrowingSlipConfirmScreen`:**
   - Both use standard `BlocProvider(create: (_) => ...)` at the screen entry widget.
   - Flutter's `BlocProvider` automatically handles BLoC teardown when the route is popped.
   - **Verdict:** Safe.

### 4.2 Dialog Isolation from Domain BLoCs
None of the extracted dialogs (`BookReserveDialog`, `CancelReservationDialog`, `CancelSlipDialog`, `SlipRenewalDialog`) instantiate, listen to, or close BLoCs:
- Dialogs interact exclusively with their callers via `Navigator.pop<T>(result)`.
- Parent screens check `mounted` after awaiting `showDialog` before calling `context.read<Bloc>().add(...)`.
- **Verdict:** Zero feature leakage or lifecycle hazards.

---

## 5. Dialog and Form Regression Checks

### 5.1 Dialog Result Contracts
All extracted dialogs now adhere to a clean contract distinguishing between **dismissal**, **confirmation with empty input**, and **confirmation with populated input**:

| Dialog | Result Type | Dismiss / Cancel | Confirmed (Empty / Default) | Confirmed (Populated) |
|---|---|---|---|---|
| **`BookReserveDialog`** | `BookReserveDialogResult` | `null` | `notes: null` | `notes: trimmedText` |
| **`CancelReservationDialog`** | `CancelReservationDialogResult` | `null` | `reason: null` | `reason: trimmedText` |
| **`CancelSlipDialog`** | `CancelSlipDialogResult` | `null` | `reason: null` | `reason: trimmedText` |
| **`SlipRenewalDialog`** | `int?` | `null` | N/A (requires valid selection) | `extraDays: 1..14` |

- **Verification:** Unit and widget tests confirm that clicking "Đóng" / "Hủy" or tapping outside the barrier produces `null` without invoking mutation events.

### 5.2 Form State & Controller Lifecycle
1. **`BorrowSlipFormCard`:**
   - `daysController` is owned by `_SlipConfirmContentState`, initialized in `initState()` and disposed in `dispose()`.
   - Rebuilding `BorrowSlipFormCard` (e.g., when book quantities change) does not recreate the controller or lose typed values.
   - Selecting a preset `ChoiceChip` updates both `daysController.text` and parent `_days` state simultaneously.
2. **`BorrowDebtSummaryCard`:**
   - Rebuilding form inputs does **not** trigger new debt summary network requests because `_debtSummaryFuture` is memoized in the parent state.
   - Refetch occurs only on explicit retry or pre-submission verification.

---

## 6. Backend Contract Compatibility

The Flutter API data sources and repository implementations were compared against expected REST contracts:

| Entity | Endpoint | HTTP Method | Expected Payload / Params | Status Codes Handled | Error Mapper |
|---|---|:---:|---|:---:|---|
| **Auth** | `/auth/login`<br>`/auth/register`<br>`/auth/me` | `POST`<br>`POST`<br>`GET` | `email`, `password`<br>`fullName`, `phone`, `email`, `password` | 200, 400, 401 | Handled in `AuthBloc` |
| **Borrowing Slips** | `/borrowing-slips` | `POST` | `memberId`, `expectedReturnDays`, `items: [{bookId, quantity}]` | 201, 400, 409 | `BorrowingSlipErrorMapper` |
| **Slip Queries** | `/borrowing-slips`<br>`/borrowing-slips/:id` | `GET` | Query: `memberId`, `status`, `page`, `limit` | 200, 404 | Repositories throw typed errors |
| **Approve / Reject** | `/borrowing-slips/:id/approve`<br>`/borrowing-slips/:id/reject` | `PATCH` | Body for reject: `{"reason": string}` | 200, 409 | Handled in `ApproveSlipBloc` |
| **Cancel Slip** | `/borrowing-slips/:id/cancel` | `PATCH` | Body: `{"reason": string}` (optional) | 200, 400, 409 | Verified via `getBorrowingSlipById` on timeout |
| **Renew Slip** | `/borrowing-slips/:id/renew` | `PATCH` | Body: `{"extraDays": int}` | 200, 400, 409 | `RenewalErrorMapper` |
| **Return Items** | `/borrowing-slips/:id/return-items` | `POST` | Body: items array with returned condition | 200, 400 | Repositories parse response |
| **Pay Fine** | `/borrowing-slips/:id/pay-fine` | `POST` | Empty body, authenticated token | 200, 400 | `PaySlipFineBloc` |
| **Reservations** | `/reservations` | `POST` | `memberId`, `bookId`, `notes` (optional) | 201, 400, 409 | `ReservationErrorMapper` |
| **Cancel Reservation** | `/reservations/:id/cancel` | `PATCH` | Body: `{"reason": string}` (optional) | 200, 400, 409 | Reconciled via `getReservationById` on timeout |

### Timeout Reconciliation Analysis
Both slip cancellation and reservation cancellation implement resilient network timeout reconciliation:
- If a `DioException` of type `connectionTimeout`, `sendTimeout`, `receiveTimeout`, or `connectionError` occurs, neither client resends the mutation request.
- Instead, they issue an idempotent `GET` verification request to check whether the state transitioned on the server before presenting an error or success to the user.

---

## 7. Manual Verification Matrix (Live Environment Checklist)

Because tests execute against fakes and mocks, this checklist defines test cases for execution against a live or staging backend:

| Case ID | Feature / Flow | Preconditions | Role Required | Test Steps | Expected Result | Status |
|---|---|---|---|---|---|:---:|
| **TC-01** | Token Persistence | User logged in | `MEMBER` | Terminate app process, relaunch app | User remains logged in; profile restored without login prompt | **NOT VERIFIED**<br>*(No live env)* |
| **TC-02** | Book Reservation Creation | Book with `copiesAvailable == 0` | `MEMBER` | Open book detail, tap "Đặt trước", enter note, tap "Xác nhận" | Reservation created with status `PENDING`, book screen updates | **NOT VERIFIED**<br>*(No live env)* |
| **TC-03** | Reservation Cancellation | Active `PENDING` reservation | `MEMBER` | In "Đặt trước của tôi", tap "Hủy đặt trước", confirm | Reservation disappears or updates to `CANCELLED`, list refreshes | **NOT VERIFIED**<br>*(No live env)* |
| **TC-04** | Multi-Book Borrow Creation | 2 available books | `MEMBER` | Select books, open confirm screen, select 7 days, submit | Slip created with status `PENDING_APPROVAL`, navigation to success | **NOT VERIFIED**<br>*(No live env)* |
| **TC-05** | Debt Limit Enforcement | Member borrowing 5/5 books | `MEMBER` | Attempt multi-book borrow | Debt card shows limit exceeded; submit button disabled | **NOT VERIFIED**<br>*(No live env)* |
| **TC-06** | Slip Approval | Pending slip exists | `LIBRARIAN` | In manage slips, tap "Duyệt phiếu", confirm in dialog | Status transitions to `BORROWED`, book inventory decrements | **NOT VERIFIED**<br>*(No live env)* |
| **TC-07** | Slip Renewal | Borrowed slip eligible for renewal | `MEMBER` | In slip detail, tap "Gia hạn", pick 14 days, confirm | Due date extends by 14 days, renew count increments | **NOT VERIFIED**<br>*(No live env)* |
| **TC-08** | Non-Owner Cancellation Guard | Slip owned by user B | User A (`MEMBER`) | Open slip detail for user B | "Hủy phiếu mượn" button is not visible | **NOT VERIFIED**<br>*(No live env)* |
| **TC-09** | Fine Collection | Slip with overdue fine | `LIBRARIAN` | Tap "Ghi nhận đã thu tiền phạt", confirm | Fine paid status updates to true, debt cleared | **NOT VERIFIED**<br>*(No live env)* |

---

## 8. Bug Reporting & Risk Assessment

### 8.1 Confirmed Bugs
- **None (0 confirmed bugs).** All 244 automated test assertions pass with zero failures.

### 8.2 Potential Risks
1. **Fallback in Pre-Submit Quota Verification (`BorrowingSlipConfirmScreen._submit`):**
   - *Risk:* If `getDebtSummary()` throws a network error right before submission, the `catch (_)` block allows the submission to proceed to let the backend validate quota.
   - *Impact:* Low. Backend returns HTTP 409 if exceeded, which is handled properly by `BorrowingSlipBloc`.
2. **Hardcoded API URL in `ApiConstants`:**
   - *Risk:* `ApiConstants.baseUrl = 'https://api.leorank.site/api'` is hardcoded.
   - *Impact:* Medium. Running automated integration tests against local mock servers or staging environments requires changing source or refactoring to environment variables (`--dart-define`).

### 8.3 Technical Debt
1. **Monolithic Data Layer Interface (`ApiBorrowingSlipsRepository`):**
   - Spans 350 LOC handling 10 distinct operations. Currently deferred to future backend/data layer epic.
2. **`BorrowConfirmScreen` (Single-Book) vs. `BorrowingSlipConfirmScreen` (Multi-Book):**
   - Two distinct confirmation screen implementations exist side-by-side. Future consolidation into a single unified borrow workflow is recommended.

---

## 9. Recommended Next Actions

1. **Production Deployment Readiness:**
   - Codebase is in a clean, stable state with high automated test coverage (244 tests).
   - Ready to merge feature branches into `main` after live staging smoke tests.
2. **Configuration Management:**
   - Introduce `--dart-define=API_BASE_URL=...` in `DioClient` to enable staging/production environment toggling without modifying Dart code.
3. **Future Architectural Slices:**
   - Consolidate single-book and multi-book borrowing flows into a unified presentation pattern.
   - Decompose `ApiBorrowingSlipsRepository` into focused domain data sources.

---

## 10. Audit Sign-Off

- **Analyzer Result:** `0 errors, 0 warnings, 0 lints`
- **Automated Tests:** `244 passed, 0 failed, 0 skipped`
- **Audit Verification:** Complete
