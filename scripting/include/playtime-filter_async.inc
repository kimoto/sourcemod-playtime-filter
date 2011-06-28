// require semicolon
#pragma semicolon 1

#if defined __PLAYTIME_FILTER_ASYNC__
  #endinput
#endif

#define __PLAYTIME_FILTER_ASYNC__

#include <sourcemod>
#include <socket>
#include <regex>
#include <playtime-filter>

#define DEBUG_STRING_BUFFER_SIZE 1024

public String:http_buffer[51200] = "";
public findPlayerClientIndex = 1;

public SteamAPI_RequestStats(client)
{
  // client index -> steamid
  new String:steamId[256];
  GetClientAuthString(client, steamId, sizeof(steamId));
  DebugPrint("client index: %d -> steamid: %s\n", client, steamId);

  // steam id -> profile id
  new String:profileId[256];
  SteamIDToCSteamID(steamId, profileId, sizeof(profileId));
  DebugPrint("steam id -> profile id: %s\n", profileId);

  // fetch from api
  GetAsyncPlayTimeByProfileId(client, profileId);
}

/*
 * HTTP Get Template (Async)
 */
new String:http_path[256];
new String:http_host[256];
new http_port = 0;
public GetAsyncHttpGet(String:host[], port, String:path[])
{
  strcopy(http_path, sizeof(http_path), path);
  strcopy(http_host, sizeof(http_host), host);
  http_port = port;

  // create a new tcp socket
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);

  // connect the socket
  SocketConnect(socket,
    GetAsyncHttpGet_OnConnected,
    GetAsyncHttpGet_OnReceive,
    GetAsyncHttpGet_OnDisconnected,
    http_host, http_port);
}

public GetAsyncHttpGet_OnConnected(Handle:socket, any:opt)
{
  new String:requestStr[256];
  Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", http_path, http_host);
  SocketSend(socket, requestStr);
}

public GetAsyncHttpGet_OnReceive(Handle:socket, String:receiveData[], const dataSize, any:opt)
{
  StrCat(http_buffer, sizeof(http_buffer), receiveData);
}

public GetAsyncHttpGet_OnDisconnected(Handle:socket, any:opt)
{
  // nop;
}

//= end of http get template

/*
 * get async playtime by steam profile id
 */
public GetAsyncPlayTimeByProfileId(client, String:profileId[])
{
  new String:pathTemplate[] = "/profiles/%s/statsfeed/550/?xml=1&schema=1";
  new String:host[] = "steamcommunity.com";
  new port = 80;

  new String:requestPath[256];
  Format(requestPath, sizeof(requestPath), pathTemplate, profileId);
  DebugPrint("request path: %s\n", requestPath);

  strcopy(http_path, sizeof(http_path), requestPath);
  strcopy(http_host, sizeof(http_host), host);
  http_port = port;

  // create a new tcp socket
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);

  // add client index option
  SocketSetArg(socket, client);

  // connect the socket
  SocketConnect(socket,
    GetAsyncHttpGet_OnConnected,
    GetAsyncHttpGet_OnReceive,
    GetAsyncPlayTime_OnDisconnected,
    http_host, http_port);
}

forward SteamAPI_ReceiveStats(client, playtime);

public GetAsyncPlayTime_OnDisconnected(Handle:socket, any:opt)
{
  new client = opt; // opt == client index

  new playtime = GetTotalPlayTimeFromXML(http_buffer);
  DebugPrint("playtime: %d", playtime);

  /*
  if(playtime < (1000 * 60 * 60 * 60)){
    CreateTimer(0.1, cfTimer, findPlayerClientIndex); // kick code
  }
  */
  DebugPrint("call SteamAPI_ReceiveStats\n");
  SteamAPI_ReceiveStats(client, playtime);

  CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
  // a socket error occured
  LogError("socket error %d (errno %d)", errorType, errorNum);
  CloseHandle(hFile);
  CloseHandle(socket);
}

