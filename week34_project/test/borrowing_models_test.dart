import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing_slip.dart';
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
    },
  );

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
}
