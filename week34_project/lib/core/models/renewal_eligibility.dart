import 'package:equatable/equatable.dart';

class RenewalEligibility extends Equatable {
  final bool canRenew;
  final String? reasonCode;
  final String? message;

  const RenewalEligibility({
    required this.canRenew,
    this.reasonCode,
    this.message,
  });

  factory RenewalEligibility.fromJson(Map<String, dynamic> raw) {
    final json = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : (raw['renewalEligibility'] is Map<String, dynamic>
            ? raw['renewalEligibility'] as Map<String, dynamic>
            : (raw['eligibility'] is Map<String, dynamic>
                ? raw['eligibility'] as Map<String, dynamic>
                : raw));

    return RenewalEligibility(
      canRenew: json['canRenew'] as bool? ?? false,
      reasonCode: json['reasonCode'] as String? ?? json['reason'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canRenew': canRenew,
      if (reasonCode != null) 'reasonCode': reasonCode,
      if (message != null) 'message': message,
    };
  }

  @override
  List<Object?> get props => [canRenew, reasonCode, message];
}
