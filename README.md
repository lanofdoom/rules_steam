# Bazel rules for downloading Steam apps

These rules make Steam applications available as Bazel repositories.

Limitations:

- Authentication is not supported so only [free-to-download](https://steamdb.info/sub/17906/apps/) apps may be used

# Setup

### Add `rules_steam` and declare apps in [`MODULE.bazel`](examples/MODULE.bazel)

```python
bazel_dep(name = "rules_steam")

git_override(
    module_name = "rules_steam",
    commit = "...",
    remote = "https://github.com/lanofdoom/rules_steam.git",
)

steam = use_extension("@rules_steam//steam:extensions.bzl", "steam")
steam.app(
    name = "my_game_server",
    app = 42,
    os = "linux",
    lock_file = "//:my_game_server.lock.json",
)
use_repo(steam, "my_game_server")
```

Run `bazel run @rules_steam//steam:pin` (or `bazel run @rules_steam//steam:pin -- my_game_server` for a single app) to resolve branch `buildId`, depot manifests, and executable permissions into the committed [lockfile](examples/scpsl.lock.json).

Omit `lock_file` to resolve directly from branch HEAD during `bazel build` (cached in `MODULE.bazel.lock`).

Pass `files = [...]` (e.g. `files = ["srcds_linux64", "bin/linux64/libsteam_api.so"]`, or `regex:`-prefixed patterns) to limit downloaded files, and `executables = [...]` to mark additional paths `0755`.

### Consume the content

Each app repository exposes `@my_game_server` (overlaid files + `SteamAppInfo`), `@my_game_server//:tar`, `@my_game_server//:mtree`, and `BUILD_ID` via `load("@my_game_server//:defs.bzl", "BUILD_ID")`, preserving manifest executable permissions and last-depot-wins overlays.

Use `steam_tar` in [`BUILD.bazel`](examples/BUILD.bazel) to package an app into a container layer without declaring `tar.bzl` directly:

```python
load("@rules_steam//steam:defs.bzl", "steam_tar")

steam_tar(
    name = "my_game_server_layer",
    src = "@my_game_server",
    package_dir = "/opt/scpsl",
    owner = 1000,
    group = 1000,
)
```

For custom [`tar.bzl`](https://registry.bazel.build/modules/tar.bzl) pipelines, consume `@my_game_server` and `@my_game_server//:mtree` directly.

### Set up automated updates

Configure automation to periodically run `bazel run @rules_steam//steam:pin` and commit the updated lockfile.

See [update-example.yml](.github/workflows/update-example.yml) for one approach. For annoying reasons, this requires permissions beyond the standard `GITHUB_TOKEN`, so a personal or application token must be used as explained in the [GitHub Docs](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#granting-additional-permissions).
