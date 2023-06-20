load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def steamcmd_repos():
    if not native.existing_rule("io_bazel_rules_docker"):
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz"],
        )
    if not native.existing_rule("rules_dotnet"):
        http_archive(
            name = "rules_dotnet",
            sha256 = "77575d68c609d98b92f3df8db79944e7b60c035766e1c233349aeb1659c86ff9",
            strip_prefix = "rules_dotnet-0.8.12",
            url = "https://github.com/bazelbuild/rules_dotnet/releases/download/v0.8.12/rules_dotnet-v0.8.12.tar.gz",
        )

    if not native.existing_rule("com_github_steamre_depotdownloader"):
        http_archive(
            name = "com_github_steamre_depotdownloader",
            urls = ["https://github.com/SteamRE/DepotDownloader/archive/refs/tags/DepotDownloader_2.5.0.zip"],
            sha256 = "80bde2bc309b281d5191b429a33f77c97fbfea159ebb3576b529337297b93434",
            strip_prefix = "DepotDownloader-DepotDownloader_2.5.0",
            build_file = "@com_github_lanofdoom_steamcmd//downloader:depotdownloader.BUILD",
        )
