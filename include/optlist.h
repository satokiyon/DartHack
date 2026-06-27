/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-27. */
/* NetHack 5.0	optlist.h */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef OPTLIST_H
#define OPTLIST_H

/*
 *  注意: オプションを追加（または削除）した場合は、次を確認してください:
 *             doc/options.txt
 *
 *         この文書には手順情報と、変更に伴って必要または推奨される
 *         更新内容の概要が記載されています。
 */

#define BACKWARD_COMPAT

extern int optfn_boolean(int, int, boolean, char *, char *);

enum OptType { BoolOpt, CompOpt, OthrOpt };
enum Y_N { No, Yes };
enum Off_On { Off, On };
/* 高度なオプションは、完全な従来型オプションメニューでのみ表示されます */
enum OptSection {
    OptS_General, OptS_Behavior, OptS_Map, OptS_Status, OptS_Advanced
};
enum menu_terminology_preference {
    Term_False, Term_Off, Term_Disabled, Term_Excluded, num_terms
};

struct allopt_t {
    const char *name;
    enum OptSection section;
    int minmatch;
    int expectedbuf;
    int idx;
    enum optset_restrictions setwhere;
    enum OptType opttyp;
    enum Y_N negateok;
    enum Y_N valok;
    enum Y_N dupeok;
    enum Y_N pfx;
    enum menu_terminology_preference termpref;
    boolean opt_in_out, *addr;
    int (*optfn)(int, int, boolean, char *, char *);
    const char *alias;
    const char *descr;
    const char *prefixgw;
    boolean initval, has_handler, dupdetected, disregarded;
};

#endif /* OPTLIST_H */

#if defined(NHOPT_PROTO) || defined(NHOPT_ENUM) || defined(NHOPT_PARSE)
/* clang-format off */
/* *INDENT-OFF* */

#define NoAlias ((const char *) 0)

#if defined(NHOPT_PROTO)
#define NHOPTB(a, sec, b, c, s, i, n, v, d, al, bp, termp, desc) /*empty*/
#define NHOPTC(a, sec, b, c, s, n, v, d, h, al, z)               \
static int optfn_##a(int, int, boolean, char *, char *);
#define NHOPTP(a, sec, b, c, s, n, v, d, h, al, z)               \
static int pfxfn_##a(int, int, boolean, char *, char *);
#define NHOPTO(m, sec, a, b, c, s, n, v, d, al, z)               \
static int optfn_##a(int, int, boolean, char *, char *);

#elif defined(NHOPT_ENUM)
#define NHOPTB(a, sec, b, c, s, i, n, v, d, al, bp, termp, desc) opt_##a,
#define NHOPTC(a, sec, b, c, s, n, v, d, h, al, z)   opt_##a,
#define NHOPTP(a, sec, b, c, s, n, v, d, h, al, z)   pfx_##a,
#define NHOPTO(m, sec, a, b, c, s, n, v, d, al, z)   opt_##a,

#elif defined(NHOPT_PARSE)
#define NHOPTB(a, sec, b, c, s, i, n, v, d, al, bp, termp, desc)             \
    { #a, OptS_##sec, 0, b, opt_##a, s, BoolOpt, n, v, d, No, termp, c,  \
      bp, &optfn_boolean, al, desc, (const char *) 0, i, 0, 0 , 0 },
