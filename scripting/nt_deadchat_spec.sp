#include <sourcemod>

char message[256];

bool targets[32 + 1];
bool IsTeamChat;

public Plugin myinfo =
{
	name        = "NT Dead Chat Spec",
	author      = "Root, ported to NT by bauxite",
	description = "Allows dead players to text chat with living teammates, spectators can always chat with everyone",
	version     = "0.1.0.spec",
};

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, false);
	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	for (int target = 1; target <= MaxClients; target++)
	{
		targets[target] = true;
	}
	
	IsTeamChat = StrEqual(command, "say_team", false);
	
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
	int i;

	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client != 0)
	{
		if (IsTeamChat)
		{
			for (i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && targets[i])
				{
					clients[numClients++] = i;
				}
			
				targets[i] = false;
			}
		}
		else
		{
			if (GetClientTeam(client) == 1)
			{
				for (i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && targets[i])
					{
						clients[numClients++] = i;
					}
				
					targets[i] = false;
				}
			}
		}
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
