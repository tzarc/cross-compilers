#!/bin/sh
set -e
umask 022

echo "Install script for @TARGET_ARCH@-gcc @GCC_VERSION@"

target_dir="$HOME/cross-compile/@CONFIG_NAME@"
[ ! -d "$target_dir" ] \
    && mkdir -p "$target_dir"

echo "Extracting to: $target_dir"

PAYLOAD_LINE=$(awk '/^#EOF#/ {print NR + 1; exit 0; }' "$0")
tail -n+$PAYLOAD_LINE "$0" | xzcat | tar x -C "$target_dir"

echo
echo "Compiler information:"
"$target_dir/bin/"*-g++ -v

echo
echo "You should add the following directory to your \$PATH:"
echo "     $target_dir/bin"

exit 0
#EOF#
