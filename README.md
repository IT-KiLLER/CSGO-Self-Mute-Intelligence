# [CS:GO] Self-Mute Intelligence 1.5.2
This plugin allows the player to mute any individual player.
## What has been improved/added is:  
- Lists players who have just spoken.
- Lists players who have a lot of mutes.
- Excludes those already muted by the client. 
- Other clients are sorted alphabetically.
- Admin can not be muted (set cvar `sm_selfmute_admin` to `1`).
- Those who get muted/unmuted are printed better if it goes.
- !cm (checkmutes) is removed. A better !su replaces this.
- Alltalk is not a problem anymore. **(NEW v1.5.1)**
- The menu will only contain team members if `sv_full_alltalk` is set to `0`. **(NEW v1.5.1)**
- And more...

## Upcoming features
- Silent radio for muted players.

## Requires
- [VoiceannounceEX](https://forums.alliedmods.net/showthread.php?p=2177167) (latest gamedata)
- [DHooks](https://forums.alliedmods.net/showthread.php?t=180114) (The plugin above requires it)

## Cvars 
- `sm_selfmute_admin` `0` - *_Admin (kick flag) can not be muted. Disabled by default. (1/0)._* 
- `sm_selfmute_talk_seconds` `45.0` - *_List clients who have recently spoken within x secounds (1.0 - 180.0)._*  
- `sm_selfmute_spam_mutes` `4.0` - *_How many mutes a client needs to get listed as spammer (1.0 - 64.0)._*

## Download
### [Download (smx)](https://github.com/IT-KiLLER/CSGO-Self-Mute-Intelligence/raw/master/SelfMute.smx)    [Source code (zip)](https://github.com/IT-KiLLER/CSGO-Self-Mute-Intelligence/archive/master.zip)
Please feel free to contact me if you have any questions. [contact information here.](https://github.com/IT-KiLLER/HOW-TO-CONTACT-ME)

There will probably be another update, after a test. Stay tuned. (2017-10-24)

## Change log
- **1.5.2** - 2017-10-27
  - Bots filter temporarily disabled.
  - Unnecessary cvar (`sv_alltalk`) removed.
  - Other changes.
- **1.5.1** - 2017-10-24
  - Excludes bots.
  - Alltalk issue solved!
  - if alltalk is disabled then the menu will only contain team members. 
- **1.5** - 2017-10-23
  - Released!

## Gameplay
Screenshots coming soon
