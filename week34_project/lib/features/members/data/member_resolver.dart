import 'members_repository.dart';

class MemberResolver {
  final MembersRepository membersRepository;

  const MemberResolver({required this.membersRepository});

  Future<String?> resolve({
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
    final member = await membersRepository.findByEmail(email);

    if (member == null) {
      return null;
    }

    return member.id;
  }
}
