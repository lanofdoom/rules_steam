// This file is subject to the terms and conditions defined
// in file 'LICENSE', which is part of this source code package.

using System;
using System.Buffers;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

using Microsoft.Extensions.Logging;
using SteamKit2;
using SteamKit2.CDN;

public class ContentDownloaderException(string value) : Exception(value) { }

public class DownloadConfig
{
    public int CellID { get; set; }
    public bool DownloadAllPlatforms { get; set; }
    public bool DownloadAllArchs { get; set; }
    public bool DownloadAllLanguages { get; set; }
    public string InstallDirectory { get; set; }
    public string BetaPassword { get; set; }
}


public class ContentDownloader
{
    public const int INVALID_APP_ID = int.MaxValue;
    public const int INVALID_DEPOT_ID = int.MaxValue;
    public const long INVALID_MANIFEST_ID = long.MaxValue;
    public const string DEFAULT_BRANCH = "public";

    public DownloadConfig Config = new();

    private Steam3Session steam3;
    private readonly ILogger logger;


    public sealed class DepotDownloadInfo(
        int depotid, int appId, long manifestId)
    {
        public int DepotId { get; } = depotid;
        public int AppId { get; } = appId;
        public long ManifestId { get; } = manifestId;
    }

    public ContentDownloader(ILogger logger)
    {
        this.logger = logger;
    }

    public bool InitializeSteam3()
    {
        this.steam3 = new Steam3Session(
            new SteamUser.LogOnDetails { },
            Config,
            logger
        );

        if (!steam3.WaitForCredentials())
        {
            logger.LogError("Unable to get steam3 credentials.");
            return false;
        }

        Task.Run(steam3.TickCallbacks);

        return true;
    }

    public void ShutdownSteam3()
    {
        if (steam3 == null)
            return;

        steam3.Disconnect();
    }

    async Task<bool> AccountHasAccess(int appId, int depotId)
    {
        if (steam3 == null || steam3.steamUser.SteamID == null || (steam3.Licenses == null && steam3.steamUser.SteamID.AccountType != EAccountType.AnonUser))
        {
            return false;
        }

        // https://steamdb.info/sub/17906/depots Anonymous Dedicated Server Comp
        IEnumerable<int> licenseQuery = [17906];

        await steam3.RequestPackageInfo(licenseQuery);

        foreach (var license in licenseQuery)
        {
            if (steam3.PackageInfo.TryGetValue(license, out var package) && package != null)
            {
                if (package.KeyValues["appids"].Children.Any(child => child.AsInteger() == depotId))
                    return true;

                if (package.KeyValues["depotids"].Children.Any(child => child.AsInteger() == depotId))
                    return true;
            }
        }

        // Check if this app is free to download without a license
        var info = GetSteam3AppSection(appId, EAppInfoSection.Common);
        if (info != null && info["FreeToDownload"].AsBoolean())
            return true;

        return false;
    }

    internal KeyValue GetSteam3AppSection(int appId, EAppInfoSection section)
    {
        if (steam3 == null || steam3.AppInfo == null)
        {
            return null;
        }

        if (!steam3.AppInfo.TryGetValue(appId, out var app) || app == null)
        {
            return null;
        }

        var appinfo = app.KeyValues;
        var section_key = section switch
        {
            EAppInfoSection.Common => "common",
            EAppInfoSection.Extended => "extended",
            EAppInfoSection.Config => "config",
            EAppInfoSection.Depots => "depots",
            _ => throw new NotImplementedException(),
        };
        var section_kv = appinfo.Children.Where(c => c.Name == section_key).FirstOrDefault();
        return section_kv;
    }

    int GetSteam3AppBuildNumber(int appId, string branch)
    {
        if (appId == INVALID_APP_ID) return 0;

        var depots = GetSteam3AppSection(appId, EAppInfoSection.Depots);
        var branches = depots["branches"];
        var node = branches[branch];

        if (node == KeyValue.Invalid) return 0;

        var buildid = node["buildid"];

        if (buildid == KeyValue.Invalid) return 0;

        return int.Parse(buildid.Value);
    }

    int GetSteam3DepotProxyAppId(int depotId, int appId)
    {
        var depots = GetSteam3AppSection(appId, EAppInfoSection.Depots);
        var depotChild = depots[depotId.ToString()];

        if (depotChild == KeyValue.Invalid)
            return INVALID_APP_ID;

        if (depotChild["depotfromapp"] == KeyValue.Invalid)
            return INVALID_APP_ID;

        return depotChild["depotfromapp"].AsInteger();
    }

