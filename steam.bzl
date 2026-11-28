_STEAM_DEPOT_BUILD = """
load("@rules_pkg//:mappings.bzl", "pkg_files")
load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes")

pkg_files(
    name = "{repo}",
    srcs = glob(["{manifest}/**"], exclude = ["**/.DepotDownloader/**"], allow_empty = True),
    strip_prefix = "{manifest}",
    visibility = ["//visibility:public"],
    attributes = pkg_attributes(mode = "0755"),
)
"""

_DOWNLOAD_TIMEOUT = 14400

def _steam_depot_impl(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        _STEAM_DEPOT_BUILD.format(
            repo = repository_ctx.original_name,
            manifest = repository_ctx.attr.manifest,
        ),
    )

    dd_dir = repository_ctx.path(repository_ctx.attr._depotdownloader_build).dirname
    dd_bin = dd_dir.get_child(
        "DepotDownloader.exe" if repository_ctx.os.name.lower().startswith("windows") else "DepotDownloader",
    )

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
        repository_ctx.path(repository_ctx.attr.manifest),
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

_steam_depot = repository_rule(
    implementation = _steam_depot_impl,
    attrs = {
        "app": attr.string(mandatory = True),
        "depot": attr.string(mandatory = True),
        "manifest": attr.string(mandatory = True),
        "files": attr.string_list(),
        "_depotdownloader_build": attr.label(
            default = Label("@depotdownloader//:BUILD.bazel"),
        ),
    },
)

_STEAM_REPO_BUILD = """
load("@rules_pkg//:mappings.bzl", "pkg_filegroup")

pkg_filegroup(
    name = "files",
    srcs = [{files}],
    visibility = ["//visibility:public"]
)
"""

def _steam_repo_impl(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        _STEAM_REPO_BUILD.format(
            name = repository_ctx.attr.name,
            files = ", ".join(["\"{}\"".format(src) for src in repository_ctx.attr.depot_repos_files]),
        ),
    )

_steam_repo = repository_rule(
    implementation = _steam_repo_impl,
    attrs = {
        "depot_repos_files": attr.label_list(),
    },
)

def steam_app(name, depots):
    for x in depots:
        _steam_depot(
            name = "depot" + x["depot"],
            app = x["app"],
            depot = x["depot"],
            manifest = x["manifest"],
            files = x.get("files", []),
        )
    _steam_repo(name = name, depot_repos_files = ["@depot" + x["depot"] for x in depots])
