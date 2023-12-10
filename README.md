# Bazel rules for downloading Steam applications

These rules produce `.tar` targets downloaded from Steam for downsteam build rules to consume.

Currently only content available without authentication is available, this includes most dedicated servers: https://steamdb.info/sub/17906/.

Use `app`, `depot`, and `manifest` ID numbers found on [SteamDB](https://steamdb.info/apps/) to populate entries in `MODULE.bazel`. Some applications use multiple depots that must be downloaded separately when using the `depot` style dependencies. `app()` rules target all depots associated with the current version of the application while `depot()` rules may specify an exact version.

## Usage

```Starlark
steam = use_extension("@rules_steam//:extension.bzl", "steam", dev_dependency = True)

# Fetches a specific version of a steam depot. Most applications are composed of multiple depots.
steam.depot(name = "battlebit_dedicated", app = "689410", depot = "1611741", manifest = "6391981145455211793")

# Download all depos associated with the latest version of an application. This rule is not hermetic.
steam.app(name = "steamworks", app = "1007")

use_repo(steam, "battlebit_dedicated", "steamworks")
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
