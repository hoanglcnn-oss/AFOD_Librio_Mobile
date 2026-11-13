import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/reservations/data/models/reservation.dart';
import 'package:week34_project/features/reservations/presentation/pages/my_reservations_screen.dart';
import 'package:week34_project/features/reservations/presentation/widgets/reservation_card.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_reservations_repository.dart';
import 'fake/fake_token_storage.dart';

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
        reservationNumber: 'RSV-001',
        memberId: 'mem-01',
        bookId: 'b-1',
        bookTitle: 'Clean Code',
        status: 'PENDING',
        reservationDate: DateTime(2026, 11, 10),
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
        reservationNumber: 'RSV-002',
        memberId: 'mem-01',
        bookId: 'b-2',
        bookTitle: 'Refactoring',
        status: 'READY',
        reservationDate: DateTime(2026, 11, 10),
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

    testWidgets('FULFILLED, CANCELLED, EXPIRED | Chỉ xem lịch sử, KHÔNG có nút Hủy đặt trước', (tester) async {
      final fulfilledRes = Reservation(
        id: 'res-3',
        reservationNumber: 'RSV-003',
        memberId: 'mem-01',
        bookId: 'b-3',
        bookTitle: 'Book 3',
        status: 'FULFILLED',
        reservationDate: DateTime(2026, 11, 1),
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
        reservationNumber: 'RSV-004',
        memberId: 'mem-01',
        bookId: 'b-4',
        bookTitle: 'Book 4',
        status: 'CANCELLED',
        reservationDate: DateTime(2026, 11, 1),
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
        reservationNumber: 'RSV-005',
        memberId: 'mem-01',
        bookId: 'b-5',
        bookTitle: 'Book 5',
        status: 'EXPIRED',
        reservationDate: DateTime(2026, 10, 1),
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
        reservationNumber: 'RSV-001',
        memberId: 'mem-other',
        bookId: 'b-1',
        bookTitle: 'Clean Code',
        status: 'PENDING',
        reservationDate: DateTime(2026, 11, 10),
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
        reservationNumber: 'RSV-001',
        memberId: 'mem-01',
        bookId: 'b-1',
        bookTitle: 'Clean Code',
        status: 'PENDING',
        reservationDate: DateTime(2026, 11, 10),
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
            reservationNumber: 'RSV-001',
            memberId: 'mem-01',
            bookId: 'book-01',
            bookTitle: 'Clean Architecture',
            status: 'PENDING',
            reservationDate: DateTime(2026, 11, 10),
          ),
          Reservation(
            id: 'res-02',
            reservationNumber: 'RSV-002',
            memberId: 'mem-01',
            bookId: 'book-02',
            bookTitle: 'The Pragmatic Programmer',
            status: 'READY',
            reservationDate: DateTime(2026, 11, 11),
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

      // Bấm nút Hủy đặt trước cho cuốn 1
      final cancelButtons = find.widgetWithText(OutlinedButton, 'Hủy đặt trước');
      expect(cancelButtons, findsNWidgets(2));

      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Kiểm tra dialog xác nhận mở ra
      expect(find.text('Hủy đặt trước'), findsWidgets);
      expect(find.textContaining('Bạn có chắc chắn muốn hủy đặt trước cuốn sách "Clean Architecture"?'), findsOneWidget);
      expect(find.text('Lý do hủy (tùy chọn)'), findsOneWidget);

      // Bấm đóng dialog -> không gọi API hủy
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(reservationsRepository.cancelCallCount, 0);

      // Mở lại dialog và xác nhận hủy
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Nhập lý do hủy
      await tester.enterText(find.byType(TextField), 'Thay đổi kế hoạch học tập');
      await tester.pumpAndSettle();

      // Xác nhận hủy
      await tester.tap(find.text('Xác nhận hủy'));
      await tester.pumpAndSettle();

      expect(reservationsRepository.cancelCallCount, 1);
      expect(find.text('Hủy đặt trước thành công'), findsOneWidget);

      // Cuốn 1 giờ đã chuyển sang trạng thái Đã hủy
      expect(find.text('Đã hủy'), findsOneWidget);
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
  });
}
