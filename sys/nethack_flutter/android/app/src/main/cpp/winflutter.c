#include "hack.h"
#include <unistd.h>
#include <pthread.h>
#include <android/log.h>

#define LOG_TAG "NetHackFlutter"
#define debuglog(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// 前方宣言
static int flutter_nhgetch(void);
extern int nhcolor_to_RGB(int c); // winandroid.c の関数を参照
extern struct window_procs and_procs; // winandroid.c で定義されている元の WindowPort 構造体

static const unsigned short cp437_to_unicode[256] = {
    0x00A0, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022, 0x25D8, 0x25CB, 0x25D9, 0x2660, 0x2661, 0x266A, 0x266B, 0x2609,
    0x25BA, 0x25C4, 0x2195, 0x203C, 0x00B6, 0x00A7, 0x25AC, 0x2607, 0x2191, 0x2193, 0x2192, 0x2190, 0x221F, 0x2194, 0x25B2, 0x25BC,
    0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027, 0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047, 0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
    0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
    0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
    0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x2206,
    0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7, 0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
    0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9, 0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A3, 0x0192,
    0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA, 0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
    0x2591, 0x2592, 0x2591, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556, 0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
    0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F, 0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
    0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B, 0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
    0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4, 0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x25A0, 0x002B,
    0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248, 0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0
};

// Dart側への中継用コールバック関数の型定義
typedef void (*DartCreateWindowCallback)(int winId, int type);
typedef void (*DartClearWindowCallback)(int winId);
typedef void (*DartDisplayWindowCallback)(int winId, int blocking);
typedef void (*DartDestroyWindowCallback)(int winId);
typedef void (*DartCursCallback)(int winId, int x, int y);
typedef void (*DartPutStrCallback)(int winId, int attr, const char* str);
typedef void (*DartPrintGlyphCallback)(int winId, int x, int y, int tile, int ch, int color, int special);
typedef void (*DartNotifyInputCallback)(int requestId);
typedef void (*DartStartMenuCallback)(int winId);
typedef void (*DartAddMenuCallback)(int winId, long ident, int accelerator, int groupacc, int attr, const char* str, int preselected, int color);
typedef void (*DartEndMenuCallback)(int winId, const char* prompt);
typedef void (*DartSelectMenuCallback)(int winId, int how);

static DartCreateWindowCallback g_create_window_cb = NULL;
static DartClearWindowCallback g_clear_window_cb = NULL;
static DartDisplayWindowCallback g_display_window_cb = NULL;
static DartDestroyWindowCallback g_destroy_window_cb = NULL;
static DartCursCallback g_curs_cb = NULL;
static DartPutStrCallback g_putstr_cb = NULL;
static DartPrintGlyphCallback g_print_glyph_cb = NULL;
static DartNotifyInputCallback g_dart_notify_input_cb = NULL;
static DartStartMenuCallback g_start_menu_cb = NULL;
static DartAddMenuCallback g_add_menu_cb = NULL;
static DartEndMenuCallback g_end_menu_cb = NULL;
static DartSelectMenuCallback g_select_menu_cb = NULL;

// 双方向通信用変数
static volatile int g_input_request_id = 0;
static volatile int g_last_received_key = 0;
static volatile int g_key_available = 0;
static volatile long g_selected_menu_item = -2; // -2: 未選択, -1: キャンセル

// FFI からコールバックを登録する関数
void RegisterFlutterCallbacks(
    DartCreateWindowCallback create_cb,
    DartClearWindowCallback clear_cb,
    DartDisplayWindowCallback display_cb,
    DartDestroyWindowCallback destroy_cb,
    DartCursCallback curs_cb,
    DartPutStrCallback putstr_cb,
    DartPrintGlyphCallback glyph_cb,
    DartNotifyInputCallback input_cb,
    DartStartMenuCallback start_menu_cb,
    DartAddMenuCallback add_menu_cb,
    DartEndMenuCallback end_menu_cb,
    DartSelectMenuCallback select_menu_cb
) {
    g_create_window_cb = create_cb;
    g_clear_window_cb = clear_cb;
    g_display_window_cb = display_cb;
    g_destroy_window_cb = destroy_cb;
    g_curs_cb = curs_cb;
    g_putstr_cb = putstr_cb;
    g_print_glyph_cb = glyph_cb;
    g_dart_notify_input_cb = input_cb;
    g_start_menu_cb = start_menu_cb;
    g_add_menu_cb = add_menu_cb;
    g_end_menu_cb = end_menu_cb;
    g_select_menu_cb = select_menu_cb;
    debuglog("Flutter window and menu callbacks registered.");
}

