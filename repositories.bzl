load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def steamcmd_repos():
    if not native.existing_rule("io_bazel_rules_docker"):
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "59536e6ae64359b716ba9c46c39183403b01eabfbd57578e84398b4829ca499a",
            strip_prefix = "rules_docker-0.22.0",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.22.0/rules_docker-v0.22.0.tar.gz"],
        )
    if not native.existing_rule("io_bazel_rules_dotnet"):
        http_archive(
            name = "io_bazel_rules_dotnet",
            urls = ["https://github.com/bazelbuild/rules_dotnet/archive/02d7f4fbfa05ce2a8651a29dba7be997555e3642.zip"],
            sha256 = "541966631c4c780770b127ac12f8379b3ab5aee17bd4b12ae62214d9b5f1ef79",
            strip_prefix = "rules_dotnet-02d7f4fbfa05ce2a8651a29dba7be997555e3642",
        )
    if not native.existing_rule("com_github_steamre_depotdownloader"):
        http_archive(
            name = "com_github_steamre_depotdownloader",
            urls = ["https://github.com/SteamRE/DepotDownloader/archive/refs/tags/DepotDownloader_2.4.7.zip"],
            sha256 = "368e6aa045b368138fae19387d9054dcb41547cae2fecde8d8fc60146cb342e9",
            strip_prefix = "DepotDownloader-DepotDownloader_2.4.7",
            build_file = "@com_github_lanofdoom_steamcmd//downloader:depotdownloader.BUILD",
        )
