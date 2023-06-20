load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

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
    private_deps = [
    ],
    target_frameworks = ["net6.0"],
    visibility = ["//visibility:public"],
    deps = [
        "@paket.main//microsoft.netcore.app.ref",
        "@paket.main//protobuf-net",
        "@paket.main//protobuf-net.core",
        "@paket.main//qrcoder",
        "@paket.main//steamkit2",
    ],
)
