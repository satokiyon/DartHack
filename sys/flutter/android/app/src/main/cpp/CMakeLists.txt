cmake_minimum_required(VERSION 3.10.2)
project(nethack VERSION 5.0.0 LANGUAGES C)

get_filename_component(NHSROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../.." ABSOLUTE)
set(JPROOT "${NHSROOT}/c_core/nethack_jp")
set(ENROOT "${NHSROOT}/c_core/nethack_en")
set(LUAROOT "${NHSROOT}/submodules/lua")
set(PDCURSESROOT "${NHSROOT}/submodules/pdcurses")
set(PDCURSESMODROOT "${NHSROOT}/submodules/pdcursesmod")

message(STATUS "NetHack Root Path (NHSROOT): ${NHSROOT}")
message(STATUS "NetHack JP Core Path (JPROOT): ${JPROOT}")
message(STATUS "NetHack EN Core Path (ENROOT): ${ENROOT}")

if(NOT DEFINED BUILD_ID)
    string(TIMESTAMP BUILD_ID "%Y%m%d_%H%M%S")
endif()

# Compile flags
string(TIMESTAMP FORCE_REBUILD_TS "%Y%m%d%H%M%S")
add_definitions(
    -DANDROID
    -DSND_LIB_ANDROIDSOUND
    -DAND_GUI
    -DLINKED_BINS
    -DHACKLIB
    -DSYSCF
    -DSYSCF_FILE="sysconf"
    -DNETHACK_BUILD_ID="${BUILD_ID}"
    -DFORCE_REBUILD_TS="${FORCE_REBUILD_TS}"
    -DLUA_USE_POSIX
)

# Common OS & Window Port Sources
set(NETHACK_OS_SOURCES
    "fluttermain.c"
    "flutterunix.c"
    "winflutter.c"
)

# Lua 5.4 Sources (Exclude lua.c, luac.c, and onelua.c)
file(GLOB LUA_SOURCES "${LUAROOT}/*.c")
list(FILTER LUA_SOURCES EXCLUDE REGEX ".*/(lua|luac|onelua)\\.c$")

# Helper function to configure target safely with file existence checks
function(configure_nethack_target TARGET_NAME CORE_ROOT EXTRA_SOURCES IS_JP_TARGET)
    set(POTENTIAL_CORE_SOURCES
        "src/allmain.c"
        "src/alloc.c"
        "src/apply.c"
        "src/artifact.c"
        "src/attrib.c"
        "src/ball.c"
        "src/bones.c"
        "src/botl.c"
        "src/calendar.c"
        "src/cfgfiles.c"
        "src/cmd.c"
        "src/coloratt.c"
        "src/date.c"
        "src/dbridge.c"
        "src/decl.c"
        "src/detect.c"
        "src/dig.c"
        "src/display.c"
        "src/dlb.c"
        "src/do.c"
        "src/do_name.c"
        "src/do_wear.c"
        "src/dog.c"
        "src/dogmove.c"
        "src/dokick.c"
        "src/dothrow.c"
        "src/drawing.c"
        "src/dungeon.c"
        "src/earlyarg.c"
        "src/eat.c"
        "src/end.c"
        "src/engrave.c"
        "src/exper.c"
        "src/explode.c"
        "src/extralev.c"
        "src/files.c"
        "src/fountain.c"
        "src/hack.c"
        "src/hacklib.c"
        "src/getpos.c"
        "src/glyphs.c"
        "src/iactions.c"
        "src/insight.c"
        "src/invent.c"
        "src/isaac64.c"
        "src/light.c"
        "src/lock.c"
        "src/mail.c"
        "src/makemon.c"
        "src/mcastu.c"
        "src/mdlib.c"
        "src/mhitm.c"
        "src/mhitu.c"
        "src/minion.c"
        "src/mklev.c"
        "src/mkmap.c"
        "src/mkmaze.c"
        "src/mkobj.c"
        "src/mkroom.c"
        "src/mon.c"
        "src/mondata.c"
        "src/monmove.c"
        "src/monst.c"
        "src/mplayer.c"
        "src/mthrowu.c"
        "src/muse.c"
        "src/music.c"
        "src/nhlobj.c"
        "src/nhlsel.c"
        "src/nhlua.c"
        "src/nhmd4.c"
        "src/o_init.c"
        "src/objects.c"
        "src/objnam.c"
        "src/options.c"
        "src/pager.c"
        "src/pickup.c"
        "src/pline.c"
        "src/polyself.c"
        "src/potion.c"
        "src/pray.c"
        "src/priest.c"
        "src/quest.c"
        "src/questpgr.c"
        "src/read.c"
        "src/rect.c"
        "src/region.c"
        "src/report.c"
        "src/restore.c"
        "src/revision.c"
        "src/rip.c"
        "src/rnd.c"
        "src/role.c"
        "src/rumors.c"
        "src/save.c"
        "src/selvar.c"
        "src/sfbase.c"
        "src/sfstruct.c"
        "src/shk.c"
        "src/shknam.c"
        "src/sit.c"
        "src/sounds.c"
        "src/sp_lev.c"
        "src/spell.c"
        "src/stairs.c"
        "src/steal.c"
        "src/steed.c"
        "src/strutil.c"
        "src/symbols.c"
        "src/sys.c"
        "src/teleport.c"
        "src/timeout.c"
        "src/topten.c"
        "src/track.c"
        "src/trap.c"
        "src/u_init.c"
        "src/utf8map.c"
        "src/uhitm.c"
        "src/vault.c"
        "src/version.c"
        "src/vision.c"
        "src/weapon.c"
        "src/were.c"
        "src/wield.c"
        "src/windows.c"
        "src/wizard.c"
        "src/wizcmds.c"
        "src/worm.c"
        "src/worn.c"
        "src/write.c"
        "src/zap.c"
        "src/tile.c"
        "sys/share/ioctl.c"
        "sys/share/unixtty.c"
        "sys/share/posixregex.c"
    )

    set(RESOLVED_CORE_SOURCES "")
    foreach(src_rel IN LISTS POTENTIAL_CORE_SOURCES)
        set(full_path "${CORE_ROOT}/${src_rel}")
        if(EXISTS "${full_path}")
            list(APPEND RESOLVED_CORE_SOURCES "${full_path}")
        endif()
    endforeach()

    add_library(${TARGET_NAME} SHARED
        ${RESOLVED_CORE_SOURCES}
        ${EXTRA_SOURCES}
        ${NETHACK_OS_SOURCES}
        ${LUA_SOURCES}
    )

    if(${IS_JP_TARGET})
        target_compile_definitions(${TARGET_NAME} PRIVATE NETHACK_JP)
    endif()

    target_include_directories(${TARGET_NAME} PRIVATE
        "${CORE_ROOT}/include"
        "${LUAROOT}"
        "${PDCURSESROOT}"
        "${PDCURSESMODROOT}"
    )

    find_library(log-lib log)
    find_library(z-lib z)
    target_link_libraries(${TARGET_NAME}
        ${log-lib}
        ${z-lib}
        m
    )
endfunction()

# 1. Target: nethack_jp (libnethack_jp.so - Japanese Core Target)
set(JP_EXTRA_SOURCES
    "${JPROOT}/src/jp_data_lookup.c"
    "${JPROOT}/src/mon_jp.c"
    "${JPROOT}/src/obj_jp.c"
    "${JPROOT}/src/spell_jp.c"
)
configure_nethack_target(nethack_jp "${JPROOT}" "${JP_EXTRA_SOURCES}" TRUE)

# 2. Target: nethack (libnethack.so - Default Fallback Alias Target)
configure_nethack_target(nethack "${JPROOT}" "${JP_EXTRA_SOURCES}" TRUE)

# 3. Target: nethack_en (libnethack_en.so - English Core Target, disabled for initial JP-first build)
# configure_nethack_target(nethack_en "${ENROOT}" "" FALSE)
