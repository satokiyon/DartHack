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

  @override
  String get detailedSettings => '詳細ゲーム設定';

  @override
  String get secUILayoutTitle => 'UI配置カスタマイズ';

  @override
  String get secUILayoutSub => '画面レイアウトのパターンを選択します';

  @override
  String get layoutPatternLabel => 'レイアウトパターン';

  @override
  String get layoutPatternDesc1 => 'ステータス・メッセージ: 上部 / 移動パッド・ショートカット: 下部';

  @override
  String get layoutPatternDesc2 => 'ステータス・メッセージ: 下部 / 移動パッド・ショートカット: 上部';

  @override
  String get swapPadSideTitle => '移動パッドとショートカットの左右を入れ替える';

  @override
  String get swapPadSideDesc => '移動パッドを右側、ショートカットボタンを左側に配置します';

  @override
  String get menuButtonPos => '半透明メニューボタンの配置位置';

  @override
  String get mapButtonPos => '半透明地図ボタンの配置位置';

  @override
  String get posTopLeft => '左上';

  @override
  String get posTopRight => '右上';

  @override
  String get posLeftEdge => '左端(中央)';

  @override
  String get posRightEdge => '右端(中央)';

  @override
  String get posBottomLeft => '左下';

  @override
  String get posBottomRight => '右下';

  @override
  String get posTop => '上部';

  @override
  String get posBottom => '下部';

  @override
  String get posLeft => '左側 (スワイプ可)';

  @override
  String get posRight => '右側 (スワイプ可)';

  @override
  String get padOpacityTitle => 'ボタン不透明度';

  @override
  String get dpadScaleTitle => '移動ボタンサイズ倍率';

  @override
  String get dpadScaleLabel => '移動';

  @override
  String get dpadLongPressTitle => '移動パッド長押し時の移動モード';

  @override
  String get dpadModeNormal => '標準';

  @override
  String get dpadModeUpper => '大文字';

  @override
  String get dpadModeGLower => 'g';

  @override
  String get dpadModeGUpper => 'G';

  @override
  String get dpadModeCtrl => '^(Ctrl)';

  @override
  String get dpadModeMCmd => 'm';

  @override
  String get dpadModeFCmd => 'F';

  @override
  String get mapTapTravelTitle => 'マップタップでの自動移動';

  @override
  String get mapTapAlways => '常に有効';

  @override
  String get mapTapAfterScroll => 'スクロール・ズーム直後のみ有効';

  @override
  String get shortcutPadScaleTitle => 'ショートカットボタンサイズ倍率';

  @override
  String get shortcutPadScaleLabel => 'ショートカット';

  @override
  String get cmdPanelScaleTitle => 'コマンドパネルサイズ倍率';

  @override
  String get cmdPanelScaleLabel => 'コマンドパネル';

  @override
  String get drawerPosTitle => 'メニュー(ドロワー)の引き出し位置';

  @override
  String appliedScale(Object scale) {
    return '適用倍率: $scale';
  }

  @override
  String get autoAdjustedScreen => '⚠ 画面幅により自動調整';

  @override
  String get secMsgSub => 'メッセージ領域の行数・透過度・フォントサイズ';

  @override
  String msgLineCountLabel(Object count) {
    return '現在: $count 行（最新メッセージを$count行表示）';
  }

  @override
  String msgOpacityLabel(Object percent) {
    return '現在: $percent%（0% = 完全透明 / 100% = 不透明）';
  }

  @override
  String msgFontSizeLabel(Object size) {
    return '現在: $size pt';
  }

  @override
  String get preview => 'プレビュー';

  @override
  String get msgSampleText => 'メッセージのサンプルテキストです。\nWelcome to NetHackJP!';

  @override
  String get secKeySub => '音量ボタンや戻るキーにゲームコマンドを割り当てます';

  @override
  String get keyVolUpTitle => '音量アップキー';

  @override
  String get keyVolDownTitle => '音量ダウンキー';

  @override
  String get keyBackTitle => '戻るボタン';

  @override
  String get volActNone => '機能なし (通常音量変化)';

  @override
  String get volActEnter => '決定 (Enter)';

  @override
  String get volActSpace => 'スペース';

  @override
  String get volActEsc => 'エスケープ (Esc)';

  @override
  String get volActInv => 'インベントリ (i)';

  @override
  String get volActSearch => '周囲の探索 (s)';

  @override
  String get volActRedraw => '画面再描画 (^R)';

  @override
  String get backActNone => '機能なし (通常通りアプリを閉じる)';

  @override
  String get backActEsc => 'エスケープ (Esc/ダイアログ閉じ)';

  @override
  String get backActInv => 'インベントリ (i)';

  @override
  String get backActSearch => '周囲の探索 (s)';

  @override
  String get backActWait => '待機する (.)';

  @override
  String get backActSave => 'セーブして終了する (S)';

  @override
  String get secShortcutSub => '3x3ショートカットパッドに割り当てるキーを設定';

  @override
  String get shortcutNotSet => '(未設定)';

  @override
  String shortcutLabelFormat(Object index, Object position) {
    return '$position ボタン ($index)';
  }

  @override
  String get shortcutBtnTL => '左上';

  @override
  String get shortcutBtnTC => '上中央';

  @override
  String get shortcutBtnTR => '右上';

  @override
  String get shortcutBtnML => '中段左';

  @override
  String get shortcutBtnMC => '中段中央';

  @override
  String get shortcutBtnMR => '中段右';

  @override
  String get shortcutBtnBL => '下段左';

  @override
  String get shortcutBtnBC => '下段中央';

  @override
  String get shortcutBtnBR => '下段右';

  @override
  String get secCmdPanelSub => 'ゲーム下部スワイプ対応のボタン群を管理';

  @override
  String get showPanelNamesTitle => 'パネル名を表示';

  @override
  String get showPanelNamesSub => '各パネル行の左端に名前バッジを表示';

  @override
  String get noButtons => '(ボタンなし)';

  @override
  String get addNewPanel => '新しいコマンドパネルを追加';

  @override
  String editPanelTitle(Object index) {
    return 'パネル $index を編集';
  }

  @override
  String get panelNameLabel => 'パネル名';

  @override
  String get cmdListLabel => 'ボタンコマンド一覧';

  @override
  String get cmdListHelper => 'スペース区切りでコマンドを入力してください';

  @override
  String get defaultPanelName => '標準パネル';

  @override
  String panelNName(Object index) {
    return 'パネル $index';
  }

  @override
  String get secGameRulesTitle => 'ゲームルール・プレイ設定 (defaults.nh)';

  @override
  String get secGameRulesSub => 'ゲーム本体の動作オプションを設定します（※反映には新規ゲームの開始が必要です）';

  @override
  String get tutorialModeTitle => 'チュートリアル動作モード';

  @override
  String get tutorialModeSub => 'ゲーム開始時のチュートリアル問いかけ・開始動作を設定します';

  @override
  String get tutorialAsk => '毎回確認する\n (標準)';

  @override
  String get tutorialAlways => '常に開始する\n (OPTIONS=tutorial)';

  @override
  String get tutorialNever => '常に通常プレイ\n (OPTIONS=!tutorial)';

  @override
  String get numberPadTitle => 'テンキー移動 (number_pad)';

  @override
  String get numberPadSub => 'テンキー（1-9）での移動やレイアウトを設定します';

  @override
  String get numPadOff => 'OFF (!number_pad)';

  @override
  String get numPadStandard => '1: 標準テンキー';

  @override
  String get numPadPCHack => '2: PC Hack互換';

  @override
  String get numPadPhone => '3: 電話配列';

  @override
  String get numPadPhonePCHack => '4: 電話+PC Hack';

  @override
  String get numPadGerman => '-1: ドイツ語配列';

  @override
  String get autopickupSub => '足元のアイテムを自動的に拾います';

  @override
  String get pickupTypesTitle => '自動拾い対象のアイテム種別 (pickup_types)';

  @override
  String get pickupTypesAll => 'すべて拾う';

  @override
  String pickupTypesSymbols(Object symbols) {
    return '対象記号: $symbols';
  }

  @override
  String get pickupTypesDisabledNote => '※自動拾いが有効な場合のみ設定できます';

  @override
  String get timeSub => 'ステータス表示に行動ターン数を表示します';

  @override
  String get showexpSub => 'ステータス表示に獲得経験値を表示します';

  @override
  String get priceQuotesSub => '未識別オブジェクトに記憶済み価格情報を表示します';

  @override
  String get hiliteStatusSub => 'HPや各種状態変化を色付きでハイライト表示します';

  @override
  String get menucolorSub => 'インベントリやダイアログの各項目を色付き表示します';

  @override
  String get nameSub => '主人公のデフォルト名 (name)';

  @override
  String get dognameSub => '犬の名前 (dogname)';

  @override
  String get catnameSub => '猫の名前 (catname)';

  @override
  String get horsenameSub => '馬の名前 (horsename)';

  @override
  String get fruitSub => '果物の名前 (fruit)';

  @override
  String get defaultUnspecified => 'デフォルト (未指定)';

  @override
  String get defaultSlimeMold => 'デフォルト (slime mold)';

  @override
  String get pickupTypesDialogTitle => '自動拾い対象アイテム';

  @override
  String get directInputLabel => '直接入力 (記号の羅列)';

  @override
  String get directInputHint => '例: \$\"=/!?+';

  @override
  String get directInputHelper => '拾いたいアイテムの記号を入力してください';

  @override
  String get toggleFromOptions => 'または選択肢からトグル選択:';

  @override
  String get save => '保存';

  @override
  String nameTooLongMaxBytes(Object maxBytes) {
    return '名前が長すぎます。$maxBytesバイト以内で入力してください。';
  }

  @override
  String textTooLongMaxBytes(Object maxBytes) {
    return '文字数が多すぎます。$maxBytesバイト以内で入力してください。';
  }

  @override
  String get hintEmptyDefault => '未指定の場合は空欄';

  @override
  String get itemGold => '金貨 (\$)';

  @override
  String get itemAmulet => '首飾り/アミュレット (\")';

  @override
  String get itemArmor => '防具 ([)';

  @override
  String get itemFood => '食料 (%)';

  @override
  String get itemScroll => '巻物 (?)';

  @override
  String get itemSpellbook => '呪文の書 (+)';

  @override
  String get itemWand => '杖 (/)';

  @override
  String get itemRing => '指輪 (=)';

  @override
  String get itemPotion => '薬 (!)';

  @override
  String get itemTool => '道具 (()';

  @override
  String get itemGem => '宝石 (*)';

  @override
  String get itemBall => '弾薬/コンポーネント (0)';

  @override
  String get itemWeapon => '武器 ()';

  @override
  String get itemOther => 'その他 (_)';

  @override
  String get secAdvancedTitle => '高度な設定';

  @override
  String get secOtherTitle => 'その他の設定';

  @override
  String get tombstoneModeTitle => '死亡時の墓表示モード';

  @override
  String get tombstoneModeImage => '画像表示';

  @override
  String get tombstoneModeText => 'テキスト表示';

  @override
  String get manualEditDefaults => 'defaults.nh を手動で編集';

  @override
  String get manualEditDefaultsSub =>
      '詳細なゲームオプションファイルを直接記述します（※反映には新規ゲームの開始が必要です）';

  @override
  String get exportSettings => '設定をエクスポート';

  @override
  String get exportSettingsSub => '現在の設定をJSON文字列でクリップボードにコピー';

  @override
  String get importSettings => '設定をインポート';

  @override
  String get importSettingsSub => 'クリップボードの設定JSONを読み込んで適用します';

  @override
  String get copiedJsonSuccess => '設定JSONをクリップボードにコピーしました。';

  @override
  String get noTextInClipboard => 'クリップボードにテキストがありません。';

  @override
  String get importedSuccess => '設定をインポートしました。';

  @override
  String get importErrorTitle => 'インポートエラー';

  @override
  String importErrorMsg(Object error) {
    return 'インポートに失敗しました。無効なJSONフォーマットです。\n$error';
  }

  @override
  String get secCreditsTitle => 'クレジット';

  @override
  String get creditsBody1 =>
      'DartHack は、NetHack をベースとしつつ、Flutter/Dart によって再構築したモバイル版です。本アプリはオリジナルの NetHack をゲームコアとして使用していますが、NetHack 開発チーム（The NetHack DevTeam）とは一切関係ありません。';

  @override
  String get creditsBody2 =>
      '本アプリは NetHack General Public License (NGPL) に基づき配布されています。  ソースコードは以下にて公開しています：https://github.com/satokiyon/DartHack';

  @override
  String get creditsBody3 => 'UI デザインの一部は、gurrhack の ForkFront を参考にしています。';

  @override
  String get creditsContributors => 'Contributors:';

  @override
  String get creditsContributorList =>
      '• @satokiyon\n• with Google Antigravity and Gemini';

  @override
  String get editDefaultsTitle => 'defaults.nh を編集';

  @override
  String get saveTooltip => '保存';

  @override
  String get defaultsSaved => 'defaults.nh を保存しました。';

  @override
  String get saveErrorTitle => '保存エラー';

  @override
  String saveErrorMsg(Object error) {
    return 'ファイルを保存できませんでした。\n$error';
  }

  @override
  String get discardChangesTitle => '変更の破棄';

  @override
  String get discardChangesMsg => '編集内容が保存されていません。破棄して戻りますか？';

  @override
  String get discard => '破棄';

  @override
  String get defaultsNotFound => 'defaults.nh が見つかりませんでした。';

  @override
  String fileReadError(Object error) {
    return 'ファイルの読み込みエラー: $error';
  }

  @override
  String get defaultsEditNotice => '※ defaults.nh の編集内容を反映するには新規ゲームの開始が必要です';

  @override
  String get enterOptionHint => 'オプションを入力してください...';

  @override
  String selectedCountLabel(Object maxCount, Object selectedCount) {
    return ' ($selectedCount個選択中 / $maxCount)';
  }
}
