#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif

// Dartから渡されるコールバック関数ポインタの型定義
typedef void (*PrintCallback)(const char* message);
typedef int (*InputCallback)(void);

static PrintCallback g_print_callback = NULL;
static InputCallback g_input_callback = NULL;

DLL_EXPORT void register_print_callback(PrintCallback callback) {
    g_print_callback = callback;
}

DLL_EXPORT void register_input_callback(InputCallback callback) {
    g_input_callback = callback;
}

DLL_EXPORT void start_dummy_game() {
    if (g_print_callback) {
        g_print_callback("=== NetHack Flutter Dummy Core Started ===");
        g_print_callback("You see a dark room. What do you want to do?");
        g_print_callback("(Press any key to walk, 'q' to quit)");
    }

    while (1) {
        if (g_input_callback) {
            int ch = g_input_callback();
            
            if (ch == 'q') {
                if (g_print_callback) {
                    g_print_callback("Goodbye!");
                }
                break;
            } else {
                char buf[128];
                snprintf(buf, sizeof(buf), "You pressed '%c'. You walk forward.", ch);
                if (g_print_callback) {
                    g_print_callback(buf);
                }
            }
        } else {
            break;
        }
    }
}

DLL_EXPORT const char* flutter_get_build_id() {
    return "dummy_build_1.0";
}

