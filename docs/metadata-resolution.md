# Resolving Steam App and Depot Metadata

Packaging a Steam app into Bazel targets (`tar`, `mtree`, `filegroup`) requires downloading one or more Steam depots and assembling them into a single filesystem tree. Beyond the depot file contents themselves, up to three pieces of metadata are needed from Steam:

- **Ordered `(app_id, depot_id, manifest_id)` tuples:** Each tuple identifies one depot snapshot. `app_id` must be the outer target AppID even for shared depots (see [Shared depots and `depotfromapp`](#shared-depots-and-depotfromapp)). Tuple order defines last-depot-wins precedence when depots collide on the same file path.
- **Executable file paths (`0x20` manifest flag):** Tells Bazel's packaging rules which paths get `0755` permissions (`0644` otherwise) in archives and container layers, optionally merged with user-supplied overrides.
- **Branch `buildid` (optional):** Steam's monotonic build number for the target branch, useful when stamping container image tags or release artifacts.

The first half of this document records how Steam, `DepotDownloader`, and Bazel behave. The second half weighs the design trade-offs around *when* and *how* to resolve this metadata.

## Reference

Behaviors marked *observed* below were verified against `DepotDownloader 3.4.0` and Bazel 9.3.3 using Half-Life Dedicated Server (`90`, with shared depot `1` from Half-Life `70`) and SCP: Secret Laboratory Dedicated Server (`996560`).

### Shared depots and `depotfromapp`

Steam publishes app and package metadata through PICS (Product Info Cache Server). An app's PICS `appinfo` defines its branches (each with a `buildid`), depot list, OS/architecture filters, and flags such as `FreeToDownload`. Normally, each depot entry lists its branch manifest IDs directly.

Dedicated servers often reuse depots owned by shared redistributables or paid parent games instead of duplicating them. On the server app, that depot entry sets `depotfromapp` to the owning AppID and omits `manifests`. For example, Half-Life Dedicated Server (`90`) mounts depot `1` with `depotfromapp = 70` (Half-Life), so depot `1`'s branch manifest IDs live in app `70`'s `appinfo`.

Across a download, Steam splits those two AppIDs by protocol step:

- **Entitlement checks and depot decryption keys** use the outer server AppID (`90`). Anonymous Steam3 sessions hold only license package `17906` (dedicated-server apps and depots) plus apps with `FreeToDownload = 1`, not paid parent games like `70`.
- **Branch manifest IDs and CDN manifest request codes** use the `depotfromapp` AppID (`70`), except CDN request codes keep the outer server AppID when `FreeToDownload = 1` is set on the outer server app.

### `DepotDownloader` CLI and output

```sh
# 1. App metadata (discovers matching depots for branch/OS/arch; skips file chunks)
DepotDownloader -app <app_id> -branch <branch> -os <os> -osarch <arch> [-language <lang>] -manifest-only [-dir <dir>]

# 2. Single-depot metadata (skips file chunks)
DepotDownloader -app <app_id> -depot <depot_id> -manifest <manifest_id> -manifest-only -dir <dir>

# 3. Single-depot content download (fetches chunks into <dir>; sets +x on POSIX when 0x20 is set)
DepotDownloader -app <app_id> -depot <depot_id> -manifest <manifest_id> -dir <dir> [-filelist <file>]
```

At startup, `DepotDownloader` checks account access against `-app`, then internally switches each shared depot's AppID to `depotfromapp` (`70`) before requesting its CDN manifest code (unless `FreeToDownload = 1` is set on the outer server app). Consequently, `-app` on every CLI invocation must be the outer server AppID (`-app 90`). *Observed (`DepotDownloader 3.4.0`):* `stdout` logs `Got manifest request code for depot 1 from app 70, manifest ...`, but passing `-app 70` on a subsequent run fails the startup access check with `App 70 (Half-Life) is not available from this account`.

When run with `-manifest-only`, `DepotDownloader 3.4.0` spreads metadata across disk paths and `stdout` rather than a single structured file:

| Metadata | Where `DepotDownloader 3.4.0` emits it | Invocation & observed quirks |
| --- | --- | --- |
| Depot order & `(depot_id, manifest_id)` | `stdout`: `Processing depot <id>` followed by `Manifest <gid> (<date>)` | Invocation 1. *Observed:* `Manifest <gid>` still prints on cache hits after `Already have manifest ...`, and `Processing depot` may be preceded on the same line by OSC `9;4` ANSI progress sequences without a newline. |
| `0x20` executable flags & file table | `manifest_<depot>_<manifest>.txt` (`Size`, `Chunks`, `File SHA`, hex `Flags`, unquoted `Name`) | Invocations 1 and 2 (unfiltered by `-filelist`). *Observed:* Invocation 3 caches only the binary protobuf `.DepotDownloader/<depot>_<manifest>.manifest`, never `manifest_*.txt`. |
| Branch `buildid` | Directory path `depots/<depot_id>/<buildid>/` | Invocation 1 *without* `-dir` only. *Observed:* passing `-dir` flattens all `manifest_*.txt` files into `<dir>/` and omits `buildid` completely. When a depot falls back to `public`, `DepotDownloader` writes that depot under `public`'s `buildid`, so one beta-branch run can produce multiple `<buildid>` directories. |
| Branch fallback | `stdout`: `Warning: Depot <id> does not have branch named "<branch>". Trying public branch.` | Invocation 1. *Observed:* exits `0` both when `<branch>` does not exist on the app and when `<branch>` is a valid beta branch whose shared depot inherits `public`. |
| Missing depot key / access | `stdout` error/warning lines (e.g. `No valid depot key for <id>`) | Invocation 1. *Observed:* `DepotDownloader` skips the depot and can still exit `0` when other depots succeed. |

### Bazel constraints

- **Output-base sandboxing:** Starlark (`module_ctx`, `repository_ctx`, and build actions) can only write inside Bazel's output base. Writing into the workspace source tree requires `bazel run` (`BUILD_WORKSPACE_DIRECTORY`).
- **`MODULE.bazel.lock` caching:** Extensions returning `reproducible = True` are omitted from `MODULE.bazel.lock`. Extensions returning `reproducible = False` have their generated repo definitions recorded in `MODULE.bazel.lock` and reused until inputs change or `bazel mod deps --lockfile_mode=refresh` refreshes all non-reproducible extensions in the workspace.
- **Archive file modes:** Hermetic `mtree` manifests (`tar.bzl`) set `0755` vs `0644` modes explicitly rather than reading host file permissions, `repository_ctx.path` has no `stat` API, and Windows NTFS has no POSIX execute bit. Executable paths must come from manifest metadata (intersected with downloaded files when `-filelist` is used).

## Design space

There are two largely independent choices: **when** metadata is resolved (during `bazel build` fetch vs. an explicit `bazel run` update step) and **how** Steam is queried.

### Resolution timing

#### 1. Fetch-time app resolution

A `MODULE.bazel` extension tag (`steam.app` without `lock_file`) runs `DepotDownloader` inside `module_ctx.execute`, parses the manifest metadata in Starlark, and instantiates per-depot download repos (`reproducible = False`).

- **Pros:** No separate update step or committed per-app lockfile; zero Python/.NET runtime invocations; `MODULE.bazel.lock` caches resolved manifests and executable lists across builds.
- **Cons:** Large, opaque `MODULE.bazel.lock` diffs; `bazel mod` refreshes all non-reproducible extensions together rather than per app.

#### 2. Pinned manifests, fetch-time flags

`(app_id, depot_id, manifest_id)` tuples are pinned in source without executable lists (`reproducible = True`). Each depot repo resolves manifest flags alongside download and parses them in Starlark.

- **Pros:** Nothing written to `MODULE.bazel.lock`; compact manifest pins.
- **Cons:** Adds a second `DepotDownloader` call per depot on cold fetches (~2-5s per depot, fanning out concurrent Steam CM logins on multi-depot apps, though skipped on Bazel repo-cache hits); still needs an external way to discover depots and `buildid` on updates.

#### 3. Update-time lockfile

`steam.app(..., lock_file = "//:...")` reads a committed per-app JSON lockfile written ahead of time by `bazel run @rules_steam//steam:pin` (`reproducible = True`).

- **Pros:** One download call per depot with zero Steam queries during `bazel build`; isolated per-app updates and small JSON diffs; detects drift between `MODULE.bazel` and the lockfile; exposes `buildid` without touching `MODULE.bazel.lock`.
- **Cons:** Uses Python during `bazel run @rules_steam//steam:pin` to write via `BUILD_WORKSPACE_DIRECTORY`; stores executable lists in git.

*(See [`design-rationale.md`](design-rationale.md) for why `rules_steam` unifies Option 3 and Option 1 behind `steam.app`.)*

### Metadata sources

#### `DepotDownloader -manifest-only`

Running `DepotDownloader -manifest-only` supplies all three inputs from the same prebuilt binary used for downloads: depot order and `(depot_id, manifest_id)` pairs from `stdout`, `0x20` flags from `manifest_<depot>_<manifest>.txt`, and (without `-dir`) `buildid` from `depots/<depot>/<buildid>/` correlated with `stdout` fallback warnings.

- **Small footprint:** Fetch-time Starlark needs no language runtime, and an update-time Python wrapper needs zero `pip` packages while matching the CLI boundary needed for a JSON flag.
- **Text coupling:** Scraping `stdout` (ANSI sequences, zero-exit depot errors) and space-padded `manifest_*.txt` columns can break if `DepotDownloader` changes console formatting.
- **Heuristic branch check:** Because `DepotDownloader 3.4.0` exits `0` on unknown branches with the same warning as inherited depots, rejecting runs where *every* depot falls back to `public` catches typos in practice, with an opt-out flag for valid all-inherited beta branches.

#### C# Steam3 client (`SteamKit2`)

An update-time C# tool built on `SteamKit2` resolves PICS metadata and decrypted `DepotManifest` protobufs in memory without text scraping. This was the original `rules_steam` approach ([`rules_steam@ca1d739`](https://github.com/lanofdoom/rules_steam/tree/ca1d739b7045b5fc0057f49f7ad2c72f8450f872/generate)). Carrying `rules_dotnet`, a .NET SDK, and Paket/NuGet extensions in `MODULE.bazel` adds heavy Bzlmod graph weight for consumers, vendored C# code still mirrors `DepotDownloader`'s `17906`, `FreeToDownload`, and `depotfromapp` rules, and fetch-time `steam.app` still needs `-manifest-only` or a .NET runtime in `module_ctx`.

#### Python Steam3 client

A Python client replaces `rules_dotnet` with `rules_python`, `protoc`-compiled `SteamTracking/Protobufs`, and `pip` wheels (`websockets`, `vdf`, `cryptography`) over Steam's CM WebSocket protocol. While lighter than `rules_dotnet`, it still adds `protobuf`, `SteamTracking/Protobufs`, and `pip.parse` to consumers' Bzlmod graphs, owns low-level Steam3 framing (`CMsgMulti`, job routing, CDN tokens, AES filename decryption) plus `depotfromapp` rules, and does not help zero-Python `steam.app`.

#### Forked `DepotDownloader`

Patching structured manifest output and branch validation into `DepotDownloader` ([`lanofdoom/DepotDownloader`](https://github.com/lanofdoom/DepotDownloader), currently used by `rules_steam`) keeps lockfile updates, unpinned `steam.app`, and depot downloads on a single `SteamKit2`-backed binary, reducing callers to `json.loads` / `json.decode`. The trade-off is building, hosting, and rebasing NativeAOT binaries across upstream releases (currently published for `linux-x64`).

`DepotDownloader` already holds all of this metadata in memory. Two changes make it directly consumable:

1. **Add `-manifest-json <path>`:** Download manifest metadata and write a single JSON document to `<path>` describing the resolved app, branch, `buildId`, `timeUpdated`, and ordered depots without downloading depot files or touching `./depots/` (string `manifestId` values preserve 64-bit precision, `sha1` is omitted on directories and symlinks, `linkTarget` is included only when non-empty, and both CLI `appId` and per-depot `containingAppId` are exposed):

   ```json
   {
     "appId": 90,
     "name": "Half-Life Dedicated Server",
     "branch": "public",
     "buildId": 8925347,
     "timeUpdated": "2024-09-13T19:20:39Z",
     "depots": [
       {
         "depotId": 1,
         "containingAppId": 70,
         "branch": "public",
         "manifestId": "2667117727132184734",
         "creationTime": "2024-09-13T19:20:39Z",
         "totalUncompressedSize": 318492104,
         "totalCompressedSize": 142910448,
         "files": [
           {
             "path": "hlds_linux",
             "size": 229376,
             "chunks": 1,
             "sha1": "...",
             "flags": 32
           }
         ]
       }
     ]
   }
   ```

2. **Fail non-zero on unknown `-branch`, empty depot sets, or missing non-DLC depot keys:** Check `branch` against the app's `depots.branches` table before resolving depots (still allowing individual depots within a valid branch to fall back to `public`), and fail non-zero without writing `<path>` if zero depots resolve or a matched non-DLC depot lacks a decryption key.

Both changes fit in a small fork of `ContentDownloader.DownloadAppAsync`, which already filters depots by `oslist` / `osarch` / `language` / `lowviolence`, reads the branch `buildid` via `GetSteam3AppBuildNumber`, and resolves each depot's `DepotDownloadInfo` (`depotfromapp`, manifest ID, depot key) via `GetDepotInfo` before downloading chunks. The C# generator at [`rules_steam@ca1d739`](https://github.com/lanofdoom/rules_steam/blob/ca1d739b7045b5fc0057f49f7ad2c72f8450f872/generate/ContentDownloader.cs) (`LookupManifestsForAppAsync`) is that same path truncated after depot resolution. The fork adds a branch-existence check against `depots.branches` before filtering. When `-manifest-json <path>` is set, it serializes the resolved app, branch, `buildId`, `timeUpdated`, and ordered depots (plus each depot's full file table when the manifest is fetched) with `Utf8JsonWriter`, which is in-box and NativeAOT-safe. It writes the result to `<path>` through a temp file and rename, only on exit `0`, and leaves `stdout` logging untouched.

#### Comparison

| Approach | Extra Bazel deps | Parsing fragility | Branch validation | `buildid` available | Maintenance burden |
| --- | --- | --- | --- | --- | --- |
| `DepotDownloader -manifest-only` (Starlark only) | None | Medium (`stdout` + text table) | Heuristic (reject total fallback) | Only without `-dir` | Low (1 parser) |
| `DepotDownloader -manifest-only` (Python + Starlark) | `rules_python` | Medium (`stdout` + text table, 2 parsers) | Heuristic (reject total fallback) | Updater: yes; `steam.app`: omitted with `-dir` | Low-medium (shared fixtures) |
| C# Steam3 client (`SteamKit2`) | `rules_dotnet`, Paket | None (protobufs) | Exact (`depots.branches`) | Yes | High (heavy toolchain + vendored logic) |
| Python Steam3 client | `rules_python`, `protobuf`, `pip` | None (protobufs) | Exact (`depots.branches`) | Yes | High (custom Steam3 wire/crypto) |
| Forked `DepotDownloader` (`-manifest-json`) | None (or `rules_python` for `//steam:pin`) | None (JSON) | Exact (`depots.branches`) | Yes | Medium (rebasing NativeAOT fork) |

## Open questions

- **Is `MODULE.bazel.lock` enough to drop `lock_file` and `//steam:pin`?** Dropping `//steam:pin` removes `rules_python`, at the cost of workspace-wide `bazel mod` refreshes and opaque `MODULE.bazel.lock` diffs instead of isolated per-app JSON lockfiles.
- **Upstream `-manifest-json` and strict `-branch` into `SteamRE/DepotDownloader`?** Upstream acceptance would let `rules_steam` drop the `lanofdoom/DepotDownloader` fork and inherit upstream multi-platform releases automatically.
