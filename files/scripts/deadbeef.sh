#!/bin/bash
sed -i 's/^Exec=deadbeef %F$/Exec=env GTK_THEME=Adwaita:dark deadbeef %F/' /usr/share/applications/deadbeef.desktop
rm -f /usr/lib64/deadbeef/mpris.so
