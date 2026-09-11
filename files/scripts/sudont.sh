#!/bin/bash
# For more info on removing `sudo`, see the « Sudon’t » approach of Vanilla OS.
set -ouex pipefail

dnf5 remove -y --setopt=protected_packages= sudo sudo-python-plugin
rm -f /usr/bin/sudo /usr/bin/pkexec /usr/bin/su

dnf5 clean all

# Comment:
# polkit itself stays, and should. polkitd is what authorizes run0, and it's a root daemon rather than a SUID binary. Removing /usr/bin/pkexec removes the SUID client without touching the authorization machinery. GNOME's escalation prompts go through D-Bus and keep working.
