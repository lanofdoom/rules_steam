import argparse
import sys
import unittest

from pin import resolve_lock_for_spec, resolve_runfile

_DEPOTDOWNLOADER_RAW = ""


class PinLiveTest(unittest.TestCase):
    def test_live_hlds_manifest_resolution(self) -> None:
        dd_bin = resolve_runfile(_DEPOTDOWNLOADER_RAW)
        spec = {
            "name": "hlds",
            "app": 90,
            "branch": "public",
            "os": "linux",
            "arch": "64",
            "language": "",
            "lock_file": "hlds.lock.json",
        }
        lock = resolve_lock_for_spec(dd_bin, spec)

        self.assertEqual(lock["appId"], 90)
        self.assertGreater(int(lock["buildId"]), 0)
        depots = lock["depots"]
        assert isinstance(depots, list)
        self.assertGreaterEqual(len(depots), 2)
        self.assertIn(1, {int(d["depotId"]) for d in depots})

        all_executables = {exe for d in depots for exe in d.get("executables", ())}
        self.assertIn("hlds_linux", all_executables)
        self.assertIn("hlds_run", all_executables)

        bad_spec = {**spec, "branch": "definitely-not-a-branch"}
        with self.assertRaisesRegex(RuntimeError, "does not exist"):
            resolve_lock_for_spec(dd_bin, bad_spec)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--depotdownloader", required=True)
    known, remaining = parser.parse_known_args()
    _DEPOTDOWNLOADER_RAW = known.depotdownloader
    unittest.main(argv=[sys.argv[0], *remaining])
