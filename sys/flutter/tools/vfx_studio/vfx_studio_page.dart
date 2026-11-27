import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darthack/models/map_animation_event.dart';
import 'package:darthack/models/vfx_tuning_config.dart';
import 'package:darthack/nethack_map_painter.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/utils/map_animation_controller.dart';
import 'package:darthack/widgets/nethack_animation_overlay_painter.dart';
import 'studio_tile_loader.dart';

/// 開発者専用アニメーション・VFX・フローティングテキスト調整画面
class VfxStudioPage extends StatefulWidget {
  /// ウィジェットテスト時にディスクI/Oや外部ディレクトリ走査を無効化するためのフラグ
  final bool enableDiskIo;

  const VfxStudioPage({
    super.key,
    this.enableDiskIo = true,
  });

  @override
  State<VfxStudioPage> createState() => _VfxStudioPageState();
}

class _VfxStudioPageState extends State<VfxStudioPage> with SingleTickerProviderStateMixin {
  static const int _heroX = 39;
  static const int _heroY = 10;
  static const int _orcX = 40;
  static const int _orcY = 10;
  static const int _dragonX = 43;
  static const int _dragonY = 10;
  static const int _boulderX = 38;
  static const int _boulderY = 10;
  static const int _pitX = 37;
  static const int _pitY = 10;

  static const VfxTuningConfig _standardDefaults = VfxTuningConfig();

  late final NetHackScreen _screen;
  late final MapAnimationController _animController;

  VfxTuningConfig _editingConfig = const VfxTuningConfig();
  VfxTuningConfig _savedConfig = const VfxTuningConfig();
  Map<String, VfxTuningConfig> _customPresets = {};

  bool _abCompareStandard = false;
  bool _repeatEnabled = false;
  Timer? _repeatTimer;
  VoidCallback? _lastTriggerAction;
  String _lastTriggerLabel = 'なし';

  int _turnCounter = 1;
  int _ambientMaskHero = 0;
  bool _enemyFleeing = false;
  int _selectedStatusCode = StatusTextCode.stoning;
  String _selectedParticleKey = 'explosion';
  String _selectedRingKey = 'explosionOuter';

  // プレビュー表示設定
  List<StudioTilesetOption> _tileOptions = const [];
  StudioTilesetOption? _selectedTileOption; // null = テキストモード
  ui.Image? _tileImage;
  double _previewZoom = 1.6;

  String? _resolvedJsonPath;
  String? _resolvedDartPath;

  static const List<(int code, String label)> _statusChoices = [
    (StatusTextCode.stoning, '1: 石化! / Stoning!'),
    (StatusTextCode.slimed, '2: 粘液化! / Slimed!'),
    (StatusTextCode.strangled, '3: 窒息! / Strangled!'),
    (StatusTextCode.foodPoisoning, '4: 食中毒! / Food Pois!'),
    (StatusTextCode.terminalIllness, '5: 病気! / Ill!'),
    (StatusTextCode.grabbed, '6: 捕縛! / Grabbed!'),
    (StatusTextCode.inLava, '7: 溶岩! / In Lava!'),
    (StatusTextCode.blind, '10: 盲目 / Blind'),
    (StatusTextCode.deaf, '11: 難聴 / Deaf'),
    (StatusTextCode.confused, '12: 混乱 / Confused'),
    (StatusTextCode.stunned, '13: 朦朧 / Stunned'),
    (StatusTextCode.hallucinating, '14: 幻覚 / Hallu'),
    (StatusTextCode.paralyzed, '15: 麻痺 / Paralyzed'),
    (StatusTextCode.asleep, '16: 睡眠 / Asleep'),
    (StatusTextCode.unconscious, '17: 失神 / Unconscious'),
    (StatusTextCode.engulfed, '18: 丸呑み / Engulfed'),
    (StatusTextCode.held, '19: 拘束 / Held'),
    (StatusTextCode.trapped, '20: 罠拘束 / Trapped'),
    (StatusTextCode.punished, '21: 懲罰 / Punished'),
    (StatusTextCode.slippery, '22: 滑手 / Slippery'),
    (StatusTextCode.woundedLegs, '23: 脚傷 / Wounded Legs'),
    (StatusTextCode.submerged, '24: 水没 / Submerged'),
    (StatusTextCode.ironSensitive, '25: 鉄過敏 / Iron'),
    (StatusTextCode.satiated, '30: 満腹 / Satiated'),
    (StatusTextCode.hungry, '31: 空腹 / Hungry'),
    (StatusTextCode.weak, '32: 衰弱 / Weak'),
    (StatusTextCode.fainting, '33: 失神寸前 / Fainting'),
    (StatusTextCode.fainted, '34: 失神(空腹) / Fainted'),
    (StatusTextCode.starved, '35: 飢餓! / Starved!'),
    (StatusTextCode.burdened, '40: 重荷 / Burdened'),
    (StatusTextCode.stressed, '41: 圧迫 / Stressed'),
    (StatusTextCode.strained, '42: 過重 / Strained'),
    (StatusTextCode.overtaxed, '43: 超過重 / Overtaxed'),
    (StatusTextCode.overloaded, '44: 過積載! / Overloaded!'),
    (StatusTextCode.levitating, '50: 浮遊 / Levitating'),
    (StatusTextCode.flying, '51: 飛行 / Flying'),
    (StatusTextCode.riding, '52: 騎乗 / Riding'),
    (StatusTextCode.glowingHands, '53: 発光 / Glowing Hands'),
    (StatusTextCode.fast, '54: 加速 / Fast'),
    (StatusTextCode.invisible, '55: 透明 / Invisible'),
    (StatusTextCode.holding, '56: 保持 / Holding'),
    (StatusTextCode.fleeing, '60: 敵逃走 / Fleeing'),
    (StatusTextCode.slowed, '61: 敵減速 / Slowed'),
  ];

  static const List<(int bit, String label)> _ambientBitChoices = [
    (AmbientStatusBits.sleep, '睡眠(Zzz)'),
    (AmbientStatusBits.paralyzed, '麻痺(||)'),
    (AmbientStatusBits.confused, '混乱(?)'),
    (AmbientStatusBits.stunned, '朦朧(★)'),
    (AmbientStatusBits.levitating, '浮遊(影/弧)'),
    (AmbientStatusBits.stoning, '石化枠'),
    (AmbientStatusBits.slimed, '粘液枠'),
    (AmbientStatusBits.sick, '毒・病枠'),
    (AmbientStatusBits.strangledOrLava, '窒息・溶岩枠'),
    (AmbientStatusBits.confusingHands, '混乱の手'),
  ];

