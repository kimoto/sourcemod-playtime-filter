// LICENCE: creative-commons: CC-BY
// AUTHOR: kimoto
#include <sourcemod>
#include "playtime-filter.inc"

#define GAMEID 550

public Plugin:myinfo = {
  name = "playtime-filter",
  author = "kimoto",
  description = "playtime filter",
  version = "1.0.0",
  url = "http://github.com/kimoto/sourcemod-playtime-filter"
};

public FilterBasedOnTotalPlayTime(client, playtime)
{
  if( IsClientInGame(client) && !IsClientBot(client) ){
    if(playtime > (700 * 60 * 60)){
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

public Action:Command_Test(client, args)
{
  for(new i=1; i<GetMaxClients(); i++){
    if( IsClientInGame(i) && !IsClientBot(i) ){
      new playtime = GetTotalPlayTimeByClient(i, GAMEID, "stat.xml");
      FilterBasedOnTotalPlayTime(i, playtime);
    }
  }
}

public OnClientPutInServer(client)
{
  DebugPrint("=================== connect: %d\n", client);
  new playtime = GetTotalPlayTimeByClient(client, GAMEID, "stat.xml");
  FilterBasedOnTotalPlayTime(client, playtime);
}

public OnPluginStart() {
  RegConsoleCmd("test_curl", Command_Test);
}
