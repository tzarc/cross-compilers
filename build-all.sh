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
    ln -sf "$script_dir/tarballs" "$script_dir/$config_name/.build/tarballs"

    pushd "$script_dir/$config_name"
    ct-ng build
    popd
}

[[ ! -d "$script_dir/crosstool-ng_source" ]] \
    && mkdir -p "$script_dir/crosstool-ng_source" \
    && git clone https://github.com/crosstool-ng/crosstool-ng "$script_dir/crosstool-ng_source"

update_crosstool() {
    pushd "$script_dir/crosstool-ng_source"
    git clean -xfd
    git checkout -- .
    git pull --ff-only
    ./bootstrap
    ./configure --prefix="$script_dir/crosstool-ng_prefix"
    make
    make install
    popd
}

if [[ "${1:-}" == "" ]] ; then

    export PATH="$script_dir/crosstool-ng_prefix/bin:$PATH"

    #build_one win64-cross

    export PATH="$HOME/x-tools/x86_64-w64-mingw32/bin:$PATH"

    build_one gcc11.1-avr

fi