  @override
  void initState() {
    super.initState();
    _screen = NetHackScreen();
    _setupMockDungeon();
    _animController = MapAnimationController(
      vsync: this,
      enabled: true,
      floatingTextEnabled: true,
      isJapanese: true,
      canLiftFloatingGlyph: true,
      tuning: _editingConfig,
    );
    _tileOptions = StudioTileLoader.discoverOptions(includeDiskScan: widget.enableDiskIo);
    if (widget.enableDiskIo) {
      _resolvePathsAndLoad();
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _tileImage?.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _isDirty => _editingConfig != _savedConfig;

  void _setupMockDungeon() {
    _screen.createWindow(3, 3);
    // 中央付近 (x=32..47, y=6..14) に疑似ダンジョン部屋を構築
    for (int y = 6; y <= 14; y++) {
      for (int x = 32; x <= 47; x++) {
        final isWall = y == 6 || y == 14 || x == 32 || x == 47;
        if (isWall) {
          _screen.printGlyph(3, x, y, 1, '-'.codeUnitAt(0), 0xFF90A4AE, 0, 1, '-'.codeUnitAt(0), 0xFF90A4AE);
        } else {
          _screen.printGlyph(3, x, y, 0, '.'.codeUnitAt(0), 0xFF78909C, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
        }
      }
    }
    // 扉・水・溶岩・落とし穴・大岩・主人公・モンスター配置
    _screen.printGlyph(3, 47, 10, 2, '+'.codeUnitAt(0), 0xFFA1887F, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
    _screen.printGlyph(3, 35, 12, 3, '}'.codeUnitAt(0), 0xFF1E88E5, 0, 3, '}'.codeUnitAt(0), 0xFF1E88E5);
    _screen.printGlyph(3, 36, 12, 4, '}'.codeUnitAt(0), 0xFFF4511E, 0, 4, '}'.codeUnitAt(0), 0xFFF4511E);
    _screen.printGlyph(3, _pitX, _pitY, 5, '^'.codeUnitAt(0), 0xFFBA68C8, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
    _screen.printGlyph(3, _boulderX, _boulderY, 6, '`'.codeUnitAt(0), 0xFFCFD8DC, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
    _screen.printGlyph(3, _heroX, _heroY, 10, '@'.codeUnitAt(0), 0xFFFFFFFF, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
    _screen.printGlyph(3, _orcX, _orcY, 11, 'o'.codeUnitAt(0), 0xFF66BB6A, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
    _screen.printGlyph(3, _dragonX, _dragonY, 12, 'D'.codeUnitAt(0), 0xFFEF5350, 0, 0, '.'.codeUnitAt(0), 0xFF78909C);
    _screen.printGlyph(3, 39, 8, 13, 'g'.codeUnitAt(0), 0xFF42A5F5, 0x10 /* MG_PET */, 0, '.'.codeUnitAt(0), 0xFF78909C);
  }

  Directory? _findFlutterRootDir() {
    final candidates = <Directory>[
      Directory.current,
      Directory('${Directory.current.path}/sys/flutter'),
    ];
    for (final d in candidates) {
      if (File('${d.path}/pubspec.yaml').existsSync() &&
          Directory('${d.path}/lib/models').existsSync()) {
        return d;
      }
    }
    try {
      var cur = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 8; i++) {
        final d1 = Directory('${cur.path}/sys/flutter');
        if (File('${d1.path}/pubspec.yaml').existsSync()) return d1;
        if (File('${cur.path}/pubspec.yaml').existsSync() &&
            Directory('${cur.path}/lib/models').existsSync()) {
          return cur;
        }
        final p = cur.parent;
        if (p.path == cur.path) break;
        cur = p;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _resolvePathsAndLoad() async {
    final root = _findFlutterRootDir();
    if (root == null) return;
    _resolvedJsonPath = '${root.path}/tools/vfx_studio/vfx_tuning.json';
    _resolvedDartPath = '${root.path}/lib/models/vfx_tuning_defaults.dart';
    await _loadFromDisk(showSnack: false);
  }

  Future<void> _loadFromDisk({bool showSnack = true}) async {
    final jsonPath = _resolvedJsonPath;
    if (jsonPath == null) return;
    try {
      final file = File(jsonPath);
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final active = decoded['active'] is Map
            ? VfxTuningConfig.fromJson(Map<String, dynamic>.from(decoded['active'] as Map))
            : VfxTuningConfig.fromJson(Map<String, dynamic>.from(decoded));
        final presetsMap = <String, VfxTuningConfig>{};
        if (decoded['presets'] is Map) {
          (decoded['presets'] as Map).forEach((k, v) {
            if (v is Map) {
              presetsMap[k.toString()] =
                  VfxTuningConfig.fromJson(Map<String, dynamic>.from(v));
            }
          });
        }
        if (!mounted) return;
        setState(() {
          _editingConfig = active;
          _savedConfig = active;
          _customPresets = presetsMap;
          _syncControllerTuning();
        });
        if (showSnack && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('vfx_tuning.json を再読み込みしました')),
          );
        }
      }
    } catch (e, st) {
      debugPrint('[VfxStudio] Failed to load JSON: $e\n$st');
    }
  }

  Future<void> _saveToDisk() async {
    if (!widget.enableDiskIo) return;
    final root = _findFlutterRootDir();
    if (root == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存エラー: sys/flutter ルートが見つかりません')),
      );
      return;
    }
    final jsonPath = _resolvedJsonPath ?? '${root.path}/tools/vfx_studio/vfx_tuning.json';
    final dartPath = _resolvedDartPath ?? '${root.path}/lib/models/vfx_tuning_defaults.dart';

    try {
      final doc = {
        'version': 1,
        'active': _editingConfig.toJson(),
        'presets': {
          for (final e in _customPresets.entries) e.key: e.value.toJson(),
        },
      };
      final formattedJson = '${const JsonEncoder.withIndent('  ').convert(doc)}\n';
      final jsonFile = File(jsonPath);
      await jsonFile.parent.create(recursive: true);
      await jsonFile.writeAsString(formattedJson);

      final dartFile = File(dartPath);
      await dartFile.writeAsString(_editingConfig.toDartConstSource());

      if (!mounted) return;
      setState(() {
        _savedConfig = _editingConfig;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存完了: vfx_tuning.json と vfx_tuning_defaults.dart を同時更新しました'),
        ),
      );
    } catch (e, st) {
      debugPrint('[VfxStudio] Save error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失敗: $e')),
      );
    }
  }

  void _updateConfig(VfxTuningConfig next) {
    setState(() {
      _editingConfig = next;
      _syncControllerTuning();
    });
  }

  void _syncControllerTuning() {
    _animController.tuning = _abCompareStandard ? _standardDefaults : _editingConfig;
  }

  Future<void> _selectDisplayOption(StudioTilesetOption? option) async {
    if (option == null) {
      setState(() {
        _selectedTileOption = null;
        _animController.canLiftFloatingGlyph = true;
      });
      return;
    }
    final img = await StudioTileLoader.loadImage(option);
    if (!mounted) {
      img.dispose();
      return;
    }
    final old = _tileImage;
    setState(() {
      _selectedTileOption = option;
      _tileImage = img;
      _animController.canLiftFloatingGlyph = option.isTransparent;
    });
    old?.dispose();
  }

  void _setRepeat(bool value) {
    setState(() {
      _repeatEnabled = value;
    });
    _repeatTimer?.cancel();
    _repeatTimer = null;
    if (value) {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 1150), (_) {
        if (!mounted) return;
        _lastTriggerAction?.call();
      });
    }
  }

  void _runTrigger(String label, VoidCallback action) {
    setState(() {
      _lastTriggerLabel = label;
      _lastTriggerAction = action;
    });
    action();
  }

  void _syncAmbientEvents() {
    _animController.handleEvent(MapAnimEvent(
      turnId: _turnCounter++,
      eventType: MapAnimEventType.ambientStatus,
      entityId: _ambientMaskHero,
      fromX: _heroX,
      fromY: _heroY,
      toX: _heroX,
      toY: _heroY,
    ));
    _animController.handleEvent(MapAnimEvent(
      turnId: _turnCounter++,
      eventType: MapAnimEventType.ambientStatus,
      entityId: _enemyFleeing ? AmbientStatusBits.fleeing : 0,
      fromX: _orcX,
      fromY: _orcY,
      toX: _orcX,
      toY: _orcY,
    ));
  }

  Future<void> _promptSaveCustomPreset() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: const Text('カスタムプリセット保存'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'プリセット名を入力'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() {
      _customPresets = {..._customPresets, name: _editingConfig};
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFF121418),
        appBar: _buildHeaderBar(),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: _buildLeftPreviewPane(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 10,
              child: _buildRightTuningPane(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeaderBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B1F27),
      titleSpacing: 12,
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF80D8FF), size: 20),
          const SizedBox(width: 8),
          const Text('DartHack VFX Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (_isDirty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '未保存 (Modified)',
                style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // A/B 比較トグル
        FilterChip(
          label: Text(_abCompareStandard ? 'A/B比較: 標準値プレビュー中' : 'A/B比較 (標準値で見る)'),
          selected: _abCompareStandard,
          selectedColor: const Color(0xFF00695C),
          onSelected: (v) {
            setState(() {
              _abCompareStandard = v;
              _syncControllerTuning();
            });
          },
        ),
        const SizedBox(width: 8),
        // プリセットメニュー
        PopupMenuButton<String>(
          tooltip: 'プリセット切替・管理',
          onSelected: (key) {
            if (key == '__std__') {
              _updateConfig(VfxTuningConfig.defaults());
            } else if (key == '__subtle__') {
              _updateConfig(VfxTuningConfig.subtle());
            } else if (key == '__vivid__') {
              _updateConfig(VfxTuningConfig.vivid());
            } else if (key == '__save_preset__') {
              _promptSaveCustomPreset();
            } else if (key.startsWith('use:')) {
              final name = key.substring(4);
              final cfg = _customPresets[name];
              if (cfg != null) _updateConfig(cfg);
            } else if (key.startsWith('del:')) {
              final name = key.substring(4);
              setState(() {
                final next = Map<String, VfxTuningConfig>.from(_customPresets)..remove(name);
                _customPresets = next;
              });
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: '__std__', child: Text('組み込み: 標準 (Defaults)')),
            const PopupMenuItem(value: '__subtle__', child: Text('組み込み: 控えめ (Subtle)')),
            const PopupMenuItem(value: '__vivid__', child: Text('組み込み: 派手 (Vivid)')),
            const PopupMenuDivider(),
            for (final name in _customPresets.keys)
              PopupMenuItem(
                value: 'use:$name',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('カスタム: $name'),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () {
                        Navigator.pop(ctx, 'del:$name');
                      },
                    ),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: '__save_preset__',
              child: Text('+ 現在の設定をプリセット保存...'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(Icons.bookmarks_outlined, size: 18),
                SizedBox(width: 4),
                Text('プリセット'),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'JSONをクリップボードにコピー',
          icon: const Icon(Icons.copy_all, size: 20),
          onPressed: () {
            final text = const JsonEncoder.withIndent('  ').convert(_editingConfig.toJson());
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('現在のJSONをクリップボードへコピーしました')),
            );
          },
        ),
        TextButton.icon(
          onPressed: () => _updateConfig(const VfxTuningConfig()),
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('全て標準へ'),
        ),
        if (widget.enableDiskIo)
          TextButton.icon(
            onPressed: () => _loadFromDisk(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('再読込'),
          ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
            onPressed: _saveToDisk,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('保存 (JSON + Dart定数)'),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPreviewPane() {
    final useTiles = _selectedTileOption != null && _tileImage != null;
    final tileW = _selectedTileOption?.tileWidth ?? 32;
    final tileH = _selectedTileOption?.tileHeight ?? 32;
    final isTransparent = _selectedTileOption?.isTransparent ?? false;

    final cellSize = FontManager.instance.getMapCellSize(
      useTiles: useTiles,
      tileWidth: tileW,
      tileHeight: tileH,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // プレビュー制御ツールバー
        Container(
          color: const Color(0xFF181C24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<StudioTilesetOption?>(
                value: _selectedTileOption,
                isDense: true,
                items: [
                  const DropdownMenuItem<StudioTilesetOption?>(
                    value: null,
                    child: Text('テキストモード (ASCII)'),
                  ),
                  for (final opt in _tileOptions)
                    DropdownMenuItem<StudioTilesetOption?>(
                      value: opt,
                      child: Text(opt.label),
                    ),
                ],
                onChanged: _selectDisplayOption,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ズーム:', style: TextStyle(fontSize: 12)),
                  SizedBox(
                    width: 110,
                    child: Slider(
                      value: _previewZoom,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      label: '${_previewZoom.toStringAsFixed(1)}x',
                      onChanged: (v) => setState(() => _previewZoom = v),
                    ),
                  ),
                  Text('${_previewZoom.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
                ],
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('JP')),
                  ButtonSegment(value: false, label: Text('EN')),
                ],
                selected: {_animController.isJapanese},
                onSelectionChanged: (s) => setState(() => _animController.isJapanese = s.first),
              ),
              SegmentedButton<MapAnimationSpeed>(
                segments: const [
                  ButtonSegment(value: MapAnimationSpeed.fast, label: Text('速')),
                  ButtonSegment(value: MapAnimationSpeed.normal, label: Text('標')),
                  ButtonSegment(value: MapAnimationSpeed.slow, label: Text('遅')),
                ],
                selected: {_animController.speed},
                onSelectionChanged: (s) => setState(() => _animController.speed = s.first),
              ),
              FilterChip(
                label: Text('リピート ($_lastTriggerLabel)'),
                selected: _repeatEnabled,
                onSelected: _setRepeat,
              ),
              OutlinedButton.icon(
                onPressed: () => _animController.snapAll(minAcceptedTurnId: ++_turnCounter),
                icon: const Icon(Icons.stop_circle_outlined, size: 16),
                label: const Text('クリア'),
              ),
            ],
          ),
        ),
        // ライブプレビューキャンバス
        Expanded(
          flex: 5,
          child: ClipRect(
            child: Container(
              color: Colors.black,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 4000x3000 キャンバス上の主人公セル (_heroX, _heroY) をビューポート中央に配置
                  const canvasW = 4000.0;
                  const canvasH = 3000.0;
                  final mapW = NetHackScreen.mapCols * cellSize.width;
                  final mapH = NetHackScreen.mapRows * cellSize.height;
                  final mapOffX = (canvasW - mapW) / 2.0;
                  final mapOffY = (canvasH - mapH) / 2.0;
                  final heroPxX = mapOffX + (_heroX + 0.5) * cellSize.width;
                  final heroPxY = mapOffY + (_heroY + 0.5) * cellSize.height;
                  final tx = constraints.maxWidth / 2.0 - heroPxX * _previewZoom;
                  final ty = constraints.maxHeight / 2.0 - heroPxY * _previewZoom;

                  return ValueListenableBuilder<Offset>(
                    valueListenable: _animController.screenShakeNotifier,
                    builder: (context, shake, child) {
                      return Transform(
                        transform: Matrix4(
                          _previewZoom, 0, 0, 0,
                          0, _previewZoom, 0, 0,
                          0, 0, _previewZoom, 0,
                          tx + shake.dx, ty + shake.dy, 0, 1,
                        ),
                        child: child,
                      );
                    },
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: canvasW,
                      maxWidth: canvasW,
                      minHeight: canvasH,
                      maxHeight: canvasH,
                      child: SizedBox(
                        width: canvasW,
                        height: canvasH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: NetHackMapPainter(
                                  screen: _screen,
                                  tileImage: _tileImage,
                                  tileWidth: tileW,
                                  tileHeight: tileH,
                                  useTiles: useTiles,
                                  isTransparentTileset: isTransparent,
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: CustomPaint(
                                painter: NetHackAnimationOverlayPainter(
                                  screen: _screen,
                                  animationController: _animController,
                                  tileImage: _tileImage,
                                  tileWidth: tileW,
                                  tileHeight: tileH,
                                  useTiles: useTiles,
                                  isTransparentTileset: isTransparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // トリガーデッキ
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTriggerSectionTitle('1. 移動・岩押し・蹴り・戦闘'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _trigBtn('1歩移動', () {
                      _animController.handleEvent(MapAnimEvent(
                        turnId: _turnCounter++,
                        eventType: MapAnimEventType.move,
                        entityId: 0,
                        fromX: _heroX - 1,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                        param1: 10,
                        param2: '@'.codeUnitAt(0),
                        param3: 0xFFFFFFFF,
                      ));
                    }),
                    _trigBtn('通常岩押し+砂埃', () {
                      final t = _turnCounter++;
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.objectMove,
                        entityId: MapObjectMoveKind.persistent,
                        fromX: _boulderX + 1,
                        fromY: _boulderY,
                        toX: _boulderX,
                        toY: _boulderY,
                        param1: 6,
                        param2: '`'.codeUnitAt(0),
                        param3: 0xFFCFD8DC,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.vfx,
                        entityId: MapVfxKind.dust,
                        fromX: _boulderX + 1,
                        fromY: _boulderY,
                        toX: _boulderX,
                        toY: _boulderY,
                      ));
                    }),
                    _trigBtn('消滅岩押し(穴落)', () {
                      _animController.handleEvent(MapAnimEvent(
                        turnId: _turnCounter++,
                        eventType: MapAnimEventType.objectMove,
                        entityId: MapObjectMoveKind.vanishing,
                        fromX: _boulderX,
                        fromY: _boulderY,
                        toX: _pitX,
                        toY: _pitY,
                        param1: 6,
                        param2: '`'.codeUnitAt(0),
                        param3: 0xFFCFD8DC,
                      ));
                    }),
                    _trigBtn('遠距離蹴り・投擲', () {
                      final t = _turnCounter++;
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.attack,
                        entityId: 0,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _orcX,
                        toY: _orcY,
                        param1: 0,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.vfx,
                        entityId: MapVfxKind.kickImpact,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _orcX,
                        toY: _orcY,
                      ));
                      for (int x = _heroX; x < _dragonX; x++) {
                        _animController.handleEvent(MapAnimEvent(
                          turnId: t,
                          eventType: MapAnimEventType.projectile,
                          entityId: 0,
                          fromX: x,
                          fromY: _heroY,
                          toX: x + 1,
                          toY: _heroY,
                          param1: 7,
                          param2: ')'.codeUnitAt(0),
                          param3: 0xFFFFEE58,
                        ));
                      }
                    }),
                    _trigBtn('近接命中', () {
                      final t = _turnCounter++;
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.attack,
                        entityId: 0,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _orcX,
                        toY: _orcY,
                        param1: 1,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.dmgMon,
                        fromX: _orcX,
                        fromY: _orcY,
                        toX: _orcX,
                        toY: _orcY,
                        param1: 16,
                      ));
                    }),
                    _trigBtn('近接ミス', () {
                      final t = _turnCounter++;
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.attack,
                        entityId: 0,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _orcX,
                        toY: _orcY,
                        param1: 0,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.miss,
                        fromX: _orcX,
                        fromY: _orcY,
                        toX: _orcX,
                        toY: _orcY,
                      ));
                    }),
                    _trigBtn('死亡フェード', () {
                      _animController.handleEvent(MapAnimEvent(
                        turnId: _turnCounter++,
                        eventType: MapAnimEventType.death,
                        entityId: 99,
                        fromX: _dragonX,
                        fromY: _dragonY,
                        toX: _dragonX,
                        toY: _dragonY,
                        param1: 12,
                        param2: 'D'.codeUnitAt(0),
                        param3: 0xFFEF5350,
                      ));
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTriggerSectionTitle('2. パーティクル・光リング・シェイク VFX'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _trigBtn('砂埃', () => _fireVfx(MapVfxKind.dust, _boulderX, _boulderY)),
                    _trigBtn('扉弱打', () => _fireVfx(MapVfxKind.woodDebris, 47, 10, p2: 1)),
                    _trigBtn('扉蹴破り(揺)', () => _fireVfx(MapVfxKind.woodDebris, 47, 10, p2: 2)),
                    _trigBtn('壁掘削', () => _fireVfx(MapVfxKind.rockDebris, 39, 6)),
                    _trigBtn('薬飛沫', () => _fireVfx(MapVfxKind.potionSplash, _orcX, _orcY)),
                    _trigBtn('爆発(揺)', () => _fireVfx(MapVfxKind.explosion, _orcX + 1, _orcY)),
                    _trigBtn('テレポート(発着)', () {
                      _animController.handleEvent(MapAnimEvent(
                        turnId: _turnCounter++,
                        eventType: MapAnimEventType.vfx,
                        entityId: MapVfxKind.teleport,
                        fromX: _heroX - 3,
                        fromY: _heroY - 2,
                        toX: _heroX,
                        toY: _heroY,
                      ));
                    }),
                    _trigBtn('レベルアップVFX', () {
                      final t = _turnCounter++;
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.vfx,
                        entityId: MapVfxKind.levelUp,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.levelUp,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                      ));
                    }),
                    _trigBtn('通常召喚', () => _fireVfx(MapVfxKind.summon, _orcX, _orcY + 1, p2: 0)),
                    _trigBtn('悪魔召喚', () => _fireVfx(MapVfxKind.summon, _orcX, _orcY + 1, p2: 1)),
                    _trigBtn('天使召喚', () => _fireVfx(MapVfxKind.summon, _orcX, _orcY + 1, p2: 2)),
                    _trigBtn('大被弾シェイク', () => _fireVfx(MapVfxKind.bigHitShake, _heroX, _heroY)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTriggerSectionTitle('3. フローティングテキスト & 状態変化'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _trigBtn('主人公被ダメ', () => _fireFloat(FloatingTextKind.dmgHero, _heroX, _heroY, 18)),
                    _trigBtn('敵ダメ', () => _fireFloat(FloatingTextKind.dmgMon, _orcX, _orcY, 24)),
                    _trigBtn('MISS', () => _fireFloat(FloatingTextKind.miss, _orcX, _orcY, 0)),
                    _trigBtn('HP回復', () => _fireFloat(FloatingTextKind.healHp, _heroX, _heroY, 22)),
                    _trigBtn('Pw回復', () => _fireFloat(FloatingTextKind.healPw, _heroX, _heroY, 14)),
                    _trigBtn('同セル4件スタガー', () {
                      final t = _turnCounter++;
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.miss,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.dmgHero,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                        param1: 19,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.statusGain,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                        param1: StatusTextCode.confused,
                      ));
                      _animController.handleEvent(MapAnimEvent(
                        turnId: t,
                        eventType: MapAnimEventType.floatingText,
                        entityId: FloatingTextKind.statusGain,
                        fromX: _heroX,
                        fromY: _heroY,
                        toX: _heroX,
                        toY: _heroY,
                        param1: StatusTextCode.stoning,
                      ));
                    }),
                    DropdownButton<int>(
                      value: _selectedStatusCode,
                      isDense: true,
                      items: [
                        for (final item in _statusChoices)
                          DropdownMenuItem(value: item.$1, child: Text(item.$2, style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedStatusCode = v);
                      },
                    ),
                    _trigBtn('状態テキスト発火', () {
                      _fireFloat(FloatingTextKind.statusGain, _heroX, _heroY, _selectedStatusCode);
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTriggerSectionTitle('4. 持続的な状態マイクロ演出 (11ビット組み合わせ)'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in _ambientBitChoices)
                      FilterChip(
                        label: Text(entry.$2, style: const TextStyle(fontSize: 12)),
                        selected: (_ambientMaskHero & entry.$1) != 0,
                        onSelected: (on) {
                          setState(() {
                            if (on) {
                              _ambientMaskHero |= entry.$1;
                            } else {
                              _ambientMaskHero &= ~entry.$1;
                            }
                            _syncAmbientEvents();
                          });
                        },
                      ),
                    FilterChip(
                      label: const Text('敵: 逃走(汗)', style: TextStyle(fontSize: 12)),
                      selected: _enemyFleeing,
                      onSelected: (on) {
                        setState(() {
                          _enemyFleeing = on;
                          _syncAmbientEvents();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _fireVfx(int kind, int x, int y, {int p1 = 0, int p2 = 1}) {
    _animController.handleEvent(MapAnimEvent(
      turnId: _turnCounter++,
      eventType: MapAnimEventType.vfx,
      entityId: kind,
      fromX: x,
      fromY: y,
      toX: x,
      toY: y,
      param1: p1,
      param2: p2,
    ));
  }

  void _fireFloat(int kind, int x, int y, int param1) {
    _animController.handleEvent(MapAnimEvent(
      turnId: _turnCounter++,
      eventType: MapAnimEventType.floatingText,
      entityId: kind,
      fromX: x,
      fromY: y,
      toX: x,
      toY: y,
      param1: param1,
    ));
  }

  Widget _trigBtn(String label, VoidCallback action) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: () => _runTrigger(label, action),
      child: Text(label),
    );
  }

  Widget _buildTriggerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF80D8FF)),
      ),
    );
  }

  Widget _buildRightTuningPane() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF181C24),
          child: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '移動・戦闘'),
              Tab(text: 'VFX粒子'),
              Tab(text: '光リング'),
              Tab(text: 'テキスト'),
              Tab(text: '持続状態'),
              Tab(text: 'シェイク・上限'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildMotionTab(),
              _buildParticlesTab(),
              _buildRingsTab(),
              _buildFloatingTextTab(),
              _buildAmbientTab(),
              _buildShakeAndLimitsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotionTab() {
    final m = _editingConfig.motion;
    const d = MotionTuning();
    void setM(MotionTuning next) => _updateConfig(_editingConfig.copyWith(motion: next));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _IntTuningRow(
          label: '移動時間 (moveMs)',
          value: m.moveMs,
          defaultValue: d.moveMs,
          min: 30,
          max: 400,
          onChanged: (v) => setM(m.copyWith(moveMs: v)),
        ),
        _DoubleTuningRow(
          label: '歩行ホップ高さ (moveHopHeightRatio)',
          value: m.moveHopHeightRatio,
          defaultValue: d.moveHopHeightRatio,
          min: 0.0,
          max: 0.35,
          onChanged: (v) => setM(m.copyWith(moveHopHeightRatio: v)),
        ),
        _IntTuningRow(
          label: 'カメラ追従時間 (cameraFollowMs)',
          value: m.cameraFollowMs,
          defaultValue: d.cameraFollowMs,
          min: 30,
          max: 400,
          onChanged: (v) => setM(m.copyWith(cameraFollowMs: v)),
        ),
        _IntTuningRow(
          label: '近接攻撃バンプ時間 (attackBumpMs)',
          value: m.attackBumpMs,
          defaultValue: d.attackBumpMs,
          min: 40,
          max: 400,
          onChanged: (v) => setM(m.copyWith(attackBumpMs: v)),
        ),
        _DoubleTuningRow(
          label: '近接バンプ踏み込み幅 (attackBumpDistance)',
          value: m.attackBumpDistance,
          defaultValue: d.attackBumpDistance,
          min: 0.05,
          max: 0.80,
          onChanged: (v) => setM(m.copyWith(attackBumpDistance: v)),
        ),
        _IntTuningRow(
          label: '被弾フィードバック時間 (hitFeedbackMs)',
          value: m.hitFeedbackMs,
          defaultValue: d.hitFeedbackMs,
          min: 40,
          max: 500,
          onChanged: (v) => setM(m.copyWith(hitFeedbackMs: v)),
        ),
        _DoubleTuningRow(
          label: '被弾横揺れ幅 (hitShakeRatio)',
          value: m.hitShakeRatio,
          defaultValue: d.hitShakeRatio,
          min: 0.0,
          max: 0.45,
          onChanged: (v) => setM(m.copyWith(hitShakeRatio: v)),
        ),
        _DoubleTuningRow(
          label: '被弾フラッシュ強度 (hitFlashAlpha)',
          value: m.hitFlashAlpha,
          defaultValue: d.hitFlashAlpha,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => setM(m.copyWith(hitFlashAlpha: v)),
        ),
        _ColorTuningRow(
          label: '被弾フラッシュ色',
          value: m.hitFlashColor,
          defaultValue: d.hitFlashColor,
          onChanged: (v) => setM(m.copyWith(hitFlashColor: v)),
        ),
        _IntTuningRow(
          label: '死亡フェード時間 (deathFadeMs)',
          value: m.deathFadeMs,
          defaultValue: d.deathFadeMs,
          min: 60,
          max: 800,
          onChanged: (v) => setM(m.copyWith(deathFadeMs: v)),
        ),
        _DoubleTuningRow(
          label: '死亡終了スケール (deathEndScale)',
          value: m.deathEndScale,
          defaultValue: d.deathEndScale,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => setM(m.copyWith(deathEndScale: v)),
        ),
        _IntTuningRow(
          label: '飛び道具1マス時間 (projectileStepMs)',
          value: m.projectileStepMs,
          defaultValue: d.projectileStepMs,
          min: 16,
          max: 200,
          onChanged: (v) => setM(m.copyWith(projectileStepMs: v)),
        ),
        _IntTuningRow(
          label: '飛び道具最大総時間 (projectileMaxTotalMs)',
          value: m.projectileMaxTotalMs,
          defaultValue: d.projectileMaxTotalMs,
          min: 60,
          max: 800,
          onChanged: (v) => setM(m.copyWith(projectileMaxTotalMs: v)),
        ),
        _DoubleTuningRow(
          label: '消滅岩フェード開始位置 (vanishFadeStartT)',
          value: m.vanishFadeStartT,
          defaultValue: d.vanishFadeStartT,
          min: 0.1,
          max: 0.9,
          onChanged: (v) => setM(m.copyWith(vanishFadeStartT: v)),
        ),
        _DoubleTuningRow(
          label: '消滅岩終了スケール (vanishEndScale)',
          value: m.vanishEndScale,
          defaultValue: d.vanishEndScale,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => setM(m.copyWith(vanishEndScale: v)),
        ),
        const Divider(),
        _DoubleTuningRow(
          label: '速度倍率: 速い (speedFastMultiplier)',
          value: m.speedFastMultiplier,
          defaultValue: d.speedFastMultiplier,
          min: 0.25,
          max: 1.0,
          onChanged: (v) => setM(m.copyWith(speedFastMultiplier: v)),
        ),
        _DoubleTuningRow(
          label: '速度倍率: 標準 (speedNormalMultiplier)',
          value: m.speedNormalMultiplier,
          defaultValue: d.speedNormalMultiplier,
          min: 0.5,
          max: 2.0,
          onChanged: (v) => setM(m.copyWith(speedNormalMultiplier: v)),
        ),
        _DoubleTuningRow(
          label: '速度倍率: 遅い (speedSlowMultiplier)',
          value: m.speedSlowMultiplier,
          defaultValue: d.speedSlowMultiplier,
          min: 1.0,
          max: 4.0,
          onChanged: (v) => setM(m.copyWith(speedSlowMultiplier: v)),
        ),
      ],
    );
  }

  Widget _buildParticlesTab() {
    final p = _editingConfig.particleOf(_selectedParticleKey);
    final d = VfxTuningConfig.defaultParticles[_selectedParticleKey]!;
    void setP(ParticleEffectTuning next) {
      final nextMap = Map<String, ParticleEffectTuning>.from(_editingConfig.particles);
      nextMap[_selectedParticleKey] = next;
      _updateConfig(_editingConfig.copyWith(particles: nextMap));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text('編集対象の粒子VFX: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedParticleKey,
              items: [
                for (final k in VfxTuningConfig.particleKeys)
                  DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedParticleKey = v);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _IntTuningRow(
          label: '発生粒数 (count)',
          value: p.count,
          defaultValue: d.count,
          min: 1,
          max: 40,
          onChanged: (v) => setP(p.copyWith(count: v)),
        ),
        _DoubleTuningRow(
          label: '最小初速 (speedMin)',
          value: p.speedMin,
          defaultValue: d.speedMin,
          min: 0.0,
          max: 5.0,
          onChanged: (v) => setP(p.copyWith(speedMin: v)),
        ),
        _DoubleTuningRow(
          label: '最大初速 (speedMax)',
          value: p.speedMax,
          defaultValue: d.speedMax,
          min: 0.1,
          max: 6.0,
          onChanged: (v) => setP(p.copyWith(speedMax: v)),
        ),
        _DoubleTuningRow(
          label: '重力加速度 (gravity ※負で上昇)',
          value: p.gravity,
          defaultValue: d.gravity,
          min: -4.0,
          max: 6.0,
          onChanged: (v) => setP(p.copyWith(gravity: v)),
        ),
        _DoubleTuningRow(
          label: '最小サイズ比 (sizeMin)',
          value: p.sizeMin,
          defaultValue: d.sizeMin,
          min: 0.03,
          max: 0.40,
          onChanged: (v) => setP(p.copyWith(sizeMin: v)),
        ),
        _DoubleTuningRow(
          label: '最大サイズ比 (sizeMax)',
          value: p.sizeMax,
          defaultValue: d.sizeMax,
          min: 0.04,
          max: 0.50,
          onChanged: (v) => setP(p.copyWith(sizeMax: v)),
        ),
        _IntTuningRow(
          label: '持続時間 (durationMs)',
          value: p.durationMs,
          defaultValue: d.durationMs,
          min: 60,
          max: 1000,
          onChanged: (v) => setP(p.copyWith(durationMs: v)),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('発光ハロー描画 (isGlow)', style: TextStyle(fontSize: 13)),
          value: p.isGlow,
          onChanged: (v) => setP(p.copyWith(isGlow: v)),
        ),
        _ColorTuningRow(
          label: '基準カラー (defaultColor ※薬・爆発は動的色優先)',
          value: p.defaultColor,
          defaultValue: d.defaultColor,
          onChanged: (v) => setP(p.copyWith(defaultColor: v)),
        ),
        const Divider(),
        const Text('召喚サブタイプ別カラー (非幻覚時)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        _ColorTuningRow(
          label: '通常召喚色 (summonNormalColor)',
          value: _editingConfig.summonNormalColor,
          defaultValue: _standardDefaults.summonNormalColor,
          onChanged: (v) => _updateConfig(_editingConfig.copyWith(summonNormalColor: v)),
        ),
        _ColorTuningRow(
          label: '悪魔召喚色 (summonDemonColor)',
          value: _editingConfig.summonDemonColor,
          defaultValue: _standardDefaults.summonDemonColor,
          onChanged: (v) => _updateConfig(_editingConfig.copyWith(summonDemonColor: v)),
        ),
        _ColorTuningRow(
          label: '天使召喚色 (summonAngelColor)',
          value: _editingConfig.summonAngelColor,
          defaultValue: _standardDefaults.summonAngelColor,
          onChanged: (v) => _updateConfig(_editingConfig.copyWith(summonAngelColor: v)),
        ),
      ],
    );
  }

  Widget _buildRingsTab() {
    final r = _editingConfig.ringOf(_selectedRingKey);
    final d = VfxTuningConfig.defaultRings[_selectedRingKey]!;
    void setR(RingEffectTuning next) {
      final nextMap = Map<String, RingEffectTuning>.from(_editingConfig.rings);
      nextMap[_selectedRingKey] = next;
      _updateConfig(_editingConfig.copyWith(rings: nextMap));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text('編集対象の光リング: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedRingKey,
              items: [
                for (final k in VfxTuningConfig.ringKeys)
                  DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedRingKey = v);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DoubleTuningRow(
          label: '開始半径 [セル比] (startRadiusCells)',
          value: r.startRadiusCells,
          defaultValue: d.startRadiusCells,
          min: 0.05,
          max: 2.5,
          onChanged: (v) => setR(r.copyWith(startRadiusCells: v)),
        ),
        _DoubleTuningRow(
          label: '終了半径 [セル比] (endRadiusCells)',
          value: r.endRadiusCells,
          defaultValue: d.endRadiusCells,
          min: 0.05,
          max: 3.5,
          onChanged: (v) => setR(r.copyWith(endRadiusCells: v)),
        ),
        _DoubleTuningRow(
          label: '線幅比率 (strokeRatio)',
          value: r.strokeRatio,
          defaultValue: d.strokeRatio,
          min: 0.02,
          max: 0.35,
          onChanged: (v) => setR(r.copyWith(strokeRatio: v)),
        ),
        _IntTuningRow(
          label: '持続時間 (durationMs)',
          value: r.durationMs,
          defaultValue: d.durationMs,
          min: 60,
          max: 1000,
          onChanged: (v) => setR(r.copyWith(durationMs: v)),
        ),
        _ColorTuningRow(
          label: 'リング色 (color)',
          value: r.color,
          defaultValue: d.color,
          onChanged: (v) => setR(r.copyWith(color: v)),
        ),
      ],
    );
  }

  Widget _buildFloatingTextTab() {
    final ft = _editingConfig.floatingText;
    const d = FloatingTextTuning();
    void setFt(FloatingTextTuning next) => _updateConfig(_editingConfig.copyWith(floatingText: next));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _IntTuningRow(
          label: '表示時間 (durationMs)',
          value: ft.durationMs,
          defaultValue: d.durationMs,
          min: 200,
          max: 1800,
          onChanged: (v) => setFt(ft.copyWith(durationMs: v)),
        ),
        _IntTuningRow(
          label: '同セル発射ディレイ (staggerMs)',
          value: ft.staggerMs,
          defaultValue: d.staggerMs,
          min: 0,
          max: 300,
          onChanged: (v) => setFt(ft.copyWith(staggerMs: v)),
        ),
        _DoubleTuningRow(
          label: '上昇セル量 (riseCells)',
          value: ft.riseCells,
          defaultValue: d.riseCells,
          min: 0.1,
          max: 2.5,
          onChanged: (v) => setFt(ft.copyWith(riseCells: v)),
        ),
        _DoubleTuningRow(
          label: 'スタック段差セル量 (stackSpacingCells)',
          value: ft.stackSpacingCells,
          defaultValue: d.stackSpacingCells,
          min: 0.1,
          max: 1.2,
          onChanged: (v) => setFt(ft.copyWith(stackSpacingCells: v)),
        ),
        _DoubleTuningRow(
          label: '文字サイズ比率 (fontSizeRatio)',
          value: ft.fontSizeRatio,
          defaultValue: d.fontSizeRatio,
          min: 0.25,
          max: 0.85,
          onChanged: (v) => setFt(ft.copyWith(fontSizeRatio: v)),
        ),
        _DoubleTuningRow(
          label: '出現ポップ最大倍率 (popScaleMax)',
          value: ft.popScaleMax,
          defaultValue: d.popScaleMax,
          min: 1.0,
          max: 1.6,
          onChanged: (v) => setFt(ft.copyWith(popScaleMax: v)),
        ),
        _DoubleTuningRow(
          label: '黒縁取り不透明度 (outlineAlpha)',
          value: ft.outlineAlpha,
          defaultValue: d.outlineAlpha,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => setFt(ft.copyWith(outlineAlpha: v)),
        ),
        const Divider(),
        const Text('基本イベント色', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        _ColorTuningRow(
          label: '主人公被ダメージ (dmgHeroColor)',
          value: ft.dmgHeroColor,
          defaultValue: d.dmgHeroColor,
          onChanged: (v) => setFt(ft.copyWith(dmgHeroColor: v)),
        ),
        _ColorTuningRow(
          label: '敵与ダメージ (dmgMonColor)',
          value: ft.dmgMonColor,
          defaultValue: d.dmgMonColor,
          onChanged: (v) => setFt(ft.copyWith(dmgMonColor: v)),
        ),
        _ColorTuningRow(
          label: 'MISS (missColor)',
          value: ft.missColor,
          defaultValue: d.missColor,
          onChanged: (v) => setFt(ft.copyWith(missColor: v)),
        ),
        _ColorTuningRow(
          label: 'HP回復 (healHpColor)',
          value: ft.healHpColor,
          defaultValue: d.healHpColor,
          onChanged: (v) => setFt(ft.copyWith(healHpColor: v)),
        ),
        _ColorTuningRow(
          label: 'Pw回復 (healPwColor)',
          value: ft.healPwColor,
          defaultValue: d.healPwColor,
          onChanged: (v) => setFt(ft.copyWith(healPwColor: v)),
        ),
        _ColorTuningRow(
          label: 'LEVEL UP! (levelUpColor)',
          value: ft.levelUpColor,
          defaultValue: d.levelUpColor,
          onChanged: (v) => setFt(ft.copyWith(levelUpColor: v)),
        ),
        const Divider(),
        const Text('状態変化 9 カテゴリパレット', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        _ColorTuningRow(
          label: '致死危機 [石化・窒息・飢餓・過積載]',
          value: ft.statusLethalColor,
          defaultValue: d.statusLethalColor,
          onChanged: (v) => setFt(ft.copyWith(statusLethalColor: v)),
        ),
        _ColorTuningRow(
          label: '粘液化 [Slimed]',
          value: ft.statusSlimeColor,
          defaultValue: d.statusSlimeColor,
          onChanged: (v) => setFt(ft.copyWith(statusSlimeColor: v)),
        ),
        _ColorTuningRow(
          label: '食中毒・病気',
          value: ft.statusSicknessColor,
          defaultValue: d.statusSicknessColor,
          onChanged: (v) => setFt(ft.copyWith(statusSicknessColor: v)),
        ),
        _ColorTuningRow(
          label: '重度危険 [溶岩・丸呑み・超過重]',
          value: ft.statusDangerColor,
          defaultValue: d.statusDangerColor,
          onChanged: (v) => setFt(ft.copyWith(statusDangerColor: v)),
        ),
        _ColorTuningRow(
          label: '精神異常 [混乱・朦朧・幻覚]',
          value: ft.statusMentalColor,
          defaultValue: d.statusMentalColor,
          onChanged: (v) => setFt(ft.copyWith(statusMentalColor: v)),
        ),
        _ColorTuningRow(
          label: '行動不能・逃走 [麻痺・睡眠・失神・逃走]',
          value: ft.statusImmobilizeColor,
          defaultValue: d.statusImmobilizeColor,
          onChanged: (v) => setFt(ft.copyWith(statusImmobilizeColor: v)),
        ),
        _ColorTuningRow(
          label: '拘束・消耗 [罠・脚傷・空腹・重荷]',
          value: ft.statusImpairColor,
          defaultValue: d.statusImpairColor,
          onChanged: (v) => setFt(ft.copyWith(statusImpairColor: v)),
        ),
        _ColorTuningRow(
          label: '移動・感覚 [浮遊・飛行・透明・盲目・難聴]',
          value: ft.statusMovementColor,
          defaultValue: d.statusMovementColor,
          onChanged: (v) => setFt(ft.copyWith(statusMovementColor: v)),
        ),
        _ColorTuningRow(
          label: '強化・その他 [加速・満腹・騎乗・発光]',
          value: ft.statusBuffColor,
          defaultValue: d.statusBuffColor,
          onChanged: (v) => setFt(ft.copyWith(statusBuffColor: v)),
        ),
      ],
    );
  }

  Widget _buildAmbientTab() {
    final a = _editingConfig.ambient;
    const d = AmbientStatusTuning();
    void setA(AmbientStatusTuning next) => _updateConfig(_editingConfig.copyWith(ambient: next));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _DoubleTuningRow(
          label: '浮遊上浮きオフセット (floatLiftDy ※負で上)',
          value: a.floatLiftDy,
          defaultValue: d.floatLiftDy,
          min: -0.35,
          max: 0.0,
          onChanged: (v) => setA(a.copyWith(floatLiftDy: v)),
        ),
        _DoubleTuningRow(
          label: '浮遊ドロップシャドウ幅比 (shadowWidthRatio)',
          value: a.shadowWidthRatio,
          defaultValue: d.shadowWidthRatio,
          min: 0.2,
          max: 0.95,
          onChanged: (v) => setA(a.copyWith(shadowWidthRatio: v)),
        ),
        _DoubleTuningRow(
          label: '浮遊ドロップシャドウ高比 (shadowHeightRatio)',
          value: a.shadowHeightRatio,
          defaultValue: d.shadowHeightRatio,
          min: 0.06,
          max: 0.45,
          onChanged: (v) => setA(a.copyWith(shadowHeightRatio: v)),
        ),
        _DoubleTuningRow(
          label: '浮遊ドロップシャドウ濃さ (shadowAlpha)',
          value: a.shadowAlpha,
          defaultValue: d.shadowAlpha,
          min: 0.0,
          max: 0.9,
          onChanged: (v) => setA(a.copyWith(shadowAlpha: v)),
        ),
        _DoubleTuningRow(
          label: '非透過タイル浮遊弧の太さ比 (arcStrokeRatio)',
          value: a.arcStrokeRatio,
          defaultValue: d.arcStrokeRatio,
          min: 0.02,
          max: 0.18,
          onChanged: (v) => setA(a.copyWith(arcStrokeRatio: v)),
        ),
        _ColorTuningRow(
          label: '非透過タイル浮遊弧の色 (arcColor)',
          value: a.arcColor,
          defaultValue: d.arcColor,
          onChanged: (v) => setA(a.copyWith(arcColor: v)),
        ),
        const Divider(),
        _DoubleTuningRow(
          label: '頭上バッジ文字サイズ比 (badgeFontSizeRatio)',
          value: a.badgeFontSizeRatio,
          defaultValue: d.badgeFontSizeRatio,
          min: 0.20,
          max: 0.65,
          onChanged: (v) => setA(a.copyWith(badgeFontSizeRatio: v)),
        ),
        _DoubleTuningRow(
          label: '頭上バッジ上下揺れ幅 (badgeBobAmplitude)',
          value: a.badgeBobAmplitude,
          defaultValue: d.badgeBobAmplitude,
          min: 0.0,
          max: 0.18,
          onChanged: (v) => setA(a.copyWith(badgeBobAmplitude: v)),
        ),
        _DoubleTuningRow(
          label: '状態外枠の線幅比 (frameStrokeRatio)',
          value: a.frameStrokeRatio,
          defaultValue: d.frameStrokeRatio,
          min: 0.02,
          max: 0.16,
          onChanged: (v) => setA(a.copyWith(frameStrokeRatio: v)),
        ),
        _DoubleTuningRow(
          label: '状態外枠の不透明度 (frameAlpha)',
          value: a.frameAlpha,
          defaultValue: d.frameAlpha,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => setA(a.copyWith(frameAlpha: v)),
        ),
        _DoubleTuningRow(
          label: '1ターンあたり位相進行量 (phaseStepPerTurn)',
          value: a.phaseStepPerTurn,
          defaultValue: d.phaseStepPerTurn,
          min: 0.0,
          max: 1.5,
          onChanged: (v) => setA(a.copyWith(phaseStepPerTurn: v)),
        ),
      ],
    );
  }

  Widget _buildShakeAndLimitsTab() {
    final s = _editingConfig.screenShake;
    final l = _editingConfig.limits;
    const ds = ScreenShakeTuning();
    const dl = VfxLimitsTuning();
    void setS(ScreenShakeTuning next) => _updateConfig(_editingConfig.copyWith(screenShake: next));
    void setL(VfxLimitsTuning next) => _updateConfig(_editingConfig.copyWith(limits: next));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('画面シェイク設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '※ 大被ダメージシェイクの発動条件（最大HPの20%以上）は winflutter.c 側の固定閾値です。振幅を 0 にすると個別無効化できます。',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ),
        _IntTuningRow(
          label: 'シェイク持続時間 (durationMs)',
          value: s.durationMs,
          defaultValue: ds.durationMs,
          min: 30,
          max: 400,
          onChanged: (v) => setS(s.copyWith(durationMs: v)),
        ),
        _DoubleTuningRow(
          label: '爆発シェイク振幅 [px] (explosionAmplitudePx)',
          value: s.explosionAmplitudePx,
          defaultValue: ds.explosionAmplitudePx,
          min: 0.0,
          max: 12.0,
          onChanged: (v) => setS(s.copyWith(explosionAmplitudePx: v)),
        ),
        _DoubleTuningRow(
          label: '大被ダメシェイク振幅 [px] (bigHitAmplitudePx)',
          value: s.bigHitAmplitudePx,
          defaultValue: ds.bigHitAmplitudePx,
          min: 0.0,
          max: 12.0,
          onChanged: (v) => setS(s.copyWith(bigHitAmplitudePx: v)),
        ),
        _DoubleTuningRow(
          label: '扉蹴破りシェイク振幅 [px] (doorBreakAmplitudePx)',
          value: s.doorBreakAmplitudePx,
          defaultValue: ds.doorBreakAmplitudePx,
          min: 0.0,
          max: 12.0,
          onChanged: (v) => setS(s.copyWith(doorBreakAmplitudePx: v)),
        ),
        const Divider(),
        const Text('同時描画上限キャップ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        _IntTuningRow(
          label: '最大パーティクル粒数 (maxParticles)',
          value: l.maxParticles,
          defaultValue: dl.maxParticles,
          min: 10,
          max: 300,
          onChanged: (v) => setL(l.copyWith(maxParticles: v)),
        ),
        _IntTuningRow(
          label: '最大光リング数 (maxRings)',
          value: l.maxRings,
          defaultValue: dl.maxRings,
          min: 1,
          max: 30,
          onChanged: (v) => setL(l.copyWith(maxRings: v)),
        ),
        _IntTuningRow(
          label: '最大フローティングテキスト総数 (maxFloatingTexts)',
          value: l.maxFloatingTexts,
          defaultValue: dl.maxFloatingTexts,
          min: 3,
          max: 60,
          onChanged: (v) => setL(l.copyWith(maxFloatingTexts: v)),
        ),
        _IntTuningRow(
          label: '同セル・同ターン最大表示件数',
          value: l.maxFloatingTextsPerCellTurn,
          defaultValue: dl.maxFloatingTextsPerCellTurn,
          min: 1,
          max: 8,
          onChanged: (v) => setL(l.copyWith(maxFloatingTextsPerCellTurn: v)),
        ),
      ],
    );
  }
}

