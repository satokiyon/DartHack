import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'DartHack'**
  String get appTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In ja, this message translates to:
  /// **'言語選択'**
  String get selectLanguage;

  /// No description provided for @japanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @english.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @startGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム開始'**
  String get startGame;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @guidebookTooltip.
  ///
  /// In ja, this message translates to:
  /// **'ガイドブック'**
  String get guidebookTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム設定'**
  String get settingsTooltip;

  /// No description provided for @preparingAssets.
  ///
  /// In ja, this message translates to:
  /// **'アセットを準備中...'**
  String get preparingAssets;

  /// No description provided for @startAdventure.
  ///
  /// In ja, this message translates to:
  /// **'冒険を始める'**
  String get startAdventure;

  /// No description provided for @drawerTitle.
  ///
  /// In ja, this message translates to:
  /// **'DartHack メニュー'**
  String get drawerTitle;

  /// No description provided for @menuExtCmds.
  ///
  /// In ja, this message translates to:
  /// **'拡張コマンド一覧'**
  String get menuExtCmds;

  /// No description provided for @menuGuidebook.
  ///
  /// In ja, this message translates to:
  /// **'ガイドブック'**
  String get menuGuidebook;

  /// No description provided for @menuSettings.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム設定'**
  String get menuSettings;

  /// No description provided for @menuFullMap.
  ///
  /// In ja, this message translates to:
  /// **'全画面マップ表示'**
  String get menuFullMap;

  /// No description provided for @menuMsgHistory.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ履歴'**
  String get menuMsgHistory;

  /// No description provided for @menuSaveQuit.
  ///
  /// In ja, this message translates to:
  /// **'セーブして終了'**
  String get menuSaveQuit;

  /// No description provided for @menuQuitWithoutSave.
  ///
  /// In ja, this message translates to:
  /// **'セーブせず終了 (放棄)'**
  String get menuQuitWithoutSave;

  /// No description provided for @confirmQuitTitle.
  ///
  /// In ja, this message translates to:
  /// **'セーブせず終了'**
  String get confirmQuitTitle;

  /// No description provided for @confirmQuitMsg.
  ///
  /// In ja, this message translates to:
  /// **'現在の進行状況は保存されません。本当に終了しますか？'**
  String get confirmQuitMsg;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get confirm;

  /// No description provided for @confirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirmTitle;

  /// No description provided for @history.
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get history;

  /// No description provided for @quit.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get quit;

  /// No description provided for @scoreboard.
  ///
  /// In ja, this message translates to:
  /// **'スコアボード'**
  String get scoreboard;

  /// No description provided for @readGuidebook.
  ///
  /// In ja, this message translates to:
  /// **'ガイドブックを読む'**
  String get readGuidebook;

  /// No description provided for @showHelp.
  ///
  /// In ja, this message translates to:
  /// **'ヘルプを表示 (?)'**
  String get showHelp;

  /// No description provided for @dbSearch.
  ///
  /// In ja, this message translates to:
  /// **'データベース検索 ( /? )'**
  String get dbSearch;

  /// No description provided for @gameOptions.
  ///
  /// In ja, this message translates to:
  /// **'オプション設定 ( O )'**
  String get gameOptions;

  /// No description provided for @showFullMap.
  ///
  /// In ja, this message translates to:
  /// **'階層の全体地図を表示'**
  String get showFullMap;

  /// No description provided for @hideKeyboard.
  ///
  /// In ja, this message translates to:
  /// **'仮想キーボードを非表示'**
  String get hideKeyboard;

  /// No description provided for @showKeyboard.
  ///
  /// In ja, this message translates to:
  /// **'仮想キーボードを表示'**
  String get showKeyboard;

  /// No description provided for @openSettings.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム設定を開く'**
  String get openSettings;

  /// No description provided for @secStatusTitle.
  ///
  /// In ja, this message translates to:
  /// **'ステータス表示設定'**
  String get secStatusTitle;

  /// No description provided for @secStatusSub.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム画面のステータス領域の表示を切替えます'**
  String get secStatusSub;

  /// No description provided for @displayLanguage.
  ///
  /// In ja, this message translates to:
  /// **'表示言語 / Language'**
  String get displayLanguage;

  /// No description provided for @displayLanguageSub.
  ///
  /// In ja, this message translates to:
  /// **'アプリ・ゲームコアの表示言語を切替えます'**
  String get displayLanguageSub;

  /// No description provided for @coreLangNote.
  ///
  /// In ja, this message translates to:
  /// **'※ゲームコアの言語切替は次回ゲーム開始時に反映されます'**
  String get coreLangNote;

  /// No description provided for @screenMode.
  ///
  /// In ja, this message translates to:
  /// **'画面モード選択'**
  String get screenMode;

  /// No description provided for @screenModeNormal.
  ///
  /// In ja, this message translates to:
  /// **'通常'**
  String get screenModeNormal;

  /// No description provided for @screenModeImmersive.
  ///
  /// In ja, this message translates to:
  /// **'イマーシブ'**
  String get screenModeImmersive;

  /// No description provided for @statusDisplayMode.
  ///
  /// In ja, this message translates to:
  /// **'ステータス領域表示モード'**
  String get statusDisplayMode;

  /// No description provided for @statusModeAuto.
  ///
  /// In ja, this message translates to:
  /// **'自動縮小フィット'**
  String get statusModeAuto;

  /// No description provided for @statusModeVariable.
  ///
  /// In ja, this message translates to:
  /// **'領域の可変高さ'**
  String get statusModeVariable;

  /// No description provided for @secTilesetTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイルセット設定'**
  String get secTilesetTitle;

  /// No description provided for @useTiles.
  ///
  /// In ja, this message translates to:
  /// **'タイル表示を使用'**
  String get useTiles;

  /// No description provided for @useTilesSub.
  ///
  /// In ja, this message translates to:
  /// **'無効時はアスキー（文字）マップになります'**
  String get useTilesSub;

  /// No description provided for @tilesetSelect.
  ///
  /// In ja, this message translates to:
  /// **'タイルセット選択'**
  String get tilesetSelect;

  /// No description provided for @secControllerTitle.
  ///
  /// In ja, this message translates to:
  /// **'操作コントローラ設定'**
  String get secControllerTitle;

  /// No description provided for @controllerMode.
  ///
  /// In ja, this message translates to:
  /// **'操作モード'**
  String get controllerMode;

  /// No description provided for @modePad.
  ///
  /// In ja, this message translates to:
  /// **'仮想パッド (D-Pad)'**
  String get modePad;

  /// No description provided for @modeKeyboard.
  ///
  /// In ja, this message translates to:
  /// **'フルキーボード'**
  String get modeKeyboard;

  /// No description provided for @layoutPattern.
  ///
  /// In ja, this message translates to:
  /// **'レイアウトパターン'**
  String get layoutPattern;

  /// No description provided for @layoutPattern1.
  ///
  /// In ja, this message translates to:
  /// **'パターン1 (左右分割)'**
  String get layoutPattern1;

  /// No description provided for @layoutPattern2.
  ///
  /// In ja, this message translates to:
  /// **'パターン2 (中央統合)'**
  String get layoutPattern2;

  /// No description provided for @swapPadSide.
  ///
  /// In ja, this message translates to:
  /// **'パッドの左右反転'**
  String get swapPadSide;

  /// No description provided for @swapPadSideSub.
  ///
  /// In ja, this message translates to:
  /// **'D-Padとショートカットパッドの配置を入れ替えます'**
  String get swapPadSideSub;

  /// No description provided for @dpadScale.
  ///
  /// In ja, this message translates to:
  /// **'D-Padの表示サイズ'**
  String get dpadScale;

  /// No description provided for @shortcutPadScale.
  ///
  /// In ja, this message translates to:
  /// **'ショートカットパッドの表示サイズ'**
  String get shortcutPadScale;

  /// No description provided for @cmdPanelScale.
  ///
  /// In ja, this message translates to:
  /// **'コマンドパネルの表示サイズ'**
  String get cmdPanelScale;

  /// No description provided for @padOpacity.
  ///
  /// In ja, this message translates to:
  /// **'コントローラの透過度'**
  String get padOpacity;

  /// No description provided for @dpadLongPressMode.
  ///
  /// In ja, this message translates to:
  /// **'D-Pad長押し動作'**
  String get dpadLongPressMode;

  /// No description provided for @mapTapTravelMode.
  ///
  /// In ja, this message translates to:
  /// **'マップタップ移動'**
  String get mapTapTravelMode;

  /// No description provided for @tapModeAlways.
  ///
  /// In ja, this message translates to:
  /// **'常時有効 (1タップ移動)'**
  String get tapModeAlways;

  /// No description provided for @tapModeDouble.
  ///
  /// In ja, this message translates to:
  /// **'ダブルタップのみ'**
  String get tapModeDouble;

  /// No description provided for @tapModeOff.
  ///
  /// In ja, this message translates to:
  /// **'無効'**
  String get tapModeOff;

  /// No description provided for @secMsgTitle.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ領域設定'**
  String get secMsgTitle;

  /// No description provided for @msgLineCount.
  ///
  /// In ja, this message translates to:
  /// **'表示行数'**
  String get msgLineCount;

  /// No description provided for @msgOpacity.
  ///
  /// In ja, this message translates to:
  /// **'背景透過度'**
  String get msgOpacity;

  /// No description provided for @msgFontSize.
  ///
  /// In ja, this message translates to:
  /// **'フォントサイズ'**
  String get msgFontSize;

  /// No description provided for @secKeyTitle.
  ///
  /// In ja, this message translates to:
  /// **'物理キー割り当て'**
  String get secKeyTitle;

  /// No description provided for @keyVolUp.
  ///
  /// In ja, this message translates to:
  /// **'音量(+)キー'**
  String get keyVolUp;

  /// No description provided for @keyVolDown.
  ///
  /// In ja, this message translates to:
  /// **'音量(-)キー'**
  String get keyVolDown;

  /// No description provided for @keyBack.
  ///
  /// In ja, this message translates to:
  /// **'戻るキー/ジェスチャー'**
  String get keyBack;

  /// No description provided for @keyActionNone.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get keyActionNone;

  /// No description provided for @keyActionEsc.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル (ESC)'**
  String get keyActionEsc;

  /// No description provided for @keyActionSpace.
  ///
  /// In ja, this message translates to:
  /// **'決定/次へ (Space)'**
  String get keyActionSpace;

  /// No description provided for @keyActionMenu.
  ///
  /// In ja, this message translates to:
  /// **'メニュー表示'**
  String get keyActionMenu;

  /// No description provided for @secShortcutTitle.
  ///
  /// In ja, this message translates to:
  /// **'ショートカット編集'**
  String get secShortcutTitle;

  /// No description provided for @secCmdPanelTitle.
  ///
  /// In ja, this message translates to:
  /// **'カスタムコマンドパネル編集'**
  String get secCmdPanelTitle;

  /// No description provided for @secDefaultsTitle.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nh 直接編集'**
  String get secDefaultsTitle;

  /// No description provided for @secDefaultsSub.
  ///
  /// In ja, this message translates to:
  /// **'NetHackの構成設定ファイルをテキストエディタで編集します'**
  String get secDefaultsSub;

  /// No description provided for @secGameOptTitle.
  ///
  /// In ja, this message translates to:
  /// **'ゲームオプション (defaults.nh)'**
  String get secGameOptTitle;

  /// No description provided for @optTutorial.
  ///
  /// In ja, this message translates to:
  /// **'チュートリアルモード'**
  String get optTutorial;

  /// No description provided for @optAutopickup.
  ///
  /// In ja, this message translates to:
  /// **'自動拾い (autopickup)'**
  String get optAutopickup;

  /// No description provided for @optPickupTypes.
  ///
  /// In ja, this message translates to:
  /// **'自動拾い対象タイプ'**
  String get optPickupTypes;

  /// No description provided for @optTime.
  ///
  /// In ja, this message translates to:
  /// **'経過ターン表示 (time)'**
  String get optTime;

  /// No description provided for @optShowexp.
  ///
  /// In ja, this message translates to:
  /// **'経験値表示 (showexp)'**
  String get optShowexp;

  /// No description provided for @optPriceQuotes.
  ///
  /// In ja, this message translates to:
  /// **'鑑定価格表示 (price_quotes)'**
  String get optPriceQuotes;

  /// No description provided for @optHiliteStatus.
  ///
  /// In ja, this message translates to:
  /// **'ステータス強調 (hilite_status)'**
  String get optHiliteStatus;

  /// No description provided for @optMenucolor.
  ///
  /// In ja, this message translates to:
  /// **'メニューカラー (menucolor)'**
  String get optMenucolor;

  /// No description provided for @optName.
  ///
  /// In ja, this message translates to:
  /// **'プレイヤー名 (name)'**
  String get optName;

  /// No description provided for @optDogname.
  ///
  /// In ja, this message translates to:
  /// **'犬の名前 (dogname)'**
  String get optDogname;

  /// No description provided for @optCatname.
  ///
  /// In ja, this message translates to:
  /// **'猫の名前 (catname)'**
  String get optCatname;

  /// No description provided for @optHorsename.
  ///
  /// In ja, this message translates to:
  /// **'馬の名前 (horsename)'**
  String get optHorsename;

  /// No description provided for @optFruit.
  ///
  /// In ja, this message translates to:
  /// **'果物の名前 (fruit)'**
  String get optFruit;

  /// No description provided for @resetDefaults.
  ///
  /// In ja, this message translates to:
  /// **'設定を初期状態にリセット'**
  String get resetDefaults;

  /// No description provided for @resetDefaultsConfirm.
  ///
  /// In ja, this message translates to:
  /// **'すべての設定を初期値に戻しますか？'**
  String get resetDefaultsConfirm;

  /// No description provided for @ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In ja, this message translates to:
  /// **'はい'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ja, this message translates to:
  /// **'いいえ'**
  String get no;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @search.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In ja, this message translates to:
  /// **'クリア'**
  String get clear;

  /// No description provided for @enterNamePrompt.
  ///
  /// In ja, this message translates to:
  /// **'プレイヤー名を入力してください'**
  String get enterNamePrompt;

  /// No description provided for @enterTextPrompt.
  ///
  /// In ja, this message translates to:
  /// **'テキストを入力してください'**
  String get enterTextPrompt;

  /// No description provided for @selectQuantity.
  ///
  /// In ja, this message translates to:
  /// **'個数を指定'**
  String get selectQuantity;

  /// No description provided for @all.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get all;

  /// No description provided for @count.
  ///
  /// In ja, this message translates to:
  /// **'個'**
  String get count;

  /// No description provided for @guidebookTitle.
  ///
  /// In ja, this message translates to:
  /// **'NetHack ガイドブック'**
  String get guidebookTitle;

  /// No description provided for @fullMapTitle.
  ///
  /// In ja, this message translates to:
  /// **'ダンジョン全体マップ'**
  String get fullMapTitle;

  /// No description provided for @msgHistoryTitle.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ履歴'**
  String get msgHistoryTitle;

  /// No description provided for @tombstoneRIP.
  ///
  /// In ja, this message translates to:
  /// **'冥福を祈る'**
  String get tombstoneRIP;

  /// No description provided for @keyboardTitle.
  ///
  /// In ja, this message translates to:
  /// **'NetHack キーボード'**
  String get keyboardTitle;

  /// No description provided for @dpadNormal.
  ///
  /// In ja, this message translates to:
  /// **'通常移動'**
  String get dpadNormal;

  /// No description provided for @dpadUpper.
  ///
  /// In ja, this message translates to:
  /// **'走る (Shift)'**
  String get dpadUpper;

  /// No description provided for @dpadGLower.
  ///
  /// In ja, this message translates to:
  /// **'指定移動 (g)'**
  String get dpadGLower;

  /// No description provided for @dpadGUpper.
  ///
  /// In ja, this message translates to:
  /// **'走って指定移動 (G)'**
  String get dpadGUpper;

  /// No description provided for @dpadCtrl.
  ///
  /// In ja, this message translates to:
  /// **'制御入力 (Ctrl)'**
  String get dpadCtrl;

  /// No description provided for @dpadMCmd.
  ///
  /// In ja, this message translates to:
  /// **'メタキー (Meta/Alt)'**
  String get dpadMCmd;

  /// No description provided for @dpadFCmd.
  ///
  /// In ja, this message translates to:
  /// **'ファイト/攻撃 (F)'**
  String get dpadFCmd;

  /// No description provided for @whoAreYou.
  ///
  /// In ja, this message translates to:
  /// **'お名前は？'**
  String get whoAreYou;

  /// No description provided for @savedGames.
  ///
  /// In ja, this message translates to:
  /// **'既存のセーブデータ:'**
  String get savedGames;

  /// No description provided for @playMode.
  ///
  /// In ja, this message translates to:
  /// **'プレイモード:'**
  String get playMode;

  /// No description provided for @playModeNormal.
  ///
  /// In ja, this message translates to:
  /// **'通常'**
  String get playModeNormal;

  /// No description provided for @playModeExplore.
  ///
  /// In ja, this message translates to:
  /// **'探索'**
  String get playModeExplore;

  /// No description provided for @playModeWizard.
  ///
  /// In ja, this message translates to:
  /// **'ウィザード'**
  String get playModeWizard;

  /// No description provided for @modeDescNormal.
  ///
  /// In ja, this message translates to:
  /// **'🏆 通常のスコアアタック・標準プレイ用。死亡するとゲームオーバーになります。'**
  String get modeDescNormal;

  /// No description provided for @modeDescExplore.
  ///
  /// In ja, this message translates to:
  /// **'🔍 死亡時に復活を選択できる練習用モード。スコアはハイスコア一覧に記録されません。'**
  String get modeDescExplore;

  /// No description provided for @modeDescWizard.
  ///
  /// In ja, this message translates to:
  /// **'🧙 デバッグ・検証用モード。任意のアイテム生成や無敵化コマンドなどのデバッグ機能が使用できます（名前は wizard に固定）。'**
  String get modeDescWizard;

  /// No description provided for @bytesCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} / {max} バイト'**
  String bytesCount(Object count, Object max);

  /// No description provided for @nameTooLong.
  ///
  /// In ja, this message translates to:
  /// **'名前が長すぎます。{max} バイト以内で入力してください。'**
  String nameTooLong(Object max);

  /// No description provided for @enterText.
  ///
  /// In ja, this message translates to:
  /// **'テキストを入力してください'**
  String get enterText;

  /// No description provided for @selectExtCmd.
  ///
  /// In ja, this message translates to:
  /// **'拡張コマンドの選択:'**
  String get selectExtCmd;

  /// No description provided for @filterCmds.
  ///
  /// In ja, this message translates to:
  /// **'コマンドを絞り込み...'**
  String get filterCmds;

  /// No description provided for @selectAll.
  ///
  /// In ja, this message translates to:
  /// **'全て選択'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In ja, this message translates to:
  /// **'解除'**
  String get deselectAll;

  /// No description provided for @howMany.
  ///
  /// In ja, this message translates to:
  /// **'個数を選択してください'**
  String get howMany;

  /// No description provided for @runHighlights.
  ///
  /// In ja, this message translates to:
  /// **'【今回のハイライト】'**
  String get runHighlights;

  /// No description provided for @recallingMemories.
  ///
  /// In ja, this message translates to:
  /// **'ダンジョンの記憶を辿っています...'**
  String get recallingMemories;

  /// No description provided for @none.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get none;

  /// No description provided for @entriesCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String entriesCount(Object count);

  /// No description provided for @noMsgHistory.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ履歴はありません'**
  String get noMsgHistory;

  /// No description provided for @fullLevelMap.
  ///
  /// In ja, this message translates to:
  /// **'階層の全体地図'**
  String get fullLevelMap;

  /// No description provided for @pinchToZoom.
  ///
  /// In ja, this message translates to:
  /// **'ピンチ操作でズームイン/ズームアウトが可能です'**
  String get pinchToZoom;

  /// No description provided for @editShortcutTitle.
  ///
  /// In ja, this message translates to:
  /// **'{name} を編集'**
  String editShortcutTitle(Object name);

  /// No description provided for @shortcutHint.
  ///
  /// In ja, this message translates to:
  /// **'例: i, d, #terrain, #herecmdmenu 等'**
  String get shortcutHint;

  /// No description provided for @shortcutHelper.
  ///
  /// In ja, this message translates to:
  /// **'#で始まるものは拡張コマンドとして入力送信されます'**
  String get shortcutHelper;

  /// No description provided for @searchCmdOrDesc.
  ///
  /// In ja, this message translates to:
  /// **'コマンド名や説明で検索...'**
  String get searchCmdOrDesc;

  /// No description provided for @noCmdFound.
  ///
  /// In ja, this message translates to:
  /// **'見つかりませんでした'**
  String get noCmdFound;

  /// No description provided for @detailedSettings.
  ///
  /// In ja, this message translates to:
  /// **'詳細ゲーム設定'**
  String get detailedSettings;

  /// No description provided for @secUILayoutTitle.
  ///
  /// In ja, this message translates to:
  /// **'UI配置カスタマイズ'**
  String get secUILayoutTitle;

  /// No description provided for @secUILayoutSub.
  ///
  /// In ja, this message translates to:
  /// **'画面レイアウトのパターンを選択します'**
  String get secUILayoutSub;

  /// No description provided for @layoutPatternLabel.
  ///
  /// In ja, this message translates to:
  /// **'レイアウトパターン'**
  String get layoutPatternLabel;

  /// No description provided for @layoutPatternDesc1.
  ///
  /// In ja, this message translates to:
  /// **'ステータス・メッセージ: 上部 / 移動パッド・ショートカット: 下部'**
  String get layoutPatternDesc1;

  /// No description provided for @layoutPatternDesc2.
  ///
  /// In ja, this message translates to:
  /// **'ステータス・メッセージ: 下部 / 移動パッド・ショートカット: 上部'**
  String get layoutPatternDesc2;

  /// No description provided for @swapPadSideTitle.
  ///
  /// In ja, this message translates to:
  /// **'移動パッドとショートカットの左右を入れ替える'**
  String get swapPadSideTitle;

  /// No description provided for @swapPadSideDesc.
  ///
  /// In ja, this message translates to:
  /// **'移動パッドを右側、ショートカットボタンを左側に配置します'**
  String get swapPadSideDesc;

  /// No description provided for @menuButtonPos.
  ///
  /// In ja, this message translates to:
  /// **'半透明メニューボタンの配置位置'**
  String get menuButtonPos;

  /// No description provided for @mapButtonPos.
  ///
  /// In ja, this message translates to:
  /// **'半透明地図ボタンの配置位置'**
  String get mapButtonPos;

  /// No description provided for @posTopLeft.
  ///
  /// In ja, this message translates to:
  /// **'左上'**
  String get posTopLeft;

  /// No description provided for @posTopRight.
  ///
  /// In ja, this message translates to:
  /// **'右上'**
  String get posTopRight;

  /// No description provided for @posLeftEdge.
  ///
  /// In ja, this message translates to:
  /// **'左端(中央)'**
  String get posLeftEdge;

  /// No description provided for @posRightEdge.
  ///
  /// In ja, this message translates to:
  /// **'右端(中央)'**
  String get posRightEdge;

  /// No description provided for @posBottomLeft.
  ///
  /// In ja, this message translates to:
  /// **'左下'**
  String get posBottomLeft;

  /// No description provided for @posBottomRight.
  ///
  /// In ja, this message translates to:
  /// **'右下'**
  String get posBottomRight;

  /// No description provided for @posTop.
  ///
  /// In ja, this message translates to:
  /// **'上部'**
  String get posTop;

  /// No description provided for @posBottom.
  ///
  /// In ja, this message translates to:
  /// **'下部'**
  String get posBottom;

  /// No description provided for @posLeft.
  ///
  /// In ja, this message translates to:
  /// **'左側 (スワイプ可)'**
  String get posLeft;

  /// No description provided for @posRight.
  ///
  /// In ja, this message translates to:
  /// **'右側 (スワイプ可)'**
  String get posRight;

  /// No description provided for @padOpacityTitle.
  ///
  /// In ja, this message translates to:
  /// **'ボタン不透明度'**
  String get padOpacityTitle;

  /// No description provided for @dpadScaleTitle.
  ///
  /// In ja, this message translates to:
  /// **'移動ボタンサイズ倍率'**
  String get dpadScaleTitle;

  /// No description provided for @dpadScaleLabel.
  ///
  /// In ja, this message translates to:
  /// **'移動'**
  String get dpadScaleLabel;

  /// No description provided for @dpadLongPressTitle.
  ///
  /// In ja, this message translates to:
  /// **'移動パッド長押し時の移動モード'**
  String get dpadLongPressTitle;

  /// No description provided for @dpadModeNormal.
  ///
  /// In ja, this message translates to:
  /// **'標準'**
  String get dpadModeNormal;

  /// No description provided for @dpadModeUpper.
  ///
  /// In ja, this message translates to:
  /// **'大文字'**
  String get dpadModeUpper;

  /// No description provided for @dpadModeGLower.
  ///
  /// In ja, this message translates to:
  /// **'g'**
  String get dpadModeGLower;

  /// No description provided for @dpadModeGUpper.
  ///
  /// In ja, this message translates to:
  /// **'G'**
  String get dpadModeGUpper;

  /// No description provided for @dpadModeCtrl.
  ///
  /// In ja, this message translates to:
  /// **'^(Ctrl)'**
  String get dpadModeCtrl;

  /// No description provided for @dpadModeMCmd.
  ///
  /// In ja, this message translates to:
  /// **'m'**
  String get dpadModeMCmd;

  /// No description provided for @dpadModeFCmd.
  ///
  /// In ja, this message translates to:
  /// **'F'**
  String get dpadModeFCmd;

  /// No description provided for @mapTapTravelTitle.
  ///
  /// In ja, this message translates to:
  /// **'マップタップでの自動移動'**
  String get mapTapTravelTitle;

  /// No description provided for @mapTapAlways.
  ///
  /// In ja, this message translates to:
  /// **'常に有効'**
  String get mapTapAlways;

  /// No description provided for @mapTapAfterScroll.
  ///
  /// In ja, this message translates to:
  /// **'スクロール・ズーム直後のみ有効'**
  String get mapTapAfterScroll;

  /// No description provided for @shortcutPadScaleTitle.
  ///
  /// In ja, this message translates to:
  /// **'ショートカットボタンサイズ倍率'**
  String get shortcutPadScaleTitle;

  /// No description provided for @shortcutPadScaleLabel.
  ///
  /// In ja, this message translates to:
  /// **'ショートカット'**
  String get shortcutPadScaleLabel;

  /// No description provided for @cmdPanelScaleTitle.
  ///
  /// In ja, this message translates to:
  /// **'コマンドパネルサイズ倍率'**
  String get cmdPanelScaleTitle;

  /// No description provided for @cmdPanelScaleLabel.
  ///
  /// In ja, this message translates to:
  /// **'コマンドパネル'**
  String get cmdPanelScaleLabel;

  /// No description provided for @drawerPosTitle.
  ///
  /// In ja, this message translates to:
  /// **'メニュー(ドロワー)の引き出し位置'**
  String get drawerPosTitle;

  /// No description provided for @appliedScale.
  ///
  /// In ja, this message translates to:
  /// **'適用倍率: {scale}'**
  String appliedScale(Object scale);

  /// No description provided for @autoAdjustedScreen.
  ///
  /// In ja, this message translates to:
  /// **'⚠ 画面幅により自動調整'**
  String get autoAdjustedScreen;

  /// No description provided for @secMsgSub.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ領域の行数・透過度・フォントサイズ'**
  String get secMsgSub;

  /// No description provided for @msgLineCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'現在: {count} 行（最新メッセージを{count}行表示）'**
  String msgLineCountLabel(Object count);

  /// No description provided for @msgOpacityLabel.
  ///
  /// In ja, this message translates to:
  /// **'現在: {percent}%（0% = 完全透明 / 100% = 不透明）'**
  String msgOpacityLabel(Object percent);

  /// No description provided for @msgFontSizeLabel.
  ///
  /// In ja, this message translates to:
  /// **'現在: {size} pt'**
  String msgFontSizeLabel(Object size);

  /// No description provided for @preview.
  ///
  /// In ja, this message translates to:
  /// **'プレビュー'**
  String get preview;

  /// No description provided for @msgSampleText.
  ///
  /// In ja, this message translates to:
  /// **'メッセージのサンプルテキストです。\nWelcome to NetHackJP!'**
  String get msgSampleText;

  /// No description provided for @secKeySub.
  ///
  /// In ja, this message translates to:
  /// **'音量ボタンや戻るキーにゲームコマンドを割り当てます'**
  String get secKeySub;

  /// No description provided for @keyVolUpTitle.
  ///
  /// In ja, this message translates to:
  /// **'音量アップキー'**
  String get keyVolUpTitle;

  /// No description provided for @keyVolDownTitle.
  ///
  /// In ja, this message translates to:
  /// **'音量ダウンキー'**
  String get keyVolDownTitle;

  /// No description provided for @keyBackTitle.
  ///
  /// In ja, this message translates to:
  /// **'戻るボタン'**
  String get keyBackTitle;

  /// No description provided for @volActNone.
  ///
  /// In ja, this message translates to:
  /// **'機能なし (通常音量変化)'**
  String get volActNone;

  /// No description provided for @volActEnter.
  ///
  /// In ja, this message translates to:
  /// **'決定 (Enter)'**
  String get volActEnter;

  /// No description provided for @volActSpace.
  ///
  /// In ja, this message translates to:
  /// **'スペース'**
  String get volActSpace;

  /// No description provided for @volActEsc.
  ///
  /// In ja, this message translates to:
  /// **'エスケープ (Esc)'**
  String get volActEsc;

  /// No description provided for @volActInv.
  ///
  /// In ja, this message translates to:
  /// **'インベントリ (i)'**
  String get volActInv;

  /// No description provided for @volActSearch.
  ///
  /// In ja, this message translates to:
  /// **'周囲の探索 (s)'**
  String get volActSearch;

  /// No description provided for @volActRedraw.
  ///
  /// In ja, this message translates to:
  /// **'画面再描画 (^R)'**
  String get volActRedraw;

  /// No description provided for @backActNone.
  ///
  /// In ja, this message translates to:
  /// **'機能なし (通常通りアプリを閉じる)'**
  String get backActNone;

  /// No description provided for @backActEsc.
  ///
  /// In ja, this message translates to:
  /// **'エスケープ (Esc/ダイアログ閉じ)'**
  String get backActEsc;

  /// No description provided for @backActInv.
  ///
  /// In ja, this message translates to:
  /// **'インベントリ (i)'**
  String get backActInv;

  /// No description provided for @backActSearch.
  ///
  /// In ja, this message translates to:
  /// **'周囲の探索 (s)'**
  String get backActSearch;

  /// No description provided for @backActWait.
  ///
  /// In ja, this message translates to:
  /// **'待機する (.)'**
  String get backActWait;

  /// No description provided for @backActSave.
  ///
  /// In ja, this message translates to:
  /// **'セーブして終了する (S)'**
  String get backActSave;

  /// No description provided for @secShortcutSub.
  ///
  /// In ja, this message translates to:
  /// **'3x3ショートカットパッドに割り当てるキーを設定'**
  String get secShortcutSub;

  /// No description provided for @shortcutNotSet.
  ///
  /// In ja, this message translates to:
  /// **'(未設定)'**
  String get shortcutNotSet;

  /// No description provided for @shortcutLabelFormat.
  ///
  /// In ja, this message translates to:
  /// **'{position} ボタン ({index})'**
  String shortcutLabelFormat(Object index, Object position);

  /// No description provided for @shortcutBtnTL.
  ///
  /// In ja, this message translates to:
  /// **'左上'**
  String get shortcutBtnTL;

  /// No description provided for @shortcutBtnTC.
  ///
  /// In ja, this message translates to:
  /// **'上中央'**
  String get shortcutBtnTC;

  /// No description provided for @shortcutBtnTR.
  ///
  /// In ja, this message translates to:
  /// **'右上'**
  String get shortcutBtnTR;

  /// No description provided for @shortcutBtnML.
  ///
  /// In ja, this message translates to:
  /// **'中段左'**
  String get shortcutBtnML;

  /// No description provided for @shortcutBtnMC.
  ///
  /// In ja, this message translates to:
  /// **'中段中央'**
  String get shortcutBtnMC;

  /// No description provided for @shortcutBtnMR.
  ///
  /// In ja, this message translates to:
  /// **'中段右'**
  String get shortcutBtnMR;

  /// No description provided for @shortcutBtnBL.
  ///
  /// In ja, this message translates to:
  /// **'下段左'**
  String get shortcutBtnBL;

  /// No description provided for @shortcutBtnBC.
  ///
  /// In ja, this message translates to:
  /// **'下段中央'**
  String get shortcutBtnBC;

  /// No description provided for @shortcutBtnBR.
  ///
  /// In ja, this message translates to:
  /// **'下段右'**
  String get shortcutBtnBR;

  /// No description provided for @secCmdPanelSub.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム下部スワイプ対応のボタン群を管理'**
  String get secCmdPanelSub;

  /// No description provided for @showPanelNamesTitle.
  ///
  /// In ja, this message translates to:
  /// **'パネル名を表示'**
  String get showPanelNamesTitle;

  /// No description provided for @showPanelNamesSub.
  ///
  /// In ja, this message translates to:
  /// **'各パネル行の左端に名前バッジを表示'**
  String get showPanelNamesSub;

  /// No description provided for @noButtons.
  ///
  /// In ja, this message translates to:
  /// **'(ボタンなし)'**
  String get noButtons;

  /// No description provided for @addNewPanel.
  ///
  /// In ja, this message translates to:
  /// **'新しいコマンドパネルを追加'**
  String get addNewPanel;

  /// No description provided for @editPanelTitle.
  ///
  /// In ja, this message translates to:
  /// **'パネル {index} を編集'**
  String editPanelTitle(Object index);

  /// No description provided for @panelNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'パネル名'**
  String get panelNameLabel;

  /// No description provided for @cmdListLabel.
  ///
  /// In ja, this message translates to:
  /// **'ボタンコマンド一覧'**
  String get cmdListLabel;

  /// No description provided for @cmdListHelper.
  ///
  /// In ja, this message translates to:
  /// **'スペース区切りでコマンドを入力してください'**
  String get cmdListHelper;

  /// No description provided for @defaultPanelName.
  ///
  /// In ja, this message translates to:
  /// **'標準パネル'**
  String get defaultPanelName;

  /// No description provided for @panelNName.
  ///
  /// In ja, this message translates to:
  /// **'パネル {index}'**
  String panelNName(Object index);

  /// No description provided for @secGameRulesTitle.
  ///
  /// In ja, this message translates to:
  /// **'ゲームルール・プレイ設定 (defaults.nh)'**
  String get secGameRulesTitle;

  /// No description provided for @secGameRulesSub.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム本体の動作オプションを設定します（※反映には新規ゲームの開始が必要です）'**
  String get secGameRulesSub;

  /// No description provided for @tutorialModeTitle.
  ///
  /// In ja, this message translates to:
  /// **'チュートリアル動作モード'**
  String get tutorialModeTitle;

  /// No description provided for @tutorialModeSub.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム開始時のチュートリアル問いかけ・開始動作を設定します'**
  String get tutorialModeSub;

  /// No description provided for @tutorialAsk.
  ///
  /// In ja, this message translates to:
  /// **'毎回確認する\n (標準)'**
  String get tutorialAsk;

  /// No description provided for @tutorialAlways.
  ///
  /// In ja, this message translates to:
  /// **'常に開始する\n (OPTIONS=tutorial)'**
  String get tutorialAlways;

  /// No description provided for @tutorialNever.
  ///
  /// In ja, this message translates to:
  /// **'常に通常プレイ\n (OPTIONS=!tutorial)'**
  String get tutorialNever;

  /// No description provided for @numberPadTitle.
  ///
  /// In ja, this message translates to:
  /// **'テンキー移動 (number_pad)'**
  String get numberPadTitle;

  /// No description provided for @numberPadSub.
  ///
  /// In ja, this message translates to:
  /// **'テンキー（1-9）での移動やレイアウトを設定します'**
  String get numberPadSub;

  /// No description provided for @numPadOff.
  ///
  /// In ja, this message translates to:
  /// **'OFF (!number_pad)'**
  String get numPadOff;

  /// No description provided for @numPadStandard.
  ///
  /// In ja, this message translates to:
  /// **'1: 標準テンキー'**
  String get numPadStandard;

  /// No description provided for @numPadPCHack.
  ///
  /// In ja, this message translates to:
  /// **'2: PC Hack互換'**
  String get numPadPCHack;

  /// No description provided for @numPadPhone.
  ///
  /// In ja, this message translates to:
  /// **'3: 電話配列'**
  String get numPadPhone;

  /// No description provided for @numPadPhonePCHack.
  ///
  /// In ja, this message translates to:
  /// **'4: 電話+PC Hack'**
  String get numPadPhonePCHack;

  /// No description provided for @numPadGerman.
  ///
  /// In ja, this message translates to:
  /// **'-1: ドイツ語配列'**
  String get numPadGerman;

  /// No description provided for @autopickupSub.
  ///
  /// In ja, this message translates to:
  /// **'足元のアイテムを自動的に拾います'**
  String get autopickupSub;

  /// No description provided for @pickupTypesTitle.
  ///
  /// In ja, this message translates to:
  /// **'自動拾い対象のアイテム種別 (pickup_types)'**
  String get pickupTypesTitle;

  /// No description provided for @pickupTypesAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて拾う'**
  String get pickupTypesAll;

  /// No description provided for @pickupTypesSymbols.
  ///
  /// In ja, this message translates to:
  /// **'対象記号: {symbols}'**
  String pickupTypesSymbols(Object symbols);

  /// No description provided for @pickupTypesDisabledNote.
  ///
  /// In ja, this message translates to:
  /// **'※自動拾いが有効な場合のみ設定できます'**
  String get pickupTypesDisabledNote;

  /// No description provided for @timeSub.
  ///
  /// In ja, this message translates to:
  /// **'ステータス表示に行動ターン数を表示します'**
  String get timeSub;

  /// No description provided for @showexpSub.
  ///
  /// In ja, this message translates to:
  /// **'ステータス表示に獲得経験値を表示します'**
  String get showexpSub;

  /// No description provided for @priceQuotesSub.
  ///
  /// In ja, this message translates to:
  /// **'未識別オブジェクトに記憶済み価格情報を表示します'**
  String get priceQuotesSub;

  /// No description provided for @hiliteStatusSub.
  ///
  /// In ja, this message translates to:
  /// **'HPや各種状態変化を色付きでハイライト表示します'**
  String get hiliteStatusSub;

  /// No description provided for @menucolorSub.
  ///
  /// In ja, this message translates to:
  /// **'インベントリやダイアログの各項目を色付き表示します'**
  String get menucolorSub;

  /// No description provided for @nameSub.
  ///
  /// In ja, this message translates to:
  /// **'主人公のデフォルト名 (name)'**
  String get nameSub;

  /// No description provided for @dognameSub.
  ///
  /// In ja, this message translates to:
  /// **'犬の名前 (dogname)'**
  String get dognameSub;

  /// No description provided for @catnameSub.
  ///
  /// In ja, this message translates to:
  /// **'猫の名前 (catname)'**
  String get catnameSub;

  /// No description provided for @horsenameSub.
  ///
  /// In ja, this message translates to:
  /// **'馬の名前 (horsename)'**
  String get horsenameSub;

  /// No description provided for @fruitSub.
  ///
  /// In ja, this message translates to:
  /// **'果物の名前 (fruit)'**
  String get fruitSub;

  /// No description provided for @defaultUnspecified.
  ///
  /// In ja, this message translates to:
  /// **'デフォルト (未指定)'**
  String get defaultUnspecified;

  /// No description provided for @defaultSlimeMold.
  ///
  /// In ja, this message translates to:
  /// **'デフォルト (slime mold)'**
  String get defaultSlimeMold;

  /// No description provided for @pickupTypesDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'自動拾い対象アイテム'**
  String get pickupTypesDialogTitle;

  /// No description provided for @directInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'直接入力 (記号の羅列)'**
  String get directInputLabel;

  /// No description provided for @directInputHint.
  ///
  /// In ja, this message translates to:
  /// **'例: \$\"=/!?+'**
  String get directInputHint;

  /// No description provided for @directInputHelper.
  ///
  /// In ja, this message translates to:
  /// **'拾いたいアイテムの記号を入力してください'**
  String get directInputHelper;

  /// No description provided for @toggleFromOptions.
  ///
  /// In ja, this message translates to:
  /// **'または選択肢からトグル選択:'**
  String get toggleFromOptions;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @nameTooLongMaxBytes.
  ///
  /// In ja, this message translates to:
  /// **'名前が長すぎます。{maxBytes}バイト以内で入力してください。'**
  String nameTooLongMaxBytes(Object maxBytes);

  /// No description provided for @textTooLongMaxBytes.
  ///
  /// In ja, this message translates to:
  /// **'文字数が多すぎます。{maxBytes}バイト以内で入力してください。'**
  String textTooLongMaxBytes(Object maxBytes);

  /// No description provided for @hintEmptyDefault.
  ///
  /// In ja, this message translates to:
  /// **'未指定の場合は空欄'**
  String get hintEmptyDefault;

  /// No description provided for @itemGold.
  ///
  /// In ja, this message translates to:
  /// **'金貨 (\$)'**
  String get itemGold;

  /// No description provided for @itemAmulet.
  ///
  /// In ja, this message translates to:
  /// **'首飾り/アミュレット (\")'**
  String get itemAmulet;

  /// No description provided for @itemArmor.
  ///
  /// In ja, this message translates to:
  /// **'防具 ([)'**
  String get itemArmor;

  /// No description provided for @itemFood.
  ///
  /// In ja, this message translates to:
  /// **'食料 (%)'**
  String get itemFood;

  /// No description provided for @itemScroll.
  ///
  /// In ja, this message translates to:
  /// **'巻物 (?)'**
  String get itemScroll;

  /// No description provided for @itemSpellbook.
  ///
  /// In ja, this message translates to:
  /// **'呪文の書 (+)'**
  String get itemSpellbook;

  /// No description provided for @itemWand.
  ///
  /// In ja, this message translates to:
  /// **'杖 (/)'**
  String get itemWand;

  /// No description provided for @itemRing.
  ///
  /// In ja, this message translates to:
  /// **'指輪 (=)'**
  String get itemRing;

  /// No description provided for @itemPotion.
  ///
  /// In ja, this message translates to:
  /// **'薬 (!)'**
  String get itemPotion;

  /// No description provided for @itemTool.
  ///
  /// In ja, this message translates to:
  /// **'道具 (()'**
  String get itemTool;

  /// No description provided for @itemGem.
  ///
  /// In ja, this message translates to:
  /// **'宝石 (*)'**
  String get itemGem;

  /// No description provided for @itemBall.
  ///
  /// In ja, this message translates to:
  /// **'弾薬/コンポーネント (0)'**
  String get itemBall;

  /// No description provided for @itemWeapon.
  ///
  /// In ja, this message translates to:
  /// **'武器 ()'**
  String get itemWeapon;

  /// No description provided for @itemOther.
  ///
  /// In ja, this message translates to:
  /// **'その他 (_)'**
  String get itemOther;

  /// No description provided for @secAdvancedTitle.
  ///
  /// In ja, this message translates to:
  /// **'高度な設定'**
  String get secAdvancedTitle;

  /// No description provided for @secOtherTitle.
  ///
  /// In ja, this message translates to:
  /// **'その他の設定'**
  String get secOtherTitle;

  /// No description provided for @tombstoneModeTitle.
  ///
  /// In ja, this message translates to:
  /// **'死亡時の墓表示モード'**
  String get tombstoneModeTitle;

  /// No description provided for @tombstoneModeImage.
  ///
  /// In ja, this message translates to:
  /// **'画像表示'**
  String get tombstoneModeImage;

  /// No description provided for @tombstoneModeText.
  ///
  /// In ja, this message translates to:
  /// **'テキスト表示'**
  String get tombstoneModeText;

  /// No description provided for @manualEditDefaults.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nh を手動で編集'**
  String get manualEditDefaults;

  /// No description provided for @manualEditDefaultsSub.
  ///
  /// In ja, this message translates to:
  /// **'詳細なゲームオプションファイルを直接記述します（※反映には新規ゲームの開始が必要です）'**
  String get manualEditDefaultsSub;

  /// No description provided for @exportSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定をエクスポート'**
  String get exportSettings;

  /// No description provided for @exportSettingsSub.
  ///
  /// In ja, this message translates to:
  /// **'現在の設定をJSON文字列でクリップボードにコピー'**
  String get exportSettingsSub;

  /// No description provided for @importSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定をインポート'**
  String get importSettings;

  /// No description provided for @importSettingsSub.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードの設定JSONを読み込んで適用します'**
  String get importSettingsSub;

  /// No description provided for @copiedJsonSuccess.
  ///
  /// In ja, this message translates to:
  /// **'設定JSONをクリップボードにコピーしました。'**
  String get copiedJsonSuccess;

  /// No description provided for @noTextInClipboard.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードにテキストがありません。'**
  String get noTextInClipboard;

  /// No description provided for @importedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'設定をインポートしました。'**
  String get importedSuccess;

  /// No description provided for @importErrorTitle.
  ///
  /// In ja, this message translates to:
  /// **'インポートエラー'**
  String get importErrorTitle;

  /// No description provided for @importErrorMsg.
  ///
  /// In ja, this message translates to:
  /// **'インポートに失敗しました。無効なJSONフォーマットです。\n{error}'**
  String importErrorMsg(Object error);

  /// No description provided for @secCreditsTitle.
  ///
  /// In ja, this message translates to:
  /// **'クレジット'**
  String get secCreditsTitle;

  /// No description provided for @creditsBody1.
  ///
  /// In ja, this message translates to:
  /// **'DartHack は、NetHack をベースとしつつ、Flutter/Dart によって再構築したモバイル版です。本アプリはオリジナルの NetHack をゲームコアとして使用していますが、NetHack 開発チーム（The NetHack DevTeam）とは一切関係ありません。'**
  String get creditsBody1;

  /// No description provided for @creditsBody2.
  ///
  /// In ja, this message translates to:
  /// **'本アプリは NetHack General Public License (NGPL) に基づき配布されています。  ソースコードは以下にて公開しています：https://github.com/satokiyon/DartHack'**
  String get creditsBody2;

  /// No description provided for @creditsBody3.
  ///
  /// In ja, this message translates to:
  /// **'UI デザインの一部は、gurrhack の ForkFront を参考にしています。'**
  String get creditsBody3;

  /// No description provided for @creditsContributors.
  ///
  /// In ja, this message translates to:
  /// **'Contributors:'**
  String get creditsContributors;

  /// No description provided for @creditsContributorList.
  ///
  /// In ja, this message translates to:
  /// **'• @satokiyon\n• with Google Antigravity and Gemini'**
  String get creditsContributorList;

  /// No description provided for @editDefaultsTitle.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nh を編集'**
  String get editDefaultsTitle;

  /// No description provided for @saveTooltip.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get saveTooltip;

  /// No description provided for @defaultsSaved.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nh を保存しました。'**
  String get defaultsSaved;

  /// No description provided for @saveErrorTitle.
  ///
  /// In ja, this message translates to:
  /// **'保存エラー'**
  String get saveErrorTitle;

  /// No description provided for @saveErrorMsg.
  ///
  /// In ja, this message translates to:
  /// **'ファイルを保存できませんでした。\n{error}'**
  String saveErrorMsg(Object error);

  /// No description provided for @discardChangesTitle.
  ///
  /// In ja, this message translates to:
  /// **'変更の破棄'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMsg.
  ///
  /// In ja, this message translates to:
  /// **'編集内容が保存されていません。破棄して戻りますか？'**
  String get discardChangesMsg;

  /// No description provided for @discard.
  ///
  /// In ja, this message translates to:
  /// **'破棄'**
  String get discard;

  /// No description provided for @defaultsNotFound.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nh が見つかりませんでした。'**
  String get defaultsNotFound;

  /// No description provided for @fileReadError.
  ///
  /// In ja, this message translates to:
  /// **'ファイルの読み込みエラー: {error}'**
  String fileReadError(Object error);

  /// No description provided for @defaultsEditNotice.
  ///
  /// In ja, this message translates to:
  /// **'※ defaults.nh の編集内容を反映するには新規ゲームの開始が必要です'**
  String get defaultsEditNotice;

  /// No description provided for @enterOptionHint.
  ///
  /// In ja, this message translates to:
  /// **'オプションを入力してください...'**
  String get enterOptionHint;

  /// No description provided for @selectedCountLabel.
  ///
  /// In ja, this message translates to:
  /// **' ({selectedCount}個選択中 / {maxCount})'**
  String selectedCountLabel(Object maxCount, Object selectedCount);

  /// No description provided for @resetAppSettingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'UI・操作設定を初期値に戻す'**
  String get resetAppSettingsTitle;

  /// No description provided for @resetAppSettingsSub.
  ///
  /// In ja, this message translates to:
  /// **'UI配置、操作パッド、メッセージ行数などをデフォルトに戻します'**
  String get resetAppSettingsSub;

  /// No description provided for @resetAppSettingsConfirm.
  ///
  /// In ja, this message translates to:
  /// **'UI・操作設定をデフォルトの初期値に戻しますか？'**
  String get resetAppSettingsConfirm;

  /// No description provided for @resetDefaultsFileTitle.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nhを初期ファイルに戻す'**
  String get resetDefaultsFileTitle;

  /// No description provided for @resetDefaultsFileSub.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nhファイルを初期のアセットファイルで上書きします'**
  String get resetDefaultsFileSub;

  /// No description provided for @resetDefaultsFileConfirm.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nhファイルを初期状態に戻しますか？既存のカスタム設定は上書きされます。'**
  String get resetDefaultsFileConfirm;

  /// No description provided for @resetAppSettingsSuccess.
  ///
  /// In ja, this message translates to:
  /// **'UI・操作設定を初期値に戻しました。'**
  String get resetAppSettingsSuccess;

  /// No description provided for @resetDefaultsFileSuccess.
  ///
  /// In ja, this message translates to:
  /// **'defaults.nhを初期ファイルに戻しました。'**
  String get resetDefaultsFileSuccess;

  /// No description provided for @btnResetConfirm.
  ///
  /// In ja, this message translates to:
  /// **'初期化'**
  String get btnResetConfirm;

  /// No description provided for @btnCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get btnCancel;

  /// No description provided for @anyKeyPromptTitle.
  ///
  /// In ja, this message translates to:
  /// **'キー機能の確認'**
  String get anyKeyPromptTitle;

  /// No description provided for @anyKeyPromptSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'調べたいキーを入力するか、下から選択してください:'**
  String get anyKeyPromptSubtitle;

  /// No description provided for @anyKeyPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'キーを入力...'**
  String get anyKeyPlaceholder;

  /// No description provided for @searchAnotherKey.
  ///
  /// In ja, this message translates to:
  /// **'他のキーを調べる'**
  String get searchAnotherKey;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