    async Task<long> GetSteam3DepotManifest(int depotId, int appId, string branch)
    {
        var depots = GetSteam3AppSection(appId, EAppInfoSection.Depots);
        var depotChild = depots[depotId.ToString()];

        if (depotChild == KeyValue.Invalid)
            return INVALID_MANIFEST_ID;

        // Shared depots can either provide manifests, or leave you relying on their parent app.
        // It seems that with the latter, "sharedinstall" will exist (and equals 2 in the one existance I know of).
        // Rather than relay on the unknown sharedinstall key, just look for manifests. Test cases: 111710, 346680.
        if (depotChild["manifests"] == KeyValue.Invalid && depotChild["depotfromapp"] != KeyValue.Invalid)
        {
            var otherAppId = depotChild["depotfromapp"].AsInteger();
            if (otherAppId == appId)
            {
                // This shouldn't ever happen, but ya never know with Valve. Don't infinite loop.
                logger.LogError("App {0}, Depot {1} has depotfromapp of {2}!",
                    appId, depotId, otherAppId);
                return INVALID_MANIFEST_ID;
            }

            await steam3.RequestAppInfo((int)otherAppId);

            return await GetSteam3DepotManifest(depotId, (int)otherAppId, branch);
        }

        var manifests = depotChild["manifests"];

        if (manifests.Children.Count == 0)
            return INVALID_MANIFEST_ID;

        var node = manifests[branch]["gid"];

        // Non passworded branch, found the manifest
        if (node.Value != null)
            return long.Parse(node.Value);

        // If we requested public branch and it had no manifest, nothing to do
        if (string.Equals(branch, DEFAULT_BRANCH, StringComparison.OrdinalIgnoreCase))
            return INVALID_MANIFEST_ID;

        // Either the branch just doesn't exist, or it has a password
        var password = Config.BetaPassword;

        if (string.IsNullOrEmpty(password))
        {
            logger.LogError($"Branch {branch} was not found, either it does not exist or it has a password.");
        }

        while (string.IsNullOrEmpty(password))
        {
            logger.LogError($"Password required for branch {branch}: ");
            return INVALID_MANIFEST_ID;
        }

        if (!steam3.AppBetaPasswords.ContainsKey(branch))
        {
            // Submit the password to Steam now to get encryption keys
            await steam3.CheckAppBetaPassword(appId, Config.BetaPassword);

            if (!steam3.AppBetaPasswords.TryGetValue(branch, out var appBetaPassword))
            {
                logger.LogError($"Error: Password was invalid for branch {branch} (or the branch does not exist)");
                return INVALID_MANIFEST_ID;
            }
        }

        // Got the password, request private depot section
        // TODO: We're probably repeating this request for every depot?
        var privateDepotSection = await steam3.GetPrivateBetaDepotSection(appId, branch);

        // Now repeat the same code to get the manifest gid from depot section
        depotChild = privateDepotSection[depotId.ToString()];

        if (depotChild == KeyValue.Invalid)
            return INVALID_MANIFEST_ID;

        manifests = depotChild["manifests"];

        if (manifests.Children.Count == 0)
            return INVALID_MANIFEST_ID;

        node = manifests[branch]["gid"];

        if (node.Value == null)
            return INVALID_MANIFEST_ID;

        return long.Parse(node.Value);
    }

    string GetAppName(int appId)
    {
        var info = GetSteam3AppSection(appId, EAppInfoSection.Common);
        if (info == null)
            return string.Empty;

        return info["name"].AsString();
    }

