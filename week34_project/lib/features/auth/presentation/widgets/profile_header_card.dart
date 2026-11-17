import 'package:flutter/material.dart';

import 'profile_digital_card_modal.dart';
import 'profile_edit_sheet.dart';

class ProfileHeaderCard extends StatelessWidget {
  final dynamic user;

  const ProfileHeaderCard({super.key, required this.user});

  static const primaryNavy = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const borderHairline = Color(0xFFE2E8F0);
  static const tealAccent = Color(0xFF0D9488);
  static const tealBg = Color(0xFFF0FDFA);
  static const surfaceLow = Color(0xFFF8FAFC);
  static const errorRed = Color(0xFFDC2626);
  static const successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderHairline),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar có badge trạng thái
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: tealBg,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.trim().split(' ').last[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: tealAccent,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.isActive
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 15,
                      color: user.isActive ? successGreen : errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Tên, Nút chỉnh sửa, Vai trò, Trạng thái
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Nút bút chì nhỏ chỉnh sửa thông tin cá nhân
                      InkWell(
                        onTap: () => EditProfileSheet.show(context, user),
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Chip Vai trò
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryNavy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          switch (user.role.toUpperCase()) {
                            'MEMBER' => 'Độc giả',
                            'LIBRARIAN' => 'Thủ thư',
                            'ADMIN' => 'Quản trị viên',
                            _ => user.role,
                          },
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Chip Trạng thái
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: user.isActive
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: user.isActive ? successGreen : errorRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.isActive
                                  ? 'Đang hoạt động'
                                  : 'Không hoạt động',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: user.isActive
                                    ? const Color(0xFF047857)
                                    : errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Nút Thẻ số (mở BottomSheet Thẻ Thư Viện Kỹ Thuật Số)
            InkWell(
              onTap: () => DigitalCardModal.show(context, user),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderHairline),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: primaryNavy,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thẻ số',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
