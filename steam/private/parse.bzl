visibility(["//steam/..."])

_FLAG_EXECUTABLE = 0x20
_FLAG_DIRECTORY = 0x40
_FLAG_SYMLINK = 0x200

def parse_manifest_json(raw_json, extra_executables = [], files = []):
    data = json.decode(raw_json)
    raw_depots = data.get("depots", [])
    if not raw_depots:
        fail("No depot manifests resolved from DepotDownloader output")
    if data.get("buildId") == None:
        fail("Missing buildId in manifest metadata")

    app_id = str(data["appId"])
    build_id = str(data["buildId"])
    depots = []
    for d in raw_depots:
        raw_execs = d["executables"] if "executables" in d else [
            f["path"]
            for f in d.get("files", [])
            if (f["flags"] & _FLAG_EXECUTABLE) and not (f["flags"] & (_FLAG_DIRECTORY | _FLAG_SYMLINK))
        ]
        exec_map = {}
        for p in raw_execs + extra_executables:
            norm = p.replace("\\", "/").lstrip("/")
            if norm:
                exec_map[norm] = True
        depots.append({
            "app": app_id,
            "depot": str(d["depotId"]),
            "manifest": str(d["manifestId"]),
            "executables": sorted(exec_map.keys()),
            "files": files,
        })
    return build_id, depots
