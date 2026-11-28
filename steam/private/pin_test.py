import json
from pathlib import Path
import sys
import tempfile
import unittest

from pin import build_lock_entry, main, write_atomic


class PinTest(unittest.TestCase):
    def test_build_lock_entry_extracts_buildid_and_executables(self) -> None:
        raw = json.dumps(
            {
                "appId": 90,
                "name": "Half-Life Dedicated Server",
                "branch": "beta",
                "buildId": 2500,
                "timeUpdated": "2024-09-13T19:20:39Z",
                "depots": [
                    {
                        "depotId": 1006,
                        "containingAppId": 70,
                        "branch": "public",
                        "manifestId": "111",
                        "files": [
                            {"path": "bin/engine.so", "flags": 0},
                            {"path": "bin", "flags": 96},
                            {"path": "bin/link", "flags": 544, "linkTarget": "bin/engine.so"},
                        ],
                    },
                    {
                        "depotId": 92,
                        "containingAppId": 90,
                        "branch": "beta",
                        "manifestId": "2667117727132184734",
                        "files": [
                            {"path": "/hlds_linux", "flags": 32},
                            {"path": "café/my launcher.sh", "flags": 32},
                        ],
                    },
                ],
            }
        )
        spec = {
            "name": "hlds",
            "app": 90,
            "branch": "beta",
            "os": "linux",
            "arch": "64",
            "language": "",
            "lock_file": "hlds.lock.json",
        }
        lock = build_lock_entry(raw, spec)
        self.assertEqual(
            lock,
            {
                "appId": 90,
                "branch": "beta",
                "os": "linux",
                "arch": "64",
                "buildId": 2500,
                "timeUpdated": "2024-09-13T19:20:39Z",
                "depots": [
                    {"depotId": 1006, "manifestId": "111"},
                    {
                        "depotId": 92,
                        "manifestId": "2667117727132184734",
                        "executables": ["café/my launcher.sh", "hlds_linux"],
                    },
                ],
            },
        )

    def test_build_lock_entry_rejects_empty_depots_or_missing_buildid(self) -> None:
        spec = {"name": "hlds", "app": 90, "branch": "public", "os": "linux", "arch": "64"}
        with self.assertRaisesRegex(RuntimeError, "No depot manifests"):
            build_lock_entry(json.dumps({"appId": 90, "buildId": 1, "depots": []}), spec)
        with self.assertRaisesRegex(RuntimeError, "Missing buildId"):
            build_lock_entry(
                json.dumps(
                    {
                        "appId": 90,
                        "buildId": None,
                        "depots": [{"depotId": 1, "manifestId": "111", "files": []}],
                    }
                ),
                spec,
            )

    def test_write_atomic_and_selective_pinning(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            ws_dir = tmp_dir / "ws"
            ws_dir.mkdir()
            write_atomic(ws_dir / "nested" / "old.json", "first\n")
            write_atomic(ws_dir / "nested" / "old.json", "second\n")
            self.assertEqual((ws_dir / "nested" / "old.json").read_text(encoding="utf-8"), "second\n")

            fake_dd = tmp_dir / "fake_dd.py"
            fake_dd.write_text(
                f"#!{sys.executable}\n"
                "import json, pathlib, sys\n"
                "app = int(sys.argv[sys.argv.index('-app') + 1])\n"
                "idx = sys.argv.index('-manifest-json')\n"
                "pathlib.Path(sys.argv[idx + 1]).write_text(\n"
                "    json.dumps({\n"
                "        'appId': app,\n"
                "        'branch': 'public',\n"
                "        'buildId': app * 10,\n"
                "        'timeUpdated': '2024-09-13T19:20:39Z',\n"
                "        'depots': [{'depotId': 1, 'manifestId': '999', 'files': []}],\n"
                "    }),\n"
                "    encoding='utf-8',\n"
                ")\n",
                encoding="utf-8",
            )
            fake_dd.chmod(0o755)

            pins_file = tmp_dir / "pins.json"
            pins_file.write_text(
                json.dumps(
                    [
                        {
                            "name": "srv_a",
                            "app": 90,
                            "branch": "public",
                            "os": "linux",
                            "arch": "64",
                            "language": "",
                            "lock_file": "a.lock.json",
                        },
                        {
                            "name": "srv_b",
                            "app": 996560,
                            "branch": "public",
                            "os": "linux",
                            "arch": "64",
                            "language": "",
                            "lock_file": "sub/b.lock.json",
                        },
                    ]
                ),
                encoding="utf-8",
            )

            rc = main(
                [
                    "--depotdownloader",
                    str(fake_dd),
                    "--pins",
                    str(pins_file),
                    "--workspace",
                    str(ws_dir),
                    "srv_b",
                ]
            )
            self.assertEqual(rc, 0)
            self.assertFalse((ws_dir / "a.lock.json").exists())
            b_lock = json.loads((ws_dir / "sub" / "b.lock.json").read_text(encoding="utf-8"))
            self.assertEqual(b_lock["buildId"], 9965600)

            with self.assertRaises(SystemExit):
                main(
                    [
                        "--depotdownloader",
                        str(fake_dd),
                        "--pins",
                        str(pins_file),
                        "--workspace",
                        str(ws_dir),
                        "unknown_srv",
                    ]
                )


if __name__ == "__main__":
    unittest.main()
