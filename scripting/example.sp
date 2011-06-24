// playtime-filter prototype code
// not complete yet, programming now
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

public String:findPlayerId[] = "kimoto";
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
	
	/*
	new Handle:hFile2 = OpenFile("tttttttttttttttttttttt.txt", "wb");
	WriteFileString(hFile2, "hogefugapiyo", false);
	CloseHandle(hFile2);
	*/
	
	// create a new tcp socket
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	// open a file handle for writing the result
	new Handle:hFile = OpenFile("dl.htm", "wb");
	// pass the file handle to the callbacks
	SocketSetArg(socket, hFile);
	// connect the socket
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80)

	DebugPrint("************** SOCKET END *********************");
}

public Action:Command_TestKick(client, args)
{
}

public Action:Command_TestClientInfo(client, args)
{
	//DebugPrint("************** Command_Test(VVV) *****************");

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
      new Handle:matches = RegexPatternMatch(steamid, "([0-9]+):([0-9]+):([0-9]+)");
      //new Handle:matches = RegexPatternMatch(steamid, "([a-z]+[0-9]+)");
      if(matches == -1){
        DebugPrint("not matched\n");
      }else{
        DebugPrint("size: %d\n", GetArraySize(matches));

        new j = 0;
        for(j=0; j<GetArraySize(matches); j++){
          DebugPrint("jjjj = %d\n", j);

          new String:buf[256];
          GetArrayString(matches, j, buf, sizeof(buf));
          DebugPrint("ary[%d] = %s\n", j, buf);
        }

        new String:buf[256];

        GetArrayString(matches, 1, buf, sizeof(buf));
        new Float:base = StringToInt(buf);

        GetArrayString(matches, 3, buf, sizeof(buf));
        new Float:core_id = StringToInt(buf);

        DebugPrint("base: %d, core_id: %d\n", base, core_id);

        new Float:profileid = core_id * 2 + (76561197960265728) + base;
        DebugPrint("profileid: %f\n", 76561197960265);
        DebugPrint("profileid: %f\n", profileid);
      }

      DebugPrint("clientofuserid: %d", GetClientOfUserId(i));
      DebugPrint("client team: %d", GetClientTeam(i));
      DebugPrint("client serial number: %d", GetClientSerial(i));
    }
  }
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
  DebugPrint("||||||||||||||||||||||| client connected!!!: %d", client);

  /*
  // create a new tcp socket
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
  // open a file handle for writing the result
  new Handle:hFile = OpenFile("dl.htm", "wb");
  // pass the file handle to the callbacks
  SocketSetArg(socket, hFile);
  // connect the socket
  SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80)
   */

  return true;
}

public OnPluginStart() {
  RegConsoleCmd("test_http_get", Command_Test)
    RegConsoleCmd("test_kick_client", Command_TestKick);
  RegConsoleCmd("test_client_info", Command_TestClientInfo);
  //CreateTimer(3.0, PrintMsg, _, TIMER_REPEAT);
}

public Action:PrintMsg(Handle:timer)
{
  DebugPrint("timer event now");
}

public OnSocketConnected(Handle:socket, any:arg) {
  // socket is connected, send the http request
  decl String:requestStr[100];
  decl String:urlFormat[] = "/id/%s/stats/L4D2";

  new String:buf[256];
  Format(buf, sizeof(buf), urlFormat, findPlayerId);

  Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", urlFormat, "steamcommunity.com");
  SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
  // receive another chunk and write it to <modfolder>/dl.htm
  // we could strip the http response header here, but for example's sake we'll leave it in
  /*DebugPrint(receiveData);*/
  StrCat(http_buffer, sizeof(http_buffer), receiveData);
  //WriteFileString(hFile, receiveData, false);
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
    DebugPrint("re: %d\n", re);
    matches = CreateArray(re);

    new i = 0;
    for(i = 0; i<re; i++){
      new String:buf[256];
      GetRegexSubString(regex, i, buf, sizeof(buf));
      DebugPrint("re parts: %s\n", buf);
      PushArrayString(matches, buf);
    }
    CloseHandle(regex);
    return matches;
  }

  CloseHandle(regex);
  return -1;
}

// @return real total play seconds
public GetPlayTimeFromString(String:buf[])
{
  new Handle:regex = CompileRegex("(([0-9]+)h )?(([0-9]+)m )?([0-9]+)s", 0, "", 0);
  new re = MatchRegex(regex, buf);
  if(re == 6){
    new hour = GetRegexSubStringInt(regex, 2);
    new min = GetRegexSubStringInt(regex, 4);
    new sec = GetRegexSubStringInt(regex, 5);
    DebugPrint("re:%d, hour:%d, min:%d, sec:%d", re, hour, min, sec);

    CloseHandle(regex);
    return ((hour * 60) + min) * 60 + sec;
  }
  CloseHandle(regex);
  return 0;
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
  new o = StrContains(buffer, brTag)
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

public OnSocketDisconnected(Handle:socket, any:hFile) {
  // Connection: close advises the webserver to close the connection when the transfer is finished
  // we're done here
  DebugPrint("************* OnSocketDisconnected");

  new playtime = -1;

  // いままでに受け取ったデータをコンソールに出力する
  // なんかうまく行かんかったときは0としちゃう
  if( IsSteamProfilePublic(http_buffer) ){
    // プレイ時間を取得する
    playtime = GetSteamProfilePlayTime(http_buffer);
  }

  DebugPrint("playtime: %d", playtime);

  // プレイ時間取得出来なかったらkick
  if(playtime == -1){
    CreateTimer(0.1, cfTimer, findPlayerClientIndex);
    return;
  }

  CloseHandle(hFile);
  CloseHandle(socket);
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
