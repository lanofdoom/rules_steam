load("@io_bazel_rules_docker//container:container.bzl", "container_pull")
load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

def steamcmdbazel_deps():
    container_deps()

    if not native.existing_rule("steamcmd_installer_base"):
        container_pull(
            name = "steamcmd_installer_base",
            registry = "index.docker.io",
            repository = "library/ubuntu",
            tag = "bionic",
        )
    if not native.existing_rule("steamcmd_runtime_base"):
        container_pull(
            name = "steamcmd_runtime_base",
            registry = "index.docker.io",
            repository = "library/ubuntu",
            tag = "bionic",
        )
    if not native.existing_rule("debian"):
       container_pull(
           name = "debian",
           registry = "index.docker.io",
           repository = "library/debian",
           tag = "bullseye",
       )
