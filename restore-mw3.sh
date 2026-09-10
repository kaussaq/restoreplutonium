#!/usr/bin/env bash

# ============================================================
# MW3 / IW5 32-bit Dedicated Server Restore
# ============================================================

STEAMCMD=""
STEAMCMD_HOME="$HOME/steamcmd"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

# SteamCMD depot download location (packaged steamcmd). Overridden for steamcmd.sh.
CONTENT_DIR="$HOME/.steam/steamcmd/linux32/steamapps/content/app_42680"

DEPOT_BASE="$CONTENT_DIR/depot_42682"
DEPOT_ENGLISH="$CONTENT_DIR/depot_42683"

# Dedicated server installation
SERVER_DIR="$HOME/.local/share/Steam/steamapps/common/Call of Duty Modern Warfare 3"

# Steam depot manifests
BASE_MANIFEST="2661317971072643596"
ENGLISH_MANIFEST="1595601894688570808"

# ------------------------------------------------------------
# Distro detection (install hints only; restore steps are the same)
# ------------------------------------------------------------

PKG_FAMILY="unknown"
DISTRO_ID="unknown"

detect_pkg_family() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
    fi

    local like=" ${ID_LIKE:-} "

    case "$DISTRO_ID" in
        arch|cachyos|manjaro|endeavouros|garuda|artix)
            PKG_FAMILY="arch"
            ;;
        debian|ubuntu|linuxmint|pop|elementary|zorin|kali|raspbian)
            PKG_FAMILY="debian"
            ;;
        fedora|nobara|rhel|centos|rocky|almalinux|ol)
            PKG_FAMILY="fedora"
            ;;
        bazzite)
            PKG_FAMILY="ostree"
            ;;
        opensuse*|sles)
            PKG_FAMILY="suse"
            ;;
        *)
            if [[ "$like" == *"arch"* ]]; then
                PKG_FAMILY="arch"
            elif [[ "$like" == *"debian"* ]] || [[ "$like" == *"ubuntu"* ]]; then
                PKG_FAMILY="debian"
            elif [[ "$like" == *"fedora"* ]] || [[ "$like" == *"rhel"* ]]; then
                PKG_FAMILY="fedora"
            elif [[ "$like" == *"suse"* ]]; then
                PKG_FAMILY="suse"
            fi
            ;;
    esac

    # Immutable Fedora-family images (Bazzite, Silverblue, Kinoite, uBlue)
    if [[ -e /run/ostree-booted ]]; then
        PKG_FAMILY="ostree"
    fi
}

print_rsync_hint() {
    echo "Install rsync with:"
    case "$PKG_FAMILY" in
        arch)
            echo "  sudo pacman -S rsync"
            ;;
        debian)
            echo "  sudo apt install rsync"
            ;;
        fedora)
            echo "  sudo dnf install rsync"
            ;;
        ostree)
            echo "  rpm-ostree install rsync"
            echo
            echo "On Bazzite / Silverblue this layers the package onto the image (reboot after)."
            echo "A Distrobox container is not required for this script."
            ;;
        suse)
            echo "  sudo zypper install rsync"
            ;;
        *)
            echo "  Use your distro's package manager (apt, dnf, pacman, zypper, rpm-ostree)."
            ;;
    esac
}

print_steamcmd_hint() {
    echo "Package-manager alternatives:"
    case "$PKG_FAMILY" in
        arch)
            echo "  paru -S steamcmd"
            echo "  # or: yay -S steamcmd"
            ;;
        debian)
            echo "  sudo dpkg --add-architecture i386"
            echo "  sudo apt update"
            echo "  sudo apt install steamcmd"
            echo
            echo "Ubuntu: enable the multiverse repo first if the package is missing."
            echo "Debian: enable the non-free repo first if the package is missing."
            ;;
        fedora)
            echo "  sudo dnf install glibc.i686 libstdc++.i686"
            echo "  Fedora does not ship a steamcmd package; use the tarball install above."
            ;;
        ostree)
            echo "  Bazzite / immutable Fedora: Distrobox is not required."
            echo "  SteamCMD is not a host package; use the tarball install above."
            ;;
        *)
            echo "  Arch:     paru -S steamcmd"
            echo "  Debian:   sudo apt install steamcmd"
            echo "  Fedora:   no steamcmd package; use the tarball"
            ;;
    esac
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local reply

    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n] " reply
        reply="${reply:-y}"
    else
        read -rp "$prompt [y/N] " reply
        reply="${reply:-n}"
    fi

    [[ "$reply" =~ ^[Yy]$ ]]
}

