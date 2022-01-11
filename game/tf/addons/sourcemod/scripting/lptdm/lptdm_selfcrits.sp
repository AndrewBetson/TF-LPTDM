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
 */

bool	g_bSelfCritsDisabled[ MAXPLAYERS + 1 ] = { false, ... };
Handle	g_hCookie_PlayerSelfCritPref;

void OnPluginStart_SelfCrits()
{
	RegConsoleCmd( "sm_selfcrits", Cmd_SelfCrits, "Disable your ability to get random crits." );

	g_hCookie_PlayerSelfCritPref = RegClientCookie( "playerselfcritpref", "Player preference for LPTDM_SelfCrits", CookieAccess_Public );
	SetCookiePrefabMenu( g_hCookie_PlayerSelfCritPref, CookieMenu_OnOff_Int, "Player Self Crit Preference", CookieHandler_PlayerSelfCritPref );
}

void OnClientCookiesCached_SelfCrits( int nClientIdx )
{
	char szCookieValue[ 8 ];
	GetClientCookie( nClientIdx, g_hCookie_PlayerSelfCritPref, szCookieValue, sizeof( szCookieValue ) );

	g_bSelfCritsDisabled[ nClientIdx ] = ( szCookieValue[ 0 ] != '\0' && StringToInt( szCookieValue ) );
}

Action Cmd_SelfCrits( int nClientIdx, int nNumArgs )
{
	g_bSelfCritsDisabled[ nClientIdx ] = !g_bSelfCritsDisabled[ nClientIdx ];
	CPrintToChat( nClientIdx, "%t", g_bSelfCritsDisabled[ nClientIdx ] ? "LPTDM_SC_Disabled" : "LPTDM_SC_Enabled" );

	char szNewCookieValue[ 8 ];
	IntToString( view_as< int >( g_bSelfCritsDisabled[ nClientIdx ] ), szNewCookieValue, sizeof( szNewCookieValue ) );

	SetClientCookie( nClientIdx, g_hCookie_PlayerSelfCritPref, szNewCookieValue );

	return Plugin_Handled;
}

public Action TF2_CalcIsAttackCritical( int nClientIdx, int nWeaponIdx, char[] szWeaponName, bool &bResult )
{
	if ( g_bSelfCritsDisabled[ nClientIdx ]  )
	{
		switch ( TF2_GetPlayerClass( nClientIdx ) )
		{
			case TFClass_Engineer:
			{
				// Player is using the Gunslinger (schema idx 142), which can't get random crits anyway; return original result to not break combo crit.
				if ( GetEntProp( nWeaponIdx, Prop_Send, "m_iItemDefinitionIndex" ) == 142 )
				{
					return Plugin_Continue;
				}
			}
			case TFClass_Spy:
			{
				// Return original result if a Spy is using their melee to not break client side backstab effects.
				if ( GetPlayerWeaponSlot( nClientIdx, 2 ) == nWeaponIdx )
				{
					return Plugin_Continue;
				}
			}
		}

		// NOTE(AndrewB): Some of these conditions aren't relevant to the LP TDM server, but are here regardless for completeness' sake.
		bool bIsCritBuffed =
			TF2_IsPlayerInCondition( nClientIdx, TFCond_Kritzkrieged )			||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_HalloweenCritCandy )	||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritCanteen )			||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritDemoCharge )		||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritOnFirstBlood )		||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritOnWin )				||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritOnFlagCapture )		||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritOnKill )			||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritMmmph )				||
			TF2_IsPlayerInCondition( nClientIdx, TFCond_CritOnDamage );

		// Return original result if crit buffed because some weapons can't get crits even *with* a crit buff.
		bResult = bIsCritBuffed ? bResult : false;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

void CookieHandler_PlayerSelfCritPref( int nClientIdx, CookieMenuAction eAction, any aInfo, char[] szBuffer, int nMaxLen )
{
	if ( eAction == CookieMenuAction_SelectOption )
	{
		OnClientCookiesCached( nClientIdx );
	}
}
