# Unwritten &nbsp; [![bluebuild build badge](https://github.com/celinekrestel/unwritten/actions/workflows/build.yml/badge.svg)](https://github.com/celinekrestel/unwritten/actions/workflows/build.yml)

*A lean, personal Fedora desktop built from fedora-bootc.*

## About

> *"Nothing is written."*
> — Lawrence in *Lawrence of Arabia* (1962)

**Unwritten is my personal, image-based Fedora desktop.** It starts from the minimal [fedora-bootc](https://containers.github.io/bootc/) base image, which has no desktop at all, and adds only what I actually use. GitHub builds it every day; my desktop and my laptop both run the same image, and every update can be rolled back.

The name comes from that scene. When Lawrence returns, Sherif Ali concedes: 'Truly, for some men nothing is written unless they write it.' Unwritten works the same way.

### Principles

- **Lean by design:** GNOME is assembled piece by piece instead of installed as a whole. Unwanted extras are kept out explicitly (see the exclude list in [`recipes/recipe.yml`](recipes/recipe.yml)).
- **Apps come from Flathub:** the image carries the system, Flathub carries the apps.
- **One image, two machines:** what is the same everywhere lives in the image; what is machine-specific lives in `/etc` and in my dotfiles.
- **Careful defaults:** no `sudo` ([Sudon't](https://vanillaos.org/nerd-info)), SSH server off, core dumps disabled, firewall on, signed images.
- **Updates on my terms:** automatic updates are disabled; I update with `run0 bootc upgrade`.

### At a glance

| | |
| --- | --- |
| Base | fedora-bootc 44 |
| Desktop | GNOME, plus niri with Noctalia as a second session |
| Apps | Flathub |
| Privileges | `run0` instead of `sudo` |
| Updates | manual, with rollback |
| Machines | my AMD desktop and a Lenovo IdeaPad 5 Pro 14ACN6 laptop |
| Build | daily with [BlueBuild](https://blue-build.org) on GitHub Actions, signed with cosign |

Unwritten is tailored to my hardware and habits. You are welcome to use it or borrow ideas, but it is not a general-purpose distribution.

> [!IMPORTANT]
> Unwritten uses **`run0`** instead of `sudo`. **`run0 <command>`** works as usual; see [run0 and SELinux](#run0-and-selinux) for the background. `sudo` remains available inside a distrobox environment.

---

## Installation

### Prerequisites

Please install [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) before proceeding:

- Use the **default (automatic) partitioning**; encryption is fine. Unwritten expects Fedora's default btrfs layout, see [Btrfs layout](#btrfs-layout).
- On my IdeaPad, I set **UMA Graphics** in the UEFI/BIOS first, see [Laptop](#laptop-lenovo-ideapad-5-pro-14acn6).

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

## Post-Installation

*After rebasing from Silverblue to Unwritten*

### Switch Flatpaks to Flathub

*Silverblue installs its default apps from Fedora's own Flatpak remote. Rebasing keeps them, because Flatpaks live in `/var`, outside the image. Unwritten takes all apps from Flathub and deliberately does not add Fedora's remote, so this one-time step moves the apps over and removes Fedora's remote. Firefox is not part of the image, so it needs installing as well.*

See what came from Fedora's remote:

```shell
flatpak list --app --columns=application,name,origin | grep -w fedora
```

Remove the apps you don't want (examples):

```shell
flatpak uninstall org.gnome.Maps org.gnome.Weather org.gnome.Contacts
```

Move the rest to Flathub (app data is kept):

```shell
for app in $(flatpak list --app --columns=application,origin | awk '$2 == "fedora" {print $1}'); do
    if flatpak remote-info flathub "$app" >/dev/null 2>&1; then
        flatpak uninstall -y "$app" && flatpak install -y flathub "$app"
    else
        echo "Not on Flathub, left alone: $app"
    fi
done
```

Remove the Fedora runtimes and the remote(s):

```shell
flatpak uninstall --unused
flatpak remotes
flatpak remote-delete fedora
flatpak remote-delete fedora-testing   # if listed above
```

Install a web browser:

```shell
flatpak install flathub org.mozilla.firefox
```

### The Terminal

*Unwritten ships zsh and Atuin, but leaves your login shell alone: `chsh` is removed on purpose, because if a shell set in `/etc/passwd` ever disappears from the image, logging in breaks. So the shell is set in the terminal profile instead, and everything else lives in your home folder. It survives every update and works the same on every machine.*

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

### run0 and SELinux

Because of a Fedora SELinux bug ([Fedora bug 2359828](https://bugzilla.redhat.com/show_bug.cgi?id=2359828)), `run0` cannot start programs that have their own SELinux domain, such as `bootc`, `dnf`, `rpm`, `journalctl`, `smartctl` or `groupadd`: they fail silently with exit code 203. Unwritten ships a small `run0` shell function (`/etc/profile.d/run0-selinux.sh`) that starts commands through `sh`, so `run0 <command>` just works. If you pass options to `run0` (for example `-u`), the function steps aside; use `run0 [options] sh -c 'exec "$@"' sh <command>` in that case.

### Btrfs layout

Unwritten sets the kernel argument `rootflags=subvol=root,compress=zstd:1`. It expects Fedora's default btrfs layout with the subvolume `root`, so install Silverblue with the default partitioning (encryption is fine).

### Laptop: Lenovo IdeaPad 5 Pro 14ACN6

- **Graphics:** set *Graphics Device* to **UMA Graphics** in the UEFI/BIOS settings. The GeForce MX450 is then switched off by the firmware and does not appear in `lspci` at all; Unwritten ships no NVIDIA support. A BIOS update can reset this setting, so check it after every BIOS update.
- **External screens:** HDMI and USB-C are wired to the AMD GPU (`lspci` lists the MX450 as a display-less "3D controller"), so UMA mode does not affect them.
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

*Seen once when rebasing from Silverblue, not reproduced since.*

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
