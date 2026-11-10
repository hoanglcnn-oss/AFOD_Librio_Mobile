import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/members/data/models/member.dart';

import 'fake/fake_members_repository.dart';

void main() {
  final member = Member(
    id: 'mem-01',
    email: 'an@example.com',
    fullName: 'Nguyễn Văn An',
    cardNumber: 'LIB-2026-0001',
    status: 'ACTIVE',
    membershipExpiry: DateTime.utc(2027, 10, 28),
  );

  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'findByEmail | Email có khoảng trắng và chữ hoa | trả đúng Member, gọi 1 lần',
    () async {
      final repository = FakeMembersRepository(members: [member]);

      final result = await repository.findByEmail('  AN@EXAMPLE.COM  ');

      expect(result?.id, 'mem-01');
      expect(repository.callCount, 1);
    },
  );

  test('findByEmail | Email không khớp | trả null', () async {
    final repository = FakeMembersRepository(members: [member]);

    final result = await repository.findByEmail('other@example.com');

    expect(result, isNull);
  });
}
