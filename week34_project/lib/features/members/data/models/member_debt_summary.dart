import 'package:equatable/equatable.dart';

class MemberDebtSummary extends Equatable {
  final int maxBorrowLimit;
  final int currentBorrowedCount;
  final int remainingBorrowLimit;
  final bool canBorrow;
  final String? reasonIfNotAllowed;
  final int overdueCount;
  final num unpaidFineAmount;

  const MemberDebtSummary({
    required this.maxBorrowLimit,
    required this.currentBorrowedCount,
    required this.remainingBorrowLimit,
    required this.canBorrow,
    this.reasonIfNotAllowed,
    this.overdueCount = 0,
    this.unpaidFineAmount = 0,
  });

  factory MemberDebtSummary.fromJson(Map<String, dynamic> raw) {
    final json = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;

    final maxLimit = json['maxBorrowLimit'] as int? ?? 5;
    final currentBorrowed =
        json['currentBorrowedCount'] as int? ??
        json['borrowedCount'] as int? ??
        0;
    final remaining =
        json['remainingBorrowLimit'] as int? ??
        (maxLimit - currentBorrowed).clamp(0, maxLimit);
    final overdue =
        json['overdueCount'] as int? ??
        json['overdueBooksCount'] as int? ??
        json['overdue'] as int? ??
        0;
    final unpaidFine =
        (json['unpaidFineAmount'] as num?) ??
        (json['totalUnpaidFine'] as num?) ??
        (json['unpaidFine'] as num?) ??
        0;
    final canBorrow =
        json['canBorrow'] as bool? ??
        (remaining > 0 && overdue == 0 && unpaidFine == 0);
    final reason =
        json['reasonIfNotAllowed'] as String? ?? json['reason'] as String?;

    return MemberDebtSummary(
      maxBorrowLimit: maxLimit,
      currentBorrowedCount: currentBorrowed,
      remainingBorrowLimit: remaining,
      canBorrow: canBorrow,
      reasonIfNotAllowed: reason,
      overdueCount: overdue,
      unpaidFineAmount: unpaidFine,
    );
  }

  Map<String, dynamic> toJson() => {
    'maxBorrowLimit': maxBorrowLimit,
    'currentBorrowedCount': currentBorrowedCount,
    'remainingBorrowLimit': remainingBorrowLimit,
    'canBorrow': canBorrow,
    'reasonIfNotAllowed': reasonIfNotAllowed,
    'overdueCount': overdueCount,
    'unpaidFineAmount': unpaidFineAmount,
  };

  MemberDebtSummary copyWith({
    int? maxBorrowLimit,
    int? currentBorrowedCount,
    int? remainingBorrowLimit,
    bool? canBorrow,
    String? reasonIfNotAllowed,
    int? overdueCount,
    num? unpaidFineAmount,
  }) {
    return MemberDebtSummary(
      maxBorrowLimit: maxBorrowLimit ?? this.maxBorrowLimit,
      currentBorrowedCount: currentBorrowedCount ?? this.currentBorrowedCount,
      remainingBorrowLimit: remainingBorrowLimit ?? this.remainingBorrowLimit,
      canBorrow: canBorrow ?? this.canBorrow,
      reasonIfNotAllowed: reasonIfNotAllowed ?? this.reasonIfNotAllowed,
      overdueCount: overdueCount ?? this.overdueCount,
      unpaidFineAmount: unpaidFineAmount ?? this.unpaidFineAmount,
    );
  }

  @override
  List<Object?> get props => [
    maxBorrowLimit,
    currentBorrowedCount,
    remainingBorrowLimit,
    canBorrow,
    reasonIfNotAllowed,
    overdueCount,
    unpaidFineAmount,
  ];
}
