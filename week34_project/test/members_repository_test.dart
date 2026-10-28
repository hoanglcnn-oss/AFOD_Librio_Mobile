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

  test('findByEmail tìm đúng email, không phân biệt hoa thường', () async {
    final repository = FakeMembersRepository(members: [member]);

    final result = await repository.findByEmail('  AN@EXAMPLE.COM  ');

    expect(result?.id, 'mem-01');
    expect(repository.callCount, 1);
  });

  test('findByEmail trả null khi email không khớp', () async {
    final repository = FakeMembersRepository(members: [member]);

    final result = await repository.findByEmail('other@example.com');

    expect(result, isNull);
  });
}
