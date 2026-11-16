import 'package:flutter_test/flutter_test.dart';

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

  group('MembersRepository.resolveMemberId', () {
    // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
    test(
      'resolveMemberId | Role MEMBER và có memberId | trả ID trực tiếp, không gọi Repository',
      () async {
        final repository = FakeMembersRepository();

        final result = await repository.resolveMemberId(
          memberId: 'mem-01',
          email: 'an@example.com',
          role: 'MEMBER',
        );

        expect(result, 'mem-01');
        expect(repository.callCount, 0);
      },
    );

    test(
      'resolveMemberId | Role MEMBER thiếu memberId | tìm bằng email, trả đúng ID',
      () async {
        final repository = FakeMembersRepository(members: [sampleMember]);

        final result = await repository.resolveMemberId(
          memberId: null,
          email: 'AN@EXAMPLE.COM',
          role: 'MEMBER',
        );

        expect(result, 'mem-01');
        expect(repository.callCount, 1);
      },
    );

    test('resolveMemberId | Không tìm thấy Member | trả null', () async {
      final repository = FakeMembersRepository();

      final result = await repository.resolveMemberId(
        memberId: null,
        email: 'unknown@example.com',
        role: 'MEMBER',
      );

      expect(result, isNull);
    });

    test(
      'resolveMemberId | Role ADMIN dù có memberId | trả null, không gọi Repository',
      () async {
        final repository = FakeMembersRepository(members: [sampleMember]);

        final result = await repository.resolveMemberId(
          memberId: 'mem-01',
          email: 'an@example.com',
          role: 'ADMIN',
        );

        expect(result, isNull);
        expect(repository.callCount, 0);
      },
    );

    test(
      'resolveMemberId | Repository ném lỗi | truyền exception lên tầng gọi',
      () async {
        final repository = FakeMembersRepository(shouldFail: true);

        await expectLater(
          repository.resolveMemberId(
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
