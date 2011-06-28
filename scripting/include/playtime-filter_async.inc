// require semicolon
#pragma semicolon 1

#if defined __PLAYTIME_FILTER_ASYNC__
  #endinput
#endif

#define __PLAYTIME_FILTER_ASYNC__

#include <sourcemod>
#include <socket>
#include <regex>
#include <csteamid>

#define STEAMCOMMUNITY_HOST "steamcommunity.com"
//#define STEAMCOMMUNITY_HOST "localhost"
#define STEAMCOMMUNITY_PORT 80
#define STEAMCOMMUNITY_STATS_API_FORMAT "/profiles/%s/statsfeed/550/?xml=1&schema=1"

stock Handle:buffers = INVALID_HANDLE;

#define DEBUG_STRING_BUFFER_SIZE 256
public DebugPrint(const String:Message[], any:...)
{
  decl String:DebugBuff[DEBUG_STRING_BUFFER_SIZE];
  VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
  LogMessage(DebugBuff);
}

public Handle:RegexPatternMatch(String:string[], String:pattern[])
{
  new Handle:regex = CompileRegex(pattern, 0, "", 0);
  new re = MatchRegex(regex, string);
  new Handle:matches;

  if(re > 0){
    //DebugPrint("regexpatternmatch: match\n");
    matches = CreateArray(re);

    for(new i=0; i<re; i++){
      new String:buf[1024];
      GetRegexSubString(regex, i, buf, sizeof(buf));
      //DebugPrint("buf: %s\n", buf);
      PushArrayString(matches, buf);
    }
    CloseHandle(regex);
    return matches;
  }

  CloseHandle(regex);
  return INVALID_HANDLE;
}

public bool:RegexPatternMatchGetFirst(String:string[], String:pattern[], String:buf[], buf_size)
{
  new Handle:matched = RegexPatternMatch(string, pattern);
  if(matched == INVALID_HANDLE){
    //DebugPrint("not matched\n");
    return false;
  }
  //DebugPrint("matched\n");
  new i = (GetArraySize(matched) >= 1 ? 1 : 0);
  GetArrayString(matched, i, buf, buf_size);
  return true;
}

public RegexPatternMatchGetFirstInt(String:string[], String:pattern[])
{
  new String:buf[256];
  if( !RegexPatternMatchGetFirst(string, pattern, buf, sizeof(buf)) ){
    return -1;
  }
  return StringToInt(buf);
}

public SteamAPI_RequestStats(client)
{
  new String:profileId[256];
  ClientIndexToProfileId(client, profileId, sizeof(profileId));

  // fetch from api
  GetAsyncPlayTimeByProfileId(client, profileId);
}

public ClientIndexToProfileId(client, String:profileId[], size_of_profileId)
{
  // client index -> steamid
  new String:steamId[256];
  GetClientAuthString(client, steamId, sizeof(steamId));
  DebugPrint("client index: %d -> steamid: %s\n", client, steamId);

  // steam id -> profile id
  SteamIDToCSteamID(steamId, profileId, size_of_profileId);
  DebugPrint("steam id -> profile id: %s\n", profileId);
}

public GetAsyncHttpGet_OnConnected(Handle:socket, any:opt)
{
  new client = opt;

  new String:profileId[256];
  ClientIndexToProfileId(client, profileId, sizeof(profileId));

  new String:requestPath[256];
  Format(requestPath, sizeof(requestPath), STEAMCOMMUNITY_STATS_API_FORMAT, profileId);
  DebugPrint("request path: %s\n", requestPath);

  new String:requestStr[256];
  Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", requestPath, STEAMCOMMUNITY_HOST);
  SocketSend(socket, requestStr);
}

public GetAsyncHttpGet_OnReceive(Handle:socket, String:receiveData[], const dataSize, any:opt)
{
  new client = opt;

  new Handle:pack = GetArrayCell(buffers, client);
  //DebugPrint("pack(receive): %d, %s\n", pack, receiveData);

  WritePackString(pack, receiveData);

  //WriteFileString(hFile, receiveData, false);
  //StrCat(http_buffer, sizeof(http_buffer), receiveData);
}

//= end of http get template

/*
 * get async playtime by steam profile id
 */
public GetAsyncPlayTimeByProfileId(client, String:profileId[])
{
  // clear accept buffer
  new Handle:pack = GetArrayCell(buffers, client);
  if(pack != INVALID_HANDLE){
    DebugPrint("****** Error: nanka okasii\n");
    return;
    /*
    CloseHandle(pack);
    pack = INVALID_HANDLE;
    */
  }
  pack = CreateDataPack();
  ResetPack(pack);
  SetArrayCell(buffers, client, pack);

  // create a new tcp socket
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);

  // add client index option
  SocketSetArg(socket, client);

  SocketSetOption(socket, SocketReceiveTimeout, 5000);
  SocketSetOption(socket, SocketSendTimeout, 5000);

  // connect the socket
  SocketConnect(socket,
    GetAsyncHttpGet_OnConnected,
    GetAsyncHttpGet_OnReceive,
    GetAsyncPlayTime_OnDisconnected,
    STEAMCOMMUNITY_HOST, STEAMCOMMUNITY_PORT);
}

public SteamAPI_PrintCachedStat(client)
{
  new Handle:pack = GetArrayCell(buffers, client);
  ResetPack(pack);

  new String:buf[5000];
  ReadPackString(pack, buf, sizeof(buf));
  DebugPrint("SteamAPI_PrintCachedStat(%d): %s\n", client, buf);
}

public SteamAPI_Init(number_of_clients)
{
  //DebugPrint("number_of_clients: %d\n", number_of_clients);

  buffers = CreateArray(number_of_clients, number_of_clients);
  for(new i=0; i<number_of_clients; i++){
    new Handle:pack = CreateDataPack();
    //ResetPack(pack);
    SetArrayCell(buffers, i, INVALID_HANDLE);
  }
}

forward SteamAPI_ReceiveStats(client, playtime);

public GetTotalPlayTimeFromXML(String:xmldata[])
{
  return RegexPatternMatchGetFirstInt(xmldata, "stat.totalplaytime.total.*<value>([0-9]+)");
}

public GetAsyncPlayTime_OnDisconnected(Handle:socket, any:opt)
{
  new client = opt;
  new Handle:pack = GetArrayCell(buffers, client);
  DebugPrint("pack(disconnect): %d\n", pack);

  new String:buf[5000];
  ResetPack(pack);
  ReadPackString(pack, buf, sizeof(buf));
  //DebugPrint("read pack: %s\n", buf);

  new playtime = GetTotalPlayTimeFromXML(buf);
  SteamAPI_ReceiveStats(client, playtime);
  CloseHandle(socket);

  CloseHandle(pack);
  pack = INVALID_HANDLE;
  SetArrayCell(buffers, client, pack);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:opt) {
  // a socket error occured
  LogError("socket error %d (errno %d)", errorType, errorNum);
  CloseHandle(socket);
}

