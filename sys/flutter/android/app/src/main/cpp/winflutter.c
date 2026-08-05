#include "hack.h"
#include "func_tab.h"   /* for extended commands */
#include "dlb.h"
#include <unistd.h>
#include <pthread.h>
#include <stdarg.h>
#include <errno.h>
#include <android/log.h>

#define LOG_TAG "NetHackFlutter"

typedef void (*DartLogCallback)(const char* msg);
static DartLogCallback g_dart_log_cb = NULL;

__attribute__((visibility("default"))) void RegisterDartLogCallback(DartLogCallback cb) {
    g_dart_log_cb = cb;
}

#define NUM_LOG_BUFS 32
#define LOG_BUF_SIZE 2048

void debuglog(const char *fmt, ...) {
    static char log_bufs[NUM_LOG_BUFS][LOG_BUF_SIZE];
    static int log_buf_idx = 0;

    char* buf = log_bufs[log_buf_idx];
    log_buf_idx = (log_buf_idx + 1) % NUM_LOG_BUFS;

    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, LOG_BUF_SIZE, fmt, args);
    va_end(args);

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "%s", buf);
    if (g_dart_log_cb) {
        g_dart_log_cb(buf);
    }
}

// 前方宣言
static int flutter_nhgetch(void);
static void flutter_nhbell(void);
extern char *decode_mixed(char *, const char *); // src/windows.c の関数 (\GXXXXNNNN → showsym 1 文字)

static int palette[CLR_MAX] = {
	0xFF555555,	// CLR_BLACK
	0xFFFF0000,	// CLR_RED
	0xFF008800,	// CLR_GREEN
	0xFF664411, // CLR_BROWN
	0xFF0000FF,	// CLR_BLUE
	0xFFFF00FF,	// CLR_MAGENTA
	0xFF00FFFF,	// CLR_CYAN
	0xFF888888,	// CLR_GRAY
	0xFFFFFFFF,	// NO_COLOR
	0xFFFF9900,	// CLR_ORANGE
	0xFF00FF00,	// CLR_BRIGHT_GREEN
	0xFFFFFF00,	// CLR_YELLOW
	0xFF0088FF,	// CLR_BRIGHT_BLUE
	0xFFFF77FF,	// CLR_BRIGHT_MAGENTA
	0xFF77FFFF,	// CLR_BRIGHT_CYAN
	0xFFFFFFFF	// CLR_WHITE
};

int nhcolor_to_RGB(int c)
{
	if(c >= 0 && c < CLR_MAX)
		return palette[c];
	return 0xFF000000;
}

// NetHack Core 参照用の補完シンボル群（sys/android 非依存化用）
struct window_procs and_procs = {
    "and",
    (enum wp_ids) 0,
    WC_COLOR | WC_HILITE_PET | WC_INVERSE,
    WC2_HILITE_STATUS | WC2_FLUSH_STATUS | WC2_SUPPRESS_HIST,
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
};
/* DartHack: implement quit_possible as a proper function stub instead of an int variable */
void
quit_possible(void)
{
    return;
}

void and_get_dumplog_dir(char *buf) {
    if (buf) {
        Strcpy(buf, ".");
    }
}

void and_you_die(void) {
}

void lock_mouse_cursor(boolean lock UNUSED) {
}

void load_usersound(const char *filename UNUSED) {
}

struct sound_procs androidsound_procs = {
    "androidsound",
    soundlib_nosound,
    0L,
    (void (*)(void)) 0,
    (void (*)(const char *)) 0,
    (void (*)(schar, schar, int32_t)) 0,
    (void (*)(char *, int32_t, int32_t)) 0,
    (void (*)(int32_t, const char *, int32_t)) 0,
    (void (*)(char *, int32_t, int32_t)) 0,
    (void (*)(int32_t, int32_t, int32_t)) 0,
    (void (*)(char *, int32_t, int32_t, int32_t, int32_t)) 0,
};

static struct window_procs flutter_procs = {
    "flutter",
    (enum wp_ids) 0,
    WC_COLOR | WC_HILITE_PET | WC_INVERSE,
    WC2_HILITE_STATUS | WC2_FLUSH_STATUS | WC2_SUPPRESS_HIST,
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
};

struct window_procs tty_procs;

static winid flutter_create_nhwindow(int type);
static void flutter_start_menu(winid wid, unsigned long behavior);
static void flutter_add_menu(winid wid, const glyph_info *glyphinfo, const anything *ident, char accelerator, char groupacc, int attr, int color, const char *str, unsigned int itemflags);
static void flutter_end_menu(winid wid, const char *prompt);
static int flutter_select_menu(winid wid, int how, menu_item **selected);
static int flutter_get_ext_cmd(void);
static int flutter_do_ext_cmd_menu(boolean complete);
static void flutter_destroy_nhwindow(winid window);
static void flutter_display_file(const char *name, boolean complain);
static void flutter_putstr(winid window, int attr, const char* str);
void flutter_putmixed_with_tile(winid window, int attr, int tile, const char* str);
static void flutter_status_update(int idx, genericptr_t ptr, int chg, int percent, int color, unsigned long *colormasks);
static void flutter_exit_nhwindows(const char* str);
static int flutter_doprev_message(void);
static void flutter_number_pad(int state);
static void flutter_delay_output(void);
static char* flutter_getmsghistory(boolean init);
static void flutter_putmsghistory(const char *msg, boolean restoring);
static void flutter_save_message(const char* msg);
extern void genl_status_update(int idx, genericptr_t ptr, int chg, int percent, int color, unsigned long *colormasks);

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
typedef void (*DartDisplayWindowCallback)(int winId, int blocking, int isPlain);
typedef void (*DartDestroyWindowCallback)(int winId);
typedef void (*DartCursCallback)(int winId, int x, int y);
typedef void (*DartPutStrCallback)(int winId, int attr, const char* str);
typedef void (*DartPrintGlyphCallback)(int winId, int x, int y, int tile, int ch, int color, int special);
typedef void (*DartNotifyInputCallback)(int requestId);
typedef void (*DartStartMenuCallback)(int winId);
typedef void (*DartAddMenuCallback)(int winId, long ident, int accelerator, int groupacc, int attr, const char* str, int preselected, int color, int tile);
typedef void (*DartEndMenuCallback)(int winId, const char* prompt);
typedef void (*DartSelectMenuCallback)(int winId, int how);
typedef void (*DartYnFunctionCallback)(const char* question, const char* choices, int def);
typedef void (*DartGetLineCallback)(const char* prompt, const char* initText);
typedef void (*DartAskNameCallback)(const char* saves, int maxChars);
typedef void (*DartExitCallback)(const char* msg);
typedef void (*DartNumberPadModeCallback)(int state);
typedef void (*DartCliparoundCallback)(int x, int y, int playerX, int playerY);
typedef void (*DartPutMixedWithTileCallback)(int winId, int attr, int tile, const char* str);
typedef void (*DartNewLevelRestCallback)(void);

static DartNewLevelRestCallback g_new_level_rest_cb = NULL;

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
static DartYnFunctionCallback g_yn_function_cb = NULL;
static DartGetLineCallback g_getline_cb = NULL;
static DartAskNameCallback g_askname_cb = NULL;
static DartExitCallback g_exit_cb = NULL;
static DartNumberPadModeCallback g_number_pad_mode_cb = NULL;
static DartCliparoundCallback g_cliparound_cb = NULL;
static DartPutMixedWithTileCallback g_putmixed_cb = NULL;
static int g_is_plain_text_dialog = 0;

void set_flutter_plain_text_dialog(int enable) {
    g_is_plain_text_dialog = enable;
    debuglog("set_flutter_plain_text_dialog: %d", enable);
}

// 同期待信用変数
static volatile char g_yn_result = 0;
static volatile int g_yn_done = 0;
static char g_getline_result[512] = {0};
static volatile int g_getline_done = 0;
static char g_askname_result[256] = {0};
static volatile int g_askname_done = 0;
static int g_askname_mode = 0;

void SendAskNameResultToC(const char* result, int mode) {
    g_askname_mode = mode;
    if (result) {
        strncpy(g_askname_result, result, sizeof(g_askname_result) - 1);
        g_askname_result[sizeof(g_askname_result) - 1] = '\0';
    } else {
        g_askname_result[0] = '\0';
    }
    g_askname_done = 1;
    debuglog("C core received AskName result: %s (mode: %d)", g_askname_result, mode);
}

// 双方向通信用変数
static volatile int g_input_request_id = 0;
static volatile int g_last_received_key = 0;
static volatile int g_key_available = 0;
static volatile long g_selected_menu_item = -2; // -2: 未選択, -1: キャンセル
static volatile int g_exit_notified = 0;

#define FLUTTER_MAX_SELECTED_MENU 512
#define FLUTTER_MAX_POSCMD 32

// PosCmd (座標クリック) キュー
typedef struct {
    int x;
    int y;
    int mod;
} PosCmdEntry;

static PosCmdEntry g_poscmd_queue[FLUTTER_MAX_POSCMD];
static volatile int g_poscmd_head = 0;
static volatile int g_poscmd_tail = 0;
static volatile int g_poscmd_count = 0;

#define FLUTTER_MAX_KEYS 64
static int g_key_queue[FLUTTER_MAX_KEYS];
static volatile int g_key_head = 0;
static volatile int g_key_tail = 0;
static volatile int g_key_count = 0;
static volatile int g_pending_extcmd_mode = 0;
static volatile int g_in_display_blocking = 0;
static volatile int g_in_input_prompt = 0;

