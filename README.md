# Bazel rules for downloading Steam apps

These rules make Steam applications available as Bazel repositories.

Limitations:

- Authentication is not supported so only [free-to-download](https://steamdb.info/sub/17906/apps/) apps may be used
- External automation is required for application updates

# Setup

### Add `rules_steam` to `MODULE.bazel`

```python
bazel_dep(name = "rules_steam")

git_override(
    module_name = "rules_steam",
    commit = "...",
    remote = "https://github.com/lanofdoom/rules_steam.git",
)
```

### Create [`update-steamapps.sh`](examples/update-steamapps.sh) script

```sh
#!/bin/bash -ue
cd $(dirname $0)

bazel run @rules_steam//generate -- --app 42 --repo my_game_server --out $(pwd)/steamapps.bzl
bazel mod deps
```

This script generates a bazel [module extension](https://bazel.build/external/extension) [file](examples/steamapps.bzl) that will create repositories containing Steam apps.

Pass `--files` (repeatable) to limit what gets downloaded, e.g. `--files 'regex:^srcds_linux64$' --files 'regex:^bin/linux64/libsteam_api\.so$'`. Each value becomes a `DepotDownloader` `-filelist` entry (a path, or a `regex:`-prefixed pattern) and is applied to every depot in the generated file.

### Load generated extension in `MODULE.bazel`

```python
steamapps = use_extension("//:steamapps.bzl", "steamapps_bzlmod")
use_repo(steamapps, "my_game_server")
```

### Consume the content

Each app repository exposes `@my_game_server` (overlaid files + `SteamAppInfo`), `@my_game_server//:tar`, `@my_game_server//:mtree`, and `BUILD_ID` via `load("@my_game_server//:defs.bzl", "BUILD_ID")`, preserving manifest executable permissions and last-depot-wins overlays.

Use `steam_tar` to package an app into a container layer without declaring `tar.bzl` directly:

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

Configure automation to periodically run the update script and commit the results.

See [update-example.yml](.github/workflows/update-example.yml) for one approach. For annoying reasons, this requires permissions beyond the standard `GITHUB_TOKEN`, so a personal or application token must be used as explained in the [GitHub Docs](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#granting-additional-permissions).
