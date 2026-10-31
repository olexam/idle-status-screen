# idle-status-screen

[Українська](README.uk.md)

Turn an idle login screen into a system status display.

While nobody is logged in graphically and there is no keyboard, mouse or
touchscreen input for a while (30 s by default), the display switches from the
login screen (SDDM or another display manager greeter) to a virtual terminal
running a system monitor — **btop** by default, or htop, atop, top or any other
program. Any input switches straight back to the login screen.

Built for a Raspberry Pi 5 with a touchscreen running KDE/SDDM, but nothing in
it is Pi-specific.

## Features

- Shows the status screen only while the **greeter** is in the foreground — never
  over a logged-in desktop session.
- Wakes up on **any** evdev input: keyboard, mouse, touchscreen; hot-plugged
  devices are picked up automatically. Input is only observed, never grabbed.
- The monitor runs **from boot** in a tmux session, so graphs already have
  history when the screen is shown.
- Displayed **read-only** through [kmscon](https://github.com/kmscon/kmscon):
  TrueType fonts with Braille glyphs (detailed btop graphs) and truecolor.
  Keystrokes on the status screen never reach the monitor program.
- Monitor runs as an unprivileged system user (`_idle-status`).
- **No screen blanking**: X screen saver/DPMS and kmscon DPMS are disabled.

## Install

Download the `.deb` from the [Releases](../../releases) page and install it:

```sh
sudo apt install ./idle-status-screen_*_all.deb
```

The services are enabled and started right away. Dependencies: `kmscon`,
`tmux`, `python3`, `kbd`, `util-linux`, `fonts-dejavu-core`; `btop` is
recommended.

## Configuration

Everything is in `/etc/default/idle-status`:

| Setting            | Default              | Meaning                                                      |
|--------------------|----------------------|--------------------------------------------------------------|
| `IDLE_TIMEOUT`     | `30`                 | Seconds without input on the login screen before switching   |
| `STATUS_VT`        | `8`                  | Virtual terminal for the status screen                       |
| `MONITOR`          | `btop`               | `btop`, `htop`, `atop`, `top` or any command/path            |
| `MONITOR_ARGS`     | *(empty)*            | Arguments; empty = sensible defaults for known programs      |
| `KMSCON_FONT`      | `DejaVu Sans Mono`   | Font of the status screen                                    |
| `KMSCON_FONT_SIZE` | `14`                 | Font size in pixels                                          |
| `KMSCON_ARGS`      | `--no-drm`           | Extra kmscon options (e.g. `--rotate=right`)                 |

Default arguments: btop `--no-tty -c /etc/idle-status/btop.conf` (0.5 s
refresh, Braille graphs), htop `-d 5`, top `-d 0.5`, atop `1`.

Apply changes:

```sh
sudo systemctl restart idle-status-monitor idle-status-display idle-status-watcher
```

The btop profile is in `/etc/idle-status/btop.conf`, the tmux settings in
`/etc/idle-status/tmux.conf`.

`--no-drm` makes kmscon draw through the framebuffer only; with DRM it showed
the Raspberry Pi DSI display twice. On other hardware you may remove it.

## How it works

| Component                      | What it does                                                                 |
|--------------------------------|------------------------------------------------------------------------------|
| `idle-status-monitor.service`  | Starts tmux as `_idle-status` at boot, running the monitor (restarted if it exits) |
| `idle-status-display.service`  | kmscon on `STATUS_VT`, showing the tmux session read-only (`tmux attach -r`) |
| `idle-status-watcher.service`  | Reads `/dev/input/event*`; asks logind whether the greeter is active; `chvt` to the status VT after `IDLE_TIMEOUT`, back to the greeter VT on input |
| `10-idle-status-noblank.conf`  | Xorg snippet in `/usr/share/X11/xorg.conf.d/` disabling screen saver and DPMS |

The watcher logs which device woke the screen:

```sh
journalctl -u idle-status-watcher
```

The X blanking settings take effect after the display manager restarts
(`sudo systemctl restart sddm`) or after a reboot.

## Build

Natively on Debian/Ubuntu (needs `dpkg-dev` and `debhelper`):

```sh
make deb          # → dist/idle-status-screen_<version>_all.deb
```

Or in a Debian container:

```sh
make deb-docker
```

GitHub Actions builds the package on every push and attaches it to the
release when a `v*` tag is pushed.

## Uninstall

```sh
sudo apt remove idle-status-screen     # or: apt purge, to also remove config
```

## Tested on

Raspberry Pi 5, Kali Linux (rolling, 2026.3), KDE Plasma + SDDM on Xorg,
720×1280 DSI touchscreen, kmscon 10.0.4, btop 1.4.7.

## License

[MIT](LICENSE)
