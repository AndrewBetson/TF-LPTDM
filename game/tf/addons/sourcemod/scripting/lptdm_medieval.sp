/**
 * Copyright Andrew Betson.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * Most of the voting portion of this module is ripped directly from the nativevotes mapchooser src,
 * which is itself based on the vanilla mapchooser plugin src.
 *
 * SourceMod	(C)2004-2008 AlliedModders LLC. (original mapchooser)
 * NativeVotes	(C)2011-2016 Ross Bemrose (Powerlord). (nativevotes mapchooser)
 */

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include <tf2>
#include <tf2_stocks>

#include <nativevotes>
#include <tf2attributes> // needed for checking if a weapon can be used in Medieval Mode
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

bool g_bIsPreGame;

public Plugin myinfo =
{
	name		= "LPTDM - Medieval",
	author		= "Andrew \"andrewb\" Betson",
	description	= "Custom reimplementation of Medieval Mode with a voting system for toggling it for LazyPurple's TDM Server.",
	version		= "1.2.0",
	url			= "https://www.github.com/AndrewBetson/TF-LPTDM"
};

ConVar	sv_lptdm_medieval_healthkit_enable;

ConVar	sv_lptdm_medieval_vote_cooldown;

bool	g_bCanCallMedievalVote;
bool	g_bIsMedievalModeActive;
bool	g_bIsMapAlreadyMedieval;

int		g_nLastVoteTime;

Handle	g_hSDKCall_TFPlayer_DropHealthPack;

