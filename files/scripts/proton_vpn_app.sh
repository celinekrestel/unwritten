#!/usr/bin/env bash
set -euo pipefail

repo="https://repo.protonvpn.com/fedora-$(rpm -E %fedora)-stable"
rel="protonvpn-stable-release-1.0.3-1.noarch.rpm"

# Proton's signing key, pinned by its fingerprint. The key, the release package and the app all
# come from Proton's server; the fingerprint is the one part that does not. If anything there
# were swapped, the build stops here instead of putting it into the image.
# Proton signs each Fedora release with its own key. After a Fedora upgrade, the build stops at
# this check: take the new fingerprint from Proton's Fedora install guide.
key_fpr="6929133BDE1CE1CFA9EDB286D84176F6844830D4"   # Proton Technologies AG (Fedora 44)

wget -q -O public_key.asc "${repo}/public_key.asc"
gnupg="$(mktemp -d)"
fpr="$(gpg --homedir "${gnupg}" --batch --quiet --no-autostart --show-keys --with-colons public_key.asc \
    | awk -F: '$1 == "pub" { getline; print $10 }')"
rm -rf "${gnupg}"
if [ "${fpr}" != "${key_fpr}" ]; then
    echo "Proton's key does not match the pinned fingerprint (got: ${fpr:-nothing})." >&2
    echo "After a Fedora upgrade: update key_fpr in files/scripts/proton_vpn_app.sh." >&2
    exit 1
fi
rpmkeys --import public_key.asc

# The release package adds Proton's repository. Its scripts run as root, so check its
# signature before installing it.
wget -q "${repo}/protonvpn-stable-release/${rel}"
rpmkeys --checksig --define '_pkgverify_level signature' "./${rel}"
dnf5 -y install "./${rel}"
rm -f "./${rel}"

# %post tries to enable the systemd unit, which fails in a container build.
# The unit is enabled in the recipe's systemd module instead.
# Weak dependencies are skipped: they are only bcc-tools, compiler-rt, libomp(-devel) and small Python extras (~45 MiB).
# gpgkey points dnf at the checked key. Otherwise, for a package signed with an unknown key,
# dnf would fetch and accept whatever key the server offers.
dnf5 -y install --setopt=tsflags=noscripts --setopt=install_weak_deps=False \
    --setopt=protonvpn-fedora-stable.gpgkey="file://${PWD}/public_key.asc" \
    proton-vpn-gnome-desktop
rm -f public_key.asc

rpm -q proton-vpn-gnome-desktop >/dev/null

# noscripts also skips the icon cache update that normally runs when a package adds an icon.
# Without it, GNOME cannot find Proton's icon (proton-vpn-logo in the hicolor theme): all files
# in the image share one timestamp, so the outdated cache still looks valid. Rebuild it here.
gtk-update-icon-cache --force /usr/share/icons/hicolor
