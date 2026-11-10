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
    // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
    test(
      'resolve | Role MEMBER và có memberId | trả ID trực tiếp, không gọi Repository',
      () async {
        final repository = FakeMembersRepository();

        final resolver = MemberResolver(membersRepository: repository);

        final result = await resolver.resolve(
          memberId: 'mem-01',
          email: 'an@example.com',
          role: 'MEMBER',
        );

        expect(result, 'mem-01');
        expect(repository.callCount, 0);
      },
    );

    test(
      'resolve | Role MEMBER thiếu memberId | tìm bằng email, trả đúng ID',
      () async {
        final repository = FakeMembersRepository(members: [sampleMember]);

        final resolver = MemberResolver(membersRepository: repository);

        final result = await resolver.resolve(
          memberId: null,
          email: 'AN@EXAMPLE.COM',
          role: 'MEMBER',
        );

        expect(result, 'mem-01');
        expect(repository.callCount, 1);
      },
    );

    test('resolve | Không tìm thấy Member | trả null', () async {
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

    test(
      'resolve | Role ADMIN dù có memberId | trả null, không gọi Repository',
      () async {
        final repository = FakeMembersRepository(members: [sampleMember]);

        final resolver = MemberResolver(membersRepository: repository);

        final result = await resolver.resolve(
          memberId: 'mem-01',
          email: 'an@example.com',
          role: 'ADMIN',
        );

        expect(result, isNull);
        expect(repository.callCount, 0);
      },
    );

    test(
      'resolve | Repository ném lỗi | truyền exception lên tầng gọi',
      () async {
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
      },
    );
  });
}
