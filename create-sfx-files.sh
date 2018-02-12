#!/bin/bash
set -e
umask 022

this_script=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(readlink -f "$(dirname "$this_script")")

st_info()  { echo -e  "\033[1;30m[\033[0;36minfo\033[1;30m]\033[0m $*"   ; }

handle_replacements() {
    local target_prefix="$1"
    local gcc_version=$(get_config_arg "$target_prefix" CT_CC_GCC_VERSION)
    local gdb_version=$(get_config_arg "$target_prefix" CT_GDB_VERSION)
    local binutils_version=$(get_config_arg "$target_prefix" CT_BINUTILS_VERSION)
    local libc_version=$(get_config_arg "$target_prefix" CT_LIBC_VERSION)
    local target_arch=$(basename "$target_prefix")

    sed -e "s#@CONFIG_NAME@#$config_name#g" \
        | sed -e "s#@GCC_VERSION@#$gcc_version#g" \
        | sed -e "s#@GDB_VERSION@#$gdb_version#g" \
        | sed -e "s#@BINUTILS_VERSION@#$binutils_version#g" \
        | sed -e "s#@LIBC_VERSION@#$libc_version#g" \
        | sed -e "s#@TARGET_ARCH@#$target_arch#g"
}

get_config_arg() {
    local target_prefix="$1"
    local config_arg="$2"
    "$target_prefix"/bin/*-ct-ng.config | grep $config_arg | cut -d= -f2 | sed -e 's#"##g'
}

create_sfx_linux() {
    local config_name="$1"
    local target_prefix="$2"

    local gcc_version=$(get_config_arg "$target_prefix" CT_CC_GCC_VERSION)
    local target_arch=$(basename "$target_prefix")

    local sfx_file="$script_dir/install-$config_name.sfx"
    [[ -f "$sfx_file" ]] && rm "$sfx_file"

    cat "$script_dir/linux-sfx-stub.sh" | handle_replacements "$target_prefix" > "$sfx_file"

    st_info "Creating Linux self-extractor for $target_arch-gcc $gcc_version"
    tar -Ocf - -C "$target_prefix" --one-file-system --owner=root --group=root . 2>/dev/null | xz -cz9e >> "$sfx_file"
    chmod +x "$sfx_file"
}

create_sfx_windows() {
    local config_name="$1"
    local target_prefix="$2"

    local gcc_version=$(get_config_arg "$target_prefix" CT_CC_GCC_VERSION)
    local target_arch=$(basename "$target_prefix")

    local sfx_file="$script_dir/install-$config_name.exe"
    [[ -f "$sfx_file" ]] && rm "$sfx_file"

    local sevenzip_file="$script_dir/install-$config_name.7z"
    [[ -f "$sevenzip_file" ]] && rm "$sevenzip_file"

    local temp_dir="$script_dir/windows-install-support/temp"
    [[ ! -d "$temp_dir" ]] && mkdir -p "$temp_dir"
    cat "$script_dir/windows-install-support/toolchain.xml" | handle_replacements "$target_prefix" > "$temp_dir/toolchain.xml"
    cat "$script_dir/windows-install-support/toolchain.props" | handle_replacements "$target_prefix" > "$temp_dir/toolchain.props"
    cat "$script_dir/windows-install-support/IntelliSense.props" | handle_replacements "$target_prefix" > "$temp_dir/IntelliSense.props"

    st_info "Creating Windows self-extractor for $target_arch-gcc $gcc_version"
    7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on "$sevenzip_file" "$target_prefix"/* >/dev/null 2>&1

    for file in $(ls "$temp_dir") ; do
        7z d -t7z "$sevenzip_file" "$(basename "$file")" >/dev/null 2>&1
        7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on "$sevenzip_file" "$temp_dir/$file" >/dev/null 2>&1
    done

    cat "$script_dir/windows-install-support/windows-sfx-stub.exe" > "$sfx_file"
    cat "$script_dir/windows-install-support/windows-sfx-cfg.txt" | handle_replacements "$target_prefix" >> "$sfx_file"
    cat "$sevenzip_file" >> "$sfx_file"
    chmod +x "$sfx_file"
}

#create_sfx_linux gcc63-raspbian-cross "$HOME/x-tools/arm-linux-gnueabihf"

#create_sfx_linux gcc73-rpi3-cross "$HOME/x-tools/armv8-rpi3-linux-gnueabihf"
#create_sfx_linux gcc73-imx7-cross "$HOME/x-tools/armv7-imx7-linux-gnueabihf"

#create_sfx_windows gcc72-rpi3-canadian-cross "$HOME/x-tools/HOST-x86_64-w64-mingw32/armv8-rpi3-linux-gnueabihf"
create_sfx_windows gcc72-imx7-canadian-cross "$HOME/x-tools/HOST-x86_64-w64-mingw32/arm-poky-linux-gnueabi"

#create_sfx_linux gcc73-avr-cross "$HOME/x-tools/avr"
#create_sfx_windows gcc73-avr-canadian-cross "$HOME/x-tools/HOST-x86_64-w64-mingw32/avr"
