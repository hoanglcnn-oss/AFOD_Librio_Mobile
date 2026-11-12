import 'models/member.dart';
import 'models/member_debt_summary.dart';

abstract class MembersRepository {
  Future<Member?> findByEmail(String email);
  Future<MemberDebtSummary> getDebtSummary(String memberId);
}
