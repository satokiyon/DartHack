import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/main.dart';
import 'package:darthack/utils/app_prefs.dart';

void main() {
  setUp(() async {
    await AppPrefs.setMockInitialValues({});
  });

  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
