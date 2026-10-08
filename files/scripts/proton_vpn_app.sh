#!/usr/bin/env bash
set -euo pipefail

rel="protonvpn-stable-release-1.0.3-1.noarch.rpm"
wget -q "https://repo.protonvpn.com/fedora-$(rpm -E %fedora)-stable/protonvpn-stable-release/${rel}"
dnf5 -y install "./${rel}"
rm -f "./${rel}"

# %post tries to enable the systemd unit, which fails in a container build.
# The unit is enabled in the recipe's systemd module instead.
# Weak dependencies are skipped: they are only bcc-tools, compiler-rt, libomp(-devel) and small Python extras (~45 MiB).
dnf5 -y install --setopt=tsflags=noscripts --setopt=install_weak_deps=False proton-vpn-gnome-desktop

rpm -q proton-vpn-gnome-desktop >/dev/null

# noscripts also skips the icon cache update that normally runs when a package adds an icon.
# Without it, GNOME cannot find Proton's icon (proton-vpn-logo in the hicolor theme): all files
# in the image share one timestamp, so the outdated cache still looks valid. Rebuild it here.
gtk-update-icon-cache --force /usr/share/icons/hicolor
