
/*	Copyright (C) 2017 IT-KiLLER
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <colors_csgo>
#undef REQUIRE_EXTENSIONS
#include <voiceannounce_ex>

#pragma semicolon 1
#pragma newdecls required

bool MuteStatus[MAXPLAYERS+1][MAXPLAYERS+1];
char clientNames[MAXPLAYERS+1][MAX_NAME_LENGTH];

float clientTalkTime[MAXPLAYERS+1] = { 0.0, ... };
ConVar sm_selfmute_admin, sm_selfmute_talk_seconds, sm_selfmute_spam_mutes;

public Plugin myinfo = 
{
	name = "Self-Mute Intelligence",
	author = "Otokiru, edit 93x, Accelerator, IT-KiLLER",
	description = "Mute player just for you.",
	version = "1.5",
	url = "https://github.com/IT-KiLLER"
}

public void OnPluginStart() 
{   
	LoadTranslations("common.phrases");
	CreateConVar("sm_selfmute_version", "1.5", "Version of Self-Mute", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_sm", selfMute, "Mute player by typing !selfmute <name>");
	RegConsoleCmd("sm_su", selfUnmute, "Unmute player by typing !su <name>");
	sm_selfmute_admin = CreateConVar("sm_selfmute_admin", "0.0", "Admin can not be muted. Disabled by default", _, true, 0.0, true, 1.0);
	sm_selfmute_talk_seconds = CreateConVar("sm_selfmute_talk_seconds", "45.0", "List clients who have recently spoken within x secounds", _, true, 1.0, true, 180.0);
	sm_selfmute_spam_mutes = CreateConVar("sm_selfmute_spam_mutes", "4.0", "How many mutes a client needs to get listed as spammer.", _, true, 1.0, true, 64.0);
}

public void OnMapStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		clientTalkTime[client] = 0.0;
	}
}

public void OnClientDisconnect_Post(int client)
{
	clientTalkTime[client] = 0.0;
	for (int id = 1; id <= MaxClients; id++)
	{
		MuteStatus[id][client] = false;
		if (id != client)
		{
			if (MuteStatus[id][client])
			{
				SetListenOverride(id, client, Listen_No);
			}
		}
	}
}

public void OnClientSpeakingEx(int client)
{
	if (GetClientListeningFlags(client) == VOICE_MUTED) return;
	clientTalkTime[client] = GetGameTime();
}

public void OnClientSpeakingEnd(int client)
{
	if (GetClientListeningFlags(client) == VOICE_MUTED) return;
	clientTalkTime[client] = GetGameTime();
}

public Action selfMute(int client, int args)
{
	if(!client) return Plugin_Handled;
	
	if(args < 1) 
	{
		DisplayMuteMenu(client);
		return Plugin_Handled;
	}
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget)); 

	if(StrEqual(strTarget, "@me"))
	{
		CPrintToChat(client, "{green}[SM]{red} You can not mute yourself.");
		return Plugin_Handled; 
	}
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget,0, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED/*|COMMAND_FILTER_NO_BOTS*/, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}

	muteTargetedPlayers(client, TargetList, TargetCount, strTarget);
	return Plugin_Handled;
}


