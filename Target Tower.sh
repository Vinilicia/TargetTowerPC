#!/bin/sh
echo -ne '\033c\033]0;TargetTower - The Demo\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Target Tower.x86_64" "$@"
