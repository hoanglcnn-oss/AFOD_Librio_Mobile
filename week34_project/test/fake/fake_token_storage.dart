import 'package:week34_project/core/storage/token_storage.dart';

class FakeTokenStorage extends TokenStorage {
  String? savedToken;

  @override
  Future<void> saveToken(String token) async {
    savedToken = token;
  }

  @override
  Future<String?> readToken() async {
    return savedToken;
  }

  @override
  Future<void> deleteToken() async {
    savedToken = null;
  }
}