#define NHOPTC(a, sec, b, c, s, n, v, d, h, al, z) \
    { #a, OptS_##sec, 0, b, opt_##a, s, CompOpt, n, v, d, No, 0, c,  \
      (boolean *) 0, &optfn_##a, al, z, (const char *) 0, Off, h, 0, 0 },
#define NHOPTP(a, sec, b, c, s, n, v, d, h, al, z) \
    { #a, OptS_##sec, 0, b, pfx_##a, s, CompOpt, n, v, d, Yes, 0, c, \
      (boolean *) 0, &pfxfn_##a, al, z, #a, Off, h, 0, 0 },
#define NHOPTO(m, sec, a, b, c, s, n, v, d, al, z) \
    { m, OptS_##sec, 0, b, opt_##a, s, OthrOpt, n, v, d, No, 0, c,   \
      (boolean *) 0, &optfn_##a, al, z, (const char *) 0, On, On, 0, 0 },

/* これは信頼できません。TILES_IN_GLYPHMAP がマルチインターフェース
 * バイナリで定義されていても、現在のインターフェースには
 * 適用されない可能性があるためです。
 */
#ifdef TILES_IN_GLYPHMAP
#define tiled_map_Def On
#define ascii_map_Def Off
#else
#define ascii_map_Def On
#define tiled_map_Def Off
#endif
#endif

/* B:名前, セクション, 長さ, opt_*, 設定可能場所?, 既定値?, 否定可?, 値可?, 重複可?, ハンドラ? 別名,
            booleanポインタ, 用語 */
/* C:名前, セクション, 長さ, opt_*, 設定可能場所?, 否定可?, 値可?, 重複可?, ハンドラ? 別名,
            説明 */
/* P:接頭辞, セクション, 長さ, opt_*, 設定可能場所?, 否定可?, 値可?, 重複可?, ハンドラ? 別名,
            説明*/
    /*
     * ほとんどのオプションはアルファベット順です。いくつかは
     * doset() が先に表示し、all_options_str() が先に収集して
     * #saveoptions により新しい RC ファイルの先頭へ書き出せるように、
     * リストの先頭へ固定配置されています。
     *
     * 先頭は windowtype です。値によって wc_ および wc2_ オプションの
     * 処理が影響を受けるためです。続いて playmode（コマンドライン指定が
     * できない、または方法を知らないプレイヤー向け）と name（ほぼ同様）、
     * その後に role、race、gender、align が続きます。これらは
     * #saveoptions で生成される RC ファイルの先頭に置かれます。
     */
    NHOPTC(windowtype, Advanced, WINTYPELEN, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "使用するウィンドウシステム（最初に指定することを推奨）")
    NHOPTC(playmode, Advanced, 8, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "通常プレイ、非スコア対象の探索モード、またはデバッグモード")
    NHOPTC(name, Advanced, PL_NSIZ, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "あなたのキャラクター名（例: name:Merlin-W）")
    NHOPTC(role, Advanced, PL_CSIZ, opt_in, set_gameview,
                Yes, Yes, Yes, No, "character",
                "開始時の役割（例: Barbarian、Valkyrie）")
    NHOPTC(race, Advanced, PL_CSIZ, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias,
                "開始時の種族（例: Human、Elf）")
    NHOPTC(gender, Advanced, 8, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias,
                "開始時の性別（male または female）")
    NHOPTC(alignment, Advanced, 8, opt_in, set_gameview,
                Yes, Yes, Yes, No, "align",
                "開始時の属性（lawful、neutral、または chaotic）")
    /* 特別な並び順はここまで。残りの項目はアルファベット順 */
    NHOPTB(accessiblemsg, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &a11y.accessiblemsg, Term_False,
           "メッセージに位置情報を追加する")
    NHOPTB(acoustics, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.acoustics, Term_False,
           "キャラクターが音を聞き取れるようにする")
 /* NHOPTC(align) -- 先頭へ移動済み */
    NHOPTC(align_message, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, No, Yes, NoAlias, "メッセージウィンドウの配置")
    NHOPTC(align_status, Advanced, 20, opt_in, set_gameview,
                No, Yes, No, Yes, NoAlias, "ステータスウィンドウの配置")
#ifdef WIN32
    NHOPTC(altkeyhandling, Advanced, 20, opt_in, set_in_game,
                No, Yes, No, Yes, "altkeyhandler", "代替キー処理")
#else
    NHOPTC(altkeyhandling, Advanced, 20, opt_in, set_in_config,
                No, Yes, No, Yes, "altkeyhandler", "（適用外）")
#endif
#ifdef ALTMETA
    NHOPTB(altmeta, Advanced, 0, opt_out, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.altmeta, Term_False,
           "\"ESC c\" を M-c（Meta+c、8ビット目セット）として扱う")
#elif defined(AMIGA_INTUITION)
    NHOPTB(altmeta, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &sysflags.altmeta, Term_False,
           "ALT+c を M-c（Meta+c、8ビット目セット）として扱う")
#else
    NHOPTB(altmeta, Advanced, 0, opt_out, set_in_config,
           Off, Yes, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(armorstatus, Advanced, 0, opt_in, set_in_game,
                Off, Yes, No, No, NoAlias, &flags.armorstatus, Term_False,
                "現在装備中の防具をステータス欄に要約表示する")
    /* this one needs unique handling because different window ports
       expect different defaults */
    NHOPTB(ascii_map, Advanced, 0, ascii_map_Def, set_in_game,
                ascii_map_Def, Yes, No, No, NoAlias, &iflags.wc_ascii_map,
                Term_False, "マップをテキストとして表示する")
    NHOPTO("autocompletions", Advanced, o_autocomplete, BUFSZ, opt_in,
                set_in_game, No, Yes, No, NoAlias, "自動補完を編集する")
    NHOPTB(autodescribe, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.autodescribe, Term_False,
           "カーソル下の地形を説明する")
    NHOPTB(autodig, Behavior, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.autodig, Term_False,
           "移動中に掘削道具を装備していれば掘る")
    NHOPTB(autoopen, Behavior, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.autoopen, Term_False,
           "ドアに向かって歩くと開けようとする")
    NHOPTB(autopickup, Behavior, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.pickup, Term_False,
           "アイテムを自動的に拾う")
    NHOPTO("autopickup exceptions", Behavior, o_autopickup_exceptions, BUFSZ,
                opt_in, set_in_game,
                No, Yes, No, NoAlias, "自動拾いの例外を編集する")
    NHOPTB(autoquiver, Behavior, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.autoquiver, Term_False,
           "射撃時に空の矢筒を自動で補充する")
    NHOPTC(autounlock, Behavior, 80, opt_out, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "施錠されたドアや箱に遭遇したときの動作")
    NHOPTB(bgcolors, Map, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.bgcolors, Term_Off,
           "一部のマップ強調表示に背景色を使う")
    NHOPTO("bind keys", Advanced, o_bind_keys, BUFSZ, opt_in, set_in_game,
                No, Yes, No, NoAlias, "キー割り当てを編集する")
#if defined(MICRO) && !defined(AMIGA)
    NHOPTB(BIOS, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.BIOS, Term_False,
           "IBM ROM BIOS 呼び出しを使用する")
#else
    NHOPTB(BIOS, Advanced, 0, opt_in, set_in_config,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(blind, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, "permablind", &u.uroleplay.blind, Term_False,
           "キャラクターを恒久的に盲目にする")
    NHOPTB(bones, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &flags.bones, Term_False,
           "bones ファイルの読み込みを許可する")
#ifdef BACKWARD_COMPAT
    NHOPTC(boulder, Advanced, 1, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "非推奨（代わりにシンボルファイルの S_boulder を使用）")
#endif
    NHOPTC(catname, Advanced, PL_PSIZ, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "開始時のペットが子猫の場合の名前")
#ifdef INSURANCE
    NHOPTB(checkpoint, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.ins_chkpt, Term_False,
           "各レベル変更後にゲーム状態を保存する")
#else
    NHOPTB(checkpoint, Advanced, 0, opt_out, set_in_config,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(cmdassist, Behavior, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.cmdassist, Term_False,
           "方向入力エラー時のヘルプを表示する")
    NHOPTB(color, Map, 0, opt_out, set_in_game,
           On, Yes, No, No, "colour", &iflags.wc_color, Term_False,
           "マップで色を使う")
    NHOPTB(confirm, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.confirm, Term_False,
           "手なずけたモンスターや友好的モンスターを攻撃する前に確認する")
#ifdef CRASHREPORT
    NHOPTC(crash_email, Advanced, PL_NSIZ, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "報告用メールアドレス")
    NHOPTC(crash_name, Advanced, PL_NSIZ, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "報告用のあなたの名前")
    NHOPTC(crash_urlmax, Advanced, PL_NSIZ, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "生成可能な最長 URL の長さ")
#endif
#ifdef CURSES_GRAPHICS
    NHOPTC(cursesgraphics, Advanced, 70, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "curses の表示シンボルを symset に読み込む")
#endif
    NHOPTB(customcolors, Map, 0, opt_out, set_in_game,
           On, Yes, No, No, "customcolours", &iflags.customcolors,
           Term_False, "マップにカスタムカラーを使用する")
    NHOPTB(customsymbols, Map, 0, opt_out, set_in_game,
           On, Yes, No, No, "customsymbols", &iflags.customsymbols,
           Term_False, "マップにカスタム UTF-8 シンボルを使用する")
    NHOPTB(dark_room, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.dark_room, Term_False,
           "視界の外の床を異なる方法で表示する")
    NHOPTB(deaf, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, "permadeaf", &u.uroleplay.deaf, Term_False,
           "キャラクターを恒久的に耳が聞こえない状態にする")
#ifdef BACKWARD_COMPAT
    NHOPTC(DECgraphics, Advanced, 70, opt_in, set_in_config,
                Yes, Yes, No, No, NoAlias,
                "DECGraphics の表示シンボルを symset に読み込む")
#endif
    NHOPTB(debug_hunger, Advanced, 0, opt_in, set_wiznofuz,
           Off, Yes, No, No, NoAlias, &iflags.debug_hunger, Term_False,
           "空腹を無効にする")
    NHOPTB(debug_mongen, Advanced, 0, opt_in, set_wiznofuz,
           Off, Yes, No, No, NoAlias, &iflags.debug_mongen, Term_False,
           "ランダムモンスター生成を無効にする")
    NHOPTB(debug_overwrite_stairs, Advanced, 0, opt_in, set_wiznofuz,
                Off, Yes, No, No, NoAlias, &iflags.debug_overwrite_stairs,
           Term_False, "レベル生成で階段を上書きできるようにする")
    NHOPTC(disclose, Advanced, sizeof flags.end_disclose * 2,
                opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "ゲーム終了時に開示する情報の種類")
    NHOPTC(dogname, Advanced, PL_PSIZ, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "開始時のペットが小型犬の場合の名前")
    NHOPTB(dropped_nopick, Behavior, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.nopick_dropped, Term_False,
            "ドロップアイテムを自動的に拾わない")
    NHOPTB(dumplog, General, 0, opt_in, set_in_game, On, Yes, No, No, NoAlias, &iflags.dumplog, Term_False, "（Android専用）ダンプログを出力する")
    NHOPTC(dungeon, Advanced, MAXDCHARS + 1,opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "ダンジョンマップ描画に使用するシンボルのリスト")
    NHOPTC(effects, Advanced, MAXECHARS + 1, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "特殊効果描画に使用するシンボルのリスト")
    NHOPTB(eight_bit_tty, Advanced, 0, opt_in, set_in_game,
                Off, Yes, No, No, NoAlias, &iflags.wc_eight_bit_input,
           Term_False, "8 ビット文字を直接端末に送信する")
    NHOPTB(extmenu, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.extmenu, Term_False,
           "拡張コマンド取得にメニューを使用する")
    NHOPTB(female, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, "male", &flags.female, Term_False,
           "非推奨; gender:female を使用")
    NHOPTB(fireassist, Behavior, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.fireassist, Term_False,
           "発射コマンドを支援する")
    NHOPTB(fixinv, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.invlet_constant, Term_False,
           "インベントリアイテムはそのままの文字を保持する")
    NHOPTC(font_map, Advanced, 40, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "マップウィンドウに使用するフォント")
    NHOPTC(font_menu, Advanced, 40, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "メニューに使用するフォント")
    NHOPTC(font_message, Advanced, 40, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias,
                "メッセージウィンドウに使用するフォント")
    NHOPTC(font_size_map, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "マップフォントのサイズ")
    NHOPTC(font_size_menu, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "メニューフォントのサイズ")
    NHOPTC(font_size_message, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "メッセージフォントのサイズ")
    NHOPTC(font_size_status, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "ステータスフォントのサイズ")
    NHOPTC(font_size_text, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "テキストフォントのサイズ")
    NHOPTC(font_status, Advanced, 40, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "ステータスウィンドウに使用するフォント")
    NHOPTC(font_text, Advanced, 40, opt_in, set_gameview,
                Yes, Yes, Yes, No, NoAlias, "テキストウィンドウに使用するフォント")
    NHOPTB(force_invmenu, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.force_invmenu, Term_False,
           "インベントリアイテムの要求にメニューを表示する")
    NHOPTC(fruit, General, PL_FSIZ, opt_in, set_in_game,
                No, Yes, No, No, NoAlias, "あなたが好んで食べる果物の名前")
    NHOPTB(fullscreen, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.wc2_fullscreen, Term_False,
           "全画面表示の切り替え")
 /* NHOPTC(gender) -- 先頭へ移動済み */
    NHOPTC(glyph, Advanced, 40, opt_in, set_in_game,
                No, Yes, Yes, No, NoAlias,
                "グリフの表現を unicode 値と色に設定する")
    NHOPTB(goldX, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.goldX, Term_False,
           "金を不明または呪われていないものとして分類する")
    NHOPTB(guicolor, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.wc2_guicolor, Term_False,
           "UI に色を使用する")
    NHOPTB(help, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.help, Term_False,
           "whatis コマンド使用時にすべての利用可能な情報を表示する")
    NHOPTB(herecmd_menu, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.herecmd_menu, Term_False,
           "この場所で利用可能なコマンドを表示する")
#if 0
/* there is no optfn_hicolor() defined in options.c presently
   and that is required for NHOPTC */
#if defined(MAC68K)
    NHOPTC(hicolor, Advanced, 15, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "palette と同じだが並び順が逆")
#endif
#endif /* 0 */
    NHOPTB(hilite_pet, Map, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.wc_hilite_pet, Term_False,
           "ペットをハイライト表示する")
    NHOPTB(hilite_pile, Map, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.hilite_pile, Term_False,
           "アイテムの山をハイライト表示する")
#ifdef STATUS_HILITES
    NHOPTC(hilite_status, Advanced, 13, opt_out, set_in_game,
                Yes, Yes, Yes, No, NoAlias,
                "ステータスハイライトルール (複数回設定可能)")
#else
    NHOPTC(hilite_status, Advanced, 13, opt_out, set_in_config,
                Yes, Yes, Yes, No, NoAlias, "(利用不可)")
#endif
    NHOPTB(hitpointbar, Status, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.wc2_hitpointbar, Term_False,
           "ヒットポイントのためのカラー付きバーを表示する")
    NHOPTC(horsename, Advanced, PL_PSIZ, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "開始時のペットがポニーの場合の名前")
#ifdef BACKWARD_COMPAT
    NHOPTC(IBMgraphics, Advanced, 70, opt_in, set_in_config,
                Yes, Yes, No, No, NoAlias,
                "IBMGraphics の表示シンボルを symset に読み込む")
#endif
    NHOPTB(idlecheckpoint, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.idlecheckpoint, Term_Off,
           "入力が 10 秒間アイドル状態のときにチェックポイントファイルを更新する")
#ifndef MAC68K
    NHOPTB(ignintr, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.ignintr, Term_False,
           "割り込み信号を無視する")
#else
    NHOPTB(ignintr, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(implicit_uncursed, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.implicit_uncursed, Term_False,
           "アイテムの説明から「uncursed」を省略する")
#if 0   /* 廃止済み - OSX 以前の Mac */
    NHOPTB(large_font, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.obsolete,
           (char *)0)
#endif
    NHOPTB(legacy, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &flags.legacy, Term_False,
           "イントロダクションメッセージを表示する")
    NHOPTB(lit_corridor, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.lit_corridor, Term_False,
           "暗い廊下を視界内で照明されているかのように表示する")
    NHOPTB(lootabc, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.lootabc, Term_False,
           "略奪時に a/b/c ではなく o/i/c を使用する")
    NHOPTB(mail, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.biff, Term_False,
           "メールデーモンを有効にする")
    NHOPTC(map_mode, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, No, No, NoAlias, "Windows でのマップ表示モード")
    NHOPTB(mention_decor, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.mention_decor, Term_False,
           "興味深い特徴の上を歩いたときにフィードバックを与える")
    NHOPTB(mention_map, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &a11y.glyph_updates, Term_False,
           "興味深いマップ上の位置が変化したときにフィードバックを与える")
    NHOPTB(mention_walls, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.mention_walls, Term_False,
           "壁に沿って歩いたときにフィードバックを与える")
    NHOPTC(menu_deselect_all, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メニュー内のすべてのアイテムの選択を解除")
    NHOPTC(menu_deselect_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "このページのすべてのアイテムの選択を解除")
    NHOPTC(menu_first_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メニューの最初のページにジャンプ")
    NHOPTC(menu_headings, Advanced, 4, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias, "メニュー見出しの表示スタイル")
    NHOPTC(menu_invert_all, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メニュー内のすべてのアイテムを反転")
    NHOPTC(menu_invert_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "このページのすべてのアイテムを反転")
    NHOPTC(menu_last_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メニューの最後のページにジャンプ")
    NHOPTC(menu_next_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "次のメニューページに移動")
    NHOPTC(menu_objsyms, Advanced, 12, opt_in, set_in_game,
           Yes, Yes, No, Yes, "use_menu_glyphs",
           "メニューにオブジェクトシンボルを表示する")
#ifdef TTY_GRAPHICS
    NHOPTB(menu_overlay, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.menu_overlay, Term_False,
           "メニューをオーバーレイし、右揃えにする")
#else
    NHOPTB(menu_overlay, Advanced, 0, opt_in, set_in_config,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTC(menu_previous_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "前のメニューページに移動")
    NHOPTC(menu_search, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メニューアイテムを検索")
    NHOPTC(menu_select_all, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メニュー内のすべてのアイテムを選択")
    NHOPTC(menu_select_page, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "このページのすべてのアイテムを選択")
    NHOPTC(menu_shift_left, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "現在のメニューページを左にパン")
    NHOPTC(menu_shift_right, Advanced, 4, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "現在のメニューページを右にパン")
    NHOPTB(menu_tab_sep, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.menu_tab_sep, Term_False,
           "メニュー書式設定")
    NHOPTB(menucolors, Advanced, 0, opt_in, set_in_game,
           Off, Yes, Yes, No, NoAlias, &iflags.use_menu_color, Term_False,
           "メニューに色を使用する")
    NHOPTO("menu colors", Status, o_menu_colors, BUFSZ, opt_in, set_in_game,
                No, Yes, No, NoAlias, "メニューで使用する色を変更")
    NHOPTC(menuinvertmode, Advanced, 5, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "メニュー反転の実験的動作")
    NHOPTC(menustyle, Advanced, MENUTYPELEN, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "オブジェクト選択のためのユーザーインターフェース")
    NHOPTO("message types", Advanced, o_message_types, BUFSZ,
                opt_in, set_in_game,
                No, Yes, No, NoAlias, "メッセージタイプを編集する")
    NHOPTB(mon_movement, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &a11y.mon_movement, Term_False,
           "モンスターの移動を目撃したときにメッセージを表示")
    NHOPTB(monpolycontrol, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.mon_polycontrol, Term_False,
           "モンスターの変身を制御")
    NHOPTB(montelecontrol, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.mon_telecontrol, Term_False,
           "モンスターのテレポート先を制御")
    NHOPTC(monsters, Advanced, MAXMCLASSES, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "モンスターに使用するシンボルのリスト")
    NHOPTC(mouse_support, Advanced, 0, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "ゲームがマウスクリック情報を受け取る")
#if PREV_MSGS /* tty または curses */
    NHOPTC(msg_window, Advanced, 1, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "\"以前のメッセージ表示\" (^P) の挙動を制御する")
#else
    NHOPTC(msg_window, Advanced, 1, opt_in, set_in_config,
                Yes, Yes, No, Yes, NoAlias, "(適用不可)")
#endif
    NHOPTC(msghistory, Advanced, 5, opt_in, set_gameview,
                Yes, Yes, No, No, NoAlias,
                "保存するトップラインメッセージの数")
 /* NHOPTC(name) -- 先頭へ移動済み */
#ifdef NEWS
    NHOPTB(news, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.news, Term_False,
           "ゲーム開始時にニュースを表示する")
#else
    NHOPTB(news, Advanced, 0, opt_in, set_in_config,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(nudist, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &u.uroleplay.nudist, Term_False,
           "鎧なしでキャラクターを開始する")
    NHOPTB(null, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.null, Term_False,
           "ヌル文字を端末に送信できるようにする")
    NHOPTC(number_pad, General, 1, opt_in, set_in_game,
                No, Yes, No, Yes, NoAlias,
                "移動にナンバーパッドを使用する")
    NHOPTC(objects, Advanced, MAXOCLASSES, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "オブジェクトに使用するシンボルのリスト")
    NHOPTC(packorder, Advanced, MAXOCLASSES, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "バックパック内のアイテムの在庫順")
#ifdef CHANGE_COLOR
#ifndef MAC68K     /* not old Mac OS9 */
    NHOPTC(palette, Advanced, 15, opt_in, set_gameview,
                No, Yes, Yes, No, "hicolor",
                "パレット（パレット内の RGB 色を調整する（色/R-G-B））")
#else
    NHOPTC(palette, Advanced, 15, opt_in, set_in_game,
                No, Yes, Yes, No, "hicolor",
                "パレット（00c/880/-fff は青/黄/反転白）")
#endif
#endif
    /* paranoid_confirmation 導入前は 'prayconfirm' が独立したオプションでした */
    NHOPTC(paranoid_confirmation, Advanced, 28, opt_in, set_in_game,
                Yes, Yes, Yes, Yes, "prayconfirm",
                "特定の状況で追加確認を行う")
    NHOPTB(pauper, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &u.uroleplay.pauper, Term_False,
           "最初は何も持たない状態でキャラクターを開始")
    NHOPTB(perm_invent, Advanced, 0, opt_in, set_in_game,
                Off, Yes, No, No, NoAlias, &iflags.perm_invent, Term_Off,
                "永続的なインベントリウィンドウを表示")
    NHOPTC(perminv_mode, Advanced, 20, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "永続的なインベントリウィンドウに表示する内容")
    NHOPTC(petattr, Advanced, 88, opt_in, set_in_game, /* tty/curses のみ */
                No, Yes, No, Yes, NoAlias, "ペットをハイライトするための属性")
    /* 一部の役割では pettype は無視されます */
    NHOPTC(pettype, Advanced, 4, opt_in, set_gameview,
                Yes, Yes, No, No, "pet", "あなたの好きな初期ペットの種類")
    NHOPTC(pickup_burden, Advanced, 20, opt_in, set_in_game,
                No, Yes, No, Yes, NoAlias,
                "プロンプト前に拾い上げる最大負担")
    NHOPTB(pickup_stolen, Behavior, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.pickup_stolen, Term_False,
           "盗まれたアイテムを自動的に拾う")
    NHOPTB(pickup_thrown, Behavior, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.pickup_thrown, Term_False,
           "投げられたアイテムを自動的に拾う")
    NHOPTC(pickup_types, Behavior, MAXOCLASSES, opt_in, set_in_game,
                No, Yes, No, Yes, NoAlias,
                "自動的に拾うオブジェクトの種類")
    NHOPTC(pile_limit, Advanced, 24, opt_in, set_in_game,
                Yes, Yes, No, No, NoAlias,
                "\"ここに多くのオブジェクトがあります\" の閾値")
    NHOPTC(player_selection, Advanced, 12, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "ダイアログまたはプロンプトによるキャラクター選択")
 /* NHOPTC(playmode) -- 先頭へ移動済み */
    NHOPTB(popup_dialog, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.wc_popup_dialog, Term_False,
           (char *)0)
    NHOPTB(preload_tiles, Advanced, 0, opt_out, set_in_config, /* MSDOS のみ */
           On, Yes, No, No, NoAlias, &iflags.wc_preload_tiles, Term_False,
           (char *)0)
    NHOPTB(price_quotes, General, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.pricequotes, Term_False,
           "未識別オブジェクトの価格を表示する")
    NHOPTB(pushweapon, Behavior, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.pushweapon, Term_False,
           "前の武器を補助スロットに移動")
    NHOPTB(query_menu, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.query_menu, Term_False,
           "はい/いいえのクエリにメニューを使用する")
    NHOPTB(quick_farsight, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.quick_farsight, Term_False,
           "強制的にマップを見せられたときにマップブラウズをスキップ")
 /* NHOPTC(race) -- 先頭へ移動済み */
#ifdef MICRO
    NHOPTB(rawio, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.rawio, Term_False,
           "raw I/O を許可する")
#else
    NHOPTB(rawio, Advanced, 0, opt_in, set_in_config,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(reroll, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &u.uroleplay.reroll, Term_False,
           "初期アイテムとインベントリの再振り分けを許可")
    NHOPTB(rest_on_space, Advanced, 0, opt_in, set_in_game, Off,
           Yes, No, No, NoAlias, &flags.rest_on_space, Term_False,
           "スペースバーを rest コマンドにバインドする")
    NHOPTC(roguesymset, Advanced, 70, opt_in, set_in_game,
                No, Yes, No, Yes, NoAlias,
                "symbols ファイルから rogue 表示シンボル一式を読み込む")
 /* NHOPTC(role) -- 先頭へ移動済み */
    NHOPTC(runmode, Advanced, sizeof "teleport", opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "`running` または `travelling` 時の表示頻度")
    NHOPTB(safe_pet, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.safe_dog, Term_False,
           "ペットを攻撃するのを防ぐ")
    NHOPTB(safe_wait, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.safe_wait, Term_False,
           "敵の隣で待機するのを防ぐ")
    NHOPTB(sanity_check, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.sanity_check, Term_False,
           "データの整合性チェックを実行")
    NHOPTC(scores, Advanced, 32, opt_in, set_in_game,
                No, Yes, No, No, NoAlias,
                "スコアリストの表示部分")
    NHOPTC(scroll_amount, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, No, No, NoAlias,
                "スクロールマージンに達したときにマップをスクロールする量")
    NHOPTC(scroll_margin, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, No, No, NoAlias,
                "エッジからこの距離だけマップをスクロールする")
    NHOPTB(selectsaved, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &iflags.wc2_selectsaved, Term_False,
           (char *)0)
    NHOPTB(showdamage, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.showdamage, Term_False,
           "メッセージラインにヒーローの受けるダメージを表示する")
    NHOPTB(showexp, Status, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.showexp, Term_False,
           "ステータスラインに経験値を表示する")
    NHOPTB(showrace, Map, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.showrace, Term_False,
           "キャラクターを役割ではなく種族で表示する")
#ifdef SCORE_ON_BOTL
    NHOPTB(showscore, Status, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.showscore, Term_False,
           "ステータスラインに現在のスコアを表示")
#else
    NHOPTB(showscore, Status, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(showvers, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.showvers, Term_False,
           "ステータスラインにバージョン情報を表示")
    NHOPTB(silent, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.silent, Term_False,
           "端末ベルを使用しない")
    NHOPTB(softkeyboard, Advanced, 0, opt_in, set_in_config,
                Off, Yes, No, No, NoAlias, &iflags.wc2_softkeyboard,
           Term_False, (char *)0)
    NHOPTC(sortdiscoveries, Advanced, 0, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "発見したオブジェクトを表示する際の優先順")
    NHOPTC(sortloot, Advanced, 4, opt_in, set_in_game,
                No, Yes, No, Yes, NoAlias,
                "オブジェクト選択リストを説明でソートする")
    NHOPTB(sortpack, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.sortpack, Term_False,
           "インベントリアイテムをタイプ別にグループ化")
    NHOPTC(sortvanquished, Advanced, 0, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "撃破したモンスターを表示する際の優先順")
    NHOPTC(soundlib, Advanced, WINTYPELEN, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "使用するサウンドライブラリインターフェース (該当する場合)")
#ifdef SND_LIB_INTEGRATED
    NHOPTB(sounds, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.sounds, Term_Off,
           "統合サウンドエフェクトを使用")
#else
    NHOPTB(sounds, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.sounds, Term_Off,
           "サウンドを使用")
#endif
    NHOPTB(sparkle, Map, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.sparkle, Term_False,
           "魔法抵抗時にきらめくエフェクトを表示する")
    NHOPTB(spot_monsters, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &a11y.mon_notices, Term_False,
           "ヒーローがモンスターを発見したときにメッセージを表示")
    NHOPTB(splash_screen, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &iflags.wc_splash_screen, Term_False,
           (char *)0)
    NHOPTB(standout, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.standout, Term_False,
           "--more-- のためにスタンドアウトを使用")
    NHOPTB(status_updates, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &iflags.status_updates, Term_False,
           "ステータスラインを更新可能にする")
    NHOPTO("status condition fields", Status, o_status_cond, BUFSZ,
                opt_in, set_in_game,
                No, Yes, No, NoAlias, "ステータス条件ハイライトを変更")
#ifdef STATUS_HILITES
    NHOPTC(statushilites, Advanced, 20, opt_in, set_in_game,
                Yes, Yes, Yes, No, NoAlias,
                "0=ステータス強調なし、N=Nターン間強調表示")
    NHOPTO("status highlight rules", Status, o_status_hilites, BUFSZ,
                opt_in, set_in_game,
                No, Yes, No, NoAlias, "ステータス行の強調表示を変更する")
#else
    NHOPTC(statushilites, Advanced, 20, opt_in, set_in_config,
                Yes, Yes, Yes, No, NoAlias, "強調表示の制御")
#endif
    NHOPTC(statuslines, Status, 20, opt_in, set_in_game,
                No, Yes, No, No, NoAlias, "ステータス表示を2行または3行にする")
#ifdef WIN32CON
    NHOPTC(subkeyvalue, Advanced, 7, opt_in, set_in_config,
                No, Yes, Yes, No, NoAlias, "キーストローク値を上書きする")
#endif
    NHOPTC(suppress_alert, Advanced, 8, opt_in, set_in_game,
                No, Yes, Yes, No, NoAlias,
                "バージョン固有機能に関する警告を抑制する")
    NHOPTC(msw_msg_cols, Advanced, 6, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メッセージウィンドウの列数")
    NHOPTC(msw_msg_rows, Advanced, 6, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "メッセージウィンドウの行数")
    NHOPTC(msw_stat_cols, Advanced, 6, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "ステータスウィンドウの列数")
    NHOPTC(msw_stat_rows, Advanced, 6, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "ステータスウィンドウの行数")
    NHOPTC(symset, Map, 70, opt_in, set_in_game,
                No, Yes, No, Yes, NoAlias,
                "symbols ファイルから表示シンボル一式を読み込む")
    NHOPTC(term_cols, Advanced, 6, opt_in, set_in_config,
                No, Yes, No, No, "termcolumns", "列数")
    NHOPTC(term_rows, Advanced, 6, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "行数")
    NHOPTB(terrainstatus, Advanced, 0, opt_in, set_in_game,
                Off, Yes, No, No, NoAlias, &flags.terrainstatus, Term_False,
                "ヒーローの位置をステータスフィールドとして表示")
    NHOPTC(tile_file, Advanced, 70, opt_in, set_gameview,
                No, Yes, No, No, NoAlias, "タイルファイルの名前")
    NHOPTC(tile_height, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, No, No, NoAlias, "タイルの高さ")
    NHOPTC(tile_width, Advanced, 20, opt_in, set_gameview,
                Yes, Yes, No, No, NoAlias, "タイルの幅")
    NHOPTB(tiled_map, Advanced, 0, opt_in, set_in_game,
                tiled_map_Def, Yes, No, No, NoAlias, &iflags.wc_tiled_map,
           Term_False, (char *)0)
    NHOPTB(time, Status, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &flags.time, Term_False,
           "ステータスラインにゲームターンを表示")
#ifdef TIMED_DELAY
    NHOPTB(timed_delay, Map, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.nap, Term_False,
           "表示効果のために一時停止する際の遅延を使用")
#else
    NHOPTB(timed_delay, Map, 0, opt_in, set_in_config,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(tips, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.tips, Term_False,
           "ゲームプレイ中に役立つヒントを表示")
    NHOPTB(tombstone, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.tombstone, Term_False,
           "キャラクターが死亡したときに墓石を表示")
    NHOPTB(toptenwin, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.toptenwin, Term_False,
           "ウィンドウ内にトップスコアを表示")
    NHOPTC(traps, Advanced, MAXTCHARS + 1, opt_in, set_in_config,
                No, Yes, No, No, NoAlias,
                "トラップ描画に使用するシンボルのリスト")
    NHOPTB(travel, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.travelcmd, Term_False,
           "マウスクリックによる移動を有効にする")
#ifdef DEBUG
    NHOPTB(travel_debug, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.trav_debug, Term_False,
           (char *)0)
#else
    NHOPTB(travel_debug, Advanced, 0, opt_in, set_wizonly,
           Off, No, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTB(tutorial, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &flags.tutorial, Term_False,
           "チュートリアルを行うかどうかを尋ねる")
    NHOPTB(use_darkgray, Advanced, 0, opt_out, set_in_config,
           On, Yes, No, No, NoAlias, &iflags.wc2_darkgray, Term_False,
           "青の代わりに濃い黒色を使用")
    NHOPTB(use_inverse, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &iflags.wc_inverse, Term_False,
           "発見されたモンスターを反転表示する")
    NHOPTB(use_truecolor, Advanced, 0, opt_in, set_in_config,
                Off, Yes, No, No, "use_truecolour",
           &iflags.use_truecolor, Term_False,
           (char *)0)
    NHOPTC(vary_msgcount, Advanced, 20, opt_in, set_gameview,
                No, Yes, No, No, NoAlias, "同時により多くの古いメッセージを表示")
    NHOPTB(verbose, Advanced, 0, opt_out, set_in_game,
           On, Yes, No, No, NoAlias, &flags.verbose, Term_False,
           (char *)0)
    NHOPTC(versinfo, Advanced, 80, opt_out, set_in_game,
           No, Yes, No, Yes, NoAlias, "'showvers' 用の追加情報")
#ifdef MSDOS
    NHOPTC(video, Advanced, 20, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "画面更新方式")
#endif
#ifdef VIDEOSHADES
    NHOPTC(videocolors, Advanced, 40, opt_in, set_gameview,
                No, Yes, No, No, "videocolours",
                "内部画面ルーチン向けの色マッピング")
    NHOPTC(videoshades, Advanced, 32, opt_in, set_gameview,
                No, Yes, No, No, NoAlias,
                "黒/灰/白に割り当てる灰色階調")
#endif
#ifdef MSDOS
    NHOPTC(video_width, Advanced, 10, opt_in, set_gameview,
                No, Yes, No, No, NoAlias, "画面幅")
    NHOPTC(video_height, Advanced, 10, opt_in, set_gameview,
                No, Yes, No, No, NoAlias, "画面高さ")
#endif
#ifdef SND_SPEECH
    NHOPTB(voices, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.voices, Term_Off,
           (char *)0)
#else
    NHOPTB(voices, Advanced, 0, opt_in, set_gameview,
           Off, Yes, No, No, NoAlias, &iflags.voices, Term_Excluded,
           (char *)0)
#endif
#ifdef TTY_TILES_ESCCODES
    NHOPTB(vt_tiledata, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.vt_tiledata, Term_False,
           "出力に特別なエスケープコードを使用")
#else
    NHOPTB(vt_tiledata, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
#ifdef TTY_SOUND_ESCCODES
    NHOPTB(vt_sounddata, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, &iflags.vt_sounddata, Term_False,
           "出力にサウンドデータの特別なエスケープコードを使用")
#else
    NHOPTB(vt_sounddata, Advanced, 0, opt_in, set_in_config,
           Off, Yes, No, No, NoAlias, (boolean *) 0, Term_False,
           (char *)0)
#endif
    NHOPTC(warnings, Advanced, 10, opt_in, set_in_config,
                No, Yes, No, No, NoAlias, "警告表示に使う文字")
    NHOPTB(weaponstatus, Advanced, 0, opt_in, set_in_game,
                Off, Yes, No, No, NoAlias, &flags.weaponstatus, Term_False,
                "現在装備中の武器をステータス欄に表示")
    NHOPTC(whatis_coord, Advanced, 1, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "カーソル位置の自動記述時に座標を表示")
    NHOPTC(whatis_filter, Advanced, 1, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias,
                "次または前へのターゲティング時に座標位置をフィルタ")
    NHOPTB(whatis_menu, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.getloc_usemenu, Term_False,
           "マップ位置取得時にメニューを表示")
    NHOPTB(whatis_moveskip, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.getloc_moveskip, Term_False,
           "マップ位置取得時に同じグリフをスキップ")
    NHOPTC(windowborders, Advanced, 9, opt_in, set_in_game,
                Yes, Yes, No, Yes, NoAlias, "0（オフ）、1（オン）、2（自動）")
#ifdef WINCHAIN
    NHOPTC(windowchain, Advanced, WINTYPELEN, opt_in, set_in_sysconf,
                No, Yes, No, No, NoAlias, "使用するウィンドウプロセッサ")
#endif
    NHOPTC(windowcolors, Advanced, 80, opt_in, set_gameview,
                No, Yes, Yes, No, NoAlias,
                "ウィンドウの前景/背景色")
 /* NHOPTC(windowtype) -- 先頭へ移動済み */
    NHOPTB(wizmgender, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.wizmgender, Term_False,
           (char *)0)
    NHOPTB(wizweight, Advanced, 0, opt_in, set_wizonly,
           Off, Yes, No, No, NoAlias, &iflags.wizweight, Term_False,
           (char *)0)
    NHOPTB(wraptext, Advanced, 0, opt_in, set_in_game,
           Off, Yes, No, No, NoAlias, &iflags.wc2_wraptext, Term_False,
           (char *)0)

    /*
     * 接頭辞ベースのオプション
     */

    NHOPTP(cond_, Advanced, 0, opt_in, set_hidden,
                Yes, No, Yes, Yes, NoAlias, "接頭辞オプションの接頭辞")
    NHOPTP(font, Advanced, 0, opt_in, set_hidden,
                Yes, Yes, Yes, No, NoAlias, "フォントオプションの接頭辞")
#if defined(MICRO) && !defined(AMIGA)
    /* 古い NetHack.cnf ファイルとの互換性のために含める */
    NHOPTP(IBM_, Advanced, 0, opt_in, set_hidden,
                No, No, Yes, No, NoAlias, "古い micro IBM_ オプション用の接頭辞")
#endif /* MICRO */

#undef NoAlias
#undef NHOPTB
#undef NHOPTC
#undef NHOPTP
#undef NHOPTO

/* *INDENT-ON* */
/* clang-format on */
#endif /* NHOPT_PROTO || NHOPT_ENUM || NHOPT_PARSE */

/*optlist.h*/

