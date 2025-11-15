load("@rules_steam//:steam.bzl", "steam_app")

BUILD_scpsl_dedicated_server = "20805753"

def repos(ctx):
    steam_app(
        name = "scpsl_dedicated_server",
        depots = [
            {"app": "996560", "depot": "1006", "manifest": "5587033981095108078"},
            {"app": "996560", "depot": "996562", "manifest": "7824721127613562026"},
        ],
    )

steamapps_bzlmod = module_extension(implementation = repos)
