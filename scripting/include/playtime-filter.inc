#pragma semicolon 1

#if defined __PLAYTIME_FILTER__
  #endinput
#endif

#define __PLAYTIME_FILTER__

#include <sourcemod>
#include <cURL>
#include <regex>
#include <csteamid>

#define USE_THREAD 1

// copy from sample file
new CURL_Default_opt[][2] = {
#if USE_THREAD
  {_:CURLOPT_NOSIGNAL,1},
#endif
  {_:CURLOPT_NOPROGRESS,1},
  {_:CURLOPT_TIMEOUT,30},
  {_:CURLOPT_CONNECTTIMEOUT,60},
  {_:CURLOPT_VERBOSE,0}
};
#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))
#define DEBUG_STRING_BUFFER_SIZE 1024

new Handle:curl = INVALID_HANDLE;

public DebugPrint(const String:Message[], any:...)
{
  decl String:DebugBuff[DEBUG_STRING_BUFFER_SIZE];
  VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
  LogMessage(DebugBuff);
}

// connected to server
public onComplete(Handle:hndl, CURLcode:code, any:data)
{
  DebugPrint("successfull: %d\n", code);

  if(code == CURLE_OK){
    DebugPrint("CURLE_OK\n");
  }else{
    DebugPrint("error!: %d\n", code);
  }

  /*
  new Handle:rfile = OpenFile(filePath, "r");
  new String:buffer[1024];
  ReadFileString(rfile, buffer, sizeof(buffer));
  new totalPlayTime = GetTotalPlayTimeFromXML(buffer);
  DebugPrint("total: %d\n", totalPlayTime);
  CloseHandle(rfile);
  */
}

/*
stock ExecCURL(Handle:curl, String:statFilePath[])
{
#if USE_THREAD
  curl_easy_perform_thread(curl, onComplete, 0);
#else
  DebugPrint("single thread mode!!\n");
  new CURLcode:code = curl_load_opt(curl);
  if(code != CURLE_OK) {
    CloseHandle(curl);
    return;
  }

  code = curl_easy_perform(curl);
  //DebugPrint("oncomplete");
  //onComplete(curl, code, 1);
  //DebugPrint("oncomplete end");
#endif
}
*/

public Handle:RegexPatternMatch(String:string[], String:pattern[])
{
  new Handle:regex = CompileRegex(pattern, 0, "", 0);
  new re = MatchRegex(regex, string);
  new Handle:matches;

  if(re > 0){
    DebugPrint("regexpatternmatch: match\n");
    matches = CreateArray(re);

    for(new i=0; i<re; i++){
      new String:buf[1024];
      GetRegexSubString(regex, i, buf, sizeof(buf));
      DebugPrint("buf: %s\n", buf);
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
    return false;
  }
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

public GetStatFilePath(String:profileId[], String:buf[], sizeof_buf)
{
  Format(buf, sizeof_buf, "steamstats_%s.xml", profileId);
}

public GetSteamStatXML(String:profileId[], gameId, String:filePath[])
{
  new String:url[256];
  Format(url, sizeof(url), "http://steamcommunity.com/profiles/%s/statsfeed/%d/?xml=1&schema=1", profileId, gameId);

  curl = curl_easy_init();
  if(curl != INVALID_HANDLE)
  {
    new String:profileIdBasedPath[256];
    GetStatFilePath(profileId, profileIdBasedPath, sizeof(profileIdBasedPath));

    CURL_DEFAULT_OPT(curl);
    //new Handle:file = curl_OpenFile(filePath, "w"); // profileid based filename
    //new Handle:file = curl_OpenFile(profileIdBasedPath, "w"); // profileid based filename
    //curl_easy_setopt_int(curl, CURLOPT_CONNECT_ONLY, 1); // connect only
    //curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, file);
    curl_easy_setopt_string(curl, CURLOPT_URL, url);
    //ExecCURL(curl, profileIdBasedPath);
    curl_easy_perform_thread(curl, onComplete);
    //CloseHandle(file);
  }
}

public GetTotalPlayTimeFromXML(String:xmldata[])
{
  DebugPrint("xml: %s\n", xmldata);
  return RegexPatternMatchGetFirstInt(xmldata, "stat.totalplaytime.total.*<value>([0-9]+)");
}

public GetTotalPlayTimeByProfileId(String:profileId[], gameId, String:filePath[])
{
  GetSteamStatXML(profileId, gameId, filePath);

  /*
  new Handle:rfile = OpenFile(filePath, "r");
  new String:buffer[1024];
  ReadFileString(rfile, buffer, sizeof(buffer));
  new totalPlayTime = GetTotalPlayTimeFromXML(buffer);
  DebugPrint("total: %d\n", totalPlayTime);
  CloseHandle(rfile);
  */

  new totalPlayTime = -1;
  return totalPlayTime;
}

public GetTotalPlayTimeBySteamId(String:steamId[], gameId, String:filePath[])
{
  new String:profileId[64];
  if( SteamIDToCSteamID(steamId, profileId, sizeof(profileId)) ){
    return GetTotalPlayTimeByProfileId(profileId, gameId, filePath);
  }else{
    DebugPrint("convert fail: steamid(%s) to profileid", steamId);
    return -1;
  }
}

public GetTotalPlayTimeByClient(client, gameId, String:filePath[])
{
  new String:steamid[256];
  if(GetClientAuthString(client, steamid, sizeof(steamid))){
    DebugPrint("steamid: %s", steamid);
    return GetTotalPlayTimeBySteamId(steamid, gameId, filePath);
  }else{
    DebugPrint("cant get steamid from client index(%d)", client);
    return -1;
  }
}
