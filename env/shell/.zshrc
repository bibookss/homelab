# Homelab Zsh Configuration
# Source this file in your main ~/.zshrc

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Aliases for homelab services
alias docker-ps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias docker-logs='docker logs -f'
alias docker-restart='docker restart'

# Docker Compose shortcuts
alias dc='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dclogs='docker compose logs -f'
alias dcrestart='docker compose restart'

# Homelab service shortcuts
alias homelab-postgres='cd ~/Projects/homelab/docker/postgres && docker compose'
alias homelab-minio='cd ~/Projects/homelab/docker/minio && docker compose'
alias homelab-airflow='cd ~/Projects/homelab/docker/airflow && docker compose'
alias homelab-qbittorrent='cd ~/Projects/homelab/docker/qbittorrent && docker compose'
alias homelab-portainer='cd ~/Projects/homelab/docker/portainer && docker compose'

# Path additions
export PATH="$HOME/.local/bin:$PATH"

