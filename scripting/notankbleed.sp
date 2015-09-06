#pragma semicolon 1

#include <sourcemod>

#define REALLY_SMALL_FLOAT 0.0000008775

public Plugin:myinfo =
{
	name = "No Tank Bleed",
	author = "CanadaRox",
	description = "Stop temp health from decaying during a tank fight",
	version = "3",
	url = "https://github.com/CanadaRox/sourcemod-plugins/tree/master/notankbleed"
};

new Float:defaultRate;
new Handle:pain_pills_decay_rate;

public OnPluginStart()
{
	pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	defaultRate = GetConVarFloat(pain_pills_decay_rate);

#if defined DEBUG
	RegConsoleCmd("sm_temptest", TempTest_Cmd);
#endif

	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn_Event);
	HookEvent("player_death", PlayerDeath_Event);
}

public OnPluginEnd()
{
	SetConVarFloat(pain_pills_decay_rate, defaultRate);
}

#if defined DEBUG
public Action:TempTest_Cmd(client, args)
{
	new Float:currentTemp = GetSurvivorTempHealth(client);
	PrintToChat(client, "Current temp: %f", currentTemp);
	SetSurvivorTempHealth(client, currentTemp);
	PrintToChat(client, "New temp: %f", GetSurvivorTempHealth(client));
}
#endif

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetNewRate(defaultRate);
}

public TankSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetNewRate(REALLY_SMALL_FLOAT);
}

public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client <= MaxClients && GetClientTeam(client) == 3 && GetZombieClass(client) == 8)
	{
		new bool:foundTank = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (client != i && IsClientInGame(i) && GetClientTeam(i) == 3 && GetZombieClass(i) == 8)
			{
				foundTank = true;
				break;
			}
		}
		if (!foundTank)
		{
			SetNewRate(defaultRate);
		}
	}
}

stock SetNewRate(Float:rate = REALLY_SMALL_FLOAT)
{
	decl Float:tempHealth;
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsPlayerIncap(client))
		{
			tempHealth = GetSurvivorTempHealth(client);
			if (tempHealth > 0.0)
			{
				SetSurvivorTempHealth(client, tempHealth);
			}
		}
	}
	SetConVarFloat(pain_pills_decay_rate, rate);
}

stock Float:GetSurvivorTempHealth(client)
{
	return GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(pain_pills_decay_rate));
}

stock SetSurvivorTempHealth(client, Float:newOverheal)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

stock bool:IsPlayerIncap(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock GetZombieClass(client) return GetEntProp(client, Prop_Send, "m_zombieClass");
