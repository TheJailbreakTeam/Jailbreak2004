// ============================================================================
// JBLocalMessage
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBLocalMessage.uc,v 1.12 2004/04/14 12:06:54 mychaeel Exp $
//
// Abstract base class for localized Jailbreak messages. Contains all
// functionality common to console and on-screen messages.
//
// The following message codes are defined:
//
//   Switch    Meaning             Info 1           Info 2           Object
//   =======   =================   ==============   ==============   ========
//   100 (B)   Team captured                                         TeamInfo
//   200 (B)   Team released       Releaser                          TeamInfo
//   300 (B)   Team stalemate
//   403       Arena countdown 3                                     Arena
//   402       Arena countdown 2                                     Arena
//   401       Arena countdown 1                                     Arena
//   400 (B)   Arena start         Red Combatant    Blue Combatant   Arena
//   410 (B)   Arena cancelled     Red Combatant    Blue Combatant   Arena
//   420 (B)   Arena tie           Red Combatant    Blue Combatant   Arena
//   430 (B)   Arena victory       Winner           Loser            Arena
//   500 (L)   Keyboard arena
//   510 (L)   Keyboard cameras
//   600 (L)   Last man (initial)
//   610 (L)   Last man (repeat)
//   700 (B)   Last second save
//   900 (B)   Game started
//   910 (B)   Game overtime
//   920 (B)   Game over                                             TeamInfo
//
// Switches marked with (B) are broadcasted to all players, all other messages
// are directly sent to the players in question. Messages marked with (L) are
// sent locally to a single player.
// ============================================================================


class JBLocalMessage extends LocalMessage
  notplaceable;


// ============================================================================
// Localization
// ============================================================================

var localized string TextTeamCaptured[2];
var localized string TextTeamReleased[2];
var localized string TextTeamReleasedBy[2];
var localized string TextTeamStalemate;


// Supported placeholders in all arena messages:
//   %teammate%   Name of teammate or own name
//   %enemy%      Name of enemy
//   %winner%     Name of arena match winner
//   %loser%      Name or arena match loser

var localized string TextArenaCountdown[3];
var localized string TextArenaStartCombatant;
var localized string TextArenaStartOther;
var localized string TextArenaCancelCombatant;
var localized string TextArenaCancelOther;
var localized string TextArenaTieCombatant;
var localized string TextArenaTieOther;
var localized string TextArenaEndWinner;
var localized string TextArenaEndLoser;
var localized string TextArenaEndOther;


var           string TextKeyboardArena;
var localized string TextKeyboardArenaBound;
var localized string TextKeyboardArenaUnbound;
var           string TextKeyboardCamera;
var localized string TextKeyboardCameraBound;
var localized string TextKeyboardCameraUnbound;


var localized string TextLastMan;


// ============================================================================
// Variables
// ============================================================================

var Class<JBLocalMessage> ClassLocalMessageScreen;   // on-screen messages
var Class<JBLocalMessage> ClassLocalMessageConsole;  // console messages


// ============================================================================
// PlaySpeech
//
// Plays the given segmented speech sequence definition for the given player
// and returns whether playback was successfully started.
// ============================================================================

static function bool PlaySpeech(PlayerController PlayerController,
                                         string Definition0,
                                optional string Definition1,
                                optional int iDefinition)
{
  local string Tags;

       if (PlayerController.PlayerReplicationInfo.bOnlySpectator)      Tags = "spectator";
  else if (PlayerController.PlayerReplicationInfo.Team.TeamIndex == 0) Tags = "red";
  else if (PlayerController.PlayerReplicationInfo.Team.TeamIndex == 1) Tags = "blue";

  switch (iDefinition) {
    case 0:  return Class'JBSpeechManager'.Static.PlayFor(PlayerController.Level, Definition0, Tags);
    case 1:  return Class'JBSpeechManager'.Static.PlayFor(PlayerController.Level, Definition1, Tags);
  }
  
  return False;
}


// ============================================================================
// ClientReceive
//
// Receives an event on a client. If called for the generic message class,
// replaces it by the more specific on-screen or console message, respectively.
// Otherwise plays sound and continues processing.
// ============================================================================