// flutter_nhgetch 内で PosCmd を消費した時に、その情報を
// flutter_nh_poskey に橋渡しするためのグローバル変数。
// (nhgetch からは x,y,mod ポインタを返せないため、nh_poskey が
//  次の readchar サイクルでクリックイベントとして配送する。)
static volatile int g_pending_poscmd_x = 0;
static volatile int g_pending_poscmd_y = 0;
static volatile int g_pending_poscmd_mod = 1;
static volatile int g_pending_poscmd = 0;
static volatile int g_selected_menu_count = -2; // -2: 待機, -1: キャンセル, 0以上: 件数
static long g_selected_menu_items[FLUTTER_MAX_SELECTED_MENU] = {0};
static long g_selected_menu_counts[FLUTTER_MAX_SELECTED_MENU] = {0};

#define FLUTTER_MSG_HISTORY_MAX 64
static char* g_msg_history[FLUTTER_MSG_HISTORY_MAX] = {0};
static int g_msg_history_idx = 0;
static int g_msg_history_count = 0;
static int g_msg_history_iter = 0;

#define NUM_CONV_BUFS 256
#define CONV_BUF_SIZE 4096

// CP437混在文字列を完全に正しいUTF-8に変換するヘルパー関数 (静的リングバッファで非同期セーフ化)
static char* convert_cp437_to_utf8(const char* str) {
    if (!str) return NULL;

    static char bufs[NUM_CONV_BUFS][CONV_BUF_SIZE];
    static int buf_idx = 0;

    char* dst_buf = bufs[buf_idx];
    buf_idx = (buf_idx + 1) % NUM_CONV_BUFS;

    int len = strlen(str);
    if (len * 3 >= CONV_BUF_SIZE) {
        return (char*)str; // バッファサイズ超過時はフォールバック
    }

    const unsigned char *p = (const unsigned char *)str;
    const unsigned char *end = p + len;
    unsigned char *dst = (unsigned char*)dst_buf;

    while (p < end) {
        unsigned char c = *p;
        int char_len = 0;
        if (c < 0x80) {
            char_len = 1;
        } else if ((c & 0xE0) == 0xC0) {
            char_len = 2;
        } else if ((c & 0xF0) == 0xE0) {
            char_len = 3;
        } else if ((c & 0xF8) == 0xF0) {
            char_len = 4;
        }

        if (char_len > 1 && p + char_len > end) {
            // 文字列の末尾で不完全に切り捨てられた UTF-8 マルチバイト文字の断片。
            // 文字化けを防ぐために無視する。
            break;
        }

        if (char_len > 0 && p + char_len <= end) {
            int valid = 1;
            for (int i = 1; i < char_len; i++) {
                if ((p[i] & 0xC0) != 0x80) {
                    valid = 0;
                    break;
                }
            }
            if (valid) {
                memcpy(dst, p, char_len);
                dst += char_len;
                p += char_len;
                continue;
            }
            if (char_len > 1) {
                p++;
                continue;
            }
        }

        unsigned short unicode_val = cp437_to_unicode[c];
        int encoded_len = 0;
        unsigned char utf8_bytes[4];
        if (unicode_val < 0x80) {
            utf8_bytes[0] = (unsigned char)unicode_val;
            encoded_len = 1;
        } else if (unicode_val < 0x800) {
            utf8_bytes[0] = (unsigned char)(0xC0 | ((unicode_val >> 6) & 0x1F));
            utf8_bytes[1] = (unsigned char)(0x80 | (unicode_val & 0x3F));
            encoded_len = 2;
        } else {
            utf8_bytes[0] = (unsigned char)(0xE0 | ((unicode_val >> 12) & 0x0F));
            utf8_bytes[1] = (unsigned char)(0x80 | ((unicode_val >> 6) & 0x3F));
            utf8_bytes[2] = (unsigned char)(0x80 | (unicode_val & 0x3F));
            encoded_len = 3;
        }
        memcpy(dst, utf8_bytes, encoded_len);
        dst += encoded_len;
        p++;
    }

    *dst = '\0';
    return dst_buf;
}

typedef struct {
    DartCreateWindowCallback create_cb;
    DartClearWindowCallback clear_cb;
    DartDisplayWindowCallback display_cb;
    DartDestroyWindowCallback destroy_cb;
    DartCursCallback curs_cb;
    DartPutStrCallback putstr_cb;
    DartPrintGlyphCallback glyph_cb;
    DartNotifyInputCallback input_cb;
    DartStartMenuCallback start_menu_cb;
    DartAddMenuCallback add_menu_cb;
    DartEndMenuCallback end_menu_cb;
    DartSelectMenuCallback select_menu_cb;
    DartYnFunctionCallback yn_cb;
    DartGetLineCallback getline_cb;
    DartAskNameCallback askname_cb;
    DartExitCallback exit_cb;
    DartNumberPadModeCallback number_pad_cb;
    DartCliparoundCallback cliparound_cb;
    DartPutMixedWithTileCallback putmixed_cb;
    DartNewLevelRestCallback newlevel_rest_cb;
} FlutterCallbacksStruct;

void RegisterFlutterCallbacksStruct(const FlutterCallbacksStruct *cbs) {
    if (!cbs) return;
    g_create_window_cb = cbs->create_cb;
    g_clear_window_cb = cbs->clear_cb;
    g_display_window_cb = cbs->display_cb;
    g_destroy_window_cb = cbs->destroy_cb;
    g_curs_cb = cbs->curs_cb;
    g_putstr_cb = cbs->putstr_cb;
    g_print_glyph_cb = cbs->glyph_cb;
    g_dart_notify_input_cb = cbs->input_cb;
    g_start_menu_cb = cbs->start_menu_cb;
    g_add_menu_cb = cbs->add_menu_cb;
    g_end_menu_cb = cbs->end_menu_cb;
    g_select_menu_cb = cbs->select_menu_cb;
    g_yn_function_cb = cbs->yn_cb;
    g_getline_cb = cbs->getline_cb;
    g_askname_cb = cbs->askname_cb;
    g_exit_cb = cbs->exit_cb;
    g_number_pad_mode_cb = cbs->number_pad_cb;
    g_cliparound_cb = cbs->cliparound_cb;
    g_putmixed_cb = cbs->putmixed_cb;
    g_new_level_rest_cb = cbs->newlevel_rest_cb;
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "All Flutter callbacks registered successfully via struct!");
}

// 後方互換用
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
    DartSelectMenuCallback select_menu_cb,
    DartYnFunctionCallback yn_cb,
    DartGetLineCallback getline_cb,
    DartAskNameCallback askname_cb,
    DartExitCallback exit_cb,
    DartNumberPadModeCallback number_pad_cb,
    DartCliparoundCallback cliparound_cb,
    DartPutMixedWithTileCallback putmixed_cb
) {
    FlutterCallbacksStruct cbs;
    cbs.create_cb = create_cb;
    cbs.clear_cb = clear_cb;
    cbs.display_cb = display_cb;
    cbs.destroy_cb = destroy_cb;
    cbs.curs_cb = curs_cb;
    cbs.putstr_cb = putstr_cb;
    cbs.glyph_cb = glyph_cb;
    cbs.input_cb = input_cb;
    cbs.start_menu_cb = start_menu_cb;
    cbs.add_menu_cb = add_menu_cb;
    cbs.end_menu_cb = end_menu_cb;
    cbs.select_menu_cb = select_menu_cb;
    cbs.yn_cb = yn_cb;
    cbs.getline_cb = getline_cb;
    cbs.askname_cb = askname_cb;
    cbs.exit_cb = exit_cb;
    cbs.number_pad_cb = number_pad_cb;
    cbs.cliparound_cb = cliparound_cb;
    cbs.putmixed_cb = putmixed_cb;
    RegisterFlutterCallbacksStruct(&cbs);
}

// Dart 側から結果を受け取る関数
void SendYnResultToC(int result) {
    g_yn_result = (char)result;
    g_yn_done = 1;
    debuglog("C core received YN result: %d (%c)", result, g_yn_result);
}

void SendGetLineResultToC(const char* result) {
    if (result) {
        strncpy(g_getline_result, result, sizeof(g_getline_result) - 1);
        g_getline_result[sizeof(g_getline_result) - 1] = '\0';
    } else {
        g_getline_result[0] = '\0';
    }
    g_getline_done = 1;
    debuglog("C core received GetLine result: %s", g_getline_result);
}

// 新階層リワード用コールバックおよび関数
static volatile int g_new_level_rest_done = 0;
static volatile int g_new_level_rest_reward_amount = 0;

void RegisterNewLevelRestCallback(DartNewLevelRestCallback cb) {
    g_new_level_rest_cb = cb;
    debuglog("NewLevelRestCallback registered.");
}

void SendNewLevelRestResultToC(int reward_amount) {
    g_new_level_rest_reward_amount = reward_amount;
    g_new_level_rest_done = 1;
    debuglog("C core received NewLevelRest result: %d", reward_amount);
}

static void flutter_apply_ad_reward(int amount) {
    boolean is_hp = (rn2(2) == 0);
    if (is_hp) {
        healup(amount, 0, FALSE, FALSE);
        u.uconduct.rested_by_ad++;
        pline("広告を見て休息した！体力(HP)が回復した。");
    } else {
        u.uen += amount;
        if (u.uen > u.uenmax)
            u.uen = u.uenmax;
        disp.botl = TRUE;
        u.uconduct.rested_by_ad++;
        pline("広告を見て休息した！魔力(Pw)が回復した。");
    }
}

void flutter_check_new_level_rest(void) {
    if (!g_new_level_rest_cb) return;

    g_new_level_rest_done = 0;
    g_new_level_rest_reward_amount = 0;

    g_new_level_rest_cb();

    while (!g_new_level_rest_done) {
        usleep(10000); // 10ms ブロック待機
    }

    if (g_new_level_rest_reward_amount > 0) {
        flutter_apply_ad_reward(g_new_level_rest_reward_amount);
    }
}


