#!/bin/bash

declare -alr packages_to_check=("curl" "gnupg2" "ca-certificates" "lsb-release" \
    "software-properties-common" "apt-transport-https" "wget" "build-essential" \
    "ninja-build" "cmake" "python3" "python3-pip" "cppcheck" "git")
declare -a packages_to_install=()

# Check for missing packages

for pkg in "${packages_to_check[@]}"; do

    is_pkg_installed=$(dpkg-query -W --showformat='${Status}\n' ${pkg} | grep "install ok installed")

    if [ "${is_pkg_installed}" == "install ok installed" ]; then
        echo "OK: ${pkg} is installed."
    else
        echo "MISSING: ${pkg} is not installed, adding to install list"
        packages_to_install+=("${pkg}")
    fi
done

# Do install of missing packages

if [ ${#packages_to_install[@]} -eq 0 ]; then
    echo "Nothing to install, yay!"
else
    sudo apt install -y "${packages_to_install[@]}"
fi

# Install other stuff

function cleanup {
  echo "Returning to original directory"
  cd - || exit
}

# Move to tmp and setup trap to go back
cd /tmp || exit
trap cleanup EXIT 

# curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# dpkg -i "./google-chome-stable_current_amd64.deb"

# Install all LLVM tools
curl -s https://apt.llvm.org/llvm.sh | sudo bash /dev/stdin all