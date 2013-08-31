/** 
 * MCP specific HTTP request implementation
 * 
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class HttpRequestWindowsMcp extends HttpRequestWindows;

/** The app id value to append to the URL */
var const string AppId;

/** The app secret value to append to the URL */
var const string AppSecret;

/** Automatically appends the specified app id and app secret values to the URL if going to MCP */
function bool ProcessRequest()
{
	local string Url;

	Url = GetURL();
	if (InStr(Url, "appspot.com") != INDEX_NONE ||
		InStr(Url, "localhost:8888") != INDEX_NONE)
	{
		// Append the app id and secret value to the URL
		if (InStr(Url, "?") != INDEX_NONE)
		{
			Url $= "&appKey=" $ AppId;
		}
		else
		{
			Url $= "?appKey=" $ AppId;
		}
		Url $= "&appSecret=" $ AppSecret;
		SetURL(Url);
	}
	return Super.ProcessRequest();
}

defaultproperties
{
	AppId="ib2"
	AppSecret="bd3f341b_94b8_4e03_9a97_fdbf6b404b3c"
}
