def _steam_download_impl(ctx):
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
        progress_message = "Downlading from Steam id={} depot={} manifest={}".format(
            ctx.attr.app,
            ctx.attr.depot or "default",
            ctx.attr.manifest or "default",
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
        "_depotdownloader": attr.label(
            default = Label("@depotdownloader"),
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
    },
)
