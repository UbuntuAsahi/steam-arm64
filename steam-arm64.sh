#!/bin/bash
#
# 2026 Andreas Schröder <andreas@kernelpanik.net>
#
# Based on https://gist.github.com/de-wim/ba440a84f65d49955a1be15a328bd8b3#file-steam-install-linux-aarch64-sh
# and https://www.reddit.com/r/AsahiLinux/comments/1tk6zoe/steam_native_arm_aarch64_on_asahi_linux_fedora/
#
# Adapted for Ubuntu Linux.

set -eo pipefail

export STEAMROOT=~/.local/share/Steam

if ! [ -e "${STEAMROOT}/steamrtarm64" ]; then
  echo Steam for arm64 is not installed yet. Installing...

  # skip download if file is already present
  if ! [ -e ~/Downloads/bins_linuxarm64_linuxarm64.zip ]; then
    LATEST_ZIPFILE=$(curl -s https://client-update.steamstatic.com/steam_client_publicbeta_linuxarm64 | grep -E '"file"\s+"bins_linuxarm64_linuxarm64.zip' | cut -d '"' -f4)
    LATEST_ZIPFILE_URL="https://client-update.steamstatic.com/${LATEST_ZIPFILE}"

    echo Downloading latest Steam aarch64 version from ${LATEST_ZIPFILE_URL}
    curl -o ~/Downloads/bins_linuxarm64_linuxarm64.zip ${LATEST_ZIPFILE_URL}
  fi

  echo Extracting
  mkdir -p ${STEAMROOT}
  unzip -o -qq ~/Downloads/bins_linuxarm64_linuxarm64.zip -d ${STEAMROOT}

  # Enable public beta
  mkdir -p ${STEAMROOT}/package && echo publicbeta > ${STEAMROOT}/package/beta

  chmod -R u+rwx ${STEAMROOT}/steamrtarm64/
  ln -sfn ${STEAMROOT}/steamrtarm64 ${STEAMROOT}/steamrt64
  touch ${STEAMROOT}/.steam-enable-steamrt64-client

  if ! [ -e /usr/lib/aarch64-linux-gnu/libvpx.so.6 ]; then
    sudo ln -s /usr/lib/aarch64-linux-gnu/libvpx.so.12 /usr/lib/aarch64-linux-gnu/libvpx.so.6
  fi

  mkdir -p ~/.steam
  ln -sf ${STEAMROOT} ~/.steam/steam
  ln -sf ${STEAMROOT} ~/.steam/root
  ln -sf ${STEAMROOT}/linuxarm64 ~/.steam/sdkarm64

  chmod +x "$STEAMROOT/steamrtarm64/steamwebhelper"
  chmod +x "$STEAMROOT/steamrtarm64/steamwebhelper.sh"
  chmod +x "$STEAMROOT/steamrtarm64/gldriverquery"
  chmod +x "$STEAMROOT/steamrtarm64/vulkandriverquery"
  chmod +x "$STEAMROOT/steamrtarm64/steamsysinfo"

  chmod +x "$STEAMROOT/steamrtarm64/steam"
  chmod +x ${STEAMROOT}/steam.sh

  echo Installing menu entry
  mkdir -p ~/.local/share/icons/hicolor/scalable/apps
  curl https://upload.wikimedia.org/wikipedia/commons/8/83/Steam_icon_logo.svg -o ~/.local/share/icons/hicolor/scalable/apps/steam.svg
  curl https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Steam_icon_logo.svg/960px-Steam_icon_logo.svg.png -o steam.png

  for size in 32x32 48x48 64x64 96x96 128x128 512x512; do
    mkdir -p ~/.local/share/icons/hicolor/${size}/apps
    convert steam.png -resize ${size} ~/.local/share/icons/hicolor/${size}/apps/steam.png
  done
  rm steam.png

  cat > ~/.local/share/applications/steam-arm64.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Steam (arm64)
Exec=muvm --env=LD_LIBRARY_PATH="${STEAMROOT}/steamrtarm64/:${LD_LIBRARY_PATH}" ${STEAMROOT}/steamrtarm64/steam -noverifyfiles
Icon=steam
Terminal=false
Categories=Game;
EOF

fi

PROTON_VERSION="GE-Proton11-11"

# GE-Proton11 already includes FEX and arm64 build of Proton
if ! [ -e ~/.steam/steam/compatibilitytools.d/${PROTON_VERSION}-aarch64/ ]; then
  echo Installing ${PROTON_VERSION}-aarch64
  mkdir -p ~/.steam/steam/compatibilitytools.d

  # skip download if file is already present
  if ! [ -e ~/Downloads/${PROTON_VERSION}-aarch64.tar.gz ]; then
    curl --follow -o ~/Downloads/${PROTON_VERSION}-aarch64.tar.gz https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}-aarch64.tar.gz
  fi
  tar -xf ~/Downloads/${PROTON_VERSION}-aarch64.tar.gz -C ~/.steam/steam/compatibilitytools.d/ 
fi

# Steam Runtime 4.0
if ! [ -e "${STEAMROOT}/steamapps/appmanifest_4185400.acf" ]; then
  echo Installing Steam Runtime 4.0
  # workaround for compat dependency checker
  sed -i 's#"4185400"#""#g' ~/.steam/steam/compatibilitytools.d/${PROTON_VERSION}-aarch64/toolmanifest.vdf
  muvm --env=LD_LIBRARY_PATH="${STEAMROOT}/steamrtarm64/:${LD_LIBRARY_PATH}" ${STEAMROOT}/steamrtarm64/steam -noverifyfiles steam://install/4185400
fi

echo muvm -ti --env=LD_LIBRARY_PATH="${STEAMROOT}/steamrtarm64/:${LD_LIBRARY_PATH}" ${STEAMROOT}/steamrtarm64/steam -noverifyfiles
muvm -ti --env=LD_LIBRARY_PATH="${STEAMROOT}/steamrtarm64/:${LD_LIBRARY_PATH}" ${STEAMROOT}/steamrtarm64/steam -noverifyfiles
