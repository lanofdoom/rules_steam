load("@rules_steam//:steam.bzl", "steam_app")

BUILD_scpsl_dedicated_server = "21186860"

def repos(ctx):
    steam_app(
        name = "scpsl_dedicated_server",
        depots = [
            {"app": "996560", "depot": "1006", "manifest": "6403079453713498174"},
            {"app": "996560", "depot": "996562", "manifest": "8299380878015604675"},
        ],
    )

steamapps_bzlmod = module_extension(implementation = repos)
