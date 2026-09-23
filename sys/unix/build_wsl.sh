# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-23.
#!/bin/sh
# NetHackJP build script for WSL (Linux)
# NetHackJP: --qt option to opt-in the Qt6 window port (2026-09-23).
# Usage: ./sys/unix/build_wsl.sh [--qt] [--default=<tty|curses|X11|Qt>] [hints_file]
#   --qt  Also build the Qt6 window port (requires qt6-base-dev,
#         qt6-multimedia-dev and qt6-base-dev-tools packages installed)
#   --default=<port>  Override the default window port (default: tty;
#         --qt implies Qt unless overridden)
# Note: this script only builds. Use sys/unix/install_wsl.sh (with the
# same --qt / --default flags) to run 'make install' into playground/.

set -e

# Change directory to repository root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# NetHackJP: parse options; --qt opts into the Qt6 port, any other
# argument is treated as the hints file (default: linux-jp).
WANT_QT=0
WANT_DEFAULT_OVERRIDE=""
HINTS=""
for arg in "$@"; do
    case "$arg" in
        --qt)
            WANT_QT=1
            ;;
        --default=*)
            WANT_DEFAULT_OVERRIDE="${arg#--default=}"
            ;;
        *)
            if [ -z "$HINTS" ]; then
                HINTS="$arg"
            fi
            ;;
    esac
done
HINTS="${HINTS:-sys/unix/hints/linux-jp}"

echo "=========================================="
echo "NetHackJP WSL / Linux Build Setup"
echo "Hints file: $HINTS"
echo "=========================================="
echo "Qt6 window port: $([ $WANT_QT -eq 1 ] && echo ON || echo off)"

if [ $WANT_QT -eq 1 ]; then
    # NetHackJP: verify Qt6 development packages before generating Makefiles;
    # the linux-jp hints resolve Qt6 compiler flags, libraries and moc path
    # via pkg-config, so Qt6Core/Qt6Gui/Qt6Widgets/Qt6Multimedia .pc files
    # plus the moc tool must be present.
    if ! pkg-config --exists Qt6Core Qt6Gui Qt6Widgets Qt6Multimedia 2>/dev/null; then
        echo "--------------------------------------------------------"
        echo "[!] Error: Qt6 development packages (qt6-base-dev, qt6-multimedia-dev)"
        echo "    not found. To build with the Qt6 window port, please run:"
        echo "    sudo apt update && sudo apt install -y qt6-base-dev \\"
        echo "         qt6-multimedia-dev qt6-base-dev-tools"
        echo "--------------------------------------------------------"
        exit 1
    fi
    QT_MOC="$(pkg-config --variable=libexecdir Qt6Core)/moc"
    if [ ! -x "$QT_MOC" ]; then
        echo "--------------------------------------------------------"
        echo "[!] Error: Qt6 'moc' tool not found at $QT_MOC."
        echo "    To fix this issue, please run the following command in WSL:"
        echo "    sudo apt install -y qt6-base-dev-tools"
        echo "--------------------------------------------------------"
        exit 1
    fi
    echo "Qt6 version: $(pkg-config --modversion Qt6Core) (moc: $QT_MOC)"
fi

if [ ! -f "$HINTS" ]; then
    echo "Error: Hints file '$HINTS' not found."
    exit 1
fi

# Check prerequisites (curses.h and libncurses)
HAS_CURSES=0
if pkg-config --exists ncursesw 2>/dev/null || pkg-config --exists ncurses 2>/dev/null; then
    HAS_CURSES=1
elif [ -f /usr/include/curses.h ] || [ -f /usr/include/ncursesw/curses.h ] || [ -f /usr/include/ncurses/curses.h ]; then
    if [ -f /usr/lib/x86_64-linux-gnu/libncursesw.so ] || [ -f /usr/lib/x86_64-linux-gnu/libncurses.so ] || [ -f /usr/lib/libncursesw.so ] || [ -f /usr/lib/libncurses.so ]; then
        HAS_CURSES=1
    fi
elif grep -q "NO_TERMCAP_HEADERS" "$HINTS" 2>/dev/null; then
    HAS_CURSES=1
fi

