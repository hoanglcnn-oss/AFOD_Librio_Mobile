import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/members/data/member_resolver.dart';
import 'package:week34_project/features/members/data/models/member.dart';

import 'fake/fake_members_repository.dart';

void main() {
  final sampleMember = Member(
    id: 'mem-01',
    email: 'an@example.com',
    fullName: 'Nguyễn Văn An',
    cardNumber: 'LIB-2026-0001',
    status: 'ACTIVE',
    membershipExpiry: DateTime.utc(2027, 10, 28),
  );

  group('MemberResolver', () {
    test('Có memberId: dùng trực tiếp, không gọi API', () async {
      final repository = FakeMembersRepository();

      final resolver = MemberResolver(membersRepository: repository);

      final result = await resolver.resolve(
        memberId: 'mem-01',
        email: 'an@example.com',
        role: 'MEMBER',
      );

      expect(result, 'mem-01');
      expect(repository.callCount, 0);
    });

    test('Thiếu memberId: tìm bằng email', () async {
      final repository = FakeMembersRepository(members: [sampleMember]);

      final resolver = MemberResolver(membersRepository: repository);

      final result = await resolver.resolve(
        memberId: null,
        email: 'AN@EXAMPLE.COM',
        role: 'MEMBER',
      );

      expect(result, 'mem-01');
      expect(repository.callCount, 1);
    });

    test('Không tìm thấy Member: trả null', () async {
      final resolver = MemberResolver(
        membersRepository: FakeMembersRepository(),
      );

      final result = await resolver.resolve(
        memberId: null,
        email: 'unknown@example.com',
        role: 'MEMBER',
      );

      expect(result, isNull);
    });

    test('Admin không được resolve Member', () async {
      final repository = FakeMembersRepository(members: [sampleMember]);

      final resolver = MemberResolver(membersRepository: repository);

      final result = await resolver.resolve(
        memberId: 'mem-01',
        email: 'an@example.com',
        role: 'ADMIN',
      );

      expect(result, isNull);
      expect(repository.callCount, 0);
    });

    test('Repository lỗi: không tự tạo Member ID', () async {
      final resolver = MemberResolver(
        membersRepository: FakeMembersRepository(shouldFail: true),
      );

      await expectLater(
        resolver.resolve(
          memberId: null,
          email: 'an@example.com',
          role: 'MEMBER',
        ),
        throwsException,
      );
    });
  });
}
