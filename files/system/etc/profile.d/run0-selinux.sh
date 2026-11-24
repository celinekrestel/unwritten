# Work around a Fedora SELinux bug in run0: https://bugzilla.redhat.com/show_bug.cgi?id=2359828
#
# run0 starts the command in root's unconfined_t context (pam_selinux sets it explicitly). Programs
# with their own SELinux domain (bootc, dnf/rpm, journalctl, smartctl, groupadd, ...) may not be
# started from that context. They fail with exit code 203, and because run0 is always quiet,
# without any message.
# Starting them through sh lets SELinux switch into their domain as usual, just like with sudo.
#
# Only 'run0 <command> [args...]' is wrapped. Plain 'run0' (root shell) and 'run0 --option ...'
# call the real run0 unchanged; with options, use: run0 [options] sh -c 'exec "$@"' sh <command>
run0() {
    if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
        command run0 "$@"
    else
        command run0 sh -c 'exec "$@"' sh "$@"
    fi
}
