import 'models/member.dart';

abstract class MembersRepository {
  Future<Member?> findByEmail(String email);
}
