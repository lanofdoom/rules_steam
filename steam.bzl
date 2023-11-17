# TODO(kleinpa): refactor to download files when loading repository.

_STEAM_BUILD = """
load("@rules_steam//:defs.bzl", "steam_download")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_pkg//:mappings.bzl", "pkg_filegroup", "pkg_files")

steam_download(
    name = "pkg",
    app = "{app}",
    depot = "{depot}",
    manifest = "{manifest}",
)

pkg_files(
    name = "files",
    srcs = [":pkg"],
    strip_prefix = "pkg",
    visibility = ["//visibility:public"]
)
"""

def _steam_repo_impl(ctx):
    ctx.file("WORKSPACE", "workspace(name = \"{name}\")".format(name = ctx.name))
    ctx.file("BUILD.bazel", _STEAM_BUILD.format(name = ctx.attr.name, app = ctx.attr.app, depot = ctx.attr.depot, manifest = ctx.attr.manifest))

steam_repo = repository_rule(
    implementation = _steam_repo_impl,
    attrs = {
        "app": attr.string(
            mandatory = True,
        ),
        "depot": attr.string(),
        "manifest": attr.string(),
        "os": attr.string(),
    },
)

_app = tag_class(attrs = {"name": attr.string(), "app": attr.string()})
_depot = tag_class(attrs = {"name": attr.string(), "app": attr.string(), "depot": attr.string(), "manifest": attr.string()})

def _steam_module_impl(module_ctx):
    for mod in module_ctx.modules:
        for app in mod.tags.app:
            steam_repo(
                name = app.name,
                app = app.app,
            )
        for depot in mod.tags.depot:
            steam_repo(
                name = depot.name,
                app = depot.app,
                depot = depot.depot,
                manifest = depot.manifest,
            )

steam = module_extension(
    implementation = _steam_module_impl,
    tag_classes = {"app": _app, "depot": _depot},
)
