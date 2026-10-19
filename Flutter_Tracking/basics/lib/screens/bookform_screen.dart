import 'package:flutter/material.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  // Khai báo GlobalKey<FormState>
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final copiesController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    copiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sách'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          //Gắn key cho Form
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên sách',
                  border: OutlineInputBorder(),
                ),

                // Viết validator:
                // Nếu null hoặc toàn khoảng trắng,
                // trả về 'Không được để trống'.
                // Ngược lại trả về null.
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: authorController,
                decoration: const InputDecoration(
                  labelText: 'Tác giả',
                  border: OutlineInputBorder(),
                ),
                //Validator: Nếu null hoặc rỗng => return 'Không được để trống',
                //Ngược lại => return null.
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: copiesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số bản',
                  border: OutlineInputBorder(),
                ),
                //Validator:
                // 1. null/rỗng → return 'Không được để trống'.
                // 2. Không phải số → return 'Phải là số'.
                // 3. Số < 0 → return 'Số bản phải lớn hơn hoặc bằng 0'.
                // 4. Hợp lệ → return null.
                validator: (value) {
                  // Kiểm tra null/rỗng
                  if (value == null || value.trim().isEmpty) {
                    return 'Không được để trống';
                  }

                  // Kiểm tra có phải số không
                  if (int.tryParse(value.trim()) == null) {
                    return 'Phải là số';
                  }

                  // Kiểm tra >= 0
                  final copies = int.parse(value.trim());
                  if (copies < 0) {
                    return 'Số bản >= 0';
                  }

                  // Nếu tất cả hợp lệ
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    // Tạo 1 Map<String, dynamic> newBook
                    // chứa thông tin sách
                    // title, author, copies
                    final newBook = <String, dynamic>{
                      'title': titleController.text.trim(),
                      'author': authorController.text.trim(),
                      'copies': int.parse(copiesController.text.trim()),
                    };
                    // Sử dụng Navigator.pop(context, newBook);
                    // để trả về màn hình trước đó cùng với dữ liệu newBook
                    Navigator.pop(context, newBook);
                  }
                },
                child: const Text('Lưu sách'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}