/// 整数パラメータ用のスライダー＋数値直打ち＋変更ドット＋個別リセット行
class _IntTuningRow extends StatefulWidget {
  final String label;
  final int value;
  final int defaultValue;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _IntTuningRow({
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_IntTuningRow> createState() => _IntTuningRowState();
}

class _IntTuningRowState extends State<_IntTuningRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _IntTuningRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final t = widget.value.toString();
      if (_ctrl.text != t) _ctrl.text = t;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commitText(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null) {
      widget.onChanged(parsed.clamp(widget.min, widget.max));
    } else {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final modified = widget.value != widget.defaultValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (modified)
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(Icons.circle, size: 8, color: Color(0xFFFFB300)),
                ),
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12))),
              SizedBox(
                width: 68,
                height: 28,
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _commitText,
                ),
              ),
              IconButton(
                tooltip: '標準値 (${widget.defaultValue}) に戻す',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                onPressed: modified ? () => widget.onChanged(widget.defaultValue) : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          Slider(
            value: widget.value.clamp(widget.min, widget.max).toDouble(),
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            divisions: (widget.max - widget.min).clamp(1, 500),
            label: widget.value.toString(),
            onChanged: (v) => widget.onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

/// 浮動小数パラメータ用のスライダー＋数値直打ち＋変更ドット＋個別リセット行
class _DoubleTuningRow extends StatefulWidget {
  final String label;
  final double value;
  final double defaultValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _DoubleTuningRow({
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_DoubleTuningRow> createState() => _DoubleTuningRowState();
}

class _DoubleTuningRowState extends State<_DoubleTuningRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _DoubleTuningRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.0001) {
      final t = widget.value.toStringAsFixed(2);
      if (_ctrl.text != t) _ctrl.text = t;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commitText(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed != null) {
      final rounded = ((parsed.clamp(widget.min, widget.max)) * 1000).round() / 1000.0;
      widget.onChanged(rounded);
    } else {
      _ctrl.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modified = (widget.value - widget.defaultValue).abs() > 0.0005;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (modified)
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(Icons.circle, size: 8, color: Color(0xFFFFB300)),
                ),
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12))),
              SizedBox(
                width: 68,
                height: 28,
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _commitText,
                ),
              ),
              IconButton(
                tooltip: '標準値 (${widget.defaultValue.toStringAsFixed(2)}) に戻す',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                onPressed: modified ? () => widget.onChanged(widget.defaultValue) : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          Slider(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            label: widget.value.toStringAsFixed(2),
            onChanged: (v) => widget.onChanged((v * 100).round() / 100.0),
          ),
        ],
      ),
    );
  }
}

