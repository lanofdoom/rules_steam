load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "depotdownloader.exe",
    srcs = [
        "DepotDownloader/AccountSettingsStore.cs",
        "DepotDownloader/CDNClientPool.cs",
        "DepotDownloader/ContentDownloader.cs",
        "DepotDownloader/DepotConfigStore.cs",
        "DepotDownloader/DownloadConfig.cs",
        "DepotDownloader/HttpClientFactory.cs",
        "DepotDownloader/HttpDiagnosticEventListener.cs",
        "DepotDownloader/PlatformUtilities.cs",
        "DepotDownloader/Program.cs",
        "DepotDownloader/ProtoManifest.cs",
        "DepotDownloader/Steam3Session.cs",
        "DepotDownloader/Util.cs",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@core_sdk_stdlib//:libraryset",
        "@steamkit2//:lib",
    ],
)
