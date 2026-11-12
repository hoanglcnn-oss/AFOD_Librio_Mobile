import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/widgets/app_toast.dart';

void main() {
  Widget createTestWidget({
    required void Function(BuildContext context) onTrigger,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => onTrigger(context),
              child: const Text('Show Toast'),
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'AppToast.success | Hiển thị thông báo màu xanh và icon thành công',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onTrigger: (context) => AppToast.success(context, 'Thành công'),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      expect(find.text('Thành công'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green.shade700);
    },
  );

  testWidgets(
    'AppToast.warning | Hiển thị thông báo màu vàng cam và icon cảnh báo',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onTrigger: (context) => AppToast.warning(context, 'Cảnh báo'),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      expect(find.text('Cảnh báo'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.amber.shade800);
    },
  );

  testWidgets('AppToast.error | Hiển thị thông báo màu lỗi và icon lỗi', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        onTrigger: (context) => AppToast.error(context, 'Có lỗi xảy ra'),
      ),
    );

    await tester.tap(find.text('Show Toast'));
    await tester.pump();

    expect(find.text('Có lỗi xảy ra'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('AppToast | Gọi toast mới sẽ ẩn toast cũ (không chồng)', (
    tester,
  ) async {
    late BuildContext currentContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              currentContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    AppToast.success(currentContext, 'Toast 1');
    await tester.pump();
    expect(find.text('Toast 1'), findsOneWidget);

    AppToast.error(currentContext, 'Toast 2');
    await tester.pump();

    expect(find.text('Toast 2'), findsOneWidget);
  });
}
