using System;
using System.Collections.Generic;
using System.CommandLine;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

using Microsoft.Extensions.Logging;
using SteamKit2;
using SteamKit2.CDN;
using Scriban;

class Program
{
  public const string template =
@"load(""@rules_steam//:steam.bzl"", ""steam_app"")

BUILD_{{name}} = ""{{build}}""

def repos(ctx):
    steam_app(
        name = ""{{name}}"",
        depots = [
            {{~ for depot in infos ~}}
            {""app"": ""{{depot.app}}"", ""depot"": ""{{depot.depot}}"", ""manifest"": ""{{depot.manifest}}""},
            {{~ end ~}}
        ],
    )

steamapps_bzlmod = module_extension(implementation = repos)
";

  static async Task<int> Main(string[] args)
  {
    // Setup logger

    var loggerFactory = LoggerFactory.Create(builder =>
    {
      builder.AddConsole(o => o.LogToStandardErrorThreshold = 0);
      builder.AddSimpleConsole(o => o.SingleLine = true);
      builder.SetMinimumLevel(LogLevel.Debug);
    });
    ILogger<Program> logger = loggerFactory.CreateLogger<Program>();

    // Parse arguments

    var rootCommand = new RootCommand();

    var outOption = new Option<string>(
      name: "--out",
      description: "output file path");
    rootCommand.AddOption(outOption);

    var appOption = new Option<int>(
      name: "--app",
      description: "Steam app to target",
      getDefaultValue: () => 90);
    rootCommand.AddOption(appOption);

    var repoOption = new Option<string>(
      name: "--repo",
      description: "Name for bazel repo rule");
    rootCommand.AddOption(repoOption);

    var osOption = new Option<string>(
      name: "--os",
      description: "steam app os",
      getDefaultValue: () => Util.GetSteamOS());
    rootCommand.AddOption(osOption);

    var archOption = new Option<string>(
      name: "--arch",
      description: "steam app arch",
      getDefaultValue: () => Util.GetSteamArch());
    rootCommand.AddOption(archOption);

    var branchOption = new Option<string>(
      name: "--branch",
      description: "Steam app branch to use",
      getDefaultValue: () => ContentDownloader.DEFAULT_BRANCH);
    rootCommand.AddOption(branchOption);

    logger.LogInformation("Starting DepotDownloader...");

    ContentDownloader downloader = new ContentDownloader(logger);

    rootCommand.SetHandler(async (outPath, app, repo, os, arch, branch) =>
    {
      downloader.Config.DownloadAllPlatforms = false;
      downloader.Config.DownloadAllArchs = false;

      string language = null;
      bool lv = false;
      bool isUGC = false;
      var depotManifestIds = new List<(int, long)>();

      if (!downloader.InitializeSteam3())
      {
        throw new InvalidOperationException("Failed to initialize Steam3 connection.");
      }

      try
      {
        logger.LogInformation("App ID: {0}", app);
        logger.LogInformation($"{downloader.Config}");
        (int buildNumber, var manifestInfos) = await downloader.LookupManifestsForAppAsync(
          (int)app, branch, os, arch, language, lv, isUGC);

        var result = Template.Parse(template).Render(new
        {
          Build = buildNumber,
          Name = repo,
          Infos = manifestInfos.Select(d => new
          {
            app = d.AppId,
            depot = d.DepotId,
            manifest = d.ManifestId
          })
        });

        File.WriteAllText(outPath, result);
        logger.LogInformation($"Wrote output to {outPath}");

      }
      finally
      {
        downloader.ShutdownSteam3();
      }
    }, outOption, appOption, repoOption, osOption, archOption, branchOption);

    return await rootCommand.InvokeAsync(args);
  }
}
