import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/models/renewal_eligibility.dart';

void main() {
  group('RenewalEligibility', () {
    test('Parse eligibility hợp lệ | canRenew = true, reasonCode và message là null', () {
      final json = {
        'canRenew': true,
        'reasonCode': null,
        'message': null,
      };

      final eligibility = RenewalEligibility.fromJson(json);

      expect(eligibility.canRenew, isTrue);
      expect(eligibility.reasonCode, isNull);
      expect(eligibility.message, isNull);
    });

    test('Parse eligibility bị chặn | canRenew = false kèm reasonCode và message', () {
      final json = {
        'canRenew': false,
        'reasonCode': 'MAX_RENEWALS_REACHED',
        'message': 'Đã đạt số lần gia hạn tối đa cho phép',
      };

      final eligibility = RenewalEligibility.fromJson(json);

      expect(eligibility.canRenew, isFalse);
      expect(eligibility.reasonCode, 'MAX_RENEWALS_REACHED');
      expect(eligibility.message, 'Đã đạt số lần gia hạn tối đa cho phép');
    });

    test('Parse eligibility thiếu trường tùy chọn | Fallback an toàn', () {
      final json = {
        'canRenew': true,
      };

      final eligibility = RenewalEligibility.fromJson(json);

      expect(eligibility.canRenew, isTrue);
      expect(eligibility.reasonCode, isNull);
      expect(eligibility.message, isNull);
    });

    test('Parse eligibility khi map rỗng | canRenew mặc định là false', () {
      final json = <String, dynamic>{};

      final eligibility = RenewalEligibility.fromJson(json);

      expect(eligibility.canRenew, isFalse);
      expect(eligibility.reasonCode, isNull);
      expect(eligibility.message, isNull);
    });

    test('Parse eligibility từ nested renewalEligibility / eligibility', () {
      final nested1 = {
        'renewalEligibility': {
          'canRenew': false,
          'reasonCode': 'OVERDUE',
          'message': 'Sách đã quá hạn',
        },
      };

      final eligibility1 = RenewalEligibility.fromJson(nested1);
      expect(eligibility1.canRenew, isFalse);
      expect(eligibility1.reasonCode, 'OVERDUE');
      expect(eligibility1.message, 'Sách đã quá hạn');

      final nested2 = {
        'eligibility': {
          'canRenew': true,
          'reason': null,
        },
      };

      final eligibility2 = RenewalEligibility.fromJson(nested2);
      expect(eligibility2.canRenew, isTrue);
      expect(eligibility2.reasonCode, isNull);
    });

    test('toJson và Equatable props so sánh đúng', () {
      const e1 = RenewalEligibility(
        canRenew: false,
        reasonCode: 'OVERDUE',
        message: 'Quá hạn',
      );
      const e2 = RenewalEligibility(
        canRenew: false,
        reasonCode: 'OVERDUE',
        message: 'Quá hạn',
      );
      const e3 = RenewalEligibility(
        canRenew: true,
      );

      expect(e1, equals(e2));
      expect(e1 == e3, isFalse);

      final json = e1.toJson();
      expect(json['canRenew'], isFalse);
      expect(json['reasonCode'], 'OVERDUE');
      expect(json['message'], 'Quá hạn');
    });
  });
}
