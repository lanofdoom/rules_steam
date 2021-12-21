load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def steamcmdbazel_repos():
    if not native.existing_rule("io_bazel_rules_docker"):
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "59d5b42ac315e7eadffa944e86e90c2990110a1c8075f1cd145f487e999d22b3",
            strip_prefix = "rules_docker-0.17.0",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.17.0/rules_docker-v0.17.0.tar.gz"],
        )

    if not native.existing_rule("steamcmd_install"):
        http_file(
            name = "steamcmd_install",
            downloaded_file_path = "steamcmd_linux.tar.gz",
            sha256 = "",
            urls = ["https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"],
        )