// Dart 側からキー入力を受け取る関数
void SendKeyToFlutter(int key) {
    g_last_received_key = key;
    g_key_available = 1;
    debuglog("C core received key: %d", key);
}

// Dart 側からメニュー選択結果を受け取る関数
void SendMenuSelection(long ident) {
    g_selected_menu_item = ident;
    debuglog("C core received menu selection: %ld", ident);
}

// カウンタ取得関数
int GetFlutterInputRequestId(void) {
    return g_input_request_id;
}

// ----------------------------------------------------
// ハイジャック用のスタブ・中継コールバック群
// ----------------------------------------------------

static void flutter_init_nhwindows(int* argc, char** argv) {
    debuglog("flutter_init_nhwindows called");
}

static void flutter_player_selection(void) {
    debuglog("flutter_player_selection called");
    flags.initrole = 0; // デフォルトの職業 (Archaeologist 等)
    flags.initrace = 0; // デフォルトの種族
    flags.initgend = 0; // デフォルトの性別
    flags.initalign = 0; // デフォルトのアライメント
}

static void flutter_askname(void) {
    debuglog("flutter_askname called");
    strncpy(svp.plname, "Player", sizeof(svp.plname) - 1);
}

static void flutter_exit_nhwindows(const char* str) {
    debuglog("flutter_exit_nhwindows: %s", str ? str : "NULL");
}

static void flutter_suspend_nhwindows(const char* str) {
    debuglog("flutter_suspend_nhwindows");
}

static void flutter_resume_nhwindows(void) {
    debuglog("flutter_resume_nhwindows");
}

static int g_next_win_id = 10; // 特殊ウィンドウIDと重複しないように10から開始

static winid flutter_create_nhwindow(int type) {
    debuglog("flutter_create_nhwindow type=%d", type);
    int winId = g_next_win_id++;
    if (g_create_window_cb) {
        g_create_window_cb(winId, type);
    }
    return (winid)winId;
}

static void flutter_clear_nhwindow(winid window) {
    debuglog("flutter_clear_nhwindow win=%d", window);
    if (g_clear_window_cb) {
        g_clear_window_cb((int)window);
    }
}

static void flutter_display_nhwindow(winid window, boolean blocking) {
    debuglog("flutter_display_nhwindow win=%d, block=%d", window, blocking);
    if (g_display_window_cb) {
        g_display_window_cb((int)window, blocking ? 1 : 0);
    }
    if (blocking) {
        flutter_nhgetch();
    }
}

static void flutter_destroy_nhwindow(winid window) {
    debuglog("flutter_destroy_nhwindow win=%d", window);
    if (g_destroy_window_cb) {
        g_destroy_window_cb((int)window);
    }
}

static void flutter_curs(winid window, int x, int y) {
    if (g_curs_cb) {
        g_curs_cb((int)window, x, y);
    }
}

static void flutter_putstr(winid window, int attr, const char* str) {
    debuglog("flutter_putstr [%d]: %s", window, str);
    if (g_putstr_cb && str) {
        g_putstr_cb((int)window, attr, str);
    }
}

static void flutter_raw_print(const char* str) {
    debuglog("flutter_raw_print: %s", str ? str : "NULL");
    if (g_putstr_cb && str) {
        g_putstr_cb(WIN_MESSAGE, ATR_NONE, str);
    }
}

