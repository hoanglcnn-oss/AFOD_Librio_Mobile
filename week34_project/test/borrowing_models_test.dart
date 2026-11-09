import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

void main() {
  test('CreateBorrowingRequest chuyển đúng thành JSON', () {
    const request = CreateBorrowingRequest(
      memberId: 'mem-01',
      bookId: 'book-01',
    );

    final json = request.toJson();

    expect(json['memberId'], 'mem-01');
    expect(json['bookId'], 'book-01');
    expect(json['durationDays'], 14);
    expect(json.containsKey('notes'), false);
  });

  test('Borrowing parse đúng response JSON', () {
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
  });
  test('Borrowing parse renewCount và return/fine fields', () {
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
  });
}