public void OnPluginStart()
{
	if ( GetEngineVersion() != Engine_TF2 )
	{
		SetFailState( "The LPTDM plugins are only compatible with Team Fortress 2." );
	}

	LoadTranslations( "lptdm.phrases" );
	AutoExecConfig( true, "lptdm_medieval" );

	RegConsoleCmd( "sm_medievalvote", Cmd_MedievalVote, "Initiate a vote to enable Medieval Mode." );
	RegAdminCmd( "sm_forcemedieval", Cmd_ForceMedieval, ADMFLAG_SLAY, "Force the server into Medieval Mode." );

	sv_lptdm_medieval_healthkit_enable = CreateConVar( "sv_lptdm_medieval_healthkit_enable", "1", "Whether players should drop small healthkits when they are killed or not.", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	sv_lptdm_medieval_vote_cooldown = CreateConVar( "sv_lptdm_medieval_vote_cooldown", "240", "Time, in seconds, after a failed Medieval Vote before another can be started.", FCVAR_NOTIFY, true, 0.0 );

	HookConVarChange( sv_lptdm_medieval_vote_cooldown, ConVar_OnCooldownChanged );
	HookEvent( "post_inventory_application", Event_PostInventoryApplication, EventHookMode_Post );
	HookEvent( "player_death", Event_PlayerDeath, EventHookMode_Post );

	// SDKCall for CTFPlayer::DropHealthPack()
	StartPrepSDKCall( SDKCall_Player );
	{
		PrepSDKCall_SetSignature( SDKLibrary_Server, "@_ZN9CTFPlayer14DropHealthPackERK15CTakeDamageInfob", -1 );
		PrepSDKCall_SetReturnInfo( SDKType_PlainOldData, SDKPass_Plain );

		// Don't know why this function even has these params,
		// since neither of them seem to actually be used by it...
		PrepSDKCall_AddParameter( SDKType_PlainOldData, SDKPass_ByRef ); // CTakeDamageInfo *
		PrepSDKCall_AddParameter( SDKType_Bool, SDKPass_ByValue );
	}

	g_hSDKCall_TFPlayer_DropHealthPack = EndPrepSDKCall();
}

public void OnMapStart()
{
	// Don't allow Medieval votes to be called if this is already a Medieval map.
	g_bIsMapAlreadyMedieval = ( FindEntityByClassname( -1, "tf_logic_medieval" ) ) != -1;
	g_bIsMedievalModeActive = false;
	g_bCanCallMedievalVote = !g_bIsMapAlreadyMedieval;
}

Action Cmd_MedievalVote( int nClientIdx, int nNumArgs )
{
	if ( g_bIsPreGame )
	{
		NativeVotes_DisplayCallVoteFail( nClientIdx, NativeVotesCallFail_Waiting );
		return Plugin_Handled;
	}

	if ( g_bIsMapAlreadyMedieval )
	{
		// TODO(AndrewB): Find a way to display this as a vote fail popup.
		CPrintToChat( nClientIdx, "%t", "LPTDM_MV_CannotCallVote_AlreadyMedieval" );
		return Plugin_Handled;
	}

	int nTimeSinceLastVote = GetTime() - g_nLastVoteTime;
	if ( nTimeSinceLastVote >= sv_lptdm_medieval_vote_cooldown.IntValue )
	{
		g_bCanCallMedievalVote = true;
	}

	if ( !g_bCanCallMedievalVote )
	{
		NativeVotes_DisplayCallVoteFail( nClientIdx, NativeVotesCallFail_Failed, sv_lptdm_medieval_vote_cooldown.IntValue - nTimeSinceLastVote );
		return Plugin_Handled;
	}

	g_bCanCallMedievalVote = false;
	g_nLastVoteTime = GetTime();

	NativeVote hMedievalVote = new NativeVote( NVCallback_VoteMenu, NativeVotesType_Custom_YesNo );
	hMedievalVote.Initiator = nClientIdx;
	hMedievalVote.SetTitle( "%t", g_bIsMedievalModeActive ? "LPTDM_MV_VoteTitle_Disable" : "LPTDM_MV_VoteTitle_Enable" );

	hMedievalVote.DisplayVoteToAll( 20, VOTEFLAG_NO_REVOTES );

	return Plugin_Handled;
}

Action Cmd_ForceMedieval( int nClientIdx, int nNumArgs )
{
	CPrintToChatAll( "%t", g_bIsMedievalModeActive ? "LPTDM_MV_Forced_Disable" : "LPTDM_MV_Forced_Enable" );
	if ( g_bIsMedievalModeActive )
	{
		g_bIsMedievalModeActive = false;
	}
	else
	{
		EnableMedievalMode();
	}

	return Plugin_Handled;
}

void ConVar_OnCooldownChanged( ConVar hConVar, const char[] szOldValue, const char[] szNewValue )
{
	int nNewValue = StringToInt( szNewValue );

	int nTimeSinceLastVote = GetTime() - g_nLastVoteTime;
	if ( nTimeSinceLastVote >= nNewValue )
	{
		g_bCanCallMedievalVote = true;
	}
}

void EnableMedievalMode()
{
	g_bIsMedievalModeActive = true;

	// Remove Medieval incompatible weapons from living players' loadouts.
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame( i ) || !IsPlayerAlive( i ) )
		{
			continue;
		}

		RemoveNonMedievalWeaponsFromClient( i );
	}

	// Remove Medieval incompatible projectiles from the world.

	int nEntIdx;
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_flare" ) ) != -1 )			RemoveEntity( nEntIdx );
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_jar" ) ) != -1 )				RemoveEntity( nEntIdx );
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_jar_gas" ) ) != -1 )			RemoveEntity( nEntIdx );
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_pipe" ) ) != -1 )			RemoveEntity( nEntIdx );
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_pipe_remote" ) ) != -1 )		RemoveEntity( nEntIdx );
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_rocket" ) ) != -1 )			RemoveEntity( nEntIdx );
	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_projectile_sentryrocket" ) ) != -1 )	RemoveEntity( nEntIdx );

	// Remove player-built Engineer buildings from the world.

	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "obj_dispenser" ) ) != -1 )
	{
		if ( GetEntPropEnt( nEntIdx, Prop_Send, "m_hBuilder" ) != -1 )
		{
			RemoveEntity( nEntIdx );
		}
	}

	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "obj_sentrygun" ) ) != -1 )
	{
		if ( GetEntPropEnt( nEntIdx, Prop_Send, "m_hBuilder" ) != -1 )
		{
			RemoveEntity( nEntIdx );
		}
	}

	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "obj_teleporter" ) ) != -1 )
	{
		if ( GetEntPropEnt( nEntIdx, Prop_Send, "m_hBuilder" ) != -1 )
		{
			RemoveEntity( nEntIdx );
		}
	}

	// Remove dropped weapons from the world to avoid players being able to
	// pick up Medieval incompatible weapons that were dropped before
	// Medieval Mode was enabled and occupy the same slot as a weapon
	// they have equipped that *is* compatible with Medieval Mode.
	// (gunboats/lunchbox -> shotgun, mad milk/bonk/cola/guillotine -> pistol, bootlegger/booties -> grenade launcher, etc.)
	// TODO(AndrewB): Only remove Medieval-incompatible dropped weapons.

	while ( ( nEntIdx = FindEntityByClassname( nEntIdx, "tf_dropped_weapon" ) ) != -1 )
	{
		RemoveEntity( nEntIdx );
	}
}

