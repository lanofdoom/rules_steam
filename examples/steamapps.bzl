load("@rules_steam//:steam.bzl", "steam_app")

BUILD_scpsl_dedicated_server = "20628849"

def repos(ctx):
    steam_app(
        name = "scpsl_dedicated_server",
        depots = [
            {"app": "996560", "depot": "1006", "manifest": "5587033981095108078"},
            {"app": "996560", "depot": "996562", "manifest": "6385232373985870429"},
        ],
    )

steamapps_bzlmod = module_extension(implementation = repos)