static void flutter_save_message(const char* msg) {
    if (!msg || !*msg || !strcmp(msg, "Restoring save file...") || !strcmp(msg, "セーブファイルを復元中...")) {
        return;
    }

    if (g_msg_history[g_msg_history_idx]) {
        free(g_msg_history[g_msg_history_idx]);
        g_msg_history[g_msg_history_idx] = NULL;
    }

    g_msg_history[g_msg_history_idx] = strdup(msg);
    if (g_msg_history[g_msg_history_idx]) {
        g_msg_history_idx = (g_msg_history_idx + 1) % FLUTTER_MSG_HISTORY_MAX;
        if (g_msg_history_count < FLUTTER_MSG_HISTORY_MAX) {
            g_msg_history_count++;
        }
    }
}

static char* flutter_getmsghistory(boolean init) {
    if (g_msg_history_count <= 0) {
        return 0;
    }

    if (init) {
        g_msg_history_iter =
            (g_msg_history_idx - g_msg_history_count + FLUTTER_MSG_HISTORY_MAX)
            % FLUTTER_MSG_HISTORY_MAX;
        return g_msg_history[g_msg_history_iter];
    }

    g_msg_history_iter = (g_msg_history_iter + 1) % FLUTTER_MSG_HISTORY_MAX;
    if (g_msg_history_iter == g_msg_history_idx) {
        return 0;
    }

    return g_msg_history[g_msg_history_iter];
}

static void flutter_putmsghistory(const char *msg, boolean restoring) {
    if (!msg) {
        return;
    }

    if (!restoring) {
        flutter_putstr(WIN_MESSAGE, ATR_NONE, msg);
        flutter_save_message(msg);
    }
}

// 拡張コマンド一覧の取得
const char* GetExtCmdsFlutter(void) {
    static char buf[16384] = {0};
    size_t used = 0;
    int i;
    int first = 1;

    buf[0] = '\0';

    for(i = 0; extcmdlist[i].ef_txt; i++)
    {
        int flgs = extcmdlist[i].flags;
        if(flgs & (CMD_NOT_AVAILABLE | INTERNALCMD))
            continue;
        if((flgs & WIZMODECMD) && !wizard)
            continue;
        if(strcmp(extcmdlist[i].ef_txt, "#") == 0 || strcmp(extcmdlist[i].ef_txt, "?") == 0)
            continue;

        {
            const char* cmd = extcmdlist[i].ef_txt;
            const char* desc = (extcmdlist[i].ef_desc && *extcmdlist[i].ef_desc)
                               ? convert_cp437_to_utf8(extcmdlist[i].ef_desc)
                               : "";
            int n = snprintf(
                buf + used,
                sizeof(buf) - used,
                "%s%s\t%s",
                first ? "" : "\n",
                cmd,
                desc
            );

            if (n < 0 || (size_t) n >= (sizeof(buf) - used)) {
                break;
            }
            used += (size_t) n;
        }

        first = 0;
    }

    return buf;
}

// Dart 側からキー入力を受け取る関数
void SendKeyToFlutter(int key) {
    g_last_received_key = key;
    g_key_available = 1;
    debuglog("C core received key: %d", key);
}

void SendKeysToFlutter(const int* keys, int len) {
    if (!keys || len <= 0) return;

    if (program_state.input_state != commandInp && len > 1 && keys[0] == '#') {
        debuglog("SendKeysToFlutter: ignored extcmd '%c' (len=%d) during prompt (input_state=%d)",
                 keys[0], len, program_state.input_state);
        flutter_nhbell();
        return;
    }

    int enqueued = 0;
    for (int i = 0; i < len; i++) {
        if (g_key_count >= FLUTTER_MAX_KEYS) {
            debuglog("SendKeysToFlutter: queue full, dropping key=%d (i=%d, queued=%d)", keys[i], i, enqueued);
            return;
        }
        g_key_queue[g_key_tail] = keys[i];
        g_key_tail = (g_key_tail + 1) % FLUTTER_MAX_KEYS;
        g_key_count++;
        enqueued++;
    }
    debuglog("C core received %d keys via SendKeysToFlutter (total queued=%d)", enqueued, g_key_count);
}

void SendShortcutToFlutter(const int* keys, int len) {
    if (!keys || len <= 0) return;

    if (program_state.input_state != commandInp && len > 1 && keys[0] == '#') {
        debuglog("SendShortcutToFlutter: ignored extcmd shortcut '%c' (len=%d) during prompt (input_state=%d)",
                 keys[0], len, program_state.input_state);
        flutter_nhbell();
        return;
    }

    int enqueued = 0;
    for (int i = 0; i < len; i++) {
        if (g_key_count >= FLUTTER_MAX_KEYS) {
            debuglog("SendShortcutToFlutter: queue full, dropping key=%d (i=%d, queued=%d)", keys[i], i, enqueued);
            return;
        }
        g_key_queue[g_key_tail] = keys[i];
        g_key_tail = (g_key_tail + 1) % FLUTTER_MAX_KEYS;
        g_key_count++;
        enqueued++;
    }
    if (enqueued > 1 && keys[0] == '#') {
        g_pending_extcmd_mode = 1;
        debuglog("SendShortcutToFlutter: extcmd shortcut detected (len=%d, first='#'), set g_pending_extcmd_mode=1", enqueued);
    }
}

void SetExtMenuFlutter(int enable) {
    iflags.extmenu = enable;
    __sync_synchronize();
    debuglog("SetExtMenuFlutter: iflags.extmenu = %d", enable);
}

// Dart 側から PosCmd (座標クリック) を受け取る関数。
// マップタップ時の herecmdmenu/therecmdmenu 連動のために使用。
void SendPosCmdToFlutter(int x, int y, int mod) {
    if (g_poscmd_count >= FLUTTER_MAX_POSCMD) {
        debuglog("SendPosCmdToFlutter: queue full, dropping pos_cmd x=%d y=%d mod=%d", x, y, mod);
        return;
    }
    g_poscmd_queue[g_poscmd_tail].x = x;
    g_poscmd_queue[g_poscmd_tail].y = y;
    g_poscmd_queue[g_poscmd_tail].mod = mod;
    g_poscmd_tail = (g_poscmd_tail + 1) % FLUTTER_MAX_POSCMD;
    g_poscmd_count++;
    debuglog("C core received PosCmd: x=%d, y=%d, mod=%d (queued=%d)", x, y, mod, g_poscmd_count);
}

// Dart 側からメニュー選択結果を受け取る関数
void SendMenuSelection(long ident, long count) {
    g_selected_menu_item = ident;
    if (ident == -1) {
        g_selected_menu_count = -1;
    } else {
        g_selected_menu_items[0] = ident;
        g_selected_menu_counts[0] = count;
        g_selected_menu_count = 1;
    }
    debuglog("C core received menu selection: %ld (count=%ld)", ident, count);
}

void SendMenuSelectionsToC(const char* csv) {
    int count = 0;
    const char* p = csv;

    if (!csv) {
        g_selected_menu_count = -1;
        debuglog("C core received menu selections: CANCEL(null)");
        return;
    }

    while (*p && count < FLUTTER_MAX_SELECTED_MENU) {
        char* endptr;
        long v;

        while (*p == ',' || *p == ' ' || *p == '\t') {
            ++p;
        }
        if (!*p) {
            break;
        }

        v = strtoll(p, &endptr, 10);
        if (endptr == p) {
            while (*p && *p != ',') {
                ++p;
            }
            continue;
        }

        long count_val = 1;
        p = endptr;
        if (*p == ':') {
            ++p;
            count_val = strtol(p, &endptr, 10);
            p = endptr;
        }

        g_selected_menu_items[count] = v;
        g_selected_menu_counts[count] = count_val;
        count++;

        while (*p && *p != ',') {
            ++p;
        }
        if (*p == ',') {
            ++p;
        }
    }

    g_selected_menu_count = count;
    debuglog("C core received menu selections count=%d", count);
}

// カウンタ取得関数
int GetFlutterInputRequestId(void) {
    return g_input_request_id;
}

int GetIsGameOver(void) {
    return program_state.gameover ? 1 : 0;
}

// ----------------------------------------------------
// ハイジャック用のスタブ・中継コールバック群
// ----------------------------------------------------

static void flutter_init_nhwindows(int* argc, char** argv) {
    debuglog("flutter_init_nhwindows called");
    iflags.window_inited = TRUE;
    iflags.menu_tab_sep = TRUE;
}

