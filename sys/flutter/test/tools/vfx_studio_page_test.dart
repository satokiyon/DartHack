import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tools/vfx_studio/vfx_studio_page.dart';

void main() {
  testWidgets('VFX Studio 画面で全6タブ切替・演出トリガー・持続トグル・A/B比較・リセットが安全に動作する', (tester) async {
    tester.view.physicalSize = const Size(1500, 980);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: VfxStudioPage(enableDiskIo: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DartHack VFX Studio'), findsOneWidget);
    expect(find.text('未保存 (Modified)'), findsNothing);

    // 演出トリガー発火＆完了後に Ticker / Timer が残らず pumpAndSettle できること
    await tester.tap(find.text('爆発(揺)'));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.text('テレポート(発着)'));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.text('同セル4件スタガー'));
    await tester.pumpAndSettle();

    // 持続状態の FilterChip トグル（スクロール領域内のため ensureVisible を実行）
    final levChip = find.text('浮遊(影/弧)');
    await tester.ensureVisible(levChip);
    await tester.pumpAndSettle();
    await tester.tap(levChip);
    await tester.pumpAndSettle();

    final confChip = find.text('混乱(?)');
    await tester.ensureVisible(confChip);
    await tester.pumpAndSettle();
    await tester.tap(confChip);
    await tester.pumpAndSettle();

    // 全 6 タブを順番に切り替えてエラーが出ないこと
    for (final tabName in ['VFX粒子', '光リング', 'テキスト', '持続状態', 'シェイク・上限', '移動・戦闘']) {
      await tester.tap(find.text(tabName));
      await tester.pumpAndSettle();
    }

    // プリセット「控えめ」適用 → Modified バッジ表示 → A/B比較トグル → 「全て標準へ」で復帰
    await tester.tap(find.text('プリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('組み込み: 控えめ (Subtle)'));
    await tester.pumpAndSettle();
    expect(find.text('未保存 (Modified)'), findsOneWidget);

    await tester.tap(find.text('A/B比較 (標準値で見る)'));
    await tester.pumpAndSettle();
    expect(find.text('A/B比較: 標準値プレビュー中'), findsOneWidget);

    await tester.tap(find.text('全て標準へ'));
    await tester.pumpAndSettle();
    expect(find.text('未保存 (Modified)'), findsNothing);
  });
}
