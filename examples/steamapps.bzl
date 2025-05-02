load("@rules_steam//:steam.bzl", "steam_app")

BUILD_scpsl_dedicated_server = "17005897"

def repos(ctx):
    steam_app(
        name = "scpsl_dedicated_server",
        depots = [
            {"app": "996560", "depot": "1006", "manifest": "7138471031118904166"},
            {"app": "996560", "depot": "996562", "manifest": "388641503046878417"},
        ],
    )

steamapps_bzlmod = module_extension(implementation = repos)
