load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_push")
load("@io_bazel_rules_docker//docker/package_managers:download_pkgs.bzl", "download_pkgs")
load("@io_bazel_rules_docker//docker/package_managers:install_pkgs.bzl", "install_pkgs")
load("@io_bazel_rules_docker//docker/util:run.bzl", "container_run_and_extract")

#
# SteamCMD Installer
#

download_pkgs(
    name = "steamcmd_installer_deps",
    image_tar = "@steamcmd_installer_base//image",
    packages = [
        "ca-certificates",
        "lib32gcc1",
        "wget",
    ],
)

install_pkgs(
    name = "steamcmd_installer",
    image_tar = "@steamcmd_installer_base//image",
    installables_tar = ":steamcmd_installer_deps.tar",
    installation_cleanup_commands = "rm -rf /var/lib/apt/lists/*",
    output_image_name = "steamcmd_installer",
)

container_run_and_extract(
    name = "install_steamcmd",
    extract_file = "/steam.tar",
    commands = [
        "mkdir -p /opt/steam",
        "wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C /opt/steam",
        "/opt/steam/steamcmd.sh +quit",
        "tar -cvf /steam.tar /opt/steam/",
    ],
    image = ":steamcmd_installer.tar",
)

#
# SteamCMD Output Image
#

download_pkgs(
    name = "steamcmd_runtime_deps",
    image_tar = "@steamcmd_runtime_base//image",
    packages = [
        "ca-certificates",
        "lib32gcc1",
    ],
)

install_pkgs(
    name = "steamcmd_runtime_deps_image",
    image_tar = "@steamcmd_runtime_base//image",
    installables_tar = ":steamcmd_runtime_deps.tar",
    installation_cleanup_commands = "rm -rf /var/lib/apt/lists/*",
    output_image_name = "steamcmd_runtime_deps_image",
)

container_image(
    name = "steamcmd_image",
    base = "steamcmd_runtime_deps_image.tar",
    tars = [
        ":install_steamcmd/steam.tar",
    ],
)

container_push(
   name = "push_steamcmd_image",
   image = ":steamcmd_image",
   format = "Docker",
   registry = "ghcr.io",
   repository = "lanofdoom/steamcmd/steamcmd",
   tag = "latest",
)