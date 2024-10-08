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

# --- Add PPAs for newer versions than available on main repository ---

# AppImageLauncher
add-apt-repository ppa:appimagelauncher-team/stable

# CMake from Kitware PPA
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

# --- Check for missing APT packages ---

for pkg in "${packages_to_check[@]}"; do
    if is_pkg_installed "$pkg"; then
        echo "OK: ${pkg} is installed."
    else
        echo "MISSING: ${pkg} is not installed, adding to install list"
        packages_to_install+=("${pkg}")
    fi
done

# --- Do install of missing APT packages ---

if [ ${#packages_to_install[@]} -eq 0 ]; then
    echo "NOTE: Nothing to install, yay!"
else
    sudo apt update \
    && sudo apt install -y "${packages_to_install[@]}"
fi

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

# --- Install pip packages ---

pip3 install cmake-init codespell conan black

# Add to PATH via bashrc
echo "NOTE: Adding '~/.local/bin' to PATH via bashrc"
echo >> ~/.bashrc
echo "# Extend path for Python" >> ~/.bashrc
echo 'export PATH="${PATH}:$HOME/.local/bin"' >> ~/.bashrc

# --- Install misc tools ---

# Docker

if is_executable_available "docker"; then
    echo "OK: Docker Engine is installed"
else
    echo "MISSING: Docker Engine, installing now"
    curl -s https://get.docker.com | sudo sh
    getent group docker || sudo groupadd docker
    sudo usermod -aG docker "${USER}"
    newgrp docker
fi

# LLVM tools

# Register all LLVM tools
# From: https://gist.github.com/junkdog/70231d6953592cd6f27def59fe19e50d

function register_clang_version {
    local version=$1
    local priority=$2

    sudo update-alternatives \
        --verbose \
        --install /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-"${version}" "${priority}" \
        --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-"${version}" \
        --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-"${version}" \
        --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-"${version}" \
        --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-"${version}" \
        --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-"${version}" \
        --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-"${version}" \
        --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-"${version}" \
        --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-"${version}" \
        --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-"${version}" \
        --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-"${version}" \
        --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-"${version}" \
        --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-"${version}" \
        --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-"${version}" \
        --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-"${version}" \
        --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-"${version}" \
        --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-"${version}" \
        --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-"${version}" \
        --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-"${version}" \
        --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-"${version}" \
        --slave   /usr/bin/llvm-objcopy      llvm-objcopy     /usr/bin/llvm-objcopy-"${version}" \
        --slave   /usr/bin/llvm-strip        llvm-strip       /usr/bin/llvm-strip-"${version}"

    sudo update-alternatives \
        --verbose \
        --install /usr/bin/clang                 clang                 /usr/bin/clang-"${version}" "${priority}" \
        --slave   /usr/bin/clang++               clang++               /usr/bin/clang++-"${version}"  \
        --slave   /usr/bin/asan_symbolize        asan_symbolize        /usr/bin/asan_symbolize-"${version}" \
        --slave   /usr/bin/clang-cpp             clang-cpp             /usr/bin/clang-cpp-"${version}" \
        --slave   /usr/bin/clang-check           clang-check           /usr/bin/clang-check-"${version}" \
        --slave   /usr/bin/clang-cl              clang-cl              /usr/bin/clang-cl-"${version}" \
        --slave   /usr/bin/ld.lld                ld.lld                /usr/bin/ld.lld-"${version}" \
        --slave   /usr/bin/lld                   lld                   /usr/bin/lld-"${version}" \
        --slave   /usr/bin/lld-link              lld-link              /usr/bin/lld-link-"${version}" \
        --slave   /usr/bin/clang-format          clang-format          /usr/bin/clang-format-"${version}" \
        --slave   /usr/bin/clang-format-diff     clang-format-diff     /usr/bin/clang-format-diff-"${version}" \
        --slave   /usr/bin/clang-include-fixer   clang-include-fixer   /usr/bin/clang-include-fixer-"${version}" \
        --slave   /usr/bin/clang-offload-bundler clang-offload-bundler /usr/bin/clang-offload-bundler-"${version}" \
        --slave   /usr/bin/clang-query           clang-query           /usr/bin/clang-query-"${version}" \
        --slave   /usr/bin/clang-rename          clang-rename          /usr/bin/clang-rename-"${version}" \
        --slave   /usr/bin/clang-reorder-fields  clang-reorder-fields  /usr/bin/clang-reorder-fields-"${version}" \
        --slave   /usr/bin/clang-tidy            clang-tidy            /usr/bin/clang-tidy-"${version}" \
        --slave   /usr/bin/lldb                  lldb                  /usr/bin/lldb-"${version}" \
        --slave   /usr/bin/lldb-server           lldb-server           /usr/bin/lldb-server-"${version}" \
        --slave   /usr/bin/clangd                clangd                /usr/bin/clangd-"${version}"
}

if is_executable_available "clang"; then
    echo "OK: LLVM tools are installed"
else
    echo "MISSING: LLVM tools, installing now"
    # curl -s https://apt.llvm.org/llvm.sh | sudo bash /dev/stdin all
    # TODO: Detect version installed and update this
    echo "NOTE: Registering LLVM tools with update-alternatives"
    # register_clang_version 15 100
fi

# VS Code Extensions

declare -alr extensions_to_install=( \
    "eamodio.gitlens" \
    "ms-azuretools.vscode-docker" \
    "ms-iot.vscode-ros" \
    "ms-python.isort" \
    "ms-python.python" \
    "ms-python.vscode-pylance" \
    "ms-toolsai.jupyter" \
    "ms-toolsai.jupyter-keymap" \
    "ms-toolsai.jupyter-renderers" \
    "ms-toolsai.vscode-jupyter-cell-tags" \
    "ms-toolsai.vscode-jupyter-slideshow" \
    "ms-vscode-remote.remote-containers" \
    "ms-vscode.cmake-tools" \
    "ms-vscode.cpptools" \
    "ms-vscode.cpptools-extension-pack" \
    "ms-vscode.cpptools-themes" \
    "platformio.platformio-ide" \
    "tombonnike.vscode-status-bar-format-toggle" \
    "twxs.cmake" \
    )

for ext in "${extensions_to_install[@]}"; do
    code --install-extension "$ext"
done

echo "Done!"