static void flutter_raw_print_bold(const char* str) {
    debuglog("flutter_raw_print_bold: %s", str ? str : "NULL");
    if (g_putstr_cb && str) {
        g_putstr_cb(WIN_MESSAGE, ATR_BOLD, str);
    }
}

// ユーザー入力待ち (キー取得)
static int flutter_nhgetch(void) {
    debuglog("flutter_nhgetch called. Waiting for key...");
    
    g_input_request_id++;
    g_key_available = 0;

    if (g_dart_notify_input_cb) {
        g_dart_notify_input_cb(g_input_request_id);
    }

    while (!g_key_available) {
        usleep(10000); // 10ms
    }

    debuglog("flutter_nhgetch returning key: %d", g_last_received_key);
    return g_last_received_key;
}

static int flutter_nh_poskey(coordxy* x, coordxy* y, int* event) {
    return flutter_nhgetch();
}

static void flutter_nhbell(void) {
    debuglog("flutter_nhbell");
}

static char flutter_yn_function(const char* question, const char* choices, char def) {
    debuglog("flutter_yn_function: %s (%s) def=%c", question, choices, def);
    
    if (g_putstr_cb && question) {
        g_putstr_cb(WIN_MESSAGE, ATR_NONE, question);
    }
    
    return (char)flutter_nhgetch();
}

static void flutter_getlin(const char* prompt, char* buf) {
    debuglog("flutter_getlin: %s", prompt);
    if (g_putstr_cb && prompt) {
        g_putstr_cb(WIN_MESSAGE, ATR_NONE, prompt);
    }
    strcpy(buf, "a");
}

static void flutter_print_glyph(winid wid, coordxy x, coordxy y, const glyph_info* glyphinfo, const glyph_info* bkglyphinfo) {
    (void)bkglyphinfo;
    int tile = glyphinfo->gm.tileidx;
    unsigned int special = glyphinfo->gm.glyphflags;
    int color = nhcolor_to_RGB(glyphinfo->gm.sym.color);

    int ch = glyphinfo->ttychar;
    if (ch >= 0 && ch < 256) {
        ch = cp437_to_unicode[ch];
    }

    if (g_print_glyph_cb) {
        g_print_glyph_cb((int)wid, (int)x, (int)y, tile, ch, color, (int)special);
    }
}

// ----------------------------------------------------
// メニューウィンドウ用のハイジャック関数群
// ----------------------------------------------------

static void flutter_start_menu(winid wid, unsigned long behavior) {
    debuglog("flutter_start_menu win=%d", wid);
    if (g_start_menu_cb) {
        g_start_menu_cb((int)wid);
    }
}

static void flutter_add_menu(winid wid, const glyph_info *glyphinfo, const anything *ident, char accelerator, char groupacc, int attr, int color, const char *str, unsigned int itemflags) {
    debuglog("flutter_add_menu win=%d, acc=%c, str=%s", wid, accelerator, str);
    int tile = (glyphinfo == &nul_glyphinfo) ? -1 : glyphinfo->gm.tileidx;
    
    if (g_add_menu_cb && str) {
        g_add_menu_cb(
            (int)wid,
            ident->a_long,
            (int)accelerator,
            (int)groupacc,
            attr,
            str,
            (itemflags & MENU_ITEMFLAGS_SELECTED) ? 1 : 0,
            color
        );
    }
}

static void flutter_end_menu(winid wid, const char *prompt) {
    debuglog("flutter_end_menu win=%d, prompt=%s", wid, prompt ? prompt : "");
    if (g_end_menu_cb) {
        g_end_menu_cb((int)wid, prompt ? prompt : "");
    }
}