static void flutter_player_selection(void) {
    debuglog("flutter_player_selection called");
    
    int i, result;
    char pick4u = 'n', thisch, lastch = 0;
    int state = 0;
    winid win;
    anything any;
    menu_item *selected = 0;

    /* prevent an unnecessary prompt */
    rigid_role_checks();

    while(flags.initalign < 0)
    {
        if(state < 2)
        {
            if(!state)
                flags.initrole = -1;
            flags.initrace = -1;
            state = 0;
        }
        else
            state &= 1;
        flags.initgend = -1;
        flags.initalign = -1;

        /* Select a role */
        result = 1;
        if(flags.initrole < 0)
        {
            /* Prompt for a role */
            win = flutter_create_nhwindow(NHW_MENU);
            flutter_start_menu(win, MENU_BEHAVE_STANDARD);
            any.a_void = 0; /* zero out all bits */
            any.a_int = randrole(TRUE)+1;
            flutter_add_menu(win, &nul_glyphinfo, &any, '*', 0, ATR_NONE, NO_COLOR, "ランダム", 0);
            for(i = 0; roles[i].name.m; i++)
            {
                if(ok_role(i, flags.initrace, flags.initgend, flags.initalign))
                {
                    any.a_int = i + 1; /* must be non-zero */
                    thisch = lowc(roles[i].name.m[0]);
                    if(thisch == lastch)
                        thisch = highc(thisch);
                    flutter_add_menu(win, &nul_glyphinfo, &any, thisch, 0, ATR_NONE, NO_COLOR, jp_role_name_for_display(i, flags.initgend >= 0 ? flags.initgend : (flags.female ? 1 : 0)), 0);
                    lastch = thisch;
                }
            }
            flutter_end_menu(win, "職業を選んでください");
            result = flutter_select_menu(win, PICK_ONE, &selected);
            flutter_destroy_nhwindow(win);

            if(result > 0)
                flags.initrole = selected[0].item.a_int - 1;
            free((genericptr_t)selected), selected = 0;
        }

        if(result <= 0)
        {
            clearlocks();
            flutter_exit_nhwindows("bye");
            exit(0);
        }

        /* Select a race, if necessary */
        if(flags.initrace < 0)
            flags.initrace = pick_race(flags.initrole, flags.initgend, flags.initalign, PICK_RIGID);

        result = 1;
        if(flags.initrace < 0)
        {
            win = flutter_create_nhwindow(NHW_MENU);
            flutter_start_menu(win, MENU_BEHAVE_STANDARD);
            any.a_void = 0; /* zero out all bits */
            any.a_int = randrace(flags.initrole)+1;
            flutter_add_menu(win, &nul_glyphinfo, &any, '*', 0, ATR_NONE, NO_COLOR, "ランダム", 0);
            for(i = 0; races[i].noun; i++)
                if(ok_race(flags.initrole, i, flags.initgend, flags.initalign))
                {
                    any.a_int = i + 1; /* must be non-zero */
                    thisch = lowc(races[i].noun[0]);
                    if(thisch == lastch)
                        thisch = highc(thisch);
                    flutter_add_menu(win, &nul_glyphinfo, &any, thisch, 0, ATR_NONE, NO_COLOR, jp_race_noun_for_display(i), 0);
                    lastch = thisch;
                }
            flutter_end_menu(win, "種族を選んでください");
            result = flutter_select_menu(win, PICK_ONE, &selected);
            flutter_destroy_nhwindow(win);

            if(result > 0)
                flags.initrace = selected[0].item.a_int - 1;
            free((genericptr_t)selected), selected = 0;
        }

        if(result <= 0)
        {
            state = 0;
            continue;
        }
        state = 2;

        /* Select a gender, if necessary */
        if(flags.initgend < 0)
            flags.initgend = pick_gend(flags.initrole, flags.initrace, flags.initalign, PICK_RIGID);

        result = 1;
        if(flags.initgend < 0)
        {
            win = flutter_create_nhwindow(NHW_MENU);
            flutter_start_menu(win, MENU_BEHAVE_STANDARD);
            any.a_void = 0; /* zero out all bits */
            any.a_int = randgend(flags.initrole, flags.initrace)+1;
            flutter_add_menu(win, &nul_glyphinfo, &any, '*', 0, ATR_NONE, NO_COLOR, "ランダム", 0);
            for(i = 0; i < ROLE_GENDERS; i++)
                if(ok_gend(flags.initrole, flags.initrace, i, flags.initalign))
                {
                    any.a_int = i + 1;
                    flutter_add_menu(win, &nul_glyphinfo, &any, "mf"[i], 0, ATR_NONE, NO_COLOR, i == 0 ? "男性" : "女性", 0);
                }
            flutter_end_menu(win, "性別を選んでください");
            result = flutter_select_menu(win, PICK_ONE, &selected);
            flutter_destroy_nhwindow(win);

            if(result > 0)
                flags.initgend = selected[0].item.a_int - 1;
            free((genericptr_t)selected), selected = 0;
        }

        if(result <= 0)
        {
            state = 1;
            continue;
        }
        state = 3;

        /* Select an alignment, if necessary */
        if(flags.initalign < 0)
            flags.initalign = pick_align(flags.initrole, flags.initrace, flags.initgend, PICK_RIGID);

        result = 1;
        if(flags.initalign < 0)
        {
            win = flutter_create_nhwindow(NHW_MENU);
            flutter_start_menu(win, MENU_BEHAVE_STANDARD);
            any.a_void = 0; /* zero out all bits */
            any.a_int = randalign(flags.initrole, flags.initrace)+1;
            flutter_add_menu(win, &nul_glyphinfo, &any, '*', 0, ATR_NONE, NO_COLOR, "ランダム", 0);
            for(i = 0; i < ROLE_ALIGNS; i++)
                if(ok_align(flags.initrole, flags.initrace, flags.initgend, i))
                {
                    any.a_int = i + 1;
                    flutter_add_menu(win, &nul_glyphinfo, &any, "lcn"[i], 0, ATR_NONE, NO_COLOR, i == 0 ? "秩序" : (i == 1 ? "中立" : "混沌"), 0);
                }
            flutter_end_menu(win, "属性（アライメント）を選んでください");
            result = flutter_select_menu(win, PICK_ONE, &selected);
            flutter_destroy_nhwindow(win);

            if(result > 0)
                flags.initalign = selected[0].item.a_int - 1;
            free((genericptr_t)selected), selected = 0;
        }

        if(result <= 0)
        {
            state = 2;
            continue;
        }
    }
}

extern char** get_saved_games(void);
extern void clearlocks(void);

static void flutter_askname(void) {
    debuglog("flutter_askname called: svp.plname='%s', g_askname_cb=%p", svp.plname, g_askname_cb);
    g_askname_result[0] = '\0';
    g_askname_done = 0;
    
    // セーブファイル一覧を取得してセミコロン区切りにする
    char** saves = get_saved_games();
    char saves_buf[4096] = {0};
    int idx = 0;
    while (saves && saves[idx]) {
        char* first_del = strchr(saves[idx], '-');
        if (first_del) *first_del = '\0';
        if (idx > 0) {
            strcat(saves_buf, ";");
        }
        strcat(saves_buf, saves[idx]);
        idx++;
    }
    
    if (g_askname_cb) {
        debuglog("flutter_askname calling g_askname_cb with saves='%s'", saves_buf);
        g_askname_cb(saves_buf, PL_NSIZ);
    } else {
        debuglog("flutter_askname: g_askname_cb is NULL! Fallback to Player");
        strncpy(svp.plname, "Player", sizeof(svp.plname) - 1);
        return;
    }
    
    while (!g_askname_done) {
        usleep(10000); // 10ms
    }
    
    debuglog("flutter_askname finished wait: result='%s', mode=%d", g_askname_result, g_askname_mode);
    
    if (g_askname_result[0] == '\033' || (unsigned char)g_askname_result[0] == 0x80 || g_askname_result[0] == '\0') {
        clearlocks();
        exit(0);
    }
    
    if (g_askname_mode == 1) {
        discover = TRUE;
        wizard = FALSE;
    } else if (g_askname_mode == 2) {
        wizard = TRUE;
        discover = FALSE;
        strncpy(svp.plname, "wizard", sizeof(svp.plname) - 1);
        svp.plname[sizeof(svp.plname) - 1] = '\0';
        set_playmode();
    } else {
        discover = FALSE;
        wizard = FALSE;
    }

    if (g_askname_mode != 2) {
        strncpy(svp.plname, g_askname_result, sizeof(svp.plname) - 1);
        svp.plname[sizeof(svp.plname) - 1] = '\0';
    }
}

static void flutter_exit_nhwindows(const char* str) {
    debuglog("flutter_exit_nhwindows: %s", str ? str : "NULL");
    iflags.window_inited = FALSE;
    if (g_exit_cb && !g_exit_notified) {
        g_exit_notified = 1;
        char* conv = str ? convert_cp437_to_utf8(str) : NULL;
        g_exit_cb(conv ? conv : (str ? str : ""));
    }
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
    /* Match Android Java port behavior: non-map/status/message windows
       must block until acknowledged, otherwise text/help windows can be
       destroyed immediately after display_nhwindow(FALSE). */
    if (window != WIN_MESSAGE && window != WIN_STATUS && window != WIN_MAP) {
        blocking = TRUE;
    }

    debuglog("flutter_display_nhwindow win=%d, block=%d", window, blocking);
    if (g_display_window_cb) {
        g_display_window_cb((int)window, blocking ? 1 : 0, g_is_plain_text_dialog);
    }
    if (blocking) {
        if (window != WIN_MAP && window != WIN_STATUS) {
            g_in_display_blocking = 1;
        }
        if (program_state.savefile_completed > 0 && window == WIN_MESSAGE) {
            debuglog("flutter_display_nhwindow: auto-bypassing nhgetch for save completed display");
            g_in_display_blocking = 0;
            return;
        }
        flutter_nhgetch();
        g_in_display_blocking = 0;
    }
}

static void flutter_destroy_nhwindow(winid window) {
    debuglog("flutter_destroy_nhwindow win=%d", window);
    if (g_destroy_window_cb) {
        g_destroy_window_cb((int)window);
    }
}

static void flutter_display_file(const char *name, boolean complain) {
    debuglog("flutter_display_file: %s, complain=%d", name ? name : "NULL", complain);

    dlb *f = (dlb *) 0;
    char buf[BUFSZ];
    char name_jp[512];
    char *cr;

    flutter_clear_nhwindow(WIN_MESSAGE);

    if (name && !strstr(name, "_jp") && (strlen(name) + 3 < sizeof name_jp)) {
        Strcpy(name_jp, name);
        Strcat(name_jp, "_jp");
        f = dlb_fopen(name_jp, "r");
    }
    if (!f && name) {
        f = dlb_fopen(name, "r");
    }

    if (f) {
        winid datawin = flutter_create_nhwindow(NHW_TEXT);
        boolean empty = TRUE;

        while (dlb_fgets(buf, BUFSZ, f)) {
            if ((cr = strchr(buf, '\n')) != NULL) {
                *cr = '\0';
            }
            if (strchr(buf, '\t') != NULL) {
                (void) tabexpand(buf);
            }
            empty = FALSE;
            flutter_putstr(datawin, ATR_NONE, buf);
        }
        (void) dlb_fclose(f);
        if (!empty) {
            flutter_display_nhwindow(datawin, TRUE);
        }
        flutter_destroy_nhwindow(datawin);
    } else if (complain) {
        flutter_putstr(WIN_MESSAGE, ATR_NONE, "ファイルを開けませんでした.");
    }
}

