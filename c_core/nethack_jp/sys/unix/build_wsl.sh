# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-06.
#!/bin/sh
# NetHackJP build script for WSL (Linux)
# Usage: ./sys/unix/build_wsl.sh [hints_file]

set -e

# Change directory to repository root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

HINTS="${1:-sys/unix/hints/linux-jp}"

echo "=========================================="
echo "NetHackJP WSL / Linux Build Setup"
echo "Hints file: $HINTS"
echo "=========================================="

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

echo "Starting main build with sequential make (tty, curses & X11 interfaces)..."

make WANT_WIN_CURSES=1 WANT_WIN_TTY=1 WANT_WIN_X11=1 WANT_DEFAULT=tty all x11tiles

echo "=========================================="
echo "Build complete! Executable is located at src/nethack."
echo "All 'tty', 'curses' and 'X11' window ports are included."
echo ""
echo "Next step: Run 'make install' to install into playground/."
echo "Then execute: ./playground/nethack (or ./playground/nethack -wX11 for X11 GUI)"
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
