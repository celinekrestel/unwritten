# Homebrew: command-line tools outside the image, in /home/linuxbrew/.linuxbrew (see the README,
# 'Homebrew'). Its folders go to the end of PATH, so a Homebrew package never takes the place of a
# system command; 'brew shellenv' would put them first. Set even before Homebrew is installed, so
# brew works right after the setup, without logging in again.
case ":${PATH}:" in
    *:/home/linuxbrew/.linuxbrew/bin:*) ;;
    *) PATH="${PATH}:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin" ;;
esac
export PATH

# Homebrew sends usage statistics unless this is set.
export HOMEBREW_NO_ANALYTICS=1
