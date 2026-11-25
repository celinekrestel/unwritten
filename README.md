# Unwritten &nbsp; [![bluebuild build badge](https://github.com/celinekrestel/unwritten/actions/workflows/build.yml/badge.svg)](https://github.com/celinekrestel/unwritten/actions/workflows/build.yml)


Unwritten is a personal Fedora desktop built from [fedora-bootc](https://containers.github.io/bootc/). 

The name comes from *Lawrence of Arabia* (1962).
> *Nothing is written.*
> — Lawrence

When Lawrence returns, Sherif Ali concedes: 'Truly, for some men nothing is written unless they write it.'

## Features

| Component | Setup |
| :--- | :--- |
| 🪶 Lean Base | **1,012 RPM packages** |
| 🍦 Desktop | ![GNOME](https://img.shields.io/badge/GNOME-%234A86CF.svg?style=for-the-badge&logo=gnome&logoColor=white) |
| 📦 GUI Apps | ![Flatpak](https://img.shields.io/badge/flatpak-%234A90D9.svg?style=for-the-badge&logo=flatpak&logoColor=white) |
| 🍺 CLI Tools | ![Homebrew](https://img.shields.io/badge/homebrew-%23FBB040.svg?style=for-the-badge&logo=homebrew&logoColor=black) |
| 🐳 Containers | **Distrobox** |
| 🛡️ Privilege Escalation | **No `sudo` — using `run0`** ([Sudon't](https://vanillaos.org/nerd-info)) |
| 🔌 Network | **Built-in internet kill switch** |
| ⚓ Updates | **Manual only** (no automatic updates) |
| 🕊️ Graphics | ![AMD](https://img.shields.io/badge/amd-%23ED1C24.svg?style=for-the-badge&logo=amd&logoColor=white) |

> [!Note]
> The internet kill switch is enabled by default. Run `killswitch off` to disable it.

---

## 💿 Installation

### 1. ⬇️ Install Silverblue

Install [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/).

Use the **default (automatic) partitioning**; encryption is optional, but recommended. Unwritten expects Fedora's default btrfs layout, see [Btrfs layout](#btrfs-layout).

Import your **WireGuard VPN profiles** and let one of them connect automatically. Unwritten's kill switch blocks the internet without a tunnel, see [Add a profile](#add-a-profile).

### 2. 📌 Pin a safe deployment

List your current deployments:

```shell
rpm-ostree status -v
```

Pin a deployment by its index number. For example, to pin index `0`:

```shell
sudo ostree admin pin 0
```

> [!Note]
> Index numbers shift with each new incoming deployment.

> [!Important]
> Unpin the deployment again once Unwritten runs well, see [step 4](#4-unpin-the-safe-deployment).

### 3. 🔄 Rebase to Unwritten

Download the image:

```shell
sudo bootc switch ghcr.io/celinekrestel/unwritten:latest
```

> [!Important]
> Silverblue does not know Unwritten's signing key yet, so it accepts the image without checking it. Nothing from the image runs before you reboot, so check it now.

Show what was downloaded and copy the digest (`sha256:…`) from the 'Staged image' entry:

```shell
sudo bootc status
```

Get the public key from this repository (if another machine that runs Unwritten is available, use its `/etc/pki/containers/unwritten.pub` instead, so that the key does not come from the same place as the image):

```shell
curl -fsSL -o cosign.pub https://raw.githubusercontent.com/celinekrestel/unwritten/main/cosign.pub
```

Check the digest against the key. Podman runs [cosign](https://github.com/sigstore/cosign), so nothing has to be installed. Replace `sha256:…` with your digest:

```shell
podman run --rm -v "$PWD/cosign.pub:/cosign.pub:ro,z" ghcr.io/sigstore/cosign/cosign:v3.0.6 verify --key /cosign.pub ghcr.io/celinekrestel/unwritten@sha256:…
```

> [!Caution]
> If this check fails, do not reboot. Remove the download with `sudo rpm-ostree cleanup --pending`.

If everything is in order, reboot:

```shell
systemctl reboot
```

> [!Important]
> After the reboot, use `run0` instead of `sudo`. If no VPN tunnel comes up, the kill switch blocks the internet: run `killswitch off` until you have added your profiles, see [VPN and kill switch](#vpn-and-kill-switch).

To go back to Silverblue:

```shell
run0 bootc rollback
```

> [!Note]
> `bootc rollback` only returns to Silverblue as long as you haven't updated or rebased again. The deployment pinned in step 1 stays in the boot menu either way.

### 4. 🔐 Rebase to the signed image

Once Unwritten runs well, rebase to the signed image:

```shell
run0 bootc switch --enforce-container-sigpolicy ghcr.io/celinekrestel/unwritten:latest
```

> [!Note]
> From now on, `bootc` checks the signature of every update.

### 5. 🧹 Unpin the safe deployment

Look up the deployment you pinned in step 1. It is marked `Pinned: yes`, and its index has shifted since:

```shell
rpm-ostree status -v
```

Unpin it by its index number. For example, to unpin index `2`:

```shell
run0 ostree admin pin --unpin 2
```

---

## 🔧 Post-Installation

### 📦 Flatpak

We move all Flatpaks to `user` and Flathub.

**Why?**

> [!note]
>
> Flatpak's root helper for system-wide installs (`flatpak-system-helper`) is masked.

**How?**

1. Close running apps first, including apps running in the background. 
2. Move the Flatpaks, once per machine:

```shell
flatpak-to-user
```

> [!Note]
> `flatpak-to-user` shows what it would move and asks first. It downloads every app and runtime again from Flathub, copies pins and masks, and removes the system copies; `run0` asks for your password once for that. App data in `~/.var/app` and your overrides stay where they are, and an app that Flathub doesn't have stays in the system installation. Running it again is safe.

3. Remove the apps you don't want, for example:

```shell
flatpak uninstall org.gnome.Maps org.gnome.Weather org.gnome.Contacts
```

4. Install a web browser, since the image has none. For example, Firefox:

```shell
flatpak install flathub org.mozilla.firefox
```

### 🍺 Homebrew

We set up Homebrew.

**Why?**

[Homebrew](https://brew.sh) provides command-line tools that don't belong in the image, such as ImageMagick or ClamAV. The binaries will be installed in a directory outside the image: `/home/linuxbrew/.linuxbrew` (which is `/var/home/linuxbrew/.linuxbrew`). After the setup, no root is needed; homebrew is not affected by bootc updates or rollbacks. The tools are not sandboxed: they run with user rights, like anything else you start in the terminal.

**How?**

Set it up once per machine:

```shell
run0 install -d -o "$USER" -g "$USER" /var/home/linuxbrew
git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew
mkdir /home/linuxbrew/.linuxbrew/bin
ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew
brew update
```

> [!Note]
> These are the steps of Homebrew's installer, without running a script from the internet. `/etc/profile.d/homebrew.sh` appends Homebrew's folders to the end of `PATH`, so a Homebrew package never takes the place of a system command, and it turns Homebrew's usage statistics off.

To **install** a tool:

```shell
brew install imagemagick
```

To **update** everything:

```shell
brew update && brew upgrade
```

> [!Note]
> Prebuilt packages don't need a compiler. If a formula has to be built, `brew install gcc` brings one.

To **remove** Homebrew completely:

```shell
rm -rf /var/home/linuxbrew/.linuxbrew ~/.cache/Homebrew
run0 rmdir /var/home/linuxbrew
```

### 🐚 The shell

Unwritten ships zsh and Atuin, but leaves your login shell alone. The shell is set in the terminal profile instead, and everything else lives in your home folder, so it survives every update and works the same on every machine.

> [!Note]
> `chsh` is removed on purpose: if a shell set in `/etc/passwd` ever disappears from the image, logging in breaks.

#### Z Shell

[Z Shell (zsh)](https://www.zsh.org/) offers several [advantages over Bash](https://linuxhint.com/differences_between_bash_zsh/). Set it as the shell of your terminal profile. In Ptyxis, open **hamburger menu → Preferences → Profiles → ⋮ → Edit…**, enable **Use Custom Command** in the **Shell** section and set it to:

```text
/usr/bin/zsh --login
```

#### Atuin

[Atuin](https://github.com/atuinsh/atuin) provides enhanced shell history and is included in Unwritten. With zsh set up, add this to `~/.zshrc`:

```shell
eval "$(atuin init zsh)"
```

#### Starship

[Starship](https://starship.rs) is a fast, customisable shell prompt written in Rust. Install it with [Homebrew](#-homebrew):

```shell
brew install starship
```

Then add this to `~/.zshrc`:

```shell
eval "$(starship init zsh)"
```

---

## 📝 Notes

### run0 and SELinux

Because of a Fedora SELinux bug ([Fedora bug 2359828](https://bugzilla.redhat.com/show_bug.cgi?id=2359828)), `run0` cannot start programs that have their own SELinux domain, such as `bootc`, `dnf`, `rpm`, `journalctl`, `smartctl` or `groupadd`: they fail silently with exit code 203. Unwritten ships a small `run0` shell function (`/etc/profile.d/run0-selinux.sh`) that starts commands through `sh`, so `run0 <command>` just works.

If you pass options to `run0` (for example `-u`), the function steps aside. Start the command through `sh` yourself:

```shell
run0 [options] sh -c 'exec "$@"' sh <command>
```

### Btrfs layout

Unwritten sets the kernel argument `rootflags=subvol=root,compress=zstd:1`. It expects Fedora's default btrfs layout with the subvolume `root`, so install Silverblue with the default partitioning (encryption is fine).

### Network discovery

Unwritten doesn't look for printers, scanners or other devices on the network, and it doesn't announce itself there: avahi (mDNS) and LLMNR are off, the firewall only lets in DHCPv6, and the printing and discovery extras are excluded from the image. Printers, scanners and phones on USB work as usual, and a network printer can usually still be added by its address.

To turn discovery back on for one machine:

```shell
run0 systemctl enable --now avahi-daemon.socket avahi-daemon.service
run0 firewall-cmd --permanent --add-service=mdns
run0 firewall-cmd --reload
```

> [!Note]
> Names ending in `.local` also need `nss-mdns`, which the image excludes.

### VPN and kill switch

The VPN is a set of plain WireGuard profiles from Proton, managed by NetworkManager. They hold private keys, so they live in `/etc/NetworkManager/system-connections` on each machine, never in this repository. Each machine gets its own profiles, because two machines can't share a key at the same time.

The kill switch is on at every boot, before the network comes up. Without a tunnel there is no internet, on purpose. Its rules are in `/usr/lib/unwritten/killswitch.nft`, and they contain no server addresses.

> [!Important]
> A machine needs its profiles before it gets an image with the kill switch. Otherwise it boots without a tunnel and without internet, and `killswitch off` has to be run after every boot.

To show the state:

```shell
killswitch
```

To turn it off until the next reboot, for example for a Wi-Fi login page:

```shell
killswitch off
```

To turn it back on:

```shell
killswitch on
```

The **Kill Switch** launcher in the app grid switches it on and off with one click.

> [!Note]
> Local names such as `fritz.box` don't resolve while the kill switch is on, but local addresses such as `http://192.168.178.1` still work.

#### Add a profile

Name the WireGuard file like `pvpn-de.conf`.

> [!Important]
> The file name becomes the interface name, which has to start with `pvpn-`, and the mark has to be `0xca6c`. Let only one profile connect automatically, and keep only one active at a time: disconnect one before connecting the next.

Import it and set the mark:

```shell
nmcli connection import type wireguard file pvpn-de.conf
nmcli connection modify pvpn-de wireguard.fwmark 0xca6c ipv4.dns-priority -1500 ipv6.dns-priority -1500 connection.autoconnect no
```

To let it connect automatically:

```shell
nmcli connection modify pvpn-de connection.autoconnect yes
```

#### Test the kill switch

Keep the tunnel from connecting at boot, then reboot:

```shell
nmcli connection modify pvpn-de connection.autoconnect no
systemctl reboot
```

> [!Note]
> With a tunnel up, `curl` gets through it and the test below wrongly says `LEAK`.

Before logging in to GNOME, switch to a text console with <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd>, log in there and run this. It should say `blocked`:

```shell
curl -m 5 -sI https://example.com >/dev/null && echo "LEAK: traffic passes" || echo "blocked"
```

Then let the profile connect automatically again, and connect it:

```shell
nmcli connection modify pvpn-de connection.autoconnect yes
nmcli connection up pvpn-de
```

### Kernel hardening

`/usr/lib/sysctl.d/90-hardening.conf` sets five kernel options; the file explains each one. The one you may notice: attaching `gdb` or `strace` to a program that is already running needs `run0`.

### Backups (btrbk)

The image ships the parts that are the same on every machine (in `/usr/lib/systemd/system/`):

| File | Purpose |
| --- | --- |
| `btrbk.timer.d/50-hourly.conf` | Run btrbk every hour instead of once a day. |
| `btrbk.service.d/40-require-config.conf` | Skip quietly on machines without `/etc/btrbk/btrbk.conf`. |
| `btrbk.service.d/60-low-priority.conf` | Lowest CPU and I/O priority, `btrbk run --verbose`. |

Each machine keeps its own parts in `/etc`:

- `/etc/btrbk/btrbk.conf`
- `/etc/systemd/system/btrbk.service.d/50-wait-for-mounts.conf` with `RequiresMountsFor=` listing the `volume` and `target` paths from `btrbk.conf`, so btrbk waits until those disks are unlocked and mounted.

---

## Troubleshooting

### GDM does not start at boot

> [!Note]
> Seen once when rebasing from Silverblue, not reproduced since.

The system hangs at:

```text
[ OK ] Started gdm.service – GNOME Display Manager
```

Switch to a text console with <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F2</kbd> (or <kbd>F3</kbd> to <kbd>F6</kbd>; add <kbd>Fn</kbd> if needed) and log in as your user. Then run:

```shell
run0 groupadd -r gdm
run0 systemctl restart gdm
```

If GDM still doesn't start, run the second command again or reboot.

---

## Related Projects

- [VedaOS](https://github.com/Lumaeris/vedaos)
- [Zirconium](https://github.com/zirconium-dev/zirconium)
- [XeniaOS](https://github.com/XeniaMeraki/XeniaOS)
- [solarpowered](https://github.com/askpng/solarpowered)
- [MizukiOS](https://github.com/koitorin/MizukiOS)
- [Entire Bootcrew project](https://github.com/bootcrew)
