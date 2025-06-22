#!/usr/bin/env bash
set -euo pipefail

# 1. Variables à personnaliser
DOTFILES_REPO="git@github.com:linventif/dotfiles.git"

# 2. Mise à jour et installation des paquets APT
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
  zsh \
  git \
  curl \
  fzf \
  direnv \
  snapd

# 3. Installer chezmoi via snap
sudo snap install chezmoi --classic

# 4. Installer Oh My Zsh (sans prompt interactif)
export ZSH="$HOME/.oh-my-zsh"
RUNZSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 5. Cloner et appliquer tes dotfiles
chezmoi init "${DOTFILES_REPO}"
chezmoi apply

# 6. Installer les plugins Zsh
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
git clone https://github.com/paulirish/git-open \
  "${ZSH_CUSTOM}/plugins/git-open"
git clone https://github.com/olivierverdier/zsh-git-prompt \
  "${ZSH_CUSTOM}/plugins/zsh-git-prompt"
git clone https://github.com/Aloxaf/fzf-tab \
  "${ZSH_CUSTOM}/plugins/fzf-tab"

# 7. Passer Zsh en shell par défaut
chsh -s "$(which zsh)" || echo "⚠️ Impossible de changer le shell, relance manuellement : chsh -s $(which zsh)"

# 8. Configurer Ctrl+Alt+T pour ouvrir GNOME Terminal en Zsh
#    (désactive d’abord le binding par défaut, puis crée un custom0)
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
# Désactive le raccourci terminal par défaut
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]"
# Récupère la liste actuelle, y ajoute custom0 si besoin
current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
  new_list="['$CUSTOM_PATH']"
else
  new_list=$(echo "$current" | sed -e "s/]$/, '$CUSTOM_PATH']/")
fi
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
# Définit le custom0
schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH"
gsettings set "$schema" name    'Terminal — Zsh'
gsettings set "$schema" command 'gnome-terminal -- zsh'
gsettings set "$schema" binding '<Primary><Alt>T'

# 9. Message de fin
echo
echo "✅ Bootstrap terminé !"
echo "  – Déconnecte-toi / reconnecte-toi ou relance ton terminal pour basculer sur Zsh."
echo "  – Ctrl+Alt+T ouvrira maintenant GNOME Terminal en Zsh."
echo "  – Tes dotfiles ont été appliqués par chezmoi depuis ${DOTFILES_REPO}."
