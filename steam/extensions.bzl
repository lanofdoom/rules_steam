load("//steam/private:parse.bzl", "parse_manifest_json")
load("//steam/private:repo_rules.bzl", "steam_app", "steam_pins_repo", "steam_repo")

_DEPOTDOWNLOADER_BUILD = Label("@depotdownloader//:BUILD.bazel")
_VALID_OS = ("linux", "macos", "windows")
_VALID_ARCH = ("32", "64")

def _lock_rel_path(lbl):
    if lbl.repo_name != "":
        fail("lock_file '{}' must belong to the root module repository".format(lbl))
    return "{}/{}".format(lbl.package, lbl.name) if lbl.package else lbl.name

def _lock_matches_tag(data, tag):
    return (
        type(data) == "dict" and
        data.get("appId") == tag.app and
        data.get("branch") == tag.branch and
        data.get("os") == tag.os and
        data.get("arch") == tag.arch and
        data.get("language", "") == tag.language and
        bool(data.get("depots")) and
        data.get("buildId") != None
    )

def _steam_impl(module_ctx):
    tags = []
    pins = []
    seen_names = {}
    seen_locks = {}

    for mod in module_ctx.modules:
        for tag in mod.tags.app:
            if tag.name == "steam_pins":
                fail("Reserved steam.app name 'steam_pins'")
            if tag.name in seen_names:
                fail("Duplicate steam.app name '{}'".format(tag.name))
            seen_names[tag.name] = True
            if tag.app <= 0:
                fail("steam.app '{}': app must be positive, got {}".format(tag.name, tag.app))
            if tag.os not in _VALID_OS:
                fail("Invalid os '{}' (expected one of {})".format(tag.os, _VALID_OS))
            if tag.arch not in _VALID_ARCH:
                fail("Invalid arch '{}' (expected one of {})".format(tag.arch, _VALID_ARCH))
            if tag.lock_file != None:
                if not mod.is_root:
                    fail("steam.app '{}': lock_file is only supported in the root module".format(tag.name))
                rel_lock = _lock_rel_path(tag.lock_file)
                if rel_lock in seen_locks:
                    fail("Duplicate lock_file '{}' across steam.app tags".format(rel_lock))
                seen_locks[rel_lock] = True
                pins.append({
                    "name": tag.name,
                    "app": tag.app,
                    "os": tag.os,
                    "arch": tag.arch,
                    "branch": tag.branch,
                    "language": tag.language,
                    "lock_file": rel_lock,
                })
            tags.append(tag)

    steam_pins_repo(
        name = "steam_pins",
        content = json.encode(pins),
    )

    if not tags:
        return module_ctx.extension_metadata(reproducible = True)

    unpinned_tags = [t for t in tags if t.lock_file == None]
    dd_bin = None
    home_dir = None
    if unpinned_tags:
        dd_dir = module_ctx.path(_DEPOTDOWNLOADER_BUILD).dirname
        dd_bin = dd_dir.get_child(
            "DepotDownloader.exe" if module_ctx.os.name.lower().startswith("windows") else "DepotDownloader",
        )
        home_dir = module_ctx.path("_home")
        module_ctx.file("_home/.keep", "")

    for tag in tags:
        if tag.lock_file != None:
            rel_lock = _lock_rel_path(tag.lock_file)
            lock_path = module_ctx.path(tag.lock_file)
            module_ctx.watch(lock_path)
            if not lock_path.exists:
                steam_repo(
                    name = tag.name,
                    error = "Missing lockfile '{}' for steam.app '{}'; run: bazel run @rules_steam//steam:pin".format(
                        rel_lock,
                        tag.name,
                    ),
                )
                continue
            raw_json = module_ctx.read(lock_path)
            data = json.decode(raw_json) if raw_json.strip() else None
            if not _lock_matches_tag(data, tag):
                steam_repo(
                    name = tag.name,
                    error = "Lockfile '{}' is out of sync with steam.app '{}'; run: bazel run @rules_steam//steam:pin".format(
                        rel_lock,
                        tag.name,
                    ),
                )
                continue
        else:
            manifest_json = module_ctx.path("_manifest_" + tag.name + ".json")
            cmd = [
                dd_bin,
                "-app",
                str(tag.app),
                "-branch",
                tag.branch,
                "-os",
                tag.os,
                "-osarch",
                tag.arch,
                "-manifest-json",
                manifest_json,
            ]
            if tag.language:
                cmd += ["-language", tag.language]

            res = module_ctx.execute(
                cmd,
                timeout = 300,
                environment = {"HOME": str(home_dir)},
            )
            if res.return_code != 0:
                fail("DepotDownloader failed for steam.app '{}' (app {}, exit {}):\n{}\n{}".format(
                    tag.name,
                    tag.app,
                    res.return_code,
                    res.stdout,
                    res.stderr,
                ))
            raw_json = module_ctx.read(manifest_json)

        build_id, depots = parse_manifest_json(
            raw_json,
            extra_executables = tag.executables,
            files = tag.files,
        )
        steam_app(
            name = tag.name,
            depots = depots,
            build_id = build_id,
        )

    return module_ctx.extension_metadata(
        reproducible = len(unpinned_tags) == 0,
    )

_app_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "app": attr.int(mandatory = True),
        "os": attr.string(mandatory = True),
        "arch": attr.string(default = "64"),
        "branch": attr.string(default = "public"),
        "language": attr.string(default = ""),
        "executables": attr.string_list(),
        "files": attr.string_list(),
        "lock_file": attr.label(),
    },
)

steam = module_extension(
    implementation = _steam_impl,
    tag_classes = {
        "app": _app_tag,
    },
)
