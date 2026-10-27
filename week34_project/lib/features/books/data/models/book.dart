class Book {
  final String id;
  final String isbn;
  final String title;
  final String authorName;
  final String categoryName;
  final String description;
  final String? coverUrl;
  final String status;
  final int copiesAvailable;
  final int copiesTotal;

  const Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authorName,
    required this.categoryName,
    required this.description,
    required this.coverUrl,
    required this.status,
    required this.copiesAvailable,
    required this.copiesTotal,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      authorName: json['authorName'] as String,
      categoryName: json['categoryName'] as String,
      description: json['description'] as String,
      coverUrl: json['coverUrl'] as String?,
      status: json['status'] as String,
      copiesAvailable: json['copiesAvailable'] as int,
      copiesTotal: json['copiesTotal'] as int,
    );
  }

  bool get canBorrow =>
      copiesAvailable > 0 && (status == 'AVAILABLE' || status == 'LOW_STOCK');
}
