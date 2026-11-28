load("@rules_steam//steam/private:repo_rules.bzl", "steam_app")

BUILD_scpsl_dedicated_server = "26443947"

def repos(ctx):
    steam_app(
        name = "scpsl_dedicated_server",
        build_id = BUILD_scpsl_dedicated_server,
        depots = [
            {"app": "996560", "depot": "1006", "manifest": "4559160656493359681", "executables": [], "files": []},
            {"app": "996560", "depot": "996562", "manifest": "7659625077094485178", "executables": [], "files": []},
        ],
    )
    return ctx.extension_metadata(reproducible = True)

steamapps_bzlmod = module_extension(implementation = repos)
