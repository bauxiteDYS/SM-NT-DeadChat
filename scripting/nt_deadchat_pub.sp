#include <sourcemod>

ConVar cvarAllChat;
char message[192];
bool targets[32+1];
bool teamChat;
bool allChat

public Plugin myinfo =
{
	name = "NT Dead Chat",
	author = "bauxite, based on Root_ All Chat",
	description = "Allows dead players to text chat with living teammates",
	version = "0.3.0",
};

public OnPluginStart()
{
	cvarAllChat = CreateConVar("sm_nt_all_chat", "0", "Enable to let everyone see all chat, or disable to allow just Specs", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarAllChat, Changed_AllChat);
	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, false);
	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
	
	AutoExecConfig(true);
}

public void OnConfigsExecuted()
{
	allChat = cvarAllChat.BoolValue;
}

void Changed_AllChat(ConVar convar, const char[] oldValue, const char[] newValue)
{
	allChat = convar.BoolValue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{	
	teamChat = StrEqual(command, "say_team", false);
	
	for (int target = 1; target <= MaxClients; target++)
	{
		targets[target] = true;
	}
	
	return Plugin_Continue;
}

public Action SayTextHook(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	BfReadString(bf, message, sizeof(message));

	for (int i; i < playersNum; i++)
	{
		targets[players[i]] = false;
	}
	
	return Plugin_Continue;
}

public void Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)
{
	int clients[32+1];
	int numClients;
	int client;

	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0 || client > MaxClients)
	{
		return;
	}
	
	if(teamChat)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && targets[i])
			{
				clients[numClients++] = i;
			}
			
			targets[i] = false;
		}
	}
	else
	{
		if(allChat || GetClientTeam(client) == 1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && targets[i])
				{
					clients[numClients++] = i;
				}
				
				targets[i] = false;
			}
		}
	}
	
	if(numClients == 0)
	{
		return;
	}
	
	Handle SayText = StartMessage("SayText", clients, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if (SayText != INVALID_HANDLE)
	{
		BfWriteByte(SayText, client);

		BfWriteString(SayText, message);

		BfWriteByte(SayText, -1);

		EndMessage();
	}
}
