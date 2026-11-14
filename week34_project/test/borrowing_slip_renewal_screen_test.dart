import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/pages/borrowing_slip_detail_screen.dart';
import 'package:week34_project/features/members/data/member_resolver.dart';
import 'package:week34_project/features/members/data/members_repository.dart';
import 'package:week34_project/features/members/data/models/member.dart';
import 'package:week34_project/features/borrowing/renewal/models/renewal_eligibility.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_members_repository.dart';
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
    String userId = 'acc-01',
    String? memberId = 'mem-01',
    MembersRepository? membersRepository,
    MemberResolver? memberResolver,
  }) {
    authBloc.emit(
      AuthAuthenticated(
        user: UserProfile(
          id: userId,
          memberId: memberId,
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
            membersRepository: membersRepository,
            memberResolver: memberResolver,
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
          memberId: 'mem-01',
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
        expect(find.text('Xác nhận gia hạn'), findsOneWidget);
        expect(find.text('7 ngày (mặc định)'), findsOneWidget); // Giá trị mặc định 7 ngày

        // Bấm Xác nhận gia hạn
        await tester.tap(find.text('Xác nhận gia hạn'));
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
          memberId: 'mem-01',
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
          memberId: 'mem-01',
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
          memberId: 'mem-01',
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
            memberId: 'mem-01',
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
          memberId: 'mem-01',
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
      'P1: user.id != user.memberId | Trùng user.memberId thì hiện nút Gia hạn',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        await tester.pumpWidget(
          createApp(
            repository,
            role: 'MEMBER',
            userId: 'acc-01',
            memberId: 'mem-01',
          ),
        );
        await tester.pumpAndSettle();

        // Khớp user.memberId -> hiển thị nút Gia hạn
        expect(find.text('Gia hạn'), findsOneWidget);
      },
    );

    testWidgets(
      'P1: user.id != user.memberId | Trùng user.id nhưng khác user.memberId thì KHÔNG hiện nút',
      (tester) async {
        final repository = FakeBorrowingRepository();
        // slip.memberId trùng user.id ('acc-01') nhưng khác user.memberId ('mem-01')
        // Lỗi cũ sẽ so sánh slip.memberId == user.id nên cho phép nhầm, sửa đúng phải KHÔNG hiện nút.
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'acc-01', // Trùng user.id nhưng không phải memberId thực
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        await tester.pumpWidget(
          createApp(
            repository,
            role: 'MEMBER',
            userId: 'acc-01',
            memberId: 'mem-01',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gia hạn'), findsNothing);
      },
    );

    testWidgets(
      'P1: user.memberId == null | Dùng MemberResolver tra cứu thành công -> Hiện nút Gia hạn',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-resolved-99',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        final membersRepository = FakeMembersRepository(
          members: [
            Member(
              id: 'mem-resolved-99',
              fullName: 'Độc giả kiểm thử',
              email: 'test@librio.vn',
              cardNumber: 'CARD-99',
              status: 'ACTIVE',
              membershipExpiry: DateTime(2027, 1, 1),
            ),
          ],
        );

        await tester.pumpWidget(
          createApp(
            repository,
            role: 'MEMBER',
            userId: 'acc-01',
            memberId: null, // Không có sẵn memberId trên user
            membersRepository: membersRepository,
          ),
        );
        await tester.pumpAndSettle();

        // MemberResolver tìm thấy memberId 'mem-resolved-99' trùng với slip -> hiển thị nút Gia hạn
        expect(find.text('Gia hạn'), findsOneWidget);
      },
    );

    testWidgets(
      'P1: user.memberId == null và không tra cứu được | Fail-closed, KHÔNG hiện nút Gia hạn',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        final membersRepository = FakeMembersRepository(members: []);

        await tester.pumpWidget(
          createApp(
            repository,
            role: 'MEMBER',
            userId: 'acc-01',
            memberId: null, // Không xác định được
            membersRepository: membersRepository,
          ),
        );
        await tester.pumpAndSettle();

        // Không xác định được owner -> Fail-closed, không hiện nút Gia hạn
        expect(find.text('Gia hạn'), findsNothing);
      },
    );

    testWidgets(
      'P2: PATCH thành công nhưng GET refresh thất bại | Vẫn giữ kết quả thành công, không chuyển sang màn hình lỗi',
      (tester) async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        int getSlipCalls = 0;
        repository.fakeSlipDetailBuilder = (slipId) {
          getSlipCalls++;
          if (getSlipCalls <= 2) {
            // Lần 1: Load ban đầu của FutureBuilder
            // Lần 2: Pre-check eligibility của RenewSlipBloc
            return initialSlip;
          }
          // Lần 3+: Khi refresh ngầm sau PATCH thành công -> ném lỗi mạng
          throw DioException(
            requestOptions: RequestOptions(path: '/borrowing-slips/slip-01'),
            type: DioExceptionType.connectionError,
          );
        };

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        expect(find.text('Số lần đã gia hạn: 0'), findsOneWidget);

        // Bấm Gia hạn -> Mở dialog
        await tester.tap(find.text('Gia hạn'));
        await tester.pumpAndSettle();

        // Xác nhận gia hạn
        await tester.tap(find.text('Xác nhận gia hạn'));
        await tester.pumpAndSettle();

        // Kiểm tra kết quả: renewSlip đã gọi thành công
        expect(repository.renewSlipCallCount, 1);

        // Quan trọng nhất: Màn hình KHÔNG được hiển thị "Không thể tải chi tiết phiếu"
        expect(find.text('Không thể tải chi tiết phiếu'), findsNothing);

        // Màn hình vẫn giữ nguyên kết quả thành công (renewCount: 1, toast thành công)
        expect(find.text('Số lần đã gia hạn: 1'), findsOneWidget);
        expect(find.text('Gia hạn phiếu mượn thành công'), findsOneWidget);
      },
    );

    testWidgets(
      'RN2 UX | Chọn lựa chọn nhanh 3 ngày và 14 ngày | Cập nhật hạn trả dự kiến và không tự gọi API',
      (tester) async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );
        repository.fakeSlipDetail = initialSlip;

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Gia hạn'));
        await tester.pumpAndSettle();

        // Ban đầu mặc định 7 ngày, hạn trả hiện tại 15/11/2026, dự kiến 22/11/2026
        expect(find.text('Hạn trả hiện tại:'), findsOneWidget);
        expect(find.text('15/11/2026'), findsOneWidget);
        expect(find.text('22/11/2026'), findsOneWidget);

        // Chuyển sang 3 ngày
        await tester.tap(find.text('3 ngày'));
        await tester.pumpAndSettle();

        // Không tự động gọi API khi chỉ đổi lựa chọn
        expect(repository.renewSlipCallCount, 0);
        // Hạn trả dự kiến cập nhật thành 18/11/2026
        expect(find.text('18/11/2026'), findsOneWidget);

        // Chuyển sang 14 ngày
        await tester.tap(find.text('14 ngày (tối đa)'));
        await tester.pumpAndSettle();
        expect(repository.renewSlipCallCount, 0);
        expect(find.text('29/11/2026'), findsOneWidget);

        // Xác nhận gia hạn 14 ngày
        await tester.tap(find.text('Xác nhận gia hạn'));
        await tester.pumpAndSettle();

        expect(repository.renewSlipCallCount, 1);
        expect(repository.lastRenewSlipExtraDays, 14);
      },
    );

    testWidgets(
      'RN2 UX | Chọn Số ngày khác | Validation 1–14 khóa/mở nút Xác nhận gia hạn',
      (tester) async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );
        repository.fakeSlipDetail = initialSlip;

        await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Gia hạn'));
        await tester.pumpAndSettle();

        // Chọn Số ngày khác
        await tester.tap(find.text('Số ngày khác'));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('renew_custom_input')), findsOneWidget);

        // Khi chưa nhập số, nút Xác nhận bị disable
        final confirmBtnFinder = find.byKey(const ValueKey('confirm_renew_button'));
        expect(tester.widget<FilledButton>(confirmBtnFinder).onPressed, isNull);
        expect(find.text('---'), findsOneWidget);

        // Nhập 0 (không hợp lệ) -> vẫn disabled
        await tester.enterText(find.byKey(const ValueKey('renew_custom_input')), '0');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(confirmBtnFinder).onPressed, isNull);
        expect(find.text('Số ngày phải từ 1 đến 14'), findsOneWidget);

        // Nhập 15 (vượt quá 14) -> disabled
        await tester.enterText(find.byKey(const ValueKey('renew_custom_input')), '15');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(confirmBtnFinder).onPressed, isNull);
        expect(find.text('Số ngày phải từ 1 đến 14'), findsOneWidget);

        // Nhập 5 (hợp lệ) -> enabled, hạn trả dự kiến 20/11/2026
        await tester.enterText(find.byKey(const ValueKey('renew_custom_input')), '5');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(confirmBtnFinder).onPressed, isNotNull);
        expect(find.text('20/11/2026'), findsOneWidget);

        // Xác nhận
        await tester.tap(confirmBtnFinder);
        await tester.pumpAndSettle();

        expect(repository.renewSlipCallCount, 1);
        expect(repository.lastRenewSlipExtraDays, 5);
      },
    );
  });
}
