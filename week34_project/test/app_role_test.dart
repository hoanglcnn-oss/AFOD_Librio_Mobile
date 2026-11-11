import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/auth/data/models/app_role.dart';

void main() {
  test('AppRole | MEMBER | không có quyền quản lý phiếu', () {
    final role = AppRole.fromString('MEMBER');

    expect(role, AppRole.member);
    expect(role.canManageBorrowingSlips, false);
  });

  test('AppRole | LIBRARIAN | có quyền quản lý phiếu', () {
    final role = AppRole.fromString('LIBRARIAN');

    expect(role, AppRole.librarian);
    expect(role.canManageBorrowingSlips, true);
  });

  test('AppRole | ADMIN | có quyền quản lý phiếu', () {
    final role = AppRole.fromString('ADMIN');

    expect(role, AppRole.admin);
    expect(role.canManageBorrowingSlips, true);
  });

  test('AppRole | Vai trò không xác định | không cấp quyền', () {
    final role = AppRole.fromString('OTHER');

    expect(role, AppRole.unknown);
    expect(role.canManageBorrowingSlips, false);
  });
}
