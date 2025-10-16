import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rishuden/ui/todo_cupertino_page.dart';

void main() {
  group('TodoCupertinoPage', () {
    testWidgets('renders empty state (light/dark)', (tester) async {
      Future<void> pumpWithBrightness(Brightness b) async {
        await tester.pumpWidget(
          CupertinoApp(
            theme: CupertinoThemeData(brightness: b),
            home: TodoCupertinoPage(items: const []),
          ),
        );
      }

      await pumpWithBrightness(Brightness.light);
      expect(find.text('未完了のタスクはありません'), findsOneWidget);

      await pumpWithBrightness(Brightness.dark);
      await tester.pump();
      expect(find.text('未完了のタスクはありません'), findsOneWidget);
    });

    testWidgets('shows items and segmented control', (tester) async {
      final items = [
        const TodoItemData(id: '1', title: 'タスクA'),
        const TodoItemData(id: '2', title: 'タスクB', completed: true),
      ];
      await tester.pumpWidget(
        const CupertinoApp(
          home: TodoCupertinoPage(items: []),
        ),
      );
      expect(find.byType(CupertinoSegmentedControl<TodoTab>), findsOneWidget);

      await tester.pumpWidget(
        CupertinoApp(
          home: TodoCupertinoPage(items: items),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('タスクA'), findsOneWidget);
    });
  });
}
