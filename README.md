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

### Load generated extension in `MODULE.bazel`

```python
steamapps = use_extension("//:steamapps.bzl", "steamapps_bzlmod")
use_repo(steamapps, "my_game_server")
```

### Consume the content

Once configured, these rules produce [`pkg_files`](https://bazelbuild.github.io/rules_pkg/latest.html#pkg_files) targets available like `@my_game_server//:files`.

Those rules can be used to produce any of the other [`rules_pkg`](https://bazelbuild.github.io/rules_pkg/latest.html) package formats for further use. For example:

```py
pkg_tar(
    name = "my_game_server",
    srcs = ["@my_game_server//:files"],
    package_dir = "/opt/scpsl",
)
```

### Set up automated updates

Configure automation to periodically run the update script and commit the results.

See [update-example.yml](.github/workflows/update-example.yml) for one approach. For annoying reasons, this requires permissions beyond the standard `GITHUB_TOKEN`, so a personal or application token must be used as explained in the [GitHub Docs](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#granting-additional-permissions).
