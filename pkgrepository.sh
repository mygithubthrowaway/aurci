#!/bin/bash

set -ex

# Variables declaration.
declare -r pkgslug="$1"
declare -r pkgtag="$2"
declare -r pkgrepo="${1#*/}"

# Download or create repository database.
cd "bin"
if curl -L -O -O -f "https://github.com/${pkgslug}/releases/download/${pkgtag}/${pkgrepo}.{db,files}.tar.gz"; then
  ln -fs "${pkgrepo}.db.tar.gz" "${pkgrepo}.db"
  ln -fs "${pkgrepo}.files.tar.gz" "${pkgrepo}.files"
else
  rm -f "${pkgrepo}.db.tar.gz" "${pkgrepo}.files.tar.gz"
  repo-add "${pkgrepo}.db.tar.gz"
fi
cd ".."

# Set up gpg options
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"
export GPG_TTY=$(tty)
echo 'auto-key-retrieve:0:1' | gpgconf --change-options gpg
echo 'keyserver:0:"hkp%3a//na.pool.sks-keyservers.net' | gpgconf --change-options dirmngr
ls -lhart
if [[ -r mygithubthrowaway-key.gpg ]]; then
  echo "step1"
  gpg --batch --import mygithubthrowaway-key.gpg
  echo "step2"
  gpg --batch --export --armor | sudo tee /usr/share/pacman/keyrings/mygithubthrowaway-key.gpg >/dev/null
  echo "step3"
  gpg -k --with-colons | grep -m1 '^fpr' | cut -d: -f10 | sed 's/$/:4:/' | sudo tee /usr/share/pacman/keyrings/pkgbuild-trusted >/dev/null
  echo "step4"
  sudo pacman-key --populate pkgbuild
  SIGN_PKG=--sign
fi

# Enable multilib repository.
sudo sed -i -e "/\[multilib\]/,/Include/s/^#//" "/etc/pacman.conf"

# Add configuration for repository.
sudo tee -a "/etc/pacman.d/${pkgrepo}" << EOF
[options]
CacheDir = /var/cache/pacman/pkg
CacheDir = $(pwd)/bin
CleanMethod = KeepCurrent

[${pkgrepo}]
SigLevel = Optional TrustAll
Server = file://$(pwd)/bin
Server = https://github.com/${pkgslug}/releases/download/${pkgtag}
EOF

# Add repository aurutilsci and incude this repository.
sudo tee -a "/etc/pacman.conf" << EOF

[aurutilsci]
SigLevel = Optional TrustAll
Server = https://github.com/localnet/aurutilsci/releases/download/repository

Include = /etc/pacman.d/${pkgrepo}
EOF

# Sync repositories and install aurutils.
sudo pacman -Sy --noconfirm aurutils

{ set +ex; } 2>/dev/null
