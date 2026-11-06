import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('フローティングボタンが ExcludeFocus(excluding: true) でラップされ、フォーカストラバーサルから隔離されている', (tester) async {
    final focusNodeA = FocusNode();
    final buttonFocusNode = FocusNode(canRequestFocus: false, skipTraversal: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TextField(
                focusNode: focusNodeA,
                autofocus: true,
              ),
              ExcludeFocus(
                excluding: true,
                child: IconButton(
                  focusNode: buttonFocusNode,
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 最初は TextField にフォーカスがある
    expect(focusNodeA.hasFocus, isTrue);

    // TextField を unfocus した場合でも、buttonFocusNode にフォーカスが勝手に奪われないこと
    focusNodeA.unfocus();
    await tester.pumpAndSettle();

    expect(buttonFocusNode.hasFocus, isFalse);
    expect(buttonFocusNode.canRequestFocus, isFalse);
    expect(buttonFocusNode.skipTraversal, isTrue);
  });
}

