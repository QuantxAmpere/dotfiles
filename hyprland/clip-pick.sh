#!/usr/bin/env bash
# Clipboard picker: newest screenshots by timestamp, then cliphist text history.
# Each fuzzel line is <kind>\t<payload>\t<label>; only the payload is accepted.
shots="$HOME/Pictures/Screenshots"
mkdir -p "$shots"

sel=$(
  {
    find "$shots" -maxdepth 1 -name '*.png' -printf '%T@ %p\n' | sort -rn | head -20 |
      while read -r _ path; do
        label=${path##*/}
        label=${label%.png}
        printf 'shot\t%s\t%s\n' "$path" "${label//_/ }"
      done

    # cliphist lists the newest entry first.
    cliphist list 2>/dev/null | head -50 | while IFS=$'\t' read -r id text; do
      printf 'text\t%s\t%s\n' "$id" "$(printf '%s' "${text//$'\t'/ }" | cut -c1-100)"
    done
  } | fuzzel -d --with-nth=3 --accept-nth=2 --prompt 'Clipboard'
)

[ -n "$sel" ] || exit 0

# fuzzel echoes typed text when it matches no entry; never clear the clipboard
# with an empty copy because of that.
copied=0
if [ -f "$sel" ]; then
  wl-copy < "$sel" && copied=1
elif text=$(cliphist decode "$sel" 2>/dev/null) && [ -n "$text" ]; then
  printf '%s' "$text" | wl-copy && copied=1
fi

[ "$copied" = 1 ] || exit 0

# Hand the item to the app: fuzzel is gone, so its window has focus again.
# Wait for wl-copy to own the selection and for focus to return.
sleep 0.15
wtype -M ctrl -k v -m ctrl
