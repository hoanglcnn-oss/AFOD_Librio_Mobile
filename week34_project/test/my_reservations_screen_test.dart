import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowing/reservations/data/models/reservation.dart';
import 'package:week34_project/features/borrowing/reservations/presentation/pages/my_reservations_screen.dart';
import 'package:week34_project/features/borrowing/reservations/presentation/widgets/reservation_card.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_members_repository.dart';
import 'fake/fake_reservations_repository.dart';
import 'fake/fake_token_storage.dart';
import 'package:week34_project/features/borrowing/create_slip/presentation/pages/borrow_confirm_screen.dart';
import 'package:week34_project/features/members/data/models/member.dart';

void main() {
  final memberUser = UserProfile(
    id: 'user-01',
    email: 'member@test.com',
    phone: '0901234567',
    fullName: 'Nguyen Van Member',
    role: 'MEMBER',
    isActive: true,
    memberId: 'mem-01',
    createdAt: DateTime(2026, 1, 1),
  );

  group('ReservationCard Component', () {
    testWidgets('PENDING status | Hiển thị badge, thông tin chờ và nút Hủy đặt trước khi là chủ sở hữu', (tester) async {
      final res = Reservation(
        id: 'res-1',
        reservationCode: 'RSV-001',
        memberId: 'mem-01',
        bookId: 'b-1',
        bookTitle: 'Clean Code',
        status: 'PENDING',
        reservedAt: DateTime(2026, 11, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: res,
              isOwner: true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Mã phiếu: RSV-001'), findsOneWidget);
      expect(find.text('Đang chờ sách'), findsOneWidget);
      expect(find.text('Đang chờ sách có sẵn từ thư viện'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsOneWidget);
    });

    testWidgets('READY status | Hiển thị thông báo sẵn sàng lấy sách và hạn lấy sách', (tester) async {
      final res = Reservation(
        id: 'res-2',
        reservationCode: 'RSV-002',
        memberId: 'mem-01',
        bookId: 'b-2',
        bookTitle: 'Refactoring',
        status: 'READY',
        reservedAt: DateTime(2026, 11, 10),
        expiresAt: DateTime(2026, 11, 15, 17, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: res,
              isOwner: true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Refactoring'), findsOneWidget);
      expect(find.text('Sẵn sàng nhận sách'), findsOneWidget);
      expect(find.text('Sách đã sẵn sàng để lấy!'), findsOneWidget);
      expect(find.textContaining('Hạn lấy sách: 15/11/2026 17:30'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsOneWidget);
    });

    testWidgets('READY status | Hiển thị nút Tạo phiếu mượn bên cạnh Hủy đặt trước khi có callback', (tester) async {
      final res = Reservation(
        id: 'res-ready',
        reservationCode: 'RSV-002',
        memberId: 'mem-01',
        bookId: 'b-2',
        bookTitle: 'Refactoring',
        status: 'READY',
        reservedAt: DateTime(2026, 11, 10),
        expiresAt: DateTime(2026, 11, 15, 17, 30),
      );

      bool onCreateSlipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: res,
              isOwner: true,
              onCreateSlip: () {
                onCreateSlipCalled = true;
              },
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_slip_btn_res-ready')), findsOneWidget);
      expect(find.text('Tạo phiếu mượn'), findsOneWidget);
      expect(find.byKey(const ValueKey('cancel_btn_res-ready')), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('create_slip_btn_res-ready')));
      expect(onCreateSlipCalled, isTrue);
    });

    testWidgets('FULFILLED, CANCELLED, EXPIRED | Chỉ xem lịch sử, KHÔNG có nút Hủy đặt trước', (tester) async {
      final fulfilledRes = Reservation(
        id: 'res-3',
        reservationCode: 'RSV-003',
        memberId: 'mem-01',
        bookId: 'b-3',
        bookTitle: 'Book 3',
        status: 'FULFILLED',
        reservedAt: DateTime(2026, 11, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: fulfilledRes,
              isOwner: true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã nhận sách'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsNothing);

      // CANCELLED
      final cancelledRes = Reservation(
        id: 'res-4',
        reservationCode: 'RSV-004',
        memberId: 'mem-01',
        bookId: 'b-4',
        bookTitle: 'Book 4',
        status: 'CANCELLED',
        reservedAt: DateTime(2026, 11, 1),
        cancellationReason: 'Độc giả tự hủy',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: cancelledRes,
              isOwner: true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.text('Lý do hủy: Độc giả tự hủy'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsNothing);

      // EXPIRED
      final expiredRes = Reservation(
        id: 'res-5',
        reservationCode: 'RSV-005',
        memberId: 'mem-01',
        bookId: 'b-5',
        bookTitle: 'Book 5',
        status: 'EXPIRED',
        reservedAt: DateTime(2026, 10, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: expiredRes,
              isOwner: true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hết hạn'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsNothing);
    });

    testWidgets('Ownership check | Không phải chủ sở hữu (isOwner = false) -> Khóa nút Hủy', (tester) async {
      final res = Reservation(
        id: 'res-1',
        reservationCode: 'RSV-001',
        memberId: 'mem-other',
        bookId: 'b-1',
        bookTitle: 'Clean Code',
        status: 'PENDING',
        reservedAt: DateTime(2026, 11, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: res,
              isOwner: false,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsNothing);
    });

    testWidgets('Librarian guard | MEMBER không thấy thao tác quản lý của thủ thư', (tester) async {
      final res = Reservation(
        id: 'res-1',
        reservationCode: 'RSV-001',
        memberId: 'mem-01',
        bookId: 'b-1',
        bookTitle: 'Clean Code',
        status: 'PENDING',
        reservedAt: DateTime(2026, 11, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: res,
              isOwner: true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duyệt'), findsNothing);
      expect(find.text('Từ chối'), findsNothing);
      expect(find.text('Hoàn tất'), findsNothing);
      expect(find.text('Quản lý'), findsNothing);
    });
  });

  group('MyReservationsScreen Integration', () {
    late FakeAuthRepository authRepository;
    late AuthBloc authBloc;
    late FakeReservationsRepository reservationsRepository;

    setUp(() {
      authRepository = FakeAuthRepository();
      authBloc = AuthBloc(
        authRepository: authRepository,
        tokenStorage: FakeTokenStorage()..savedToken = 'valid-jwt',
      )..emit(AuthAuthenticated(user: memberUser));
      reservationsRepository = FakeReservationsRepository(
        initialReservations: [
          Reservation(
            id: 'res-01',
            reservationCode: 'RSV-001',
            memberId: 'mem-01',
            bookId: 'book-01',
            bookTitle: 'Clean Architecture',
            status: 'PENDING',
            reservedAt: DateTime(2026, 11, 10),
          ),
          Reservation(
            id: 'res-02',
            reservationCode: 'RSV-002',
            memberId: 'mem-01',
            bookId: 'book-02',
            bookTitle: 'The Pragmatic Programmer',
            status: 'READY',
            reservedAt: DateTime(2026, 11, 11),
            expiresAt: DateTime(2026, 11, 18, 12, 0),
          ),
        ],
      );
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('Hiển thị danh sách đặt trước của MEMBER và hủy thành công khi xác nhận dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MyReservationsScreen(
              memberId: 'mem-01',
              repository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đặt trước của tôi'), findsOneWidget);
      expect(find.text('Clean Architecture'), findsOneWidget);
      expect(find.text('The Pragmatic Programmer'), findsOneWidget);
      expect(find.text('Sách đã sẵn sàng để lấy!'), findsOneWidget);

      final cancelButtons = find.widgetWithText(OutlinedButton, 'Hủy đặt trước');
      expect(cancelButtons, findsNWidgets(2));

      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Hủy đặt trước'), findsWidgets);
      expect(find.textContaining('Bạn có chắc chắn muốn hủy đặt trước cuốn sách "Clean Architecture"?'), findsOneWidget);
      expect(find.text('Lý do hủy (tùy chọn)'), findsOneWidget);

      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(reservationsRepository.cancelCallCount, 0);

      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Thay đổi kế hoạch học tập');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận hủy'));
      await tester.pumpAndSettle();

      expect(reservationsRepository.cancelCallCount, 1);
      expect(find.text('Hủy đặt trước thành công'), findsOneWidget);

      expect(find.text('Đã hủy'), findsOneWidget);
    });

    testWidgets('Không tin memberId truyền từ UI làm bằng chứng ownership | Không hiện nút Hủy của member khác', (tester) async {
      // Đăng nhập là mem-01, nhưng UI truyền vào memberId='victim-99'
      reservationsRepository.reservations.add(
        Reservation(
          id: 'res-victim',
          reservationCode: 'RSV-VICTIM',
          memberId: 'victim-99',
          bookId: 'book-victim',
          bookTitle: 'Victim Book',
          status: 'PENDING',
          reservedAt: DateTime(2026, 11, 10),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MyReservationsScreen(
              memberId: 'victim-99',
              repository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Victim Book'), findsOneWidget);
      // Nút Hủy đặt trước KHÔNG được hiển thị vì user đăng nhập (mem-01) không phải chủ sở hữu của victim-99
      expect(find.text('Hủy đặt trước'), findsNothing);
    });

    testWidgets('Pull-to-refresh phải đợi GET thực sự hoàn thành', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MyReservationsScreen(
              memberId: 'mem-01',
              repository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialGetCalls = reservationsRepository.getCallCount;

      // Kéo xuống để refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(reservationsRepository.getCallCount, greaterThan(initialGetCalls));
    });

    testWidgets('Hiển thị trạng thái rỗng khi không có lượt đặt trước nào', (tester) async {
      reservationsRepository.reservations.clear();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MyReservationsScreen(
              memberId: 'mem-01',
              repository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa có yêu cầu đặt trước nào'), findsOneWidget);
    });

    testWidgets('C5.5 | Nhấn Tạo phiếu mượn trên READY reservation | Mở BorrowConfirmScreen, không tự gọi POST', (tester) async {
      final fakeBorrowRepo = FakeBorrowingRepository();
      final sampleMember = Member(
        id: 'mem-01',
        fullName: 'Nguyen Van Member',
        email: 'member@test.com',
        cardNumber: 'LIB-001',
        status: 'ACTIVE',
        membershipExpiry: DateTime(2027, 1, 1),
      );
      final fakeMembersRepo = FakeMembersRepository(members: [sampleMember]);

      reservationsRepository.reservations = [
        Reservation(
          id: 'res-ready-1',
          reservationCode: 'RSV-READY',
          memberId: 'mem-01',
          bookId: 'b-ready',
          bookTitle: 'Design Patterns',
          status: 'READY',
          reservedAt: DateTime(2026, 11, 10),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MyReservationsScreen(
              memberId: 'mem-01',
              repository: reservationsRepository,
              borrowingSlipsRepository: fakeBorrowRepo,
              membersRepository: fakeMembersRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tạo phiếu mượn'), findsOneWidget);
      expect(find.text('Hủy đặt trước'), findsOneWidget);

      // Bấm nút Tạo phiếu mượn
      await tester.tap(find.text('Tạo phiếu mượn'));
      await tester.pumpAndSettle();

      // Màn hình BorrowConfirmScreen được mở
      expect(find.byType(BorrowConfirmScreen), findsOneWidget);
      expect(find.text('Xác nhận mượn sách'), findsOneWidget);
      expect(find.text('Design Patterns'), findsOneWidget);
      expect(find.text('Gửi phiếu mượn'), findsOneWidget);

      // Tuyệt đối KHÔNG tự động thực hiện POST khi vừa mở màn
      expect(fakeBorrowRepo.createSlipCallCount, 0);
      // Không chuyển reservation sang FULFILLED từ Flutter
      expect(reservationsRepository.reservations.first.status, 'READY');
    });
  });
}