stock void DisplayMuteMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_MuteMenu);
	menu.SetTitle("Self-Mute Intelligence");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	float gametime = GetGameTime();

	// Lised clients
	bool clientAlreadyListed[MAXPLAYERS+1] = {false,...}; 

	// Excluding client from the menu.
	clientAlreadyListed[client] = true; 
	
	// Sort array
	int clientSortRecentlyTalked[MAXPLAYERS+1] = {0,1,...}; 

	char strClientID[12];
	char strClientName[50];
	bool loop = true;
	int myindex = 0;
	int temp = 0;

	// Sorts who have recently spoken 
	do {
		loop=false;
		myindex++;
		for(int i = 1; i < MaxClients - myindex; i++) {
			int target1 = clientSortRecentlyTalked[i];
			int target2 = clientSortRecentlyTalked[i + 1];
			if(clientTalkTime[target1] < clientTalkTime[target2]) {
				temp = clientSortRecentlyTalked[target1];
				clientSortRecentlyTalked[target1] = clientSortRecentlyTalked[target2];
				clientSortRecentlyTalked[target2] = temp;
				loop = true;
				}
			}
	} while (loop);

	// Players who speak now or have just done it. Adds these to the menu.
	for(int i = 0; i <= MaxClients; i++)
	{
		int target = clientSortRecentlyTalked[i];
		if(target != 0 && (IsClientInGame(target) && !clientAlreadyListed[target] && !MuteStatus[client][target] && (clientTalkTime[target]+sm_selfmute_talk_seconds.FloatValue) > gametime))
		{
			clientAlreadyListed[target] = true;
			IntToString(GetClientUserId(target), strClientID, sizeof(strClientID));
			if(gametime == clientTalkTime[target]) // Speaking now
			{
				FormatEx(strClientName, sizeof(strClientName), "%N (Speaking + %dM)", target, targetMutes(target,true));
			} else {
				FormatEx(strClientName, sizeof(strClientName), "%N (%1.fs + %dM)", target, gametime-clientTalkTime[target], targetMutes(target,true));
			}
			menu.AddItem(strClientID, strClientName);
		}
	}

	loop = true;

	// Provides suggestions for clients to mute based on other clients choices.
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && !clientAlreadyListed[target] && targetMutes(target, true) >= sm_selfmute_spam_mutes.IntValue && !MuteStatus[client][target]) 
		{
			clientAlreadyListed[target] = true;
			IntToString(GetClientUserId(target), strClientID, sizeof(strClientID));
			FormatEx(strClientName, sizeof(strClientName), "%N (SPAM %dM)", target, targetMutes(target, true));
			menu.AddItem(strClientID, strClientName);
		}
	}

	int[] alphabetClients = new int[MaxClients+1];

	// Alphabetical sorting of clients
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !clientAlreadyListed[i])
		{
			alphabetClients[i] = i;
			GetClientName(alphabetClients[i], clientNames[alphabetClients[i]], sizeof(clientNames[]));
		}
	}

	SortCustom1D(alphabetClients, MaxClients, SortByPlayerName);
	
	for(int i = 0; i < MaxClients; i++)
	{
		if(alphabetClients[i]!=0 && !clientAlreadyListed[alphabetClients[i]] && !MuteStatus[client][alphabetClients[i]]) 
		{
			IntToString(GetClientUserId(alphabetClients[i]), strClientID, sizeof(strClientID));
			FormatEx(strClientName, sizeof(strClientName), "%N", alphabetClients[i]);
			menu.AddItem(strClientID, strClientName);
		}
	}

	if(menu.ItemCount == 0) 
	{
		CPrintToChat(client, "{green}[SM]{lightgreen} Could not list any players, you already have muted {red}%d{lightgreen} players", clientMutes(client));
		delete(menu);
	} else {
		if(menu.ItemCount>7) {
			menu.ExitBackButton = true;
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}


public int MenuHandler_MuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);
			
			if ((target = GetClientOfUserId(userid)) == 0)
			{
				CPrintToChat(param1, "{green}[SM]{red} Player no longer available");
			}
			else
			{
				// This will be improved in a later update
				int temp[1];
				temp[0] = target;
				muteTargetedPlayers(param1, temp, 1, "");
			}
		}
	}
}

public void muteTargetedPlayers(int client, int[] list, int TargetCount, const char[] filtername)
{

	if(TargetCount==1)
	{
		int target = list[0];
		if(client == target){
			CPrintToChat(client, "{green}[SM]{red} You can not mute yourself.");
			return;
		}
		if(sm_selfmute_admin.BoolValue && IsPlayerAdmin(target)) {
			CPrintToChat(client, "{green}[SM]{red} You can not mute an admin: {lightblue} %N", target);
			return;
		}   
		SetListenOverride(client, target, Listen_No);
		CPrintToChat(client, "{green}[SM]{lightgreen} You have self-muted: %N", target);
		MuteStatus[client][target] = true;

	} 
	else if(TargetCount>1)
	{
		char textNames[250];
		int textSize = 0, countTargets = 0;

		for (int target = 0; target < TargetCount; target++) 
		{
			if(list[target] == client || MuteStatus[client][list[target]] || (sm_selfmute_admin.BoolValue && IsPlayerAdmin(list[target]))) continue;
			countTargets++;
			MuteStatus[client][list[target]] = true;
			SetListenOverride(client, list[target], Listen_No);
			FormatEx(textNames, sizeof(textNames), "%s%s%N", textNames, countTargets==1 ? "" : ", ",  list[target]);
			textSize = strlen(textNames) - textSize;
		}
		if(countTargets>0) 
		{
			CPrintToChat(client, "{green}[SM]{lightgreen} You have self-muted(%d){green}: %s", countTargets , (textSize <= sizeof(textNames) && countTargets <= 14 ) ? textNames : getFilterName(filtername));
		} else
		{
			CPrintToChat(client, "{green}[SM]{lightgreen} Everyone in the list was already muted.");
		}
	}
}

