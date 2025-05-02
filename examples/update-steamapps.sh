#!/bin/bash -ue
cd $(dirname $0)

bazel run @rules_steam//generate -- --app 996560 --repo scpsl_dedicated_server --out $(pwd)/steamapps.bzl
bazel mod deps