static function ClientReceive(PlayerController PlayerController,
                              optional int Switch,
                              optional PlayerReplicationInfo PlayerReplicationInfo1,
                              optional PlayerReplicationInfo PlayerReplicationInfo2,
                              optional Object ObjectOptional)
{
  local string Key;
  local string KeyPrev;
  local string KeyNext;
  local Class<JBLocalMessage> ClassLocalMessageReplacement;

  if (Default.Class == Class'JBLocalMessage') {
    ClassLocalMessageReplacement = Default.ClassLocalMessageScreen;
    
    if (Switch >= 400 && Switch <= 499 &&
       !IsLocalPlayer(PlayerReplicationInfo1) &&
       !IsLocalPlayer(PlayerReplicationInfo2))
      ClassLocalMessageReplacement = Default.ClassLocalMessageConsole;

    PlayerController.ReceiveLocalizedMessage(
      ClassLocalMessageReplacement,
      Switch,
      PlayerReplicationInfo1,
      PlayerReplicationInfo2,
      ObjectOptional);
    return;
  }

  switch (Switch) {
    case 100:  PlaySpeech(PlayerController, "$TeamCapturedRed", "$TeamCapturedBlue", TeamInfo(ObjectOptional).TeamIndex);  break;
    case 200:  PlaySpeech(PlayerController, "$TeamReleasedRed", "$TeamReleasedBlue", TeamInfo(ObjectOptional).TeamIndex);  break;
    case 300:  PlaySpeech(PlayerController, "$TeamCapturedBoth");  break;
    
    case 403:  PlayerController.PlayBeepSound();  PlaySpeech(PlayerController, "$ArenaWarning");  break;
    case 402:  PlayerController.PlayBeepSound();  break;
    case 401:  PlayerController.PlayBeepSound();  break;
   
    case 400:  PlaySpeech(PlayerController, "$ArenaStart");       break;
    case 410:  PlaySpeech(PlayerController, "$ArenaCancelled");   break;
    case 420:  PlaySpeech(PlayerController, "$ArenaEndTimeout");  break;

    case 430:
           if (PlayerController.PlayerReplicationInfo == PlayerReplicationInfo1) PlaySpeech(PlayerController, "$ArenaEndWinner");
      else if (PlayerController.PlayerReplicationInfo == PlayerReplicationInfo2) PlaySpeech(PlayerController, "$ArenaEndLoser");
      break;

    case 600:  PlaySpeech(PlayerController, "$LastMan");          break;
    case 700:  PlaySpeech(PlayerController, "$LastSecondSave");   break;
    case 900:  PlaySpeech(PlayerController, "$GameStart");        break;
    case 910:  PlaySpeech(PlayerController, "$GameOvertime");     break;
    case 920:  PlaySpeech(PlayerController, "$GameOverWinnerRed", "$GameOverWinnerBlue", TeamInfo(ObjectOptional).TeamIndex);  break;

    case 500:
      Key = Class'JBInteractionKeys'.Static.GetKeyForCommand("ArenaCam");
      if (Key == "")
             Default.TextKeyboardArena =                   Default.TextKeyboardArenaUnbound;
        else Default.TextKeyboardArena = StaticReplaceText(Default.TextKeyboardArenaBound, "%key%", Key);
      break;

    case 510:
      KeyPrev = Class'JBInteractionKeys'.Static.GetKeyForCommand("PrevWeapon", "PrevWeapon");
      KeyNext = Class'JBInteractionKeys'.Static.GetKeyForCommand("NextWeapon", "NextWeapon");
      if (KeyPrev == "PrevWeapon" && KeyNext == "NextWeapon")
        Default.TextKeyboardCamera = Default.TextKeyboardCameraUnbound;
      else
        Default.TextKeyboardCamera = StaticReplaceText(StaticReplaceText(
          Default.TextKeyboardCameraBound,
            "%keyprev%", KeyPrev),
            "%keynext%", KeyNext);
      break;
  }

  Super.ClientReceive(PlayerController, Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, ObjectOptional);
}


// ============================================================================
// StaticReplaceText
//
// Works almost like ReplaceText defined in Actor, but returns its result
// instead of employing an out parameter, and is static and can thus be called
// from other static functions.
// ============================================================================

