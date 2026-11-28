import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

from python.runfiles import Runfiles

FLAG_EXECUTABLE = 0x20
FLAG_DIRECTORY = 0x40
FLAG_SYMLINK = 0x200


def resolve_runfile(raw: str) -> Path:
    direct = Path(raw)
    if direct.is_file():
        return direct.resolve()
    runfiles = Runfiles.Create()
    resolved = runfiles.Rlocation(raw) if runfiles else None
    if resolved and Path(resolved).is_file():
        return Path(resolved).resolve()
    raise FileNotFoundError(f"Unable to locate runfile: {raw}")


def build_lock_entry(raw_json: str, spec: dict[str, object]) -> dict[str, object]:
    data = json.loads(raw_json)
    raw_depots = data.get("depots") or []
    if not raw_depots:
        raise RuntimeError("No depot manifests resolved from DepotDownloader output")

    build_id = data.get("buildId")
    if build_id is None:
        raise RuntimeError("Missing buildId in DepotDownloader manifest JSON")

    depots: list[dict[str, object]] = []
    for d in raw_depots:
        executables = sorted(
            {
                norm
                for f in d.get("files", ())
                if (int(f["flags"]) & FLAG_EXECUTABLE)
                and not (int(f["flags"]) & (FLAG_DIRECTORY | FLAG_SYMLINK))
                if (norm := str(f["path"]).replace("\\", "/").lstrip("/"))
            }
        )
        entry: dict[str, object] = {
            "depotId": int(d["depotId"]),
            "manifestId": str(d["manifestId"]),
        }
        if executables:
            entry["executables"] = executables
        depots.append(entry)

    lock: dict[str, object] = {
        "appId": int(spec["app"]),
        "branch": str(spec["branch"]),
        "os": str(spec["os"]),
        "arch": str(spec["arch"]),
    }
    if spec.get("language"):
        lock["language"] = str(spec["language"])
    lock["buildId"] = int(build_id)
    if data.get("timeUpdated") is not None:
        lock["timeUpdated"] = str(data["timeUpdated"])
    lock["depots"] = depots
    return lock


def resolve_lock_for_spec(depotdownloader_bin: Path, spec: dict[str, object]) -> dict[str, object]:
    with tempfile.TemporaryDirectory() as tmp:
        json_path = Path(tmp) / "manifest.json"
        cmd = [
            str(depotdownloader_bin),
            "-app",
            str(spec["app"]),
            "-branch",
            str(spec["branch"]),
            "-os",
            str(spec["os"]),
            "-osarch",
            str(spec["arch"]),
            "-manifest-json",
            str(json_path),
        ]
        if spec.get("language"):
            cmd += ["-language", str(spec["language"])]
        proc = subprocess.run(
            cmd,
            env={**os.environ, "HOME": tmp},
            text=True,
            capture_output=True,
        )
        if proc.returncode != 0:
            raise RuntimeError(
                f"DepotDownloader failed for '{spec['name']}' (exit {proc.returncode}):\n"
                f"{proc.stdout}\n{proc.stderr}"
            )
        return build_lock_entry(json_path.read_text(encoding="utf-8"), spec)


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(content)
        os.replace(tmp_name, path)
    except BaseException:
        Path(tmp_name).unlink(missing_ok=True)
        raise


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--depotdownloader", required=True)
    parser.add_argument("--pins", required=True)
    parser.add_argument("--workspace")
    parser.add_argument("names", nargs="*")
    args = parser.parse_args(argv)

    dd_bin = resolve_runfile(args.depotdownloader)
    pins: list[dict[str, object]] = json.loads(
        resolve_runfile(args.pins).read_text(encoding="utf-8")
    )
    if not pins:
        raise SystemExit("No steam.app tags with lock_file configured in MODULE.bazel")

    by_name = {str(p["name"]): p for p in pins}
    if args.names:
        unknown = [n for n in args.names if n not in by_name]
        if unknown:
            raise SystemExit(
                f"Unknown locked steam.app name(s): {', '.join(unknown)} "
                f"(available: {', '.join(sorted(by_name))})"
            )
        selected = [by_name[n] for n in args.names]
    else:
        selected = pins

    ws = args.workspace or os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if not ws:
        raise SystemExit("BUILD_WORKSPACE_DIRECTORY is not set; run via 'bazel run @rules_steam//steam:pin'")
    ws_root = Path(ws)

    for spec in selected:
        lock = resolve_lock_for_spec(dd_bin, spec)
        out_path = ws_root / str(spec["lock_file"])
        write_atomic(out_path, json.dumps(lock, indent=2, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
