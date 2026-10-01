/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-10-01. */
// lua.hpp
// Lua header files for C++
// 'extern "C" not supplied automatically in lua.h and other headers
// because Lua also compiles as C++

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}
