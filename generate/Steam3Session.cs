// This file is subject to the terms and conditions defined
// in file 'LICENSE', which is part of this source code package.

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

using Microsoft.Extensions.Logging;
using SteamKit2;
using SteamKit2.Authentication;
using SteamKit2.CDN;
using SteamKit2.Internal;

class Steam3Session
{
    public bool IsLoggedOn { get; private set; }

    public ReadOnlyCollection<SteamApps.LicenseListCallback.License> Licenses
    {
        get;
        private set;
    }

    public Dictionary<int, long> AppTokens { get; } = [];
    public Dictionary<int, long> PackageTokens { get; } = [];
    public Dictionary<int, byte[]> DepotKeys { get; } = [];
    public ConcurrentDictionary<(int, string), TaskCompletionSource<SteamContent.CDNAuthToken>> CDNAuthTokens { get; } = [];
    public Dictionary<int, SteamApps.PICSProductInfoCallback.PICSProductInfo> AppInfo { get; } = [];
    public Dictionary<int, SteamApps.PICSProductInfoCallback.PICSProductInfo> PackageInfo { get; } = [];
    public Dictionary<string, byte[]> AppBetaPasswords { get; } = [];

    public SteamClient steamClient;
    public SteamUser steamUser;
    public SteamContent steamContent;
    readonly SteamApps steamApps;
    readonly SteamCloud steamCloud;
    readonly PublishedFile steamPublishedFile;

    readonly CallbackManager callbacks;

    bool bConnecting;
    bool bAborted;
    bool bExpectingDisconnectRemote;
    bool bDidDisconnect;
    bool bIsConnectionRecovery;
    int connectionBackoff;
    int seq; // more hack fixes
    readonly CancellationTokenSource abortedToken = new();

    DownloadConfig downloadConfig;

    private readonly ILogger logger;

    // input
    readonly SteamUser.LogOnDetails logonDetails;

    public Steam3Session(SteamUser.LogOnDetails details, DownloadConfig downloadConfig, ILogger logger)
    {
        this.downloadConfig = downloadConfig;
        this.logger = logger;

        this.logonDetails = details;

        this.steamClient = new SteamClient();

        this.steamUser = this.steamClient.GetHandler<SteamUser>();
        this.steamApps = this.steamClient.GetHandler<SteamApps>();
        this.steamCloud = this.steamClient.GetHandler<SteamCloud>();
        var steamUnifiedMessages = this.steamClient.GetHandler<SteamUnifiedMessages>();
        this.steamPublishedFile = steamUnifiedMessages.CreateService<PublishedFile>();
        this.steamContent = this.steamClient.GetHandler<SteamContent>();

        this.callbacks = new CallbackManager(this.steamClient);

        this.callbacks.Subscribe<SteamClient.ConnectedCallback>(ConnectedCallback);
        this.callbacks.Subscribe<SteamClient.DisconnectedCallback>(DisconnectedCallback);
        this.callbacks.Subscribe<SteamUser.LoggedOnCallback>(LogOnCallback);
        this.callbacks.Subscribe<SteamApps.LicenseListCallback>(LicenseListCallback);

        logger.LogInformation("Connecting to Steam3...");
        Connect();
    }

    public delegate bool WaitCondition();

    private readonly Lock steamLock = new();

    public bool WaitUntilCallback(Action submitter, WaitCondition waiter)
    {
        while (!bAborted && !waiter())
        {
            lock (steamLock)
            {
                submitter();
            }

            var seq = this.seq;
            do
            {
                lock (steamLock)
                {
                    callbacks.RunWaitCallbacks(TimeSpan.FromSeconds(1));
                }
            } while (!bAborted && this.seq == seq && !waiter());
        }

        return bAborted;
    }

    public bool WaitForCredentials()
    {
        if (IsLoggedOn || bAborted)
            return IsLoggedOn;

        WaitUntilCallback(() => { }, () => IsLoggedOn);

        return IsLoggedOn;
    }

