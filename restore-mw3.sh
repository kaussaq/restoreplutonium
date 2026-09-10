#!/usr/bin/env bash

# ============================================================
# MW3 / IW5 32-bit Dedicated Server Restore
# ============================================================

STEAMCMD="steamcmd"

# SteamCMD depot download location
CONTENT_DIR="$HOME/.steam/steamcmd/linux32/steamapps/content/app_42680"

DEPOT_BASE="$CONTENT_DIR/depot_42682"
DEPOT_ENGLISH="$CONTENT_DIR/depot_42683"

# Dedicated server installation
SERVER_DIR="$HOME/.local/share/Steam/steamapps/common/Call of Duty Modern Warfare 3"

# Steam depot manifests
BASE_MANIFEST="2661317971072643596"
ENGLISH_MANIFEST="1595601894688570808"

# ------------------------------------------------------------
# Check requirements
# ------------------------------------------------------------

if ! command -v steamcmd >/dev/null 2>&1; then
    echo "ERROR: steamcmd is not installed or not in PATH."
    echo "Could be fixed with (or similar):"
    echo "   paru -S steamcmd"
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    echo "ERROR: rsync is not installed."
    echo
    echo "Install it with:"
    echo "  sudo pacman -S rsync"
    exit 1
fi

if [[ ! -d "$SERVER_DIR" ]]; then
    echo "ERROR: MW3 dedicated server directory not found:"
    echo
    echo "  $SERVER_DIR"
    exit 1
fi

# ------------------------------------------------------------
# Steam credentials
# ------------------------------------------------------------

echo "=============================================="
echo " MW3 / IW5 32-bit Dedicated Server Restore"
echo "=============================================="
echo

read -rp "Steam username: " STEAM_USER

if [[ -z "$STEAM_USER" ]]; then
    echo "ERROR: Steam username cannot be empty."
    exit 1
fi

read -rsp "Steam password: " STEAM_PASS
echo
echo

if [[ -z "$STEAM_PASS" ]]; then
    echo "ERROR: Steam password cannot be empty."
    exit 1
fi

# ------------------------------------------------------------
# Download depot 42682
# ------------------------------------------------------------

echo "=============================================="
echo " Downloading depot 42682"
echo "=============================================="
echo

steamcmd \
    +login "$STEAM_USER" "$STEAM_PASS" \
    +download_depot 42680 42682 "$BASE_MANIFEST" \
    +quit

if [[ ! -d "$DEPOT_BASE" ]]; then
    echo
    echo "ERROR: depot 42682 was not downloaded."
    exit 1
fi

echo
echo "Depot 42682 download complete."
echo

# ------------------------------------------------------------
# Download depot 42683
# ------------------------------------------------------------

echo "=============================================="
echo " Downloading depot 42683"
echo "=============================================="
echo

steamcmd \
    +login "$STEAM_USER" "$STEAM_PASS" \
    +download_depot 42680 42683 "$ENGLISH_MANIFEST" \
    +quit

if [[ ! -d "$DEPOT_ENGLISH" ]]; then
    echo
    echo "ERROR: depot 42683 was not downloaded."
    exit 1
fi

echo
echo "Depot 42683 download complete."
echo

# ------------------------------------------------------------
# Merge depot 42682
# ------------------------------------------------------------

echo "=============================================="
echo " Restoring depot 42682"
echo "=============================================="
echo

rsync -av --progress \
    "$DEPOT_BASE/" \
    "$SERVER_DIR/"

# ------------------------------------------------------------
# Merge depot 42683
# ------------------------------------------------------------

echo
echo "=============================================="
echo " Restoring depot 42683"
echo "=============================================="
echo

rsync -av --progress \
    "$DEPOT_ENGLISH/" \
    "$SERVER_DIR/"

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

echo
echo "=============================================="
echo " RESTORATION COMPLETE"
echo "=============================================="
echo
echo "32-bit MW3 files restored to:"
echo
echo "  $SERVER_DIR"
echo
