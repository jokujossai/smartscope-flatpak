# SmartScope Flatpak

Unofficial Flatpak packaging of the [LabNation SmartScope](https://www.lab-nation.com/)
application (last Linux release, 0.15.1.0). The proprietary application is
**not** redistributed here: it is downloaded from lab-nation.com at install
time (flatpak `extra-data`), unpacked from the official `.deb`, and run with a
bundled Mono runtime on top of the freedesktop 25.08 runtime.

## Install from the Flatpak repository

The GitHub Actions workflow publishes a GPG-signed Flatpak repository to
GitHub Pages on every `smartscope-*` tag:

```sh
flatpak remote-add --if-not-exists smartscope-flatpak https://jokujossai.github.io/smartscope-flatpak/smartscope.flatpakrepo
flatpak install smartscope-flatpak com.lab_nation.SmartScope
```

Launchers installed: **SmartScope** (the scope UI), **SmartScope Server**
(share a USB-connected scope over the network), plus CLI entry points
`smartscope`, `smartscopeserver` (headless) and `smartscopeserverui` via
`flatpak run --command=...`.

## USB access

The app talks to the scope directly through libusb (`--device=all` is
granted). If the device is not found, your user needs read/write access to the
USB device node. Add a udev rule on the host (the SmartScope enumerates as
`04d8:f4b5`):

```sh
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="f4b5", MODE="0660", TAG+="uaccess"' \
  | sudo tee /etc/udev/rules.d/99-smartscope.rules
sudo udevadm control --reload && sudo udevadm trigger
```

## Build locally

```sh
git clone --recurse-submodules https://github.com/jokujossai/smartscope-flatpak.git
cd smartscope-flatpak
flatpak-builder --user --install-deps-from=flathub --install --force-clean \
  build-dir com.lab_nation.SmartScope/com.lab_nation.SmartScope.yaml
flatpak run com.lab_nation.SmartScope
```

## CI / repository publishing

`.github/workflows/flatpak-build.yaml` (same layout as
[claude-desktop-flatpak](https://github.com/kk-daniel/claude-desktop-flatpak)):

- Every push / PR builds the flatpak in the
  `ghcr.io/flathub-infra/flatpak-github-actions:freedesktop-25.08` container
  and uploads a `.flatpak` bundle artifact.
- Pushing a tag matching `smartscope-*` additionally restores the existing
  OSTree repo from GitHub Pages, commits the new build into it, signs it, and
  deploys it back to Pages together with a GitHub release carrying the bundle.

Required repository configuration:

| Kind     | Name              | Purpose                                  |
|----------|-------------------|------------------------------------------|
| secret   | `GPG_PRIVATE_KEY` | ASCII-armored signing key                 |
| secret   | `GPG_PASSPHRASE`  | Passphrase of the signing key             |
| variable | `GPG_KEY_ID`      | Key fingerprint used for `--gpg-sign`     |
| variable | `GPG_KEY_GREP`    | Keygrip used to preset the passphrase     |

GitHub Pages must be set to deploy from **GitHub Actions**.

## Notes

- The mono6 SDK extension does not ship `libgdiplus`, so it is built from
  source for Mono's `System.Drawing`.
- `libGLU` is built from [shared-modules](https://github.com/flathub/shared-modules)
  (OpenTK maps `glu32.dll` to it); SDL2, OpenAL and libusb are already part of
  the freedesktop 25.08 runtime.
- Recordings/exports are written to `~/SmartScope` (pre-granted via
  `--filesystem=~/SmartScope:create`).
- `mesa_glthread=false` is exported because Mesa's GL command marshalling
  thread deadlocks the app's old multithreaded Xlib/GLX rendering loop
  (black window after resize, window close never processed).
