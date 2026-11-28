load(":parse.bzl", "parse_manifest_json")

visibility(["//steam/private"])

def _parse_test_impl(ctx):
    payload = json.encode({
        "appId": 90,
        "name": "Half-Life Dedicated Server",
        "branch": "beta",
        "buildId": 8925347,
        "timeUpdated": "2024-09-13T19:20:39Z",
        "depots": [
            {
                "depotId": 1,
                "containingAppId": 70,
                "branch": "public",
                "manifestId": "2667117727132184734",
                "files": [
                    {"path": "bin/hlds_linux", "flags": 32},
                    {"path": "tools/my launcher.sh", "flags": 32},
                    {"path": "bin/engine.so", "flags": 0},
                    {"path": "bin", "flags": 96},
                    {"path": "bin/hlds_link", "flags": 544, "linkTarget": "bin/hlds_linux"},
                ],
            },
            {
                "depotId": 92,
                "containingAppId": 90,
                "branch": "beta",
                "manifestId": "111",
                "files": [],
            },
        ],
    })
    build_id, actual = parse_manifest_json(
        payload,
        extra_executables = ["\\custom/run.sh"],
        files = ["regex:^bin/"],
    )
    expected = [
        {
            "app": "90",
            "depot": "1",
            "manifest": "2667117727132184734",
            "executables": ["bin/hlds_linux", "custom/run.sh", "tools/my launcher.sh"],
            "files": ["regex:^bin/"],
        },
        {
            "app": "90",
            "depot": "92",
            "manifest": "111",
            "executables": ["custom/run.sh"],
            "files": ["regex:^bin/"],
        },
    ]
    if build_id != "8925347" or actual != expected:
        fail("expected ('8925347', {}), got ({}, {})".format(expected, build_id, actual))

    locked_payload = json.encode({
        "appId": 90,
        "branch": "beta",
        "os": "linux",
        "arch": "64",
        "buildId": 8925347,
        "depots": [
            {
                "depotId": 1,
                "manifestId": "2667117727132184734",
                "executables": ["bin/hlds_linux", "tools/my launcher.sh"],
            },
            {
                "depotId": 92,
                "manifestId": "111",
            },
        ],
    })
    locked_build_id, locked_actual = parse_manifest_json(
        locked_payload,
        extra_executables = ["\\custom/run.sh"],
        files = ["regex:^bin/"],
    )
    if locked_build_id != "8925347" or locked_actual != expected:
        fail("expected ('8925347', {}), got ({}, {})".format(expected, locked_build_id, locked_actual))

    return [AnalysisTestResultInfo(success = True, message = "ok")]

parse_test = rule(
    implementation = _parse_test_impl,
    test = True,
    analysis_test = True,
)
