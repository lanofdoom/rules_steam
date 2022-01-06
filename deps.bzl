load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)
load("@io_bazel_rules_dotnet//dotnet:deps.bzl", "dotnet_repositories")

def steamcmd_deps():
    dotnet_repositories()

    container_repositories()
