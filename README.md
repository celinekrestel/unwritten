# Unwritten &nbsp; [![bluebuild build badge](https://github.com/namoria/unwritten/actions/workflows/build.yml/badge.svg)](https://github.com/namoria/unwritten/actions/workflows/build.yml)

## About

Unwritten is a custom [bootc](https://containers.github.io/bootc/) image based on **fedora-bootc**, tailored to an AMD CPU/GPU desktop. It ships with GNOME and the CachyOS kernel. This project was inspired by the excellent [**VedaOS**](https://github.com/Lumaeris/vedaos) by **Lumaeris**.

> [!IMPORTANT]
> Unwritten uses **`run0`** instead of `sudo`. For certain commands, you will need to wrap them as **`run0 sh -c '$your_command$'`** — this is an SELinux constraint that may be resolved in a future release. You can also set SELinux to permissive mode (`setenforce 0`), though this is not recommended. Note that `sudo` remains available inside a distrobox environment.

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
sudo bootc switch ghcr.io/namoria/unwritten:latest
```

After rebooting, `sudo` will no longer be available. Use **`run0`** or **`run0 sh -c '$your_command$'`** going forward.

If you change your mind, you can roll back to your previous deployment:

```shell
# Only use this if you wish to revert:
run0 sh -c 'bootc rollback'
```

> [!NOTE]
> `bootc rollback` is only effective if you have **not** updated the system after rebasing. Once a second deployment from the new remote image source is pulled, rollback will not return you to the previous source.

Once you are satisfied, rebase to the signed image to complete the installation:

```shell
run0 sh -c 'bootc switch --enforce-container-sigpolicy ghcr.io/namoria/unwritten:latest'
```

### Verification

Unwritten images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). To verify the signature, download the `cosign.pub` file from this repository and run:

```shell
cosign verify --key cosign.pub ghcr.io/namoria/unwritten
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

## Variable Refresh Rate

[Refine](https://flathub.org/en-GB/apps/search?q=refine) lets you adjust advanced GNOME settings, including VRR.

1. Enable VRR in Refine.
2. Then enable it in the standard GNOME display settings.

> [!IMPORTANT]
> Once VRR is active, disable VSync in games — the two features conflict with each other.

---

## 3D Applications

### MangoHud

Install the Flatpak version of MangoHud:

```shell
flatpak install org.freedesktop.Platform.VulkanLayer.MangoHud
```

Then use [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal) to give Steam the following filesystem permission: `xdg-config/MangoHud:ro`.

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

- [VedaOS](https://github.com/Lumaeris/vedaos) — Special credit and thanks to Lumaeris!
- [Zirconium](https://github.com/zirconium-dev/zirconium)
- [XeniaOS](https://github.com/XeniaMeraki/XeniaOS)
- [solarpowered](https://github.com/askpng/solarpowered)
- [MizukiOS](https://github.com/koitorin/MizukiOS)
- [Entire Bootcrew project](https://github.com/bootcrew)
