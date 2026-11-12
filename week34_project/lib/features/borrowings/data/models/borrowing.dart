import '../../../../core/models/renewal_eligibility.dart';

class Borrowing {
  final String id;
  final String transactionCode;
  final String memberId;
  final String memberName;
  final String bookId;
  final String bookTitle;
  final DateTime borrowDate;
  final DateTime dueDate;
  final String status;

  // Renew + Return + Fine
  final int renewCount;
  final DateTime? returnDate;
  final int? fineAmount;
  final bool? finePaid;
  final RenewalEligibility? renewalEligibility;

  const Borrowing({
    required this.id,
    required this.transactionCode,
    required this.memberId,
    required this.memberName,
    required this.bookId,
    required this.bookTitle,
    required this.borrowDate,
    required this.dueDate,
    required this.status,
    this.renewCount = 0,
    this.returnDate,
    this.fineAmount,
    this.finePaid,
    this.renewalEligibility,
  });

  bool get canRenew => renewalEligibility?.canRenew ?? false;
  String? get renewalReasonCode => renewalEligibility?.reasonCode;
  String? get renewalMessage => renewalEligibility?.message;

  factory Borrowing.fromJson(Map<String, dynamic> raw) {
    final json = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;

    final renewalJson = json['renewalEligibility'] ?? json['eligibility'];
    RenewalEligibility? renewalEligibility;
    if (renewalJson is Map<String, dynamic>) {
      renewalEligibility = RenewalEligibility.fromJson(renewalJson);
    } else if (json.containsKey('canRenew')) {
      renewalEligibility = RenewalEligibility.fromJson(json);
    }

    return Borrowing(
      id: json['id'] as String,
      transactionCode: json['transactionCode'] as String,
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String? ?? '',
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      borrowDate: DateTime.parse(json['borrowDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: json['status'] as String,

      renewCount: (json['renewCount'] as num?)?.toInt() ?? 0,

      returnDate: json['returnDate'] == null
          ? null
          : DateTime.parse(json['returnDate'] as String),

      fineAmount: (json['fineAmount'] as num?)?.toInt(),
      finePaid: json['finePaid'] as bool?,
      renewalEligibility: renewalEligibility,
    );
  }
}

typedef BorrowingDetail = Borrowing;

