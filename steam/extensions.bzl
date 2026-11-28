load("//steam/private:parse.bzl", "parse_manifest_json")
load("//steam/private:repo_rules.bzl", "steam_app")

_DEPOTDOWNLOADER_BUILD = Label("@depotdownloader//:BUILD.bazel")
_VALID_OS = ("linux", "macos", "windows")
_VALID_ARCH = ("32", "64")

def _steam_impl(module_ctx):
    tags = []
    seen_names = {}

    for mod in module_ctx.modules:
        for tag in mod.tags.app:
            if tag.name in seen_names:
                fail("Duplicate steam.app name '{}'".format(tag.name))
            seen_names[tag.name] = True
            if tag.app <= 0:
                fail("steam.app '{}': app must be positive, got {}".format(tag.name, tag.app))
            if tag.os not in _VALID_OS:
                fail("Invalid os '{}' (expected one of {})".format(tag.os, _VALID_OS))
            if tag.arch not in _VALID_ARCH:
                fail("Invalid arch '{}' (expected one of {})".format(tag.arch, _VALID_ARCH))
            tags.append(tag)

    if not tags:
        return module_ctx.extension_metadata(reproducible = True)

    dd_dir = module_ctx.path(_DEPOTDOWNLOADER_BUILD).dirname
    dd_bin = dd_dir.get_child(
        "DepotDownloader.exe" if module_ctx.os.name.lower().startswith("windows") else "DepotDownloader",
    )

    home_dir = module_ctx.path("_home")
    module_ctx.file("_home/.keep", "")

    for tag in tags:
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

        build_id, depots = parse_manifest_json(
            module_ctx.read(manifest_json),
            extra_executables = tag.executables,
            files = tag.files,
        )
        steam_app(
            name = tag.name,
            depots = depots,
            build_id = build_id,
        )

    return module_ctx.extension_metadata(reproducible = False)

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
    },
)

steam = module_extension(
    implementation = _steam_impl,
    tag_classes = {
        "app": _app_tag,
    },
)
