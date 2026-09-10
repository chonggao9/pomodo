import 'package:flutter_test/flutter_test.dart';
import 'package:pomodo/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 渲染 PomoDo 应用
    await tester.pumpWidget(const PomoDoApp());
    expect(find.byType(PomoDoApp), findsOneWidget);
  });
}
