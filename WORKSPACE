workspace(name = "com_github_lanofdoom_steamcmd")

load("@com_github_lanofdoom_steamcmd//:repositories.bzl", "steamcmd_repos")

steamcmd_repos()

load("@com_github_lanofdoom_steamcmd//:deps.bzl", "steamcmd_deps")

steamcmd_deps()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

#
# Container infrastructure for examples
#

load("@io_bazel_rules_docker//container:container.bzl", "container_pull")

container_pull(
    name = "debian",
    digest = "sha256:2b66a124e7f89004b77f57136e0c83744e861ac4c6f1d66c0d22f20907d7f5c2",
    registry = "index.docker.io",
    repository = "i386/debian",
)
