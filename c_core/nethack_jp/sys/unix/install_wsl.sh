# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-23.
#!/bin/sh
# NetHackJP install script for WSL (Linux)
# NetHackJP: install counterpart of build_wsl.sh (2026-09-23).
# Usage: ./sys/unix/install_wsl.sh [--qt] [--default=<tty|curses|X11|Qt>]
#   Runs 'make install' with the same WANT_WIN_* flags that were used by
#   'sys/unix/build_wsl.sh' (optionally - '--qt').  The flags must match
#   because hints-level VARDATND0 additions (e.g. the Qt port's
#   nhtiles.bmp / nhsplash.xpm) are evaluated by make at run time, so an
#   install invoked with different flags would silently skip the Qt data
#   assets (see DEVELOPMENT.md §2.2 / §4.17).
#   --default=<port> overrides the default window port (WANT_DEFAULT);
#   useful for an all-in-one build that still starts in the tty console.

set -e

# Change directory to repository root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# NetHackJP: parse options the same way build_wsl.sh does
WANT_QT=0
WANT_DEFAULT_OVERRIDE=""
for arg in "$@"; do
    case "$arg" in
        --qt)
            WANT_QT=1
            ;;
        --default=*)
            WANT_DEFAULT_OVERRIDE="${arg#--default=}"
            ;;
        *)
            echo "Usage: ./sys/unix/install_wsl.sh [--qt] [--default=<port>]"
            echo "  --qt             Same meaning as 'build_wsl.sh --qt'"
            echo "                   (installs the Qt6 data assets too)."
            echo "  --default=<port> Override the default window port"
            echo "                   (tty|curses|X11|Qt)."
            exit 1
            ;;
    esac
done

if [ ! -f "src/Makefile" ]; then
    echo "--------------------------------------------------------"
    echo "[!] Error: Makefiles have not been generated."
    echo "    Run the build script first:"
    echo "      sh sys/unix/build_wsl.sh           # tty/curses/X11"
    echo "      sh sys/unix/build_wsl.sh --qt      # and add the Qt port"
    echo "--------------------------------------------------------"
    exit 1
fi

QTMAKEARGS=""
WANT_DEFAULT=tty
if [ $WANT_QT -eq 1 ]; then
    QTMAKEARGS="WANT_WIN_QT=1 WANT_WIN_QT6=1"
    WANT_DEFAULT=Qt
fi
if [ -n "$WANT_DEFAULT_OVERRIDE" ]; then
    WANT_DEFAULT="$WANT_DEFAULT_OVERRIDE"
fi

echo "=========================================="
echo "NetHackJP WSL / Linux Install"
echo "Qt6 build: $([ $WANT_QT -eq 1 ] && echo yes || echo no)"
echo "=========================================="

echo "Running 'make install' with the same flags as the build..."
make WANT_WIN_CURSES=1 WANT_WIN_TTY=1 WANT_WIN_X11=1 $QTMAKEARGS \
     WANT_DEFAULT=$WANT_DEFAULT install

echo "=========================================="
echo "Install complete! The game is in playground/ ."
echo "Execute: ./playground/nethack"
echo "(or ./playground/nethack -wX11 for the X11 GUI)"
if [ $WANT_QT -eq 1 ]; then
    echo "For the Qt6 GUI: QT_QPA_PLATFORM=xcb ./playground/nethack -wQt"
fi
echo ""
echo "------ XIM verification (X11 GUI only) ------"
echo "Run './playground/nethack -wX11' and check stderr for one of:"
echo "  XIM: connected to input method (XPreeditNothing / XStatusNothing)"
echo "      -> fcitx5 / ibus connected; Japanese input will work"
echo "  XIM: no input method registered (XMODIFIERS unset or @im=none)"
echo "      -> check 'export XMODIFIERS=@im=fcitx' (or @im=ibus)"
echo "  XIM: XOpenIM failed; falling back to XLookupString (ASCII only)"
echo "      -> IM server is set in XMODIFIERS but not actually running"
echo "      -> e.g. 'fcitx5 --disable=wayland,waylandim -d'"
echo "=========================================="