static void flutter_curs(winid window, int x, int y) {
    if (g_curs_cb) {
        g_curs_cb((int)window, x, y);
    }
}

// プレイヤー位置 (u.ux, u.uy) を Dart 側に通知する cliparound 実装。
// マップ上の主人公タップ検出 (#herecmdmenu 連動) のために必要。
static void flutter_cliparound(int x, int y) {
    if (g_cliparound_cb) {
        // (x, y) はフォーカス座標、続いてプレイヤー位置を渡す。
        // u.ux は 1-based (1..COLNO-1)、u.uy は 0-based (0..ROWNO-1)
        // (src/cmd.c の isok() 参照)。
        // マップグリッド座標系 (0-based for both) に合わせるため x は -1。
        g_cliparound_cb(x, y, (int) u.ux - 1, (int) u.uy);
    }
}

static char g_topten_capture_buf[32768];
static int g_is_topten_capturing = 0;

static void flutter_putstr(winid window, int attr, const char* str) {
    if (g_is_topten_capturing) {
        if (str) {
            char* conv = convert_cp437_to_utf8(str);
            const char* target = conv ? conv : str;
            if (strlen(g_topten_capture_buf) + strlen(target) + 2 < sizeof(g_topten_capture_buf)) {
                strcat(g_topten_capture_buf, target);
                strcat(g_topten_capture_buf, "\n");
            }
        }
        return;
    }
    debuglog("flutter_putstr [%d]: %s", window, str);
    if ((int) window == WIN_MESSAGE && str) {
        /* NetHackJP: ATR_NOHISTORY 付き putstr (farlook 説明など)
         * は C 側履歴 (^P 用) にも積まず Dart 側の topline にだけ
         * 表示する。 */
        if (!(attr & ATR_NOHISTORY)) {
            flutter_save_message(str);
        }
    }
    if (g_putstr_cb && str) {
        char* conv = convert_cp437_to_utf8(str);
        int final_attr = attr;
        if (g_in_input_prompt) {
            final_attr |= 0x8000;
        }
        g_putstr_cb((int)window, final_attr, conv ? conv : str);
    }
}

void flutter_putmixed_with_tile(winid window, int attr, int tile, const char* str) {
    debuglog("flutter_putmixed_with_tile [%d, attr=%d, tile=%d]: %s", window, attr, tile, str);
    if (!str) {
        return;
    }
    /* \GXXXXNNNN (encglyph() 由来) を showsym 1 文字 (CP437) に
     * デコードしてから UTF-8 変換する。 pager.c の outbuf には \G
     * 以外の特殊シーケンス (\033 ANSI 等) は含まれないため、
     * decode_mixed はそのまま使える。 */
    char decoded[BUFSZ];
    decode_mixed(decoded, str);
    if ((int) window == WIN_MESSAGE) {
        /* NetHackJP: ATR_NOHISTORY 付き putmixed も C 側履歴を skip。
         * 現在は farlook 説明 (pager.c:2288) と autodescribe
         * (getpos.c:652) が該当。 */
        if (!(attr & ATR_NOHISTORY)) {
            flutter_save_message(decoded);
        }
    }
    if (g_putmixed_cb) {
        char* conv = convert_cp437_to_utf8(decoded);
        int final_attr = attr;
        if (g_in_input_prompt) {
            final_attr |= 0x8000;
        }
        g_putmixed_cb((int)window, final_attr, tile, conv ? conv : decoded);
    }
}

static void flutter_raw_print(const char* str) {
    if (g_is_topten_capturing) {
        if (str) {
            char* conv = convert_cp437_to_utf8(str);
            const char* target = conv ? conv : str;
            if (strlen(g_topten_capture_buf) + strlen(target) + 2 < sizeof(g_topten_capture_buf)) {
                strcat(g_topten_capture_buf, target);
                strcat(g_topten_capture_buf, "\n");
            }
        }
        return;
    }
    debuglog("flutter_raw_print: %s", str ? str : "NULL");
    if (str) {
        flutter_save_message(str);
    }
    if (g_putstr_cb && str) {
        char* conv = convert_cp437_to_utf8(str);
        g_putstr_cb(WIN_MESSAGE, ATR_NONE, conv ? conv : str);
    }
}

static void flutter_raw_print_bold(const char* str) {
    if (g_is_topten_capturing) {
        if (str) {
            char* conv = convert_cp437_to_utf8(str);
            const char* target = conv ? conv : str;
            if (strlen(g_topten_capture_buf) + strlen(target) + 2 < sizeof(g_topten_capture_buf)) {
                strcat(g_topten_capture_buf, target);
                strcat(g_topten_capture_buf, "\n");
            }
        }
        return;
    }
    debuglog("flutter_raw_print_bold: %s", str ? str : "NULL");
    if (str) {
        flutter_save_message(str);
    }
    if (g_putstr_cb && str) {
        char* conv = convert_cp437_to_utf8(str);
        g_putstr_cb(WIN_MESSAGE, ATR_BOLD, conv ? conv : str);
    }
}

static int flutter_doprev_message(void) {
    winid wid;

    wid = flutter_create_nhwindow(NHW_MENU);
    if (!wid) {
        return 0;
    }

    set_flutter_plain_text_dialog(1);

    if (g_msg_history_count <= 0) {
        flutter_putstr(wid, ATR_NONE, "メッセージ履歴はまだありません.");
    } else {
        int start = (g_msg_history_idx - g_msg_history_count + FLUTTER_MSG_HISTORY_MAX)
                    % FLUTTER_MSG_HISTORY_MAX;
        flutter_putstr(wid, ATR_NONE, "メッセージ履歴:");
        flutter_putstr(wid, ATR_NONE, "");
        for (int i = 0; i < g_msg_history_count; i++) {
            int idx = (start + i) % FLUTTER_MSG_HISTORY_MAX;
            if (g_msg_history[idx] && *g_msg_history[idx]) {
                flutter_putstr(wid, ATR_NONE, g_msg_history[idx]);
            }
        }
    }

    flutter_display_nhwindow(wid, TRUE);
    set_flutter_plain_text_dialog(0);
    flutter_destroy_nhwindow(wid);
    return 0;
}

static void flutter_number_pad(int state) {
    debuglog("flutter_number_pad: state=%d", state);
    if (g_number_pad_mode_cb) {
        g_number_pad_mode_cb(state);
    }
}

static void flutter_delay_output(void) {
    usleep(50000);
}

// ユーザー入力待ち (キー取得)
static int flutter_nhgetch(void) {
    debuglog("flutter_nhgetch called. Waiting for key...");

    if (g_poscmd_count > 0) {
        PosCmdEntry cmd = g_poscmd_queue[g_poscmd_head];
        g_poscmd_head = (g_poscmd_head + 1) % FLUTTER_MAX_POSCMD;
        g_poscmd_count--;
        g_pending_poscmd_x = cmd.x;
        g_pending_poscmd_y = cmd.y;
        g_pending_poscmd_mod = cmd.mod;
        g_pending_poscmd = 1;
        g_key_available = 1;
        g_last_received_key = 0;
        debuglog("flutter_nhgetch: forwarded PosCmd to pending x=%d y=%d mod=%d (remaining=%d)",
                 cmd.x, cmd.y, cmd.mod, g_poscmd_count);
        return 0;
    }

    if (g_in_display_blocking) {
        while (g_key_count > 0) {
            int key = g_key_queue[g_key_head];
            if (key != 32 && key != 27 && key != 10 && key != 13) {
                g_key_head = (g_key_head + 1) % FLUTTER_MAX_KEYS;
                g_key_count--;
                debuglog("flutter_nhgetch: dropped key %d during display blocking", key);
            } else {
                break;
            }
        }
    }

    if (g_key_count > 0) {
        int key = g_key_queue[g_key_head];
        if (program_state.input_state != commandInp && (key == '#' || g_pending_extcmd_mode)) {
            debuglog("flutter_nhgetch: purging key queue due to extcmd key '%c' during prompt (input_state=%d, remaining=%d)",
                     key, program_state.input_state, g_key_count);
            g_key_head = 0;
            g_key_tail = 0;
            g_key_count = 0;
            g_pending_extcmd_mode = 0;
            flutter_nhbell();
        } else {
            g_key_head = (g_key_head + 1) % FLUTTER_MAX_KEYS;
            g_key_count--;
            g_key_available = 1;
            g_last_received_key = key;
            debuglog("flutter_nhgetch: dispatched from key queue: %d (remaining=%d)", key, g_key_count);
            return key;
        }
    }

    g_input_request_id++;
    g_key_available = 0;

    if (g_dart_notify_input_cb) {
        g_dart_notify_input_cb(g_input_request_id);
    }

    while (!g_key_available) {
        if (g_poscmd_count > 0) {
            PosCmdEntry cmd = g_poscmd_queue[g_poscmd_head];
            g_poscmd_head = (g_poscmd_head + 1) % FLUTTER_MAX_POSCMD;
            g_poscmd_count--;
            g_pending_poscmd_x = cmd.x;
            g_pending_poscmd_y = cmd.y;
            g_pending_poscmd_mod = cmd.mod;
            g_pending_poscmd = 1;
            g_key_available = 1;
            g_last_received_key = 0;
            debuglog("flutter_nhgetch: forwarded PosCmd from wait loop x=%d y=%d mod=%d (remaining=%d)",
                     cmd.x, cmd.y, cmd.mod, g_poscmd_count);
            return 0;
        }
        if (g_key_count > 0) {
            int key = g_key_queue[g_key_head];
            if (program_state.input_state != commandInp && (key == '#' || g_pending_extcmd_mode)) {
                debuglog("flutter_nhgetch (wait loop): purging key queue due to extcmd key '%c' during prompt (input_state=%d, remaining=%d)",
                         key, program_state.input_state, g_key_count);
                g_key_head = 0;
                g_key_tail = 0;
                g_key_count = 0;
                g_pending_extcmd_mode = 0;
                flutter_nhbell();
                g_input_request_id++;
                if (g_dart_notify_input_cb) {
                    g_dart_notify_input_cb(g_input_request_id);
                }
                continue;
            }
            if (g_in_display_blocking && key != 32 && key != 27 && key != 10 && key != 13) {
                g_key_head = (g_key_head + 1) % FLUTTER_MAX_KEYS;
                g_key_count--;
                debuglog("flutter_nhgetch (wait loop): dropped key %d during display blocking", key);
                // キーを破棄したため、Dart側に入力可能状態に戻すよう再通知する
                g_input_request_id++;
                if (g_dart_notify_input_cb) {
                    g_dart_notify_input_cb(g_input_request_id);
                }
                continue;
            }
            g_key_head = (g_key_head + 1) % FLUTTER_MAX_KEYS;
            g_key_count--;
            g_key_available = 1;
            g_last_received_key = key;
            if (key == 27) {
                g_poscmd_count = 0;
                g_poscmd_head = 0;
                g_poscmd_tail = 0;
                g_pending_poscmd = 0;
            }
            debuglog("flutter_nhgetch: dispatched from key queue in wait loop: %d (remaining=%d)", key, g_key_count);
            return key;
        }
        usleep(10000);
    }

    if (g_last_received_key == 27) {
        g_poscmd_count = 0;
        g_poscmd_head = 0;
        g_poscmd_tail = 0;
        g_pending_poscmd = 0;
    }
    debuglog("flutter_nhgetch returning key: %d", g_last_received_key);
    return g_last_received_key;
}

