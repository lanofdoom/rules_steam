# bazel-steamcmd

Bazel build rules for creating docker containers with steam software.

Add the following to your `WORKSPACE` to use:

```
http_archive(
    name = "com_github_lanofdoom_steamcmd",
    sha256 = "xxxxxx",
    strip_prefix = "steamcmd-xxxxxx",
    urls = ["https://github.com/lanofdoom/steamcmd/archive/xxxxxx.tar.gz"],
)

load("@com_github_lanofdoom_steamcmd//:repos.bzl", "steamcmdbazel_repos")

steamcmdbazel_repos()

load("@io_bazel_rules_docker//repositories:repositories.bzl", container_repositories = "repositories")

container_repositories()

load("@com_github_lanofdoom_steamcmd//:deps.bzl", "steamcmdbazel_deps")

steamcmdbazel_deps()
```

Then instantiate the macro in a `BUILD.bazel` file:
```
load("@com_github_lanofdoom_steamcmd//:defs.bzl", "steamcmd_update")

steamcmd_update(
    name = "counterstrikesource",
    app_ids = [232330],
)

```

This macro creates a target `:counterstrikesource/tarball.tar.gz` that
contains the downloaded game from steam. It can then be incorporated
into a container:

```
load("@io_bazel_rules_docker//container:container.bzl", "container_image")

container_image(
    name = "counterstrikesource_image",
    base = "@ubuntu//image",
    directory = "/opt/game",
    tars = [
        ":counterstrikesource/tarball.tar.gz",
    ],
)
```
