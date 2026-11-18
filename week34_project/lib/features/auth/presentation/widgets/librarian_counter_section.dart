import 'package:flutter/material.dart';

import 'package:week34_project/features/books/data/repositories/books_repository.dart';
import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'package:week34_project/features/members/data/repositories/members_repository.dart';

class LibrarianCounterSection extends StatelessWidget {
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final BooksRepository? booksRepository;
  final MembersRepository? membersRepository;

  const LibrarianCounterSection({
    super.key,
    this.borrowingSlipsRepository,
    this.booksRepository,
    this.membersRepository,
  });

  static const primaryNavy = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const borderHairline = Color(0xFFE2E8F0);
  static const tealAccent = Color(0xFF0D9488);
  static const tealBg = Color(0xFFF0FDFA);

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryNavy, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryNavy,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin công tác & tài khoản',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: primaryNavy,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Thẻ thông tin phân quyền & vai trò
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderHairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tealBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: tealAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vai trò: Thủ thư vận hành',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryNavy,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hệ thống quản lý thư viện Librio Academic',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: tealAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thao tác quầy và duyệt phiếu được thực hiện tại tab Bàn trực.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Thẻ Cài đặt tài khoản & Ứng dụng
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderHairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Cập nhật mật khẩu bảo mật tài khoản',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tính năng đổi mật khẩu đang được quản lý bởi Quản trị viên hệ thống.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: Color(0xFFF1F5F9),
                ),
                _buildSettingTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Quy chế phục vụ thư viện',
                  subtitle: 'Tiêu chuẩn mượn trả và kiểm kê tài liệu',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Quy chế lưu hành: Tối đa 5 cuốn/sinh viên, thời hạn tối đa 30 ngày.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: Color(0xFFF1F5F9),
                ),
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Phiên bản ứng dụng',
                  subtitle: 'Librio Academic v1.0.0 (Build 2026)',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
