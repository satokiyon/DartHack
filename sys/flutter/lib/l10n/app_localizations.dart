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
