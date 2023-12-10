DepotdownloaderToolchainInfo = provider(
    doc = "Information about how to invoke qt tools.",
    fields = ["depotdownloader"],
)

def _depotdownloader_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        depotdownloaderinfo = DepotdownloaderToolchainInfo(
            depotdownloader = ctx.executable.depotdownloader,
        ),
    )

depotdownloader_toolchain = rule(
    implementation = _depotdownloader_toolchain_impl,
    attrs = {"depotdownloader": attr.label(
        mandatory = True,
        executable = True,
        cfg = "exec",
        allow_files = True,
    )},
)
