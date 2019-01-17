#!/bin/bash

set -ex

# Environment variables.
export PACKAGER="https://travis-ci.org/${1}/builds/${2}"
export AURDEST="$(pwd)/src"

# Variables declaration.
declare -r pkgrepo="${1#*/}"
declare -a pkglist=()
declare -a pkgkeys=()
declare -a pkgdeps=()

# Remove comments or blank lines.
for pkgfile in "pkglist" "pkgkeys"; do
  sed -i -e "/\s*#.*/s/\s*#.*//" -e "/^\s*$/d" $pkgfile
done

# Load files.
mapfile pkglist < "pkglist"
mapfile pkgkeys < "pkgkeys"

# Create package list with dependencies.
mapfile pkgdeps < <(echo ${pkglist[@]} | aur depends -n)
pkgdeps+=("${pkglist[@]}")

# Remove packages from repository.
cd "bin"
while read pkgpackage; do
  repo-remove "${pkgrepo}.db.tar.gz" $pkgpackage
done < <(comm -23 <(pacman -Sl $pkgrepo | cut -d" " -f2 | sort) <(printf "%s" "${pkgdeps[@]}" | sort))
cd ".."

# Get package gpg keys.
for pkgkey in ${pkgkeys[@]}; do
  gpg --recv-keys --keyserver "hkp://ipv4.pool.sks-keyservers.net" $pkgkey
done

# Build outdated packages.
aur sync -d $pkgrepo --root "${HOME}/bin" -n ${pkglist[@]}

{ set +ex; } 2>/dev/null
