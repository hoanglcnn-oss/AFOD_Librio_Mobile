import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowing_slips/data/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

void main() {
  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'CreateBorrowingRequest.toJson | Request không có notes | JSON có memberId, bookId và durationDays mặc định',
    () {
      const request = CreateBorrowingRequest(
        memberId: 'mem-01',
        bookId: 'book-01',
      );

      final json = request.toJson();

      expect(json['memberId'], 'mem-01');
      expect(json['bookId'], 'book-01');
      expect(json['durationDays'], 14);
      expect(json.containsKey('notes'), false);
    },
  );

  test(
    'Borrowing.fromJson | Response mượn sách hợp lệ | parse đúng ID, tên sách, status và dueDate',
    () {
      final json = {
        'id': 'brw-01',
        'transactionCode': 'BRW-2026-0001',
        'memberId': 'mem-01',
        'memberName': 'Nguyễn Văn An',
        'bookId': 'book-01',
        'bookTitle': 'Clean Code',
        'borrowDate': '2026-10-29T08:00:00.000Z',
        'dueDate': '2026-11-12T08:00:00.000Z',
        'status': 'BORROWED',
      };

      final borrowing = Borrowing.fromJson(json);

      expect(borrowing.id, 'brw-01');
      expect(borrowing.bookTitle, 'Clean Code');
      expect(borrowing.status, 'BORROWED');
      expect(borrowing.dueDate.day, 12);
    },
  );
  test(
    'Borrowing.fromJson | Có thông tin Renew và Fine | parse đúng renewCount, returnDate, fineAmount và finePaid',
    () {
      final borrowing = Borrowing.fromJson({
        'id': 'brw-01',
        'transactionCode': 'BRW-2026-0001',
        'memberId': 'mem-01',
        'memberName': 'Nguyễn Văn An',
        'bookId': 'book-01',
        'bookTitle': 'Clean Code',
        'borrowDate': '2026-11-01T08:00:00Z',
        'dueDate': '2026-11-15T08:00:00Z',
        'returnDate': null,
        'renewCount': 1,
        'fineAmount': 0,
        'finePaid': false,
        'status': 'BORROWED',
      });

      expect(borrowing.renewCount, 1);
      expect(borrowing.returnDate, isNull);
      expect(borrowing.fineAmount, 0);
      expect(borrowing.finePaid, false);
      expect(borrowing.canRenew, isNull); // Chưa tải eligibility
    },
  );

  group('Borrowing renewal eligibility tri-state', () {
    test('canRenew == null khi không có trường eligibility trong JSON (danh sách)', () {
      final borrowing = Borrowing.fromJson({
        'id': 'brw-01',
        'transactionCode': 'BRW-2026-0001',
        'memberId': 'mem-01',
        'bookId': 'book-01',
        'bookTitle': 'Clean Code',
        'borrowDate': '2026-11-01T08:00:00Z',
        'dueDate': '2026-11-15T08:00:00Z',
        'status': 'BORROWED',
      });

      expect(borrowing.renewalEligibility, isNull);
      expect(borrowing.canRenew, isNull);
      expect(borrowing.renewalReasonCode, isNull);
      expect(borrowing.renewalMessage, isNull);
    });

    test('canRenew == true khi Backend cho phép gia hạn', () {
      final borrowing = Borrowing.fromJson({
        'id': 'brw-01',
        'transactionCode': 'BRW-2026-0001',
        'memberId': 'mem-01',
        'bookId': 'book-01',
        'bookTitle': 'Clean Code',
        'borrowDate': '2026-11-01T08:00:00Z',
        'dueDate': '2026-11-15T08:00:00Z',
        'status': 'BORROWED',
        'renewalEligibility': {
          'canRenew': true,
          'message': 'Đủ điều kiện gia hạn',
        },
      });

      expect(borrowing.canRenew, isTrue);
      expect(borrowing.renewalMessage, 'Đủ điều kiện gia hạn');
    });

    test('canRenew == false khi Backend từ chối gia hạn kèm reasonCode và message', () {
      final borrowing = Borrowing.fromJson({
        'id': 'brw-01',
        'transactionCode': 'BRW-2026-0001',
        'memberId': 'mem-01',
        'bookId': 'book-01',
        'bookTitle': 'Clean Code',
        'borrowDate': '2026-11-01T08:00:00Z',
        'dueDate': '2026-11-15T08:00:00Z',
        'status': 'BORROWED',
        'renewalEligibility': {
          'canRenew': false,
          'reasonCode': 'ACTIVE_RESERVATION',
          'message': 'Sách đang có người đặt trước',
        },
      });

      expect(borrowing.canRenew, isFalse);
      expect(borrowing.renewalReasonCode, 'ACTIVE_RESERVATION');
      expect(borrowing.renewalMessage, 'Sách đang có người đặt trước');
    });

    test('copyWith cập nhật đúng các trường', () {
      final original = Borrowing(
        id: 'brw-01',
        transactionCode: 'BRW-2026-0001',
        memberId: 'mem-01',
        memberName: 'Nguyễn Văn An',
        bookId: 'book-01',
        bookTitle: 'Clean Code',
        borrowDate: DateTime.utc(2026, 11, 1),
        dueDate: DateTime.utc(2026, 11, 15),
        status: 'BORROWED',
      );

      final updated = original.copyWith(
        status: 'RETURNED',
        renewCount: 2,
      );

      expect(updated.id, 'brw-01');
      expect(updated.status, 'RETURNED');
      expect(updated.renewCount, 2);
      expect(updated.bookTitle, 'Clean Code');
    });
  });

  test(
    'BorrowingSlip.fromJson | Phiếu có 1 dòng sách | parse đúng thông tin phiếu và BorrowingSlipItem',
    () {
      final json = {
        'id': 'slip-01',
        'slipNumber': 'SLIP-2026-001',
        'memberId': 'mem-01',
        'status': 'PENDING_APPROVAL',
        'dueDate': '2026-11-20T10:00:00.000Z',
        'items': [
          {
            'id': 'item-01',
            'bookId': 'book-01',
            'bookTitle': 'Refactoring',
            'quantity': 2,
            'status': 'BORROWED',
          },
        ],
      };

      final slip = BorrowingSlip.fromJson(json);

      expect(slip.id, 'slip-01');
      expect(slip.slipNumber, 'SLIP-2026-001');
      expect(slip.memberId, 'mem-01');
      expect(slip.status, 'PENDING_APPROVAL');
      expect(slip.dueDate.day, 20);
      expect(slip.items.length, 1);

      final item = slip.items.first;
      expect(item.id, 'item-01');
      expect(item.bookId, 'book-01');
      expect(item.bookTitle, 'Refactoring');
      expect(item.quantity, 2);
      expect(item.status, 'BORROWED');
    },
  );

  test(
    'BorrowingSlip.fromJson | Phiếu đã trả quá hạn | parse đúng trạng thái từng sách và tiền phạt',
    () {
      final slip = BorrowingSlip.fromJson({
        'id': 'slip-01',
        'slipNumber': 'SLIP-2026-0001',
        'memberId': 'mem-01',
        'status': 'COMPLETED',
        'dueDate': '2026-11-15T08:00:00Z',
        'borrowDate': '2026-11-01T08:00:00Z',
        'totalFine': 25000,
        'finePaid': false,
        'renewCount': 0,
        'items': [
          {
            'id': 'item-A',
            'bookId': 'book-A',
            'bookTitle': 'Sách A',
            'quantity': 1,
            'returnedQuantity': 1,
            'status': 'RETURNED',
            'returnDate': '2026-11-14T08:00:00Z',
            'lateFee': 0,
            'fineAmount': 0,
          },
          {
            'id': 'item-B',
            'bookId': 'book-B',
            'bookTitle': 'Sách B',
            'quantity': 1,
            'returnedQuantity': 1,
            'status': 'RETURNED',
            'returnDate': '2026-11-15T08:00:00Z',
            'lateFee': 0,
            'fineAmount': 0,
          },
          {
            'id': 'item-C',
            'bookId': 'book-C',
            'bookTitle': 'Sách C',
            'quantity': 1,
            'returnedQuantity': 1,
            'status': 'RETURNED',
            'returnDate': '2026-11-20T08:00:00Z',
            'lateFee': 25000,
            'fineAmount': 25000,
          },
        ],
      });

      expect(slip.status, 'COMPLETED');
      expect(slip.totalFine, 25000);
      expect(slip.finePaid, false);
      expect(slip.items.length, 3);

      expect(slip.items[0].lateFee, 0);
      expect(slip.items[1].lateFee, 0);
      expect(slip.items[2].lateFee, 25000);

      expect(slip.items[2].returnedQuantity, 1);
      expect(slip.items[2].remainingQuantity, 0);
      expect(slip.items[2].returnDate, isNotNull);
    },
  );

  group('BorrowingSlip member mapping', () {
    test(
      'BorrowingSlip.fromJson | Có member object lồng nhau | parse đúng memberName và memberCardNumber',
      () {
        final slip = BorrowingSlip.fromJson({
          'id': 'slip-nested',
          'slipNumber': 'SLIP-001',
          'memberId': 'mem-01',
          'member': {'fullName': 'Nguyễn Văn An', 'cardNumber': 'CARD-999'},
          'status': 'PENDING_APPROVAL',
          'dueDate': '2026-11-20T08:00:00Z',
          'items': [],
        });

        expect(slip.memberName, 'Nguyễn Văn An');
        expect(slip.memberCardNumber, 'CARD-999');
      },
    );

    test(
      'BorrowingSlip.fromJson | Có memberName/memberCardNumber phẳng | parse đúng thông tin độc giả',
      () {
        final slip = BorrowingSlip.fromJson({
          'id': 'slip-flat',
          'slipNumber': 'SLIP-002',
          'memberId': 'mem-02',
          'memberName': 'Trần Thị Bình',
          'memberCardNumber': 'CARD-888',
          'status': 'BORROWED',
          'dueDate': '2026-11-20T08:00:00Z',
          'items': [],
        });

        expect(slip.memberName, 'Trần Thị Bình');
        expect(slip.memberCardNumber, 'CARD-888');
      },
    );

    test(
      'BorrowingSlip.fromJson | Không có thông tin member | memberName và memberCardNumber là null',
      () {
        final slip = BorrowingSlip.fromJson({
          'id': 'slip-none',
          'slipNumber': 'SLIP-003',
          'memberId': 'mem-03',
          'status': 'BORROWED',
          'dueDate': '2026-11-20T08:00:00Z',
          'items': [],
        });

        expect(slip.memberName, isNull);
        expect(slip.memberCardNumber, isNull);
      },
    );
  });
}
