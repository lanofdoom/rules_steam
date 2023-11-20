# Bazel rules for downloading Steam applications

These rules produce `.tar` targets downloaded from Steam for downsteam build rules to consume.

Currently only content available without authentication is available, this includes most dedicated servers: https://steamdb.info/sub/17906/.

Use `app`, `depot`, and `manifest` ID numbers found on [SteamDB](https://steamdb.info/apps/) to populate entries in `MODULE.bazel`. Some applications use multiple depots that must be downloaded separately when using the `depot` style dependencies. `app()` rules target all depots associated with the current version of the application while `depot()` rules may specify an exact version.

Add this to `MODULE.bazel`:

```Starlark
bazel_dep(name = "rules_steam", version = "...")

steam = use_extension("@rules_steam//:steam.bzl", "steam")
steam.app(name = "battlebit_dedicated", app = "689410")
steam.depot(name = "steamworks_linux", app = "1007", depot = "1006", manifest = "4884950798805348056")
use_repo(
    steam,
    "battlebit_dedicated",
    "steamworks_linux",
)
```

Now repositories will be available with rules to produce `@battlebit_dedicated//:files` and `@steamworks_linux//:files`.

```Starlark
load("@rules_pkg//:pkg.bzl", "pkg_tar")

pkg_tar(
    name = "battlebit_dedicated",
    srcs = ["@battlebit_dedicated//:files"],
    package_dir = "/opt/battlebit",
)
```
