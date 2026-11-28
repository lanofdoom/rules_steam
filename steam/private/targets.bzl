load("@tar.bzl", "mtree_mutate", "tar")

SteamAppInfo = provider(
    fields = ["files", "mtree"],
)

SteamDepotInfo = provider(
    fields = ["exec_paths", "exec_srcs", "data_paths", "data_srcs"],
)

_MTREE_TIME = "1672560000"
_COMMON_RULE_ATTRS = (
    "exec_compatible_with",
    "exec_properties",
    "features",
    "tags",
    "target_compatible_with",
    "testonly",
)

_UNSAFE_BYTES = (
    "\001\002\003\004\005\006\007\010\011\012\013\014\015\016\017\020" +
    "\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037\040" +
    "#=\\\177" +
    "\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217" +
    "\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237" +
    "\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257" +
    "\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277" +
    "\300\301\302\303\304\305\306\307\310\311\312\313\314\315\316\317" +
    "\320\321\322\323\324\325\326\327\330\331\332\333\334\335\336\337" +
    "\340\341\342\343\344\345\346\347\350\351\352\353\354\355\356\357" +
    "\360\361\362\363\364\365\366\367\370\371\372\373\374\375\376\377"
)

_UNSAFE_CODES = (
    list(range(1, 33)) +
    [0x23, 0x3D, 0x5C, 0x7F] +
    list(range(128, 256))
)

_VIS_ESCAPES = {
    _UNSAFE_BYTES[i]: "\\%d%d%d" % (
        _UNSAFE_CODES[i] >> 6,
        (_UNSAFE_CODES[i] >> 3) & 7,
        _UNSAFE_CODES[i] & 7,
    )
    for i in range(len(_UNSAFE_CODES))
}

def vis_encode(s):
    return "".join([_VIS_ESCAPES.get(ch, ch) for ch in s.elems()])

def overlay_entries(depot_items):
    by_path = {}
    for exec_items, data_items in depot_items:
        for p, val in exec_items:
            by_path[p] = ("0755", val)
        for p, val in data_items:
            by_path[p] = ("0644", val)
    return [(p, by_path[p][0], by_path[p][1]) for p in sorted(by_path.keys())]

def render_mtree(entries):
    lines = []
    seen_dirs = {}
    for path, mode, content_path in entries:
        parts = path.split("/")
        for i in range(1, len(parts)):
            d = "/".join(parts[:i]) + "/"
            if d not in seen_dirs:
                seen_dirs[d] = True
                lines.append("{} uid=0 gid=0 time={} mode=0755 type=dir nlink=1".format(
                    vis_encode(d),
                    _MTREE_TIME,
                ))
        lines.append("{} uid=0 gid=0 time={} mode={} type=file nlink=1 content={}".format(
            vis_encode(path),
            _MTREE_TIME,
            mode,
            vis_encode(content_path),
        ))
    return "\n".join(lines) + ("\n" if lines else "")

def _steam_depot_files_impl(ctx):
    if len(ctx.files.exec_srcs) != len(ctx.attr.exec_paths) or len(ctx.files.data_srcs) != len(ctx.attr.data_paths):
        fail("Mismatched depot srcs/paths lengths")
    return [
        SteamDepotInfo(
            exec_paths = ctx.attr.exec_paths,
            exec_srcs = ctx.files.exec_srcs,
            data_paths = ctx.attr.data_paths,
            data_srcs = ctx.files.data_srcs,
        ),
    ]

steam_depot_files = rule(
    implementation = _steam_depot_files_impl,
    attrs = {
        "exec_paths": attr.string_list(),
        "exec_srcs": attr.label_list(allow_files = True),
        "data_paths": attr.string_list(),
        "data_srcs": attr.label_list(allow_files = True),
    },
)

def _steam_app_impl(ctx):
    if ctx.attr.error:
        fail(ctx.attr.error)
    resolved = overlay_entries([
        (
            zip(d[SteamDepotInfo].exec_paths, d[SteamDepotInfo].exec_srcs),
            zip(d[SteamDepotInfo].data_paths, d[SteamDepotInfo].data_srcs),
        )
        for d in ctx.attr.depots
    ])
    files = depset([item[2] for item in resolved])
    mtree = ctx.actions.declare_file(ctx.label.name + ".mtree")
    ctx.actions.write(
        mtree,
        render_mtree([(item[0], item[1], item[2].path) for item in resolved]),
    )
    return [
        DefaultInfo(files = files),
        SteamAppInfo(
            files = files,
            mtree = mtree,
        ),
    ]

_steam_app = rule(
    implementation = _steam_app_impl,
    attrs = {
        "depots": attr.label_list(providers = [SteamDepotInfo]),
        "error": attr.string(),
    },
)

def _steam_app_mtree_impl(ctx):
    return [DefaultInfo(files = depset([ctx.attr.src[SteamAppInfo].mtree]))]

_steam_app_mtree = rule(
    implementation = _steam_app_mtree_impl,
    attrs = {
        "src": attr.label(providers = [SteamAppInfo], mandatory = True),
    },
)

def steam_tar(
        name,
        src,
        srcs = [],
        package_dir = None,
        strip_prefix = None,
        mtime = None,
        owner = None,
        ownername = None,
        group = None,
        groupname = None,
        awk_script = None,
        script_args = None,
        includes = None,
        **kwargs):
    common = {
        k: kwargs[k]
        for k in _COMMON_RULE_ATTRS
        if k in kwargs
    }

    app_mtree = name + "_app_mtree"
    _steam_app_mtree(
        name = app_mtree,
        src = src,
        visibility = ["//visibility:private"],
        **common
    )

    if type(src) == "string" or type(src) == "Label":
        tar_srcs = [src] + srcs
    else:
        app_files = name + "_app_files"
        native.alias(
            name = app_files,
            actual = src,
            visibility = ["//visibility:private"],
            **common
        )
        tar_srcs = [":" + app_files] + srcs

    has_mutation = any([
        package_dir != None,
        strip_prefix != None,
        mtime != None,
        owner != None,
        ownername != None,
        group != None,
        groupname != None,
        awk_script != None,
        bool(script_args),
        bool(includes),
    ])

    mtree_target = ":" + app_mtree
    if has_mutation:
        mutated = name + "_mtree"
        mutate_kwargs = dict(common)
        if awk_script != None:
            mutate_kwargs["awk_script"] = awk_script
        if group != None:
            mutate_kwargs["group"] = str(group)
        if groupname != None:
            mutate_kwargs["groupname"] = groupname
        mtree_mutate(
            name = mutated,
            mtree = mtree_target,
            strip_prefix = strip_prefix,
            package_dir = package_dir,
            mtime = str(mtime) if mtime != None else None,
            owner = str(owner) if owner != None else None,
            ownername = ownername,
            script_args = script_args or {},
            includes = includes,
            visibility = ["//visibility:private"],
            **mutate_kwargs
        )
        mtree_target = ":" + mutated

    tar(
        name = name,
        srcs = tar_srcs,
        mtree = mtree_target,
        **kwargs
    )

def steam_app_targets(name, depots, error = ""):
    if name in ("mtree", "tar"):
        fail("Reserved steam app name '{}'".format(name))

    _steam_app(
        name = name,
        depots = depots,
        error = error,
        visibility = ["//visibility:public"],
    )

    _steam_app_mtree(
        name = "mtree",
        src = ":" + name,
        visibility = ["//visibility:public"],
    )

    tar(
        name = "tar",
        srcs = [":" + name],
        mtree = ":mtree",
        compress = "",
        out = name + ".tar",
        visibility = ["//visibility:public"],
    )
