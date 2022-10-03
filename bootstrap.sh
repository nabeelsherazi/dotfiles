#!/bin/bash

declare -alr packages_to_check=("curl" "gnupg2" "ca-certificates" "lsb-release" \
    "software-properties-common" "apt-transport-https" "wget" "build-essential" \
    "ninja-build" "cmake" "python3" "python3-pip" "cppcheck" "git")
declare -a packages_to_install=()

# Check for missing packages

for pkg in "${packages_to_check[@]}"; do

    is_pkg_installed="$(dpkg-query -W --showformat='${Status}\n' "${pkg}" | grep "install ok installed")"

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

# TODO: Detect version installed and update this
register_clang_version 15 100