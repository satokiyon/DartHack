/* NetHack 5.0	sys.h	$NHDT-Date: 1693083207 2023/08/26 20:53:27 $  $NHDT-Branch: keni-crashweb2 $:$NHDT-Revision: 1.41 $ */
/* Copyright (c) Kenneth Lorber, Kensington, Maryland, 2008. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef SYS_H
#define SYS_H

struct sysopt_s {
    char *support; /* ローカルサポート連絡先 */
    char *recover; /* recover の実行方法 - win port により上書きされる可能性あり */
    char *wizards; /* ユーザー名の空白区切り一覧 */
    char *fmtd_wizard_list; /* wizards の整形版; null または "one"
                               または "one or two" または "one, two, or three" など */
    char *explorers;  /* wizards と同様だが explore モード用 */
    char *shellers;   /* wizards と同様、! コマンド用 (-DSHELL); また ^Z */
    char *genericusers; /* ユーザー名入力を促すユーザー名 */
    char *debugfiles; /* debugpline を表示するファイル。'*' は全て。 */
    char *msghandler;
#ifdef DUMPLOG
    char *dumplogfile; /* ダンプファイルの保存先 */
#endif
    int env_dbgfl;    /*  1: debugfiles は getenv("DEBUGFILES") 由来
                       *     なので sysconf の DEBUGFILES で上書きしない;
                       *  0: getenv() はまだ試行されていない;
                       * -1: getenv() で DEBUGFILES の値が見つからなかった。
                       */
    int maxplayers;
    int seduce;
    int check_save_uid; /* セーブ復元時に UID を確認するか? */
    int check_plname; /* wizards/explorers/shellers 判定に plname を使う */
    int bones_pools;
    long livelog; /* livelog に記録する LL_foo イベント */

    /* 記録ファイル */
    int persmax;
    int pers_is_uid;
    int entrymax;
    int pointsmin;
    int tt_oname_maxrank;

    /* panic オプション */
    char *gdbpath;
    char *greppath;
    char *crashreporturl;
    int panictrace_gdb;
    int panictrace_libc;

    /* セーブおよび bones のフォーマット */
    int saveformat[2];    /* 主形式と一回限り変換 */
    int bonesformat[2];   /* 主形式と一回限り変換 */

    /* アクセシビリティオプションを有効化 */
    int accessibility;
#ifdef WIN32
    int portable_device_paths;  /* ポータブルデバイス向け nethack 設定 */
#endif

    /* nethack の対話型ヘルプメニュー */
    int hideusage;      /* 0: ヘルプメニューに「コマンドライン使用法」を含める;
                         * 1: 非表示にする */
};

extern struct sysopt_s sysopt;

#define SYSOPT_SEDUCE sysopt.seduce

#endif /* SYS_H */
