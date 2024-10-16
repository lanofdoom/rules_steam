load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("depotdownloader_version.bzl", "LINUX_RELEASE_SHA256", "LINUX_RELEASE_URL")

def _depotdownloader_repo_impl(ctx):
    ctx.download_and_extract(
        url = LINUX_RELEASE_URL,
        sha256 = LINUX_RELEASE_SHA256,
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
