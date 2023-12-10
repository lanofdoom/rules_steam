def _steam_download_impl(ctx):
    dl_dir = ctx.actions.declare_directory("{}".format(ctx.label.name))

    args = ctx.actions.args()
    if ctx.attr.app:
        args.add("-app", ctx.attr.app)
    if ctx.attr.depot:
        args.add("-depot", ctx.attr.depot)
    if ctx.attr.depot:
        args.add("-manifest", ctx.attr.manifest)
    args.add("-dir", dl_dir.path)
    args.add("-verify")

    args.add("-os", ctx.attr.os)

    info = ctx.toolchains["@rules_steam//:toolchain_type"].depotdownloaderinfo
    ctx.actions.run(
        outputs = [dl_dir],
        arguments = [args],
        executable = info.depotdownloader,
        execution_requirements = {
            "no-sandbox": "1",  # TODO: remove
            "no-remote-cache": "1",
        },
        progress_message = "Downlading from Steam id={} depot={} manifest={} os={}".format(
            ctx.attr.app,
            ctx.attr.depot or "default",
            ctx.attr.manifest or "default",
            ctx.attr.os or "default",
        ),
    )

    return [DefaultInfo(files = depset([dl_dir]))]

steam_download = rule(
    implementation = _steam_download_impl,
    attrs = {
        "app": attr.string(
            mandatory = True,
        ),
        "depot": attr.string(),
        "manifest": attr.string(),
        "os": attr.string(),
    },
    toolchains = ["@rules_steam//:toolchain_type"],
)