void RemoveNonMedievalWeaponsFromClient( int nClientIdx )
{
	// Force the client to switch to their melee to avoid civilizing them.
	// Not a pretty way to do it, but setting the active weapon handle manually
	// causes the weapon model to not render.
	// Note: This doesn't work for bots.
	ClientCommand( nClientIdx, "slot3" );

	for ( int nSlotIdx = TFWeaponSlot_Primary; nSlotIdx < TFWeaponSlot_PDA; nSlotIdx++ )
	{
		// All melee weapons are allowed in Medieval Mode.
		if ( nSlotIdx == TFWeaponSlot_Melee )
		{
			continue;
		}

		int nWeaponIdx = GetPlayerWeaponSlot( nClientIdx, nSlotIdx );

		// Some weapons are basically just cosmetics w/ gameplay attributes, and don't actually exist in the slot they're supposed to.
		if ( nWeaponIdx == -1 )
		{
			continue;
		}

		// Don't remove the disguise kit or invis watch.
		// Yes, those are actually the weapon slot indices for these.
		if ( TF2_GetPlayerClass( nClientIdx ) == TFClass_Spy && ( nSlotIdx == TFWeaponSlot_Grenade || nSlotIdx == TFWeaponSlot_Building ) )
		{
			continue;
		}

		int nWeaponItemDefinitionIdx = GetEntProp( nWeaponIdx, Prop_Send, "m_iItemDefinitionIndex" );
		int nAttributes[ 16 ];
		float flValues[ 16 ];
		int nNumAttributes = TF2Attrib_GetStaticAttribs( nWeaponItemDefinitionIdx, nAttributes, flValues );

		bool bIsWeaponMedievalCompatible = false;
		for ( int nAttribIdx = 0; nAttribIdx <= nNumAttributes; nAttribIdx++ )
		{
			if ( nAttributes[ nAttribIdx ] == 2029 ) // 2029 = "allowed in medieval mode" attrib idx
			{
				bIsWeaponMedievalCompatible = true;
				break;
			}
		}

		if ( !bIsWeaponMedievalCompatible )
		{
			TF2_RemoveWeaponSlot( nClientIdx, nSlotIdx );
		}
	}
}

Action Event_PostInventoryApplication( Handle hEvent, char[] szName, bool bDontBroadcast )
{
	if ( !g_bIsMedievalModeActive || g_bIsMapAlreadyMedieval )
	{
		return Plugin_Handled;
	}

	int nClientIdx = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );

	// HACK(AndrewB): For some reason RemoveNonMedievalWeaponsFromClient() fails to remove the sapper from Spies unless we wait a frame first.
	RequestFrame( Frame_PostInventoryApplication, nClientIdx );

	return Plugin_Handled;
}

Action Event_PlayerDeath( Handle hEvent, char[] szName, bool bDontBroadcast )
{
	if ( !g_bIsMedievalModeActive || g_bIsMapAlreadyMedieval || !sv_lptdm_medieval_healthkit_enable.BoolValue )
	{
		return Plugin_Handled;
	}

	int nVictim = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	int nAttacker = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );

	if ( nVictim == nAttacker || nAttacker == 0 )
	{
		// Don't drop a healthkit if the player killed themselves or were killed by a server command.
		return Plugin_Handled;
	}

	SDKCall( g_hSDKCall_TFPlayer_DropHealthPack, nVictim, 0, false );

	return Plugin_Handled;
}

void Frame_PostInventoryApplication( int nClientIdx )
{
	RemoveNonMedievalWeaponsFromClient( nClientIdx );
}

public void TF2_OnWaitingForPlayersStart()
{
	g_bIsPreGame = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bIsPreGame = false;
}

int NVCallback_VoteMenu( NativeVote hMenu, MenuAction eAction, int nParam1, int nParam2 )
{
	switch ( eAction )
	{
		case MenuAction_End:
		{
			hMenu.Close();
		}
		case MenuAction_VoteCancel:
		{
			hMenu.DisplayFail( nParam1 == VoteCancel_NoVotes ? NativeVotesFail_NotEnoughVotes : NativeVotesFail_Generic );
		}
		case MenuAction_VoteEnd:
		{
			if ( nParam1 == NATIVEVOTES_VOTE_NO )
			{
				hMenu.DisplayFail( NativeVotesFail_Loses );
			}
			else
			{
				hMenu.DisplayPass( "%t", g_bIsMedievalModeActive ? "LPTDM_MV_VoteSucceeded_Disable" : "LPTDM_MV_VoteSucceeded_Enable" );
				if ( g_bIsMedievalModeActive )
				{
					g_bIsMedievalModeActive = false;
				}
				else
				{
					EnableMedievalMode();
				}
			}
		}
	}

	return 0;
}
