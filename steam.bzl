_STEAM_DEPOT_BUILD = """
load("@rules_pkg//:mappings.bzl", "pkg_files")
load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes")

pkg_files(
    name = "{repo}",
    srcs = glob(["{manifest}/**"], exclude = ["**/.DepotDownloader/**"]),
    strip_prefix = "{manifest}",
    visibility = ["//visibility:public"],
    attributes = pkg_attributes(mode = "0755"), # TODO: remove pending https://github.com/bazelbuild/rules_pkg/issues/822
)
"""

def _steam_depot_impl(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        _STEAM_DEPOT_BUILD.format(
            repo = repository_ctx.original_name,
            manifest = repository_ctx.attr.manifest,
        ),
    )

    if repository_ctx.os.name.startswith("windows"):  # TODO: there must be a better way...
        repository_ctx.download_and_extract(
            url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_3.4.0/DepotDownloader-windows-x64.zip",
            sha256 = "sha256-Qcnp8N9Us60C5noRcmdW5ccyg718LhsErPpa5MLtN2c=",
        )
        repository_ctx.file("BUILD", 'alias(name="depotdownloader", actual="DepotDownloader.exe", visibility = ["//visibility:public"])')
    else:
        repository_ctx.download_and_extract(
            url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_3.4.0/DepotDownloader-linux-x64.zip",
            integrity = "sha256-qZnexmtIUPyWG9UDZmltI8LQ+texh5DmpWR7LxkJelM=",
        )
        repository_ctx.execute(["chmod", "+x", "depotdownloader.exe"])
        repository_ctx.file("BUILD", 'alias(name="depotdownloader", actual="DepotDownloader", visibility = ["//visibility:public"])')

    repository_ctx.report_progress("Downlading from Steam app:{} depot:{} manifest:{}".format(
        repository_ctx.attr.app,
        repository_ctx.attr.depot,
        repository_ctx.attr.manifest,
    ))
    repository_ctx.execute([
        "./DepotDownloader",
        "-app",
        repository_ctx.attr.app,
        "-depot",
        repository_ctx.attr.depot,
        "-manifest",
        repository_ctx.attr.manifest,
        "-dir",
        repository_ctx.path(repository_ctx.attr.manifest),
    ])

_steam_depot = repository_rule(
    implementation = _steam_depot_impl,
    attrs = {
        "app": attr.string(mandatory = True),
        "depot": attr.string(mandatory = True),
        "manifest": attr.string(mandatory = True),
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
    """Creates a steam app repository.

    Args:
        name: The name of the repository.
        depots: A list of depot dictionaries. Each dictionary should contain
            the keys "app", "depot", and "manifest".
    """
    depot_repos_files = []
    for x in depots:
        _steam_depot(
            name = "depot" + x["depot"],
            app = x["app"],
            depot = x["depot"],
            manifest = x["manifest"],
        )
    _steam_repo(name = name, depot_repos_files = ["@depot" + x["depot"] for x in depots])
