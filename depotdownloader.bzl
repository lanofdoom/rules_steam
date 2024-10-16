load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _depotdownloader_repo_impl(ctx):
    if ctx.os.name.startswith("windows"):  # TODO: there must be a better way...
        ctx.download_and_extract(
            url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.7.1/DepotDownloader-windows-x64.zip",
            sha256 = "",
            rename_files = {"DepotDownloader.exe": "depotdownloader.exe"},
        )
    else:
        ctx.download_and_extract(
            url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.7.1/DepotDownloader-linux-x64.zip",
            sha256 = "",
            rename_files = {"DepotDownloader": "depotdownloader.exe"},
        )
        ctx.execute(["chmod", "+x", "depotdownloader.exe"])

    # Create a BUILD file containing the cc_library declaration
    ctx.file("BUILD", 'exports_files(["depotdownloader.exe"])')

    # Create an empty WORKSPACE file.
    ctx.file("WORKSPACE", "")

depotdownloader_repo = repository_rule(
    implementation = _depotdownloader_repo_impl,
    attrs = {
        "workspace_name": attr.string(mandatory = True),
    },
)

def _depotdownloader_module_impl(ctx):
    depotdownloader_repo(name = "depotdownloader", workspace_name = "depotdownloader")

depotdownloader = module_extension(implementation = _depotdownloader_module_impl)
