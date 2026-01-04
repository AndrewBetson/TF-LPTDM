// SPDX-FileCopyrightText: © Andrew Betson
// SPDX-License-Identifier: AGPL-3.0-or-later

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include <tf2>
#include <tf2_stocks>
#include <tf2utils>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "LPTDM - Spawn Protection",
	author		= "Andrew \"andrewb\" Betson",
	description	= "Configurable spawn protection plugin for LazyPurple's TDM Server.",
	version		= "1.4.0",
	url			= "https://www.github.com/AndrewBetson/TF-LPTDM"
};

bool	g_bIsPreGame;

bool	g_bIsClientProtected[ MAXPLAYERS + 1 ] = { false, ... };
bool	g_bShouldClientReceiveProtection[ MAXPLAYERS + 1 ] = { false, ... };
bool	g_bHasLeftSpawnroom[ MAXPLAYERS + 1 ] = { false, ... };
float	g_nClientProtectionTime[ MAXPLAYERS + 1 ] = { 0.0, ... };

ConVar	sv_lptdm_spawnprotection_cancel_on_attack;
ConVar	sv_lptdm_spawnprotection_fade_duration;
ConVar	sv_lptdm_spawnprotection_disable_during_pregame;
ConVar	sv_lptdm_spawnprotection_duration;

public void OnPluginStart()
{
	if ( GetEngineVersion() != Engine_TF2 )
	{
		SetFailState( "The LPTDM plugins are only compatible with Team Fortress 2." );
	}

	AutoExecConfig( true, "lptdm_spawnprotection" );

	sv_lptdm_spawnprotection_cancel_on_attack = CreateConVar(
		"sv_lptdm_spawnprotection_cancel_on_attack",
		"1",
		"Cancel spawn protection when a player fires their weapon.",
		FCVAR_NONE,
		true, 0.0,
		true, 1.0
	);

	sv_lptdm_spawnprotection_fade_duration = CreateConVar(
		"sv_lptdm_spawnprotection_fade_duration",
		"1.5",
		"Duration of fading protection state. Effectively adds this many seconds to protection time.",
		FCVAR_NONE,
		true, 0.001
	);

	sv_lptdm_spawnprotection_disable_during_pregame = CreateConVar(
		"sv_lptdm_spawnprotection_disable_during_pregame",
		"1.0",
		"Disable spawn protection during pre-game warmup.",
		FCVAR_NONE,
		true, 0.0,
		true, 1.0
	);

	sv_lptdm_spawnprotection_duration = CreateConVar(
		"sv_lptdm_spawnprotection_duration",
		"3.5",
		"How long spawn protection should last.",
		FCVAR_NONE,
		true, 0.001
	);

	HookEvent( "player_spawn", Event_PlayerSpawn, EventHookMode_Post );
	HookEvent( "player_death", Event_PlayerDeath, EventHookMode_Post );
}

void Protection_Apply( int nClientIdx )
{
	TF2_AddCondition( nClientIdx, TFCond_Ubercharged, sv_lptdm_spawnprotection_duration.FloatValue );
	g_bIsClientProtected[ nClientIdx ] = true;
	g_bShouldClientReceiveProtection[ nClientIdx ] = false;
	g_nClientProtectionTime[ nClientIdx ] = GetGameTime();
}

Action Event_PlayerSpawn( Handle hEvent, char[] szName, bool bDontBroadcast )
{
	if ( g_bIsPreGame && sv_lptdm_spawnprotection_disable_during_pregame.BoolValue )
	{
		return Plugin_Continue;
	}

	int nClientIdx = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if ( !g_bShouldClientReceiveProtection[ nClientIdx ] )
	{
		return Plugin_Continue;
	}

	Protection_Apply( nClientIdx );

	return Plugin_Continue;
}

Action Event_PlayerDeath( Handle hEvent, char[] szName, bool bDontBroadcast )
{
	if ( g_bIsPreGame && sv_lptdm_spawnprotection_disable_during_pregame.BoolValue )
	{
		return Plugin_Continue;
	}

	int nClientIdx = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	g_bIsClientProtected[ nClientIdx ] = false;
	g_bShouldClientReceiveProtection[ nClientIdx ] = true;
	g_bHasLeftSpawnroom[ nClientIdx ] = false;

	return Plugin_Continue;
}

