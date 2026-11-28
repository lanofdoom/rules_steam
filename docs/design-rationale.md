# Design Rationale

[`metadata-resolution.md`](metadata-resolution.md) covers how Steam and `DepotDownloader` behave and maps out the design space. This document explains why `rules_steam` unifies configuration around **`steam.app` in `MODULE.bazel`**, centering on **pinned per-app JSON lockfiles (`lock_file` + `bazel run @rules_steam//steam:pin`) updated on a CI schedule** while supporting unpinned branch-HEAD resolution when `lock_file` is omitted.

## Pinning in source

Bazel rulesets normally declare dependencies in `MODULE.bazel` and resolve floating versions into committed JSON or lockfiles outside `bazel build`:

- `rules_jvm_external` declares artifacts in `maven.install(..., lock_file = "//:maven_install.json")` and repins via `bazel run @unpinned_maven//:pin`.
- `rules_rust` pins crates in `Cargo.Bazel.lock` / `Cargo.lock`, and `rules_python` compiles `requirements_lock.txt` via `bazel run`.

Steam branches (`public`, `beta`) are mutable channels too. Adding `lock_file = "//:..."` on `steam.app` keeps `bazel build` deterministic, turns server updates into small CI-tested JSON commits showing the new `buildId` and manifest IDs, fails builds immediately if `MODULE.bazel` and the lockfile drift out of sync, and keeps `MODULE.bazel.lock` clean (`reproducible = True`).

## Automated updates

Renovate and Dependabot work by querying public HTTP registries, which Valve does not provide for PICS depot metadata or encrypted CDN manifests (and unofficial third-party mirrors are neither trustworthy for builds nor able to see AES-encrypted `0x20` file flags). Resolving `(app_id, branch, os, arch)` requires logging into Steam3 anonymously (`17906`), walking PICS `depotfromapp` links, and decrypting depot manifests.

`@rules_steam//steam:pin` fills that gap as a scheduled CI step (for example, `bazelisk run @rules_steam//steam:pin` in [`examples/`](../examples) via [`.github/workflows/update-example.yml`](../.github/workflows/update-example.yml)). Passing an app name (`bazelisk run @rules_steam//steam:pin -- my_server`) updates a single lockfile for isolated, `bazel test`-gated bumps.

## Update-time vs. fetch-time flags

Pinning bare `(app_id, depot_id, manifest_id)` tuples and resolving `0x20` flags at fetch time ([Option 2](metadata-resolution.md#2-pinned-manifests-fetch-time-flags)) is a natural middle ground, but resolving flags at update time wins out in practice:

1. **Bumping already needs Steam3.** Discovering depots, following `depotfromapp`, and reading `buildid` already runs `DepotDownloader` in CI. Recording the `0x20` flags from that same `-manifest-json` run is free; omitting them does not remove `//steam:pin`.
2. **Faster cold fetches.** Each `steam_depot` runs one download instead of adding a 2-5 second Steam3 login per depot.
3. **Self-contained pins.** Committed lockfiles already hold everything `tar.bzl` needs during `bazel build`.

## Implementation choices

- **Single `steam.app` declaration for pinned and unpinned modes.** Both modes share the same `MODULE.bazel` tag, JSON parser (`parse.bzl`), and `@<repo>` surface (`@<repo>`, `:tar`, `:mtree`, `defs.bzl`), while `//steam:pin` reads tag definitions from an internal `@steam_pins` metadata repo without downloading depots.
- **Use a minimal `DepotDownloader` fork (`-manifest-json` + strict `-branch`) instead of a custom Steam3 client.** Earlier C# (`SteamKit2` + `rules_dotnet` + Paket) and Python (`SteamTracking/Protobufs` + `protobuf` + `pip` wheels) generators added heavy Bzlmod dependencies and duplicated `DepotDownloader`'s `depotfromapp` logic, while upstream `-manifest-only` required fragile console/table text scraping. Adding `-manifest-json` and branch validation in [`lanofdoom/DepotDownloader`](https://github.com/lanofdoom/DepotDownloader) reduces both Python and Starlark callers to trivial JSON decoding with zero `pip` wheels.
- **Package layers in `BUILD.bazel` with `steam_tar` (`tar.bzl`).** Keeping `package_dir` and `owner`/`group` in `BUILD.bazel` next to `oci_image` preserves standard Bazel separation between fetching (`MODULE.bazel`) and image layout (`BUILD.bazel`), using statically-linked C `bsdtar` instead of Python `tarfile`.

## Costs

- Maintaining a small [`lanofdoom/DepotDownloader`](https://github.com/lanofdoom/DepotDownloader) fork (currently publishing `linux-x64` NativeAOT binaries) until `-manifest-json` and strict `-branch` can be upstreamed.
- `rules_python` is in consumers' Bzlmod graph (the interpreter is only fetched if `//steam:pin` is built or run).
- Executable file lists are checked into `*.lock.json`.
- Automated bumps need a scheduled CI workflow with push or PR permissions.
