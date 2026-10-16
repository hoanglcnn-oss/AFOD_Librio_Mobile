/*
DAY 2 - DART PRACTICE

Nội dung:
- Import và sử dụng class/hàm từ Day 1
- Thực hành ?, !, late, required
- Mixin và Extension
- Future, async/await, exception handling
- Stream

Các mục [GIẢI THÍCH] cần viết lại bằng lời của mình.
*/

import 'Day 1.dart';

// [GIẢI THÍCH 1] Mixin dùng để làm gì?
// giúp nhiều class dùng chung hành vi, kể cả class không cùng superclass.
mixin Borrowable {
  void borrow() {
    print('Book borrowed successfully.');
  }
}

// Dùng lại Book từ day1.dart, kết hợp hành vi Borrowable.
class BorrowableBook extends Book with Borrowable {
  BorrowableBook({
    required super.title,
    required super.author,
    required super.availableCopies,
    super.description,
  });
}

// [GIẢI THÍCH 2] Extension khác method thông thường ở đâu?
// giúp bổ sung method tiện ích cho một kiểu dữ liệu đã tồn tại
// Ở đây dùng để xử lý chuỗi tìm kiếm (cắt dấu cách thừa đầu đuôi + chuyển chữ thường)
// mà không cần sửa class String.
extension SearchExtension on String {
  String normalizeSearch() {
    return trim().toLowerCase();
  }
}

// [GIẢI THÍCH 3] Vì sao trả về Future<List<Book>>?
//Vì Future là một object đại diện cho một giá trị sẽ có trong tương lai,
// List<Book> là kiểu dữ liệu sẽ trả về sau khi Future hoàn thành

//trả về list book mong muốn sau khi pending 2s
//giống như khi call api
Future<List<Book>> fetchBooks(bool shouldFail) async {
  await Future.delayed(const Duration(seconds: 2));

  if (shouldFail) {
    throw Exception('Failed to fetch books');
  }

  return [
    Book(
      title: 'Doraemon',
      author: 'Fujiko Fujio',
      availableCopies: 5,
      description: 'Truyện tranh kinh điển',
    ),
    Book(
      title: 'Sherlock Holmes',
      author: 'Arthur Conan Doyle',
      availableCopies: 0,
    ),
    Book(
      title: 'Nhà Giả Kim',
      author: 'Paulo Coelho',
      availableCopies: 2,
      description: 'Một hành trình đi tìm kho báu',
    ),
  ];
}

// [GIẢI THÍCH 4] Stream khác Future như thế nào?
//Future là một giá trị duy nhất, Stream có thể phát ra nhiều giá trị theo thời gian

//truyền value theo thời gian (từng số)
//như đếm ngược số sách còn lại
Stream<int> trackBookStock() async* {
  for (int i = 5; i >= 2; i--) {
    yield i;

    if (i > 2) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

void main() async {
  // PHẦN A - IMPORT VÀ REQUIRED
  // [GIẢI THÍCH 5]
  // Vì sao có thể tạo Book ở đây dù class nằm trong Day 1?
  // vì Day 2 đã import file Day 1

  // required trong constructor này có tác dụng gì?
  // Khi tạo BorrowableBook, phải truyền title, author, availableCopies.
  // description thì không bắt buộc.
  final borrowedBook = BorrowableBook(
    title: 'Clean Code',
    author: 'Robert C. Martin',
    availableCopies: 2,
  );

  borrowedBook.displayInfo();
  borrowedBook.borrow();

  // PHẦN B - EXTENSION
  final keyword = '   DORAEMON   ';
  print('Keyword: ${keyword.normalizeSearch()}');

  // PHẦN C - LATE
  // [GIẢI THÍCH 6] late có tác dụng gì?
  // late là để khai báo biến mà chưa gán giá trị ngay lập tức
  late String currentUser;
  currentUser = 'Hoang';
  print('Current user: $currentUser');

  // PHẦN D - FUTURE
  print('\n--- Fetching books ---');

  try {
    final books = await fetchBooks(false);

    for (final book in books) {
      book.displayInfo();
    }

    // PHẦN E - NULL SAFETY (?, !)
    // [GIẢI THÍCH 7]
    // Vì sao foundBook có thể null?
    // vì có thể không tìm thấy sách
    // Dùng ! khi nào thì nguy hiểm?
    // Khi không chắc chắn giá trị không null

    final Book? foundBook = findBookByTitle(books, 'Doraemon');

    print('Safe title: ${foundBook?.title ?? "Not found"}');

    // Chỉ dùng ! để thử cú pháp.
    // Nếu không có Doraemon, dòng này sẽ lỗi runtime.
    final forcedBook = findBookByTitle(books, 'Doraemon')!;

    print('Forced title: ${forcedBook.title}');

    final missingBook = findBookByTitle(books, 'Harry Potter');

    print('Missing: ${missingBook?.title ?? "Not found"}');
  } catch (e) {
    print('Error: $e');
  } finally {
    print('--- Fetch completed ---');
  }

  // PHẦN F - EXCEPTION HANDLING
  // [GIẢI THÍCH 8] Tại sao await cần nằm trong try?
  // Phải await Future trong try để khi Future thất bại, catch nhận được lỗi.
  try {
    await fetchBooks(true);
  } catch (e) {
    print('Error: $e');
  } finally {
    print('--- Failed fetch test completed ---');
  }

  // PHẦN G - STREAM
  // [GIẢI THÍCH 9] async*, yield, await for làm gì?
  // async* là để khai báo function trả về stream
  // yield là để phát ra giá trị
  // await for là để nhận giá trị từ stream
  print('\n--- Tracking stock updates ---');

  await for (final stock in trackBookStock()) {
    print('Stock: $stock');

    if (stock <= 2) {
      print('Sắp hết sách');
    }
  }
}
