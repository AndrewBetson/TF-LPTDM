A set of SourceMod plugins developed for [LazyPurple's TDM Server](https://lazypurple.com/connect-to/192.223.26.238%3A27025).

# Modules
### Medieval
Implements a custom recreation of Medieval Mode, and a voting system to toggle it on any map.
### Crit Toggle
Allows players to toggle their ability to get random crits.
### Spawn Protection
Configurable spawn protection.

# Console Elements
LPTDM exposes the following console elements:
| Name | Description | Default | Notes |
|------|------|------|------|
| `sm_selfcrits`/`sm_togglecrits` | Toggle the calling players ability to get random crits. | N/A | None |
| `sm_medievalvote` | Initiate a vote to toggle Medieval Mode. | N/A | None |
| `sm_forcemedieval` | Forcefully toggle Medieval Mode. | N/A | Requires >= ADMFLAG_SLAY command privilege |
| `sv_lptdm_medieval_healthkit_enable` | Whether players should drop small healthkits upon death or not. | 1 | None |
| `sv_lptdm_medieval_vote_cooldown` | Time, in seconds, after a failed Medieval vote before another can be started. | 240 | None |
| `sv_lptdm_spawnprotection_duration` | Number of seconds players are protected after spawning. | 5.0 | None |
| `sv_lptdm_spawnprotection_disable_during_pregame` | Disable spawn protection during pre-game warmup. | 1 | None |
| `sv_lptdm_spawnprotection_cancel_on_attack` | Cancel spawn protection when a player presses their primary attack key. | 0 | None |

# Dependencies
[nativevotes-updated](https://github.com/sapphonie/sourcemod-nativevotes-updated/releases/latest/)  
[tf2attributes](https://forums.alliedmods.net/showthread.php?t=210221)  
[morecolors](https://raw.githubusercontent.com/DoctorMcKay/sourcemod-plugins/master/scripting/include/morecolors.inc) *(compilation only)*

# Notes
### Medieval
- Enabling *actual* Medieval Mode requires a mapchange, so a successful Medieval vote actually enables a sort of faux-Medieval Mode instead, which I've tried to make as functionally similar to real Medieval Mode as possible.
- Currently, *all* dropped weapons get removed from the world when a Medieval vote is passed. In the future, I would like for only *Medieval incompatible* dropped weapons to be removed.
- As a result of the first note, `tf_medieval_autorp` and `tf_medieval_thirdperson` do not function.
### Crit Toggle
- Due to a quirk in how random crits are calculated, attacks that otherwise would have been random crits will still play crit sounds/particles/anims on the clients of players that have them disabled.

# TODO
### Medieval
- Only remove Medieval incompatible `tf_dropped_weapon` entities when Medieval is enabled.
- Add params to `sm_forcemedieval` for duration and filters. (map, until disabled, only RED, only BLU, etc.)

# License
LPTDM is released under version 3 of the GNU Affero General Public License. For more info, see `LICENSE.md`.
