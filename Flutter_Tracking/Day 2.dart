
/*
DAY 2 - ADVANCED DART
Exercise: Async Librio Book Inventory

Objectives:
- Practice Mixin and Extension.
- Use Future and async/await.
- Handle errors with try/catch/finally.
- Use Stream, async* and yield.

Requirements:
1. Create a Borrowable mixin with borrow().

2. Create a String extension with normalizeSearch().
   - Trim whitespace.
   - Convert text to lowercase.

3. Create a Book class using Borrowable.

4. Create fetchBooks(bool shouldFail):
   - Return Future<List<Book>>.
   - Simulate a 2-second delay.
   - Return a list of books on success.
   - Throw an exception on failure.

5. In main():
   - Fetch books successfully.
   - Display the returned books.
   - Simulate a failed request.
   - Handle errors using try/catch/finally.

6. Create trackBookStock():
   - Return Stream<int>.
   - Emit 5, 4, 3, 2.
   - Wait 1 second between emissions.

7. Use await for to process stock updates.
   - Print each stock value.
   - Print "Sắp hết sách" when stock <= 2.

Acceptance Criteria:
- Mixin and Extension work correctly.
- Future returns book data asynchronously.
- Errors are handled without unhandled exceptions.
- Stream emits values in the correct order.
- Program runs on DartPad.
*/

// TODO 1: Create Borrowable mixin.

// TODO 2: Create SearchExtension on String.

// TODO 3: Create Book class using Borrowable.

// TODO 4: Implement Future<List<Book>> fetchBooks(bool shouldFail).

// TODO 5: Implement Stream<int> trackBookStock().

void main() async {
  // TODO 6: Fetch and display books.

  // TODO 7: Test failed fetch with try/catch/finally.

  // TODO 8: Listen to stock updates using await for.
}
