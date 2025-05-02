`generate` is a tool to query steam for the latest manifests for a particular game and produce a bazel file that will make the files referenced by those manifests available to the rest of the build process. It is intended to run continuously as part of CI automation to pull the latest game versions into a build workflow.

Check out [`/examples`](../examples) and especially [`/examples/update-steamapps.sh`](../examples/update-steamapps.sh) to see how this all fits together.

`generate`'s C# source is derived from https://github.com/SteamRE/DepotDownloader and is licensed under the GPL. See LICENSE for details. Extra special thanks to all the https://github.com/SteamRE contributors.
