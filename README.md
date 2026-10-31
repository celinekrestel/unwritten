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
- **Careful defaults:** no `sudo` ([Sudon't](https://vanillaos.org/nerd-info)), SSH server off, no network discovery, core dumps disabled, a few kernel hardening settings, firewall on, signed images.
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

> [!WARNING]
> Unpin the deployment again once Unwritten runs well. A pinned deployment stays in the boot menu with its old software and its old update settings. If it is ever booted, it can pull updates from wherever it used to point.

### 2. Rebase to Unwritten

First, download the image:

```shell
sudo bootc switch ghcr.io/celinekrestel/unwritten:latest
```

Silverblue does not know Unwritten's signing key yet, so it accepts the image without checking it. Nothing from the image runs before you reboot, so check it now. Show what was downloaded and copy the digest (`sha256:…`) from the "Staged image" entry:

```shell
sudo bootc status
```

Get the public key from this repository. If you already have a machine that runs Unwritten, use its `/etc/pki/containers/unwritten.pub` instead, so that the key does not come from the same place as the image:

```shell
curl -fsSL -o cosign.pub https://raw.githubusercontent.com/celinekrestel/unwritten/main/cosign.pub
```

Check the digest against the key. Podman runs cosign, so nothing has to be installed. Replace `sha256:…` with your digest:

```shell
podman run --rm -v "$PWD/cosign.pub:/cosign.pub:ro,z" ghcr.io/sigstore/cosign/cosign:v3.0.6 verify --key /cosign.pub ghcr.io/celinekrestel/unwritten@sha256:…
```

> [!CAUTION]
> If this check fails, do not reboot. Remove the download with `sudo rpm-ostree cleanup --pending`.

Then reboot. After rebooting, `sudo` will no longer be available. Use **`run0`** going forward.

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

### Network discovery

Unwritten doesn't look for printers, scanners or other devices on the network, and it doesn't announce itself there: avahi (mDNS) and LLMNR are off, the firewall only lets in DHCPv6, and the printing and discovery extras are excluded from the image. Printers, scanners and phones on USB work as usual, and a network printer can usually still be added by its address.

To turn discovery back on for one machine:

```shell
run0 systemctl enable --now avahi-daemon.socket avahi-daemon.service
run0 firewall-cmd --permanent --add-service=mdns
run0 firewall-cmd --reload
```

Names ending in `.local` also need `nss-mdns`, which the image excludes.

### VPN and kill switch

The VPN is a set of plain WireGuard profiles from Proton, managed by NetworkManager. They hold private keys, so they live in `/etc/NetworkManager/system-connections` on each machine, never in this repository. Each machine gets its own profiles, because two machines can't share a key at the same time.

The kill switch is on at every boot, before the network comes up. Without a tunnel there is no internet, on purpose. Its rules are in `/usr/lib/unwritten/killswitch.nft`, and they contain no server addresses.

```shell
killswitch             # Shows the state
killswitch off         # Until the next reboot, for example for a Wi-Fi login page
killswitch on
```

The **Kill Switch** launcher in the app grid does the same with one click. `fritz.box` doesn't resolve while the kill switch is on, but `http://192.168.178.1` works.

To add a profile, name the file after the rule the kill switch expects, like `pvpn-de.conf`. The file name becomes the interface name, which has to start with `pvpn-`, and the mark has to match:

```shell
nmcli connection import type wireguard file pvpn-de.conf
nmcli connection modify pvpn-de wireguard.fwmark 0xca6c ipv4.dns-priority -1500 ipv6.dns-priority -1500 connection.autoconnect no
```

Only one profile connects automatically, and only one should be active at a time: disconnect one before connecting the next.

To test the kill switch, keep the tunnel from connecting at boot. With a tunnel up, `curl` gets through it and the test below wrongly says `LEAK`.

```shell
nmcli connection modify pvpn-de connection.autoconnect no
systemctl reboot
```

Before logging in to GNOME, switch to a text console with Ctrl+Alt+F3, log in there and run this. It should say `blocked`:

```shell
curl -m 5 -sI https://example.com >/dev/null && echo "LEAK: traffic passes" || echo "blocked"
```

Then turn `connection.autoconnect` back on and connect with `nmcli connection up pvpn-de`.

> [!WARNING]
> A machine needs its profiles before it gets an image with the kill switch. Otherwise it boots without a tunnel and without internet, and `killswitch off` has to be run after every boot.

### Kernel hardening

`/usr/lib/sysctl.d/90-hardening.conf` sets five kernel options; the file explains each one. The one you may notice: attaching `gdb` or `strace` to a program that is already running needs `run0`.

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
