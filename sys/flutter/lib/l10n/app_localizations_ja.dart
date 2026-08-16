// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'DartHack';

  @override
  String get selectLanguage => '言語選択';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get startGame => 'ゲーム開始';

  @override
  String get settings => '設定';

  @override
  String get guidebookTooltip => 'ガイドブック';

  @override
  String get settingsTooltip => 'ゲーム設定';

  @override
  String get preparingAssets => 'アセットを準備中...';

  @override
  String get startAdventure => '冒険を始める';

  @override
  String get drawerTitle => 'DartHack メニュー';

  @override
  String get menuExtCmds => '拡張コマンド一覧';

  @override
  String get menuGuidebook => 'ガイドブック';

  @override
  String get menuSettings => 'ゲーム設定';

  @override
  String get menuFullMap => '全画面マップ表示';

  @override
  String get menuMsgHistory => 'メッセージ履歴';

  @override
  String get menuSaveQuit => 'セーブして終了';

  @override
  String get menuQuitWithoutSave => 'セーブせず終了 (放棄)';

  @override
  String get confirmQuitTitle => 'セーブせず終了';

  @override
  String get confirmQuitMsg => '現在の進行状況は保存されません。本当に終了しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '決定';

  @override
  String get confirmTitle => '確認';

  @override
  String get history => '履歴';

  @override
  String get quit => '終了';

  @override
  String get scoreboard => 'スコアボード';

  @override
  String get readGuidebook => 'ガイドブックを読む';

  @override
  String get showHelp => 'ヘルプを表示 (?)';

  @override
  String get dbSearch => 'データベース検索 ( /? )';

  @override
  String get gameOptions => 'オプション設定 ( O )';

  @override
  String get showFullMap => '階層の全体地図を表示';

  @override
  String get hideKeyboard => '仮想キーボードを非表示';

  @override
  String get showKeyboard => '仮想キーボードを表示';

  @override
  String get openSettings => 'ゲーム設定を開く';

  @override
  String get secStatusTitle => 'ステータス表示設定';

  @override
  String get secStatusSub => 'ゲーム画面のステータス領域の表示を切替えます';

  @override
  String get displayLanguage => '表示言語 / Language';

  @override
  String get displayLanguageSub => 'アプリ・ゲームコアの表示言語を切替えます';

  @override
  String get coreLangNote => '※ゲームコアの言語切替は次回ゲーム開始時に反映されます';

  @override
  String get screenMode => '画面モード選択';

  @override
  String get screenModeNormal => '通常';

  @override
  String get screenModeImmersive => 'イマーシブ';

  @override
  String get statusDisplayMode => 'ステータス領域表示モード';

  @override
  String get statusModeAuto => '自動縮小フィット';

  @override
  String get statusModeVariable => '領域の可変高さ';

  @override
  String get secTilesetTitle => 'タイルセット設定';

  @override
  String get useTiles => 'タイル表示を使用';

  @override
  String get useTilesSub => '無効時はアスキー（文字）マップになります';

  @override
  String get tilesetSelect => 'タイルセット選択';

  @override
  String get secControllerTitle => '操作コントローラ設定';

  @override
  String get controllerMode => '操作モード';

  @override
  String get modePad => '仮想パッド (D-Pad)';

  @override
  String get modeKeyboard => 'フルキーボード';

  @override
  String get layoutPattern => 'レイアウトパターン';

  @override
  String get layoutPattern1 => 'パターン1 (左右分割)';

  @override
  String get layoutPattern2 => 'パターン2 (中央統合)';

  @override
  String get swapPadSide => 'パッドの左右反転';

  @override
  String get swapPadSideSub => 'D-Padとショートカットパッドの配置を入れ替えます';

  @override
  String get dpadScale => 'D-Padの表示サイズ';

  @override
  String get shortcutPadScale => 'ショートカットパッドの表示サイズ';

  @override
  String get cmdPanelScale => 'コマンドパネルの表示サイズ';

  @override
  String get padOpacity => 'コントローラの透過度';

  @override
  String get dpadLongPressMode => 'D-Pad長押し動作';

  @override
  String get mapTapTravelMode => 'マップタップ移動';

  @override
  String get tapModeAlways => '常時有効 (1タップ移動)';

  @override
  String get tapModeDouble => 'ダブルタップのみ';

  @override
  String get tapModeOff => '無効';

  @override
  String get secMsgTitle => 'メッセージ領域設定';

  @override
  String get msgLineCount => '表示行数';

  @override
  String get msgOpacity => '背景透過度';

  @override
  String get msgFontSize => 'フォントサイズ';

  @override
  String get secKeyTitle => '物理キー割り当て';

  @override
  String get keyVolUp => '音量(+)キー';

  @override
  String get keyVolDown => '音量(-)キー';

  @override
  String get keyBack => '戻るキー/ジェスチャー';

  @override
  String get keyActionNone => 'なし';

  @override
  String get keyActionEsc => 'キャンセル (ESC)';

  @override
  String get keyActionSpace => '決定/次へ (Space)';

  @override
  String get keyActionMenu => 'メニュー表示';

  @override
  String get secShortcutTitle => 'ショートカット編集';

  @override
  String get secCmdPanelTitle => 'カスタムコマンドパネル編集';

  @override
  String get secDefaultsTitle => 'defaults.nh 直接編集';

  @override
  String get secDefaultsSub => 'NetHackの構成設定ファイルをテキストエディタで編集します';

  @override
  String get secGameOptTitle => 'ゲームオプション (defaults.nh)';

  @override
  String get optTutorial => 'チュートリアルモード';

  @override
  String get optAutopickup => '自動拾い (autopickup)';

  @override
  String get optPickupTypes => '自動拾い対象タイプ';

  @override
  String get optTime => '経過ターン表示 (time)';

  @override
  String get optShowexp => '経験値表示 (showexp)';

  @override
  String get optPriceQuotes => '鑑定価格表示 (price_quotes)';

  @override
  String get optHiliteStatus => 'ステータス強調 (hilite_status)';

  @override
  String get optMenucolor => 'メニューカラー (menucolor)';

  @override
  String get optName => 'プレイヤー名 (name)';

  @override
  String get optDogname => '犬の名前 (dogname)';

  @override
  String get optCatname => '猫の名前 (catname)';

  @override
  String get optHorsename => '馬の名前 (horsename)';

  @override
  String get optFruit => '果物の名前 (fruit)';

  @override
  String get resetDefaults => '設定を初期状態にリセット';

  @override
  String get resetDefaultsConfirm => 'すべての設定を初期値に戻しますか？';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get close => '閉じる';

  @override
  String get search => '検索';

  @override
  String get clear => 'クリア';

  @override
  String get enterNamePrompt => 'プレイヤー名を入力してください';

  @override
  String get enterTextPrompt => 'テキストを入力してください';

  @override
  String get selectQuantity => '個数を指定';

  @override
  String get all => 'すべて';

  @override
  String get count => '個';

  @override
  String get guidebookTitle => 'NetHack ガイドブック';

  @override
  String get fullMapTitle => 'ダンジョン全体マップ';

  @override
  String get msgHistoryTitle => 'メッセージ履歴';

  @override
  String get tombstoneRIP => '冥福を祈る';

  @override
  String get keyboardTitle => 'NetHack キーボード';

  @override
  String get dpadNormal => '通常移動';

  @override
  String get dpadUpper => '走る (Shift)';

  @override
  String get dpadGLower => '指定移動 (g)';

  @override
  String get dpadGUpper => '走って指定移動 (G)';

  @override
  String get dpadCtrl => '制御入力 (Ctrl)';

  @override
  String get dpadMCmd => 'メタキー (Meta/Alt)';

  @override
  String get dpadFCmd => 'ファイト/攻撃 (F)';

  @override
  String get whoAreYou => 'お名前は？';

  @override
  String get savedGames => '既存のセーブデータ:';

  @override
  String get playMode => 'プレイモード:';

  @override
  String get playModeNormal => '通常';

  @override
  String get playModeExplore => '探索';

  @override
  String get playModeWizard => 'ウィザード';

  @override
  String get modeDescNormal => '🏆 通常のスコアアタック・標準プレイ用。死亡するとゲームオーバーになります。';

  @override
  String get modeDescExplore => '🔍 死亡時に復活を選択できる練習用モード。スコアはハイスコア一覧に記録されません。';

  @override
  String get modeDescWizard =>
      '🧙 デバッグ・検証用モード。任意のアイテム生成や無敵化コマンドなどのデバッグ機能が使用できます（名前は wizard に固定）。';

  @override
  String bytesCount(Object count, Object max) {
    return '$count / $max バイト';
  }

  @override
  String nameTooLong(Object max) {
    return '名前が長すぎます。$max バイト以内で入力してください。';
  }

  @override
  String get enterText => 'テキストを入力してください';

  @override
  String get selectExtCmd => '拡張コマンドの選択:';

  @override
  String get filterCmds => 'コマンドを絞り込み...';

  @override
  String get selectAll => '全て選択';

  @override
  String get deselectAll => '解除';

  @override
  String get howMany => '個数を選択してください';

  @override
  String get runHighlights => '【今回のハイライト】';

  @override
  String get recallingMemories => 'ダンジョンの記憶を辿っています...';

  @override
  String get none => 'なし';

  @override
  String entriesCount(Object count) {
    return '$count件';
  }

  @override
  String get noMsgHistory => 'メッセージ履歴はありません';

  @override
  String get fullLevelMap => '階層の全体地図';

  @override
  String get pinchToZoom => 'ピンチ操作でズームイン/ズームアウトが可能です';

  @override
  String editShortcutTitle(Object name) {
    return '$name を編集';
  }

  @override
  String get shortcutHint => '例: i, d, #terrain, #herecmdmenu 等';

  @override
  String get shortcutHelper => '#で始まるものは拡張コマンドとして入力送信されます';

  @override
  String get searchCmdOrDesc => 'コマンド名や説明で検索...';

  @override
  String get noCmdFound => '見つかりませんでした';
}
