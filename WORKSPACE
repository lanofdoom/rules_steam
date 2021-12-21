workspace(name = "com_github_lanofdoom_steamcmd")

load("@com_github_lanofdoom_steamcmd//:repos.bzl", "steamcmdbazel_repos")

steamcmdbazel_repos()

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@com_github_lanofdoom_steamcmd//:deps.bzl", "steamcmdbazel_deps")

steamcmdbazel_deps()
