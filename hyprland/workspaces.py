#!/usr/bin/env python3
"""Per-Hyprland-instance monitor/workspace numbering; no background daemon.

External monitors are ordered left to right; eDP comes last. Workspace IDs
are 11..19, 21..29, 31..39, 41..49. The helper retains workspace ownership
across connector hotplug by staging IDs using Hyprland 0.56's change_id API.
"""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys


def ctl(*args):
    result = subprocess.run(
        ["hyprctl", *[str(a) for a in args]],
        text=True, capture_output=True, check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    if result.stdout.startswith("error"):
        raise RuntimeError(result.stdout.strip())
    return result.stdout


def query(name):
    return json.loads(ctl("-j", name))


def dispatch(expr):
    ctl("dispatch", expr)


def q(value):
    return json.dumps(value)


def focus_monitor(name):
    dispatch(f"hl.dsp.focus({{ monitor = {q(name)} }})")


def focus_workspace(wid):
    dispatch(f"hl.dsp.focus({{ workspace = {wid} }})")


def move_workspace(wid, name):
    dispatch(f"hl.dsp.workspace.move({{ workspace = {wid}, monitor = {q(name)} }})")


def change_id(old, new):
    dispatch(f"hl.dsp.workspace.change_id({{ workspace = {old}, id = {new} }})")


def cursor_move(x, y):
    dispatch(f"hl.dsp.cursor.move({{ x = {int(x)}, y = {int(y)} }})")


def monitor_list():
    monitors = [m for m in query("monitors") if not m.get("disabled") and not m.get("mirrorOf")]
    physical = [m for m in monitors if not m["name"].startswith(("HEADLESS-", "WAYLAND-"))
                and m["name"] != "REMOTE"]
    # The independent remote compositor initially exposes a Weston-backed
    # WAYLAND output. Do not number it: the real VNC output appears later.
    if os.getenv("HYPRLAND_REMOTE_SESSION") == "1":
        chosen = [m for m in monitors if m["name"].startswith("HEADLESS-")
                  or m["name"] == "REMOTE"]
    else:
        chosen = physical or [m for m in monitors if m["name"].startswith("HEADLESS-")] or monitors
    external = sorted(
        [m for m in chosen if not m["name"].startswith("eDP-")],
        key=lambda m: (m["x"], m["y"], m["name"]),
    )
    internal = sorted(
        [m for m in chosen if m["name"].startswith("eDP-")],
        key=lambda m: m["name"],
    )
    return (external + internal)[:4]


def owner_for(wid, monitor, old_slots, owners):
    if wid > 0 and wid % 10 in range(1, 10):
        if 11 <= wid <= 49:
            slot = wid // 10
            if slot <= len(old_slots):
                return old_slots[slot - 1], wid % 10
        if wid >= 10000:
            number = (wid - 10000) // 10
            name = next((n for n, v in owners.items() if v == number), None)
            if name:
                return name, wid % 10
        if 1 <= wid <= 9:  # First activation of this configuration.
            return monitor, wid
    return None, None


def sync(state, monitors):
    names = [m["name"] for m in monitors]
    old_slots = state.get("slots", [])
    if names == old_slots:
        return
    owners = state.setdefault("owners", {})
    for name in names:
        if name not in owners:
            owners[name] = max(owners.values(), default=0) + 1
    new_slots = {name: index for index, name in enumerate(names, 1)}
    workspaces = [w for w in query("workspaces") if w["id"] > 0]
    by_id = {w["id"]: w for w in workspaces}
    focused = next((m["name"] for m in monitors if m.get("focused")), None)
    cursor = query("cursorpos")
    originals = {}
    for m in monitors:
        original_id = m["activeWorkspace"]["id"]
        originals[m["name"]] = owner_for(
            original_id,
            by_id.get(original_id, {}).get("monitor", m["name"]),
            old_slots, owners,
        )

    transfers = []
    for w in workspaces:
        wid = w["id"]
        owner, digit = owner_for(wid, w["monitor"], old_slots, owners)
        if owner is None:
            continue  # Special or manually-created non-numbered workspaces.
        target = (new_slots[owner] * 10 + digit
                  if owner in new_slots else 10000 + owners[owner] * 10 + digit)
        if target != wid:
            transfers.append((wid, target, owner))
        elif owner in new_slots and w["monitor"] != owner:
            move_workspace(wid, owner)

    # Stage before filling IDs: changing 31 -> 21 while 21 still exists
    # would collide. change_id preserves windows and even empty workspaces.
    for wid, target, _ in transfers:
        change_id(wid, 200000 + wid)
    for wid, target, owner in transfers:
        change_id(200000 + wid, target)
        if owner in new_slots:
            move_workspace(target, owner)

    for m in monitors:
        name = m["name"]
        prior_owner, digit = originals[name]
        if prior_owner != name or digit is None:
            digit = 1
        focus_monitor(name)
        focus_workspace(new_slots[name] * 10 + digit)

    if focused and focused in new_slots:
        focus_monitor(focused)
    if cursor and "x" in cursor and "y" in cursor:
        cursor_move(cursor["x"], cursor["y"])
    state["slots"] = names


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in (
        "sync", "focus-monitor", "move-monitor", "focus-workspace", "move-workspace"
    ):
        raise SystemExit("usage: workspaces.py sync|focus-monitor N|move-monitor N|focus-workspace N D|move-workspace N D")
    action = sys.argv[1]
    signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE", "default")
    directory = Path(os.getenv("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "hypr" / signature
    directory.mkdir(parents=True, exist_ok=True)
    with (directory / "numbered-workspaces.lock").open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        path = directory / "numbered-workspaces.json"
        try:
            state = json.loads(path.read_text())
        except (FileNotFoundError, ValueError):
            state = {}
        monitors = monitor_list()
        if not monitors:
            return
        sync(state, monitors)
        path.write_text(json.dumps(state))
        if action == "sync":
            return
        # Sync may have changed the active workspace IDs on every output.
        monitors = monitor_list()
        try:
            number = int(sys.argv[2])
            digit = int(sys.argv[3]) if "workspace" in action else None
        except (IndexError, ValueError):
            raise SystemExit("invalid monitor/workspace number")
        if number < 1 or number > len(monitors) or (digit is not None and not 1 <= digit <= 9):
            return  # Disconnected monitor or invalid workspace: no-op.
        target = monitors[number - 1]
        name = target["name"]
        wid = number * 10 + digit if digit is not None else target["activeWorkspace"]["id"]
        if action.startswith("focus"):
            if action == "focus-workspace" and any(w["id"] == wid for w in query("workspaces")):
                move_workspace(wid, name)
            focus_monitor(name)
            if action == "focus-workspace":
                focus_workspace(wid)
            # Always place cursor on target monitor, even for an empty workspace.
            cursor_move(target["x"] + target["width"] // 2, target["y"] + target["height"] // 2)
        else:
            active = query("activewindow")
            address = active.get("address", "")
            if not address or address == "0x":
                return
            if wid <= 0:
                wid = number * 10 + 1
            # Explicitly don't follow: pointer and focus stay on source.
            dispatch(f"hl.dsp.window.move({{ workspace = {wid}, follow = false, window = {q('address:' + address)} }})")
            move_workspace(wid, name)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError) as exc:
        print(f"hypr-workspaces: {exc}", file=sys.stderr)
        sys.exit(1)
