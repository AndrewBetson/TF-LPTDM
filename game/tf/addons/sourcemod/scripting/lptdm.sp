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
	name		= "LazyPurple Team Deathmatch Server Stuff",
	author		= "Andrew \"andrewb\" Betson",
	description	= "Stuff for the LazyPurple Team Deathmatch Server.",
	version		= "1.0.1",
	url			= "https://www.github.com/AndrewBetson/TF-LPTDM"
};

#include "lptdm/lptdm_medieval.sp"
#include "lptdm/lptdm_selfcrits.sp"

public void OnPluginStart()
{
	if ( GetEngineVersion() != Engine_TF2 )
	{
		SetFailState( "LPTDM is only compatible with Team Fortress 2." );
	}

	LoadTranslations( "lptdm.phrases" );

	OnPluginStart_Medieval();
	OnPluginStart_SelfCrits();

	AutoExecConfig( true, "lptdm" );

	for ( int nIdx = MaxClients; nIdx > 0; --nIdx )
	{
		if ( !AreClientCookiesCached( nIdx ) )
		{
			continue;
		}

		OnClientCookiesCached( nIdx );
	}
}

public void OnClientCookiesCached( int nClientIdx )
{
	OnClientCookiesCached_SelfCrits( nClientIdx );
}

public void OnMapStart()
{
	OnMapStart_Medieval();
}

public void TF2_OnWaitingForPlayersStart()
{
	g_bIsPreGame = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bIsPreGame = false;
}
