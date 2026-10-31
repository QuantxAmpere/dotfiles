"""Regression tests for physical-monitor numbering and first-session migration."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch, call

spec = importlib.util.spec_from_file_location(
    "workspaces", Path(__file__).resolve().parents[1] / "hyprland" / "workspaces.py"
)
workspaces = importlib.util.module_from_spec(spec)
spec.loader.exec_module(workspaces)


def monitor(name, x, active, focused=False, mirror="none"):
    return {
        "name": name, "x": x, "y": 0, "width": 2560, "height": 1440,
        "disabled": False, "mirrorOf": mirror, "focused": focused,
        "activeWorkspace": {"id": active},
    }


class WorkspaceTests(unittest.TestCase):
    def test_hyprland_none_mirror_is_not_a_mirror(self):
        outputs = [
            monitor("DP-1", 0, 1),
            monitor("DP-2", 2560, 2),
            monitor("HDMI-A-1", 5120, 3),
            monitor("eDP-1", 7680, 4),
            monitor("DP-MIRROR", 0, 5, mirror="DP-1"),
        ]
        with patch.object(workspaces, "query", return_value=outputs):
            self.assertEqual(
                [m["name"] for m in workspaces.monitor_list()],
                ["DP-1", "DP-2", "HDMI-A-1", "eDP-1"],
            )

    def test_internal_display_is_always_last(self):
        outputs = [monitor("eDP-1", 0, 1), monitor("DP-1", 2560, 2)]
        with patch.object(workspaces, "query", return_value=outputs):
            self.assertEqual(
                [m["name"] for m in workspaces.monitor_list()],
                ["DP-1", "eDP-1"],
            )

    def test_migration_from_hyprland_default_ids(self):
        outputs = [
            monitor("DP-1", 0, 1),
            monitor("DP-2", 2560, 2, focused=True),
            monitor("HDMI-A-1", 5120, 3),
            monitor("eDP-1", 7680, 4),
        ]
        legacy = [
            {"id": i, "monitor": output["name"]}
            for i, output in enumerate(outputs, 1)
        ]
        def query(name):
            return {"workspaces": legacy, "cursorpos": {"x": 2700, "y": 100}}[name]
        state = {}
        with patch.object(workspaces, "query", side_effect=query), \
             patch.object(workspaces, "change_id") as change, \
             patch.object(workspaces, "move_workspace") as move, \
             patch.object(workspaces, "focus_monitor"), \
             patch.object(workspaces, "focus_workspace") as focus, \
             patch.object(workspaces, "cursor_move") as cursor:
            self.assertTrue(workspaces.sync(state, outputs))
        # A second sync on unchanged monitors must not signal waybar again.
        with patch.object(workspaces, "query", side_effect=query):
            self.assertFalse(workspaces.sync(state, outputs))
        self.assertEqual(state["slots"], [m["name"] for m in outputs])
        for old, new in enumerate([11, 21, 31, 41], 1):
            self.assertIn(call(old, 200000 + old), change.call_args_list)
            self.assertIn(call(200000 + old, new), change.call_args_list)
        self.assertEqual(
            [c.args[0] for c in focus.call_args_list], [11, 21, 31, 41]
        )
        cursor.assert_called_once_with(2700, 100)
        self.assertEqual(move.call_count, 4)


if __name__ == "__main__":
    unittest.main()
