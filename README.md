# Unwritten &nbsp; [![bluebuild build badge](https://github.com/celinekrestel/unwritten/actions/workflows/build.yml/badge.svg)](https://github.com/celinekrestel/unwritten/actions/workflows/build.yml)

## About

Unwritten is a custom [bootc](https://containers.github.io/bootc/) image based on **fedora-bootc**, tailored to my AMD CPU/GPU desktop and my Lenovo IdeaPad 5 Pro 14ACN6 laptop. Both use the same image. It ships with the GNOME desktop.

> [!IMPORTANT]
> Unwritten uses **`run0`** instead of `sudo`. Because of a Fedora SELinux bug ([Fedora bug 2359828](https://bugzilla.redhat.com/show_bug.cgi?id=2359828)), `run0` cannot start programs that have their own SELinux domain, such as `bootc`, `dnf`, `rpm`, `journalctl`, `smartctl` or `groupadd`: they fail silently with exit code 203. Unwritten ships a small `run0` shell function (`/etc/profile.d/run0-selinux.sh`) that starts commands through `sh`, so **`run0 <command>`** just works. If you pass options to `run0` (for example `-u`), the function steps aside; use `run0 [options] sh -c 'exec "$@"' sh <command>` in that case. Note that `sudo` remains available inside a distrobox environment.

---

## Installation

### Prerequisites

Please install [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) before proceeding.

### 1. Pin a safe deployment

> [!TIP]
> It is good practice to pin a known-working deployment before rebasing to a new remote image source.

List your current deployments (index numbers are shown in round brackets):

```shell
rpm-ostree status -v
```

Pin a deployment by its index. For example, to pin index `0`:

```shell
sudo ostree admin pin 0
```

To unpin it later:

```shell
sudo ostree admin pin --unpin 0
```

> [!IMPORTANT]
> Index numbers shift with each new incoming deployment. Always verify the correct index before pinning.

### 2. Rebase to Unwritten

First, rebase to the unsigned image to receive the proper signing keys:

```shell
sudo bootc switch ghcr.io/celinekrestel/unwritten:latest
```

After rebooting, `sudo` will no longer be available. Use **`run0`** going forward.

If you change your mind, you can roll back to your previous deployment:

```shell
# Only use this if you wish to revert:
run0 bootc rollback
```

> [!NOTE]
> `bootc rollback` is only effective if you have **not** updated the system after rebasing. Once a second deployment from the new remote image source is pulled, rollback will not return you to the previous source.

Once you are satisfied, rebase to the signed image to complete the installation:

```shell
run0 bootc switch --enforce-container-sigpolicy ghcr.io/celinekrestel/unwritten:latest
```

### Verification

Unwritten images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). To verify the signature, download the `cosign.pub` file from this repository and run:

```shell
cosign verify --key cosign.pub ghcr.io/celinekrestel/unwritten
```

---

## Post-installation

### The Terminal

#### Z Shell

[Z Shell (zsh)](https://www.zsh.org/) offers several [advantages over Bash](https://linuxhint.com/differences_between_bash_zsh/). To switch to it without modifying system files such as `/etc/passwd`, configure it via your terminal profile:

In Ptyxis: **hamburger menu → Preferences → Profiles → ⋮ → Edit… → Shell section → enable _Use Custom Command_ → set it to `/usr/bin/zsh --login`**.

#### Atuin

[Atuin](https://github.com/atuinsh/atuin) provides enhanced shell history and is included in Unwritten. It is recommended to switch to zsh first, then add the following to `~/.zshrc`:

```shell
eval "$(atuin init zsh)"
```

#### Starship

[Starship](https://starship.rs) is a fast, customisable shell prompt written in Rust. To install it locally:

```shell
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
```

Then add the following to `~/.zshrc`:

```shell
export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"
```

---

## Notes

### Btrfs layout

Unwritten sets the kernel argument `rootflags=subvol=root,compress=zstd:1`. It expects Fedora's default btrfs layout with the subvolume `root`, so install Silverblue with the default partitioning (encryption is fine).

### Laptop: Lenovo IdeaPad 5 Pro 14ACN6

- **Graphics:** set *Graphics Device* to **UMA Graphics** in the UEFI/BIOS settings. The GeForce MX450 is then switched off by the firmware and does not appear in `lspci` at all; Unwritten ships no NVIDIA support. A BIOS update can reset this setting, so check it after every BIOS update.
- **External screens:** according to `lspci`, HDMI and USB-C belong to the AMD GPU (the MX450 is listed as a display-less "3D controller"), so they should keep working in UMA mode. Not tested yet.
- **Wi-Fi and Bluetooth:** MediaTek MT7921; its firmware (`mt7xxx-firmware`) is part of the image.

### Backups (btrbk)

The image ships the parts that are the same on every machine (in `/usr/lib/systemd/system/`):

| File | Purpose |
| --- | --- |
| `btrbk.timer.d/50-hourly.conf` | Run btrbk every hour instead of once a day. |
| `btrbk.service.d/40-require-config.conf` | Skip quietly on machines without `/etc/btrbk/btrbk.conf`. |
| `btrbk.service.d/60-low-priority.conf` | Lowest CPU and I/O priority, `btrbk run --verbose`. |

Each machine keeps its own parts in `/etc` (backed up in my dotfiles repo):

- `/etc/btrbk/btrbk.conf`
- `/etc/systemd/system/btrbk.service.d/50-wait-for-mounts.conf` with `RequiresMountsFor=` listing the `volume` and `target` paths from `btrbk.conf`, so btrbk waits until those disks are unlocked and mounted.

---

## Troubleshooting

### GDM does not start at boot

If the system hangs at:

```
[ OK ] Started gdm.service – GNOME Display Manager
```

switch to a TTY with `Ctrl + Alt + F2` (or `F3`–`F6`; add `Fn` if needed) and log in as your user. Then run:

```shell
run0 groupadd -r gdm
run0 systemctl restart gdm
```

You may need to run the second command twice, or perform a full reboot.

---

## Related Projects

- [VedaOS](https://github.com/Lumaeris/vedaos)
- [Zirconium](https://github.com/zirconium-dev/zirconium)
- [XeniaOS](https://github.com/XeniaMeraki/XeniaOS)
- [solarpowered](https://github.com/askpng/solarpowered)
- [MizukiOS](https://github.com/koitorin/MizukiOS)
- [Entire Bootcrew project](https://github.com/bootcrew)
