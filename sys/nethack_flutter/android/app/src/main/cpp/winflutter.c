#include "hack.h"
#include <unistd.h>
#include <pthread.h>
#include <android/log.h>

#define LOG_TAG "NetHackFlutter"
#define debuglog(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Dart側への通知用コールバック関数の型
typedef void (*DartPrintCallback)(const char* msg);
typedef void (*DartNotifyInputCallback)(int requestId);

static DartPrintCallback g_dart_print_cb = NULL;
static DartNotifyInputCallback g_dart_notify_input_cb = NULL;

// 双方向通信用変数
static volatile int g_input_request_id = 0;
static volatile int g_last_received_key = 0;
static volatile int g_key_available = 0;

// ハイジャック前の元のプロシージャを退避（必要であれば）
static struct window_procs orig_procs;

// FFI からコールバックを登録する関数
void RegisterFlutterCallbacks(DartPrintCallback print_cb, DartNotifyInputCallback input_cb) {
    g_dart_print_cb = print_cb;
    g_dart_notify_input_cb = input_cb;
    debuglog("Flutter callbacks registered.");
}

// Dart 側からキー入力を受け取る関数
void SendKeyToFlutter(int key) {
    g_last_received_key = key;
    g_key_available = 1;
    debuglog("C core received key: %d", key);
}

// カウンタ取得関数
int GetFlutterInputRequestId(void) {
    return g_input_request_id;
}

// ----------------------------------------------------
// ハイジャック用のスタブコールバック群
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

static winid flutter_create_nhwindow(int type) {
    debuglog("flutter_create_nhwindow type=%d", type);
    return 1; // ダミーのウィンドウID
}

static void flutter_clear_nhwindow(winid window) {
    debuglog("flutter_clear_nhwindow win=%d", window);
}

static void flutter_display_nhwindow(winid window, boolean blocking) {
    debuglog("flutter_display_nhwindow win=%d, block=%d", window, blocking);
}

static void flutter_destroy_nhwindow(winid window) {
    debuglog("flutter_destroy_nhwindow win=%d", window);
}

static void flutter_curs(winid window, int x, int y) {
    // カーソル位置移動
}

static void flutter_putstr(winid window, int attr, const char* str) {
    debuglog("flutter_putstr [%d]: %s", window, str);
    if (g_dart_print_cb && str) {
        g_dart_print_cb(str);
    }
}

static void flutter_raw_print(const char* str) {
    debuglog("flutter_raw_print: %s", str ? str : "NULL");
    if (g_dart_print_cb && str) {
        g_dart_print_cb(str);
    }
}

static void flutter_raw_print_bold(const char* str) {
    debuglog("flutter_raw_print_bold: %s", str ? str : "NULL");
    if (g_dart_print_cb && str) {
        g_dart_print_cb(str);
    }
}

// ユーザー入力待ち (キー取得)
static int flutter_nhgetch(void) {
    debuglog("flutter_nhgetch called. Waiting for key...");
    
    // カウンタを上げて Dart に入力待ちを通知
    g_input_request_id++;
    g_key_available = 0;

    if (g_dart_notify_input_cb) {
        g_dart_notify_input_cb(g_input_request_id);
    }

    // キーが来るまでスリープポーリング
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
    
    if (g_dart_print_cb && question) {
        g_dart_print_cb(question);
    }
    
    return (char)flutter_nhgetch();
}

static void flutter_getlin(const char* prompt, char* buf) {
    debuglog("flutter_getlin: %s", prompt);
    if (g_dart_print_cb && prompt) {
        g_dart_print_cb(prompt);
    }
    strcpy(buf, "a");
}

// windowprocs をハイジャックする関数
static void HijackWindowProcs(void) {
    debuglog("Hijacking windowprocs...");
    orig_procs = windowprocs; // 元のをバックアップ

    windowprocs.win_init_nhwindows = flutter_init_nhwindows;
    windowprocs.win_player_selection = flutter_player_selection;
    windowprocs.win_askname = flutter_askname;
    windowprocs.win_exit_nhwindows = flutter_exit_nhwindows;
    windowprocs.win_suspend_nhwindows = flutter_suspend_nhwindows;
    windowprocs.win_resume_nhwindows = flutter_resume_nhwindows;
    windowprocs.win_create_nhwindow = flutter_create_nhwindow;
    windowprocs.win_clear_nhwindow = flutter_clear_nhwindow;
    windowprocs.win_display_nhwindow = flutter_display_nhwindow;
    windowprocs.win_destroy_nhwindow = flutter_destroy_nhwindow;
    windowprocs.win_curs = flutter_curs;
    windowprocs.win_putstr = flutter_putstr;
    windowprocs.win_raw_print = flutter_raw_print;
    windowprocs.win_raw_print_bold = flutter_raw_print_bold;
    windowprocs.win_nhgetch = flutter_nhgetch;
    windowprocs.win_nh_poskey = flutter_nh_poskey;
    windowprocs.win_nhbell = flutter_nhbell;
    windowprocs.win_yn_function = flutter_yn_function;
    windowprocs.win_getlin = flutter_getlin;
    
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

    // windowprocs をハイジャック！
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
