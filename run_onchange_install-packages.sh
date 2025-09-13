#!/bin/bash

# Bootstrap new Linux install with everything I have to download anyway

# Desired APT installs
declare -alr packages_to_check=( \
    "apt-transport-https" \
    "build-essential" \
    "ca-certificates" \
    "cmake" \
    "cppcheck" \
    "curl" \
    "git" \
    "gnupg2" \
    "lsb-release" \
    "ninja-build" \
    "nano" \
    "python-is-python3" \
    "python3" \
    "python3-pip" \
    "software-properties-common" \
    "wget" \
    )

# Will be populated with any missing packages from above
declare -a packages_to_install=()

# Helper functions

function is_pkg_installed {
    [ "$(dpkg-query -W --showformat='${Status}\n' "$1" | grep "install ok installed")" == "install ok installed" ];
}

function is_executable_available {
    [ -x "$(command -v "$1")" ];
}

function directory_exists {
    [ -d "$1" ];
}

function file_exists {
    [ -f "$1" ];
}

# --- Add PPAs for newer versions than available on main repository ---

# CMake from Kitware PPA
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

# --- Do install of apt packages ---

sudo apt update && sudo apt install -y "${packages_to_check[@]}"

# --- Install DEB packages ---

function cleanup {
  echo "Returning to original directory"
  cd - || exit
}

# Move to tmp and setup trap to go back
cd /tmp || exit
trap cleanup EXIT

# Chrome

if is_pkg_installed "google-chrome-stable"; then
    echo "OK: Chrome is installed"
else
    echo "MISSING: Google Chrome, installing now"
    curl -LOJR "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
    && sudo dpkg -i "$(find . -maxdepth 1 -name 'google-chrome*')"
fi

# AppImageLauncher

if is_executable_available "appimagelauncherd"; then
    echo "OK: AppImageLauncher is installed"
else
    echo "MISSING: AppImageLauncher, installing now"
    curl -LOJR "https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb" \
    && sudo dpkg -i "$(find . -maxdepth 1 -name 'appimagelauncher*')"
fi

# Uninstall Firefox

if is_pkg_installed "firefox"; then
    echo "NOTE: Found Firefox installation, removing now"
    sudo apt purge firefox
else
    echo "OK: Firefox not installed"
fi

# Install VS Code

if is_pkg_installed "code"; then
    echo "OK: VS Code is installed"
else
    echo "MISSING: VS Code, installing now"
    curl -LOJR "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
    && sudo dpkg -i "$(find . -maxdepth 1 -name 'code*')"
fi

# --- Setup global Python venv ---
if file_exists $HOME/.local/bin/activate; then
    echo "OK: global venv exists"
else
    echo "NOTE: Creating global venv for Python packages at ~/.local"
    python3 -m venv ~/.local
    # Activate now
    source ~/.local/bin/activate
fi

# Install uv
if is_executable_available "uv"; then
    echo "OK: uv is installed"
else
    echo "MISSING: astral/uv, installing now"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# --- Install misc tools ---

# Docker

if is_executable_available "docker"; then
    echo "OK: Docker Engine is installed"
else
    echo "MISSING: Docker Engine, installing now"
    curl -s https://get.docker.com | sudo sh
    getent group docker || sudo groupadd docker
    sudo usermod -aG docker "${USER}"
fi

# Kitty

if is_executable_available kitty; then
    echo "OK: Kitty is installed"
else
    echo "MISSING: Kitty, installing now"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    # Add to ~/.local/bin
    ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
    # Place the kitty.desktop file somewhere it can be found by the OS
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
    # If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
    cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
    # Update the paths to the kitty and its icon in the kitty desktop file(s)
    sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
    sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
    # Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
    echo 'kitty.desktop' > ~/.config/xdg-terminals.list
    # Update alternatives
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator ~/.local/kitty.app/bin/kitty 60
    # Kitty themes
    git clone --depth 1 https://github.com/dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
    ln -s ~/.config/kitty/kitty-themes/themes/ayu_mirage.conf ~/.config/kitty/theme.conf
    echo "include ./theme.conf" >> ~/.config/kitty/kitty.conf
fi

echo "Done!"