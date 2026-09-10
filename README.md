# MW3 Dedicated Server — Linux 32-bit Restore

Restore the legacy **32-bit MW3 Dedicated Server files** required for Plutonium after Steam moved the MW3 server files to a 64-bit build.

## ⚠️ Prerequisite — Plutonium

Plutonium must be configured to use your **MW3 Dedicated Server directory** as its Game Path.

Plutonium can run through Proton, but the selected Game Path must point directly to the **dedicated server installation restored by this script**.

For example:

```text
~/.local/share/Steam/steamapps/common/Call of Duty Modern Warfare 3
```

Your Steam library path may be different.

**You do not need to own/install the MW3 game itself. This workaround uses the MW3 Dedicated Server files.**

---

## What This Does

The script:

1. Downloads the legacy 32-bit base server depot.
2. Downloads the English language depot.
3. Waits for each download to finish.
4. Merges them into your MW3 Dedicated Server installation.
5. Overwrites newer files with the legacy versions.

### Depots

| Depot              | Manifest              |
| ------------------ | --------------------- |
| `42682` — MW3 base | `2661317971072643596` |
| `42683` — English  | `1595601894688570808` |

---

## Requirements

Arch / CachyOS:

```bash
sudo pacman -S rsync
paru -S steamcmd
```

You also need a Steam account with access to the required dedicated server depots.

---

## Install & Run

```bash
chmod +x restore-mw3.sh
./restore-mw3.sh
```

The script asks for your Steam username and password at runtime.

Your password is **not stored in the script**.

Steam Guard may be requested by SteamCMD.

---

## Steam Updates

If Steam updates the dedicated server files and replaces the legacy binaries, simply run the script again:

```text
Steam updates server
        ↓
32-bit files replaced
        ↓
Run restore-mw3.sh
        ↓
Legacy 32-bit files restored
        ↓
Plutonium uses the restored server
```

---

## Server Location

The script defaults to:

```text
~/.local/share/Steam/steamapps/common/Call of Duty Modern Warfare 3
```

If your Dedicated Server is installed somewhere else, change `SERVER_DIR` in the script.

---

## Notes

* Designed for Linux + Proton.
* Plutonium may run through Proton.
* Plutonium's **Game Path must point to the Dedicated Server installation**.
* The script downloads both depots every time it runs.
* `rsync` overwrites changed files but does not delete unrelated files.

## Credits

Based on the Plutonium MW3 32-bit depot workaround.

🐧 Keep MW3 alive on Linux.
