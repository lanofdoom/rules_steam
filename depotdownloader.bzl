load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _depotdownloader_module_impl(ctx):
    http_archive(
        name = "depotdownloader_windows",
        url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.5.0/DepotDownloader-windows-x64.zip",
        build_file_content = """exports_files(["DepotDownloader.exe"])""",
    )
    http_archive(
        name = "depotdownloader_linux",
        url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.5.0/DepotDownloader-linux-x64.zip",
        build_file_content = """exports_files(["DepotDownloader"])""",
        patch_cmds = ["chmod +x DepotDownloader"],
    )

depotdownloader = module_extension(implementation = _depotdownloader_module_impl)
