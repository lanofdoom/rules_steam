visibility("public")

_DOWNLOAD_TIMEOUT = 14400
_TARGETS_BZL = str(Label("//steam/private:targets.bzl"))

def _collect_files(root_dir):
    if not root_dir.exists:
        return []
    found = []
    stack = [("", root_dir)]
    for _ in range(2000000):
        if not stack:
            break
        rel_dir, cur = stack.pop()
        for entry in cur.readdir():
            rel = "{}/{}".format(rel_dir, entry.basename) if rel_dir else entry.basename
            if entry.is_dir:
                stack.append((rel, entry))
            elif entry.basename in ("BUILD", "BUILD.bazel"):
                fail("Depot contains reserved Bazel build file '{}'".format(rel))
            else:
                found.append(rel)
    if stack:
        fail("Directory traversal limit exceeded under {}".format(root_dir))
    return sorted(found)

def _steam_depot_impl(repository_ctx):
    dd_dir = repository_ctx.path(repository_ctx.attr._depotdownloader_build).dirname
    dd_bin = dd_dir.get_child(
        "DepotDownloader.exe" if repository_ctx.os.name.lower().startswith("windows") else "DepotDownloader",
    )
    manifest_dir = repository_ctx.path(repository_ctx.attr.manifest)

    repository_ctx.report_progress("Downloading from Steam app:{} depot:{} manifest:{}".format(
        repository_ctx.attr.app,
        repository_ctx.attr.depot,
        repository_ctx.attr.manifest,
    ))
    args = [
        dd_bin,
        "-app",
        repository_ctx.attr.app,
        "-depot",
        repository_ctx.attr.depot,
        "-manifest",
        repository_ctx.attr.manifest,
        "-dir",
        manifest_dir,
    ]

    if repository_ctx.attr.files:
        repository_ctx.file("filelist.txt", "\n".join(repository_ctx.attr.files) + "\n")
        args += ["-filelist", "filelist.txt"]

    repository_ctx.file("_home/.keep", "")
    result = repository_ctx.execute(
        args,
        timeout = _DOWNLOAD_TIMEOUT,
        environment = {"HOME": str(repository_ctx.path("_home"))},
    )

    if result.return_code != 0:
        fail("DepotDownloader failed for app:{} depot:{} manifest:{} (exit {})\n{}\n{}".format(
            repository_ctx.attr.app,
            repository_ctx.attr.depot,
            repository_ctx.attr.manifest,
            result.return_code,
            result.stdout,
            result.stderr,
        ))

    dd_meta = manifest_dir.get_child(".DepotDownloader")
    if dd_meta.exists:
        repository_ctx.delete(dd_meta)

    exec_set = {p: True for p in repository_ctx.attr.executables}
    rel_paths = _collect_files(manifest_dir)
    executables = [p for p in rel_paths if p in exec_set]
    files = [p for p in rel_paths if p not in exec_set]
    manifest = repository_ctx.attr.manifest

    repository_ctx.file(
        "BUILD.bazel",
        """load({targets_bzl}, "steam_depot_files")

steam_depot_files(
    name = "depot",
    exec_paths = {exec_paths},
    exec_srcs = {exec_srcs},
    data_paths = {data_paths},
    data_srcs = {data_srcs},
    visibility = ["//visibility:public"],
)
""".format(
            targets_bzl = json.encode(_TARGETS_BZL),
            exec_paths = json.encode(executables),
            exec_srcs = json.encode(["{}/{}".format(manifest, p) for p in executables]),
            data_paths = json.encode(files),
            data_srcs = json.encode(["{}/{}".format(manifest, p) for p in files]),
        ),
    )

    return repository_ctx.repo_metadata(reproducible = True)

steam_depot = repository_rule(
    implementation = _steam_depot_impl,
    attrs = {
        "app": attr.string(mandatory = True),
        "depot": attr.string(mandatory = True),
        "manifest": attr.string(mandatory = True),
        "executables": attr.string_list(),
        "files": attr.string_list(),
        "_depotdownloader_build": attr.label(
            default = Label("@depotdownloader//:BUILD.bazel"),
        ),
    },
)

def _steam_repo_impl(repository_ctx):
    repository_ctx.file(
        "defs.bzl",
        "BUILD_ID = {}\n".format(json.encode(repository_ctx.attr.build_id)),
    )
    repository_ctx.file(
        "BUILD.bazel",
        """load({targets_bzl}, "steam_app_targets")

steam_app_targets(
    name = {name},
    depots = {depots},
    error = {error},
)
""".format(
            targets_bzl = json.encode(_TARGETS_BZL),
            name = json.encode(repository_ctx.original_name),
            depots = json.encode(repository_ctx.attr.depots),
            error = json.encode(repository_ctx.attr.error),
        ),
    )
    return repository_ctx.repo_metadata(reproducible = True)

steam_repo = repository_rule(
    implementation = _steam_repo_impl,
    attrs = {
        "depots": attr.string_list(),
        "build_id": attr.string(),
        "error": attr.string(),
    },
)

def steam_app(name, depots, build_id):
    depot_targets = []
    for x in depots:
        depot_repo = "{}_depot_{}".format(name, x["depot"])
        steam_depot(
            name = depot_repo,
            app = x["app"],
            depot = x["depot"],
            manifest = x["manifest"],
            executables = x["executables"],
            files = x["files"],
        )
        depot_targets.append("@{}//:depot".format(depot_repo))

    steam_repo(
        name = name,
        depots = depot_targets,
        build_id = build_id,
    )
