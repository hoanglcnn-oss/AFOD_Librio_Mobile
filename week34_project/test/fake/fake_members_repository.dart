import 'package:week34_project/features/members/data/members_repository.dart';
import 'package:week34_project/features/members/data/models/member.dart';

class FakeMembersRepository implements MembersRepository {
  final List<Member> members;
  final bool shouldFail;

  int callCount = 0;

  FakeMembersRepository({this.members = const [], this.shouldFail = false});

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
}