public void OnMapStart()
{
	CreateTimer( 1.0, Timer_ExtendProtection, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

Action Timer_ExtendProtection( Handle hTimer )
{
	for ( int nClientIdx = 1; nClientIdx <= MaxClients; nClientIdx++ )
	{
		if ( IsClientInGame( nClientIdx ) && g_bIsClientProtected[ nClientIdx ] && !g_bHasLeftSpawnroom[ nClientIdx ] )
		{
			float vOrigin[ 3 ];
			GetClientAbsOrigin( nClientIdx, vOrigin );
			if ( TF2Util_IsPointInRespawnRoom( vOrigin, nClientIdx, true ) )
			{
				Protection_Apply( nClientIdx );
			}
			else
			{
				g_bHasLeftSpawnroom[ nClientIdx ] = true;
			}
		}
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	for ( int i = 0; i < MAXPLAYERS + 1; i++ )
	{
		g_bIsClientProtected[ i ] = false;
		g_bShouldClientReceiveProtection[ i ] = false;
		g_bHasLeftSpawnroom[ i ] = false;
	}
}

public void OnClientConnected( int nClientIdx )
{
	if ( g_bIsPreGame && sv_lptdm_spawnprotection_disable_during_pregame.BoolValue )
	{
		return;
	}

	g_bShouldClientReceiveProtection[ nClientIdx ] = true;
}

public void OnClientDisconnect( int nClientIdx )
{
	g_bIsClientProtected[ nClientIdx ] = false;
	g_bShouldClientReceiveProtection[ nClientIdx ] = false;
	g_bHasLeftSpawnroom[ nClientIdx ] = false;
}

public void TF2_OnConditionRemoved( int nClientIdx, TFCond eCondition )
{
	if ( eCondition != TFCond_Ubercharged || !g_bIsClientProtected[ nClientIdx ] )
	{
		return;
	}

	float flFadeDuration = sv_lptdm_spawnprotection_fade_duration.FloatValue;

	// This is incredibly hacky, but doing this the right way
	// would be a bit of a nightmare.
	TF2_AddCondition( nClientIdx, TFCond_Ubercharged, flFadeDuration );
	TF2_AddCondition( nClientIdx, TFCond_UberchargeFading, flFadeDuration );

	g_bIsClientProtected[ nClientIdx ] = false;
	g_nClientProtectionTime[ nClientIdx ] = 0.0;
}

public void TF2_OnWaitingForPlayersStart()
{
	g_bIsPreGame = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bIsPreGame = false;
}

static int g_nWeaponsWithSecondaryFire[] = {
	44, 220, 648, 812,							// Sandman, Shortstop, Wrap Assassin, Guillotine
	441,										// Cow Mangler
	21, 40, 215, 741, 1178, 30474,				// Flamethrowers
	15, 41, 298, 312, 424, 811,					// Miniguns
	42, 159, 311, 433, 863, 1190,				// Heavy lunchboxes,
	5, 43, 239, 310, 331, 426, 587, 656, 1100,	// Fists
	140, 528, 30668,							// Wrangler, Short Circuit, Giger Counter
	998											// Vaccinator
};

public Action OnPlayerRunCmd(
	int nClientIdx, int &nButtonMask, int &nImpulse,
	float vDesiredVelocity[ 3 ], float vDesiredViewAngles[ 3 ],
	int &nWeapon, int &nSubtype,
	int &nCmdNum, int &nTickCount,
	int &nSeed, int vMousePos[ 2  ]
)
{
	if ( !sv_lptdm_spawnprotection_cancel_on_attack.BoolValue || !g_bIsClientProtected[ nClientIdx ] )
	{
		return Plugin_Continue;
	}

	if ( !IsPlayerAlive( nClientIdx ) )
	{
		return Plugin_Continue;
	}

	if ( view_as< bool >( nButtonMask & IN_ATTACK ) )
	{
		TF2_RemoveCondition( nClientIdx, TFCond_Ubercharged );

		return Plugin_Continue;
	}

	if ( view_as< bool >( nButtonMask & IN_ATTACK2 ) )
	{
		if ( TF2_GetPlayerClass( nClientIdx ) == TFClass_DemoMan )
		{
			if ( GetEntProp( nClientIdx, Prop_Send, "m_bShieldEquipped" ) == 1 )
			{
				TF2_RemoveCondition( nClientIdx, TFCond_Ubercharged );

				return Plugin_Continue;
			}
		}

		int nCurrentWeapon = GetEntPropEnt( nClientIdx, Prop_Send, "m_hActiveWeapon" );
		int nWeaponItemDefinitionIdx = GetEntProp( nCurrentWeapon, Prop_Send, "m_iItemDefinitionIndex" );
		for ( int i = 0; i < sizeof( g_nWeaponsWithSecondaryFire ); i++ )
		{
			if ( g_nWeaponsWithSecondaryFire[ i ] == nWeaponItemDefinitionIdx )
			{
				TF2_RemoveCondition( nClientIdx, TFCond_Ubercharged );

				return Plugin_Continue;
			}
		}
	}

	return Plugin_Continue;
}
