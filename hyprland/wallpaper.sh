#!/bin/sh
# Wallpaper on all outputs, current choice in ~/.local/state/wallpaper.
#   wallpaper.sh            pick with fuzzel and apply
#   wallpaper.sh <image>    apply (login and monitor hotplug use this form)
dir="$HOME/Pictures/Wallpapers"
state="$HOME/.local/state/wallpaper"

if [ "$#" -eq 0 ]; then
  choice=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | sed 's|.*/||' | sort |
    fuzzel --dmenu --prompt 'wallpaper> ') || exit 0
  [ -n "$choice" ] || exit 0
  set -- "$dir/$choice"
fi

[ -f "$1" ] || exit 1
mkdir -p "${state%/*}"
printf '%s\n' "$1" > "$state"

# shortcut: swaybg cannot adopt outputs added after start, so it is restarted
# here; hyprland.lua calls this again on monitor.added.
pkill -x swaybg
exec swaybg -m fill -i "$1"
