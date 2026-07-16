#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#define DLL_EXPORT __declspec(dllexport)
#else
#include <pthread.h>
#include <unistd.h>
#define DLL_EXPORT
#endif

typedef void (*PrintCallback)(int winId, int attr, const char* message);
typedef void (*DartNotifyInputCallback)(int requestId);

static PrintCallback g_print_callback = NULL;
static DartNotifyInputCallback g_input_callback = NULL;
static volatile int g_next_key = 0;
static volatile int g_input_request_id = 0;
static volatile int g_thread_running = 0;

DLL_EXPORT void register_print_callback(PrintCallback callback) {
    g_print_callback = callback;
}

DLL_EXPORT void send_key_to_c(int key) {
    g_next_key = key;
}

DLL_EXPORT int get_input_request_id() {
    return g_input_request_id;
}

// ----------------------------------------------------
// Flutter-compatible APIs (for seamless local Windows testing)
// ----------------------------------------------------

DLL_EXPORT void RegisterFlutterCallbacks(
    void* create_cb,
    void* clear_cb,
    void* display_cb,
    void* destroy_cb,
    void* curs_cb,
    PrintCallback putstr_cb,
    void* glyph_cb,
    DartNotifyInputCallback input_cb,
    void* start_menu_cb,
    void* add_menu_cb,
    void* end_menu_cb,
    void* select_menu_cb,
    void* yn_cb,
    void* getline_cb,
    void* askname_cb,
    void* exit_cb,
    void* number_pad_cb,
    void* cliparound_cb,
    void* putmixed_cb
) {
    (void)create_cb;
    (void)clear_cb;
    (void)display_cb;
    (void)destroy_cb;
    (void)curs_cb;
    (void)glyph_cb;
    (void)start_menu_cb;
    (void)add_menu_cb;
    (void)end_menu_cb;
    (void)select_menu_cb;
    (void)yn_cb;
    (void)getline_cb;
    (void)askname_cb;
    (void)exit_cb;
    (void)number_pad_cb;
    (void)cliparound_cb;
    (void)putmixed_cb;
    g_print_callback = putstr_cb;
    g_input_callback = input_cb;
}

DLL_EXPORT void SendKeyToFlutter(int key) {
    g_next_key = key;
}

DLL_EXPORT void SendKeysToFlutter(const int* keys, int len) {
    if (keys && len > 0) {
        g_next_key = keys[0];
    }
}

DLL_EXPORT void SendShortcutToFlutter(const int* keys, int len) {
    if (keys && len > 0) {
        g_next_key = keys[0];
    }
}

DLL_EXPORT void SendMenuSelection(long ident) {
    (void)ident;
}

DLL_EXPORT void SendMenuSelectionsToC(const char* csv) {
    (void)csv;
}

DLL_EXPORT int GetFlutterInputRequestId() {
    return g_input_request_id;
}

void run_dummy_game_loop() {
    g_thread_running = 1;
    if (g_print_callback) {
        g_print_callback(1, 0, "=== NetHack Flutter Dummy Core Started ===");
        g_print_callback(1, 0, "You see a dark room. What do you want to do?");
        g_print_callback(1, 0, "(Press any key to walk, 'q' to quit)");
    }

    while (g_thread_running) {
        // Increment input request ID to notify Dart
        g_input_request_id++;
        if (g_input_callback) {
            g_input_callback(g_input_request_id);
        }

        // Wait for key from Dart
        while (g_next_key == 0 && g_thread_running) {
#ifdef _WIN32
            Sleep(50);
#else
            usleep(50000);
#endif
        }

        if (!g_thread_running) break;

        int ch = g_next_key;
        g_next_key = 0;

        if (ch == 'q') {
            if (g_print_callback) {
                g_print_callback(1, 0, "Goodbye!");
            }
            break;
        } else {
            char buf[128];
            snprintf(buf, sizeof(buf), "You pressed '%c'. You walk forward.", ch);
            if (g_print_callback) {
                g_print_callback(1, 0, buf);
            }
        }
    }
    g_thread_running = 0;
}

#ifdef _WIN32
DWORD WINAPI thread_func(LPVOID lpParam) {
    run_dummy_game_loop();
    return 0;
}
DLL_EXPORT void start_dummy_game() {
    if (g_thread_running) return;
    CreateThread(NULL, 0, thread_func, NULL, 0, NULL);
}
DLL_EXPORT void StartNetHackFlutter(const char* path, const char* username) {
    if (g_thread_running) return;
    CreateThread(NULL, 0, thread_func, NULL, 0, NULL);
}
DLL_EXPORT void stop_dummy_game() {
    g_thread_running = 0;
}
#else
void* thread_func(void* arg) {
    run_dummy_game_loop();
    return NULL;
}
DLL_EXPORT void start_dummy_game() {
    if (g_thread_running) return;
    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_detach(thread);
}
DLL_EXPORT void StartNetHackFlutter(const char* path, const char* username) {
    if (g_thread_running) return;
    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_detach(thread);
}
DLL_EXPORT void stop_dummy_game() {
    g_thread_running = 0;
}
#endif
