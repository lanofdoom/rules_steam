load(
    "@io_bazel_rules_dotnet//dotnet:defs.bzl",
    "dotnet_register_toolchains",
    "nuget_package",
)

def steamcmd_nugets():
    dotnet_register_toolchains()

    ### Generated by the tool
    nuget_package(
        name = "protobuf-net.core",
        package = "protobuf-net.core",
        version = "3.0.101",
        sha256 = "35e0d9ef7cddbcb065342eb08f0798195de144f79ee9a481ee1238536d4e76cf",
        core_lib = {
            "netcoreapp2.0": "lib/netstandard2.0/protobuf-net.Core.dll",
            "netcoreapp2.1": "lib/netstandard2.0/protobuf-net.Core.dll",
            "netcoreapp2.2": "lib/netstandard2.0/protobuf-net.Core.dll",
            "netcoreapp3.0": "lib/netstandard2.1/protobuf-net.Core.dll",
            "netcoreapp3.1": "lib/netcoreapp3.1/protobuf-net.Core.dll",
            "net5.0": "lib/net5.0/protobuf-net.Core.dll",
        },
        core_deps = {
            "netcoreapp2.0": [
                "@system.collections.immutable//:netcoreapp2.0_core",
                "@system.memory//:netcoreapp2.0_core",
            ],
            "netcoreapp2.1": [
                "@system.collections.immutable//:netcoreapp2.1_core",
                "@system.memory//:netcoreapp2.1_core",
            ],
            "netcoreapp2.2": [
                "@system.collections.immutable//:netcoreapp2.2_core",
                "@system.memory//:netcoreapp2.2_core",
            ],
            "netcoreapp3.0": [
                "@system.collections.immutable//:netcoreapp3.0_core",
            ],
        },
        core_files = {
            "netcoreapp2.0": [
                "lib/netstandard2.0/protobuf-net.Core.dll",
                "lib/netstandard2.0/protobuf-net.Core.xml",
            ],
            "netcoreapp2.1": [
                "lib/netstandard2.0/protobuf-net.Core.dll",
                "lib/netstandard2.0/protobuf-net.Core.xml",
            ],
            "netcoreapp2.2": [
                "lib/netstandard2.0/protobuf-net.Core.dll",
                "lib/netstandard2.0/protobuf-net.Core.xml",
            ],
            "netcoreapp3.0": [
                "lib/netstandard2.1/protobuf-net.Core.dll",
                "lib/netstandard2.1/protobuf-net.Core.xml",
            ],
            "netcoreapp3.1": [
                "lib/netcoreapp3.1/protobuf-net.Core.dll",
                "lib/netcoreapp3.1/protobuf-net.Core.xml",
            ],
            "net5.0": [
                "lib/net5.0/protobuf-net.Core.dll",
                "lib/net5.0/protobuf-net.Core.xml",
            ],
        },
    )
    nuget_package(
        name = "protobuf-net",
        package = "protobuf-net",
        version = "3.0.101",
        sha256 = "8e3b513b3db00e422c42caed3182a3c1ed8a09563092c375309002b626c32415",
        core_lib = {
            "netcoreapp2.0": "lib/netstandard2.0/protobuf-net.dll",
            "netcoreapp2.1": "lib/netstandard2.0/protobuf-net.dll",
            "netcoreapp2.2": "lib/netstandard2.0/protobuf-net.dll",
            "netcoreapp3.0": "lib/netstandard2.1/protobuf-net.dll",
            "netcoreapp3.1": "lib/netcoreapp3.1/protobuf-net.dll",
            "net5.0": "lib/net5.0/protobuf-net.dll",
        },
        core_deps = {
            "netcoreapp2.0": [
                "@protobuf-net.core//:netcoreapp2.0_core",
                "@system.memory//:netcoreapp2.0_core",
            ],
            "netcoreapp2.1": [
                "@protobuf-net.core//:netcoreapp2.1_core",
                "@system.memory//:netcoreapp2.1_core",
            ],
            "netcoreapp2.2": [
                "@protobuf-net.core//:netcoreapp2.2_core",
                "@system.memory//:netcoreapp2.2_core",
            ],
            "netcoreapp3.0": [
                "@protobuf-net.core//:netcoreapp3.0_core",
            ],
            "netcoreapp3.1": [
                "@protobuf-net.core//:netcoreapp3.1_core",
            ],
            "net5.0": [
                "@protobuf-net.core//:net5.0_core",
            ],
        },
        core_files = {
            "netcoreapp2.0": [
                "lib/netstandard2.0/protobuf-net.dll",
                "lib/netstandard2.0/protobuf-net.xml",
            ],
            "netcoreapp2.1": [
                "lib/netstandard2.0/protobuf-net.dll",
                "lib/netstandard2.0/protobuf-net.xml",
            ],
            "netcoreapp2.2": [
                "lib/netstandard2.0/protobuf-net.dll",
                "lib/netstandard2.0/protobuf-net.xml",
            ],
            "netcoreapp3.0": [
                "lib/netstandard2.1/protobuf-net.dll",
                "lib/netstandard2.1/protobuf-net.xml",
            ],
            "netcoreapp3.1": [
                "lib/netcoreapp3.1/protobuf-net.dll",
                "lib/netcoreapp3.1/protobuf-net.xml",
            ],
            "net5.0": [
                "lib/net5.0/protobuf-net.dll",
                "lib/net5.0/protobuf-net.xml",
            ],
        },
    )
    nuget_package(
        name = "system.security.principal.windows",
        package = "system.security.principal.windows",
        version = "5.0.0",
        sha256 = "081390c25f6f78592b28ada853c24514488a221fe9f9a24efaaf5373643ff3d6",
        core_lib = {
            "netcoreapp2.0": "lib/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp2.1": "lib/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp2.2": "lib/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp3.0": "lib/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp3.1": "lib/netstandard2.0/System.Security.Principal.Windows.dll",
            "net5.0": "lib/netstandard2.0/System.Security.Principal.Windows.dll",
        },
        core_ref = {
            "netcoreapp2.0": "ref/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp2.1": "ref/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp2.2": "ref/netstandard2.0/System.Security.Principal.Windows.dll",
            "netcoreapp3.0": "ref/netcoreapp3.0/System.Security.Principal.Windows.dll",
            "netcoreapp3.1": "ref/netcoreapp3.0/System.Security.Principal.Windows.dll",
            "net5.0": "ref/netcoreapp3.0/System.Security.Principal.Windows.dll",
        },
        core_files = {
            "netcoreapp2.0": [
                "lib/netstandard2.0/System.Security.Principal.Windows.dll",
                "lib/netstandard2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.xml",
            ],
            "netcoreapp2.1": [
                "lib/netstandard2.0/System.Security.Principal.Windows.dll",
                "lib/netstandard2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.xml",
            ],
            "netcoreapp2.2": [
                "lib/netstandard2.0/System.Security.Principal.Windows.dll",
                "lib/netstandard2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.xml",
            ],
            "netcoreapp3.0": [
                "lib/netstandard2.0/System.Security.Principal.Windows.dll",
                "lib/netstandard2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.xml",
            ],
            "netcoreapp3.1": [
                "lib/netstandard2.0/System.Security.Principal.Windows.dll",
                "lib/netstandard2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.xml",
            ],
            "net5.0": [
                "lib/netstandard2.0/System.Security.Principal.Windows.dll",
                "lib/netstandard2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.0/System.Security.Principal.Windows.xml",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.dll",
                "runtimes/unix/lib/netcoreapp2.1/System.Security.Principal.Windows.xml",
            ],
        },
    )
    nuget_package(
        name = "system.security.accesscontrol",
        package = "system.security.accesscontrol",
        version = "5.0.0",
        sha256 = "b9e486f989fcd9ebf1c86067138f4de03fa780e0c35e0a2b9e506d4373a6c39e",
        core_lib = {
            "netcoreapp2.0": "lib/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp2.1": "lib/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp2.2": "lib/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp3.0": "lib/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp3.1": "lib/netstandard2.0/System.Security.AccessControl.dll",
            "net5.0": "lib/netstandard2.0/System.Security.AccessControl.dll",
        },
        core_ref = {
            "netcoreapp2.0": "ref/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp2.1": "ref/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp2.2": "ref/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp3.0": "ref/netstandard2.0/System.Security.AccessControl.dll",
            "netcoreapp3.1": "ref/netstandard2.0/System.Security.AccessControl.dll",
            "net5.0": "ref/netstandard2.0/System.Security.AccessControl.dll",
        },
        core_deps = {
            "netcoreapp2.0": [
                "@system.security.principal.windows//:netcoreapp2.0_core",
            ],
            "netcoreapp2.1": [
                "@system.security.principal.windows//:netcoreapp2.1_core",
            ],
            "netcoreapp2.2": [
                "@system.security.principal.windows//:netcoreapp2.2_core",
            ],
            "netcoreapp3.0": [
                "@system.security.principal.windows//:netcoreapp3.0_core",
            ],
            "netcoreapp3.1": [
                "@system.security.principal.windows//:netcoreapp3.1_core",
            ],
            "net5.0": [
                "@system.security.principal.windows//:net5.0_core",
            ],
        },
        core_files = {
            "netcoreapp2.0": [
                "lib/netstandard2.0/System.Security.AccessControl.dll",
                "lib/netstandard2.0/System.Security.AccessControl.xml",
            ],
            "netcoreapp2.1": [
                "lib/netstandard2.0/System.Security.AccessControl.dll",
                "lib/netstandard2.0/System.Security.AccessControl.xml",
            ],
            "netcoreapp2.2": [
                "lib/netstandard2.0/System.Security.AccessControl.dll",
                "lib/netstandard2.0/System.Security.AccessControl.xml",
            ],
            "netcoreapp3.0": [
                "lib/netstandard2.0/System.Security.AccessControl.dll",
                "lib/netstandard2.0/System.Security.AccessControl.xml",
            ],
            "netcoreapp3.1": [
                "lib/netstandard2.0/System.Security.AccessControl.dll",
                "lib/netstandard2.0/System.Security.AccessControl.xml",
            ],
            "net5.0": [
                "lib/netstandard2.0/System.Security.AccessControl.dll",
                "lib/netstandard2.0/System.Security.AccessControl.xml",
            ],
        },
    )
    nuget_package(
        name = "microsoft.win32.registry",
        package = "microsoft.win32.registry",
        version = "5.0.0",
        sha256 = "f64ca53c67ca65ce7cc85a8d29aefbb2da2672836731e1115e8cd62730dc5080",
        core_lib = {
            "netcoreapp2.0": "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp2.1": "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp2.2": "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp3.0": "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp3.1": "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
            "net5.0": "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
        },
        core_ref = {
            "netcoreapp2.0": "ref/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp2.1": "ref/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp2.2": "ref/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp3.0": "ref/netstandard2.0/Microsoft.Win32.Registry.dll",
            "netcoreapp3.1": "ref/netstandard2.0/Microsoft.Win32.Registry.dll",
            "net5.0": "ref/netstandard2.0/Microsoft.Win32.Registry.dll",
        },
        core_deps = {
            "netcoreapp2.0": [
                "@system.memory//:netcoreapp2.0_core",
                "@system.security.accesscontrol//:netcoreapp2.0_core",
                "@system.security.principal.windows//:netcoreapp2.0_core",
            ],
            "netcoreapp2.1": [
                "@system.security.accesscontrol//:netcoreapp2.1_core",
                "@system.security.principal.windows//:netcoreapp2.1_core",
            ],
            "netcoreapp2.2": [
                "@system.security.accesscontrol//:netcoreapp2.2_core",
                "@system.security.principal.windows//:netcoreapp2.2_core",
            ],
            "netcoreapp3.0": [
                "@system.security.accesscontrol//:netcoreapp3.0_core",
                "@system.security.principal.windows//:netcoreapp3.0_core",
            ],
            "netcoreapp3.1": [
                "@system.security.accesscontrol//:netcoreapp3.1_core",
                "@system.security.principal.windows//:netcoreapp3.1_core",
            ],
            "net5.0": [
                "@system.security.accesscontrol//:net5.0_core",
                "@system.security.principal.windows//:net5.0_core",
            ],
        },
        core_files = {
            "netcoreapp2.0": [
                "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
                "lib/netstandard2.0/Microsoft.Win32.Registry.xml",
            ],
            "netcoreapp2.1": [
                "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
                "lib/netstandard2.0/Microsoft.Win32.Registry.xml",
            ],
            "netcoreapp2.2": [
                "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
                "lib/netstandard2.0/Microsoft.Win32.Registry.xml",
            ],
            "netcoreapp3.0": [
                "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
                "lib/netstandard2.0/Microsoft.Win32.Registry.xml",
            ],
            "netcoreapp3.1": [
                "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
                "lib/netstandard2.0/Microsoft.Win32.Registry.xml",
            ],
            "net5.0": [
                "lib/netstandard2.0/Microsoft.Win32.Registry.dll",
                "lib/netstandard2.0/Microsoft.Win32.Registry.xml",
            ],
        },
    )
    nuget_package(
        name = "steamkit2",
        package = "steamkit2",
        version = "2.4.0-Alpha.3",
        sha256 = "7b3fadde4fdde70b19d86d43c9ccb389a76a0d6e7c2e99d09e89c8efa7f48858",
        core_lib = {
            "netcoreapp2.0": "lib/netstandard2.0/SteamKit2.dll",
            "netcoreapp2.1": "lib/netstandard2.0/SteamKit2.dll",
            "netcoreapp2.2": "lib/netstandard2.0/SteamKit2.dll",
            "netcoreapp3.0": "lib/netstandard2.0/SteamKit2.dll",
            "netcoreapp3.1": "lib/netstandard2.0/SteamKit2.dll",
            "net5.0": "lib/netstandard2.0/SteamKit2.dll",
        },
        core_deps = {
            "netcoreapp2.0": [
                "@microsoft.win32.registry//:netcoreapp2.0_core",
                "@protobuf-net//:netcoreapp2.0_core",
            ],
            "netcoreapp2.1": [
                "@microsoft.win32.registry//:netcoreapp2.1_core",
                "@protobuf-net//:netcoreapp2.1_core",
            ],
            "netcoreapp2.2": [
                "@microsoft.win32.registry//:netcoreapp2.2_core",
                "@protobuf-net//:netcoreapp2.2_core",
            ],
            "netcoreapp3.0": [
                "@microsoft.win32.registry//:netcoreapp3.0_core",
                "@protobuf-net//:netcoreapp3.0_core",
            ],
            "netcoreapp3.1": [
                "@microsoft.win32.registry//:netcoreapp3.1_core",
                "@protobuf-net//:netcoreapp3.1_core",
            ],
            "net5.0": [
                "@microsoft.win32.registry//:net5.0_core",
                "@protobuf-net//:net5.0_core",
            ],
        },
        core_files = {
            "netcoreapp2.0": [
                "lib/netstandard2.0/SteamKit2.dll",
                "lib/netstandard2.0/SteamKit2.pdb",
                "lib/netstandard2.0/SteamKit2.xml",
            ],
            "netcoreapp2.1": [
                "lib/netstandard2.0/SteamKit2.dll",
                "lib/netstandard2.0/SteamKit2.pdb",
                "lib/netstandard2.0/SteamKit2.xml",
            ],
            "netcoreapp2.2": [
                "lib/netstandard2.0/SteamKit2.dll",
                "lib/netstandard2.0/SteamKit2.pdb",
                "lib/netstandard2.0/SteamKit2.xml",
            ],
            "netcoreapp3.0": [
                "lib/netstandard2.0/SteamKit2.dll",
                "lib/netstandard2.0/SteamKit2.pdb",
                "lib/netstandard2.0/SteamKit2.xml",
            ],
            "netcoreapp3.1": [
                "lib/netstandard2.0/SteamKit2.dll",
                "lib/netstandard2.0/SteamKit2.pdb",
                "lib/netstandard2.0/SteamKit2.xml",
            ],
            "net5.0": [
                "lib/netstandard2.0/SteamKit2.dll",
                "lib/netstandard2.0/SteamKit2.pdb",
                "lib/netstandard2.0/SteamKit2.xml",
            ],
        },
    )
    ### End of generated by the tool