#!/bin/bash

set -eEuo pipefail
umask 022

this_script=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(readlink -f "$(dirname "$this_script")")

havecmd()  { type ${1} &>/dev/null || return 1; }

if ! havecmd makeinfo ; then
    echo "Missing command 'makeinfo'" >&2
    echo "Perhaps try something like 'sudo apt install texinfo'" >&2
    exit 1
fi

if ! havecmd help2man ; then
    echo "Missing command 'help2man'" >&2
    echo "Perhaps try something like 'sudo apt install help2man'" >&2
    exit 1
fi

if ! havecmd meson ; then
    echo "Missing command 'meson'" >&2
    echo "Perhaps try something like 'python3 -m pip install meson'" >&2
    exit 1
fi

if ! havecmd ninja ; then
    echo "Missing command 'ninja'" >&2
    echo "Perhaps try something like 'python3 -m pip install ninja'" >&2
    exit 1
fi

build_one() {
    local config_name=$1

    [[ ! -d "$script_dir/$config_name/.build" ]] \
        && mkdir -p "$script_dir/$config_name/.build"

    cp "$script_dir/$config_name.config" "$script_dir/$config_name/.config"

    pushd "$script_dir/$config_name"

    # Update the config
    cat << EOF >> .config
CT_RM_RF_PREFIX_DIR=y
CT_PREFIX_DIR_RO=y
CT_LOCAL_TARBALLS_DIR="$script_dir/tarballs"
CT_PREFIX_DIR="$script_dir/target_prefix/$config_name"
CT_STATIC_TOOLCHAIN=y
CT_DEBUG_GDB=y
CT_GDB_CROSS_STATIC=y
CT_COMP_TOOLS_MAKE=y
# CT_COMP_LIBS_NEWLIB_NANO is not set
EOF
    ct-ng olddefconfig

    # Build the compiler
    ct-ng build
    popd
}

update_crosstool() {
    pushd "$script_dir/crosstool-ng"
    git clean -xfd
    git checkout -- .
    git pull --ff-only
    ./bootstrap
    ./configure --prefix="$script_dir/build_prefix"
    make
    make install
    popd
}

export PATH="$script_dir/build_prefix/bin:$PATH"

if ! havecmd ct-ng ; then
    update_crosstool
fi

#build_one gcc11.1_win64-cross

export PATH="$HOME/x-tools/x86_64-w64-mingw32/bin:$PATH"

build_one gcc11.1_avr
build_one gcc11.1_arm
build_one gcc11.1_riscv32