static int flutter_select_menu(winid wid, int how, menu_item **selected) {
    debuglog("flutter_select_menu win=%d, how=%d", wid, how);
    
    g_selected_menu_item = -2; // 未選択状態

    // Dart 側に入力モードを「メニュー選択モード」にするよう通知
    if (g_select_menu_cb) {
        g_select_menu_cb((int)wid, how);
    }

    // カウンタを上げてキー入力可能にする
    g_input_request_id++;
    if (g_dart_notify_input_cb) {
        g_dart_notify_input_cb(g_input_request_id);
    }

    // ユーザーが選択を完了するかキャンセルするまで待機
    while (g_selected_menu_item == -2) {
        usleep(10000); // 10ms
    }

    if (g_selected_menu_item == -1) {
        *selected = NULL;
        return -1; // キャンセル / ABORT
    }

    // 選択された項目を格納して返す
    *selected = (menu_item*)alloc(sizeof(menu_item));
    (*selected)[0].item = cg.zeroany;
    (*selected)[0].item.a_long = g_selected_menu_item;
    (*selected)[0].count = 1;

    return 1; // 1個選択された
}

// windowprocs と and_procs を同時にハイジャックする関数
static void HijackWindowProcs(void) {
    debuglog("Hijacking and_procs...");

    and_procs.win_init_nhwindows = flutter_init_nhwindows;
    and_procs.win_player_selection = flutter_player_selection;
    and_procs.win_askname = flutter_askname;
    and_procs.win_exit_nhwindows = flutter_exit_nhwindows;
    and_procs.win_suspend_nhwindows = flutter_suspend_nhwindows;
    and_procs.win_resume_nhwindows = flutter_resume_nhwindows;
    and_procs.win_create_nhwindow = flutter_create_nhwindow;
    and_procs.win_clear_nhwindow = flutter_clear_nhwindow;
    and_procs.win_display_nhwindow = flutter_display_nhwindow;
    and_procs.win_destroy_nhwindow = flutter_destroy_nhwindow;
    and_procs.win_curs = flutter_curs;
    and_procs.win_putstr = flutter_putstr;
    and_procs.win_raw_print = flutter_raw_print;
    and_procs.win_raw_print_bold = flutter_raw_print_bold;
    and_procs.win_nhgetch = flutter_nhgetch;
    and_procs.win_nh_poskey = flutter_nh_poskey;
    and_procs.win_nhbell = flutter_nhbell;
    and_procs.win_yn_function = flutter_yn_function;
    and_procs.win_getlin = flutter_getlin;
    and_procs.win_print_glyph = flutter_print_glyph;

    // メニュー用の関数ポインタも完全にハイジャック！
    and_procs.win_start_menu = flutter_start_menu;
    and_procs.win_add_menu = flutter_add_menu;
    and_procs.win_end_menu = flutter_end_menu;
    and_procs.win_select_menu = flutter_select_menu;

    windowprocs = and_procs;
    
    debuglog("Hijack completed.");
}

// ----------------------------------------------------
// スレッド起動関数
// ----------------------------------------------------

struct StartArgs {
    char path[512];
    char username[256];
};

static void* NetHackThreadFunc(void* arg) {
    struct StartArgs* args = (struct StartArgs*)arg;
    debuglog("NetHack Thread started. Chdir to: %s", args->path);

    if (chdir(args->path) != 0) {
        debuglog("chdir failed in thread!");
    }

    HijackWindowProcs();

    char* params[2];
    params[0] = "nethack";
    params[1] = NULL;

    debuglog("Calling NetHackMain...");
    extern int NetHackMain(int argc, char** argv);
    NetHackMain(1, params);

    debuglog("NetHackMain exited.");
    free(args);
    return NULL;
}

void StartNetHackFlutter(const char* path, const char* username) {
    debuglog("StartNetHackFlutter: path=%s, user=%s", path, username);

    struct StartArgs* args = malloc(sizeof(struct StartArgs));
    strncpy(args->path, path, sizeof(args->path) - 1);
    strncpy(args->username, username, sizeof(args->username) - 1);

    pthread_t thread;
    if (pthread_create(&thread, NULL, NetHackThreadFunc, args) != 0) {
        debuglog("Failed to create NetHack thread!");
        free(args);
    } else {
        pthread_detach(thread);
        debuglog("NetHack thread spawned successfully.");
    }
}
