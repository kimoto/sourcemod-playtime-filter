// LICENCE: creative-commons: CC-BY
// AUTHOR: kimoto
#include <sourcemod>
#include <playtime-filter_async>

#define PLUGIN_FILENAME "playtime-filter"
#define PLUGIN_VERSION "1.0.0"
#define GAMEID 550

new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hMinPlayTime = INVALID_HANDLE;
new Handle:g_hMaxPlayTime = INVALID_HANDLE;

new bool:g_bEnable = true;
new g_iMinPlayTime = 0;
new g_iMaxPlayTime = 0;

public Plugin:myinfo = {
  name = "playtime-filter",
  author = "kimoto",
  description = "playtime filter",
  version = "1.0.0",
  url = "http://github.com/kimoto/sourcemod-playtime-filter"
};

public KickClientFormatText(client, const String:Message[], any:...)
{
  new String:buf[256];
  VFormat(buf, sizeof(buf), Message, 3);
  KickClient(client, buf);
}

public PlayTimeToString(playtime, String:buf[], sizeof_buf)
{
  new minutes = (playtime / 60);
  new seconds = (playtime % 60);

  new hours = (minutes / 60);
  minutes = (minutes % 60);

  Format(buf, sizeof_buf, "%02dh %02dm %02ds", hours, minutes, seconds);
}

public IsValidPlayTime(playtime)
{
  return (g_iMinPlayTime <= playtime && playtime <= g_iMaxPlayTime);
}

public KickClientByPlayTime(client, playtime)
{
  DebugPrint("kick client by playtime: %d\n", playtime);
  new String:curPlayTime[256];
  new String:minPlayTime[256];
  new String:maxPlayTime[256];

  PlayTimeToString(playtime, curPlayTime, sizeof(curPlayTime));
  PlayTimeToString(g_iMinPlayTime, minPlayTime, sizeof(minPlayTime));
  PlayTimeToString(g_iMaxPlayTime, maxPlayTime, sizeof(maxPlayTime));

  KickClientFormatText(client,
    "rejected by playtime filter (%s <= %s <= %s)",
    minPlayTime, curPlayTime, maxPlayTime);
}

public FilterBasedOnTotalPlayTime(client, playtime)
{
  if( IsClientInGame(client) && !IsClientBot(client) ){
    if(IsValidPlayTime(playtime)){
      DebugPrint("trust user (playtime): %d", playtime);
    }else{
      KickClientByPlayTime(client, playtime);
    }
  }
}

public IsClientBot(client)
{
  new String:SteamID[256];
  GetClientAuthString(client, SteamID, sizeof(SteamID));
  if (StrEqual(SteamID, "BOT"))
    return true;
  return false;
}

public Action:Command_PlayTimeFilterRun(client, args)
{
  DebugPrint("Command_PlayTimeFilterRun\n");

  for(new i=1; i<GetMaxClients(); i++){
    if( IsClientInGame(i) && !IsClientBot(i) ){ // human player & in game
      new playtime = GetTotalPlayTimeByClient(i, GAMEID, "stat.xml");
      FilterBasedOnTotalPlayTime(i, playtime);
    }
  }
}

public Action:Command_PlayTimeFilterAsyncRun(client, args)
{
  DebugPrint("Command_PlayTimeFilterAsyncRun\n");

  for(new i=1; i<GetMaxClients(); i++){
    if( IsClientInGame(i) && !IsClientBot(i) ){ // human player & in game
      SteamAPI_RequestStats(i);
    }
  }
}

public SteamAPI_ReceiveStats(client, playtime)
{
  DebugPrint("steamapi_stats_recevied: client:%d, playtime:%d\n", client, playtime);
  FilterBasedOnTotalPlayTime(client, playtime);
}

public TestParsePlayTimeFormat(String:format[], n)
{
  new r = ParsePlayTimeFormat(format);
  DebugPrint("%s -> %d (%b)\n", format, r, r == n);
}

public Action:Command_FormatTest(client, args)
{
  DebugPrint("format test\n");
  TestParsePlayTimeFormat("100h 10m 0s", 360600);
  TestParsePlayTimeFormat("100h 10m", 360600);
  TestParsePlayTimeFormat("100h", 360000);
  TestParsePlayTimeFormat("200h", 720000);

  TestParsePlayTimeFormat("100m 0s", 6000);
  TestParsePlayTimeFormat("100m", 6000);

  TestParsePlayTimeFormat("100s", 100);
  TestParsePlayTimeFormat("10s", 10);
  TestParsePlayTimeFormat("0s", 0);
  TestParsePlayTimeFormat("", 0);
  TestParsePlayTimeFormat("0", 0);
  TestParsePlayTimeFormat("1", 1);
}

public OnClientPutInServer(client)
{
  if(g_bEnable){
    DebugPrint("client connect: %d\n", client);
    SteamAPI_RequestStats(client);
  }
}

// modify convars
public OnConVarsChanged(Handle:hConVar, const String:oldValue[], const String:newValue[])
{
  ReloadConvars();
}

public ParsePlayTimeFormat(String:format[])
{
  new hours = RegexPatternMatchGetFirstInt(format, "([0-9]+)h");
  new minutes = RegexPatternMatchGetFirstInt(format, "([0-9]+)m");
  new seconds = RegexPatternMatchGetFirstInt(format, "([0-9]+)s?$");

  if(hours == -1){
    hours = 0;
  }
  if(minutes == -1){
    minutes = 0;
  }
  if(seconds == -1){
    seconds = 0;
  }

  return (hours * 60 + minutes) * 60 + seconds;
}

public GetConVarPlayTime(Handle:convar)
{
  new String:buf[256];
  GetConVarString(convar, buf, sizeof(buf));
  return ParsePlayTimeFormat(buf);
}

public ReloadConvars()
{
  // reload convars
  g_bEnable = GetConVarBool(g_hEnable);
  g_iMinPlayTime = GetConVarPlayTime(g_hMinPlayTime);
  g_iMaxPlayTime = GetConVarPlayTime(g_hMaxPlayTime);

  DebugPrint("ReloadConvars: g_iMinPlayTime: %d, g_iMaxPlayTime: %d\n", g_iMinPlayTime, g_iMaxPlayTime);
}

public OnPluginStart()
{
  CreateConVar("playtime_filter_version", PLUGIN_VERSION, "playtime-filter plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  g_hEnable   = CreateConVar("playtime_filter_enable", "0", "Enable/Disable playtime-filter plugin", FCVAR_PLUGIN);

  g_hMinPlayTime = CreateConVar("playtime_filter_min_playtime", "0s", "playtime-filter accept min playtime (min <= x <= max)", FCVAR_PLUGIN);
  g_hMaxPlayTime = CreateConVar("playtime_filter_max_playtime", "1000h", "playtime-filter accept max playtime(min <= x <= max)", FCVAR_PLUGIN);

  HookConVarChange(g_hEnable, OnConVarsChanged);
  HookConVarChange(g_hMaxPlayTime, OnConVarsChanged);
  HookConVarChange(g_hMinPlayTime, OnConVarsChanged);

  AutoExecConfig(true, PLUGIN_FILENAME);
  ReloadConvars();

  RegConsoleCmd("playtime_filter_async_run", Command_PlayTimeFilterAsyncRun);
  RegConsoleCmd("playtime_filter_run", Command_PlayTimeFilterRun);
  RegConsoleCmd("playtime_filter_format_test", Command_FormatTest);
}