    public async Task TickCallbacks()
    {
        var token = abortedToken.Token;

        try
        {
            while (!token.IsCancellationRequested)
            {
                await callbacks.RunWaitCallbackAsync(token);
            }
        }
        catch (OperationCanceledException)
        {
            //
        }
    }

    public async Task RequestAppInfo(int appId, bool bForce = false)
    {
        if ((AppInfo.ContainsKey(appId) && !bForce) || bAborted)
            return;

        var appTokens = await steamApps.PICSGetAccessTokens([(uint)appId], []);

        if (appTokens.AppTokensDenied.Contains((uint)appId))
        {
            logger.LogError("Insufficient privileges to get access token for app {0}", appId);
        }

        foreach (var token_dict in appTokens.AppTokens)
        {
            this.AppTokens[(int)token_dict.Key] = (long)token_dict.Value;
        }

        var request = new SteamApps.PICSRequest((uint)appId);

        if (AppTokens.TryGetValue(appId, out var token))
        {
            request.AccessToken = (ulong)token;
        }

        var appInfoMultiple = await steamApps.PICSGetProductInfo([request], []);

        foreach (var appInfo in appInfoMultiple.Results)
        {
            foreach (var app_value in appInfo.Apps)
            {
                var app = app_value.Value;

                logger.LogInformation("Got AppInfo for {0}", app.ID);
                AppInfo[(int)app.ID] = app;
            }

            foreach (var app in appInfo.UnknownApps)
            {
                AppInfo[(int)app] = null;
            }
        }
    }

    public async Task RequestPackageInfo(IEnumerable<int> packageIds)
    {
        var packages = packageIds.ToList();
        packages.RemoveAll(PackageInfo.ContainsKey);

        if (packages.Count == 0 || bAborted)
            return;

        var packageRequests = new List<SteamApps.PICSRequest>();

        foreach (var package in packages)
        {
            var request = new SteamApps.PICSRequest((uint)package);

            if (PackageTokens.TryGetValue(package, out var token))
            {
                request.AccessToken = (ulong)token;
            }

            packageRequests.Add(request);
        }

        var packageInfoMultiple = await steamApps.PICSGetProductInfo([], packageRequests);

        foreach (var packageInfo in packageInfoMultiple.Results)
        {
            foreach (var package_value in packageInfo.Packages)
            {
                var package = package_value.Value;
                PackageInfo[(int)package.ID] = package;
            }

            foreach (var package in packageInfo.UnknownPackages)
            {
                PackageInfo[(int)package] = null;
            }
        }
    }

    public async Task<bool> RequestFreeAppLicense(int appId)
    {
        try
        {
            var resultInfo = await steamApps.RequestFreeLicense((uint)appId);

            return resultInfo.GrantedApps.Contains((uint)appId);
        }
        catch (Exception ex)
        {
            logger.LogError($"Failed to request FreeOnDemand license for app {appId}: {ex.Message}");
            return false;
        }
    }

    public async Task RequestDepotKey(int depotId, int appid = 0)
    {
        if (DepotKeys.ContainsKey(depotId) || bAborted)
            return;

        var depotKey = await steamApps.GetDepotDecryptionKey((uint)depotId, (uint)appid);

        logger.LogInformation("Got depot key for {0} result: {1}", depotKey.DepotID, depotKey.Result);

        if (depotKey.Result != EResult.OK)
        {
            return;
        }

        DepotKeys[(int)depotKey.DepotID] = depotKey.DepotKey;
    }


    public async Task<long> GetDepotManifestRequestCodeAsync(int depotId, int appId, long manifestId, string branch)
    {
        if (bAborted)
            return 0;

        var requestCode = (long)await steamContent.GetManifestRequestCode((uint)depotId, (uint)appId, (ulong)manifestId, branch);

        if (requestCode == 0)
        {
            logger.LogError($"No manifest request code was returned for depot {depotId} from app {appId}, manifest {manifestId}");
            // Suggestion: Try logging in with -username as old manifests may not be available for anonymous accounts.
        }
        else
        {
            logger.LogInformation($"Got manifest request code for depot {depotId} from app {appId}, manifest {manifestId}, result: {requestCode}");
        }

        return requestCode;
    }

