cmake_minimum_required(VERSION 3.10.2)

project(nethack_dummy VERSION 1.0.0 LANGUAGES C)

add_library(nethack_dummy SHARED
            libnethack_dummy.c)

# ログ出力用（必要に応じて）
find_library(log-lib log)
if(log-lib)
    target_link_libraries(nethack_dummy ${log-lib})
endif()