    public async Task<(int, List<DepotDownloadInfo>)> LookupManifestsForAppAsync(int appId, string branch, string os, string arch, string language, bool lv, bool isUgc)
    {
        List<int> depotIds = new();

        await steam3?.RequestAppInfo(appId);

        if (!await AccountHasAccess(appId, appId))
        {
            if (await steam3.RequestFreeAppLicense(appId))
            {
                logger.LogInformation("Obtained FreeOnDemand license for app {0}", appId);

                // Fetch app info again in case we didn't get it fully without a license.
                await steam3.RequestAppInfo(appId, true);
            }
            else
            {
                var contentName = GetAppName(appId);
                throw new ContentDownloaderException(string.Format("App {0} ({1}) is not available from this account.", appId, contentName));
            }
        }

        var depots = GetSteam3AppSection(appId, EAppInfoSection.Depots); ////////////

        //var branches = depots["branches"]
        //var branchNames = branches.Children.Select(child => child.Name).ToList();
        //logger.LogInformation("Available branches: {0}", string.Join(", ", branchNames));


        logger.LogInformation("Using app branch: '{0}'.", branch);

        if (depots != null)
        {
            foreach (var depotSection in depots.Children)
            {
                var id = INVALID_DEPOT_ID;
                if (depotSection.Children.Count == 0)
                    continue;

                if (!int.TryParse(depotSection.Name, out id))
                    continue;

                var depotConfig = depotSection["config"];
                if (depotConfig != KeyValue.Invalid)
                {
                    if (!Config.DownloadAllPlatforms &&
                        depotConfig["oslist"] != KeyValue.Invalid &&
                        !string.IsNullOrWhiteSpace(depotConfig["oslist"].Value))
                    {
                        var oslist = depotConfig["oslist"].Value.Split(',');
                        if (Array.IndexOf(oslist, os ?? Util.GetSteamOS()) == -1)
                            continue;
                    }

                    if (!Config.DownloadAllArchs &&
                        depotConfig["osarch"] != KeyValue.Invalid &&
                        !string.IsNullOrWhiteSpace(depotConfig["osarch"].Value))
                    {
                        var depotArch = depotConfig["osarch"].Value;
                        if (depotArch != (arch ?? Util.GetSteamArch()))
                            continue;
                    }

                    if (!Config.DownloadAllLanguages &&
                        depotConfig["language"] != KeyValue.Invalid &&
                        !string.IsNullOrWhiteSpace(depotConfig["language"].Value))
                    {
                        var depotLang = depotConfig["language"].Value;
                        if (depotLang != (language ?? "english"))
                            continue;
                    }

                    if (!lv &&
                        depotConfig["lowviolence"] != KeyValue.Invalid &&
                        depotConfig["lowviolence"].AsBoolean())
                        continue;

                }

                depotIds.Add(id);
            }
        }

        if (depotIds.Count == 0)
        {
            throw new ContentDownloaderException(string.Format("Couldn't find any depots to download for app {0}", appId));
        }

        int buildNumber = GetSteam3AppBuildNumber(appId, branch);

        var infos = new List<DepotDownloadInfo>();
        foreach (var depotId in depotIds)
        {
            var info = await GetDepotInfo(depotId, appId, INVALID_MANIFEST_ID, branch);
            if (info != null)
            {
                infos.Add(info);
            }
        }

        return (buildNumber, infos);
    }

    async Task<DepotDownloadInfo> GetDepotInfo(int depotId, int appId, long manifestId, string branch)
    {
        if (steam3 != null && appId != INVALID_APP_ID)
        {
            await steam3.RequestAppInfo(appId);
        }

        if (!await AccountHasAccess(appId, depotId))
        {
            logger.LogError("Depot {0} is not available from this account.", depotId);

            return null;
        }

        if (manifestId == INVALID_MANIFEST_ID)
        {
            manifestId = await GetSteam3DepotManifest(depotId, appId, branch);
            if (manifestId == INVALID_MANIFEST_ID && !string.Equals(branch, DEFAULT_BRANCH, StringComparison.OrdinalIgnoreCase))
            {
                logger.LogError("Warning: Depot {0} does not have branch named \"{1}\". Trying {2} branch.", depotId, branch, DEFAULT_BRANCH);
                branch = DEFAULT_BRANCH;
                manifestId = await GetSteam3DepotManifest(depotId, appId, branch);
            }

            if (manifestId == INVALID_MANIFEST_ID)
            {
                logger.LogError("Depot {0} missing public subsection or manifest section.", depotId);
                return null;
            }
        }

        await steam3.RequestDepotKey(depotId, appId);
        if (!steam3.DepotKeys.TryGetValue(depotId, out var depotKey))
        {
            logger.LogError("No valid depot key for {0}, unable to download.", depotId);
            return null;
        }


        // For depots that are proxied through depotfromapp, we still need to resolve the proxy app id, unless the app is freetodownload
        var containingAppId = appId;
        var proxyAppId = GetSteam3DepotProxyAppId(depotId, appId);
        if (proxyAppId != INVALID_APP_ID)
        {
            var common = GetSteam3AppSection(appId, EAppInfoSection.Common);
            if (common == null || !common["FreeToDownload"].AsBoolean())
            {
                containingAppId = proxyAppId;
            }
        }

        return new DepotDownloadInfo(depotId, containingAppId, manifestId);
    }
}