    public async Task RequestCDNAuthToken(int appid, int depotid, Server server)
    {
        var cdnKey = (depotid, server.Host);
        var completion = new TaskCompletionSource<SteamContent.CDNAuthToken>();

        if (bAborted || !CDNAuthTokens.TryAdd(cdnKey, completion))
        {
            return;
        }

        logger.LogDebug($"Requesting CDN auth token for {server.Host}");

        var cdnAuth = await steamContent.GetCDNAuthToken((uint)appid, (uint)depotid, server.Host);

        logger.LogInformation($"Got CDN auth token for {server.Host} result: {cdnAuth.Result} (expires {cdnAuth.Expiration})");

        if (cdnAuth.Result != EResult.OK)
        {
            return;
        }

        completion.TrySetResult(cdnAuth);
    }

    public async Task CheckAppBetaPassword(int appid, string password)
    {
        var appPassword = await steamApps.CheckAppBetaPassword((uint)appid, password);

        logger.LogInformation("Retrieved {0} beta keys with result: {1}", appPassword.BetaPasswords.Count, appPassword.Result);

        foreach (var entry in appPassword.BetaPasswords)
        {
            AppBetaPasswords[entry.Key] = entry.Value;
        }
    }

    public async Task<KeyValue> GetPrivateBetaDepotSection(int appid, string branch)
    {
        if (!AppBetaPasswords.TryGetValue(branch, out var branchPassword)) // Should be filled by CheckAppBetaPassword
        {
            return new KeyValue();
        }

        AppTokens.TryGetValue(appid, out var accessToken); // Should be filled by RequestAppInfo

        var privateBeta = await steamApps.PICSGetPrivateBeta((uint)appid, (ulong)accessToken, branch, branchPassword);

        logger.LogInformation($"Retrieved private beta depot section for {appid} with result: {privateBeta.Result}");

        return privateBeta.DepotSection;
    }

    public async Task<PublishedFileDetails> GetPublishedFileDetails(int appId, PublishedFileID pubFile)
    {
        var pubFileRequest = new CPublishedFile_GetDetails_Request { appid = (uint)appId };
        pubFileRequest.publishedfileids.Add(pubFile);

        var details = await steamPublishedFile.GetDetails(pubFileRequest);

        if (details.Result == EResult.OK)
        {
            return details.Body.publishedfiledetails.FirstOrDefault();
        }

        throw new Exception($"EResult {(int)details.Result} ({details.Result}) while retrieving file details for pubfile {pubFile}.");
    }

    public async Task<SteamCloud.UGCDetailsCallback> GetUGCDetails(UGCHandle ugcHandle)
    {
        var callback = await steamCloud.RequestUGCDetails(ugcHandle);

        if (callback.Result == EResult.OK)
        {
            return callback;
        }
        else if (callback.Result == EResult.FileNotFound)
        {
            return null;
        }

        throw new Exception($"EResult {(int)callback.Result} ({callback.Result}) while retrieving UGC details for {ugcHandle}.");
    }

    private void ResetConnectionFlags()
    {
        bExpectingDisconnectRemote = false;
        bDidDisconnect = false;
        bIsConnectionRecovery = false;
    }

    void Connect()
    {
        bAborted = false;
        bConnecting = true;
        connectionBackoff = 0;

        ResetConnectionFlags();
        this.steamClient.Connect();
    }

    private void Abort(bool sendLogOff = true)
    {
        Disconnect(sendLogOff);
    }

