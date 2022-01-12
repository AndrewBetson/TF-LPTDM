A modularized Team Fortress 2 SourceMod plugin developed for the LazyPurple Team Deathmatch Server.

# Modules
### Medieval
Implements a custom recreation of Medieval Mode, and a voting system to enable it on any map.
### Self Crits
Allows players to disable their ability to get random crits.

# Console Elements
LPTDM exposes the following console elements:
- `sm_selfcrits`									- Disables the calling players ability to get random crits.
- `sm_medievalvote`									- Initiates a vote to enable Medieval Mode.
- `sm_forcemedieval`								- Forces the server into Medieval Mode. Requires >=ADMFLAG_SLAY command privilege.
- `sv_lptdm_medieval_healthkit_enable (def 1)`		- Whether players should drop small healthkits when they are killed or not.
- `sv_lptdm_medieval_vote_cooldown (def. 240)`		- Time, in seconds, after a failed Medieval vote before another can be started.
- `sv_lptdm_medieval_vote_percentage (def. 0.60)`	- Percent of players that need to vote yes to enable Medieval Mode.

# Dependencies
[nativevotes-updated](https://github.com/sapphonie/sourcemod-nativevotes-updated/releases/latest/)  
[tf2attributes](https://forums.alliedmods.net/showthread.php?t=210221)  
[morecolors](https://raw.githubusercontent.com/DoctorMcKay/sourcemod-plugins/master/scripting/include/morecolors.inc) *(compilation only)*

# Notes
### Medieval
- Enabling *actual* Medieval Mode requires a mapchange, so a successful Medieval vote actually enables a sort of faux-Medieval Mode instead, which I've tried to make as functionally similar to real Medieval Mode as possible.
- Currently, *all* dropped weapons get removed from the world when a Medieval vote is passed. In the future, I would like for only *non-Medieval compatible* dropped weapons to be removed.
- As a result of the first note, `tf_medieval_autorp` and `tf_medieval_thirdperson` do not function.
### Self Crits
- Due to a quirk in how random crits are calculated, attacks that otherwise would have been random crits will still play crit sounds/particles/anims on the clients of players that have self crits disabled.

# TODO
### Medieval
- Only remove non-Medieval compatible `tf_dropped_weapon` entities when Medieval is enabled.
- Add params to `sm_forcemedieval` for duration and filters. (map, until disabled, only RED, only BLU, etc.)

# License
LPTDM is released under version 3 of the GNU Affero General Public License. For more info, see `LICENSE.md`.
