A modularized Team Fortress 2 SourceMod plugin developed for the LazyPurple Team Deathmatch Server.

# Modules
### Medieval
Implements a custom recreation of Medieval Mode, and a voting system to enable it on any map.
### Self Crits
Allows players to disable their ability to get random crits.

# Console Elements
LPTDM exposes the following console elements:
| Name | Description | Default | Notes |
|------|------|------|------|
| `sm_selfcrits` | Disable the calling players ability to get random crits. | N/A | None |
| `sm_medievalvote` | Initiate a vote to enable Medieval Mode. | N/A | None |
| `sm_forcemedieval` | Force the server into Medieval Mode. | N/A | Requires >= ADMFLAG_SLAY command privilege |
| `sv_lptdm_medieval_healthkit_enable` | Whether players should drop small healthkits upon death or not. | 1 | None |
| `sv_lptdm_medieval_vote_cooldown` | Time, in seconds, after a failed Medieval vote before another can be started. | 240 | None |
| `sv_lptdm_medieval_vote_percentage` | Percentage of players in the server that need to vote yes for Medieval Mode to be enabled. | 0.60 | None |

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