    public void Disconnect(bool sendLogOff = true)
    {
        if (sendLogOff)
        {
            steamUser.LogOff();
        }

        bAborted = true;
        bConnecting = false;
        bIsConnectionRecovery = false;
        abortedToken.Cancel();
        steamClient.Disconnect();

        // flush callbacks until our disconnected event
        while (!bDidDisconnect)
        {
            callbacks.RunWaitAllCallbacks(TimeSpan.FromMilliseconds(100));
        }
    }

    private void Reconnect()
    {
        bIsConnectionRecovery = true;
        steamClient.Disconnect();
    }

    private void ConnectedCallback(SteamClient.ConnectedCallback connected)
    {
        logger.LogInformation(" Done!");
        bConnecting = false;

        // Update our tracking so that we don't time out, even if we need to reconnect multiple times,
        // e.g. if the authentication phase takes a while and therefore multiple connections.
        connectionBackoff = 0;

        logger.LogInformation("Logging anonymously into Steam3...");
        steamUser.LogOnAnonymous();
    }

    private void DisconnectedCallback(SteamClient.DisconnectedCallback disconnected)
    {
        bDidDisconnect = true;

        logger.LogDebug($"Disconnected: bIsConnectionRecovery = {bIsConnectionRecovery}, UserInitiated = {disconnected.UserInitiated}, bExpectingDisconnectRemote = {bExpectingDisconnectRemote}");

        // When recovering the connection, we want to reconnect even if the remote disconnects us
        if (!bIsConnectionRecovery && (disconnected.UserInitiated || bExpectingDisconnectRemote))
        {
            logger.LogInformation("Disconnected from Steam");

            // Any operations outstanding need to be aborted
            bAborted = true;
        }
        else if (connectionBackoff >= 10)
        {
            logger.LogError("Could not connect to Steam after 10 tries");
            Abort(false);
        }
        else if (!bAborted)
        {
            connectionBackoff += 1;

            if (bConnecting)
            {
                logger.LogError($"Connection to Steam failed. Trying again (#{connectionBackoff})...");
            }
            else
            {
                logger.LogError("Lost connection to Steam. Reconnecting");
            }

            Thread.Sleep(1000 * connectionBackoff);

            // Any connection related flags need to be reset here to match the state after Connect
            ResetConnectionFlags();
            steamClient.Connect();
        }
    }

    private void LogOnCallback(SteamUser.LoggedOnCallback loggedOn)
    {
        var isSteamGuard = loggedOn.Result == EResult.AccountLogonDenied;
        var is2FA = loggedOn.Result == EResult.AccountLoginDeniedNeedTwoFactor;

        if (loggedOn.Result == EResult.TryAnotherCM)
        {
            logger.LogInformation("Retrying Steam3 connection (TryAnotherCM)...");
            Reconnect();
            return;
        }

        if (loggedOn.Result == EResult.ServiceUnavailable)
        {
            logger.LogError("Unable to login to Steam3: {0}", loggedOn.Result);
            Abort(false);
            return;
        }

        if (loggedOn.Result != EResult.OK)
        {
            logger.LogError("Unable to login to Steam3: {0}", loggedOn.Result);
            Abort();
            return;
        }

        logger.LogInformation(" Done!");

        this.seq++;
        IsLoggedOn = true;

        if (downloadConfig.CellID == 0)
        {
            logger.LogInformation("Using Steam3 suggested CellID: " + loggedOn.CellID);
            downloadConfig.CellID = (int)loggedOn.CellID;
        }
    }

    private void LicenseListCallback(SteamApps.LicenseListCallback licenseList)
    {
        if (licenseList.Result != EResult.OK)
        {
            logger.LogError("Unable to get license list: {0} ", licenseList.Result);
            Abort();

            return;
        }

        logger.LogInformation("Got {0} licenses for account!", licenseList.LicenseList.Count);
        Licenses = licenseList.LicenseList;

        foreach (var license in licenseList.LicenseList)
        {
            if (license.AccessToken > 0)
            {
                PackageTokens.TryAdd((int)license.PackageID, (long)license.AccessToken);
            }
        }
    }

}