static int flutter_nh_poskey(coordxy* x, coordxy* y, int* event) {
    // まず PosCmd キューにエントリがあれば、それを優先的に消費する。
    if (g_poscmd_count > 0) {
        PosCmdEntry cmd = g_poscmd_queue[g_poscmd_head];
        g_poscmd_head = (g_poscmd_head + 1) % FLUTTER_MAX_POSCMD;
        g_poscmd_count--;
        *x = (coordxy) cmd.x;
        *y = (coordxy) cmd.y;
        *event = cmd.mod;
        debuglog("flutter_nh_poskey: dispatched PosCmd x=%d y=%d mod=%d (remaining=%d)",
                 cmd.x, cmd.y, cmd.mod, g_poscmd_count);
        return 0; // 0 = クリックイベント (readchar_core で click_to_cmd 経由)
    }
    // 既に nhgetch が PosCmd を消費して pending に積んでいるケース。
    // (readchar_core は nhgetch 戻り値 0 だけでは x/y/mod を取り出せない
    //  ため、次の readchar サイクル (= 次の nh_poskey 呼び出し) で復元する。)
    if (g_pending_poscmd) {
        g_pending_poscmd = 0;
        *x = (coordxy) g_pending_poscmd_x;
        *y = (coordxy) g_pending_poscmd_y;
        *event = g_pending_poscmd_mod;
        debuglog("flutter_nh_poskey: restored pending PosCmd x=%d y=%d mod=%d",
                 g_pending_poscmd_x, g_pending_poscmd_y, g_pending_poscmd_mod);
        return 0; // クリックイベント
    }
    int ret = flutter_nhgetch();
    if (ret == 0 && g_pending_poscmd) {
        g_pending_poscmd = 0;
        *x = (coordxy) g_pending_poscmd_x;
        *y = (coordxy) g_pending_poscmd_y;
        *event = g_pending_poscmd_mod;
        debuglog("flutter_nh_poskey: consumed PosCmd from nhgetch x=%d y=%d mod=%d",
                 g_pending_poscmd_x, g_pending_poscmd_y, g_pending_poscmd_mod);
    }
    return ret;
}

static void flutter_nhbell(void) {
    debuglog("flutter_nhbell");
}

static boolean flutter_is_direction_prompt(const char* question) {
    if (!question || !*question) {
        return FALSE;
    }

    if (strstr(question, "what direction")
        || strstr(question, "What direction")
        || strstr(question, "どの方向")) {
        return TRUE;
    }

    return FALSE;
}

static char flutter_yn_function(const char* question, const char* choices, char def) {
    debuglog("flutter_yn_function: %s (%s) def=%c", question, choices, def);

    if (flutter_is_direction_prompt(question)) {
        char message[BUFSZ];

        if (choices && *choices) {
            char choicebuf[QBUFSZ];
            intptr_t esc;

            strncpy(choicebuf, choices, sizeof(choicebuf) - 1);
            choicebuf[sizeof(choicebuf) - 1] = '\0';

            esc = (intptr_t) strchr(choicebuf, '\033');
            if (esc) {
                choicebuf[esc - (intptr_t) choicebuf] = '\0';
            }

            Snprintf(message, sizeof message, "%s [%s]", question, choicebuf);
            if (def) {
                Snprintf(eos(message), BUFSZ - strlen(message), "(%c) ", def);
            }
        } else {
            Snprintf(message, sizeof message, "%s ", question);
        }

        flutter_clear_nhwindow(WIN_MESSAGE);
        flutter_putstr(WIN_MESSAGE, ATR_BOLD, message);
        return (char) flutter_nhgetch();
    }
    
    g_yn_result = 0;
    g_yn_done = 0;
    
    if (g_yn_function_cb) {
        char* q_utf8 = convert_cp437_to_utf8(question);
        g_yn_function_cb(q_utf8 ? q_utf8 : question, choices, (int)def);
    } else {
        return def;
    }
    
    while (!g_yn_done) {
        usleep(10000); // 10ms
    }
    
    char res = g_yn_result;
    if (res == '\033') {
        if (choices && strchr(choices, 'q'))
            res = 'q';
        else if (choices && strchr(choices, 'n'))
            res = 'n';
        else
            res = def;
    }
    return res;
}

static void flutter_getlin(const char* prompt, char* buf) {
    debuglog("flutter_getlin: %s", prompt);
    
    g_getline_result[0] = '\0';
    g_getline_done = 0;
    
    if (g_getline_cb) {
        char* p_utf8 = convert_cp437_to_utf8(prompt);
        g_getline_cb(p_utf8 ? p_utf8 : prompt, buf);
    } else {
        strcpy(buf, "a");
        return;
    }
    
    while (!g_getline_done) {
        usleep(10000); // 10ms
    }
    
    strcpy(buf, g_getline_result);
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
        char* conv = convert_cp437_to_utf8(str);
        bool is_negative_a_int = ident && ((ident->a_ulong & 0xFFFFFFFF00000000ULL) == 0) && (((int)ident->a_int) < 0);
        long menu_ident = ident ? (is_negative_a_int ? (long)(int)ident->a_int : ident->a_long) : 0L;
        g_add_menu_cb(
            (int)wid,
            menu_ident,
            (int)accelerator,
            (int)groupacc,
            attr,
            conv ? conv : str,
            (itemflags & MENU_ITEMFLAGS_SELECTED) ? 1 : 0,
            color,
            tile
        );
    }
}

static void flutter_end_menu(winid wid, const char *prompt) {
    debuglog("flutter_end_menu win=%d, prompt=%s", wid, prompt ? prompt : "");
    if (g_end_menu_cb) {
        char* conv = prompt ? convert_cp437_to_utf8(prompt) : NULL;
        g_end_menu_cb((int)wid, conv ? conv : (prompt ? prompt : ""));
    }
}

static int flutter_select_menu(winid wid, int how, menu_item **selected) {
    debuglog("flutter_select_menu win=%d, how=%d", wid, how);
    
    g_selected_menu_item = -2; // 未選択状態
    g_selected_menu_count = -2;

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
    while (g_selected_menu_count == -2) {
        usleep(10000); // 10ms
    }

    if (g_selected_menu_count == -1) {
        *selected = NULL;
        return -1; // キャンセル / ABORT
    }

    if (g_selected_menu_count == 0) {
        *selected = NULL;
        return 0;
    }

    // 選択された項目を格納して返す
    *selected = (menu_item*)alloc(sizeof(menu_item) * g_selected_menu_count);
    for (int i = 0; i < g_selected_menu_count; ++i) {
        (*selected)[i].item = cg.zeroany;
        (*selected)[i].item.a_long = g_selected_menu_items[i];
        (*selected)[i].count = g_selected_menu_counts[i];
    }

    return g_selected_menu_count;
}

static const char* flutter_complete_ext_cmd(const char* base) {
    int i, icmd = -1;
    int baselen;

    if (!base) return 0;
    baselen = (int) strlen(base);
    if (baselen == 0) return 0;

    for (i = 0; extcmdlist[i].ef_txt != (char *)0; i++) {
        if (!strncmpi(base, extcmdlist[i].ef_txt, baselen)) {
            if (icmd == -1) {
                icmd = i;
            } else {
                return 0;
            }
        }
    }

    if (icmd >= 0) {
        return extcmdlist[icmd].ef_txt;
    }
    return 0;
}