resolve_steamcmd() {
    if command -v steamcmd >/dev/null 2>&1; then
        STEAMCMD="$(command -v steamcmd)"
        return 0
    fi

    local candidate
    for candidate in \
        /usr/games/steamcmd \
        "$STEAMCMD_HOME/steamcmd.sh" \
        "$HOME/.steam/steamcmd/steamcmd.sh" \
        "$HOME/.local/share/steamcmd/steamcmd.sh"
    do
        if [[ -x "$candidate" ]]; then
            STEAMCMD="$candidate"
            return 0
        fi
    done

    return 1
}

apply_steamcmd_paths() {
    # Valve's steamcmd.sh keeps depots next to itself, not ~/.steam/steamcmd
    if [[ "$STEAMCMD" == *.sh ]]; then
        STEAMCMD_DIR="$(cd "$(dirname "$STEAMCMD")" && pwd)"
        CONTENT_DIR="$STEAMCMD_DIR/linux32/steamapps/content/app_42680"
        DEPOT_BASE="$CONTENT_DIR/depot_42682"
        DEPOT_ENGLISH="$CONTENT_DIR/depot_42683"
    fi
}

install_steamcmd_tarball() {
    local archive="$STEAMCMD_HOME/steamcmd_linux.tar.gz"

    mkdir -p "$STEAMCMD_HOME"

    echo
    echo "Downloading SteamCMD into:"
    echo "  $STEAMCMD_HOME"
    echo
    echo "This is a fixed home-directory location, not the folder you ran the script from."
    echo

    if command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar "$STEAMCMD_URL" -o "$archive"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$archive" "$STEAMCMD_URL"
    else
        echo "ERROR: curl or wget is required to download SteamCMD."
        return 1
    fi

    tar -xzf "$archive" -C "$STEAMCMD_HOME"
    rm -f "$archive"
    chmod +x "$STEAMCMD_HOME/steamcmd.sh"

    if [[ ! -x "$STEAMCMD_HOME/steamcmd.sh" ]]; then
        echo "ERROR: SteamCMD extract failed in $STEAMCMD_HOME"
        return 1
    fi

    STEAMCMD="$STEAMCMD_HOME/steamcmd.sh"
    echo
    echo "SteamCMD installed to:"
    echo "  $STEAMCMD"
}

offer_steamcmd_symlink() {
    local bindir="$HOME/.local/bin"
    local link="$bindir/steamcmd"

    echo
    echo "This restore script will call SteamCMD by full path. You do not need it on PATH to continue."
    echo

    if ! confirm "Also create a symlink at $link so 'steamcmd' works in other terminals?" "n"; then
        echo
        echo "Skipped PATH symlink. To run SteamCMD yourself later:"
        echo "  $STEAMCMD"
        return 0
    fi

    mkdir -p "$bindir"
    ln -sf "$STEAMCMD" "$link"
    echo
    echo "Created symlink:"
    echo "  $link -> $STEAMCMD"

    if [[ ":$PATH:" != *":$bindir:"* ]]; then
        echo
        echo "$bindir is not on PATH in this shell. Add this to your shell config if you want the steamcmd command:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

prompt_install_steamcmd() {
    echo "SteamCMD was not found on PATH or in $STEAMCMD_HOME."
    echo
    if [[ "$DISTRO_ID" != "unknown" ]]; then
        echo "Detected distro: $DISTRO_ID"
        echo
    fi
    echo "This script can download Valve's Linux SteamCMD into:"
    echo "  $STEAMCMD_HOME"
    echo
    echo "It will not extract into the current directory, so it will not land in this git repo."
    echo

    if confirm "Install SteamCMD there now?" "y"; then
        install_steamcmd_tarball || exit 1
        offer_steamcmd_symlink
        return 0
    fi

    echo
    echo "SteamCMD was not installed."
    echo "Re-run this script and answer Y, or install it yourself:"
    echo
    print_steamcmd_hint
    exit 1
}

# ------------------------------------------------------------
# Check requirements
# ------------------------------------------------------------

detect_pkg_family

if ! resolve_steamcmd; then
    prompt_install_steamcmd
fi

apply_steamcmd_paths

if ! command -v rsync >/dev/null 2>&1; then
    echo "ERROR: rsync is not installed."
    echo
    if [[ "$DISTRO_ID" != "unknown" ]]; then
        echo "Detected distro: $DISTRO_ID"
        echo
    fi
    print_rsync_hint
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

"$STEAMCMD" \
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

"$STEAMCMD" \
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
