# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Фикс P10k warning
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Тема
ZSH_THEME="powerlevel10k/powerlevel10k"

# Плагины (убери их из plugins=(), так как source ручной)
plugins=(
    git
    zoxide
)

source $ZSH/oh-my-zsh.sh

# P10k кастом
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# User config
export EDITOR='nvim'
export PATH="$HOME/bin:$PATH"

# Aliases
alias ls='eza --icons'
alias cat='bat --theme=base16'
alias cd='z'

# Zoxide init
eval "$(zoxide init zsh)"

# Фикс плагинов: Source AUR версии (Arch-way)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
