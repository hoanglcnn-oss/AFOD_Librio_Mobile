class Member {
  final String id;
  final String email;
  final String fullName;
  final String cardNumber;
  final String status;
  final DateTime membershipExpiry;

  const Member({
    required this.id,
    required this.email,
    required this.fullName,
    required this.cardNumber,
    required this.status,
    required this.membershipExpiry,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      cardNumber: json['cardNumber'] as String,
      status: json['status'] as String,
      membershipExpiry: DateTime.parse(json['membershipExpiry'] as String),
    );
  }
}
