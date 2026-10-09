# Load oh-my-zsh
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git)
source "${ZSH}/oh-my-zsh.sh"

# UTF-8 charset
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Editor
export BUNDLER_EDITOR=nvim
export EDITOR=nvim

# Homebrew prefix: .zprofile sets it in a login shell; helper for the blocks below
_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$_brew_prefix/opt/nvm/nvm.sh" ] && \. "$_brew_prefix/opt/nvm/nvm.sh"  # This loads nvm
[ -s "$_brew_prefix/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$_brew_prefix/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Load rustup
export PATH="$_brew_prefix/opt/rustup/bin:$HOME/.cargo/bin:$PATH"

unset _brew_prefix

# Aliases
alias vim=nvim
alias buu="brew update && brew upgrade && brew cleanup"

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
