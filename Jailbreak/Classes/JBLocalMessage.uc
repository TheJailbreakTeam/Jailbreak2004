// ============================================================================
// JBLocalMessage
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBLocalMessage.uc,v 1.1 2002/11/24 11:14:07 mychaeel Exp $
//
// Localized messages for generic Jailbreak announcements.
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


// Allowed placeholders in all arena messages:
//   %teammate%  Name of teammate or own name
//   %enemy%     Name of enemy
//   %winner%    Name of arena match winner
//   %loser%     Name or arena match loser

var localized string TextArenaCountdown[3];
var localized string TextArenaStartCombatant;
var localized string TextArenaStartOther;
var localized string TextArenaTieCombatant;
var localized string TextArenaTieOther;
var localized string TextArenaEndWinner;
var localized string TextArenaEndLoser;
var localized string TextArenaEndOther;


// ============================================================================
// ClientReceive
//
// Receives an event on a client's computer and performs appropriate actions.
// The parameters assume the following values:
//
//   Switch    Meaning             Info 1           Info 2           Object    
//   =======   =================   ==============   ==============   ========
//   100 (b)   Team captured                                         TeamInfo
//   200 (b)   Team released       Releaser                          TeamInfo
//   300 (b)   Team stalemate
//   403       Arena countdown 3                                     Arena
//   402       Arena countdown 2                                     Arena
//   401       Arena countdown 1                                     Arena
//   400 (b)   Arena start         Red Combatant    Blue Combatant   Arena
//   410 (b)   Arena tie           Red Combatant    Blue Combatant   Arena
//   420 (b)   Arena victory       Winner           Loser            Arena
//
// Switches marked with (b) are broadcasted to all players, all other messages
// are directly sent to the players in question.
// ============================================================================

static function ClientReceive(PlayerController Player,
                              optional int Switch,
                              optional PlayerReplicationInfo PlayerReplicationInfo1, 
                              optional PlayerReplicationInfo PlayerReplicationInfo2,
                              optional Object ObjectOptional) {

  Super.ClientReceive(Player, Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, ObjectOptional);
  }


// ============================================================================
// ReplaceTextPlayer
//
// Replaces player name placeholder in the given template and returns the
// result.
// ============================================================================

static function string ReplaceTextPlayer(string TextTemplate, PlayerReplicationInfo PlayerReplicationInfo) {

  PlayerReplicationInfo.ReplaceText(TextTemplate, "%player%", PlayerReplicationInfo.PlayerName);
  return TextTemplate;
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
                                        PlayerReplicationInfo PlayerReplicationInfo2) {
  local PlayerController PlayerLocal;
  local PlayerReplicationInfo PlayerReplicationInfoTeammate;
  local PlayerReplicationInfo PlayerReplicationInfoEnemy;

  PlayerLocal = PlayerReplicationInfo1.Level.GetLocalPlayerController();

  if (PlayerLocal.PlayerReplicationInfo.Team == PlayerReplicationInfo1.Team) {
    PlayerReplicationInfoTeammate = PlayerReplicationInfo1;
    PlayerReplicationInfoEnemy    = PlayerReplicationInfo2;
    }
  
  else {
    PlayerReplicationInfoTeammate = PlayerReplicationInfo2;
    PlayerReplicationInfoEnemy    = PlayerReplicationInfo1;
    }

  PlayerLocal.ReplaceText(TextTemplate, "%teammate%", PlayerReplicationInfoTeammate.PlayerName);
  if (PlayerReplicationInfoEnemy != None)
    PlayerLocal.ReplaceText(TextTemplate, "%enemy%", PlayerReplicationInfoEnemy.PlayerName);
  
  PlayerLocal.ReplaceText(TextTemplate, "%winner%", PlayerReplicationInfo1.PlayerName);
  if (PlayerReplicationInfo2 != None)
    PlayerLocal.ReplaceText(TextTemplate, "%loser%",  PlayerReplicationInfo2.PlayerName);

  return TextTemplate;
  }


// ============================================================================
// IsLocalPlayer
//
// Returns whether the given PlayerReplicationInfo actor belongs to the local
// player on this client.
// ============================================================================

static function bool IsLocalPlayer(PlayerReplicationInfo PlayerReplicationInfo) {

  return PlayerController(PlayerReplicationInfo.Owner) != None &&
         Viewport(PlayerController(PlayerReplicationInfo.Owner).Player) != None;
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
                                 optional Object ObjectOptional) {

  local string TextTemplate;

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
        return ReplaceTextArena(Default.TextArenaTieCombatant, PlayerReplicationInfo1, PlayerReplicationInfo2);
      return ReplaceTextArena(Default.TextArenaTieOther, PlayerReplicationInfo1, PlayerReplicationInfo2);

    case 420:
      if (IsLocalPlayer(PlayerReplicationInfo1))
        return ReplaceTextArena(Default.TextArenaEndWinner, PlayerReplicationInfo1, PlayerReplicationInfo2);
      if (IsLocalPlayer(PlayerReplicationInfo2))
        return ReplaceTextArena(Default.TextArenaEndLoser, PlayerReplicationInfo1, PlayerReplicationInfo2);
      return ReplaceTextArena(Default.TextArenaEndOther, PlayerReplicationInfo1, PlayerReplicationInfo2);
    }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextTeamCaptured[0]     = "The red team has been captured.";
  TextTeamCaptured[1]     = "The blue team has been captured.";
  TextTeamReleased[0]     = "The red team has been released.";
  TextTeamReleased[1]     = "The blue team has been released.";
  TextTeamReleasedBy[0]   = "The red team has been released by %player%.";
  TextTeamReleasedBy[1]   = "The blue team has been released by %player%.";
  TextTeamStalemate       = "Both teams captured, no score.";

  TextArenaCountdown[2]   = "Arena match is about to begin...3";
  TextArenaCountdown[1]   = "Arena match is about to begin...2";
  TextArenaCountdown[0]   = "Arena match is about to begin...1";
  TextArenaStartCombatant = "Arena match has begun!";
  TextArenaStartOther     = "%teammate% is fighting %enemy% in the arena.";
  TextArenaTieCombatant   = "Arena match tied.";
  TextArenaTieOther       = "Arena match between %teammate% and %enemy% tied.";
  TextArenaEndWinner      = "You have won your freedom!";
  TextArenaEndLoser       = "You have lost the arena match.";
  TextArenaEndOther       = "%winner% has defeated %loser% in the arena.";

  bFadeMessage = True;
  bIsUnique    = True;
  bIsSpecial   = True;
  }