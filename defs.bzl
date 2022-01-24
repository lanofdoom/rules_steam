load("@io_bazel_rules_docker//container:container.bzl", "container_layer")
load(
    "@io_bazel_rules_docker//container:layer.bzl",
    _layer = "layer",
)
load("@bazel_skylib//lib:dicts.bzl", "dicts")

def _steam_depot_layer(ctx):
    dl_dir = ctx.actions.declare_directory("{}".format(ctx.label.name))

    args = ctx.actions.args()
    if ctx.attr.app:
        args.add("-app", ctx.attr.app)
    if ctx.attr.depot:
        args.add("-depot", ctx.attr.depot)
    if ctx.attr.depot:
        args.add("-manifest", ctx.attr.manifest)
    if ctx.attr.os:
        args.add("-os", ctx.attr.os)
    args.add("-dir", dl_dir.path)
    args.add("-verify")

    ctx.actions.run(
        outputs = [dl_dir],
        arguments = [args],
        executable = ctx.executable._depotdownloader,
        execution_requirements = {
            "no-sandbox": "1",  # TODO: remove
            "no-remote-cache": "1",
        },
        progress_message = "Downlading Steam App id={} depot={} manifest={}".format(
            ctx.attr.app,
            ctx.attr.depot or "default",
            ctx.attr.manifest or "default",
        ),
    )

    return _layer.implementation(ctx, file_map = {".": dl_dir})

steam_depot_layer = rule(
    implementation = _steam_depot_layer,
    attrs = dicts.add(_layer.attrs, {
        "app": attr.string(
            mandatory = True,
        ),
        "depot": attr.string(),
        "manifest": attr.string(),
        "os": attr.string(),
        "_depotdownloader": attr.label(
            default = Label("@com_github_steamre_depotdownloader//:depotdownloader.exe"),
            executable = True,
            cfg = "exec",
        ),
    }),
    outputs = _layer.outputs,
    toolchains = _layer.toolchains,
)
