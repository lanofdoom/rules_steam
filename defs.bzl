load("@io_bazel_rules_docker//docker/util:run.bzl", "container_run_and_extract")
load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_layer")

# Download an application from steam. The output of this macro is a tar containing the application.
def steamcmd_update(name, app_ids, visibility = None):
    app_update_string = ""
    for app_id in app_ids:
        app_update_string += "+app_update " + str(app_id) + " "

    container_run_and_extract(
        name = name,
        extract_file = "/app.tar.gz",
        commands = [
            "/usr/games/steamcmd +@ShutdownOnFailedCommand 1 +force_install_dir /opt/game +login anonymous " + app_update_string + "validate +quit",
            "rm -rf /opt/game/steamapps",
            "tar -czvf /app.tar.gz -C /opt/game/ .",
        ],
        image = "@com_github_lanofdoom_steamcmd//:steamcmd.tar",
        visibility = visibility,
    )
