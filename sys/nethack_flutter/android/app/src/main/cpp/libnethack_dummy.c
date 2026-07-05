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

typedef void (*PrintCallback)(const char* message);

static PrintCallback g_print_callback = NULL;
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

void run_dummy_game_loop() {
    g_thread_running = 1;
    if (g_print_callback) {
        g_print_callback("=== NetHack Flutter Dummy Core Started ===");
        g_print_callback("You see a dark room. What do you want to do?");
        g_print_callback("(Press any key to walk, 'q' to quit)");
    }

    while (g_thread_running) {
        // Increment input request ID to notify Dart
        g_input_request_id++;

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
DLL_EXPORT void stop_dummy_game() {
    g_thread_running = 0;
}
#endif
