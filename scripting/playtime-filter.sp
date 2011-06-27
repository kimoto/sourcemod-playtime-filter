// LICENCE: creative-commons: CC-BY
// AUTHOR: kimoto
#include <sourcemod>
#include "playtime-filter.inc"

#define PLUGIN_FILENAME "playtime-filter"
#define PLUGIN_VERSION "1.0.0"
#define GAMEID 550

new Handle:g_hEnable = INVALID_HANDLE;
new bool:g_bEnable = true;

// defualt is 0 <= x <= 100
new g_minPlayTime = 0;
new g_maxPlayTime = (100 * 60 * 60);

public Plugin:myinfo = {
  name = "playtime-filter",
  author = "kimoto",
  description = "playtime filter",
  version = "1.0.0",
  url = "http://github.com/kimoto/sourcemod-playtime-filter"
};

public IsValidPlayTime(playtime)
{
  return (g_minPlayTime <= playtime && playtime <= g_maxPlayTime);
}

public FilterBasedOnTotalPlayTime(client, playtime)
{
  if( IsClientInGame(client) && !IsClientBot(client) ){
    if(IsValidPlayTime(playtime)){
      DebugPrint("success login");
    }else{
      DebugPrint("kick player");
      KickClient(client, "rejected playtime filter");
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

public Action:Command_PlayTimeFilterTest(client, args)
{
  DebugPrint("Command_PlayTimeFilterTest\n");
  if(g_bEnable){
    for(new i=1; i<GetMaxClients(); i++){
      if( IsClientInGame(i) && !IsClientBot(i) ){
        new playtime = GetTotalPlayTimeByClient(i, GAMEID, "stat.xml");
        FilterBasedOnTotalPlayTime(i, playtime);
      }
    }
  }
}

public Action:Command_FormatTest(client, args)
{
  DebugPrint("format test\n");
}

public OnClientPutInServer(client)
{
  if(g_bEnable){
    DebugPrint("=================== connect: %d\n", client);
    new playtime = GetTotalPlayTimeByClient(client, GAMEID, "stat.xml");
    FilterBasedOnTotalPlayTime(client, playtime);
  }
}

// modify convars
public OnConVarsChanged(Handle:hConVar, const String:oldValue[], const String:newValue[])
{
  ReloadConvars();
}

public ReloadConvars()
{
  // reload convars
  g_bEnable = GetConVarBool(g_hEnable);
  //g_minPlayTime = GetConVarString(g_minPlayTime);
  //g_maxPlayTime = GetConVarString(g_maxPlayTime);
}

public OnPluginStart()
{
  CreateConVar("playtime_filter_version", PLUGIN_VERSION, "playtime-filter plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  g_hEnable   = CreateConVar("playtime_filter_enable", "0", "Enable/Disable playtime-filter plugin", FCVAR_PLUGIN);

  g_minPlayTime = CreateConVar("playtime_filter_min_playtime", "1", "playtime-filter min time", FCVAR_PLUGIN);
  g_maxPlayTime = CreateConVar("playtime_filter_max_playtime", "1", "playtime-filter max time", FCVAR_PLUGIN);

  HookConVarChange(g_hEnable, OnConVarsChanged);
  HookConVarChange(g_maxPlayTime, OnConVarsChanged);
  HookConVarChange(g_minPlayTime, OnConVarsChanged);

  AutoExecConfig(true, PLUGIN_FILENAME);
  ReloadConvars();

  RegConsoleCmd("playtime_filter_test", Command_PlayTimeFilterTest);
  RegConsoleCmd("playtime_format_test", Command_FormatTest);
}