static function string StaticReplaceText(string TextTemplate, string TextPlaceholder, string TextReplacement)
{
  local int OffsetPlaceholder;
  local string TextOutput;

  while (True) {
    OffsetPlaceholder = InStr(TextTemplate, TextPlaceholder);
    if (OffsetPlaceholder < 0)
      break;

    TextOutput = TextOutput $ Left(TextTemplate, OffsetPlaceholder);
    TextOutput = TextOutput $ TextReplacement;

    TextTemplate = Mid(TextTemplate, OffsetPlaceholder + Len(TextPlaceholder));
  }

  TextOutput = TextOutput $ TextTemplate;
  return TextOutput;
}


// ============================================================================
// ReplaceTextPlayer
//
// Replaces player name placeholder in the given template and returns the
// result.
// ============================================================================

static function string ReplaceTextPlayer(string TextTemplate, PlayerReplicationInfo PlayerReplicationInfo)
{
  return StaticReplaceText(TextTemplate, "%player%", PlayerReplicationInfo.PlayerName);
}


// ============================================================================
// ReplaceTextArena
//
// Replaces all placeholders present in the given template string by the
// information given through the two PlayerReplicationInfo actors. Assumes the
// first PlayerReplicationInfo actor to refer to the winner, the second to
// refer to the loser.
// ============================================================================

static function string ReplaceTextArena(string TextTemplate,
                                        PlayerReplicationInfo PlayerReplicationInfo1,
                                        PlayerReplicationInfo PlayerReplicationInfo2)
{
  local PlayerController PlayerLocal;
  local PlayerReplicationInfo PlayerReplicationInfoTeammate;
  local PlayerReplicationInfo PlayerReplicationInfoEnemy;

  PlayerLocal = PlayerReplicationInfo1.Level.GetLocalPlayerController();

  if (PlayerLocal.PlayerReplicationInfo.Team == PlayerReplicationInfo1.Team) {
    PlayerReplicationInfoTeammate = PlayerReplicationInfo1;
    PlayerReplicationInfoEnemy    = PlayerReplicationInfo2;
  } else {
    PlayerReplicationInfoTeammate = PlayerReplicationInfo2;
    PlayerReplicationInfoEnemy    = PlayerReplicationInfo1;
  }

  TextTemplate = StaticReplaceText(TextTemplate, "%teammate%", PlayerReplicationInfoTeammate.PlayerName);
  if (PlayerReplicationInfoEnemy != None)
    TextTemplate = StaticReplaceText(TextTemplate, "%enemy%", PlayerReplicationInfoEnemy.PlayerName);

  TextTemplate = StaticReplaceText(TextTemplate, "%winner%", PlayerReplicationInfo1.PlayerName);
  if (PlayerReplicationInfo2 != None)
    TextTemplate = StaticReplaceText(TextTemplate, "%loser%",  PlayerReplicationInfo2.PlayerName);

  return TextTemplate;
}


// ============================================================================
// IsLocalPlayer
//
// Returns whether the given PlayerReplicationInfo actor belongs to the local
// player on this client.
// ============================================================================

static function bool IsLocalPlayer(PlayerReplicationInfo PlayerReplicationInfo)
{
  return (PlayerReplicationInfo.Level.GetLocalPlayerController().PlayerReplicationInfo == PlayerReplicationInfo);
}


// ============================================================================
// GetString
//
// Gets the localized string for the given event. See ClientReceive for an
// explanation of possible parameter values.
// ============================================================================

