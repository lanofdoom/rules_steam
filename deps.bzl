load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)
load(
    "@rules_dotnet//dotnet:repositories.bzl",
    "dotnet_register_toolchains",
    "rules_dotnet_dependencies",
)

def steamcmd_deps():
    rules_dotnet_dependencies()

    # Here you can specify the version of the .NET SDK to use.
    dotnet_register_toolchains("dotnet", "6.0.100")

    container_repositories()
