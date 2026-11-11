enum AppRole {
  member,
  librarian,
  admin,
  unknown;

  static AppRole fromString(String role) {
    return switch (role.toUpperCase()) {
      'MEMBER' => AppRole.member,
      'LIBRARIAN' => AppRole.librarian,
      'ADMIN' => AppRole.admin,
      _ => AppRole.unknown,
    };
  }

  bool get canManageBorrowingSlips =>
      this == AppRole.librarian || this == AppRole.admin;
}