static void flutter_get_ext_cmd_auto(const char* query, char* bufp) {
    int n = 0, nl = 0;
    const char* complete = 0;
    int c;
    const int maxc = COLNO >= BUFSZ ? BUFSZ - 1 : COLNO;
    char display[BUFSZ];
    char prompt[BUFSZ];

    g_in_input_prompt = 1;

    Snprintf(prompt, sizeof(prompt), "%s ", query);
    flutter_putstr(WIN_MESSAGE, ATR_NONE, prompt);
    bufp[0] = 0;

    for (;;) {
        c = flutter_nhgetch();
        if (c == EOF || c == '\n') {
            bufp[n] = 0;
            if (complete) {
                strcpy(bufp, complete);
            }
            flutter_save_message(bufp);
            break;
        }
        if (c == '\033') {
            bufp[0] = (char) c;
            bufp[1] = 0;
            break;
        }
        if (c == 0x7f) {
            if (n > 0) {
                bufp[--n] = 0;
            }
        } else if ((unsigned char) c >= ' ' && n < maxc) {
            bufp[n] = (char) c;
            bufp[++n] = 0;
        }
        complete = flutter_complete_ext_cmd(bufp);
        if (complete) {
            Snprintf(display, sizeof(display), "%s%s", bufp, complete + n);
            flutter_putstr(WIN_MESSAGE, ATR_NONE, display);
        } else {
            flutter_putstr(WIN_MESSAGE, ATR_NONE, bufp);
        }
        nl = complete ? (int) strlen(complete) : n;
    }
    clear_nhwindow(WIN_MESSAGE);
    g_in_input_prompt = 0;
}

static int do_ext_cmd_text_flutter(void) {
    int i;
    char buf[BUFSZ];

    flutter_get_ext_cmd_auto("#", buf);

    (void) mungspaces(buf);
    if (buf[0] == 0 || buf[0] == '\033') {
        return -1;
    }

    if (!gi.in_doagain) {
        int j;
        for (j = 0; buf[j]; j++) {
            cmdq_add_key(CQ_REPEAT, buf[j]);
        }
        cmdq_add_key(CQ_REPEAT, '\n');
    }

    for (i = 0; extcmdlist[i].ef_txt != (char *)0; i++) {
        if (!strcmpi(buf, extcmdlist[i].ef_txt)) break;
    }

    if (extcmdlist[i].ef_txt == (char *)0) {
        char err[BUFSZ];
        Snprintf(err, sizeof(err), "%s: unknown extended command.", buf);
        flutter_putstr(WIN_MESSAGE, ATR_NONE, err);
        i = -1;
    }

    return i;
}

static int flutter_do_ext_cmd_menu(boolean complete) {
    winid wid;
    int i, count, what, flgs;
    menu_item *selected = NULL;
    anything any = cg.zeroany;
    char accelerator = 'a';
    const char *ptr;
    long show_all_ident = -1;

    wid = flutter_create_nhwindow(NHW_MENU);
    flutter_start_menu(wid, MENU_BEHAVE_STANDARD);

    for (i = 0; (ptr = extcmdlist[i].ef_txt); i++) {
        flgs = extcmdlist[i].flags;
        if ((flgs & (CMD_NOT_AVAILABLE | INTERNALCMD)) != 0)
            continue;
        if ((flgs & WIZMODECMD) && !wizard)
            continue;
        if (strcmp(ptr, "#") == 0 || strcmp(ptr, "?") == 0)
            continue;
        if (!complete && !(flgs & AUTOCOMPLETE) && !(flgs & WIZMODECMD))
            continue;

        any.a_long = (long) (i + 1);

        {
            char buf[BUFSZ];
            if (extcmdlist[i].ef_desc && *extcmdlist[i].ef_desc) {
                Sprintf(buf, "#%s\t%s", ptr, extcmdlist[i].ef_desc);
            } else {
                Sprintf(buf, "#%s", ptr);
            }
            flutter_add_menu(wid, &nul_glyphinfo, &any, accelerator, 0,
                             ATR_NONE, NO_COLOR, buf, MENU_ITEMFLAGS_NONE);
        }

        if (accelerator == 'z')
            accelerator = 'A';
        else if (accelerator == 'Z')
            accelerator = '!';
        else
            accelerator++;
    }

    if (!complete) {
        show_all_ident = (long) (i + 1);
        any.a_long = show_all_ident;
        flutter_add_menu(wid, &nul_glyphinfo, &any, '*', 0, ATR_NONE,
                         NO_COLOR, "(すべて表示)", MENU_ITEMFLAGS_NONE);
    }

    flutter_end_menu(wid, "拡張コマンド");
    count = flutter_select_menu(wid, PICK_ONE, &selected);
    what = count > 0 ? (int) selected[0].item.a_long - 1 : -1;
    if (selected)
        free((genericptr_t) selected);
    flutter_destroy_nhwindow(wid);

    if (!complete && what == (int) show_all_ident - 1)
        return flutter_do_ext_cmd_menu(TRUE);
    return what;
}

static int flutter_get_ext_cmd(void) {
    debuglog("flutter_get_ext_cmd: g_pending_extcmd_mode = %d, iflags.extmenu = %d",
             g_pending_extcmd_mode, iflags.extmenu);
    if (g_pending_extcmd_mode) {
        g_pending_extcmd_mode = 0;
        return do_ext_cmd_text_flutter();
    }
    if (iflags.extmenu) {
        return flutter_do_ext_cmd_menu(FALSE);
    }
    return do_ext_cmd_text_flutter();
}

static void flutter_get_nh_event(void) {}
static void flutter_mark_synch(void) {}
static char g_last_config_error_msg[1024] = {0};

void set_flutter_config_error_msg(const char* msg) {
    if (msg) {
        strncpy(g_last_config_error_msg, msg, sizeof(g_last_config_error_msg) - 1);
        g_last_config_error_msg[sizeof(g_last_config_error_msg) - 1] = '\0';
    }
}

static void flutter_wait_synch(void) {
    debuglog("flutter_wait_synch called! opt_initial=%d, msg='%s'", go.opt_initial, g_last_config_error_msg);
    if (g_last_config_error_msg[0] != '\0') {
        debuglog("CONFIG_ERROR_ALERT:%s", g_last_config_error_msg);
        g_last_config_error_msg[0] = '\0';
    }
    if (go.opt_initial) {
        debuglog("flutter_wait_synch: early init phase, returning to allow progress.");
    }
}
static void flutter_update_inventory(int status UNUSED) {}
static win_request_info *flutter_ctrl_nhwindow(winid window UNUSED, int request UNUSED, win_request_info *wri UNUSED) {
    return (win_request_info *) 0;
}

extern void genl_putmixed(winid, int, const char *);
extern char genl_message_menu(char, int, const char *);
extern void genl_outrip(winid, int, time_t);
extern void genl_status_update(int, genericptr_t, int, int, int, unsigned long *);

// windowprocs を Flutter 用にセットアップする関数
static void HijackWindowProcs(void) {
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "HijackWindowProcs 1.1");

    flutter_procs.win_init_nhwindows = flutter_init_nhwindows;
    flutter_procs.win_player_selection = flutter_player_selection;
    flutter_procs.win_askname = flutter_askname;
    flutter_procs.win_get_nh_event = flutter_get_nh_event;
    flutter_procs.win_exit_nhwindows = flutter_exit_nhwindows;
    flutter_procs.win_suspend_nhwindows = flutter_suspend_nhwindows;
    flutter_procs.win_resume_nhwindows = flutter_resume_nhwindows;
    flutter_procs.win_create_nhwindow = flutter_create_nhwindow;
    flutter_procs.win_clear_nhwindow = flutter_clear_nhwindow;
    flutter_procs.win_display_nhwindow = flutter_display_nhwindow;
    flutter_procs.win_destroy_nhwindow = flutter_destroy_nhwindow;
    flutter_procs.win_curs = flutter_curs;
    flutter_procs.win_putstr = flutter_putstr;

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "HijackWindowProcs 1.2");

    flutter_procs.win_putmixed = genl_putmixed;
    flutter_procs.win_raw_print = flutter_raw_print;
    flutter_procs.win_raw_print_bold = flutter_raw_print_bold;
    flutter_procs.win_display_file = flutter_display_file;
    flutter_procs.win_nhgetch = flutter_nhgetch;
    flutter_procs.win_nh_poskey = flutter_nh_poskey;
    flutter_procs.win_nhbell = flutter_nhbell;
    flutter_procs.win_doprev_message = flutter_doprev_message;
    flutter_procs.win_yn_function = flutter_yn_function;
    flutter_procs.win_getlin = flutter_getlin;
    flutter_procs.win_get_ext_cmd = flutter_get_ext_cmd;
    flutter_procs.win_number_pad = flutter_number_pad;
    flutter_procs.win_delay_output = flutter_delay_output;
    flutter_procs.win_print_glyph = flutter_print_glyph;

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "HijackWindowProcs 1.3");

    // プレイヤー位置を Dart 側へ通知 (マップタップの #herecmdmenu 連動で使用)
    flutter_procs.win_cliparound = flutter_cliparound;

    // メニュー用の関数ポインタもセット！
    flutter_procs.win_start_menu = flutter_start_menu;
    flutter_procs.win_add_menu = flutter_add_menu;
    flutter_procs.win_end_menu = flutter_end_menu;
    flutter_procs.win_select_menu = flutter_select_menu;
    flutter_procs.win_message_menu = genl_message_menu;

    flutter_procs.win_mark_synch = flutter_mark_synch;
    flutter_procs.win_wait_synch = flutter_wait_synch;
    flutter_procs.win_outrip = genl_outrip;
    flutter_procs.win_preference_update = genl_preference_update;

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "HijackWindowProcs 1.4 (Status handlers)");

    // ステータス表示用のハンドラを Flutter 専用実装 (ハイライト対応) に設定
    flutter_procs.win_status_init = genl_status_init;
    flutter_procs.win_status_finish = genl_status_finish;
    flutter_procs.win_status_enablefield = genl_status_enablefield;
    flutter_procs.win_status_update = flutter_status_update;
    flutter_procs.win_getmsghistory = flutter_getmsghistory;
    flutter_procs.win_putmsghistory = flutter_putmsghistory;

    flutter_procs.win_can_suspend = genl_can_suspend_no;
    flutter_procs.win_update_inventory = flutter_update_inventory;
    flutter_procs.win_ctrl_nhwindow = flutter_ctrl_nhwindow;

    and_procs = flutter_procs;
    and_procs.name = "and";
    tty_procs = flutter_procs;
    tty_procs.name = "tty";
    windowprocs = flutter_procs;
    iflags.windowtype_locked = TRUE;
    
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "flutter_procs setup completed! windowtype_locked set to TRUE.");
}

