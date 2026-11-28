visibility(["//..."])

_VERSION = "v3.5.0-json.4"

_INTEGRITY = {
    "linux-x64": "sha256-3j8h4gOeV8H1Q5CoLDewD5DI/jQP51eZUgL3FPXFmkg=",
}

def _detect_platform(repository_ctx):
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch.lower()
    if os_name.startswith("linux") and arch in ("amd64", "x86_64", "x64"):
        return "linux-x64"
    fail("Unsupported host platform '{}/{}' for DepotDownloader (only linux-x64 is currently published)".format(
        repository_ctx.os.name,
        repository_ctx.os.arch,
    ))

def _depotdownloader_repo_impl(repository_ctx):
    platform = _detect_platform(repository_ctx)
    exe = "DepotDownloader.exe" if platform.startswith("windows") else "DepotDownloader"
    repository_ctx.download_and_extract(
        url = "https://github.com/lanofdoom/DepotDownloader/releases/download/{}/DepotDownloader-{}.tar.gz".format(
            _VERSION,
            platform,
        ),
        integrity = _INTEGRITY[platform],
    )
    repository_ctx.file(
        "BUILD.bazel",
        'exports_files(["{exe}"])\nalias(name = "bin", actual = "{exe}", visibility = ["//visibility:public"])\n'.format(
            exe = exe,
        ),
    )
    return repository_ctx.repo_metadata(reproducible = True)

depotdownloader_repo = repository_rule(
    implementation = _depotdownloader_repo_impl,
)

def _depotdownloader_ext_impl(module_ctx):
    depotdownloader_repo(name = "depotdownloader")
    return module_ctx.extension_metadata(reproducible = True)

depotdownloader = module_extension(
    implementation = _depotdownloader_ext_impl,
)
