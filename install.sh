#!/usr/bin/env bash
# install.sh — One-line installer for unbar-server:
#   curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
#
# Fetches the main script, puts it in /usr/local/bin/unbar-server
# and opens the interactive menu.
set -euo pipefail

REPO="viahamed/unbar-server"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
INSTALL_PATH="/usr/local/bin/unbar-server"

# Installation needs root; if not run with sudo, either continue with sudo
# (when the install file has been downloaded) or say clearly how to run it.
if [[ "$(id -u)" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1 && [[ -f "$0" ]]; then
        echo "Root access is required; continuing with sudo..."
        exec sudo bash "$0" "$@"
    fi
    echo "Error: installing unbar-server requires root access." >&2
    echo "Run it like this:" >&2
    echo "  curl -fsSL $RAW/install.sh | sudo bash" >&2
    exit 1
fi

command -v curl >/dev/null 2>&1 || {
    echo "Error: curl not found; install it first (e.g.: apt install curl)" >&2
    exit 1
}

echo "Downloading unbar-server from $REPO ..."
tmp="$(mktemp)"
# Download to a temp file first so that if the download fails, the currently
# installed version stays untouched.
curl -fsSL "$RAW/unbar-server" -o "$tmp" || {
    rm -f "$tmp"
    echo "Error: downloading unbar-server failed; check the internet connection or the repo address" >&2
    exit 1
}
head -n 1 "$tmp" | grep -q '^#!/usr/bin/env bash' || {
    rm -f "$tmp"
    echo "Error: the downloaded file is not a valid script" >&2
    exit 1
}
install -m 755 "$tmp" "$INSTALL_PATH"
rm -f "$tmp"
echo "Installed: $INSTALL_PATH"
# Short command: bare `unbar` opens the menu, same as `unbar-server`
ln -sf "$INSTALL_PATH" /usr/local/bin/unbar

# The menu reads from the terminal; when installed via a pipe, stdin
# is no longer the terminal (EOF) — so I reconnect input to /dev/tty so
# the menu does not close immediately.
if [[ -e /dev/tty ]]; then
    exec "$INSTALL_PATH" < /dev/tty
else
    exec "$INSTALL_PATH"
fi