// NetHackステータスハイライト用 static 変数とハンドラ実装
#define MAXBLSTATS 30
static char flutter_status_vals[MAXBLSTATS][256];
static int flutter_status_colors[MAXBLSTATS];
static unsigned long *flutter_cond_hilites = NULL;

extern void genl_status_init(void);
extern void genl_status_finish(void);
extern void genl_status_enablefield(int, const char *, const char *, boolean);

static void append_status_field(char* buf, int idx, int* is_first) {
    if (idx == BL_CONDITION) {
        long active_conds = 0;
        sscanf(flutter_status_vals[idx], "%ld", &active_conds);
        
        for (int i = 0; i < CONDITION_COUNT; i++) {
            unsigned long mask = conditions[i].mask;
            if (active_conds & mask) {
                strcat(buf, " ");
                int color = CLR_WHITE;
                if (flutter_cond_hilites) {
                    for (int c = 0; c < CLR_MAX; c++) {
                        if (flutter_cond_hilites[c] & mask) {
                            color = c;
                            break;
                        }
                    }
                }
                char markup[64];
                sprintf(markup, "\\C%08X%s\\c", color, conditions[i].text[1]);
                strcat(buf, markup);
            }
        }
    } else {
        const char* val = flutter_status_vals[idx];
        if (!val || !*val) return;
        
        if (*is_first && *val == ' ') {
            val++;
        } else if (idx == BL_LEVELDESC && !*is_first) {
            strcat(buf, " ");
        }
        
        while (*val == ' ') {
            strcat(buf, " ");
            val++;
        }
        
        if (!*val) return;
        
        int color = flutter_status_colors[idx] & 0xFF;
        if (color == NO_COLOR || color == CLR_WHITE) {
            strcat(buf, val);
        } else {
            char markup[512];
            sprintf(markup, "\\C%08X%s\\c", color, val);
            strcat(buf, markup);
        }
        *is_first = 0;
    }
}

static void flutter_status_flush(void) {
    char line1[1024] = "";
    char line2[1024] = "";
    int is_first = 1;
    
    static enum statusfields fieldorder_line1[] = {
        BL_TITLE, BL_STR, BL_DX, BL_CO, BL_IN, BL_WI, BL_CH, BL_ALIGN, BL_SCORE,
        BL_FLUSH
    };
    
    static enum statusfields fieldorder_line2[] = {
        BL_LEVELDESC, BL_GOLD, BL_HP, BL_HPMAX, BL_ENE, BL_ENEMAX, BL_AC, BL_XP,
        BL_EXP, BL_HD, BL_TIME, BL_HUNGER, BL_CAP, BL_CONDITION, BL_FLUSH
    };
    
    is_first = 1;
    for (int i = 0; fieldorder_line1[i] != BL_FLUSH; i++) {
        append_status_field(line1, fieldorder_line1[i], &is_first);
    }
    
    is_first = 1;
    for (int i = 0; fieldorder_line2[i] != BL_FLUSH; i++) {
        int idx = fieldorder_line2[i];
        if (idx == BL_HPMAX) {
            int color = flutter_status_colors[BL_HPMAX] & 0xFF;
            if (color == NO_COLOR) {
                flutter_status_colors[BL_HPMAX] = flutter_status_colors[BL_HP];
            }
        } else if (idx == BL_ENEMAX) {
            int color = flutter_status_colors[BL_ENEMAX] & 0xFF;
            if (color == NO_COLOR) {
                flutter_status_colors[BL_ENEMAX] = flutter_status_colors[BL_ENE];
            }
        }
        append_status_field(line2, idx, &is_first);
    }
    
    flutter_curs(2 /* WIN_STATUS */, 1, 0);
    flutter_putstr(2 /* WIN_STATUS */, 0, line1);
    
    flutter_curs(2 /* WIN_STATUS */, 1, 1);
    flutter_putstr(2 /* WIN_STATUS */, 0, line2);
}

static void flutter_status_update(int idx, genericptr_t ptr, int chg, int percent, int color, unsigned long *colormasks) {
    extern const char *status_fieldfmt[MAXBLSTATS];
    char *text = (char *) ptr;
    if (idx == BL_FLUSH) {
        flutter_status_flush();
    } else if (idx >= 0 && idx < MAXBLSTATS) {
        if (idx == BL_CONDITION) {
            long *condptr = (long *) ptr;
            long cond = condptr ? *condptr : 0L;
            flutter_cond_hilites = colormasks;
            sprintf(flutter_status_vals[idx], "%ld", cond);
            flutter_status_colors[idx] = color;
        } else if (idx == BL_GOLD && text && *text == '\\') {
            const char* fmt = status_fieldfmt[idx] ? status_fieldfmt[idx] : "$%s";
            sprintf(flutter_status_vals[idx], fmt, text + 10);
            flutter_status_colors[idx] = color;
        } else {
            const char* fmt = status_fieldfmt[idx] ? status_fieldfmt[idx] : "%s";
            sprintf(flutter_status_vals[idx], fmt, text ? text : "");
            flutter_status_colors[idx] = color;
        }
    }
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
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "NetHack Thread Function is RUNNING! Chdir to: %s", args->path);

    if (chdir(args->path) != 0) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "chdir failed in thread! errno=%d", errno);
    }

    // sysconf ファイルを毎回最新の完全正当内容で確実に更新・展開
    char syscf_path[512];
    snprintf(syscf_path, sizeof(syscf_path), "%s/sysconf", args->path);
    FILE* f_syscf = fopen(syscf_path, "w");
    if (f_syscf) {
        fputs("# NetHack 5.0 System Configuration File\n"
              "WIZARDS=*\n"
              "EXPLORERS=*\n"
              "SHELLERS=*\n"
              "GENERICUSERS=*\n"
              "SUPPORT=https://nethack.org\n"
              "MAXPLAYERS=25\n"
              "PERSMAX=10\n"
              "POINTSMIN=1\n"
              "PERS_IS_UID=0\n"
              "ENTRYMAX=100\n"
              "MAX_REROLL_RATE=10\n"
              "SEDUCE=1\n"
              "HIDEUSAGE=0\n", f_syscf);
        fclose(f_syscf);
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "sysconf file updated to latest valid content at: %s", syscf_path);
    }

    // perm ファイルが存在しなければ自動作成して getlock() での Fatal 終了を完全防止
    char perm_path[512];
    snprintf(perm_path, sizeof(perm_path), "%s/perm", args->path);
    FILE* f_perm = fopen(perm_path, "r");
    if (!f_perm) {
        f_perm = fopen(perm_path, "w");
        if (f_perm) {
            fputs("# NetHack 5.0 Permanent Locks File\n", f_perm);
            fclose(f_perm);
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "perm file created at: %s", perm_path);
        }
    } else {
        fclose(f_perm);
    }

    HijackWindowProcs();

    char* params[2];
    params[0] = "nethack";
    params[1] = NULL;

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Calling NetHackMain... (initial svp.plname='%s')", svp.plname);
    extern int NetHackMain(int argc, char** argv);
    NetHackMain(1, params);

    debuglog("NetHackMain exited.");
    if (g_exit_cb && !g_exit_notified) {
        g_exit_notified = 1;
        g_exit_cb("");
    }
    free(args);
    return NULL;
}

void StartNetHackFlutter(const char* path, const char* username) {
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "StartNetHackFlutter: path=%s, user=%s", path, username);

    g_exit_notified = 0;

    struct StartArgs* args = malloc(sizeof(struct StartArgs));
    if (!args) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "Failed to malloc StartArgs!");
        return;
    }
    strncpy(args->path, path, sizeof(args->path) - 1);
    strncpy(args->username, username, sizeof(args->username) - 1);

    pthread_t thread;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    // NetHack Cコアの巨大なスタック消費に耐えるため 8MB に拡張
    pthread_attr_setstacksize(&attr, 8 * 1024 * 1024);

    int rc = pthread_create(&thread, &attr, NetHackThreadFunc, args);
    pthread_attr_destroy(&attr);

    if (rc != 0) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "Failed to create NetHack thread! rc=%d", rc);
        free(args);
    } else {
        pthread_detach(thread);
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "NetHack thread spawned successfully with 8MB stack.");
    }
}

extern void prscore(int argc, char **argv);

const char* GetTopTenTextFlutter(void) {
    g_topten_capture_buf[0] = '\0';

    winid old_toptenwin = gt.toptenwin;
    gt.toptenwin = 9999;
    g_is_topten_capturing = 1;

    char *score_argv[2];
    score_argv[0] = "scores";
    score_argv[1] = "-sall";
    prscore(2, score_argv);

    g_is_topten_capturing = 0;
    gt.toptenwin = old_toptenwin;

    return g_topten_capture_buf;
}

void TriggerDatabaseSearchFlutter(void) {
    extern void cmdq_add_key(int q, char key);
    cmdq_add_key(0 /* CQ_CANNED */, '?');
    int key = '/';
    SendKeysToFlutter(&key, 1);
}

#ifndef NETHACK_BUILD_ID
#define NETHACK_BUILD_ID "unknown_build"
#endif

const char* flutter_get_build_id(void) {
    return NETHACK_BUILD_ID;
}