/// ARGB カラー用のスウォッチ選択＋Hex直入力＋変更ドット＋個別リセット行
class _ColorTuningRow extends StatefulWidget {
  final String label;
  final int value;
  final int defaultValue;
  final ValueChanged<int> onChanged;

  const _ColorTuningRow({
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.onChanged,
  });

  @override
  State<_ColorTuningRow> createState() => _ColorTuningRowState();
}

class _ColorTuningRowState extends State<_ColorTuningRow> {
  static const List<int> _palette = [
    0xFFFF5252,
    0xFFFF1744,
    0xFFFF7043,
    0xFFFFAB91,
    0xFFFFD740,
    0xFFFFEE58,
    0xFFFFF59D,
    0xFF76FF03,
    0xFF69F0AE,
    0xFF40C4FF,
    0xFF80D8FF,
    0xFF81D4FA,
    0xFFE040FB,
    0xFFCE93D8,
    0xFFD7CCC8,
    0xFFA1887F,
    0xFFB0BEC5,
    0xFFFFFFFF,
  ];

  late final TextEditingController _ctrl;

  String _formatHex(int v) =>
      '#${(v & 0xFFFFFFFF).toRadixString(16).toUpperCase().padLeft(8, '0')}';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _formatHex(widget.value));
  }

  @override
  void didUpdateWidget(covariant _ColorTuningRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final t = _formatHex(widget.value);
      if (_ctrl.text != t) _ctrl.text = t;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commitHex(String raw) {
    var clean = raw.trim().replaceFirst('#', '').replaceFirst('0x', '').replaceFirst('0X', '');
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed != null) {
      widget.onChanged(parsed);
    } else {
      _ctrl.text = _formatHex(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modified = (widget.value & 0xFFFFFFFF) != (widget.defaultValue & 0xFFFFFFFF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (modified)
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(Icons.circle, size: 8, color: Color(0xFFFFB300)),
            ),
          Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12))),
          PopupMenuButton<int>(
            tooltip: 'パレットから選択',
            onSelected: widget.onChanged,
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: SizedBox(
                  width: 220,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in _palette)
                        InkWell(
                          onTap: () => Navigator.pop(ctx, c),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Color(c),
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Color(widget.value | 0xFF000000),
                border: Border.all(color: Colors.white70),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(
            width: 96,
            height: 28,
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _commitHex,
            ),
          ),
          IconButton(
            tooltip: '標準色に戻す',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: modified ? () => widget.onChanged(widget.defaultValue) : null,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
    );
  }
}
