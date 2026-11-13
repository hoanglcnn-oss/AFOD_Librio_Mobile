import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowing_slips/data/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing_slips/presentation/pages/borrowing_slip_detail_screen.dart';
import 'package:week34_project/features/renewal/models/renewal_eligibility.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeTokenStorage tokenStorage;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = FakeAuthRepository();
    tokenStorage = FakeTokenStorage();
    authBloc = AuthBloc(
      authRepository: authRepository,
      tokenStorage: tokenStorage,
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  Widget createApp(
    FakeBorrowingRepository repository, {
    String role = 'MEMBER',
    String userId = 'user-01',
  }) {
    authBloc.emit(
      AuthAuthenticated(
        user: UserProfile(
          id: userId,
          email: 'test@librio.vn',
          phone: '0901234567',
          fullName: 'Người dùng kiểm thử',
          role: role,
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        home: Scaffold(
          body: BorrowingSlipDetailScreen(
            slipId: 'slip-01',
            repository: repository,
          ),
        ),
      ),
    );
  }

  group('BorrowingSlipDetailScreen - Gia hạn phiếu nhiều sách', () {
    testWidgets(
      'canRenew == true | Hiển thị nút Gia hạn, mở dialog xác nhận và gửi PATCH thành công',
      (tester) async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'user-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [
            BorrowingSlipItem(
              id: 'it-1',
              bookId: 'b-1',
              bookTitle: 'Clean Code',
              quantity: 1,
              status: 'BORROWING',
            ),
          ],
        );
        repository.fakeSlipDetail = initialSlip;

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        // Kiểm tra thông tin hạn trả và số lần gia hạn
        expect(find.text('SLIP-2026-0001'), findsOneWidget);
        expect(find.text('Số lần đã gia hạn: 0'), findsOneWidget);
        expect(find.text('Gia hạn'), findsOneWidget);

        // Nhấn nút Gia hạn -> mở dialog
        await tester.tap(find.text('Gia hạn'));
        await tester.pumpAndSettle();

        expect(find.text('Gia hạn phiếu mượn'), findsOneWidget);
        expect(find.text('Xác nhận'), findsOneWidget);
        expect(find.text('7 ngày'), findsWidgets); // Giá trị mặc định 7 ngày

        // Bấm Xác nhận gia hạn
        await tester.tap(find.text('Xác nhận'));
        await tester.pumpAndSettle();

        // Kiểm tra gọi API và cập nhật UI từ Backend
        expect(repository.renewSlipCallCount, 1);
        expect(repository.lastRenewSlipExtraDays, 7);
        expect(find.text('Số lần đã gia hạn: 1'), findsOneWidget);
        expect(find.text('Gia hạn phiếu mượn thành công'), findsOneWidget);
      },
    );

    testWidgets(
      'canRenew == false (ACTIVE_RESERVATION) | Khóa nút Gia hạn và hiển thị lý do',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'user-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 1,
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'ACTIVE_RESERVATION',
            message: 'Sách đang có người đặt trước, không thể gia hạn.',
          ),
          items: const [],
        );

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        expect(find.text('Số lần đã gia hạn: 1'), findsOneWidget);
        expect(
          find.text('Sách đang có người đặt trước, không thể gia hạn.'),
          findsOneWidget,
        );

        // Nút Gia hạn bị disabled (onPressed == null)
        final filledButtonFinder = find.widgetWithText(FilledButton, 'Gia hạn');
        expect(filledButtonFinder, findsOneWidget);
        final filledButton = tester.widget<FilledButton>(filledButtonFinder);
        expect(filledButton.onPressed, isNull);
      },
    );

    testWidgets(
      'canRenew == false (MAX_RENEWALS_REACHED) | Khóa nút và hiển thị lý do map từ code',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'user-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 2,
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'MAX_RENEWALS_REACHED',
          ),
          items: const [],
        );

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Đã đạt giới hạn số lần gia hạn cho phép.'),
          findsOneWidget,
        );
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gia hạn'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'canRenew == null | Hiển thị nút Kiểm tra gia hạn và không cho phép PATCH trực tiếp',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'user-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: null, // canRenew == null
          items: const [],
        );

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        // Không hiển thị nút Gia hạn trực tiếp
        expect(find.widgetWithText(FilledButton, 'Gia hạn'), findsNothing);
        // Hiển thị nút Kiểm tra gia hạn
        expect(find.text('Kiểm tra gia hạn'), findsOneWidget);

        // Nhấn nút Kiểm tra gia hạn
        await tester.tap(find.text('Kiểm tra gia hạn'));
        await tester.pumpAndSettle();

        // Tuyệt đối không gọi renewSlip PATCH
        expect(repository.renewSlipCallCount, 0);
      },
    );

    testWidgets(
      'Trạng thái COMPLETED / REJECTED / CANCELLED | Không hiển thị thao tác gia hạn',
      (tester) async {
        final repository = FakeBorrowingRepository();

        for (final status in ['COMPLETED', 'REJECTED', 'CANCELLED']) {
          repository.fakeSlipDetail = BorrowingSlip(
            id: 'slip-01',
            slipNumber: 'SLIP-2026-0001',
            memberId: 'user-01',
            status: status,
            dueDate: DateTime.utc(2026, 11, 15),
            renewCount: 0,
            renewalEligibility: const RenewalEligibility(canRenew: true),
            items: const [],
          );

          await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
          await tester.pumpAndSettle();

          expect(
            find.text('Gia hạn'),
            findsNothing,
            reason: 'Không được hiện nút Gia hạn với status $status',
          );
          expect(
            find.text('Kiểm tra gia hạn'),
            findsNothing,
            reason: 'Không được hiện nút Kiểm tra gia hạn với status $status',
          );
        }
      },
    );

    testWidgets(
      'MEMBER chỉ thấy thao tác phù hợp, không thấy nút quản lý',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'user-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          totalFine: 20000,
          finePaid: false,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [
            BorrowingSlipItem(
              id: 'it-1',
              bookId: 'b-1',
              bookTitle: 'Clean Code',
              quantity: 1,
              status: 'BORROWING',
            ),
          ],
        );

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        // MEMBER thấy nút Gia hạn cho phiếu của mình
        expect(find.text('Gia hạn'), findsOneWidget);

        // MEMBER KHÔNG thấy các thao tác của thủ thư
        expect(find.text('Duyệt phiếu'), findsNothing);
        expect(find.text('Từ chối'), findsNothing);
        expect(find.text('Xác nhận trả sách'), findsNothing);
        expect(find.text('Ghi nhận đã thu tiền phạt'), findsNothing);
      },
    );

    testWidgets(
      'MEMBER xem phiếu của độc giả khác | Không thấy thao tác gia hạn',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'other-member', // Không phải user-01
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        await tester.pumpWidget(
          createApp(repository, role: 'MEMBER', userId: 'user-01'),
        );
        await tester.pumpAndSettle();

        // Không thấy nút Gia hạn
        expect(find.text('Gia hạn'), findsNothing);
      },
    );
  });
}
