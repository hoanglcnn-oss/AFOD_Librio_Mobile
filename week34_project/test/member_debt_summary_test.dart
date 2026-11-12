import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';

void main() {
  group('MemberDebtSummary', () {
    test('fromJson | Đầy đủ dữ liệu chuẩn | Parse chính xác các trường', () {
      final json = {
        'maxBorrowLimit': 5,
        'currentBorrowedCount': 3,
        'remainingBorrowLimit': 2,
        'canBorrow': true,
        'reasonIfNotAllowed': null,
        'overdueCount': 0,
        'unpaidFineAmount': 0,
      };

      final summary = MemberDebtSummary.fromJson(json);

      expect(summary.maxBorrowLimit, 5);
      expect(summary.currentBorrowedCount, 3);
      expect(summary.remainingBorrowLimit, 2);
      expect(summary.canBorrow, isTrue);
      expect(summary.reasonIfNotAllowed, isNull);
      expect(summary.overdueCount, 0);
      expect(summary.unpaidFineAmount, 0);
    });

    test('fromJson | Bọc trong data: {...} | Parse chính xác', () {
      final json = {
        'data': {
          'maxBorrowLimit': 7,
          'currentBorrowedCount': 7,
          'remainingBorrowLimit': 0,
          'canBorrow': false,
          'reasonIfNotAllowed': 'Đã đạt giới hạn tối đa',
          'overdueCount': 1,
          'unpaidFineAmount': 20000,
        },
      };

      final summary = MemberDebtSummary.fromJson(json);

      expect(summary.maxBorrowLimit, 7);
      expect(summary.currentBorrowedCount, 7);
      expect(summary.remainingBorrowLimit, 0);
      expect(summary.canBorrow, isFalse);
      expect(summary.reasonIfNotAllowed, 'Đã đạt giới hạn tối đa');
      expect(summary.overdueCount, 1);
      expect(summary.unpaidFineAmount, 20000);
    });

    test('fromJson | Thiếu một số trường | Có giá trị mặc định hợp lý', () {
      final json = {
        'currentBorrowedCount': 1,
      };

      final summary = MemberDebtSummary.fromJson(json);

      expect(summary.maxBorrowLimit, 5);
      expect(summary.currentBorrowedCount, 1);
      expect(summary.remainingBorrowLimit, 4);
      expect(summary.canBorrow, isTrue);
      expect(summary.overdueCount, 0);
      expect(summary.unpaidFineAmount, 0);
    });

    test('toJson | Chuyển đổi qua lại JSON | Giữ nguyên dữ liệu', () {
      const original = MemberDebtSummary(
        maxBorrowLimit: 5,
        currentBorrowedCount: 2,
        remainingBorrowLimit: 3,
        canBorrow: true,
        reasonIfNotAllowed: null,
        overdueCount: 0,
        unpaidFineAmount: 0,
      );

      final json = original.toJson();
      final parsed = MemberDebtSummary.fromJson(json);

      expect(parsed, equals(original));
    });
  });
}

