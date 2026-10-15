
/*
DAY 1 - DART FUNDAMENTALS
Exercise: Librio Book Inventory

Objectives:
- Practice OOP, inheritance and abstract classes.
- Use named parameters and required.
- Work with List<Book>.
- Apply Null Safety (?, ??).
- Search and filter books.

Requirements:
1. Create an abstract class LibraryItem with:
   - final String title
   - displayInfo() method

2. Create Book extends LibraryItem with:
   - final String author
   - int availableCopies
   - String? description
   - Named constructor with required parameters

3. Create a List<Book> with at least 3 books:
   - One book with 5 copies
   - One book with 0 copies
   - One book with 2 copies

4. Display only books with availableCopies > 0.

5. Display "Chưa có mô tả" when description is null.

6. Implement findBookByTitle().
   - Return Book if found.
   - Return null otherwise.

7. Test searching for existing and non-existing books.

Acceptance Criteria:
- Program runs without errors.
- Available books are filtered correctly.
- Nullable descriptions are handled safely.
- Search works for both found and not-found cases.
*/

// TODO 1: Create abstract class LibraryItem.
abstract class LibraryItem {
  final String title;

  LibraryItem(this.title);

  void displayInfo();
}

// TODO 2: Create Book extending LibraryItem.
// Add author, availableCopies and nullable description.
// Use named parameters and super(title).
// Override displayInfo().
class Book extends LibraryItem {
  final String author;
  int availableCopies;
  String? description;

  Book({
    required String title,
    required this.author,
    required this.availableCopies,
    this.description,
  }) : super(title);

  @override
  void displayInfo() {
    print('$title - $author - Còn $availableCopies bản');
    print(description ?? 'Chưa có mô tả');
  }
}

// TODO 3: Implement a search function.
// Return Book? to handle the not-found case.
Book? findBookByTitle(List<Book> books, String title) {
  for (var book in books) {
    if (book.title == title) {
      return book;
    }
  }

  return null;
}

void main() {
  // TODO 4: Create a List<Book> with 3 books.
  List<Book> books = [
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

  // TODO 5: Display books that are still available.
  print('--- Danh sách sách còn hàng ---');

  for (var book in books) {
    if (book.availableCopies > 0) {
      book.displayInfo();
    }
  }

  // TODO 6: Search for an existing book.
  print('\n--- Tìm sách tồn tại ---');

  var foundBook = findBookByTitle(books, 'Doraemon');

  if (foundBook != null) {
    print('Đã tìm thấy: ${foundBook.title}');
  }

  // TODO 7: Search for a non-existing book.
  print('\n--- Tìm sách không tồn tại ---');

  var notFoundBook = findBookByTitle(books, 'Harry Potter');

  if (notFoundBook == null) {
    print('Không tìm thấy sách này.');
  }

  // TODO 8: Test a book with a null description.
  print('\n--- Kiểm tra mô tả null ---');
  books[1].displayInfo();
}
