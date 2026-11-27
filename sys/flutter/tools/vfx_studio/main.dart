import 'package:flutter/material.dart';
import 'vfx_studio_page.dart';

/// 開発者専用のアニメーション・VFX・フローティングテキスト調整ツール（ユーザー非配布）
///
/// 起動方法:
///   cd sys/flutter
///   flutter run -t tools/vfx_studio/main.dart -d windows
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VfxStudioApp());
}

class VfxStudioApp extends StatelessWidget {
  const VfxStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartHack VFX Studio (Dev Tool)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF80D8FF),
          brightness: Brightness.dark,
        ),
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
        ),
      ),
      home: const VfxStudioPage(),
    );
  }
}
