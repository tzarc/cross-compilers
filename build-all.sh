#!/bin/bash

set -e
umask 022

this_script=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(readlink -f "$(dirname "$this_script")")

build_one() {
    local config_name=$1

    [[ ! -d "$script_dir/$config_name" ]] \
        && mkdir -p "$script_dir/$config_name"

    cp "$script_dir/$config_name.config" "$script_dir/$config_name/.config"

    pushd "$script_dir/$config_name"
    ct-ng build
    popd
}

crosstool_ng_version="1.23.0"
[[ ! -f "$script_dir/crosstool-ng-${crosstool_ng_version}.tar.gz" ]] \
    && wget -O"$script_dir/crosstool-ng-${crosstool_ng_version}.tar.gz" https://github.com/crosstool-ng/crosstool-ng/archive/crosstool-ng-${crosstool_ng_version}.tar.gz

[[ ! -d "$script_dir/crosstool-ng_source" ]] \
    && mkdir -p "$script_dir/crosstool-ng_source"
tar -zxf "$script_dir/crosstool-ng-${crosstool_ng_version}.tar.gz" --strip-components=1 -C "$script_dir/crosstool-ng_source"

pushd "$script_dir/crosstool-ng_source"
./bootstrap
./configure --prefix="$script_dir/crosstool-ng_prefix"
make
make install
popd

export PATH="$script_dir/crosstool-ng_prefix/bin:$PATH"

#build_one gcc63-raspbian-cross

#build_one gcc73-rpi3-cross
#build_one gcc73-imx7-cross

#build_one gcc63-win64-cross

export PATH="$HOME/x-tools/x86_64-w64-mingw32/bin:$PATH"

#build_one gcc72-rpi3-canadian-cross
build_one gcc72-imx7-canadian-cross
