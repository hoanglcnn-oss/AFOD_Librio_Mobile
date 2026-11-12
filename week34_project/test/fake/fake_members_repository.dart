import 'package:week34_project/features/members/data/members_repository.dart';
import 'package:week34_project/features/members/data/models/member.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';

class FakeMembersRepository implements MembersRepository {
  final List<Member> members;
  final bool shouldFail;

  int callCount = 0;
  int getDebtSummaryCallCount = 0;
  bool shouldFailDebtSummary = false;
  MemberDebtSummary? fakeDebtSummary;
  Exception? debtSummaryException;

  FakeMembersRepository({
    this.members = const [],
    this.shouldFail = false,
    this.shouldFailDebtSummary = false,
    this.fakeDebtSummary,
  });

  @override
  Future<Member?> findByEmail(String email) async {
    callCount++;

    if (shouldFail) {
      throw Exception('Members API unavailable');
    }

    final normalized = email.trim().toLowerCase();

    for (final member in members) {
      if (member.email.trim().toLowerCase() == normalized) {
        return member;
      }
    }

    return null;
  }

  @override
  Future<MemberDebtSummary> getDebtSummary(String memberId) async {
    getDebtSummaryCallCount++;

    if (shouldFail || shouldFailDebtSummary) {
      throw debtSummaryException ?? Exception('Debt summary API unavailable');
    }

    return fakeDebtSummary ??
        const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 0,
          remainingBorrowLimit: 5,
          canBorrow: true,
          overdueCount: 0,
          unpaidFineAmount: 0,
        );
  }
}
