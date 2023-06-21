load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def steamcmd_repos():
    if not native.existing_rule("io_bazel_rules_docker"):
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz"],
        )

    if not native.existing_rule("com_github_steamre_depotdownloader"):
        http_archive(
            name = "com_github_steamre_depotdownloader",
            url = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.5.0/DepotDownloader-linux-x64.zip",
            sha256 = "45fceab12f352943bb618f50abe3e03f48831233f541acf08f8340c8ecbee0f8",
            #build_file = "@com_github_lanofdoom_steamcmd//downloader:depotdownloader.BUILD",
            build_file_content = 'genrule(name = "depotdownloader.exe", srcs = ["DepotDownloader"], outs = ["DepotDownloader.exe"], cmd = "cp $< $@", executable = 1, visibility = ["//visibility:public"])',
        )