public void unMuteTargetedPlayers(int client, int[] list, int TargetCount, const char[] filtername)
{
	if(TargetCount==1)
	{
		int target = list[0];
		if(client == target){
			CPrintToChat(client, "{green}[SM]{red} You can not unmute yourself.");
			return;
		}
		if(sm_selfmute_admin.BoolValue && IsPlayerAdmin(target)) {
			CPrintToChat(client, "{green}[SM]{red} You can not unmute an admin: %N", target);
			return;
		}
		SetListenOverride(client, target, Listen_Yes);
		CPrintToChat(client, "{green}[SM]{lightgreen} You have self-unmuted: %N", target);
		MuteStatus[client][target] = false;

	} 
	else if(TargetCount>1)
	{
		char textNames[250];
		int textSize = 0, countTargets = 0;
		for (int target = 0; target < TargetCount; target++) 
		{
			if(list[target] == client || !MuteStatus[client][list[target]] || (sm_selfmute_admin.BoolValue && IsPlayerAdmin(list[target])) ) continue;
			countTargets++;
			SetListenOverride(client, list[target], Listen_Yes);
			MuteStatus[client][list[target]] = false;
			FormatEx(textNames, sizeof(textNames), "%s%s%N", textNames, countTargets==1 ? "" : ", ",  list[target]);
			textSize = strlen(textNames) - textSize;
		}
		if(countTargets>0) 
		{
			CPrintToChat(client, "{green}[SM]{lightgreen} You have self-unmuted(%d){green}: %s", countTargets , (textSize <= sizeof(textNames) && countTargets <= 14 ) ? textNames : getFilterName(filtername));
		}
		else
		{
			CPrintToChat(client, "{green}[SM]{lightgreen} Everyone in the list was already unmuted.");
		}
	}
}

public Action selfUnmute(int client, int args)
{
	if(!client) return Plugin_Handled;
	
	if(args < 1) 
	{
		DisplayUnMuteMenu(client);
		return Plugin_Handled;
	}
	
	char arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	
	if(StrEqual(strTarget, "@me"))
	{
		CPrintToChat(client, "{green}[SM]{red} You can not unmute yourself.");
		return Plugin_Handled; 
	}

	if ((TargetCount = ProcessTargetString(strTarget, 0, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}

	unMuteTargetedPlayers(client, TargetList, TargetCount, strTarget);
	return Plugin_Handled;
}

stock void DisplayUnMuteMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_UnMuteMenu);
	menu.SetTitle("Self-unMute Intelligence");
	char strClientID[12];
	char strClientName[50];
	
	for(int target = 1; target <= MaxClients; target++)
	{
		if(client != target && IsClientInGame(target) && MuteStatus[client][target]) 
		{
			IntToString(GetClientUserId(target), strClientID, sizeof(strClientID));
			FormatEx(strClientName, sizeof(strClientName), "%N (M)", target);
			menu.AddItem(strClientID, strClientName);
		}
	}
	if(menu.ItemCount==0) 
	{
		CPrintToChat(client, "{green}[SM]{lightgreen} No players are muted.");
		delete(menu);
	} else {
		if(menu.ItemCount>7) {
			menu.ExitBackButton = true;
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_UnMuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);
			
			if ((target = GetClientOfUserId(userid)) == 0)
			{
				CPrintToChat(param1, "{green}[SM]{red} Player no longer available");
			}
			else
			{
				// This will be improved in a later update
				int temp[1];
				temp[0] = target;
				unMuteTargetedPlayers(param1, temp, 1, "");
			}
		}
	}
}

// Checking if a client is admin
stock bool IsPlayerAdmin(int client)
{
	if (CheckCommandAccess(client, "Kick_admin", ADMFLAG_KICK, false))
	{
		return true;
	}
	return false;
}  

stock int SortByPlayerName(int player1, int player2, const int[] array, Handle hndl)
{
	return strcmp(clientNames[player1], clientNames[player2], false);
}

// Counting how many mutes a client has done.
stock int clientMutes(int client)
{
	int count=0;
	for (int target = 1; target <= MaxClients ; target++){
		if(MuteStatus[client][target]) count++;
	}
	return count;
}
// Counting how many mutes a target has received.
stock int targetMutes(int target, bool massivemute = false)
{
	int count = 0;
	int mutes = 0;
	for (int client = 1; client <= MaxClients ; client++){
		if(MuteStatus[client][target] && ( massivemute && (mutes=clientMutes(client)) > 0 && mutes <= (MaxClients/2) ) ) 
		{
			count++;
		}
	}
	return count;
}

stock char getFilterName(const char[] filter)
{
	// This will be improved in a later update
	char temp[30];
	if(StrEqual(filter, "@all"))
	{
		temp = "Everyone";
	} 
	else if(StrEqual(filter, "@spec"))
	{
		temp = "Spectators";
	} 
	else if(StrEqual(filter, "@ct"))
	{
		temp = "Counter-Terrorists";
	} 
	else if(StrEqual(filter, "@t"))
	{
		temp = "Terrorists";
	}
	else if(StrEqual(filter, "@dead"))
	{
		temp = "Dead players";
	}
	else if(StrEqual(filter, "@alive"))
	{
		temp = "Alive players";
	}
	else if(StrEqual(filter, "@!me"))
	{
		temp = "Everyone except me";
	}
	else if(StrEqual(filter, "@admins"))
	{
		temp = "Admins";
	} else {
		FormatEx(temp, sizeof(temp), "%s", filter);
	}
	return temp;
}