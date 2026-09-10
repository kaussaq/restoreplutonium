# MW3 Dedicated Server — Linux 32-bit Restore

Steam now ships a 64-bit MW3 Dedicated Server. Plutonium still needs the older **32-bit** files. This script downloads those legacy files and copies them over your Dedicated Server install.

You do **not** need to own the MW3 campaign/multiplayer game. You only need the **MW3 Dedicated Server** on Steam.

---

## ⚠️ Prerequisites

1. **MW3 Dedicated Server** installed through Steam (Linux / Proton is fine).
2. **Plutonium** with Game Path set to that Dedicated Server folder, for example:

   ```text
   ~/.local/share/Steam/steamapps/common/Call of Duty Modern Warfare 3
   ```

   Your Steam library path may differ. Plutonium can run under Proton; the Game Path must still be the Dedicated Server directory this script restores.

3. **`rsync`** (used to copy the restored files). Install it with your distro's package manager if needed:

   ```bash
   sudo pacman -S rsync          # Arch / CachyOS
   sudo apt install rsync        # Debian / Ubuntu
   sudo dnf install rsync        # Fedora / Nobara
   rpm-ostree install rsync      # Bazzite / Silverblue (reboot after)
   sudo zypper install rsync     # openSUSE
   ```

4. A **Steam account** that can download the Dedicated Server depots. Steam Guard may prompt during the run.

**SteamCMD** is required to download the depots. You do not need to install it first: if it is missing, the script will offer to install it. If you already have `steamcmd` (package or `~/steamcmd`), that copy is used.

---

## How to run

```bash
chmod +x restore-mw3.sh
./restore-mw3.sh
```

Steam username and password are asked at runtime and are **not** stored in the script.

If Steam later replaces the 32-bit files with a 64-bit update, run the script again.

---

## What the script does

1. **Finds SteamCMD** on your PATH, or at `~/steamcmd/steamcmd.sh`.
2. **If SteamCMD is missing**, asks whether to install Valve's Linux SteamCMD into `~/steamcmd`. If you agree, it downloads it there and continues. You can optionally create `~/.local/bin/steamcmd` so the `steamcmd` command works in other terminals. If you decline, it prints package-manager options and exits.
3. **Checks `rsync`** and that the Dedicated Server directory exists.
4. **Asks for Steam login**, then downloads depot `42682` (32-bit base) and depot `42683` (English).
5. **Copies both depots** into the Dedicated Server directory with `rsync` (overwrites matching files, does not delete other files).

Default server path:

```text
~/.local/share/Steam/steamapps/common/Call of Duty Modern Warfare 3
```

If yours is different, change `SERVER_DIR` near the top of `restore-mw3.sh`.

Both depots are downloaded every time the script runs.

### Depots

| Depot              | Manifest              |
| ------------------ | --------------------- |
| `42682` — MW3 base | `2661317971072643596` |
| `42683` — English  | `1595601894688570808` |

---

## Credits

Based on the Plutonium MW3 32-bit depot workaround.

🐧 Keep MW3 alive on Linux.