if [ $HAS_CURSES -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "[!] Error: ncurses development library/headers (libncursesw5-dev) not found."
    echo "    To fix this issue, please run the following command in WSL:"
    echo "    sudo apt update && sudo apt install -y build-essential libncursesw5-dev liblua5.4-dev pkg-config \\"
    echo "         libx11-dev libxft-dev libxpm-dev libxaw7-dev libxt-dev fonts-noto-cjk \\"
    echo "         fcitx5 fcitx5-modules fcitx5-mozc"
    echo "--------------------------------------------------------"
    exit 1
fi

# Run setup.sh to generate Makefiles
sh sys/unix/setup.sh "$HINTS"

echo "Makefiles generated successfully."
echo "Cleaning old build artifacts..."
make clean
rm -f src/hacklib.a src/*.o util/*.o util/tile2x11 dat/x11tiles playground/x11tiles

# NetHackJP: Report XIM (X Input Method) compile-time status so the
# user can verify that HAVE_XIM was picked up by the generated Makefile.
if grep -q -- "-DHAVE_XIM" src/Makefile 2>/dev/null; then
    echo "XIM support: ENABLED (-DHAVE_XIM detected in src/Makefile)"
else
    echo "XIM support: DISABLED (HAVE_XIM not set; check linux-jp hints)"
fi

# NetHackJP: Fetch Lua sources if not already present
if [ ! -f "lib/lua-5.4.8/src/lua.h" ]; then
    echo "Fetching Lua 5.4.8 prerequisites..."
    make fetch-lua || make fetch-lua NOCHKSUM=1
fi

echo "Building prerequisites (lua_support)..."
make lua_support

# NetHackJP: add the Qt6 port to the make invocation only when --qt was
# given, so the existing tty/curses/X11 build stays untouched by default.
QTMAKEARGS=""
WANT_DEFAULT=tty
if [ $WANT_QT -eq 1 ]; then
    QTMAKEARGS="WANT_WIN_QT=1 WANT_WIN_QT6=1"
    WANT_DEFAULT=Qt
fi
if [ -n "$WANT_DEFAULT_OVERRIDE" ]; then
    WANT_DEFAULT="$WANT_DEFAULT_OVERRIDE"
fi

echo "Starting main build with sequential make (tty, curses & X11 interfaces)..."

make WANT_WIN_CURSES=1 WANT_WIN_TTY=1 WANT_WIN_X11=1 $QTMAKEARGS WANT_DEFAULT=$WANT_DEFAULT all x11tiles

if [ $WANT_QT -eq 1 ]; then
    # NetHackJP: the Qt port also uses nhtiles.bmp / nhsplash.xpm / rip.xpm
    # (VARDATND0 in the hints); build them from dat/ up front so that
    # 'make install' and the first Qt launch have every asset ready.
    echo "Building Qt data assets (nhtiles.bmp, nhsplash.xpm, rip.xpm)..."
    make nhtiles.bmp nhsplash.xpm rip.xpm
fi

echo "=========================================="
echo "Build complete! Executable is located at src/nethack."
if [ $WANT_QT -eq 1 ]; then
    echo "All 'tty', 'curses', 'X11' and 'Qt' window ports are included."
else
    echo "All 'tty', 'curses' and 'X11' window ports are included."
fi
echo ""
echo "Next step: Install into playground/ with sys/unix/install_wsl.sh"
echo "(it runs 'make install' with the same WANT_WIN_* flags as this build;)"
echo "or run 'make install' by hand with the same flags)."
echo "Then execute: ./playground/nethack (or ./playground/nethack -wX11 for X11 GUI)"
if [ $WANT_QT -eq 1 ]; then
    # NetHackJP: the hints add the Qt data assets (nhtiles.bmp, nhsplash.xpm,
    # rip.xpm) to VARDATND0 at make parse time, so 'make install' must be
    # invoked with the same WANT_WIN_QT flags as the build.
    echo "For the Qt6 GUI: QT_QPA_PLATFORM=xcb ./playground/nethack -wQt"
fi
echo ""
echo "------ XIM verification (X11 GUI only) ------"
echo "Run './playground/nethack -wX11' and check stderr for one of:"
echo "  XIM: connected to input method (XPreeditNothing / XStatusNothing)"
echo "      -> fcitx5 / ibus connected; Japanese input will work after Phase 2+"
echo "  XIM: no input method registered (XMODIFIERS unset or @im=none)"
echo "      -> check 'export XMODIFIERS=@im=fcitx' (or @im=ibus)"
echo "  XIM: XOpenIM failed; falling back to XLookupString (ASCII only)"
echo "      -> IM server is set in XMODIFIERS but not actually running"
echo "      -> e.g. 'fcitx5 --disable=wayland,waylandim -d' or 'ibus-daemon -drx'"
echo "=========================================="
