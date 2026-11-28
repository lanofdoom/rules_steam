load(":targets.bzl", "overlay_entries", "render_mtree", "vis_encode")

visibility(["//steam/private"])

def _overlay_test_impl(ctx):
    actual = overlay_entries([
        (
            [("bin/run", "d1/bin/run"), ("bin/demoted", "d1/bin/demoted")],
            [("cfg/a.cfg", "d1/cfg/a.cfg"), ("promoted.sh", "d1/promoted.sh")],
        ),
        (
            [("promoted.sh", "d2/promoted.sh")],
            [("bin/demoted", "d2/bin/demoted"), ("cfg/b.cfg", "d2/cfg/b.cfg")],
        ),
    ])
    expected = [
        ("bin/demoted", "0644", "d2/bin/demoted"),
        ("bin/run", "0755", "d1/bin/run"),
        ("cfg/a.cfg", "0644", "d1/cfg/a.cfg"),
        ("cfg/b.cfg", "0644", "d2/cfg/b.cfg"),
        ("promoted.sh", "0755", "d2/promoted.sh"),
    ]
    if actual != expected:
        fail("expected {}, got {}".format(expected, actual))

    if render_mtree([]) != "":
        fail("expected empty mtree for empty entries")

    encoded = vis_encode("tools/my launcher#1=a\\b/café.sh")
    expected_encoded = "tools/my\\040launcher\\0431\\075a\\134b/caf\\303\\251.sh"
    if encoded != expected_encoded:
        fail("expected {}, got {}".format(expected_encoded, encoded))

    mtree = render_mtree([
        ("LocalAdmin", "0755", "external/repo1/999/LocalAdmin"),
        ("SCPSL_Data/Managed/a.dll", "0644", "external/repo1/999/SCPSL_Data/Managed/a.dll"),
        ("SCPSL_Data/Managed/my file.dll", "0644", "external/repo2/888/SCPSL_Data/Managed/my file.dll"),
    ])
    expected_mtree = "\n".join([
        "LocalAdmin uid=0 gid=0 time=1672560000 mode=0755 type=file nlink=1 content=external/repo1/999/LocalAdmin",
        "SCPSL_Data/ uid=0 gid=0 time=1672560000 mode=0755 type=dir nlink=1",
        "SCPSL_Data/Managed/ uid=0 gid=0 time=1672560000 mode=0755 type=dir nlink=1",
        "SCPSL_Data/Managed/a.dll uid=0 gid=0 time=1672560000 mode=0644 type=file nlink=1 content=external/repo1/999/SCPSL_Data/Managed/a.dll",
        "SCPSL_Data/Managed/my\\040file.dll uid=0 gid=0 time=1672560000 mode=0644 type=file nlink=1 content=external/repo2/888/SCPSL_Data/Managed/my\\040file.dll",
        "",
    ])
    if mtree != expected_mtree:
        fail("expected:\n{}\ngot:\n{}".format(expected_mtree, mtree))

    return [AnalysisTestResultInfo(success = True, message = "ok")]

overlay_test = rule(
    implementation = _overlay_test_impl,
    test = True,
    analysis_test = True,
)
