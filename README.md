# `rules_steam`

Bazel build rules for downloading software from Steam.

These rules are currently only suitable for steam content that can be downloaded without authentication (https://steamdb.info/sub/17906/).

Using `app`, `depot`, and `manifest` ID numbers found on [SteamDB](https://steamdb.info/apps/). Some apps use multiple depots that must be downloaded separately when using the `depot` style dependencies. (Counter-Strike: Source has separate `server` and `assets` depots). Only the `depot` version of this rule is hermetic.

Add this to `MODULE.bazel`:

```
bazel_dep(name = "rules_steam", version = "...")
steam = use_extension("@rules_steam//:download.bzl", "steam")
steam.app(name = "battlebit_dedicated", app = "689410")
steam.depot(name = "steamworks_linux", app = "1007", depot = "1006", manifest = "4884950798805348056")
use_repo(
    steam,
    "battlebit_dedicated",
    "steamworks_linux",
)
```

Now repositories will be available with rules to produce `@battlebit_dedicated//:files` and `@steamworks_linux//:files`.

```
pkg_tar(
    name = "battlebit_dedicated",
    srcs = ["@battlebit_dedicated//:files"],
    package_dir = "/opt/battlebit",
)
```