static function string GetString(optional int Switch,
                                 optional PlayerReplicationInfo PlayerReplicationInfo1,
                                 optional PlayerReplicationInfo PlayerReplicationInfo2,
                                 optional Object ObjectOptional)
{
  switch (Switch) {
    case 100:  return Default.TextTeamCaptured[TeamInfo(ObjectOptional).TeamIndex];
    case 300:  return Default.TextTeamStalemate;

    case 200:
      if (PlayerReplicationInfo1 != None)
        return ReplaceTextPlayer(Default.TextTeamReleasedBy[TeamInfo(ObjectOptional).TeamIndex], PlayerReplicationInfo1);
      return Default.TextTeamReleased[TeamInfo(ObjectOptional).TeamIndex];

    case 403:  return ReplaceTextArena(Default.TextArenaCountdown[2], PlayerReplicationInfo1, PlayerReplicationInfo2);
    case 402:  return ReplaceTextArena(Default.TextArenaCountdown[1], PlayerReplicationInfo1, PlayerReplicationInfo2);
    case 401:  return ReplaceTextArena(Default.TextArenaCountdown[0], PlayerReplicationInfo1, PlayerReplicationInfo2);

    case 400:
      if (IsLocalPlayer(PlayerReplicationInfo1) ||
          IsLocalPlayer(PlayerReplicationInfo2))
        return ReplaceTextArena(Default.TextArenaStartCombatant, PlayerReplicationInfo1, PlayerReplicationInfo2);
      return ReplaceTextArena(Default.TextArenaStartOther, PlayerReplicationInfo1, PlayerReplicationInfo2);

    case 410:
      if (IsLocalPlayer(PlayerReplicationInfo1) ||
          IsLocalPlayer(PlayerReplicationInfo2))
        return ReplaceTextArena(Default.TextArenaCancelCombatant, PlayerReplicationInfo1, PlayerReplicationInfo2);
      return ReplaceTextArena(Default.TextArenaCancelOther, PlayerReplicationInfo1, PlayerReplicationInfo2);

    case 420:
      if (IsLocalPlayer(PlayerReplicationInfo1) ||
          IsLocalPlayer(PlayerReplicationInfo2))
        return ReplaceTextArena(Default.TextArenaTieCombatant, PlayerReplicationInfo1, PlayerReplicationInfo2);
      return ReplaceTextArena(Default.TextArenaTieOther, PlayerReplicationInfo1, PlayerReplicationInfo2);

    case 430:
      if (IsLocalPlayer(PlayerReplicationInfo1))
        return ReplaceTextArena(Default.TextArenaEndWinner, PlayerReplicationInfo1, PlayerReplicationInfo2);
      if (IsLocalPlayer(PlayerReplicationInfo2))
        return ReplaceTextArena(Default.TextArenaEndLoser, PlayerReplicationInfo1, PlayerReplicationInfo2);
      return ReplaceTextArena(Default.TextArenaEndOther, PlayerReplicationInfo1, PlayerReplicationInfo2);

    case 500:  return Default.TextKeyboardArena;
    case 510:  return Default.TextKeyboardCamera;
    
    case 600:  return Default.TextLastMan;
    case 610:  return Default.TextLastMan;
  }
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsConsoleMessage = False;
  bIsSpecial = False;

  TextTeamCaptured[0]       = "The red team has been captured.";
  TextTeamCaptured[1]       = "The blue team has been captured.";
  TextTeamReleased[0]       = "The red team has been released.";
  TextTeamReleased[1]       = "The blue team has been released.";
  TextTeamReleasedBy[0]     = "The red team has been released by %player%.";
  TextTeamReleasedBy[1]     = "The blue team has been released by %player%.";
  TextTeamStalemate         = "Both teams captured, no score.";

  TextArenaCountdown[2]     = "Arena match is about to begin...3";
  TextArenaCountdown[1]     = "Arena match is about to begin...2";
  TextArenaCountdown[0]     = "Arena match is about to begin...1";
  TextArenaStartCombatant   = "Arena match has begun!";
  TextArenaStartOther       = "%teammate% is fighting %enemy% in the arena.";
  TextArenaCancelCombatant  = "Arena match between %teammate% and %enemy% cancelled.";
  TextArenaCancelOther      = "Arena match has been cancelled.";
  TextArenaTieCombatant     = "Arena match tied.";
  TextArenaTieOther         = "Arena match between %teammate% and %enemy% tied.";
  TextArenaEndWinner        = "You have won your freedom!";
  TextArenaEndLoser         = "You have lost the arena match.";
  TextArenaEndOther         = "%winner% has defeated %loser% in the arena.";

  TextKeyboardArenaBound    = "Press [%key%] to watch this arena fight!";
  TextKeyboardArenaUnbound  = "Enter 'ArenaCam' at the console to watch this arena fight!";
  TextKeyboardCameraBound   = "Press [%keyprev%] and [%keynext%] to switch cameras";
  TextKeyboardCameraUnbound = "Enter 'PrevWeapon' and 'NextWeapon' at the console to switch cameras";

  TextLastMan               = "You are the last free player. Release your team!";

  ClassLocalMessageScreen   = Class'JBLocalMessageScreen';
  ClassLocalMessageConsole  = Class'JBLocalMessageConsole';
}