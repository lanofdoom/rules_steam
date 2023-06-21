# Steam App Image Builder

Tools for building container images containing Steam applications.

This repository contains Bazel build rules to build container images from Steam applications. The `steam_depot_layer` rule uses [depotdownloader](https://github.com/SteamRE/DepotDownloader) to create container layers with applications downloaded from Steam. [SteamDB](https://steamdb.info/apps/) can be used to find the application data to find the specific `app`, `depot`, and `manifest` ID numbers to use in the build rule. For some games multiple depots may be required (Counter-Strike: Source has separate `server` and `assets` depots).

```
load("@com_github_lanofdoom_steamcmd//:defs.bzl", "steam_depot_layer")

steam_depot_layer(
    name = "counterstrikesource_server",
    directory = "/opt/game",
    app = "232330",
    depot = "232336",
    manifest = "2107924716899862244",
)
```

This rule's dependencies must be loaded in your `WORKSPACE`:

```
http_archive(
    name = "com_github_lanofdoom_steamcmd",
    sha256 = "xxxxxx",
    strip_prefix = "steamcmd-xxxxxx",
    urls = ["https://github.com/lanofdoom/steamcmd/archive/xxxxxx.tar.gz"],
)

load("@com_github_lanofdoom_steamcmd//:repositories.bzl", "steamcmd_repos")
steamcmd_repos()

load("@com_github_lanofdoom_steamcmd//:deps.bzl", "steamcmd_deps")
steamcmd_deps()

```
