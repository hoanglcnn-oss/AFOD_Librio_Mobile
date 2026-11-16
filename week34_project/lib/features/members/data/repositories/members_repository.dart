import '../models/member.dart';
import '../models/member_debt_summary.dart';

abstract class MembersRepository {
  Future<Member?> findByEmail(String email);
  Future<MemberDebtSummary> getDebtSummary(String memberId);

  Future<String?> resolveMemberId({
    required String? memberId,
    required String email,
    required String role,
  }) async {
    // Chỉ tài khoản MEMBER mới được mượn.
    if (role != 'MEMBER') {
      return null;
    }

    // Ưu tiên liên kết đã được backend cung cấp.
    if (memberId != null && memberId.trim().isNotEmpty) {
      return memberId.trim();
    }

    // Fallback: tra cứu bằng email.
    final member = await findByEmail(email);

    if (member == null) {
      return null;
    }

    return member.id;
  }
}
