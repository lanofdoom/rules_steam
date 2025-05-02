#!/bin/bash -ue

cd $(dirname $0)

rm -rf .paket packages paket-files paket.lock

paket update
bazel run @rules_dotnet//tools/paket2bazel -- \
  --dependencies-file $(pwd)/paket.dependencies \
  --output-folder $(pwd)/paket
bazel mod deps

rm -rf .paket paket-files
