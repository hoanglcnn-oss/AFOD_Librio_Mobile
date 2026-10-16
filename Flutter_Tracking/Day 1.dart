/*
DAY 1 - DART FUNDAMENTALS
Bài tập: Librio Book Inventory

Nội dung:
- OOP: abstract class, inheritance, constructor
- Null Safety
- List và tìm kiếm dữ liệu

Các class và hàm trong file này sẽ được dùng ở Day 2.
*/

// [GIẢI THÍCH 1] Vì sao tạo abstract class LibraryItem?
// giúp form 1 mẫu chung cho các lớp con -> dù lớp con khác nhau, vẫn giữ được những tính chất phải có
abstract class LibraryItem {
  final String title;

  LibraryItem(this.title);

  void displayInfo();
}

// [GIẢI THÍCH 2] Book extends LibraryItem để làm gì?
//sách cần tính chất phải có (từ LibraryItem) để đảm bảo có thể thêm vào thư viện, các tính chất khác tính sau khi extends
class Book extends LibraryItem {
  final String author;
  int availableCopies;
  String? description;

  // [GIẢI THÍCH 3] required, ?, super(title) có vai trò gì?
  // required: bắt buộc truyền tham số khi tạo Book, thiếu thì Dart báo lỗi.
  //?: có thể là null, nếu không điền gì
  //super(title): đưa title từ Book lên constructor của LibraryItem để khởi tạo field title ở lớp cha.
  Book({
    required String title,
    required this.author,
    required this.availableCopies,
    this.description,
  }) : super(title);

  @override
  void displayInfo() {
    print('$title - $author - Còn $availableCopies bản');

    // [GIẢI THÍCH 4] Vì sao dùng ?? ở đây?
    // description khác null thì lấy bên trái, nếu null thì lấy 'Chưa có mô tả'.
    print(description ?? 'Chưa có mô tả');
  }
}

// [GIẢI THÍCH 5] Vì sao hàm trả về Book? thay vì Book?
//Tìm không thấy sách thì trả null, nên phải khai báo Book? để Dart biết kết quả có thể null và bắt mình xử lý trước khi dùng.
Book? findBookByTitle(List<Book> books, String title) {
  for (final book in books) {
    if (book.title == title) {
      return book;
    }
  }

  return null;
}
