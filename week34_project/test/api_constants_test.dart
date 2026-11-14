import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/constants/api_constants.dart';

void main() {
  group('ApiConstants Configuration', () {
    test('baseUrl matches configured environment or defaults to production', () {
      const expectedUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.leorank.site/api',
      );

      expect(ApiConstants.baseUrl, expectedUrl);
    });

    test('baseUrl matches custom API_BASE_URL if supplied via dart-define', () {
      const customUrl = String.fromEnvironment('API_BASE_URL');
      if (customUrl.isNotEmpty) {
        expect(ApiConstants.baseUrl, customUrl);
      }
    });

    test('All endpoint paths are preserved and structured correctly', () {
      expect(ApiConstants.login, '/auth/login');
      expect(ApiConstants.register, '/auth/register');
      expect(ApiConstants.me, '/auth/me');
      expect(ApiConstants.forgotPassword, '/auth/forgot-password');
      expect(ApiConstants.books, '/books');
      expect(ApiConstants.borrowings, '/borrowings');
      expect(ApiConstants.borrowingSlips, '/borrowing-slips');
      expect(ApiConstants.members, '/members');
      expect(ApiConstants.reservations, '/reservations');
    });
  });
}
