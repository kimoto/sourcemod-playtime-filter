// LICENCE: Creative Commons(CC BY)
// Author: kimoto
// playtime-filter prototype code
// not complete yet, programming now

// require semicolon
#pragma semicolon 1

#include <sourcemod>
#include <socket>
#include <regex>

#define DEBUG_STRING_BUFFER_SIZE 1024

public String:http_buffer[51200] = "";

public Plugin:myinfo = {
	name = "socket example",
	author = "Player",
	description = "This example demonstrates downloading a http file with the socket extension",
	version = "1.1.0",
	url = "http://www.player.to/"
};

public findPlayerClientIndex = 1;

public DebugPrint(const String:Message[], any:...)
{
	if (true)
	{
		decl String:DebugBuff[DEBUG_STRING_BUFFER_SIZE];
		VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
		LogMessage(DebugBuff);
	}
}

public Action:Command_Test(client, args)
{
	DebugPrint("************** Command_Test(VVV) *****************");
  //GetAsyncHttpGet("steamcommunity.com", 80, "/id/usopuki/stats/L4D2");
  GetAsyncPlayTimeByProfileId("76561198019632638");
  /*
  DebugPrint("playtime: %d\n", GetPlayTimeFromString("1967h 31m 3s"));
  DebugPrint("playtime: %d\n", GetPlayTimeFromString("1967h 31m"));
  DebugPrint("playtime: %d\n", GetPlayTimeFromString("1967h"));
  */
	DebugPrint("************** SOCKET END *********************");
}

