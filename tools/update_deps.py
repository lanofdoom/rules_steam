# Fetches release archives for a given lanofdoom/DepotDownloader tag and updates
# _VERSION and _INTEGRITY in steam/private/depotdownloader.bzl (used by Renovate).

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import os
from pathlib import Path
import re
import urllib.request

PLATFORMS = (
    "linux-x64",
)


def workspace_root() -> Path:
    ws = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if ws:
        return Path(ws)
    return Path(__file__).resolve().parent.parent


def fetch_sri(url: str) -> str:
    h = hashlib.sha256()
    req = urllib.request.Request(url, headers={"User-Agent": "rules_steam-updater"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        while chunk := resp.read(1024 * 1024):
            h.update(chunk)
    return "sha256-" + base64.b64encode(h.digest()).decode("ascii")


def update_depotdownloader(tag: str) -> None:
    bzl_path = workspace_root() / "steam" / "private" / "depotdownloader.bzl"
    content = bzl_path.read_text(encoding="utf-8")
    urls = {
        p: f"https://github.com/lanofdoom/DepotDownloader/releases/download/{tag}/DepotDownloader-{p}.tar.gz"
        for p in PLATFORMS
    }
    with ThreadPoolExecutor(max_workers=len(PLATFORMS)) as pool:
        integrities = dict(zip(PLATFORMS, pool.map(lambda p: fetch_sri(urls[p]), PLATFORMS)))

    block = "_INTEGRITY = {\n" + "\n".join(
        f'    "{p}": "{integrities[p]}",' for p in PLATFORMS
    ) + "\n}"
    content, n1 = re.subn(r'_VERSION\s*=\s*"[^"]*"', f'_VERSION = "{tag}"', content, count=1)
    content, n2 = re.subn(r"_INTEGRITY\s*=\s*\{.*?\n\}", block, content, count=1, flags=re.DOTALL)
    if (n1, n2) != (1, 1):
        raise SystemExit("Failed to update depotdownloader.bzl")
    bzl_path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    dd = sub.add_parser("depotdownloader")
    dd.add_argument("tag")
    args = parser.parse_args()
    update_depotdownloader(args.tag)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
