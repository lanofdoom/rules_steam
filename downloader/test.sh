#!/bin/bash -ue

cd $(dirname $0)/..

bazel run @com_github_steamre_depotdownloader//:depotdownloader.exe -- $@