public Action:Command_TestKick(client, args)
{
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
public GetAsyncPlayTimeByProfileId(String:profileId[])
{
  new String:pathTemplate[] = "/profiles/%s/stats/L4D2";
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

	// connect the socket
	SocketConnect(socket,
    GetAsyncHttpGet_OnConnected,
    GetAsyncHttpGet_OnReceive,
    GetAsyncPlayTime_OnDisconnected,
    http_host, http_port);
}

public GetAsyncPlayTime_OnDisconnected(Handle:socket, any:opt)
{
  new playtime = -1;
  if( IsSteamProfilePublic(http_buffer) ){
    playtime = GetSteamProfilePlayTime(http_buffer);
  }
  DebugPrint("playtime: %d", playtime);
  // CreateTimer(0.1, cfTimer, findPlayerClientIndex); // kick code
  CloseHandle(socket);
}

/*
 * get async playtime by steam profile id
 */
new finding = false;
public PlayTimeFilterByProfileId(String:profileId[])
{
  finding = true;

  new String:pathTemplate[] = "/profiles/%s/stats/L4D2";
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

	// connect the socket
	SocketConnect(socket,
    GetAsyncHttpGet_OnConnected,
    GetAsyncHttpGet_OnReceive,
    PlayTimeFilterByProfileId_OnDisconnected,
    http_host, http_port);
}

public PlayTimeFilterByProfileId_OnDisconnected(Handle:socket, any:opt)
{
  new playtime = -1;
  if( IsSteamProfilePublic(http_buffer) ){
    playtime = GetSteamProfilePlayTime(http_buffer);
  }
  DebugPrint("playtime: %d", playtime);
  if(playtime < (1000 * 60 * 60 * 60)){
    CreateTimer(0.1, cfTimer, findPlayerClientIndex); // kick code
  }
  CloseHandle(socket);

  finding = false;
}

// string number -> number array
public BigIntParse(String:value[])
{
  new len = strlen(value);
  new ary = CreateArray(len, len);
  for(new i=0; i<len; i++){
    SetArrayCell(ary, i, value[i] - 48); // 48 == '0' character
  }
  return ary;
}

public StringToBigInt(String:str[])
{
  return BigIntParse(str);
}

public BigIntToString(Handle:bigint, String:buf[], buf_size)
{
  new size = GetArraySize(bigint);
  for(new i=0; i<size; i++){
    new d = GetArrayCell(bigint, i);
    buf[i] = d + 48; // 48 == '0' character
  }
}

public PaddingArray(Handle:ary, padSize, padNum)
{
  if(GetArraySize(ary) > padSize){
    return -1;
  }

  // init array buffer
  new Handle:newbuf = CreateArray(padSize, padSize);
  for(new i=0; i<padSize; i++){
    SetArrayCell(newbuf, i, padNum);
  }

  for(new i=0; i<GetArraySize(ary); i++){
    new j = i + (padSize - GetArraySize(ary));
    SetArrayCell(newbuf, j, GetArrayCell(ary,i));
  }
  return newbuf;
}

public Max(x, y)
{
  if(x > y)
    return x;
  else
    return y;
}

public MatrixAdd(Handle:ary1, Handle:ary2)
{
  new size = GetArraySize(ary1);
  new Handle:result = CreateArray(size, size);

  for(new i=0; i<size; i++){
    new a = GetArrayCell(ary1, i);
    new b = GetArrayCell(ary2, i);
    SetArrayCell(result, i, a + b);
  }
  return result;
}

public ArrayReverse(Handle:ary)
{
  new size = GetArraySize(ary);
  new Handle:result = CreateArray(size, size);

  for(new i=0; i<size; i++){
    new j = size - i - 1;
    new data = GetArrayCell(ary, j);
    SetArrayCell(result, i, data);
  }
  return result;
}

public BigIntAdd(Handle:val1, Handle:val2)
{
  // array no keta awase
  new max_size = Max(GetArraySize(val1), GetArraySize(val2));
  new Handle:pad1 = PaddingArray(val1, max_size, 0);
  new Handle:pad2 = PaddingArray(val2, max_size, 0);

  // matrix de add
  new Handle:added = MatrixAdd(pad1, pad2);

  // reverse
  new Handle:reversed = ArrayReverse(added);

  // keta no kuriagari syori
  new i = 0;
  new size = GetArraySize(reversed);
  new kuriagari = 0;

  new Handle:result = CreateArray();

  while(true){
    // if array index range
    new data = 0;
    if(i < size){
      data = GetArrayCell(reversed, i);
    }else{
      //break;
    }

    new next_v = (data + kuriagari) / 10;
    new v = (data + kuriagari) % 10;

    if(kuriagari == 0 && next_v == 0 && v == 0 && i >= size){
      break;
    }

    // add result
    PushArrayCell(result, v);

    i++;
    kuriagari = next_v;
  }

  return ArrayReverse(result);
}

public DebugPrintBigInt(Handle:bigint)
{
  for(new i=0; i<GetArraySize(bigint); i++){
    new j = GetArrayCell(bigint, i);
    DebugPrint("DebugPrint: bigint[%d] = %d\n", i, j);
  }
}

public Action:Command_TestBigInt(client, args)
{
  DebugPrint("command test bigint");
  new Handle:bigintA = BigIntParse("211");
  new Handle:bigintB = BigIntParse("922");

  new Handle:bigintC = BigIntAdd(bigintA, bigintB);
  DebugPrint("******************");
//  DebugPrintBigInt(bigintC);

  new String:buf[256];
  BigIntToString(bigintC, buf, sizeof(buf));
  DebugPrint("buf: %s\n", buf);
}

// @return: -1 error, 0 success
public SteamIdToProfileId(String:steamid[], String:profileId[], bufsize)
{
  // steamid to friendid
  new Handle:matches = RegexPatternMatch(steamid, "([0-9]+):([0-9]+):([0-9]+)");
  //new Handle:matches = RegexPatternMatch(steamid, "([a-z]+[0-9]+)");
  if(matches == -1){
    return -1; // not steamid
  }else{
    new j = 0;
    for(j=0; j<GetArraySize(matches); j++){
      new String:buf[256];
      GetArrayString(matches, j, buf, sizeof(buf));
    }

    new String:buf[256];

    // base
    GetArrayString(matches, 2, buf, sizeof(buf));
    new bigint_base = StringToBigInt(buf);

    // core_id
    GetArrayString(matches, 3, buf, sizeof(buf));
    new bigint_core_id = StringToBigInt(buf);

    // fix_value
    new fix_value = BigIntParse("76561197960265728");

    // calc profile_id
    new bigint_double_core = BigIntAdd(bigint_core_id, bigint_core_id);
    new core_fixed = BigIntAdd(bigint_double_core, fix_value);
    new based_fixed = BigIntAdd(core_fixed, bigint_base);

    BigIntToString(based_fixed, profileId, bufsize);
    return 0;
  }
}

public Action:Command_TestClientInfo(client, args)
{
  for(new i=1; i<GetMaxClients(); i++){
    DebugPrint("client: %d", i);
    if(IsClientInGame(i)){
      DebugPrint("in-game client");

      new String:name[256];
      GetClientName(i, name, sizeof(name));
      DebugPrint("name: %s", name);

      new String:steamid[256];
      GetClientAuthString(i, steamid, sizeof(steamid));
      DebugPrint("steamid: %s", steamid);

      // steamid to friendid
      new String:profileid[256];
      SteamIdToProfileId(steamid, profileid, sizeof(profileid));
      DebugPrint("profileid: %s\n", profileid);

      // getprofileid async
      //GetAsyncPlayTimeByProfileId(profileid);
      if(finding == true){
        DebugPrint("finding other steamid, please wait\n");
      }else{
        findPlayerClientIndex = i;
        PlayTimeFilterByProfileId(profileid);
      }

      // profileid to playtime
      DebugPrint("clientofuserid: %d", GetClientOfUserId(i));
      DebugPrint("client team: %d", GetClientTeam(i));
      DebugPrint("client serial number: %d", GetClientSerial(i));
    }
  }
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
  DebugPrint("||||||||||||||||||||||| client connected!!!: %d", client);
  return true;
}

public OnPluginStart() {
  RegConsoleCmd("test_bigint", Command_TestBigInt);
  RegConsoleCmd("test_http_get", Command_Test);
  RegConsoleCmd("test_kick_client", Command_TestKick);
  RegConsoleCmd("test_client_info", Command_TestClientInfo);
  //CreateTimer(3.0, PrintMsg, _, TIMER_REPEAT);
}

public Action:PrintMsg(Handle:timer)
{
  DebugPrint("timer event now");
}



public IsSteamProfilePublic(String:html[])
{
  if( StrContains(html, "<p class=\"errorPrivate\">", false) == -1 ){
    return true;
  }else{
    return false;
  }
}

public GetRegexSubStringInt(Handle:regex, id)
{
  new String:buf[256];
  GetRegexSubString(regex, id, buf, sizeof(buf));
  return StringToInt(buf);
}

public RegexPatternMatch(String:string[], String:pattern[])
{
  new Handle:regex = CompileRegex(pattern, 0, "", 0);
  new re = MatchRegex(regex, string);
  new Handle:matches;

  if(re > 0){
    matches = CreateArray(re);

    new i = 0;
    for(i = 0; i<re; i++){
      new String:buf[256];
      GetRegexSubString(regex, i, buf, sizeof(buf));
      PushArrayString(matches, buf);
    }
    CloseHandle(regex);
    return matches;
  }

  CloseHandle(regex);
  return -1;
}

public RegexPatternMatchGetIntFirst(String:string[], String:pattern[])
{
  new matched = RegexPatternMatch(string, pattern);
  if(matched == -1){
    return 0;
  }
  for(new i=0; i<GetArraySize(matched); i++){
    new String:buf[256];
    GetArrayString(matched, i, buf, sizeof(buf));
    return StringToInt(buf);
  }
}

// @return real total play seconds
public GetPlayTimeFromString(String:buf[])
{
  new hour = RegexPatternMatchGetIntFirst(buf, "([0-9]+)h");
  new min = RegexPatternMatchGetIntFirst(buf, "([0-9]+)m");
  new sec = RegexPatternMatchGetIntFirst(buf, "([0-9]+)s");
  DebugPrint("hour:%d, min:%d, sec:%d", hour, min, sec);
  return ((hour * 60) + min) * 60 + sec;
}

// @return
//  not found: -1
//  found: seconds(int)
public GetSteamProfilePlayTime(String:html[])
{
  new String:tsblVal[] = "<div id=\"tsblVal\">";
  new String:divEndTag[] = "</div>";
  new String:brTag[] = "<br />";
  new r = StrContains(html, tsblVal);
  if(r == -1){
    return -1; // not found play time
  }

  // increment buffer pointer
  r = r + strlen(tsblVal);

  new p = StrContains(html[r], divEndTag);
  if(p == -1){
    return -1;
  }

  new buffer_len = p + 1;
  DebugPrint("buffer_len: %d", buffer_len);

  new String:buffer[buffer_len];
  StrCat(buffer, buffer_len, html[r]);
  DebugPrint("%s", buffer);

  // find <br /> tag
  new o = StrContains(buffer, brTag);
    if(o == -1){
      return -1;
    }

  // before <br /> = total play time
  new totalTimeLen = o + 1;
  new String:totalPlayTime[totalTimeLen];
  StrCat(totalPlayTime, totalTimeLen, buffer);

  // parse total play time
  // example: 1956h 26m 51s
  new totalPlaySeconds = GetPlayTimeFromString(totalPlayTime);
  DebugPrint("totalPlayTime: %d", totalPlaySeconds);

  // after <br /> = 2 week play time
  return totalPlaySeconds;
}

public Action:cfTimer(Handle:timer, any:client)
{
  KickClient(client, "rejected playtime filter");
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
  // a socket error occured
  LogError("socket error %d (errno %d)", errorType, errorNum);
  CloseHandle(hFile);
  CloseHandle(socket);
}
